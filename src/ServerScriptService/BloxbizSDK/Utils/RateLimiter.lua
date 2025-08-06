--[[
	Counting module: limits number of client calls to server per player per minute
	to (Config).RateLimitThreshold.
]]

local RateLimiter = { rateLimitingEvents = {} }

local Utils = require(script.Parent.Parent.Utils)
local ConfigReader = require(script.Parent.Parent.ConfigReader)
local RATE_LIMIT_THRESHOLD = ConfigReader:read("RateLimitThreshold")

--Adds rate counter object (os.time) to player debounce table. Removes expired objects.
--Returns bool: whether player debounce table is above rate limit within past min.
function RateLimiter:checkRateLimiting(player)
	local currentTime = os.time()
	local expiredTime = currentTime - 60
	local playerId = player.UserId
	local playerEventsNotExpired = {}

	if not self.rateLimitingEvents[playerId] then
		self.rateLimitingEvents[playerId] = {}
	end

	for _, eventTime in ipairs(self.rateLimitingEvents[playerId]) do
		if eventTime >= expiredTime then
			table.insert(playerEventsNotExpired, eventTime)
		end
	end

	self.rateLimitingEvents[playerId] = playerEventsNotExpired

	table.insert(self.rateLimitingEvents[playerId], currentTime)

	if #self.rateLimitingEvents[playerId] > RATE_LIMIT_THRESHOLD then
		Utils.pprint(
			"[SuperBiz] Rate limiting threshold of "
				.. tostring(RATE_LIMIT_THRESHOLD)
				.. " hit by player ID: "
				.. tostring(playerId)
		)
		return true
	end

	return false
end

return RateLimiter
