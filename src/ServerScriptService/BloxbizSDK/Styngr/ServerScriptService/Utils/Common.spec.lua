local filterTable = {
	{
		["name"] = "SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE",
	},
	{
		["name"] = "SUBSCRIPTION_RADIO_TIME_BUNDLE_LARGE",
	},
}

local filterConfigTable = {
	SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE = {
		"269109337",
	},
}

local expectedFilteredTable = {
	SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE = {
		"269109337",
	},
}

return function()
	local CommonUtils = require(script.parent.Common)

	describe("Common", function()
		describe("filterTableByKey", function()
			it("should return table with keys taken from specified key", function()
				local result = CommonUtils.filterTableByKey(filterTable, "name")
				expect(result[1]).to.equal("SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE")
				expect(result[2]).to.equal("SUBSCRIPTION_RADIO_TIME_BUNDLE_LARGE")
			end)
		end)

		describe("filterByTableKeys", function()
			it("should return table based on table keys", function()
				local filterTableKeys = CommonUtils.filterTableByKey(filterTable, "name")
				local result = CommonUtils.filterByTableKeys(filterConfigTable, filterTableKeys)
				expect(result["SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE"][1]).to.equal(
					expectedFilteredTable["SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE"][1]
				)
			end)
		end)
	end)
end
