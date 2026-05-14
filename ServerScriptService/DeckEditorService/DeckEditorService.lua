-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryService = require(game.ServerScriptService.InventoryHandler.InventoryService)
local GetInventory = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetInventoryItems")


local SaveDeck = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SaveDeck")

GetInventory.OnServerEvent:Connect(function(player, deckId)
	print("SERVER GOT DECK INVENTORY REQUEST")
	local items = InventoryService.GetInventory(player)
	local savedDeck = InventoryService.GetDeck(player, deckId)
	
	GetInventory:FireClient(player, items.Cards or {}, savedDeck or {})
end)

SaveDeck.OnServerEvent:Connect(function(player, deckId, deckList)
	local success, message = InventoryService.SaveDeck(player, deckId, deckList)
	SaveDeck:FireClient(player, success, message)
end)
