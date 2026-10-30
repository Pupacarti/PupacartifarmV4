local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local scriptActive = true
local aiming = false

-- 1. ฟังก์ชันหา NPC/ซอมบี้ที่ใกล้ที่สุด
local function getClosestNPC()
    local closestNPC = nil
    local shortestDistance = math.huge

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
            -- ต้องไม่ใช่ตัวละครของผู้เล่น
            if not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
                if obj.Humanoid.Health > 0 then
                    local headPosition, onScreen = Camera:WorldToViewportPoint(obj.Head.Position)
                    if onScreen then
                        local mouseLocation = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(headPosition.X, headPosition.Y) - mouseLocation).Magnitude

                        if distance < shortestDistance then
                            closestNPC = obj
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestNPC
end

-- 2. ฟังก์ชันยิงปืน (สั่งกดใช้ Tool ที่ถืออยู่)
local function autoShoot()
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate() -- สั่งยิงปืนทันที
        end
    end
end

-- 3. ระบบตรวจจับการกดคลิกขวาค้างเพื่อเล็ง
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- 4. รันระบบล็อกหัวและยิงทุกเฟรม
RunService.RenderStepped:Connect(function()
    if scriptActive and aiming then
        local target = getClosestNPC()
        if target and target:FindFirstChild("Head") then
            -- ล็อกกล้องไปที่หัว
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Head.Position)
            -- สั่งยิงอัตโนมัติ
            autoShoot()
        end
    end
end)

-- 5. ระบบตรวจจับและกด E อัตโนมัติ (ProximityPrompt)
task.spawn(function()
    while task.wait(0.05) do
        if scriptActive then
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
                        -- ตรวจสอบว่าอยู่ในระยะที่สามารถกดได้หรือไม่
                        if distance <= prompt.MaxActivationDistance then
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration)
                                prompt:InputHoldEnd()
                            end
                        end
                    end
                end
            end
        end
    end
end)
