local UIS = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
mouse.TargetFilter = workspace.IgnoreList


local TARGETCLONE = workspace.TARGET:Clone()
TARGETCLONE.Parent = workspace.IgnoreList
TARGETCLONE.Transparency = 0.6

local desiredHeight = 10

local function onInputBegan(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.F then
        game:GetService("ReplicatedStorage").UpdateCFrame:FireServer(TARGETCLONE.CFrame)
    elseif input.KeyCode == Enum.KeyCode.V then
        print(TARGETCLONE.CFrame)
        while UIS:IsKeyDown(Enum.KeyCode.V) do
            desiredHeight = desiredHeight + 4
            task.wait()
        end
    elseif input.KeyCode == Enum.KeyCode.C then
        while UIS:IsKeyDown(Enum.KeyCode.C) do
            desiredHeight = desiredHeight - 4
            task.wait()
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        while UIS:IsKeyDown(Enum.KeyCode.R) do
            TARGETCLONE.CFrame = TARGETCLONE.CFrame * CFrame.Angles(0, math.rad(4), 0)
            task.wait()
        end
    end
end

UIS.InputBegan:Connect(onInputBegan)

game:GetService("RunService").RenderStepped:Connect(function()
    TARGETCLONE.Position = Vector3.new(mouse.Hit.Position.X, desiredHeight, mouse.Hit.Position.Z)
end)


