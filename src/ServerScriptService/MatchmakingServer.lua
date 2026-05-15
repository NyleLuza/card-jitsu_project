-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local matchmaking = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Matchmaking")
local matchFound = matchmaking:WaitForChild("MatchFound")
local readyUp = matchmaking:WaitForChild("ReadyUp")

local gui = script.Parent
local function findUI(name)
	return gui:FindFirstChild(name, true)
end

local battleButton = findUI("BattleButton")
local queueFrame = findUI("QueueFrame")
local matchFrame = findUI("MatchFrame")
local opponentName = findUI("OpponentName")
local opponentImage = findUI("OpponentImage")
local readyButton = findUI("ReadyButton")

local isReady = false

-- UI Initialization
battleButton.Visible = true
queueFrame.Visible = false
matchFrame.Visible = false

-- Match Found Logic
matchFound.OnClientEvent:Connect(function(opponent)
	print("[UI Debug]: MatchFound event received. Opponent: " .. (opponent and opponent.Name or "None"))

	if not opponent then
		-- Opponent left the ring
		matchFrame.Visible = false
		battleButton.Visible = true
		isReady = false
		readyButton.Text = "READY"
		return
	end

	-- Show Match UI
	battleButton.Visible = false
	queueFrame.Visible = false
	matchFrame.Visible = true
	opponentName.Text = opponent.Name
	opponentImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..opponent.UserId.."&width=420&height=420&format=png"
end)

-- Ready Up Logic
readyButton.MouseButton1Click:Connect(function()
	isReady = not isReady
	readyButton.Text = isReady and "CANCEL" or "READY"
	print("[UI Debug]: Sending Ready status: " .. tostring(isReady))
	readyUp:FireServer(isReady)
end)
