-- Roblox Kami & Rivals Script (Key System + Clean UI)
local input_key = (type(script_key) == "string" and script_key) or "Unknown"

-- [1] AC Bypass & Core Function
local _stbl; _stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
    if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
        local tr = debug.traceback()
        if tr:find("MiscellaneousController") then
            return _stbl({1,2,3}, {})
        end
    end
    return _stbl(tbl, mt)
end))

coroutine.wrap(function()
    pcall(function()
        local function _proc(o)
            pcall(function()
                if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                    local _s, nm = pcall(function() return o.Name:lower() end)
                    if not _s or not nm then return end
                    local _tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
                    for _i = 1, #_tags do
                        if nm:find(_tags[_i]) then
                            pcall(function() o.Disabled = true end)
                            break
                        end
                    end
                end
            end)
        end
        pcall(function()
            local _desc = game:GetDescendants()
            for _i = 1, #_desc do _proc(_desc[_i]) end
        end)
        pcall(function() game.DescendantAdded:Connect(_proc) end)
    end)
end)()

task.wait(2)

-- 기능 상태 변수
local Config = {
    SkinUnlock = false,
    Aimbot = false
}

-- [2] Skin Unlocker Logic
local _plrs    = game:GetService("Players")
local _rs      = game:GetService("ReplicatedStorage")
local _lp      = _plrs.LocalPlayer
local _pscripts = _lp.PlayerScripts
local _ctrl    = _pscripts.Controllers
local _mods    = _rs:WaitForChild("Modules", 10)

local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
local function _isCosType(cosObj)
    if not cosObj then return false end
    for _, t in ipairs(_cosTypes) do
        if cosObj.Type == t then return true end
    end
    return false
end

_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
    if not Config.SkinUnlock then return false end
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end

local _origGet = _datCtrl.Get
_datCtrl.Get = function(self, key)
    local _val = _origGet(self, key)
    if key == "CosmeticInventory" and Config.SkinUnlock then
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

-- [3] Aimbot Logic
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CurrentTarget

pcall(function()
    local FighterController = require(_ctrl:WaitForChild("FighterController", 10))
    local LocalFighter = FighterController.LocalFighter
    local Old = LocalFighter.GetMouseLocation
    LocalFighter.GetMouseLocation = newcclosure(function(...)
        if Config.Aimbot and CurrentTarget then
            local ScreenPosition = Camera:WorldToScreenPoint(CurrentTarget.Position)
            return Vector2.new(ScreenPosition.X, ScreenPosition.Y)
        end
        return Old(...)
    end)
end)

RunService.RenderStepped:Connect(function()
    if not Config.Aimbot then
        CurrentTarget = nil
        return
    end

    local PlayerCharacter = _lp.Character
    if not PlayerCharacter then
        CurrentTarget = nil
        return
    end

    local CameraPosition = Camera.CFrame.Position
    local CameraLookVector = Camera.CFrame.LookVector
    CurrentTarget = nil
    local ClosestDistance = math.huge

    for _, OtherPlayer in ipairs(_plrs:GetPlayers()) do
        if OtherPlayer == _lp then continue end
        local TargetCharacter = OtherPlayer.Character
        if not TargetCharacter then continue end
        local TargetHumanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")
        if not TargetHumanoid or TargetHumanoid.Health <= 0 then continue end
        if TargetCharacter:FindFirstChildOfClass("ForceField") then continue end
        local TargetHead = TargetCharacter:FindFirstChild("Head")
        if not TargetHead then continue end

        local HeadPosition = TargetHead.Position
        local ScreenPosition, IsOnScreen = Camera:WorldToViewportPoint(HeadPosition)
        if IsOnScreen then
            local ScreenVector = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            local DistanceFromCenter = (ScreenVector - UserInputService:GetMouseLocation()).Magnitude
            if DistanceFromCenter <= 300 and DistanceFromCenter < ClosestDistance then
                local DirectionToTarget = (HeadPosition - CameraPosition).Unit
                if CameraLookVector:Dot(DirectionToTarget) > 0 then
                    ClosestDistance = DistanceFromCenter
                    CurrentTarget = TargetHead
                end
            end
        end
    end
end)

-- [4] Clean Toggle UI (버튼 2개 최적화 패널)
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("KamiSimpleUI") then
    CoreGui.KamiSimpleUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KamiSimpleUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "💜 Roblox Kami Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(100, 65, 165)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Text = name .. ": OFF"
        end
        pcall(function()
            callback(state)
        end)
    end)
end

createToggle("Skin Unlock", 40, function(enabled)
    Config.SkinUnlock = enabled
end)

createToggle("Aimbot", 85, function(enabled)
    Config.Aimbot = enabled
end)
