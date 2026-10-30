local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local scriptActive = true
local aiming = false

-- 1. ฟังก์ชันหาหัว NPC/ซอมบี้ที่ใกล้เป้าเมาส์ที่สุด
local function getClosestNPC()
    local closest = nil
    local shortestDistance = math.huge

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
            if not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
                if obj.Humanoid.Health > 0 then
                    local headPos, onScreen = Camera:WorldToViewportPoint(obj.Head.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
                        if dist < shortestDistance then
                            closest = obj
                            shortestDistance = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- 2. ดักจับการกดคลิกขวาเพื่อเล็ง
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

-- 3. รันการล็อกหัวและจำลองการคลิกซ้ายเพื่อยิง
RunService.RenderStepped:Connect(function()
    if scriptActive and aiming then
        local target = getClosestNPC()
        if target and target:FindFirstChild("Head") then
            -- ล็อกเป้ากล้องไปที่หัว
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Head.Position)
            
            -- จำลองการกดคลิกซ้าย (MouseButton1) เพื่อสั่งยิงปืนทุกชนิด
            local mousePos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
        end
    end
end)

-- 4. รันระบบจำลองการกดปุ่ม E อัตโนมัติทุกๆ 0.2 วินาที
task.spawn(function()
    while task.wait(0.2) do
        if scriptActive then
            -- จำลองการกดปุ่ม E บนคีย์บอร์ดโดยตรง
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end
end)
