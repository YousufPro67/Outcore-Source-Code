local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("SUPER_BIZ_PLR_ANALYTICS_HISTORY")

local Utils = require(script.Parent.Parent.Utils)

local WAIT_FOR_DATA_TIMEOUT = 10 --seconds

local module = {}
module.playerHistoryCache = {}

local function getUTCDate()
    return os.date("!%Y-%m-%d", os.time())
end

local function getDataStoreKey(playerId)
    return getUTCDate() .. "_" .. playerId
end

function module:_getDataTemplate()
	return {
		["billboardReach"] = {
            --[bloxbizAdId] = true/false,
        },
        ["3dAdUniqueChats"] = {
            --[bloxbizAdId] = true/false,
        },
        ["3dAdUniqueResponse"] = {
            --[bloxbizAdId] = true/false,
        },
	}
end

function module:_fetchPlayerHistory(playerId)
	local success, result = pcall(function()
		return DataStore:GetAsync(getDataStoreKey(playerId))
	end)

	local isNewPlayer = success and result == nil

	if not success then
		Utils.pprint("[SuperBiz] PlayerAnalyticsHistory DataStore fetch failure: " .. result)
		result = module:_getDataTemplate()
	elseif isNewPlayer then
		result = module:_getDataTemplate()
	end

	module.playerHistoryCache[playerId] = result

	return success
end

function module:getPlayerHistory(playerId)
    module:_waitForDataReady(playerId)

    return module.playerHistoryCache[playerId]
end

function module:_savePlayerHistory(playerId)
	local playerHistory = module.playerHistoryCache[playerId]

	if not playerHistory then
		return
	end

	local success, result = pcall(function()
		return DataStore:SetAsync(getDataStoreKey(playerId), playerHistory)
	end)

	if not success then
		Utils.pprint("[SuperBiz] PlayerAnalyticsHistory DataStore save failure: " .. result)
	end

	module.playerHistoryCache[playerId] = nil

	return success
end

function module:_waitForDataReady(playerId)
	local start = tick()
	local hasData = module.playerHistoryCache[playerId]
	local hasTimedOut = false

	while not hasData and not hasTimedOut do
		hasData = module.playerHistoryCache[playerId]
		hasTimedOut = tick() - start > WAIT_FOR_DATA_TIMEOUT
		RunService.Stepped:Wait()
	end

	if hasTimedOut then
		local resetData = module:_getDataTemplate()
		module.playerHistoryCache[playerId] = resetData
	end
end

Players.PlayerAdded:Connect(function(player)
	module:_fetchPlayerHistory(player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	module:_savePlayerHistory(player.UserId)
end)

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        module:_savePlayerHistory(player.UserId)
    end
end)

return module
