local BatchHTTP = {}

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Utils = require(script.Parent.Utils)

local AdRequestStats = require(script.Parent.AdRequestStats)
local InternalConfig = require(script.Parent.InternalConfig)
local ConfigReader = require(script.Parent.ConfigReader)

BatchHTTP.eventQueue = {}

local MAX_EVENT_BATCH = InternalConfig.MAX_EVENT_BATCH
local MAX_EVENT_BATCH_SIZE = InternalConfig.MAX_EVENT_BATCH_SIZE
local MAX_RETRY_EVENTS = InternalConfig.MAX_RETRY_EVENTS
local BATCH_EVENTS_WAIT_TIME = InternalConfig.BATCH_EVENTS_WAIT_TIME

local dataStore = DataStoreService:GetDataStore("BLOXBIZ_EVENTS")

function BatchHTTP.getAlphanumericGuidWithLength(len)
	local guid = HttpService:GenerateGUID(false)
	guid = guid:gsub("-", "")
	guid = guid:sub(1, len)

	return guid
end

function BatchHTTP.getNewUrl(query)
	local baseUrl = require(script.BaseUrl).getBaseUrl()

	if query:sub(1, 1) == "/" then
		query = query:sub(2)
	end

	local newUrl = baseUrl .. "/" .. query .. "?d={GUID}"

	newUrl = newUrl:gsub("{GAME_ID}", tostring(game.GameId), 1)
	newUrl = newUrl:gsub("{GUID}", BatchHTTP.getAlphanumericGuidWithLength(12), 1)
	newUrl = newUrl:gsub("{GUID}", BatchHTTP.getAlphanumericGuidWithLength(12), 1)

	return newUrl
end

function BatchHTTP.httpSendEvents(data)
	local jsonPayload = HttpService:JSONEncode(data)
	local url = BatchHTTP.getNewUrl("events")
	local success, result = pcall(function()
		return HttpService:PostAsync(url, jsonPayload, nil, nil, BatchHTTP:getGeneralRequestHeaders())
	end)

	if not success then
		if string.find(result, "401") then
			warn("[Super Biz] API key auth failed. Ensure you are on latest plugin version and have set your API key via the plugin.")
		else
			error(result)
		end
	else
		local jsonSuccess, responseData = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		responseData = jsonSuccess and responseData or {}

		if responseData.errors then
			for _, err in ipairs(responseData.errors) do
				warn("[Super Biz] " .. err.message)
			end
		end
	end
end

function BatchHTTP.dataStoreSendEvents(data)
	local timestamp = DateTime.now():ToIsoDate()
	local serverId = tostring(game.JobId)
	local guid = BatchHTTP.getAlphanumericGuidWithLength(12)

	if serverId == "" then
		serverId = "STUDIO"
	end

	--chop the server id because of the datastore key limit
	serverId = string.sub(serverId, #serverId-12, #serverId)

	local key = timestamp .. "_" .. serverId .. "_" .. guid
	dataStore:SetAsync(key, HttpService:JSONEncode(data))
end

function BatchHTTP.getGeneralRequestHeaders()
	return {
		["API-KEY"] = require(script.ApiKey).getApiKey()
	}
end

function BatchHTTP.batchSendEvents()
	local data = {}

	local countEvents = 0
	local batchByteSize = 0

	for _ = 1, MAX_EVENT_BATCH do
		local item = table.remove(BatchHTTP.eventQueue, 1)

		if not item then
			break
		end

		local itemByteSize = #HttpService:JSONEncode(item)
		local maxSizeExceeded = batchByteSize + itemByteSize > MAX_EVENT_BATCH_SIZE
		if maxSizeExceeded then
			return
		end

		table.insert(data, item)
		countEvents += 1
		batchByteSize += itemByteSize
	end

	if countEvents == 0 then
		return
	end

	Utils.pprint("[Super Biz] Batched " .. countEvents .. " events")

	if ConfigReader:read("UseDataStoresNotHttp") then
		Utils.callWithRetry(function()
			BatchHTTP.dataStoreSendEvents(data)
		end, MAX_RETRY_EVENTS)
	else
		Utils.callWithRetry(function()
			BatchHTTP.httpSendEvents(data)
		end, MAX_RETRY_EVENTS)
	end
end

function BatchHTTP.backgroundProcessEvents()
	while true do
		BatchHTTP.batchSendEvents()
		task.wait(BATCH_EVENTS_WAIT_TIME)
	end
end

-- Utility HTTP function that will auto encode/decode JSON and return any ad server error messages
function BatchHTTP.request(method, url, data, ignoreWarnings): (boolean, table | string)
	if not string.find(url, "://") then
		url = BatchHTTP.getNewUrl(url)
	end

	data = data or {}

	local headers = BatchHTTP.getGeneralRequestHeaders()
	headers["Content-Type"] = "application/json"

	local reqData = AdRequestStats:getGameStats()
	for k, v in pairs(data) do
		reqData[k] = v
	end

	local result =  HttpService:RequestAsync({
		Method = string.upper(method),
		Url = url,
		Headers = headers,
		Body = HttpService:JSONEncode(reqData),
	})

	local success = result.Success
	local jsonSuccess, jsonResult = pcall(function()
		return HttpService:JSONDecode(result.Body)
	end)

	if not jsonSuccess then
		if not ignoreWarnings then
			warn(jsonResult)
		end
		
		return false, {}
	end

	if not success or jsonResult.status ~= "ok" then
		if not ignoreWarnings then
			warn(jsonResult.message or HttpService:JSONEncode(jsonResult))
		end
		
		return false, jsonResult
	end

	return true, jsonResult
end

function BatchHTTP.init()
	task.spawn(BatchHTTP.backgroundProcessEvents)
end

game:BindToClose(function()
	local isQueueEmpty = #BatchHTTP.eventQueue == 0

	while not isQueueEmpty do
		BatchHTTP.batchSendEvents()
		isQueueEmpty = #BatchHTTP.eventQueue == 0
	end
end)

return BatchHTTP
