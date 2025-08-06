local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local InternalConfig = require(script.Parent.Parent.InternalConfig)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)

local module = {}

local function sendEvent()
	local playerStats = AdRequestStats:getAllPlayerStatsWithClientStats()

	local gameStats = AdRequestStats:getGameStats()
	local playerEvent = { timestamp = os.time(), game = gameStats, players = playerStats }

	local event = { event_type = "heart_beat", data = playerEvent }
	table.insert(BatchHTTP.eventQueue, event)
	Utils.pprint("[SuperBiz] Heart beat sent.")
end

local function backgroundProcess()
	while true do
		sendEvent()
		task.wait(InternalConfig.TIME_BETWEEN_HEART_BEAT)
	end
end

function module.init()
    task.spawn(backgroundProcess)
end

return module