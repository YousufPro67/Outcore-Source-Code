local PolicyService = game:GetService("PolicyService")

local Common = {}

local SECONDS_IN_A_DAY = 86400

function Common.filterTableByKey(filterTable: table, key: string): table
	local filteredKeys = {}

	for _, v in pairs(filterTable) do
		table.insert(filteredKeys, v[key])
	end

	return filteredKeys
end

function Common.filterByTableKeys(filterTable: table, filterKeys: table): table
	local filteredItems = {}

	for k, v in pairs(filterTable) do
		if table.find(filterKeys, k) then
			filteredItems[k] = v
		end
	end

	return filteredItems
end

function Common.getPlayerAgeInfo(player: Player): string
	local function getEpoch(areAdsAllowed: boolean): number
		assert(type(areAdsAllowed) == "boolean", "AreAdsAllowed has to be boolean")

		local epochStart = os.time() - SECONDS_IN_A_DAY
		if areAdsAllowed then
			epochStart = os.time({ year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0 })
		end

		local dateInSeconds = os.date("!*t", epochStart)
		return string.format("%i-%02i-%02i", dateInSeconds.year, dateInSeconds.month, dateInSeconds.day)
	end

	local ok, result = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	assert(ok, "Can't get policy")

	local date = getEpoch(result.AreAdsAllowed)

	return date, result.AreAdsAllowed
end

return Common
