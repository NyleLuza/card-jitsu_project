-- @ScriptType: Script
--[[
TODO: Create function to retrieve a pack from a user's inventory and randomly pull a card to then place in user's inventory 
]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuyItemEvent = ReplicatedStorage.RemoteEvents.BuyItem
local InventoryService = require(script.Parent.InventoryService)
local GetInventoryEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetInventory")
local SendInventoryEvent  = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SendInventory")
local RequestOpenPack = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestOpenPack")
local RemovePackEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RemovePackEvent")
local Series1 = require(ReplicatedStorage:WaitForChild("Packs"):WaitForChild("Series1"))


local Players = game:GetService("Players")


-- connects user to their saved inventory
Players.PlayerAdded:Connect(function(player)
	print("InitPlayer:", player.Name)
	InventoryService.InitPlayer(player)
	-- TEMP RESET
	--[[
	if player.Name == "GizzToast" then
		InventoryService.ResetPlayerData(player)
	end
	]]--
end)
 -- Players.Backpack:ClearAllChildren()
-- removes players inventory from memory when they exit the game
Players.PlayerRemoving:Connect(function(player)
	print("removing player")
	InventoryService.RemovePlayer(player)
end)

-- Adding item to user's inventory
BuyItemEvent.OnServerEvent:Connect(function(player, PackName)
	-- Pack name is the value that is passed in because we just want to store the name and not the object
	print(player.Name .. " is purchasing " .. PackName)

	InventoryService.AddItem(player, PackName, "Pack")

	print("Added to " .. player.Name .. "'s inventory.")
end)

-- Makes request to obtain user's inventory
GetInventoryEvent.OnServerEvent:Connect(function(player)
	print("Received inventory request for " .. player.Name)
	local inventory = InventoryService.GetInventory(player, "Packs")
	print(inventory)
	SendInventoryEvent:FireClient(player, inventory)
	print("Sent inventory data for " .. player.Name)
end)

function bisect_left(totals, r)
	local left = 1
	local right = #totals

	while left <= right do
		local mid = math.floor((left + right) / 2)

		if totals[mid] < r then
			left = mid + 1
		else
			right = mid - 1
		end
	end

	return left
end


local Pack = require(ReplicatedStorage.Packs.Series1)
local Card = require(ReplicatedStorage.Cards.CardConfig)
local WeightsArray={}
local PrefixSumArray={}
local RunningTotal = 0
math.randomseed(os.time())

-- Generate a random integer between 1 and 100 (inclusive)
local randomNumber
-- Opens Pack and adds card to user's inventory
RequestOpenPack.OnServerEvent:Connect(function(player, PackName)
	local weightsArray = {}
	local prefixSumArray = {}
	local runningTotal = 0

	for _, item in ipairs(Pack[PackName].cards) do
		local weight = Card[item].weight
		runningTotal += weight
		table.insert(prefixSumArray, runningTotal)
	end

	local randomNumber = math.random() * runningTotal
	local index = bisect_left(prefixSumArray, randomNumber)
	local chosenCard = Pack[PackName].cards[index]

	print("Chosen card:", index, chosenCard)

	InventoryService.AddItem(player, chosenCard, "Card")

	local updatedCards = InventoryService.GetInventory(player)
	SendInventoryEvent:FireClient(player, updatedCards)

	local updatedPacks = InventoryService.RemovePack(player, PackName)
	SendInventoryEvent:FireClient(player, updatedPacks)
end)

