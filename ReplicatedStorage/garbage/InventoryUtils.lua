-- @ScriptType: ModuleScript
local InventoryUtils = {}
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local InventoryTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("InventoryUI"):Clone()
local Inventory = nil
-- track inventory status
local IsOpen = false
local data = DataStore:GetAsync(player.UserId)

function InventoryUtils.AddToInventory(Pack)
	
end
return InventoryUtils
