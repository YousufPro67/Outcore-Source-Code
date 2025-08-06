local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTES_FOLDER = "BloxbizRemotes"

local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local RateLimiter = require(script.Parent.Parent.Utils.RateLimiter)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

local module = {}
module.lastPlayerOpenedTime = {}

local function queueItemTryOn(itemTryOn)
	local event = { event_type = "popup_shop_try_on", data = itemTryOn }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueShopOpen(shopOpen)
	local event = { event_type = "popup_shop_open", data = shopOpen }
	table.insert(BatchHTTP.eventQueue, event)
end

function module:onItemTryOn(player, eventStats)
    eventStats = {
        ["bloxbiz_ad_id"] = eventStats.bloxbizAdId,
        ["item_id"] = eventStats.itemId,
        ["asset_name"] = eventStats.assetName,
        ["item_category"] = eventStats.itemCategory,
        ["timestamp"] = os.time(),
    }

    local gameStats = AdRequestStats:getGameStats()
    local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

    eventStats = merge(merge(eventStats, gameStats), playerStats)
    queueItemTryOn(eventStats)

    return eventStats
end

function module:onPopUpShopOpened(player, eventStats)
    local bloxbizAdId = eventStats.bloxbizAdId

    if not module.lastPlayerOpenedTime[player] then
        module.lastPlayerOpenedTime[player] = {}
    end

    local playerTimeTable = module.lastPlayerOpenedTime[player]

	playerTimeTable[bloxbizAdId] = tick()
end

function module:onPopUpShopClosed(player, eventStats)
    if not module.lastPlayerOpenedTime[player] then
        return
    end

    local playerTimeTable = module.lastPlayerOpenedTime[player]

    local bloxbizAdId = eventStats.bloxbizAdId
    local lastOpened = playerTimeTable[bloxbizAdId]

    if lastOpened then
        local timeSpent = tick() - lastOpened
        playerTimeTable[bloxbizAdId] = nil

        eventStats = {
            ["bloxbiz_ad_id"] = bloxbizAdId,
            ["time_spent"] = timeSpent,
            ["timestamp"] = os.time(),
        }

        local gameStats = AdRequestStats:getGameStats()
        local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

        eventStats = merge(merge(eventStats, gameStats), playerStats)
        queueShopOpen(eventStats)

        return eventStats
    end
end

function module:connectToEvents()
    local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
    local popUpShopEvent = remotesFolder:WaitForChild("PopUpShopEvent")

    popUpShopEvent.OnServerEvent:Connect(function(player, eventType, eventStats)
        if RateLimiter:checkRateLimiting(player) then
            return
        end

        if eventType == "ItemTryOn" then
            self:onItemTryOn(player, eventStats)
        elseif eventType == "PopUpShopOpened" then
            self:onPopUpShopOpened(player, eventStats)
        elseif eventType == "PopUpShopClosed" then
            self:onPopUpShopClosed(player, eventStats)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if module.lastPlayerOpenedTime[player] then
            module.lastPlayerOpenedTime[player] = nil
        end
    end)
end

function module.init()
    module:connectToEvents()
end

return module