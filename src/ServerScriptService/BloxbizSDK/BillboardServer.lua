local BillboardServer = {
	adPart = nil,
	eventConnection = nil,
	updateAdEvent = nil,
	CentralBillboardServer = nil,
	BillboardServerInstances = {},
	deleted = false,
	teleportedPlayers = {},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BatchHTTP = require(script.Parent.BatchHTTP)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge --table merge function
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local AdRequestStats = require(script.Parent.AdRequestStats)
local AnalyticsDataStoreQueue = require(script.Parent.AnalyticsDataStoreQueue)
local PlayerAnalyticsHistory = require(script.Parent.AnalyticsDataStoreQueue.PlayerAnalyticsHistory)

local ConfigReader = require(script.Parent.ConfigReader)

local InternalConfig = require(script.Parent.InternalConfig)

local PRINT_DEBUG_STATEMENTS = InternalConfig.PRINT_DEBUG_STATEMENTS
local PRINT_IMPRESSIONS = InternalConfig.PRINT_IMPRESSIONS
local REMOTES_FOLDER = "BloxbizRemotes"

local function queueImpressionDataStore(impression, adFormat)
	if adFormat == "video" then
		return
	end

	local AdFilter = require(script.Parent.AdFilter)
	local FrequencyCapper = AdFilter.FrequencyCapper

	local bloxbizAdId = impression.bloxbiz_ad_id
	local validExposureTime = FrequencyCapper:getValidExposureTime(impression)
	AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "exposure_time", validExposureTime)

	if validExposureTime >= 1 then
		AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "impressions", 1)

		local analyticsHistory = PlayerAnalyticsHistory:getPlayerHistory(impression.player_id)
		if not analyticsHistory["billboardReach"][tostring(bloxbizAdId)] then
			analyticsHistory["billboardReach"][tostring(bloxbizAdId)] = true
			AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "reach", 1)
		end
	end
end

local function queueImpressionHttp(impression)
	local event = { event_type = "exposure", data = impression }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueVideoPlay(play, billType)
	play.ad_format = "video"

	local event = { event_type = "video_event", data = play }
	table.insert(BatchHTTP.eventQueue, event)

	local AdFilter = require(script.Parent.AdFilter)
	local FrequencyCapper = AdFilter.FrequencyCapper

	if billType == "cpv" then
		FrequencyCapper:RecordExposureForXSecVideoPlays(play, 2)
	elseif billType == "video_plays_cpm" then
		FrequencyCapper:RecordExposureForXSecVideoPlays(play, 0)
	end
end

local function queueInteraction(interaction)
	local event = { event_type = "interaction", data = interaction }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueError(error_msg)
	local game_stats = AdRequestStats:getGameStats()
	local error_event = { timestamp = os.time(), game = game_stats, error_msg = error_msg }

	local event = { event_type = "error", game = game_stats, error = error_event }
	table.insert(BatchHTTP.eventQueue, event)
end

local function impressionFired(player, clientPlayerStats, adUrl, bloxbizAdId, partOrPartStats,
	timestamp, timeSeen, rays, clientGuid, isClientPart, adFormat)
	if not isClientPart and partOrPartStats.Parent == nil then
		return
	end

	if RateLimiter:checkRateLimiting(player) then
		return
	end

	if PRINT_DEBUG_STATEMENTS or PRINT_IMPRESSIONS then
		if partOrPartStats.Name then
			print(
				"[SuperBiz] "
					.. partOrPartStats.Name
					.. " Exposure for "
					.. string.format("%.2f", timeSeen)
					.. " seconds ("
					.. bloxbizAdId
					.. ")"
			)
		elseif partOrPartStats.part_name then
			print(
				"[SuperBiz] Local part ad "
					.. partOrPartStats.part_name
					.. " Exposure for "
					.. string.format("%.2f", timeSeen)
					.. " seconds ("
					.. bloxbizAdId
					.. ")"
			)
		end
	end

	local impression = BillboardServer:getImpressionStats(
		player,
		clientPlayerStats,
		adUrl,
		bloxbizAdId,
		partOrPartStats,
		timestamp,
		timeSeen,
		rays,
		clientGuid,
		isClientPart
	)

	local ad = Utils.getAdUsingBloxbizAdId(bloxbizAdId)
	if ad and ad.analytics_protocol == "datastore" then
		queueImpressionDataStore(impression, adFormat)
	else
		queueImpressionHttp(impression)
	end

	if adFormat ~= "video" then
		local AdFilter = require(script.Parent.AdFilter)
		local FrequencyCapper = AdFilter.FrequencyCapper
		FrequencyCapper:RecordExposureFor10SecImpressions(impression)
	end
end

local function videoPlayedFired(player, playStats, clientPlayerStats, bloxbizAdId, adPart, clientGUID, billType)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	if PRINT_DEBUG_STATEMENTS or PRINT_IMPRESSIONS then
		print(
			"[SuperBiz] "
				.. adPart.Name
				.. " video play ended at "
				.. string.format("%.2f", playStats.playEndSeconds)
				.. " seconds ("
				.. bloxbizAdId
				.. ")"
		)
	end

	local play = BillboardServer:getVideoPlayStats(player, playStats, clientPlayerStats, bloxbizAdId, adPart, clientGUID)
	return queueVideoPlay(play, billType)
end

local function sendPlayerAdsToPreload(player)
	local preloadAdsEvent = ReplicatedStorage[REMOTES_FOLDER].PreloadAdsEvent
	local adFilter = require(script.Parent.AdFilter)
	local adsList = adFilter:GetAllEnabledAds()
	local assetURLs = {}

	for _, ad in ipairs(adsList) do
		if ad.ad_format == "video" then
			table.insert(assetURLs, ad.audio_url)

			for _, frame in ipairs(ad.ad_url) do
				table.insert(assetURLs, frame.ad_url)
			end
		end
	end

	preloadAdsEvent:FireClient(player, assetURLs)
end

local function newPlayerFired(player)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	pcall(function()
		sendPlayerAdsToPreload(player)
	end)

	local newBillboardServerInstances = {}
	for i, billboardServer in pairs(BillboardServer.BillboardServerInstances) do
		if not billboardServer.deleted then
			table.insert(newBillboardServerInstances, billboardServer)

			local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)
			local singlePlayerList = Utils.deepCopy({ playerStats })
			billboardServer:getAndSendAd(singlePlayerList)
		end
	end

	BillboardServer.BillboardServerInstances = newBillboardServerInstances
end

local function adInteractionFired(player, interactionType, clientPlayerStats, adUrl, bloxbizAdId, part, startTime, ...)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	local interactionStats = {
		["interaction_type"] = interactionType,
		["ad_url"] = adUrl,
		["bloxbiz_ad_id"] = bloxbizAdId,
		["timestamp"] = startTime,
	}

	if interactionType == "hover" then
		local hoverTime = (...)
		interactionStats["hover_time"] = hoverTime
	elseif interactionType == "click" then
		interactionStats["hover_time"] = -1
	end

	local partStats = AdRequestStats:getPartStats(part)
	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	local interaction = merge(
		merge(merge(merge(merge(interactionStats, partStats), gameStats), playerStats), lightingStats),
		clientPlayerStats
	)
	queueInteraction(interaction)
end

--[[
local function adChatOpportunityFired(player, chatOpportunityData, clientPlayerStats, partStats)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	local partStats = partStats
	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	local data = merge(merge(merge(merge(chatOpportunityData, partStats), gameStats), playerStats), clientPlayerStats)

	Utils.pprint("[SuperBiz] Queue chat opportunity.")
	local event = {event_type="chat_opportunity", data=data}
	table.insert(BatchHTTP.eventQueue, event)
end
]]

function BillboardServer:connectToEvents()
	local bloxbizFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	bloxbizFolder.ImpressionEvent.OnServerEvent:Connect(impressionFired)
	bloxbizFolder.VideoPlayedEvent.OnServerEvent:Connect(videoPlayedFired)
	bloxbizFolder.NewPlayerEvent.OnServerEvent:Connect(newPlayerFired)
	bloxbizFolder.AdInteractionEvent.OnServerEvent:Connect(adInteractionFired)
	--bloxbizFolder.AdChatOpportunityEvent.OnServerEvent:Connect(adChatOpportunityFired)
end

function BillboardServer:checkBillboard()
	local size  = self.adPart.Size
	if size.X/size.Y ~= 2 then
		warn("[Superbiz] Ad part " .. self.adPart:GetFullName() .. " did not have a 2:1 size ratio")
	end

	if not self.adPart:FindFirstChild("AdSurfaceGui") then
		error("[SuperBiz] Ad part must have a SurfaceGui attached to it with the name 'AdSurfaceGui'")
	end
end

function BillboardServer:getAdSizeRatio()
	local height = self.adPart.AdSurfaceGui.AbsoluteSize.Y
	local width = self.adPart.AdSurfaceGui.AbsoluteSize.X

	return height / width
end

function BillboardServer:getDefaultAd()
	local adFallbackUrls

	local adRatio = self:getAdSizeRatio()

	if adRatio == 0.5 then
		adFallbackUrls = ConfigReader:read("AdFallbackURL")
	else
		adFallbackUrls = ConfigReader:read("AdFallbackURLVertical")
	end

	if #adFallbackUrls == 0 then
		return { "blank" }
	end

	local randomIndex = math.random(1, #adFallbackUrls)
	return { adFallbackUrls[randomIndex] }
end

function BillboardServer:setupBillboardGUI()
	local imageLabel = self.adPart.AdSurfaceGui:FindFirstChild("ImageLabel")

	if imageLabel == nil then
		imageLabel = Instance.new("ImageLabel")
	end

	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.Image = self:getDefaultAd()[1]
	imageLabel.Parent = self.adPart.AdSurfaceGui

	local disclaimerHolder = Instance.new("Frame", self.adPart.AdSurfaceGui)
	disclaimerHolder.Name = "DisclaimerHolder"
	disclaimerHolder.AnchorPoint = Vector2.new(1, 1)
	disclaimerHolder.Size = UDim2.new(2, 0, 1, 0)
	disclaimerHolder.SizeConstraint = Enum.SizeConstraint.RelativeYY
	disclaimerHolder.BackgroundTransparency = 1
	disclaimerHolder.Position = UDim2.new(1, 0, 1, 0)
	disclaimerHolder.BorderSizePixel = 0
	disclaimerHolder.ZIndex = 2147483647
	disclaimerHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	local adDisclaimerLabel = Instance.new("ImageLabel", disclaimerHolder)

	adDisclaimerLabel.Name = "AdDisclaimerLabel"
	adDisclaimerLabel.Image = "rbxassetid://7122215099"
	adDisclaimerLabel.ImageTransparency = 0.2
	adDisclaimerLabel.BackgroundTransparency = 1
	adDisclaimerLabel.BorderSizePixel = 0
	adDisclaimerLabel.Size = UDim2.new(0.117, 0, 0.08, 0)
	adDisclaimerLabel.AnchorPoint = Vector2.new(1, 1)
	adDisclaimerLabel.Position = UDim2.new(1, 0, 1, 0)
	adDisclaimerLabel.ZIndex = 2147483647
	adDisclaimerLabel.Visible = false
end

function BillboardServer:getImpressionStats(
	player,
	clientPlayerStats,
	adUrl,
	bloxbizAdId,
	partOrPartStats,
	timestamp,
	timeSeen,
	rays,
	clientGuid,
	isClientPart
)
	local impressionStats = {
		["ad_url"] = adUrl,
		["bloxbiz_ad_id"] = bloxbizAdId,
		["timestamp"] = os.time(),
		["time_seen"] = timeSeen,
		["rays"] = rays,
		["client_GUID"] = clientGuid,
	}

	local partStats
	if not isClientPart then
		partStats = AdRequestStats:getPartStats(partOrPartStats)
	else
		partStats = partOrPartStats
	end

	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	return merge(
		merge(merge(merge(merge(impressionStats, partStats), gameStats), playerStats), lightingStats),
		clientPlayerStats
	)
end

function BillboardServer:getVideoPlayStats(player, playStats, clientPlayerStats, bloxbizAdId, adPart, clientGUID)
	playStats = {
		["play_end_percentage"] = playStats.playEndPercentage,
		["play_end_seconds"] = playStats.playEndSeconds,
		["num_resumes"] = playStats.numResumes,
		["audio_active_seconds"] = playStats.audioActiveSeconds,
		["max_continuous_play_time"] = playStats.maxContinuousPlaytime,
		["bloxbiz_ad_id"] = bloxbizAdId,
		["timestamp"] = os.time(),
		["client_GUID"] = clientGUID,
	}

	local partStats = AdRequestStats:getPartStats(adPart)
	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	return merge(
		merge(merge(merge(merge(playStats, partStats), gameStats), playerStats), lightingStats),
		clientPlayerStats
	)
end

function BillboardServer:isGifsEnabled()
	if self.gifsEnabledPartSetting ~= nil then
		return self.gifsEnabledPartSetting
	end

	return ConfigReader:read("GIFAdsDefault")
end

function BillboardServer:isVideoEnabled()
	if self.videoEnabledPartSetting ~= nil then
		return self.videoEnabledPartSetting
	end

	return ConfigReader:read("VideoAdsDefault")
end

function BillboardServer:getAdsStats(playerStats)
	local partStats = AdRequestStats:getPartStats(self.adPart)
	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()

	local stats = merge(merge(gameStats, partStats), lightingStats)
	stats["blocklist"] = ConfigReader:read("AdBlocklistURL")
	stats["gifs_enabled"] = BillboardServer:isGifsEnabled()
	stats["video_enabled"] = BillboardServer:isVideoEnabled()
	stats["players"] = playerStats

	return stats
end

function BillboardServer:getAds(stats)
	local AdFilter = require(script.Parent.AdFilter)
	local adUrlPerPlayer = AdFilter:GetAds(stats)

	return adUrlPerPlayer
end

local function formatAdBeforeSending(ad)
	if ad["ad_url"][1] == "" then
		ad["ad_url"] = BillboardServer:getDefaultAd()
		ad["ad_format"] = "static"
		ad["gif_version"] = nil
		ad["show_ad_disclaimer"] = false
	else
		ad["show_ad_disclaimer"] = true
	end

	if not ad["ad_disclaimer_url"] then
		ad["ad_disclaimer_url"] = "rbxassetid://7122215099"
		ad["ad_disclaimer_scale_x"] = 0.117
		ad["ad_disclaimer_scale_y"] = 0.08
	end
end

function BillboardServer:sendAd(playerId, ad)
	local player = Players:GetPlayerByUserId(playerId)

	if player then
		formatAdBeforeSending(ad)
		self.updateAdEvent:FireClient(player, ad)
	end
end

function BillboardServer:getAndSendAd(playerStats)
	return pcall(function()
		if not playerStats then
			playerStats = AdRequestStats:getAllPlayerStatsWithClientStats()
		end

		local stats = self:getAdsStats(playerStats)
		local adUrlPerPlayer = self:getAds(stats)

		for playerId, ad in pairs(adUrlPerPlayer) do
			self:sendAd(playerId, ad)
		end
	end)
end

function BillboardServer:updateAdFired(player, clientPlayerStats)
	local playerId = player.UserId
	local playerStats = merge(clientPlayerStats, AdRequestStats:getPlayerStats(player))

	local stats = self:getAdsStats({ playerStats })
	local adList = self:getAds(stats)
	local ad = adList[playerId]

	self:sendAd(playerId, ad)
end

function BillboardServer:initInstance(ad, dynamically)
	local part = nil
	local gifsEnabled = nil
	local videoEnabled = nil

	if type(ad) == "table" then
		part = ad["partInstance"]
		gifsEnabled = ad["GIFAdsEnabled"]
		videoEnabled = ad["VideoAdsEnabled"]
	else
		part = ad
	end

	local BillboardServerInstance = script:Clone()
	BillboardServerInstance.Name = "BillboardServerInstance"
	BillboardServerInstance.Parent = script.Parent

	local billboardServer = require(BillboardServerInstance)
	billboardServer.CentralBillboardServer = require(script)
	table.insert(billboardServer.CentralBillboardServer.BillboardServerInstances, billboardServer)
	billboardServer:initAd(part, dynamically, gifsEnabled, videoEnabled)

	return billboardServer
end

function BillboardServer:initAd(part, dynamically, gifsEnabled, videoEnabled)
	self.gifsEnabledPartSetting = gifsEnabled
	self.videoEnabledPartSetting = videoEnabled

	if dynamically then
		local newAdEvent = game.ReplicatedStorage:WaitForChild(REMOTES_FOLDER):WaitForChild("NewAdEvent")
		newAdEvent:FireAllClients(part:GetFullName())

		self.eventConnection = game.Players.PlayerAdded:Connect(function(player)
			if part ~= nil then
				newAdEvent:FireClient(player, part:GetFullName())
			end
		end)
	end

	self.updateAdEvent = Instance.new("RemoteEvent", ReplicatedStorage:WaitForChild(REMOTES_FOLDER))
	self.updateAdEvent.Name = "updateAdEvent-" .. part:GetFullName()
	self.updateAdEvent.OnServerEvent:Connect(function(player, ...)
		self:updateAdFired(player, ...)
	end)

	Utils.pprint("[SuperBiz] Ad server started!")
	self.adPart = part

	self:checkBillboard()

	self:setupBillboardGUI()
end

return BillboardServer
