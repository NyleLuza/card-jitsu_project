-- @ScriptType: LocalScript
-- DeckUIController LocalScript under ScreenGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetInventory = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetInventoryItems")
local SaveDeck = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SaveDeck")

local screenGui = script.Parent

local deckBuilderUI = screenGui:WaitForChild("DeckPagesUI")
local deckEditorUI = screenGui:WaitForChild("DeckEditorUI")

local deckPages = deckBuilderUI:WaitForChild("DeckPages")
local pageLayout = deckPages:WaitForChild("UIPageLayout")

local deckList = deckPages:WaitForChild("DeckList")
local deckTemplate = deckList:WaitForChild("DeckTemplate")

local addButton = deckBuilderUI:WaitForChild("plus_sign")
local leftArrow = deckBuilderUI:WaitForChild("left_arr")
local rightArrow = deckBuilderUI:WaitForChild("right_arr")

-- Deck editor objects
local deckScroll = deckEditorUI:WaitForChild("DeckScroll")
local title = deckEditorUI:WaitForChild("Title")

local saveButton = deckEditorUI:FindFirstChild("SaveDeckButton")
local backButton = deckEditorUI:FindFirstChild("BackButton")

local MAX_DECK_SIZE = 12

local decks = {}
local nextDeckId = 1
local openedDeckId = nil

local ownedCards = {}
local currentDeck = {}

local cardsPerPage = 3
local currentPage = deckList
local countOnPage = 0

local function showBuilder()
	deckBuilderUI.Visible = true
	deckEditorUI.Visible = false
end

local function clearDeckScroll()
	for _, child in ipairs(deckScroll:GetChildren()) do
		if child:IsA("GuiObject")
			and child.Name ~= "CardTemplate"
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIListLayout") then
			child:Destroy()
		end
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

local function refreshEditor()
	clearDeckScroll()

	local ownedCounts = countCopies(ownedCards)
	local deckCounts = countCopies(currentDeck)
	
	local uniqueCards = {}

	for _, cardName in ipairs(ownedCards) do
		uniqueCards[cardName] = true
	end

	for cardName in pairs(uniqueCards) do
		local owned = ownedCounts[cardName] or 0
		local selected = deckCounts[cardName] or 0
		local available = owned - selected

		local cardButton = Instance.new("TextButton")
		cardButton.Name = "Card_" .. cardName
		cardButton.Size = UDim2.new(0, 90, 0, 110)
		cardButton.TextScaled = true
		cardButton.Text = cardName .. "\n" .. selected .. "/" .. owned
		cardButton.Parent = deckScroll

		if selected > 0 then
			cardButton.Text = cardName .. "\nSelected: " .. selected .. "/" .. owned
		else
			cardButton.Text = cardName .. "\nOwned: " .. owned
		end

		cardButton.Activated:Connect(function()
			if #currentDeck >= MAX_DECK_SIZE then
				return
			end

			if available <= 0 then
				return
			end

			table.insert(currentDeck, cardName)

			local deck = findDeck(openedDeckId)
			if deck then
				deck.cards = currentDeck
			end
			
			refreshEditor()
		end)
		print("refreshEditor ownedCards:", #ownedCards)
	end
end

local function showEditor(deckId)
	openedDeckId = deckId

	deckBuilderUI.Visible = false
	deckEditorUI.Visible = true

	deckEditorUI:SetAttribute("OpenDeckId", deckId)

	if title:IsA("TextLabel") or title:IsA("TextButton") then
		title.Text = "Deck " .. deckId
	end

	local deck = findDeck(deckId)
	if deck then
		currentDeck = deck.cards or {}
	else
		currentDeck = {}
	end
	print("Requesting deck inventory from server")
	print("CLIENT EVENT PATH:", GetInventory:GetFullName())
	GetInventory:FireServer()
end

local function createDeckCard(deckId, parentList)
	local card = deckTemplate:Clone()
	card.Name = "Deck_" .. deckId
	card.Visible = true
	card.LayoutOrder = deckId
	card.Parent = parentList

	local button = card

	if not button:IsA("TextButton") and not button:IsA("ImageButton") then
		button = card:FindFirstChildWhichIsA("TextButton", true)
	end

	if button then
		button.Text = "Deck_" .. deckId

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
		newPage.Parent = deckPages

		for _, child in ipairs(newPage:GetChildren()) do
			if child.Name:match("^Deck_%d+$") then
				child:Destroy()
			end
		end

		currentPage = newPage
		countOnPage = 0

		pageLayout:JumpTo(currentPage)
	end

	createDeckCard(deckId, currentPage)
	countOnPage += 1
end

local function goLeft()
	pageLayout:Previous()
end

local function goRight()
	pageLayout:Next()
end

addButton.Activated:Connect(addDeck)
leftArrow.Activated:Connect(goLeft)
rightArrow.Activated:Connect(goRight)

if backButton then
	backButton.Activated:Connect(showBuilder)
end

if saveButton then
	saveButton.Activated:Connect(function()
		local deck = findDeck(openedDeckId)
		if deck then
			SaveDeck:FireServer(deck.cards)
		end
	end)
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

deckTemplate.Visible = false

for i = 1, 3 do
	addDeck()
end

showBuilder()