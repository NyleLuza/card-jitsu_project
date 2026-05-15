-- @ScriptType: Script
--local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)
--print("RunTests.server.lua STARTED")
--local results = TestEZ.TestBootstrap:run({
--	script.Parent
--})

--print("Failures:", results.failureCount)

-- ServerScriptService/Tests/RunTests.server.lua (Script)

print("=== Test Runner START ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local testEZModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("TestEZ")
local TestEZ = require(testEZModule)

print("TestEZ loaded:", TestEZ ~= nil)

local results = TestEZ.TestBootstrap:run({ script.Parent })

print("=== Test Runner DONE ===")
print("Failures:", results.failureCount)
print("Errors:", results.errors)