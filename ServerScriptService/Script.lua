-- @ScriptType: Script
local function hideName(humanoid)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end

for _, obj in pairs(workspace:GetDescendants()) do
	if obj:IsA("Humanoid") then
		hideName(obj)
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Humanoid") then
		hideName(obj)
	end
end)