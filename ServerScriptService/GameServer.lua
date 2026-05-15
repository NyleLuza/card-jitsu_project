-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEvent = ReplicatedStorage:WaitForChild("GameEvent")
local PlayCardRE = ReplicatedStorage:WaitForChild("PlayCard")
local TeleportService = game:GetService("TeleportService")
local lobbyPlaceId = 130844335458829

-- inventory init
local DataStoreService = game:GetService("DataStoreService")
local InventoryStore = DataStoreService:GetDataStore("PlayerInventoryData")
local Inventory = {}
local decklist = nil
local decks = nil
local decklists = {}

local cardConfig = require(ReplicatedStorage:WaitForChild("Cards"):WaitForChild("CardConfig"))

local UserId


local Workspace = game:GetService("Workspace")
local BattlePositions = Workspace:WaitForChild("BattlePositions")
local Player1Stand = BattlePositions:WaitForChild("Player1Stand")
local Player2Stand = BattlePositions:WaitForChild("Player2Stand")


local function makeDeck(decks)
	local newDeck = {}
	-- Using deck 3 as a placeholder for now
	-- print(decks["3"])
	-- iterate through each card in the selected deck
	for _, card in ipairs(decks["2"]) do
		local CardData = cardConfig[card]
		table.insert(newDeck, CardData)
	end
	print("new deck", newDeck)
	
	return newDeck
end

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

local function draw(deck)
	return table.remove(deck) -- draws from end
end

-- Basic Card-Jitsu-style triangle
local function beats(a, b)
	-- returns true if element a beats element b
	return (a == "fire" and b == "snow")
		or (a == "snow" and b == "water")
		or (a == "water" and b == "fire")
end
local function resolveRound(cardA, cardB)
	print("resolveRound called")
	print("Card A:", cardA.name, "[" .. tostring(cardA.element) .. "]", cardA.value)
	print("Card B:", cardB.name, "[" .. tostring(cardB.element) .. "]", cardB.value)

	if cardA.element == cardB.element then
		print("Same element, comparing power")
		if cardA.value > cardB.value then
			print("Winner: A by power")
			return "A"
		end
		if cardB.value > cardA.value then
			print("Winner: B by power")
			return "B"
		end
		print("Tie: same element and same power")
		return "Tie"
	end

	if beats(cardA.element, cardB.element) then
		print("Winner: A by element advantage")
		return "A"
	end

	if beats(cardB.element, cardA.element) then
		print("Winner: B by element advantage")
		return "B"
	end

	print("Tie: no element matchup found")
	return "Tie"
end


-- ===== Game state =====
local gameState = {
	waiting = nil, -- player waiting for match
	match = nil,   -- current match state (2 players only)
}

local function dealHands(match, handSize)
	for _, p in ipairs(match.players) do
		local playerDeck = match.decks[p.UserId]

		for i = 1, handSize do
			local card = draw(playerDeck)
			if card then
				table.insert(match.hands[p.UserId], card)
			else
				warn("Deck ran out for", p.Name)
			end
		end
	end
end

local function sendHandsToClients(match)
	for _, p in ipairs(match.players) do
		local hand = match.hands[p.UserId]
		-- Send your own hand to you (do not leak opponent hand)
		GameEvent:FireClient(p, "HandUpdate", hand)
	end
end

local function hasWonMatch(wonElements)
	local counts = {
		fire = 0,
		water = 0,
		snow = 0
	}

	for _, element in ipairs(wonElements) do
		if counts[element] ~= nil then
			counts[element] += 1
		end
	end

	-- Win condition 1: three of same element
	for _, count in pairs(counts) do
		if count >= 3 then
			return true
		end
	end

	-- Win condition 2: one of each element
	if counts.fire >= 1 and counts.water >= 1 and counts.snow >= 1 then
		return true
	end

	return false
end

--set player positions 
local function freezePlayer(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	root.Anchored = true
end

local function placePlayerFacing(player, standPart, faceTargetPart)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")

	local standPosition = standPart.Position + Vector3.new(0, 3, 0)
	local lookAtPosition = faceTargetPart.Position + Vector3.new(0, 3, 0)

	root.CFrame = CFrame.lookAt(standPosition, lookAtPosition)

	freezePlayer(player)
end

local function setupBattlePositions(p1, p2)
	placePlayerFacing(p1, Player1Stand, Player2Stand)
	placePlayerFacing(p2, Player2Stand, Player1Stand)
end
--end of player positions
--start match
local function startMatch(p1, p2)
	-- decklist = makeDeck(decks)
	local p1Deck = makeDeck(decklists[p1.UserId])
	local p2Deck = makeDeck(decklists[p2.UserId])
	print("started match")
	--print(deck)
	shuffle(p1Deck)
	shuffle(p2Deck)

	setupBattlePositions(p1, p2)
	
	local match = {
		players = {p1, p2},
		decks = {
			[p1.UserId] = p1Deck,
			[p2.UserId] = p2Deck,
		},
		hands = {
			[p1.UserId] = {},
			[p2.UserId] = {}
		},       -- [userId] = {cards}
		picks = {},       -- [userId] = cardId
		score = {         -- simple score for now
			[p1.UserId] = 0,
			[p2.UserId] = 0,
		},
		wonElements = {
			[p1.UserId] = {},
			[p2.UserId] = {}
		},
		handSize = 5,
		inProgress = true,
	}

	dealHands(match, match.handSize)
	sendHandsToClients(match)

	-- Tell both players the game started + who opponent is
	GameEvent:FireClient(p1, "MatchStart", {opponentUserId = p2.UserId})
	GameEvent:FireClient(p2, "MatchStart", {opponentUserId = p1.UserId})

	gameState.match = match
	GameEvent:FireAllClients("ServerMsg", "Match started!")
end

local function teleportPlayersToLobby(match)
	local playersToTeleport = {}

	for _, player in ipairs(match.players) do
		if player and player.Parent == Players then
			table.insert(playersToTeleport, player)
		end
	end

	if #playersToTeleport > 0 then
		local success, err = pcall(function()
			TeleportService:TeleportAsync(lobbyPlaceId, playersToTeleport)
		end)

		if not success then
			warn("Failed to teleport players back to lobby:", err)
		end
	end
end

--local function endMatch(match, reason)
--	match.inProgress = false
--	for _, p in ipairs(match.players) do
--		GameEvent:FireClient(p, "MatchEnd", {reason = reason, score = match.score})
--	end
--	gameState.match = nil
--end

local function endMatch(match, reason, winner)
	match.inProgress = false

	local p1 = match.players[1]
	local p2 = match.players[2]

	if p1 and p1.Parent == Players then
		GameEvent:FireClient(p1, "MatchEnd", {
			reason = reason or "Match ended.",
			winnerUserId = winner and winner.UserId or nil,
			score = match.score,

			yourWonElements = match.wonElements[p1.UserId],
			opponentWonElements = match.wonElements[p2.UserId]
		})
	end

	if p2 and p2.Parent == Players then
		GameEvent:FireClient(p2, "MatchEnd", {
			reason = reason or "Match ended.",
			winnerUserId = winner and winner.UserId or nil,
			score = match.score,

			yourWonElements = match.wonElements[p2.UserId],
			opponentWonElements = match.wonElements[p1.UserId]
		})
	end
	task.wait(5)
	teleportPlayersToLobby(match)
	gameState.match = nil
end

local function getPlayerByUserId(match, userId)
	for _, p in ipairs(match.players) do
		if p.UserId == userId then return p end
	end
	return nil
end

local function removeCardFromHand(match, userId, cardId)
	local hand = match.hands[userId]
	for i, c in ipairs(hand) do
		print("comparison",c.id, cardId)
		if c.id == cardId then
			return table.remove(hand, i)
		end
	end
	return nil
end



local function onBothPicked(match)
	local p1, p2 = match.players[1], match.players[2]

	local c1Id = match.picks[p1.UserId]
	local c2Id = match.picks[p2.UserId]
	if not (c1Id and c2Id) then return end

	local c1 = match.lastPlayed[p1.UserId]
	local c2 = match.lastPlayed[p2.UserId]

	if not c1 or not c2 then
		warn("Missing played cards in onBothPicked", c1, c2)
		return
	end

	local winner = resolveRound(c1, c2)
	local resultForP1 = "Tie"
	local resultForP2 = "Tie"
	local matchWinner = nil
	local winningCard = nil

	if winner == "A" then
		resultForP1 = "Win"
		resultForP2 = "Lose"

		match.score[p1.UserId] += 1
		table.insert(match.wonElements[p1.UserId], c1.element)

		matchWinner = p1
		winningCard = c1

	elseif winner == "B" then
		resultForP1 = "Lose"
		resultForP2 = "Win"

		match.score[p2.UserId] += 1
		table.insert(match.wonElements[p2.UserId], c2.element)

		matchWinner = p2
		winningCard = c2
	end
	--debugging
	print("SERVER scoreboard before RoundReveal")
print(p1.Name, "wins:", table.concat(match.wonElements[p1.UserId], ", "))
print(p2.Name, "wins:", table.concat(match.wonElements[p2.UserId], ", "))
	
	
	GameEvent:FireClient(p1, "RoundReveal", {
		yourCard = c1,
		opponentCard = c2,
		result = resultForP1,
		score = match.score,

		--yourWonElements = match.wonElements[p1.UserId],
		--opponentWonElements = match.wonElements[p2.UserId]
		leftWonElements = match.wonElements[p2.UserId],
		rightWonElements = match.wonElements[p1.UserId]
	})

	GameEvent:FireClient(p2, "RoundReveal", {
		yourCard = c2,
		opponentCard = c1,
		result = resultForP2,
		score = match.score,
		--yourWonElements = match.wonElements[p2.UserId],
		--opponentWonElements = match.wonElements[p1.UserId]
		leftWonElements = match.wonElements[p2.UserId],
		rightWonElements = match.wonElements[p1.UserId]
	})

	-- Check match win after round reveal
	if matchWinner and hasWonMatch(match.wonElements[matchWinner.UserId]) then
		task.wait(2.6)

		--for _, p in ipairs(match.players) do
		--	GameEvent:FireClient(p, "MatchEnd", {
		--		reason = matchWinner.Name .. " won the match!",
		--		winnerUserId = matchWinner.UserId,
		--		wonElements = match.wonElements,
		--		winningElement = winningCard.Element
		--	})
		--end
		GameEvent:FireClient(p1, "MatchEnd", {
			reason = matchWinner.Name .. " won the match! ",
			winnerUserId = matchWinner.UserId,
			score = match.score,

			--yourWonElements = match.wonElements[p1.UserId],
			--opponentWonElements = match.wonElements[p2.UserId],
			leftWonElements = match.wonElements[p2.UserId],
			rightWonElements = match.wonElements[p1.UserId],
			winningElement = winningCard.element
		})

		GameEvent:FireClient(p2, "MatchEnd", {
			reason = matchWinner.Name .. " won the match! ",
			winnerUserId = matchWinner.UserId,
			score = match.score,

			--yourWonElements = match.wonElements[p2.UserId],
			--opponentWonElements = match.wonElements[p1.UserId],
			leftWonElements = match.wonElements[p2.UserId],
			rightWonElements = match.wonElements[p1.UserId],
			winningElement = winningCard.element
		})
		
		-- Give players time to see the final result
		task.wait(5)

		teleportPlayersToLobby(match)
		
		gameState.match = nil
		return
	end

	task.wait(2)

	for _, p in ipairs(match.players) do
		local uid = p.UserId
		local playerDeck = match.decks[uid]

		if playerDeck and #playerDeck > 0 then
			table.insert(match.hands[uid], draw(playerDeck))
		else
			warn("Deck empty for", p.Name)
		end
	end

	sendHandsToClients(match)

	match.picks[p1.UserId] = nil
	match.picks[p2.UserId] = nil
	match.lastPlayed[p1.UserId] = nil
	match.lastPlayed[p2.UserId] = nil
end
--	local p1, p2 = match.players[1], match.players[2]
--	local c1Id = match.picks[p1.UserId]
--	local c2Id = match.picks[p2.UserId]
--	if not (c1Id and c2Id) then
--		print("onBothPicked: missing pick for", p1.Name, " or ", p2.Name)
--		return
--	end

--	local c1 = match.lastPlayed[p1.UserId]
--	local c2 = match.lastPlayed[p2.UserId]

--	local winner = resolveRound(c1, c2)
--	if winner == "A" then
--		match.score[p1.UserId] += 1
--	elseif winner == "B" then
--		match.score[p2.UserId] += 1
--	end

--	-- Reveal to both
--	--for _, p in ipairs(match.players) do
--	--	GameEvent:FireClient(p, "RoundReveal", {
--	--		cardA = c1,
--	--		cardB = c2,
--	--		winner = winner,
--	--		score = match.score
--	--	})
--	--end
	
--	local p1, p2 = match.players[1], match.players[2]

--	local resultForP1 = "Tie"
--	local resultForP2 = "Tie"

--	if winner == "A" then
--		resultForP1 = "Win"
--		resultForP2 = "Lose"
--	elseif winner == "B" then
--		resultForP1 = "Lose"
--		resultForP2 = "Win"
--	end
	
--	print("Sending RoundReveal to", p1.Name, c1 and c1.Element, c2 and c2.Element, resultForP1)
	
--	GameEvent:FireClient(p1, "RoundReveal", {
--		yourCard = c1,
--		opponentCard = c2,
--		result = resultForP1,
--		score = match.score
--	})
	
--	print("Sending RoundReveal to", p2.Name, c2 and c2.Element, c1 and c1.Element, resultForP2)
--	GameEvent:FireClient(p2, "RoundReveal", {
--		yourCard = c2,
--		opponentCard = c1,
--		result = resultForP2,
--		score = match.score
--	})
--	task.wait(2) -- Wait 2 seconds before the next round

--	-- Draw back up (simple)
--	for _, p in ipairs(match.players) do
--		local uid = p.UserId
--		if #match.deck == 0 then
--			endMatch(match, "Deck empty")
--			return
--		end
--		table.insert(match.hands[uid], draw(match.deck))
--	end
--	sendHandsToClients(match)

--	-- Reset picks
--	match.picks[p1.UserId] = nil
--	match.picks[p2.UserId] = nil
--	match.lastPlayed[p1.UserId] = nil
--	match.lastPlayed[p2.UserId] = nil
--end

PlayCardRE.OnServerEvent:Connect(function(player, cardId)
	local match = gameState.match
	if not match or not match.inProgress then return end

	-- Ensure player is in this match
	local p = getPlayerByUserId(match, player.UserId)
	if not p then return end

	-- Ensure player hasn't already picked this round
	if match.picks[player.UserId] then return end

	-- Validate card is in their hand, then remove it and store as played
	local played = removeCardFromHand(match, player.UserId, cardId)
	if not played then return end

	match.picks[player.UserId] = cardId
	match.lastPlayed = match.lastPlayed or {}
	match.lastPlayed[player.UserId] = played

	-- Acknowledge (optional)
	GameEvent:FireClient(player, "PlayedAck", {cardId = cardId})

	onBothPicked(match)
end)

-- Simple “queue”: first player waits, second starts match
Players.PlayerAdded:Connect(function(player)
	UserId = player.UserId
	print(UserId)
	
	-- loading inventory on player init
	
	local function loadInventory()
		local success, data = pcall(function()
			return InventoryStore:GetAsync(UserId)
		end)
		if success and data then
			decklists[player.UserId] = data.Decks
			-- Inventory = data
			-- print(Inventory)
			-- decks = Inventory.Decks
			-- local deckprint = makeDeck(decks)
			-- print(deckprint)
			end
	end
	loadInventory()
		
	print("before match")
	if gameState.match then
		GameEvent:FireClient(player, "ServerMsg", "Match in progress, please wait.")
		return
	end

	if gameState.waiting and gameState.waiting.Parent then
		local other = gameState.waiting
		gameState.waiting = nil
		startMatch(other, player)
	else
		gameState.waiting = player
		GameEvent:FireClient(player, "ServerMsg", "Waiting for an opponent...")
	end
	print("👤 PlayerAdded:", player.Name, player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	-- If they were waiting, clear queue
	if gameState.waiting == player then
		gameState.waiting = nil
	end

	-- If they were in a match, end it
	local match = gameState.match
	if match then
		local p = getPlayerByUserId(match, player.UserId)
		if p then
			endMatch(match, "Opponent left")
		end
	end
	local winner = nil

	for _, otherPlayer in ipairs(match.players) do
		if otherPlayer ~= player and otherPlayer.Parent == Players then
			winner = otherPlayer
			break
		end
	end

	endMatch(match, "Opponent left", winner)
end)