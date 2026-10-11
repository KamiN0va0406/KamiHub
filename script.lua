local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

print("[ Kami Hub ] 라이선스 인증 완료! 스크립트를 로드합니다.")

-- [ 설정 ]
local Y_OFFSET = 2 
local BIND_KEY = Enum.KeyCode.E 
local targetPool = {} 
local isToggled = false
local originalPos = nil
local loopConnection = nil

-- [ UI 생성 ]
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AutoSwitchTargetUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("ScrollingFrame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 350)
MainFrame.Position = UDim2.new(1, -220, 0.5, -175) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.4
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 4
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", MainFrame)
UIList.Padding = UDim.new(0, 6)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- [ 로직: 가장 가까운 '살아있는' 타겟 찾기 ]
local function getClosestLivingTarget()
    local closestTarget, minDist = nil, math.huge
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    for player, isSelected in pairs(targetPool) do
        if isSelected and player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetHrp and hum and hum.Health > 0 then
                local dist = (targetHrp.Position - myHrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestTarget = targetHrp
                end
            end
        end
    end
    return closestTarget
end

-- 플레이어 목록 UI 업데이트
local function refreshPlayerList()
    for _, item in pairs(MainFrame:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", MainFrame)
            btn.Size = UDim2.new(0.9, 0, 0, 32)
            btn.Text = p.DisplayName
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            
            if targetPool[p] then
                btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
                btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end

            btn.MouseButton1Click:Connect(function()
                targetPool[p] = not targetPool[p]
                refreshPlayerList() 
            end)
        end
    end
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function(p)
    targetPool[p] = nil
    refreshPlayerList()
end)
refreshPlayerList()

-- [ 텔레포트 실행 로직 ]
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == BIND_KEY then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            isToggled = true
            originalPos = hrp.CFrame
            
            if loopConnection then loopConnection:Disconnect() end
            loopConnection = RS.Heartbeat:Connect(function()
                if isToggled then
                    local targetHrp = getClosestLivingTarget()
                    if targetHrp then
                        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, Y_OFFSET, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == BIND_KEY then
        isToggled = false
        if loopConnection then loopConnection:Disconnect() end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and originalPos then
            hrp.CFrame = originalPos
            originalPos = nil
        end
    end
end)
