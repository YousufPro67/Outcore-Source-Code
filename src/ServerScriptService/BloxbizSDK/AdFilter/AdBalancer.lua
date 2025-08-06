local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local BatchHttp = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)
local InternalConfig = require(script.Parent.Parent.InternalConfig)
local ConfigReader = require(script.Parent.Parent.ConfigReader)

local DATASTORE_FETCH_EMPTY_FALLBACK = {}
local FETCH_INTERVAL = 5 --minutes
local WAIT_FOR_DATA_TIMEOUT = 10 --seconds
local MAX_RETRY_GET_RATIOS = 5

local dataStore = DataStoreService:GetDataStore("BLOXBIZ_ADS_DELIVERY_RATIOS")

local AdBalancer = {}
AdBalancer.LatestRatios = nil

function AdBalancer.WaitForDataReady()
	local start = tick()
	local hasTimedOut = false

	while not AdBalancer.LatestRatios and not hasTimedOut do
		hasTimedOut = tick() - start > WAIT_FOR_DATA_TIMEOUT
		RunService.Stepped:Wait()
	end

	if hasTimedOut then
		AdBalancer.LatestRatios = {}

		Utils.pprint("[SuperBiz] AdBalancer wasn't able to fetch ratios on time")
	end
end

function AdBalancer:GetAdRatio(bloxbizAdId)
	AdBalancer.WaitForDataReady()

	local hasRatio = AdBalancer.LatestRatios[tostring(bloxbizAdId)]

	if hasRatio then
		return AdBalancer.LatestRatios[tostring(bloxbizAdId)].ratio
	end
end

function AdBalancer.UpdateRatiosWithHttp()
	local AdFilter = require(script.Parent)
	local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
	local adsList = AdFilter:GetAllEnabledAds()
	local truncatedAdsList = {}

	local url = BatchHttp.getNewUrl("ratios")

	for index, ad in ipairs(adsList) do
		local adInfoDict = {
			["bloxbiz_ad_id"] = ad.bloxbiz_ad_id,
			["ad_version"] = ad.ad_version or -1
		}
		table.insert(truncatedAdsList, index, adInfoDict)
	end

	local postData = {
		["sdk_version"] = InternalConfig.SDK_VERSION,
		["ad_ids"] = truncatedAdsList,
	}
	local gameStats = AdRequestStats:getGameStats()

	postData = Utils.merge(postData, gameStats)

	local jsonedData = HttpService:JSONEncode(postData)
	local httpOkay, result = pcall(HttpService.PostAsync, HttpService, url, jsonedData)

	if httpOkay then
		result = HttpService:JSONDecode(result)
		AdBalancer.LatestRatios = result.ratios

		return true
	else
		return result
	end
end

function AdBalancer.UpdateRatiosWithDataStore()
	local fetchSuccess, fetchResult = pcall(function()
		return dataStore:GetAsync("delivery_ratios")
	end)

	if not fetchSuccess then
		return fetchResult
	end

	if fetchResult then
		AdBalancer.LatestRatios = fetchResult.ratios
	else
		AdBalancer.LatestRatios = DATASTORE_FETCH_EMPTY_FALLBACK
	end

	return true
end

function AdBalancer.UpdateOnInterval()
	while true do
		if ConfigReader:read("UseDataStoresNotHttp") then
			Utils.callWithRetry(AdBalancer.UpdateRatiosWithDataStore, MAX_RETRY_GET_RATIOS)
		else
			Utils.callWithRetry(AdBalancer.UpdateRatiosWithHttp, MAX_RETRY_GET_RATIOS)
		end

		task.wait(FETCH_INTERVAL * 60)
	end
end

task.spawn(AdBalancer.UpdateOnInterval)

return AdBalancer
