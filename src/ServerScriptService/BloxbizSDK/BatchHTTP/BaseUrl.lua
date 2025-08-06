local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local FETCH_FRESHNESS_TIME = 5 --minutes

local dataStore = DataStoreService:GetDataStore("BLOXBIZ_SETTINGS")
local latestUrl = nil

local BaseUrl = {}
BaseUrl.lastFetch = 0

local function updateLocalBaseUrl()
	local fetchSuccess, fetchResult = pcall(function()
		return dataStore:GetAsync("BASE_URL")
	end)

	if fetchSuccess then
		latestUrl = fetchResult
		BaseUrl.lastFetch = tick()
	end
end

function BaseUrl.getBaseUrl()
	local cachedValueIsExpired = tick() - BaseUrl.lastFetch > (FETCH_FRESHNESS_TIME * 60)

	if cachedValueIsExpired then
		task.spawn(updateLocalBaseUrl)
	end

    local InternalConfig = require(ServerScriptService.BloxbizSDK.InternalConfig)

	if InternalConfig.USE_INTERNAL_CONFIG_BASE_URL then
		return InternalConfig.BASE_URL
	end

    return latestUrl or InternalConfig.BASE_URL
end

updateLocalBaseUrl()

return BaseUrl
