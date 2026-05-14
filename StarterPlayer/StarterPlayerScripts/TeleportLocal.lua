-- @ScriptType: Script
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local battlePlaceId = 98599794487468
local teleportPart = workspace:WaitForChild("Teleport Pad")

-- Create the custom teleport GUI (pretending this still works)
local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold
label.TextColor3 = Color3.new(1,1,1)
label.Text = "Travelling to the Battle Arena"
label.Parent = screenGui

screenGui.Parent = player:WaitForChild("PlayerGui")

TeleportService:SetTeleportGui(screenGui)


-- Detect touching the part (client-side)
teleportPart.Touched:Connect(function(hit)
	if hit.Parent == player.Character then
		TeleportService:Teleport(battlePlaceId, player)
	end
end)
