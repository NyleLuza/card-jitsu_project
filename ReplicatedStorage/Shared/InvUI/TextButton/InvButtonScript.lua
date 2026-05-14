-- @ScriptType: LocalScript
local invButton = script.Parent
local Inventory = invButton.Parent:WaitForChild("Inventory")

invButton.MouseButton1Click:Connect(function()
	Inventory.Visible = not Inventory.Visible
end)
