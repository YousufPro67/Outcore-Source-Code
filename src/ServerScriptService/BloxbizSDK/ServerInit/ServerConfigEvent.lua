local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local InternalConfig = require(script.Parent.Parent.InternalConfig)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Ad3DServer = require(script.Parent.Parent.Ad3DServer)
local PortalServer = require(script.Parent.Parent.PortalServer)
local BillboardServer = require(script.Parent.Parent.BillboardServer)
local ConfigReader = require(script.Parent.Parent.ConfigReader)
local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

local DYNAMIC_AD_UNITS_WAIT_TIME = 60

local function queueServerConfig(serverStartup)
	local event = {event_type="server_config", data=serverStartup}
	table.insert(BatchHTTP.eventQueue, event)
end

local function isTableEmpty(tableToScan)
	for _, _ in pairs(tableToScan) do
		return false
	end

	return true
end

local function getCombinedConfig()
	local bloxbizConfig = ConfigReader:getFullConfigWithDefaults()
	local combinedConfig = {}

	local function restrictTypesAndAdd(key, val)
		local keyType = type(key)
		local valueType = type(val)

		if keyType ~= 'string' then
			return
		end

		if valueType == 'boolean' or valueType == 'number' or valueType == 'string' then
			combinedConfig[key] = val
		end
	end

	for key, val in pairs(bloxbizConfig) do
		restrictTypesAndAdd(key, val)
	end

	for key, val in pairs(InternalConfig) do
		restrictTypesAndAdd(key, val)
	end

	return combinedConfig
end

local function sendServerConfigEvent()
	local combinedConfig = getCombinedConfig()

	local startupStats = {
		["timestamp"] = os.time(),
		["StaticAdsEnabled"] = not isTableEmpty(BillboardServer.CentralBillboardServer.BillboardServerInstances),
		["3dAdsEnabled"] = not isTableEmpty(Ad3DServer.Ad3DServerInstances),
		["InventorySizingEnabled"] = Ad3DServer.hasInventorySizing,
		["PortalAdsEnabled"] = not isTableEmpty(PortalServer.Instances),
	}
	local gameStats = AdRequestStats:getGameStats()

	local eventData = merge(merge(combinedConfig, startupStats), gameStats)
	queueServerConfig(eventData)
end

return function()
	task.delay(DYNAMIC_AD_UNITS_WAIT_TIME, sendServerConfigEvent)
end