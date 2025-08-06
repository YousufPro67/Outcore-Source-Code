local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Utils = require(script.Parent.Parent.Utils)

local DEFAULT_DATA = {
	["gender"] = "Unknown",
	["tier"] = "Tier1",
}
local WAIT_FOR_DATA_TIMEOUT = 10 --seconds
local MAX_RETRY_FETCH = 5

local merge = Utils.merge

local module = {}
module.InferredData = {}

function module:Fetch(playerId)
	local result = Utils.callWithRetry(function()
		local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
		local AdRequestStats = require(script.Parent.Parent.AdRequestStats)

		local player = Players:GetPlayerByUserId(playerId)
		local gameStats = AdRequestStats:getGameStats()
		local playerStats = player and AdRequestStats:getPlayerStats(player)
		local clientPlayerStats = playerStats and AdRequestStats:getClientPlayerStats(player)

		--edge case for when playerId is not in the game
		--example: UserOwnsGamePassAsync(playerId, gamePassId)
		if not player then
			return {
				success = true,
				data = DEFAULT_DATA,
			}
		end

		local postData = {
			player_id = playerId,
			avatar_items = AdRequestStats:getPlayerOutfit(player),
		}
		postData = merge(merge(merge(postData, playerStats), gameStats), clientPlayerStats)
		postData = HttpService:JSONEncode(postData)

		local url = BatchHTTP.getNewUrl("player")

		local response = HttpService:PostAsync(url, postData)
		response = HttpService:JSONDecode(response)

		return response
	end, MAX_RETRY_FETCH)

	local success = result and result.success

	if success then
		result = result.data or DEFAULT_DATA
	else
		Utils.pprint("[SuperBiz] Player profile fetch failure")
		result = DEFAULT_DATA
	end

	module.InferredData[playerId] = result

	return success
end

function module:WaitForDataReady(playerId)
	local start = tick()
	local hasData = module.InferredData[playerId]
	local hasTimedOut = false

	while not hasData and not hasTimedOut do
		hasData = module.InferredData[playerId]
		hasTimedOut = tick() - start > WAIT_FOR_DATA_TIMEOUT
		RunService.Stepped:Wait()
	end

	if hasTimedOut then
		module.InferredData[playerId] = DEFAULT_DATA
	end
end

function module:Get(playerId)
	if not Players:GetPlayerByUserId(playerId) then
		module:Fetch(playerId)
	end

	module:WaitForDataReady(playerId)

	return module.InferredData[playerId]
end

Players.PlayerAdded:Connect(function(player)
	module:Fetch(player.UserId)
end)

for _, player in pairs(game.Players:GetPlayers()) do
	module:Fetch(player.UserId)
end

return module
