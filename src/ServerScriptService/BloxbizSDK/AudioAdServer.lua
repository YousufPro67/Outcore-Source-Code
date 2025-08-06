local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdRequestStats = require(script.Parent.AdRequestStats)
local AdFilter = require(script.Parent.AdFilter)
local BatchHTTP = require(script.Parent.BatchHTTP)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge

local RemotesFolder = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local requestAudioAdEvent = RemotesFolder:WaitForChild("RequestAudioAdEvent")

local AudioAdServer = {}

local currentCachedAd = {}
local nextForcedAd = {}

local function queueSongRequestEvent(player)
	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)
	local lightingStats = AdRequestStats:getGameLightingStats()

	local data = merge(merge(merge(gameStats, playerStats), lightingStats), clientPlayerStats)

	local event = { event_type = "SongRequestEvent", data = data }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueAreAudioAdsAvailableEvent(player)
	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)
	local lightingStats = AdRequestStats:getGameLightingStats()

	local data = merge(merge(merge(gameStats, playerStats), lightingStats), clientPlayerStats)

	local event = { event_type = "AreAudioAdsAvailableEvent", data = data }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueImpression(impression)
	impression.ad_format = "audio"

	local event = { event_type = "video_event", data = impression }
	table.insert(BatchHTTP.eventQueue, event)
end

local function getAdsStats()
	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()
	local playerStats = AdRequestStats:getAllPlayerStatsWithClientStats()

	local stats = merge(gameStats, lightingStats)
	stats["audio_ad_request"] = true
	stats["players"] = playerStats

	return stats
end

function AudioAdServer:areAdsAvailableForPlayer(player)
	queueAreAudioAdsAvailableEvent(player)

	local availableAds = AdFilter:GetAllAvailableAudioAdsForPlayer(getAdsStats(), player) or {}
	local hasAds = not not availableAds[1]

	return hasAds
end

local function checkForForcedAd(player)
	local forcedAd = nextForcedAd[player]
	if not forcedAd then
		return
	end

	nextForcedAd[player] = nil

	local audioId = forcedAd["audio_url"]
	if not audioId or audioId == "" then
		return
	end

	return audioId, forcedAd
end

function AudioAdServer:getAds(player)
	queueSongRequestEvent(player)

	local audioId, forcedAd = checkForForcedAd(player)
	if audioId then
		currentCachedAd[player] = forcedAd

		return audioId
	end

	local userId = player.UserId

	local ads = AdFilter:GetAds(getAdsStats())
	local ad = ads[userId]
	if not ad then
		return
	end

	audioId = ad["audio_url"]
	if not audioId or audioId == "" then
		return
	end

	currentCachedAd[player] = ad

	return audioId
end

function AudioAdServer:triggerImpression(player, adListenTime, adTotalDurationTime, adMaxContinuousTime, adResumedCount)
	local ad = currentCachedAd[player]
	if not ad then
		return
	end

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)
	local lightingStats = AdRequestStats:getGameLightingStats()

	local playStats = {
		["play_end_percentage"] = adListenTime / adTotalDurationTime,
		["play_end_seconds"] = adListenTime,
		["audio_active_seconds"] = adListenTime,
		["num_resumes"] = adResumedCount,
		["max_continuous_play_time"] = adMaxContinuousTime,
		["bloxbiz_ad_id"] = ad.bloxbiz_ad_id,
		["timestamp"] = os.time(),
		["client_GUID"] = HttpService:GenerateGUID(),
	}

	queueImpression(merge(merge(merge(merge(gameStats, playerStats), lightingStats), playStats), clientPlayerStats))

	local FrequencyCapper = AdFilter.FrequencyCapper
	FrequencyCapper:RecordExposureForAudioAdPlayed(merge(playerStats, ad))

	currentCachedAd[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	currentCachedAd[player] = nil
	nextForcedAd[player] = nil
end)

requestAudioAdEvent.OnServerEvent:Connect(function(player, ad)
	nextForcedAd[player] = ad
end)

return AudioAdServer