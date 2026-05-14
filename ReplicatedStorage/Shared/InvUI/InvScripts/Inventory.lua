-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer.PlayerGui
local GUI = playerGui:WaitForChild("InvUI")
local invTemplate = GUI.templates:WaitForChild("InventoryTemplate")

local invScroll = GUI.Inventory.Scroll
local itemData = require(script.ItemData)
local getInventoryFunction = RS:WaitForChild("RemoteFunctions"):WaitForChild("GetInventory")
local playerItems = getInventoryFunction:InvokeServer()