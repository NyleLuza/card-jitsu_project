-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShopAction")
local ClickUtils = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("ClickUtils"))

ShopEvent.OnClientEvent:Connect(function(...)
	local Shop = ClickUtils.OpenShop()
	local exit = Shop:WaitForChild("MainFrame"):WaitForChild("ExitButton")
	exit.MouseButton1Click:Connect(function()
	ClickUtils.CloseShop(Shop)
	end)
end)
