-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shopFolder = workspace:WaitForChild("Dojo"):WaitForChild("Shop")
local openShopEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShopAction") -- Allows communication between server and client

local shop = shopFolder:WaitForChild("shopModel")  -- Allows shop to be reused

-- Create instance of shop and place on workspace
--local shop = shopTemplate:Clone()
--shop.Parent = workspace

local prompt = shop:WaitForChild("MainPart"):WaitForChild("ProximityPrompt")


prompt.Triggered:Connect(function(player)
	print("Server: " .. player.Name .. " clicked the shop")
	-- sends an event to the client to open their shop GUI
	openShopEvent:FireClient(player)
	

end)