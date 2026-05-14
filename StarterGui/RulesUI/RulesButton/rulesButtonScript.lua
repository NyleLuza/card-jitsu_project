-- @ScriptType: LocalScript
local helpButton = script.Parent
local RulesFrame = helpButton.Parent:WaitForChild("RulesFrame")

helpButton.MouseButton1Click:Connect(function()
	RulesFrame.Visible = not RulesFrame.Visible
end)

local UserInputService = game:GetService("UserInputService")

-- Function to handle key presses
local function onKeyPress(input)
	if input.KeyCode == Enum.KeyCode.H then -- Change 'X' to your desired key (e.g., Enum.KeyCode.M)
		-- Toggle the visibility of the menu frame
		RulesFrame.Visible = not RulesFrame.Visible
	end
end

-- Connect the function to the InputBegan event
UserInputService.InputBegan:Connect(onKeyPress)