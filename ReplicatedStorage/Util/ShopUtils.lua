-- @ScriptType: ModuleScript
local ShopUtils = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local BuyItemEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyItem")
local shopUI = nil

function ShopUtils.OpenShop()
	--print("here")
	shopUI = ReplicatedStorage:WaitForChild("UI"):WaitForChild("ShopUI"):Clone()
	shopUI.Parent = PlayerGui
	return shopUI
end

function ShopUtils.CloseShop(Shop)
	Shop.Enabled = false
	
end

-- pass Pack name to store in inventory
function ShopUtils.BuyItem(PackName)
	print("You just purchased ", PackName)
	-- InventoryUtils.AddToInventory(Pack, player)
	BuyItemEvent:FireServer(PackName)
	
end
return ShopUtils
