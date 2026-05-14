-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopUtils = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("ShopUtils"))
local CardTemplate = script.Parent.CardTemplate -- moves up the hierarchy

-- Folder where Packs lie in
local Series1 = require(ReplicatedStorage:WaitForChild("Packs").Series1)

-- init array of packs 
local PackPool = {
}
print(Series1)
--[[
-- iterates through each Pack in the series
for _, pack in pairs(Series:GetChildren()) do
	-- need require function to allow module script to return card object
	local PackData = require(pack)
	--print(PackData)
	table.insert(PackPool, PackData)
end
--]]
local CurrentPositionY = 0
local offset = 0
local x = 1
--Populate shop with Packs
for i, _ in pairs(Series1) do
	print(i)
	local NewPack = CardTemplate:Clone()
	NewPack.Visible = true
	NewPack.Parent = script.Parent
	
	-- set pack name, description, and cost
	NewPack.InnerTextFrame.CardName.Text = Series1[i].name
	NewPack.PackCost.Text = "Cost: ".. " ".. Series1[i].cost
	NewPack.InnerTextFrame.PackDescription.Text = Series1[i].description
	
	-- init first pack on the shop to obtain position for next card
	if x == 1 then
		NewPack.Position = UDim2.new(0, 0, CurrentPositionY, offset) 
		offset = offset + 15
		
	else 
		-- adjust position for next card in shop
		CurrentPositionY = CurrentPositionY + NewPack.Size.Y.Scale
		NewPack.Position = UDim2.new(0, 0, CurrentPositionY, offset)
		offset = offset + 15
		--print(offset)
	end
	
	-- create instance Buy button to each individual pack
	local BuyButton = NewPack:WaitForChild("BuyButton")
	BuyButton.MouseButton1Click:Connect(function()
		ShopUtils.BuyItem(i)
	end)
	x = x+1
	
end

return PackPool 







