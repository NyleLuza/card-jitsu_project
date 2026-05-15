-- @ScriptType: ModuleScript
-- cloud that saves existing player data
local DataStoreService = game:GetService("DataStoreService")
local InventoryStore = DataStoreService:GetDataStore("PlayerInventoryData")

local InventoryService = {}

local playerInventories = {}


-- initialization
function InventoryService.InitPlayer(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return InventoryStore:GetAsync(userId)
	end)
	print("GetAsync success:", success, data)
	
	if success and data then
		playerInventories[userId] = data
		print("Loaded data for", player.Name, data)
	elseif not success then
		warn("Failed to load inventory for", player.Name, data)
		data.Decks = data.Decks or {}
	else
		-- Default structure if no data exists
		playerInventories[userId] = {
			Items = {Packs = {}, Cards = {}, Decks = {}},
			Bux = 0,
			Decks = {},
		}
	end
end

function InventoryService.RemovePlayer(player)
	local userId = player.UserId
	local data = playerInventories[userId]
	print("Exiting data with:", data)
	if data then
		local success, err = pcall(function()
			InventoryStore:SetAsync(userId, data)
		end)
		print("SetAsync ok:", success, "err:", err)

		if not success then
			warn("Failed to save inventory for", player.Name, err)
		end
	end

	-- removes player's inventory from memory
	playerInventories[userId] = nil

	
end

function InventoryService.AddItem(player, item, type)
	local inventory = playerInventories[player.UserId]
	if type == "Pack" then
		table.insert(inventory.Items["Packs"], item)
	elseif type == "Card" then
		table.insert(inventory.Items["Cards"], item)
	end
	print(inventory.Items)
	
end

function InventoryService.GetInventory(player, Type)
	return playerInventories[player.UserId].Items
end

function InventoryService.RemovePack(player, PackName)
	for i, v in pairs(playerInventories[player.UserId].Items["Packs"]) do
		if v == PackName then
			table.remove(playerInventories[player.UserId].Items["Packs"], i)
		end
	end
	return playerInventories[player.UserId].Items
end

function InventoryService.GetDeck(player, deckId)
	local inventory = playerInventories[player.UserId]
	if not inventory then
		return {}
	end

	inventory.Decks = inventory.Decks or {}
	print("Current Inv Deck: ", inventory.Decks)
	return inventory.Decks[tostring(deckId)] or {}
end
	


function InventoryService.SaveDeck(player, deckId, deckList)
	local inventory = playerInventories[player.UserId]
	if not inventory then
		return false, "No inventory loaded"
	end

	inventory.Decks = inventory.Decks or {}
	inventory.Decks[tostring(deckId)] = deckList

	return true, "Deck saved"
end

function InventoryService.ResetPlayerData(player)
	local userId = player.UserId

	local defaultData = {
		Items = {Packs = {}, Cards = {}},
		Bux = 0,
		Decks = {},
	}

	-- Reset in memory
	playerInventories[userId] = defaultData

	-- Save to DataStore
	local success, err = pcall(function()
		InventoryStore:SetAsync(userId, defaultData)
	end)

	if success then
		print("Player data reset for", player.Name)
	else
		warn("Failed to reset player data:", err)
	end
end

return InventoryService
