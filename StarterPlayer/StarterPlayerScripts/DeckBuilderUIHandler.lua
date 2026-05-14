-- @ScriptType: LocalScript
--// Combined DeckBuilder + DeckEditor Handler
--// Put this LocalScript in StarterPlayerScripts

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetInventory = RemoteEvents:WaitForChild("GetInventoryItems")
local SaveDeck = RemoteEvents:WaitForChild("SaveDeck")

local DeckBuilderTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("DeckBuilderUI")

local TOGGLE_KEY = Enum.KeyCode.U
local MAX_DECK_SIZE = 8

local DeckBuilderUI
local DeckPagesUI
local DeckEditorUI
local DeckPages
local PageLayout
local DeckList
local DeckTemplate
local DeckScroll
local Title
local BackButton
local SaveDeckButton
local AddButton
local LeftArrow
local RightArrow

local IsOpen = false
local openedDeckId = nil

local decks = {}
local nextDeckId = 1

local ownedCards = {}
local currentDeck = {}

local cardsPerPage = 3
local currentPage
local countOnPage = 0

local CardsCount
local FireValue
local WaterValue
local SnowValue
local AvgPowerValue

local function UpdateMouse()
	if DeckBuilderUI then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	else
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false
	end
end

local function countCopies(cardList)
	local counts = {}

	for _, cardName in ipairs(cardList) do
		counts[cardName] = (counts[cardName] or 0) + 1
	end

	return counts
end

local function findDeck(deckId)
	for _, deck in ipairs(decks) do
		if deck.id == deckId then
			return deck
		end
	end

	return nil
end

local function clearDeckScroll()
	for _, child in ipairs(DeckScroll:GetChildren()) do
		if child:IsA("GuiObject")
			and child.Name ~= "CardTemplate"
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end
local function updateEditorStats()
	local fireCount = 0
	local waterCount = 0
	local snowCount = 0

	for _, cardName in ipairs(currentDeck) do
		local lowerName = string.lower(cardName)

		if string.find(lowerName, "fire") or string.find(lowerName, "pyro") then
			fireCount += 1
		elseif string.find(lowerName, "water") or string.find(lowerName, "crystal") then
			waterCount += 1
		elseif string.find(lowerName, "snow") or string.find(lowerName, "frost") then
			snowCount += 1
		end
	end

	if CardsCount then
		CardsCount.Text = tostring(#currentDeck) .. "/" .. tostring(MAX_DECK_SIZE)
	end

	if FireValue then
		FireValue.Text = tostring(fireCount)
	end

	if WaterValue then
		WaterValue.Text = tostring(waterCount)
	end

	if SnowValue then
		SnowValue.Text = tostring(snowCount)
	end

	if AvgPowerValue then
		AvgPowerValue.Text = "0"
	end
end
local function removeOneCard(cardName)
	for i = #currentDeck, 1, -1 do
		if currentDeck[i] == cardName then
			table.remove(currentDeck, i)
			return true
		end
	end

	return false
end

local TweenService = game:GetService("TweenService")

local function flashCard(cardButton, flashColor)
	local originalColor = cardButton.BackgroundColor3

	local flashTween = TweenService:Create(
		cardButton,
		TweenInfo.new(0.25, Enum.EasingStyle.Linear),
		{BackgroundColor3 = flashColor}
	)

	local returnTween = TweenService:Create(
		cardButton,
		TweenInfo.new(0.25, Enum.EasingStyle.Linear),
		{BackgroundColor3 = originalColor}
	)

	flashTween:Play()
	flashTween.Completed:Wait()
	returnTween:Play()
end
local function refreshEditor()
	if not DeckScroll then return end
	
	updateEditorStats()
	clearDeckScroll()

	local ownedCounts = countCopies(ownedCards)
	local deckCounts = countCopies(currentDeck)

	local uniqueCards = {}

	for _, cardName in ipairs(ownedCards) do
		uniqueCards[cardName] = true
	end

	local sortedCards = {}

	for cardName in pairs(uniqueCards) do
		table.insert(sortedCards, cardName)
	end

	table.sort(sortedCards)

	for index, cardName in ipairs(sortedCards) do
		local owned = ownedCounts[cardName] or 0
		local selected = deckCounts[cardName] or 0
		local available = owned - selected

		local cardButton = Instance.new("TextButton")
		cardButton.Name = "Card_" .. cardName
		cardButton.Size = UDim2.new(0, 125, 0, 145)
		cardButton.LayoutOrder = index
		cardButton.TextScaled = true
		cardButton.BackgroundTransparency = 0.05
		cardButton.TextColor3 = Color3.fromRGB(0,0,0)
		cardButton.BackgroundColor3 = Color3.fromRGB(32, 28, 24)
		cardButton.Font = Enum.Font.PermanentMarker
		cardButton.Parent = DeckScroll
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = cardButton
		
		
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.Parent = cardButton
		
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(1, -12, 0, 42)
		countLabel.Position = UDim2.new(0, 6, 1, -54)
		countLabel.TextScaled = false
		countLabel.TextSize = 16
		countLabel.TextWrapped = true
		countLabel.Font = Enum.Font.PermanentMarker

		
		if selected > 0 then
			cardButton.Text = cardName .. "\nSelected: " .. selected .. "/" .. owned
		else
			cardButton.Text = cardName .. "\nOwned: " .. owned
		end

		cardButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if #currentDeck >= MAX_DECK_SIZE then
					flashCard(cardButton, Color3.fromRGB(150, 50, 50))
					return
				end

				if available <= 0 then
					flashCard(cardButton, Color3.fromRGB(150, 50, 50))
					return
				end

				table.insert(currentDeck, cardName)
				flashCard(cardButton, Color3.fromRGB(80, 140, 70))

			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				if selected > 0 then
					removeOneCard(cardName)
					flashCard(cardButton, Color3.fromRGB(160, 90, 50))
				else
					flashCard(cardButton, Color3.fromRGB(150, 50, 50))
					return
				end
			end

			local deck = findDeck(openedDeckId)
			if deck then
				deck.cards = currentDeck
			end

			task.wait(0.08)
			refreshEditor()
		end)
	end
end

local function showPages()
	if DeckPagesUI then
		DeckPagesUI.Visible = true
	end

	if DeckEditorUI then
		DeckEditorUI.Visible = false
	end
end

local function showEditor(deckId)
	openedDeckId = deckId

	if DeckPagesUI then
		DeckPagesUI.Visible = false
	end

	if DeckEditorUI then
		DeckEditorUI.Visible = true
	end

	if Title and (Title:IsA("TextLabel") or Title:IsA("TextButton")) then
		Title.Text = "Deck " .. tostring(deckId)
	end

	local deck = findDeck(deckId)
	if deck then
		currentDeck = deck.cards or {}
	else
		currentDeck = {}
	end
	updateEditorStats()

	print("Requesting deck inventory from server")
	print("CLIENT EVENT PATH:", GetInventory:GetFullName())

	GetInventory:FireServer(openedDeckId)
end

local function destroyUI()
	if DeckBuilderUI then
		DeckBuilderUI:Destroy()
		DeckBuilderUI = nil
	end

	IsOpen = false
	UpdateMouse()
end

local function clearDeckPages()
	if not DeckList or not DeckTemplate then return end

	for _, child in ipairs(DeckList:GetChildren()) do
		if child:IsA("GuiObject")
			and child ~= DeckTemplate
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function createDeckCard(deckId, parentList)
	local card = DeckTemplate:Clone()
	card.Name = "Deck_" .. tostring(deckId)
	card.Visible = true
	card.LayoutOrder = deckId
	card.Parent = parentList

	local button = card

	if not button:IsA("TextButton") and not button:IsA("ImageButton") then
		button = card:FindFirstChildWhichIsA("TextButton", true)
	end

	if button then
		if button:IsA("TextButton") then
			button.Text = "Deck_" .. tostring(deckId)
		end

		button.Activated:Connect(function()
			print("Deck clicked:", deckId)
			showEditor(deckId)
		end)
	else
		warn("No clickable button found in DeckTemplate")
	end

	return card
end

local function addDeck()
	local deckId = nextDeckId
	nextDeckId += 1

	table.insert(decks, {
		id = deckId,
		cards = {},
	})

	if countOnPage >= cardsPerPage then
		local newPage = currentPage:Clone()
		newPage.Name = "DeckList_" .. tostring(math.ceil(deckId / cardsPerPage))
		newPage.Parent = DeckPages

		for _, child in ipairs(newPage:GetChildren()) do
			if child:IsA("GuiObject")
				and child.Name:match("^Deck_%d+$") then
				child:Destroy()
			end
		end

		currentPage = newPage
		countOnPage = 0

		if PageLayout then
			PageLayout:JumpTo(currentPage)
		end
	end

	createDeckCard(deckId, currentPage)
	countOnPage += 1
end

local function goLeft()
	if PageLayout then
		PageLayout:Previous()
	end
end

local function goRight()
	if PageLayout then
		PageLayout:Next()
	end
end

local function setupUI()
	DeckBuilderUI = DeckBuilderTemplate:Clone()
	DeckBuilderUI.Parent = PlayerGui
	DeckBuilderUI.Enabled = true

	DeckPagesUI = DeckBuilderUI:WaitForChild("DeckPagesUI")
	DeckEditorUI = DeckBuilderUI:WaitForChild("DeckEditorUI")

	DeckPages = DeckPagesUI:WaitForChild("DeckPages")
	PageLayout = DeckPages:WaitForChild("UIPageLayout")

	DeckList = DeckPages:WaitForChild("DeckList")
	DeckTemplate = DeckList:WaitForChild("DeckTemplate")

	DeckScroll = DeckEditorUI:WaitForChild("DeckScroll")
	Title = DeckEditorUI:WaitForChild("Title")

	BackButton = DeckBuilderUI:FindFirstChild("BackButton", true)
	SaveDeckButton = DeckEditorUI:FindFirstChild("SaveDeckButton", true)

	AddButton = DeckPagesUI:WaitForChild("plus_sign")
	LeftArrow = DeckPagesUI:WaitForChild("left_arr")
	RightArrow = DeckPagesUI:WaitForChild("right_arr")
	
	CardsCount = DeckEditorUI:FindFirstChild("CardsCount", true)
	FireValue = DeckEditorUI:FindFirstChild("FireValue", true)
	WaterValue = DeckEditorUI:FindFirstChild("WaterValue", true)
	SnowValue = DeckEditorUI:FindFirstChild("SnowValue", true)
	AvgPowerValue = DeckEditorUI:FindFirstChild("AvgPowerValue", true)

	DeckTemplate.Visible = false

	currentPage = DeckList
	countOnPage = 0

	AddButton.Activated:Connect(addDeck)
	LeftArrow.Activated:Connect(goLeft)
	RightArrow.Activated:Connect(goRight)

	if BackButton then
		BackButton.Activated:Connect(function()
			if DeckEditorUI.Visible then
				showPages()
			else
				destroyUI()
			end
		end)
	end

	if SaveDeckButton then
		SaveDeckButton.Activated:Connect(function()
			local deck = findDeck(openedDeckId)
			if deck then
				print("Saving deck:", openedDeckId)
				SaveDeck:FireServer(openedDeckId, deck.cards)
			end
		end)
	end

	IsOpen = true
	UpdateMouse()

	showPages()

	decks = {}
	nextDeckId = 1
	currentPage = DeckList
	countOnPage = 0

	for i = 1, 3 do
		addDeck()
	end
end

GetInventory.OnClientEvent:Connect(function(serverCards, savedDeck)
	print("CLIENT GOT CARDS:", serverCards, savedDeck)
	print("Card count:", serverCards and #serverCards or 0)

	ownedCards = serverCards or {}

	local deck = findDeck(openedDeckId)
	if deck then
		if #deck.cards == 0 and savedDeck then
			deck.cards = savedDeck
		end

		currentDeck = deck.cards
	end

	refreshEditor()
end)

SaveDeck.OnClientEvent:Connect(function(success, message)
	if success then
		print("Deck saved:", message)
	else
		warn("Deck save failed:", message)
	end
end)

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode ~= TOGGLE_KEY then return end

	if IsOpen then
		destroyUI()
	else
		setupUI()
	end
end)