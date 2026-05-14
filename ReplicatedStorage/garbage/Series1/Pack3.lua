-- @ScriptType: ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardFolder = ReplicatedStorage:WaitForChild("Cards")

local FireSet = CardFolder:WaitForChild("Fire")
local SnowSet = CardFolder:WaitForChild("Snow")
local WaterSet = CardFolder:WaitForChild("Water")


local Pack3 = {
	id = "p3",
	name = "Generations Pack",
	description = "A balanced pack containing Fire, Water, and Snow cards.",
	cost = 100,
	num_cards = 6,
	cards = {
		require(FireSet:WaitForChild("BlazeImp")),
		require(FireSet:WaitForChild("PyroDrake")),
		require(SnowSet:WaitForChild("Frostling")),
		require(SnowSet:WaitForChild("CrystalGolem")),
		require(WaterSet:WaitForChild("AquaSprite")),
		require(WaterSet:WaitForChild("AbyssLeviathan")),
	}
}


return Pack3
