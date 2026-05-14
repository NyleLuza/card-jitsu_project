-- @ScriptType: LocalScript
--[[
TODO: Create a function that allows the user to interact with the UI to open a pack *
]]--

-- accesses user input
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local GetInventoryEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetInventory")
local ReceivedInventory = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SendInventory")
local RequestOpenPack = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestOpenPack")
local rs = game:GetService("RunService")

local InventoryUI = ReplicatedStorage:WaitForChild("UI"):WaitForChild("InventoryUI")
local Inventory = nil
local InventoryData = nil

-- track inventory status
local IsOpen = false


local rs = game:GetService("RunService")

-- controls camera perspective
local function UpdateMouse()
	if Inventory == nil then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end

-- Controls the opening and closing of the Inventory UI
UIS.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)	
	if gameProcessedEvent then return
	elseif input.KeyCode == Enum.KeyCode.B then
		if IsOpen then
			if Inventory then
				Inventory:Destroy()				
			end
			Inventory = nil
			IsOpen = false
			UpdateMouse()
			return
		end
		GetInventoryEvent:FireServer()
		print("Opened Inventory")
	end	
end)

local Series1 = require(ReplicatedStorage.Packs.Series1)


local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local CurrentType = "Packs" -- default tab

local InventoryTemplate
local ScrollFrame

local function ClearList()
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		-- destroy cloned entries, keep the template
		if child ~= InventoryTemplate and child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function GetListForType(inv, invType)
	-- Support both shapes:
	-- 1) inv is an array of pack names: {"Pack3","Pack2"}  (your current loop uses ipairs(InventoryData))
	-- 2) inv is a dict: inv.Packs / inv.Cards
	if type(inv) ~= "table" then return {} end

	-- If server sends {Packs = {...}, Cards = {...}}
	if inv[invType] ~= nil and type(inv[invType]) == "table" then
		return inv[invType]
	end

	-- If server sends a plain array (likely "Packs" only)
	if invType == "Packs" then
		return inv
	end

	return {}
end

local function RefreshInventoryUI()
	if not Inventory or not InventoryData then return end

	ClearList()

	local list = GetListForType(InventoryData, CurrentType)
	print("Refreshing UI. Type=", CurrentType, "Count=", #list)

	for i, item in ipairs(list) do
		local entry = InventoryTemplate:Clone()
		entry.Visible = true
		entry.Parent = ScrollFrame

		local cfg = Series1[item]
		if cfg then
			entry.TextLabel.Text = cfg.name
		else
			entry.TextLabel.Text = tostring(item)
		end

		-- If you only want OpenButton for packs:
		local openBtn = entry:FindFirstChild("OpenButton", true)
		if openBtn then
			openBtn.Visible = (CurrentType == "Packs")

			openBtn.MouseButton1Click:Connect(function()
				-- IMPORTANT: FireServer returns nothing.
				-- Server should respond via another RemoteEvent like "PackOpened" if you need results.
				print("Client requesting open pack:", item)
				RequestOpenPack:FireServer(item)
			end)
		end
	end
end

local function SetupInventoryUI()
	Inventory = InventoryUI:Clone()
	Inventory.Parent = PlayerGui

	InventoryTemplate = Inventory.Inventory.Scroll.InventoryTemplate
	InventoryTemplate.Visible = false
	ScrollFrame = InventoryTemplate.Parent

	-- Buttons connect ONCE
	local CardsButton = Inventory.Inventory:WaitForChild("CardsButton")
	local PacksButton = Inventory.Inventory:WaitForChild("PacksButton")

	CardsButton.MouseButton1Click:Connect(function()
		CurrentType = "Cards"
		RefreshInventoryUI()
	end)

	PacksButton.MouseButton1Click:Connect(function()
		CurrentType = "Packs"
		RefreshInventoryUI()
	end)

	IsOpen = true
	UpdateMouse()
end

-- Listen for server inventory pushes (can happen multiple times)
ReceivedInventory.OnClientEvent:Connect(function(inv)
	InventoryData = inv

	if not Inventory then
		SetupInventoryUI()
	end

	-- Always refresh when new data arrives
	RefreshInventoryUI()
end)
