-- @ScriptType: ModuleScript

-- CardConfig.spec.lua

return function()
	local CardConfig = require(game.ReplicatedStorage.Cards.CardConfig) -- adjust path
	describe("CardConfig", function()
		it("every card has required fields", function()
			for key, card in pairs(CardConfig) do
				expect(type(key)).to.equal("string")
				expect(type(card)).to.equal("table")

				expect(type(card.id)).to.equal("string")
				expect(type(card.name)).to.equal("string")
				expect(type(card.element)).to.equal("string")

				-- value SHOULD be a number for gameplay comparisons.
				-- This test will FAIL for InfernoTitan because value = "8" (string)
				expect(type(card.value)).to.equal("number")

				expect(type(card.weight)).to.equal("number")
			end
		end)

		it("card ids are unique", function()
			local seen = {}
			for _, card in pairs(CardConfig) do
				expect(seen[card.id]).to.equal(nil)
				seen[card.id] = true
			end
		end)

		it("elements are within allowed set", function()
			local allowed = { fire = true, snow = true, water = true }
			for _, card in pairs(CardConfig) do
				expect(allowed[card.element]).to.equal(true)
			end
		end)
	end)
end