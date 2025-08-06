local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local FETCH_FRESHNESS_TIME = 5 --minutes
local FALLBACK_KEY = "empty"

local dataStore = DataStoreService:GetDataStore("BLOXBIZ_SETTINGS")
local latestApiKey = nil

local warnedForNoKey = false

local ApiKey = {}
ApiKey.lastFetch = 0

local function updateLocalApiKey()
	local fetchSuccess, fetchResult = pcall(function()
		return dataStore:GetAsync("API_KEY")
	end)

	if fetchSuccess then
		--Fallback is needed because PostAsync headers can't be empty
		latestApiKey = fetchResult or FALLBACK_KEY
		ApiKey.lastFetch = tick()
	end
end

function ApiKey.getApiKey()
	local cachedValueIsExpired = tick() - ApiKey.lastFetch > (FETCH_FRESHNESS_TIME * 60)

	if cachedValueIsExpired then
		task.spawn(updateLocalApiKey)
	end

	local InternalConfig = require(ServerScriptService.BloxbizSDK.InternalConfig)

	if InternalConfig.USE_INTERNAL_CONFIG_API_KEY then
		return InternalConfig.API_KEY
	end

	local key = latestApiKey or InternalConfig.API_KEY

	if (key == "empty" or not key) and not warnedForNoKey then
		warn("[Super Biz] You are using the Super Biz SDK without an API key! This may break certain SDK features.")
		warn('[Super Biz] Use the Super Biz Plugin to set your API key.')
		warn("[Super Biz] https://docs.superbiz.gg/sdk-setup-updates")

		warnedForNoKey = true
	end

	return key
end

updateLocalApiKey()

return ApiKey
