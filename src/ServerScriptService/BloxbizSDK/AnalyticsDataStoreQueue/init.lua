local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DATA_STORE_NAME = "SUPER_BIZ_ANALYTICS"
local DATA_STORE_NUM_BUCKETS = 5
local UPDATE_DATA_STORE_INTERVAL = 60
local DEBUG_AD = {
    ad_format = "3d",
}

local AdFilter = require(script.Parent.AdFilter)
local Utils = require(script.Parent.Utils)
local PlayerAnalyticsHistory = require(script.PlayerAnalyticsHistory)

local module = {}
module._updateQueue = {}

local function getUTCDate()
    return os.date("!%Y-%m-%d", os.time())
end

local function truncateToThreeDecimals(num)
    return math.floor(num * 1000) / 1000
end

local basicMigrateTable
basicMigrateTable = function(oldTable, newTable)
	for key, value in pairs(newTable) do
		local isMissingValue = oldTable[key] == nil
		local bothAreTableValues = type(oldTable[key]) == "table" and type(value) == "table"

		if isMissingValue then
			oldTable[key] = value
		elseif bothAreTableValues then
			basicMigrateTable(oldTable[key], value)
		end
	end

	return oldTable
end

function module:initializeQueue()
    module:_onServerClose()

    task.spawn(function()
        while task.wait(UPDATE_DATA_STORE_INTERVAL) do
            module:_consumeQueue()
        end
    end)
end

-- Consequent arguments after bloxbizAdId are to index through a given DataStore
-- The last argument should be the increment number to change the DataStore value
function module:queueChange(bloxbizAdId, ...)
    local adInStorage = module:_getAdFromAdId(bloxbizAdId)
    if not adInStorage then
        Utils.pprint("[Super Biz] Invalid bloxbiz_ad_id when changing analytics DataStore")
        return
    end

    local isAdFormatSupported = module:_getDefaultAnalyticsFromAdFormat(adInStorage.ad_format)
    if not isAdFormatSupported then
        Utils.pprint("[Super Biz] Ad format is not supported yet for id", bloxbizAdId)
        return
    end

    local partitionBucket = tostring(bloxbizAdId % DATA_STORE_NUM_BUCKETS)
    local utcDate = getUTCDate()

    local change = {tostring(bloxbizAdId), ...}

    local incrementExists = type(change[#change] == "number")
    if not incrementExists then
        Utils.pprint("[Super Biz] Analytics DataStore module expected a number when making a change")
        return
    end

    local existingQueueEntry = nil
    for _, entry in module._updateQueue do
        local isDuplicateEntry = entry.dataStoreKey == partitionBucket and entry.dataStoreScope == utcDate
        if isDuplicateEntry then
            existingQueueEntry = entry
            break
        end
    end

    if existingQueueEntry then
        table.insert(existingQueueEntry.changesList, change)

        Utils.pprint("[Super Biz] DataStore Analytics: inserted change into queue entry")
        Utils.pprint(existingQueueEntry)

        return existingQueueEntry
    end

    local queueEntry = {
        dataStoreKey = partitionBucket,
        dataStoreScope = utcDate,
        changesList = {change}
    }
    table.insert(module._updateQueue, queueEntry)

    Utils.pprint("[Super Biz] DataStore Analytics: inserted entry into update queue")
    Utils.pprint(queueEntry)

    return queueEntry
end

function module:_getAdFromAdId(idToValidate)
    local allAds = AdFilter:GetAllEnabledAds()
    idToValidate = tonumber(idToValidate)

    for _, ad in allAds do
        if ad.bloxbiz_ad_id == idToValidate then
            return ad
        end
    end

    if idToValidate <= -1 then
        return DEBUG_AD
    end
end

function module:_getDefaultAnalyticsFromAdFormat(adFormat)
    if adFormat == '3d' then
        return require(script.DefaultAnalytics3d)
    end
end

function module:_getInitialDataStoreValue(queuedEntry)
    local dataStoreValue = {}

    local changesList = queuedEntry.changesList
    for _, change in changesList do
        local bloxbizAdId = tostring(change[1])

        local adInStorage = module:_getAdFromAdId(tonumber(bloxbizAdId))
        if not adInStorage then
            return
        end

        if not dataStoreValue[bloxbizAdId] then
            dataStoreValue[bloxbizAdId] = {}
        end

        dataStoreValue[bloxbizAdId] = module:_getDefaultAnalyticsFromAdFormat(adInStorage.ad_format)
    end

    return dataStoreValue
end

function module:_applyChangeToAnalyticsDict(analyticsDict, keyPathAndIncrement)
    local success = pcall(function()
        local lastTable = analyticsDict
        local lastKey = keyPathAndIncrement[#keyPathAndIncrement - 1]
        local increment = keyPathAndIncrement[#keyPathAndIncrement]

        for i = 1, #keyPathAndIncrement - 2 do
            local currentKey = keyPathAndIncrement[i]
            lastTable = lastTable[currentKey]
        end

        if not lastTable[lastKey] then
            error("[Super Biz] Missing index when incrementing analytics dict")
        end

        local newValue = truncateToThreeDecimals(lastTable[lastKey] + increment)
        lastTable[lastKey] = newValue
    end)

    return success
end

function module:_migrateOldTables(analyticsDict)
    for bloxbizAdId, oldAnalyticsTable in analyticsDict do
        local adInStorage = module:_getAdFromAdId(tonumber(bloxbizAdId))
        if not adInStorage then
            continue
        end

        local newAnalyticsTable = module:_getDefaultAnalyticsFromAdFormat(adInStorage.ad_format)
        basicMigrateTable(oldAnalyticsTable, newAnalyticsTable)
    end
end

function module:_datastoreUpdateAsync(queueIndex)
    local queueEntry = module._updateQueue[queueIndex]
    table.remove(module._updateQueue, queueIndex)

    local partitionBucket = queueEntry.dataStoreKey
    local unixDay = queueEntry.dataStoreScope
    local changesList = queueEntry.changesList

    local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME, unixDay)
    dataStore:UpdateAsync(partitionBucket, function(analyticsDictJSON)
        local analyticsDict

        if analyticsDictJSON then
            analyticsDict = HttpService:JSONDecode(analyticsDictJSON)
            module:_migrateOldTables(analyticsDict)
        else
            analyticsDict = module:_getInitialDataStoreValue(queueEntry)
        end

        Utils.pprint("[Super Biz] DataStore Analytics: updating current analytics dict")
        Utils.pprint(analyticsDict)

        for _, currentChange in changesList do
           local success = module:_applyChangeToAnalyticsDict(analyticsDict, currentChange)

           if not success then
                Utils.pprint("[Super Biz] DataStore Analytics: invalid indexing when updating analytics data")
           end
        end

        Utils.pprint("[Super Biz] DataStore Analytics: updated to new analytics dict")
        Utils.pprint(analyticsDict)

        return HttpService:JSONEncode(analyticsDict)
    end)
end

function module:_consumeQueue()
    local queueSize = #module._updateQueue
    if queueSize == 0 then
        return
    end

    for queueIndex = 1, queueSize do
        module:_datastoreUpdateAsync(queueIndex)
    end
end

function module:_onServerClose()
    game:BindToClose(function()
        module:_consumeQueue()
    end)
end

return module