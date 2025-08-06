local HttpService = game:GetService("HttpService")

local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local AdFilter = require(script.Parent.Parent.AdFilter)
local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge
local CreateBillboard = require(script.Parent.Parent.Ad3DClient.CharacterAd.MetricsClient.CreateBillboard)

local PopUpAdHelper = {}
PopUpAdHelper.__index = PopUpAdHelper
PopUpAdHelper._registeredAds = {}

local function getAdsStatsForStaticAd(playerStats)
    local fakeBillboard = CreateBillboard()
    local partStats = AdRequestStats:getPartStats(fakeBillboard.AdUnit)
    fakeBillboard:Destroy()

    local gameStats = AdRequestStats:getGameStats()
    local lightingStats = AdRequestStats:getGameLightingStats()
    local stats = merge(merge(gameStats, partStats), lightingStats)
    stats["players"] = playerStats

    return stats
end

function PopUpAdHelper:isAdTargetedForPlayer(player)
    local adConfig = self.adConfig
    local playerStats, clientPlayerStats
    if not clientPlayerStats then
        clientPlayerStats = AdRequestStats:getClientPlayerStats(player)
    end
    playerStats = merge(clientPlayerStats, AdRequestStats:getPlayerStats(player))
    playerStats = { playerStats }

    local adsStats = getAdsStatsForStaticAd(playerStats)
    local unfilteredAdsList = {adConfig}
    local filteredAdsList = AdFilter:GetAds(adsStats, unfilteredAdsList)
    for _, ad in filteredAdsList do
        if ad.bloxbiz_ad_id == adConfig.bloxbiz_ad_id then
            return true
        end
    end

    return false
end

function PopUpAdHelper:registerEvent(...)
    local PublicAPI = require(script.Parent)
    local bloxbizAdId = self.adConfig.bloxbiz_ad_id

    local args = {...}
    table.insert(args, bloxbizAdId)

    return PublicAPI.registerEventForAd(unpack(args))
end

function PopUpAdHelper.new(adUnit, adConfig)
    if not adUnit or not adConfig then
        error("[Super Biz] Missing argument when registering pop up ad")
    end
    if adConfig.Name ~= "AdConfig" then
        error("[Super Biz] Invalid adConfig when registering pop up ad")
    end

    local self = setmetatable({}, PopUpAdHelper)
    self.adUnit = adUnit
    self.adConfig = HttpService:JSONDecode(adConfig.Value)

    -- Filtering requirements for fake static ad
    local validAdFormat = self.adConfig.ad_format == "static" or self.adConfig.ad_format == nil
    if not validAdFormat then
        error("[Super Biz] Invalid adConfig ad_format when registering pop up ad")
    end
    self.adConfig.ad_height_over_width_ratio = self.adConfig.ad_height_over_width_ratio or 1

    local bloxbizAdId = self.adConfig.bloxbiz_ad_id
    local existingAdHelper = PopUpAdHelper._registeredAds[bloxbizAdId]
    if existingAdHelper and existingAdHelper.adUnit ~= adUnit then
        error("[Super Biz] Attempt to register two different pop up ads under same config")
    elseif existingAdHelper and existingAdHelper.adUnit == adUnit then
        return existingAdHelper
    elseif not existingAdHelper then
        PopUpAdHelper._registeredAds[bloxbizAdId] = self
        return self
    end
end

return PopUpAdHelper