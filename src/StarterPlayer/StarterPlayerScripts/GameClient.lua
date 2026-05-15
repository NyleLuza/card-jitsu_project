-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameEvent = ReplicatedStorage:WaitForChild("GameEvent")
local PlayCardRE = ReplicatedStorage:WaitForChild("PlayCard")

local gui = playerGui:WaitForChild("BattleGUI")
local handFrame = gui:WaitForChild("HandFrame")
local statusLabel = gui:WaitForChild("StatusLabel")
local resultLabel = gui:WaitForChild("ResultLabel")

local currentHand = {}
local cardButtons = {}
local hasPlayedThisRound = false
local revealVersion = 0

local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera

-- Optional score label support:
local scoreLabel = gui:FindFirstChild("ScoreLabel")

local leftScoreFrame = gui:WaitForChild("LeftScoreFrame")
local rightScoreFrame = gui:WaitForChild("RightScoreFrame")

--set fixed camera position
local function setBattleCamera()
	local battlePositions = Workspace:WaitForChild("BattlePositions")
	local cameraPart = battlePositions:WaitForChild("CameraPart")

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraPart.CFrame
end

local function setStatus(text)
	statusLabel.Text = tostring(text or "")
end

local ElementImages = {
	fire = "rbxassetid://87831534483432",
	water = "rbxassetid://86496707478556",
	snow = "rbxassetid://83121971045922"
}

local function setScoreText(scoreTable)
	if not scoreLabel or not scoreTable then
		return
	end

	-- Since scoreTable is keyed by UserId, get your score and opponent score
	local yourScore = scoreTable[player.UserId] or 0
	local opponentScore = 0

	for userId, score in pairs(scoreTable) do
		if userId ~= player.UserId then
			opponentScore = score
			break
		end
	end

	scoreLabel.Text = string.format("You: %d | Opponent: %d", yourScore, opponentScore)
end

local function clearHandUI()
	for _, child in ipairs(handFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	cardButtons = {}
end

local function getCardColor(element)
	if element == "fire" then
		return Color3.fromRGB(180, 70, 70)
	elseif element == "water" then
		return Color3.fromRGB(70, 120, 200)
	elseif element == "snow" then
		return Color3.fromRGB(180, 220, 255)
	else
		return Color3.fromRGB(60, 60, 60)
	end
end

local function disableAllCardButtons()
	for _, button in pairs(cardButtons) do
		button.Active = false
		button.AutoButtonColor = false
		button.BackgroundTransparency = 0.4
	end
end

local function getElementColor(element)
	if element == "fire" then
		return Color3.fromRGB(200, 70, 70)
	elseif element == "water" then
		return Color3.fromRGB(70, 130, 220)
	elseif element == "snow" then
		return Color3.fromRGB(190, 230, 255)
	else
		return Color3.fromRGB(150, 150, 150)
	end
end

--CLEAR SCORE FRAME (NEW)
local function clearScoreFrame(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
end
--CLEAR TEXT LABELS IN SCORE FRAME (OLD)
--local function clearScoreFrame(frame)
--	for _, child in ipairs(frame:GetChildren()) do
--		if child:IsA("TextLabel") and child.Name ~= "TitleLabel" then
--			child:Destroy()
--		end
--	end
--end

--DISPLAY ELEMENTS IN SCORE FRAME AS IMAGES
local function addElementIcon(frame, element)
	local image = Instance.new("ImageLabel")
	image.Name = element .. "Win"
	image.Size = UDim2.new(0, 70, 0, 70)
	image.BackgroundTransparency = 1
	image.Image = ElementImages[element] or ""
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = frame
end
-- DISPLAY ELEMENTS IN SCORE FRAME AS TEXT LABELS
--local function addElementIcon(frame, element)
--	local label = Instance.new("TextLabel")
--	label.Name = element .. "Win"
--	label.Size = UDim2.new(0, 60, 0, 60)
--	label.BackgroundColor3 = getElementColor(element)
--	label.TextColor3 = Color3.new(1, 1, 1)
--	label.TextScaled = true
--	label.Text = element
--	label.Parent = frame
--end

--local function updateWonElementsDisplay(yourElements, opponentElements)
--	clearScoreFrame(playerScoreFrame)
--	clearScoreFrame(opponentScoreFrame)
	
--	yourElements = yourElements or {}
--	opponentElements = opponentElements or {}
	
--	print("Updating scoreboard")
--	print("Your elements count:", #yourElements)
--	print("Opponent elements count:", #opponentElements)

--	for _, element in ipairs(yourElements) do
--		print("Adding your element:", element)
--		addElementIcon(playerScoreFrame, element)
--	end

--	for _, element in ipairs(opponentElements) do
--		print("Adding opponent element:", element)
--		addElementIcon(opponentScoreFrame, element)
--	end
--end
local function updateWonElementsDisplay(leftElements, rightElements)
	clearScoreFrame(leftScoreFrame)
	clearScoreFrame(rightScoreFrame)

	leftElements = leftElements or {}
	rightElements = rightElements or {}

	for _, element in ipairs(leftElements) do
		addElementIcon(leftScoreFrame, element)
	end

	for _, element in ipairs(rightElements) do
		addElementIcon(rightScoreFrame, element)
	end
end
--local function showRoundResult(text, color)
--	revealVersion += 1
--	local myVersion = revealVersion

--	resultLabel.Text = text
--	resultLabel.TextColor3 = color
--	resultLabel.Visible = true

--	task.delay(2.5, function()
--		if revealVersion == myVersion then
--			resultLabel.Visible = false
--		end
--	end)
--end
local function showRoundResult(text, color, duration)
	revealVersion += 1
	local myVersion = revealVersion

	resultLabel.Text = text
	resultLabel.TextColor3 = color
	resultLabel.Visible = true

	if duration then
		task.delay(duration, function()
			if revealVersion == myVersion then
				resultLabel.Visible = false
			end
		end)
	end
end

local function createCardButton(card)
	local button = Instance.new("TextButton")
	button.Name = card.name
	button.Size = UDim2.new(0, 110, 0, 150)
	button.BackgroundColor3 = getCardColor(card.element)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextWrapped = true
	button.TextScaled = true
	button.BorderSizePixel = 0
	button.Parent = handFrame

	button.Text = string.format("%s\nPower: %d", card.name, card.value)

	button.MouseButton1Click:Connect(function()
		if hasPlayedThisRound then
			return
		end

		hasPlayedThisRound = true
		setStatus(string.format("You played %s %d. Waiting for opponent...", card.element, card.value))

		PlayCardRE:FireServer(card.id)

		disableAllCardButtons()
		button.BackgroundTransparency = 0
	end)

	cardButtons[card.name] = button
end

local function renderHand(hand)
	currentHand = hand
	clearHandUI()

	for _, card in ipairs(currentHand) do
		createCardButton(card)
	end
end

-- Hide result label on startup
resultLabel.Visible = false
setStatus("Waiting for match...")

GameEvent.OnClientEvent:Connect(function(eventName, data)
	if eventName == "ServerMsg" then
		setStatus(data)

	elseif eventName == "MatchStart" then
		hasPlayedThisRound = false
		resultLabel.Visible = false

		clearScoreFrame(leftScoreFrame)
		clearScoreFrame(rightScoreFrame)

		setBattleCamera()
		
		setStatus(" Match started! Choose a card. ")

	elseif eventName == "HandUpdate" then
		hasPlayedThisRound = false
		renderHand(data)

		if not resultLabel.Visible then
			setStatus("Choose a card.")
		end

	elseif eventName == "PlayedAck" then
		print("Played:", data.cardId)

	elseif eventName == "RoundReveal" then
		print("RoundReveal received: ", data.result)
		local resultText = "TIE!"
		local resultColor = Color3.fromRGB(240, 220, 90)

		if data.result == "Win" then
			print("Win")
			resultText = "YOU WIN!"
			resultColor = Color3.fromRGB(80, 220, 120)
		elseif data.result == "Lose" then
			print("Lose")
			resultText = "YOU LOSE!"
			resultColor = Color3.fromRGB(220, 80, 80)
		end
		if data.leftWonElements and data.rightWonElements then
			updateWonElementsDisplay(data.leftWonElements, data.rightWonElements)
		else
			warn("RoundReveal missing left/right scoreboard data")
		end
		--if data.yourWonElements and data.opponentWonElements then
		--	updateWonElementsDisplay(data.yourWonElements, data.opponentWonElements)
		--else
		--	warn("RoundReveal missing scoreboard data")
		--end
		
		--if data.wonElements then
		--	updateWonElementsDisplay(data.wonElements)
		--end
		
		showRoundResult(resultText, resultColor, 2.5)

		if data.yourCard and data.opponentCard then
			setStatus(string.format(
				" You played %s %d | Opponent played %s %d ",
				tostring(data.yourCard.element),
				tonumber(data.yourCard.value) or 0,
				tostring(data.opponentCard.element),
				tonumber(data.opponentCard.value) or 0
				))
			
		else
			warn("RoundReveal missing card data:", data)
			setStatus("Round finished.")
		end

		setScoreText(data.score)
		task.wait(2.5)
		setStatus("Next Round! Choose a card.")
		
	elseif eventName == "MatchEnd" then
		if data.leftWonElements and data.rightWonElements then
			updateWonElementsDisplay(data.leftWonElements, data.rightWonElements)
		else
			warn("MatchEnd missing left/right scoreboard data")
		end
		
		if data.winnerUserId == player.UserId then
			showRoundResult("YOU WON THE MATCH!", Color3.fromRGB(80, 220, 120))
		else
			showRoundResult("YOU LOST THE MATCH!", Color3.fromRGB(220, 80, 80))
		end

		setStatus(data.reason)
	end
end)