-- @ScriptType: Script
game.Players.PlayerAdded:Connect(function(player)
	-- Create the leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create the Cash stat
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0 -- starting cash
	cash.Parent = leaderstats
end)
