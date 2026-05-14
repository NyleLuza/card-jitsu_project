-- @ScriptType: LocalScript
-- DeckUIController (LocalScript) under ScreenGui

local screenGui = script.Parent

local deckBuilderUI = screenGui:WaitForChild("DeckPagesUI")
local deckEditorUI = screenGui:WaitForChild("DeckEditorUI")

local deckPages = deckBuilderUI:WaitForChild("DeckPages")
local pageLayout = deckPages:WaitForChild("UIPageLayout")

local deckTemplate = deckPages:WaitForChild("DeckList"):WaitForChild("DeckTemplate")
local deckList = deckPages:WaitForChild("DeckList")

local addButton = deckBuilderUI:WaitForChild("plus_sign")
local leftArrow = deckBuilderUI:WaitForChild("left_arr")
local rightArrow = deckBuilderUI:WaitForChild("right_arr")

-- local backButton = deckEditorUI:WaitForChild("BackButton")

-- simple deck data (you can later replace with real saved data)
local decks = {}
local nextDeckId = 1

local function showBuilder()
	deckBuilderUI.Visible = true
	deckEditorUI.Visible = false
end

local function showEditor(deckId)
	deckBuilderUI.Visible = false
	deckEditorUI.Visible = true

	-- Optional: store which deck is open
	deckEditorUI:SetAttribute("OpenDeckId", deckId)
end
local cardsPerPage = 3
local currentPage = deckPages:WaitForChild("DeckList")
local countOnPage = 0

local function createDeckCard(deckId, parentList)
	local card = deckTemplate.TextButton:Clone()
	card.Name = "Deck_" .. deckId
	card.Text = "Deck_" .. deckId
	card.Visible = true
	card.LayoutOrder = deckId
	card.Parent = parentList

	card.Activated:Connect(function()
		showEditor(deckId)
	end)

	return card
end

local function addDeck()
	local deckId = nextDeckId
	nextDeckId += 1

	table.insert(decks, { id = deckId })

	-- If current page is full, make a new one
	if countOnPage >= cardsPerPage then
		local newPage = currentPage:Clone()
		newPage.Name = "DeckList_" .. tostring(math.ceil(deckId / cardsPerPage))
		newPage.Parent = deckPages

		-- Remove old cloned deck cards from the new page, keep only template/layout
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
--[[
-- Create a deck card (button) from template
local function createDeckCard(deckId)
	local card = deckTemplate:Clone()
	card.Name = "Deck_" .. deckId
	card.Visible = true
	card.LayoutOrder = deckId
	card.Parent = deckList

	-- If you have a label inside the template, you can set it here:
	-- local title = card:FindFirstChild("TitleLabel", true)
	-- if title and title:IsA("TextLabel") then
	-- 	title.Text = "Deck " .. deckId
	-- end

	-- Clicking the deck card opens the editor UI
	card.Activated:Connect(function()
		showEditor(deckId)
	end)

	return card
end
local count = 1

local function addDeck()
	local deckId = nextDeckId
	local newPage = nil
	nextDeckId += 1

	table.insert(decks, { id = deckId })
	
	if count~=3 then 
		local newCard = createDeckCard(deckId)
		count+=1
	elseif count==3 then 
		newPage = deckPages:WaitForChild("DeckList"):Clone()
		newPage.Parent = deckPages
		count = 1
	end
	end
	-- Jump to the new deck page
	pageLayout:JumpTo(newPage)
end
--]]
-- Rotate left/right through current decks
local function goLeft()
	pageLayout:Previous()
end

local function goRight()
	pageLayout:Next()
end

-- Wire up buttons
addButton.Activated:Connect(addDeck)
leftArrow.Activated:Connect(goLeft)
rightArrow.Activated:Connect(goRight)

-- backButton.Activated:Connect(showBuilder)

-- Initial state
deckTemplate.Visible = false
--showBuilder()

-- Optional: start with 3 decks like your mockup
for i = 1, 3 do
	addDeck()
end