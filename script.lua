-- =============================================================
-- KamiHub Ultimate + Key System + Skin Changer Integrated
-- =============================================================

-- [0-1] 키 시스템 인증 검증 로직 (웹 서버 API 통신)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local API_URL = "https://api.pagamescripts.xyz/checkkey" -- 필요시 수정 가능

local function verifyKey()
    if not script_key or script_key == "" then
        LocalPlayer:Kick("\n[KamiHub] ❌ License key is missing! Please get your script from the Discord bot.")
        return false
    end

    local rawHwid = ""
    pcall(function()
        rawHwid = (gethwid and gethwid()) or (RbxAnalyticsService and RbxAnalyticsService:GetClientId()) or "Unknown_HWID"
    end)

    local requestUrl = string.format("%s?key=%s&hwid=%s", API_URL, HttpService:UrlEncode(script_key), HttpService:UrlEncode(rawHwid))
    
    local success, response = pcall(function()
        return game:HttpGet(requestUrl)
    end)

    if not success then
        LocalPlayer:Kick("\n[KamiHub] ⚠️ Failed to connect to the authentication server.")
        return false
    end

    local decoded = {}
    pcall(function()
        decoded = HttpService:JSONDecode(response)
    end)

    if decoded and decoded.valid then
        print("[KamiHub] ✅ License verified successfully!")
        return true
    else
        local reason = (decoded and decoded.message) or "Invalid or unverified key."
        LocalPlayer:Kick("\n[KamiHub] ❌ Authentication Failed: " .. reason)
        return false
    end
end

-- [0-2] 키 인증 통과 시에만 메인 허브 작동
if verifyKey() then
    print("[KamiHub] Loading ESP & Hub Features...")

    -- [0] Environment Cloak & Anti-Kick Script
    local GEN = (getgenv and getgenv()) or _G
    local HookFunction = GEN.hookfunction or hookfunction
    local NewCClosure = GEN.newcclosure or newcclosure
    local CheckCaller = GEN.checkcaller or checkcaller
    local GetCallingScript = GEN.getcallingscript or getcallingscript

    local MARKER = {
        hookfunction = true, hookmetamethod = true, newcclosure = true, clonefunction = true,
        checkcaller = true, getnamecallmethod = true, getcallingscript = true, isexecutorclosure = true,
        getgc = true, getreg = true, getrawmetatable = true, setreadonly = true, isreadonly = true,
        getconstants = true, getupvalues = true, getprotos = true, getgenv = true, getrenv = true,
        readfile = true, writefile = true, appendfile = true, loadfile = true, listfiles = true,
        makefolder = true, delfile = true, isfile = true, isfolder = true, setclipboard = true,
        request = true, http_request = true, Drawing = true, queue_on_teleport = true,
    }

    local function callerIsGame()
        if type(GetCallingScript) == "function" then
            local ok, scr = pcall(GetCallingScript)
            if ok and typeof(scr) == "Instance" then return true, scr end
        end
        if type(CheckCaller) == "function" then
            local ok, own = pcall(CheckCaller)
            if ok then return not own, nil end
        end
        return true, nil
    end

    pcall(function()
        local OriginalRawget = rawget
        HookFunction(rawget, NewCClosure(function(t, k)
            if callerIsGame() and type(k) == "string" and MARKER[k] then return nil end
            return OriginalRawget(t, k)
        end))
    end)

    pcall(function()
        local ok, kickMethod = pcall(function() return LocalPlayer.Kick end)
        if ok and type(kickMethod) == "function" then
            local OldKick
            OldKick = HookFunction(kickMethod, NewCClosure(function(self, ...)
                if callerIsGame() and self == LocalPlayer then return nil end
                return OldKick(self, ...)
            end))
        end
    end)


    -- [1] UI 및 ESP 설정
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    local ESPConfig = {
        Enabled = false,
        SkeletonEnabled = false,
        HealthBarEnabled = false,
        HealthNumberEnabled = false,
        SilentAimEnabled = false,
        Rainbow = false,
        Color = Color3.fromRGB(240, 240, 240),
    }

    local currentHue, currentSat, currentVal = 0, 0, 0.94

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KamiHubControlUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromOffset(220, 370)
    mainFrame.Position = UDim2.new(0.5, -110, 0.5, -185)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚙️ KamiHub Ultimate"
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize, titleLabel.Font = 13, Enum.Font.GothamBold
    titleLabel.Parent = mainFrame

    local dragging, dragInput, dragStart, startPos
    titleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    titleLabel.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function createToggle(name, yPos, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 36)
        button.Position = UDim2.fromOffset(10, yPos)
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = mainFrame

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = button

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.fromOffset(10, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.TextSize, label.Font = 12, Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button

        local statusIndicator = Instance.new("Frame")
        statusIndicator.Size = UDim2.fromOffset(24, 16)
        statusIndicator.AnchorPoint = Vector2.new(1, 0.5)
        statusIndicator.Position = UDim2.new(1, -10, 0.5, 0)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        statusIndicator.Parent = button

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(1, 0)
        sCorner.Parent = statusIndicator

        local state = false
        button.MouseButton1Click:Connect(function()
            state = not state
            statusIndicator.BackgroundColor3 = state and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(50, 50, 50)
            callback(state)
        end)
    end

    createToggle("Enable ESP", 45, function(v) ESPConfig.Enabled = v end)
    createToggle("Skeleton ESP", 90, function(v) ESPConfig.SkeletonEnabled = v end)
    createToggle("Health Bar", 135, function(v) ESPConfig.HealthBarEnabled = v end)
    createToggle("Health Number", 180, function(v) ESPConfig.HealthNumberEnabled = v end)
    createToggle("Silent Aim", 225, function(v) ESPConfig.SilentAimEnabled = v end)
    createToggle("Rainbow Colors", 270, function(v) ESPConfig.Rainbow = v end)

    local colorSwatchButton = Instance.new("TextButton")
    colorSwatchButton.Size = UDim2.new(1, -20, 0, 36)
    colorSwatchButton.Position = UDim2.fromOffset(10, 315)
    colorSwatchButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    colorSwatchButton.Text = ""
    colorSwatchButton.AutoButtonColor = false
    colorSwatchButton.Parent = mainFrame

    local csCorner = Instance.new("UICorner")
    csCorner.CornerRadius = UDim.new(0, 6)
    csCorner.Parent = colorSwatchButton

    local csLabel = Instance.new("TextLabel")
    csLabel.Size = UDim2.new(1, -50, 1, 0)
    csLabel.Position = UDim2.fromOffset(10, 0)
    csLabel.BackgroundTransparency = 1
    csLabel.Text = "ESP Color"
    csLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    csLabel.TextSize, csLabel.Font = 12, Enum.Font.GothamMedium
    csLabel.TextXAlignment = Enum.TextXAlignment.Left
    csLabel.Parent = colorSwatchButton

    local colorDisplay = Instance.new("Frame")
    colorDisplay.Size = UDim2.fromOffset(24, 16)
    colorDisplay.AnchorPoint = Vector2.new(1, 0.5)
    colorDisplay.Position = UDim2.new(1, -10, 0.5, 0)
    colorDisplay.BackgroundColor3 = ESPConfig.Color
    colorDisplay.Parent = colorSwatchButton

    local cdCorner = Instance.new("UICorner")
    cdCorner.CornerRadius = UDim.new(0, 4)
    cdCorner.Parent = colorDisplay

    -- 컬러 피커 창
    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.fromOffset(170, 150)
    pickerFrame.Position = UDim2.new(1, 10, 0, 0)
    pickerFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    pickerFrame.Visible = false
    pickerFrame.Parent = mainFrame

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 8)
    pCorner.Parent = pickerFrame

    local svBox = Instance.new("Frame")
    svBox.Size = UDim2.fromOffset(115, 126)
    svBox.Position = UDim2.fromOffset(12, 12)
    svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
    svBox.BorderSizePixel = 0
    svBox.Parent = pickerFrame

    local svCorner = Instance.new("UICorner")
    svCorner.CornerRadius = UDim.new(0, 4)
    svCorner.Parent = svBox

    local whiteGradient = Instance.new("UIGradient")
    whiteGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    whiteGradient.Parent = svBox

    local blackOverlay = Instance.new("Frame")
    blackOverlay.Size = UDim2.new(1, 0, 1, 0)
    blackOverlay.BackgroundTransparency = 0
    blackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackOverlay.BorderSizePixel = 0
    blackOverlay.Parent = svBox

    local boCorner = Instance.new("UICorner")
    boCorner.CornerRadius = UDim.new(0, 4)
    boCorner.Parent = blackOverlay

    local blackGradient = Instance.new("UIGradient")
    blackGradient.Rotation = 90
    blackGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    blackGradient.Parent = blackOverlay

    local svPointer = Instance.new("Frame")
    svPointer.Size = UDim2.fromOffset(10, 10)
    svPointer.AnchorPoint = Vector2.new(0.5, 0.5)
    svPointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    svPointer.BorderSizePixel = 0
    svPointer.Parent = svBox

    local svpCorner = Instance.new("UICorner")
    svpCorner.CornerRadius = UDim.new(1, 0)
    svpCorner.Parent = svPointer

    local svpStroke = Instance.new("UIStroke")
    svpStroke.Color = Color3.fromRGB(0, 0, 0)
    svpStroke.Thickness = 1.5
    svpStroke.Parent = svPointer

    local hueSlider = Instance.new("Frame")
    hueSlider.Size = UDim2.fromOffset(18, 126)
    hueSlider.Position = UDim2.fromOffset(139, 12)
    hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueSlider.BorderSizePixel = 0
    hueSlider.Parent = pickerFrame

    local hsCorner = Instance.new("UICorner")
    hsCorner.CornerRadius = UDim.new(0, 4)
    hsCorner.Parent = hueSlider

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Rotation = 90
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
    })
    hueGradient.Parent = hueSlider

    local huePointer = Instance.new("Frame")
    huePointer.Size = UDim2.new(1, 4, 0, 6)
    huePointer.AnchorPoint = Vector2.new(0.5, 0.5)
    huePointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    huePointer.Parent = hueSlider

    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(1, 0)
    hpCorner.Parent = huePointer

    local hpStroke = Instance.new("UIStroke")
    hpStroke.Color = Color3.fromRGB(0, 0, 0)
    hpStroke.Thickness = 1.5
    hpStroke.Parent = huePointer

    local function updateUIFromValues()
        ESPConfig.Color = Color3.fromHSV(currentHue, currentSat, currentVal)
        colorDisplay.BackgroundColor3 = ESPConfig.Color
        svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)

        svPointer.Position = UDim2.new(currentSat, 0, 1 - currentVal, 0)
        huePointer.Position = UDim2.new(0.5, 0, currentHue, 0)
    end

    updateUIFromValues()

    local pickingSV, pickingHue = false, false

    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickingSV = true
        end
    end)

    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickingHue = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickingSV = false
            pickingHue = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UserInputService:GetMouseLocation()
            if pickingSV then
                local absPos = svBox.AbsolutePosition
                local absSize = svBox.AbsoluteSize
                currentSat = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
                local correctedSVY = (mousePos.Y - absPos.Y) - 60
                currentVal = math.clamp(1 - (correctedSVY / absSize.Y), 0, 1)
                updateUIFromValues()
            elseif pickingHue then
                local absPos = hueSlider.AbsolutePosition
                local absSize = hueSlider.AbsoluteSize
                local correctedY = (mousePos.Y - absPos.Y) - 60
                currentHue = math.clamp(correctedY / absSize.Y, 0, 1)
                updateUIFromValues()
            end
        end
    end)

    local pickerOpen = false
    colorSwatchButton.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        pickerFrame.Visible = pickerOpen
    end)

    -- ESP 렌더링 루프
    local function setupPlayerESP(player)
        if player == LocalPlayer then return end

        local box = Drawing.new("Square")
        box.Visible = false; box.Thickness = 1.5; box.Filled = false; box.Transparency = 0.9

        local healthBarBg = Drawing.new("Square")
        healthBarBg.Visible = false; healthBarBg.Filled = true; healthBarBg.Color = Color3.fromRGB(0, 0, 0); healthBarBg.Transparency = 0.7

        local healthBar = Drawing.new("Square")
        healthBar.Visible = false; healthBar.Filled = true; healthBar.Transparency = 0.9

        local healthText = Drawing.new("Text")
        healthText.Visible = false; healthText.Size = 11; healthText.Center = false; healthText.Outline = true; healthText.Font = 2

        local skeletonLines = {}
        for i = 1, 15 do
            local line = Drawing.new("Line")
            line.Visible = false; line.Thickness = 1.2; line.Transparency = 0.9
            table.insert(skeletonLines, line)
        end

        local R6_BONE_PAIRS = {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
        }
        local R15_BONE_PAIRS = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }

        local connection
        connection = RunService.RenderStepped:Connect(function()
            local currentColor = ESPConfig.Rainbow and Color3.fromHSV((os.clock() * 0.12) % 1, 0.45, 1) or ESPConfig.Color
            local char = player.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not rootPart or not humanoid or humanoid.Health <= 0 then
                box.Visible = false; healthBarBg.Visible = false; healthBar.Visible = false; healthText.Visible = false
                for _, line in ipairs(skeletonLines) do line.Visible = false end
                return
            end

            local head = char:FindFirstChild("Head") or rootPart
            local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

            if onScreen and vector.Z > 0 then
                local headPoint = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPoint = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                local height = math.abs(headPoint.Y - legPoint.Y)
                local width = height * 0.6
                local boxPos = Vector2.new(vector.X - width / 2, headPoint.Y)

                if ESPConfig.Enabled then
                    box.Size = Vector2.new(width, height)
                    box.Position = boxPos
                    box.Color = currentColor
                    box.Visible = true
                else
                    box.Visible = false
                end

                if ESPConfig.HealthBarEnabled then
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barHeight = height * healthPercent
                    healthBarBg.Size = Vector2.new(3, height + 2)
                    healthBarBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y - 1)
                    healthBarBg.Visible = true

                    healthBar.Size = Vector2.new(1, barHeight)
                    healthBar.Color = Color3.fromRGB(255 - (healthPercent * 255), healthPercent * 255, 0)
                    healthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (height - barHeight))
                    healthBar.Visible = true
                else
                    healthBarBg.Visible = false
                    healthBar.Visible = false
                end

                if ESPConfig.HealthNumberEnabled then
                    healthText.Text = math.floor(humanoid.Health) .. " HP"
                    healthText.Position = Vector2.new(boxPos.X - 38, boxPos.Y - 2)
                    healthText.Color = Color3.fromRGB(240, 240, 240)
                    healthText.Visible = true
                else
                    healthText.Visible = false
                end
            else
                box.Visible = false; healthBarBg.Visible = false; healthBar.Visible = false; healthText.Visible = false
            end

            if not ESPConfig.SkeletonEnabled then
                for _, line in ipairs(skeletonLines) do line.Visible = false end
            else
                local pairsList = humanoid.RigType == Enum.HumanoidRigType.R15 and R15_BONE_PAIRS or R6_BONE_PAIRS
                local lineIdx = 1
                for _, bonePair in ipairs(pairsList) do
                    local partA = char:FindFirstChild(bonePair[1])
                    local partB = char:FindFirstChild(bonePair[2])
                    local line = skeletonLines[lineIdx]
                    if partA and partB and line then
                        local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
                        local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)
                        if (onScreenA or onScreenB) and posA.Z > 0 and posB.Z > 0 then
                            line.From = Vector2.new(posA.X, posA.Y)
                            line.To = Vector2.new(posB.X, posB.Y)
                            line.Color = currentColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    elseif line then
                        line.Visible = false
                    end
                    lineIdx = lineIdx + 1
                end
                for i = lineIdx, #skeletonLines do
                    if skeletonLines[i] then skeletonLines[i].Visible = false end
                end
            end
        end)

        player.AncestryChanged:Connect(function(_, parent)
            if not parent then
                connection:Disconnect()
                box:Remove(); healthBarBg:Remove(); healthBar:Remove(); healthText:Remove()
                for _, line in ipairs(skeletonLines) do pcall(function() line:Remove() end) end
            end
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do task.spawn(setupPlayerESP, p) end
    Players.PlayerAdded:Connect(setupPlayerESP)


    -- [2] 스킨 체인저 및 Silent Aim 로직 (비동기 실행)
    task.spawn(function()
        pcall(function()
            local _rs = game:GetService("ReplicatedStorage")
            local _http = game:GetService("HttpService")
            local _mods = _rs:WaitForChild("Modules", 10)
            if not _mods then return end

            local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
            if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

            local _cosLib = require(_mods:WaitForChild("CosmeticLibrary", 10))
            local _ctrl = LocalPlayer.PlayerScripts.Controllers
            local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

            local _eq, _favs = {}, {}
            local _cfgFile = "rivals_unlocker_config.json"

            local function _mkCosmetic(nm, ctype, opts)
                local _base = _cosLib.Cosmetics[nm]
                if not _base then return nil end
                local _d = {}
                for k, v in pairs(_base) do _d[k] = v end
                _d.Name = nm; _d.Type = _d.Type or ctype; _d.Seed = math.random(1, 1000000)
                if _enumLib then
                    local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
                    if _s and _eid then _d.Enum = _eid; _d.ObjectID = _eid end
                end
                if opts then
                    if opts.inverted ~= nil then _d.Inverted = opts.inverted end
                    if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
                end
                return _d
            end

            local function _loadCfg()
                if not isfile or not readfile then return end
                local ok, raw = pcall(readfile, _cfgFile)
                if ok and raw and raw ~= "" then
                    local s, dec = pcall(_http.JSONDecode, _http, raw)
                    if s and dec and dec.equipped then
                        for wn, cos in pairs(dec.equipped) do
                            _eq[wn] = {}
                            for ct, sd in pairs(cos) do
                                if sd and sd.Name and _cosLib.Cosmetics[sd.Name] then
                                    _eq[wn][ct] = _mkCosmetic(sd.Name, ct, { inverted = sd.Inverted, favoritesOnly = sd.OnlyUseFavorites })
                                end
                            end
                            if not next(_eq[wn]) then _eq[wn] = nil end
                        end
                    end
                end
            end
            pcall(_loadCfg)

            local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
            local function _isCosType(cosObj)
                if not cosObj then return false end
                for _, t in ipairs(_cosTypes) do if cosObj.Type == t then return true end end
                return false
            end

            _cosLib.OwnsCosmeticNormally = function() return true end
            _cosLib.OwnsCosmeticUniversally = function() return true end
            _cosLib.OwnsCosmeticForWeapon = function() return true end

            local _origOwns = _cosLib.OwnsCosmetic
            _cosLib.OwnsCosmetic = function(self, inv, nm, wep)
                if nm:find("MISSING_") or nm == "Bubble Gun" then return _origOwns(self, inv, nm, wep) end
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then return true end
                return _origOwns(self, inv, nm, wep)
            end

            local _origGet = _datCtrl.Get
            _datCtrl.Get = function(self, key)
                local _val = _origGet(self, key)
                if key == "CosmeticInventory" then
                    local _prx = {}
                    if _val then
                        for k, v in pairs(_val) do
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then _prx[k] = v end
                        end
                    end
                    return setmetatable(_prx, {
                        __index = function(t, k)
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then return true end
                            return nil
                        end
                    })
                end
                return _val
            end

            local _origGetWep = _datCtrl.GetWeaponData
            _datCtrl.GetWeaponData = function(self, wn)
                local _d = _origGetWep(self, wn)
                if not _d then return nil end
                local _m = {}
                for k, v in pairs(_d) do _m[k] = v end
                _m.Name = wn
                if _eq[wn] then for ct, cd in pairs(_eq[wn]) do _m[ct] = cd end end
                return _m
            end

            -- Silent Aim Raycast 훅 연결
            local util = require(_rs.Modules.Utility)
            local old_ray = util.Raycast
            util.Raycast = function(s, o, d, len, f, ft, viz)
                if ESPConfig and ESPConfig.SilentAimEnabled then
                    if len == 999 and len > 100 and f then
                        local ents = {}
                        for _, v in pairs(workspace:GetChildren()) do
                            if v:FindFirstChildOfClass("Humanoid") then table.insert(ents, v) end
                        end
                        local best, dist = nil, 99999
                        local scr = Camera.ViewportSize / 2
                        for _, v in pairs(ents) do
                            if v ~= LocalPlayer and v:FindFirstChild("HumanoidRootPart") then
                                local pos, vis = Camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
                                if vis and pos.Z > 0 then
                                    local dval = (Vector2.new(pos.X, pos.Y) - scr).Magnitude
                                    if dval < dist then best = v; dist = dval end
                                end
                            end
                        end
                        if best and best:FindFirstChild("Head") then
                            local hitpos = best.Head.Position
                            return {
                                Position = hitpos,
                                Distance = (hitpos - o).Magnitude,
                                Instance = best.Head,
                                Material = best.Head.Material,
                                Normal = Vector3.yAxis
                            }
                        end
                    end
                end
                return old_ray(s, o, d, len, f, ft, viz)
            end
        end)
    end
end
