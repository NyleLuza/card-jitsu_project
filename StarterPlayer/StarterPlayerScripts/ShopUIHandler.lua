-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShopAction")
local ShopUtils = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("ShopUtils"))
local Shop = nil
local UIS = game:GetService("UserInputService")
local rs = game:GetService("RunService")

-- init perspective
-- UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
-- UIS.MouseIconEnabled = false

-- controls camera perspective
local function UpdateMouse()
	-- if Shop == nil then
	-- 	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	-- 	UIS.MouseIconEnabled = false
	-- else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	-- end
end

ShopEvent.OnClientEvent:Connect(function(...)
	-- checks to make sure there is only one instance of a shop
	if Shop == nil then
		Shop = ShopUtils.OpenShop()
		UpdateMouse()
	end
	
	-- exit function
	local exit = Shop:WaitForChild("MainFrame"):WaitForChild("ExitButton")
	exit.MouseButton1Click:Connect(function()
	ShopUtils.CloseShop(Shop)
	
	-- update Shop status after closing
	Shop = nil
	UpdateMouse()
	end)
end)
