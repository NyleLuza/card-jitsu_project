-- @ScriptType: LocalScript
local UserInputService = game:GetService("UserInputService")
local Inventory = script.Parent -- Reference to your frame

-- Function to handle key presses
local function onKeyPress(input)
	if input.KeyCode == Enum.KeyCode.T then -- Change 'X' to your desired key (e.g., Enum.KeyCode.M)
		-- Toggle the visibility of the menu frame
		Inventory.Visible = not Inventory.Visible
	end
end

-- Connect the function to the InputBegan event
UserInputService.InputBegan:Connect(onKeyPress)


