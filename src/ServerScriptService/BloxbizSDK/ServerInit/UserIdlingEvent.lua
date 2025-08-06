local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)
local RateLimiter = require(script.Parent.Parent.Utils.RateLimiter)
local merge = Utils.merge

local REMOTES_FOLDER = "BloxbizRemotes"

local module = {}

local function queueUserIdling(userIdling)
	Utils.pprint("[SuperBiz] Queue user idling.")

	local event = { event_type = "user_idling", data = userIdling }
	table.insert(BatchHTTP.eventQueue, event)
end

local function getUserIdlingStats(player, timeIdling)
	local userIdlingStats = {
		["timestamp"] = os.time(),
		["time_idling"] = timeIdling,
	}
	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	return merge(merge(userIdlingStats, gameStats), playerStats)
end

local function userIdlingFired(player, timeIdling)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	Utils.pprint("[SuperBiz] User idling fired.")
	local userIdling = getUserIdlingStats(player, timeIdling)
	queueUserIdling(userIdling)
end

function module.init()
	local bloxbizFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	bloxbizFolder.UserIdlingEvent.OnServerEvent:Connect(userIdlingFired)
end

return module