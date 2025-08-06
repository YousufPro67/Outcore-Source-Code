local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')

local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

local CLIENT_RESPONSE_WAIT = 180

local module = {}
module.teleportedPlayers = {}

local function queueGameJoin(join)
	local event = { event_type = "game_join", data = join }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueGameTeleport(teleport)
	local event = { event_type = "game_teleport", data = teleport }
	table.insert(BatchHTTP.eventQueue, event)
end

function module:setTeleported(player)
	if self.teleportedPlayers[player.UserId] then
		return
	end

	self.teleportedPlayers[player.UserId] = true

	task.delay(10, function()
		self.teleportedPlayers[player.UserId] = nil
	end)
end

function module:trackGameTeleport(player, placeId, portalId, teleportGuid, ignoreTimeout)
	local waitStart = tick()
	local timeout = false
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)

	self:setTeleported(player)

	repeat
		task.wait()
		timeout = tick() - waitStart > 10
	until player.Parent ~= Players or timeout or ignoreTimeout

	if timeout and ignoreTimeout ~= true then
		return
	end

	local teleportStats = {
		["timestamp"] = os.time(),
		["teleport_place_id"] = placeId,
		["bloxbiz_ad_id"] = portalId or -1,
		["teleport_guid"] = teleportGuid or "",
	}

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	local eventData = merge(merge(merge(teleportStats, gameStats), playerStats), clientPlayerStats)
	queueGameTeleport(eventData)

	return eventData
end

function module:trackGameJoin(player)
	local success, joinData = pcall(function()
		return player:GetJoinData()
	end)

	if success then
		local teleportData = joinData.TeleportData
		if typeof(teleportData) ~= "table" then
			teleportData = {}
		end

		local joinStats = {
			["timestamp"] = os.time(),
			["source_place_id"] = joinData.SourcePlaceId or -1,
			["source_game_id"] = joinData.SourceGameId or -1,
			["teleport_guid"] = teleportData.teleportGuid or "",
			["bloxbiz_ad_id"] = teleportData.bloxbizAdId or -1,
			["launch_data"] = joinData.LaunchData or "",
			["session_id"] = HttpService:GenerateGUID(),
		}

		local gameStats = AdRequestStats:getGameStats()
		local playerStats = AdRequestStats:getPlayerStats(player)
		local clientPlayerStats = AdRequestStats:getClientPlayerStats(player, CLIENT_RESPONSE_WAIT)

		local eventData = merge(merge(merge(joinStats, gameStats), playerStats), clientPlayerStats)
		queueGameJoin(eventData)

		return eventData
	end
end

function module:trackJoinAndTeleport(player)
	player.OnTeleport:connect(function(_, placeId)
		if self.teleportedPlayers[player.UserId] then
			return
		end

		self:trackGameTeleport(player, placeId)
	end)

	self:trackGameJoin(player)
end

function module.init()
	Players.PlayerAdded:Connect(function(player)
		module:trackJoinAndTeleport(player)
	end)
end

return module