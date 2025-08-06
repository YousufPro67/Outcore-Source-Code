local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigReader = require(script.Parent.ConfigReader)
local Utils = require(script.Parent.Utils)
local FilterParams = require(script.FilterParams)
local FilterUtils = require(script.FilterUtils)
local Filters = require(script.Filters)
local FrequencyCapper = require(script.FrequencyCapper)
local InferredPlayerData = require(script.InferredPlayerData)

local GET_ADS_PLAYER_PARAMETERS = FilterParams.GET_ADS_PLAYER_PARAMETERS
local GET_ADS_PARAMETERS = FilterParams.GET_ADS_PARAMETERS
local REMOTES_FOLDER = "BloxbizRemotes"

local AdFilter = {}
AdFilter.FilterUtils = FilterUtils
AdFilter.FrequencyCapper = FrequencyCapper
AdFilter.InferredPlayerData = InferredPlayerData

setmetatable(Filters, { __index = AdFilter })

local function safeDiv(x, y)
	if y == 0 then
		return 0
	end

	return x / y
end

function AdFilter:connectToEvents()
	local bloxbizFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	bloxbizFolder.getAdStorage.OnServerInvoke = function()
		return self:GetAllEnabledAds()
	end
end

function AdFilter:disableAdsForUnder13Users(adsList)
	for _, ad in pairs(adsList) do
		ad["are_ads_allowed_allowlist"] = {true}
	end

	return adsList
end

function AdFilter:GetAllEnabledAds()
	local adStorage = ReplicatedStorage.BloxbizConfig:FindFirstChild("BloxbizAdStorage")
	local adsList

	if not adStorage then
		adsList = {}
		Utils.pprint("[SuperBiz] BloxbizAdStorage was not found under the config!")
	else
		adStorage = require(adStorage)

		if adStorage.getAdsList then
			adsList = adStorage.getAdsList()
		else
			adsList = adStorage
		end
	end

	--The backend will send the allowlist instead
	--self:disableAdsForUnder13Users(adsList)

	return adsList
end

function AdFilter:BuildAudioAdItem(ad, adDisclaimer)
	local adToShowPlayer = {
		["ad_format"] = ad["ad_format"],
		["ad_url"] = ad["ad_url"],
		["bloxbiz_ad_id"] = ad["bloxbiz_ad_id"],
		["external_link_references"] = ad["external_link_references"] or {},
		["audio_url"] = ad["audio_url"],
		["ad_disclaimer_url"] = adDisclaimer["url"],
	}

	local adUrl = adToShowPlayer["ad_url"]

	if type(adUrl) == "string" then
		adToShowPlayer["ad_url"] = { adUrl }
	end

	return adToShowPlayer
end

function AdFilter:Build2DAdItem(ad, adDisclaimer)
	local adToShowPlayer = {
		["ad_format"] = ad["ad_format"],
		["ad_url"] = ad["ad_url"],
		["bloxbiz_ad_id"] = ad["bloxbiz_ad_id"],
		["external_link_references"] = ad["external_link_references"] or {},
		["gif_fps"] = math.floor(tonumber(ad["gif_fps"] or 15)),
		["gif_version"] = ad["gif_version"] or 2,
		["audio_url"] = ad["audio_url"],
		["ad_disclaimer_url"] = adDisclaimer["url"],
		["ad_disclaimer_scale_x"] = adDisclaimer["scale_x"],
		["ad_disclaimer_scale_y"] = adDisclaimer["scale_y"],
	}

	local adUrl = adToShowPlayer["ad_url"]

	if type(adUrl) == "string" then
		adToShowPlayer["ad_url"] = { adUrl }
	end

	return adToShowPlayer
end

function AdFilter:Build3DAdItem(ad, adDisclaimer)
	local adToShowPlayer = {
		["ad_format"] = ad["ad_format"],
		["bloxbiz_ad_id"] = ad["bloxbiz_ad_id"],
		["ad_type"] = ad["ad_type"] or "Character",
		["ad_serialized_model"] = ad["ad_serialized_model"],
		["ad_model_data"] = ad["ad_model_data"],
		["ad_box_width_max"] = ad["ad_box_width_max"],
		["ad_box_depth_max"] = ad["ad_box_depth_max"],
		["ad_box_height_max"] = ad["ad_box_height_max"],
		["external_link_references"] = ad["external_link_references"] or {},
		["ad_disclaimer_text"] = adDisclaimer["text"],
	}

	return adToShowPlayer
end

function AdFilter:BuildPortalAdItem(ad, adDisclaimer)
	local adToShowPlayer = {
		["ad_format"] = ad["ad_format"],
		["bloxbiz_ad_id"] = ad["bloxbiz_ad_id"],
		["destination_place_id"] = ad["destination_place_id"],
		["ad_url"] = ad["ad_url"],
		["external_link_references"] = ad["external_link_references"] or {},
		["ad_disclaimer_url"] = adDisclaimer["url"],
		["ad_disclaimer_scale_x"] = adDisclaimer["scale_x"],
		["ad_disclaimer_scale_y"] = adDisclaimer["scale_y"],
	}

	local adUrl = adToShowPlayer["ad_url"]

	if type(adUrl) == "string" then
		adToShowPlayer["ad_url"] = { adUrl }
	end

	return adToShowPlayer
end

function AdFilter:BlankAd()
	return { ["ad_url"] = "", ["bloxbiz_ad_id"] = -1 }
end

function AdFilter:getPortalsDeliveryRatio(initialSumDeliveryRatio)
	local configRatio = ConfigReader:read("AdsPortalMaxDisplayPercentage")
	configRatio = tonumber(configRatio)
	configRatio = math.clamp(configRatio, 1, 100)
	configRatio /= 100

	return math.min(initialSumDeliveryRatio, configRatio)
end

function AdFilter:getFinalAdDeliveryRatio(ad)
	local AdBalancer = require(script.AdBalancer)

	local deliveryRatio = AdBalancer:GetAdRatio(ad["bloxbiz_ad_id"])
	local testerRatio = ad.test_delivery_ratio

	deliveryRatio = tonumber(testerRatio or deliveryRatio or 0)

	return deliveryRatio
end

function AdFilter:SelectAdToDisplay(ads)
	local adList = {}
	local adWeightsList = {}

	local sumDeliveryRatios = 0

	for _, ad in ipairs(ads) do
		local deliveryRatio = self:getFinalAdDeliveryRatio(ad)
		sumDeliveryRatios += deliveryRatio

		table.insert(adList, ad)
		table.insert(adWeightsList, deliveryRatio)
	end

	local isPortalRequest = ads[1] and ads[1]['ad_format'] == 'portal'
	if isPortalRequest then
		local portalsDeliveryRatio = self:getPortalsDeliveryRatio(sumDeliveryRatios)

		--Make ad weights proportional to new ratio
		for i = 1, #adWeightsList do
			adWeightsList[i] *= safeDiv(portalsDeliveryRatio, sumDeliveryRatios)
		end

		sumDeliveryRatios = portalsDeliveryRatio
	end

	local noAdProportion = 1 - sumDeliveryRatios
	if noAdProportion > 0 then
		table.insert(adList, self:BlankAd())
		table.insert(adWeightsList, noAdProportion)
	end

	return FilterUtils.PythonChoices(adList, adWeightsList)[1]
end

function AdFilter:GetAdDisclaimer(language)
	local languageToAdDisclaimer = {
		["de-de"] = {
			["url"] = "rbxassetid://7787165346",
			["scale_x"] = 0.133,
			["scale_y"] = 0.08,
			["text"] = "Werbung",
		},
		["fr-fr"] = {
			["url"] = "rbxassetid://7787165346",
			["scale_x"] = 0.133,
			["scale_y"] = 0.08,
			["text"] = "Publicité",
		},
	}

	return languageToAdDisclaimer[language] or {}
end

function AdFilter:GetAllAvailableAudioAdsForPlayer(getAdData, forPlayer)
	if not getAdData.audio_ad_request then
		return
	end

	local bloxbizVersion = tonumber(getAdData["bloxbiz_version"] or 0)
	local blocklist = getAdData["blocklist"] or {}

	local adFormatsRequested = {}
	table.insert(adFormatsRequested, "audio")

	local playerInfo
	for _, player in getAdData["players"] do
		if player.player_id == forPlayer.UserId then
			playerInfo = player
			break
		end
	end

	if not playerInfo then
		return
	end

	local initialAdList = AdFilter:GetAllEnabledAds()

	local adsFilteredForGame = Filters:FilterAdsByAdFormat(initialAdList, adFormatsRequested)
	adsFilteredForGame = Filters:FilterAdsByGameTargeting(adsFilteredForGame, bloxbizVersion)
	adsFilteredForGame = Filters:FilterAdsByBlocklist(adsFilteredForGame, blocklist)

	local playerId = playerInfo["player_id"]
	local playerLocaleId = playerInfo["player_locale_id"]
	local playerCountry = playerInfo["country_code"]
	local playerMembershipType = playerInfo["player_membership_type"]
	local playerAllowedExternalLinkReferences = playerInfo["allowed_external_link_references"] or {}
	local playerDevice = FilterUtils.GetDeviceType(playerInfo)
	local playerGender = InferredPlayerData:Get(playerId).gender
	local areAdsAllowed = playerInfo["are_ads_allowed"]
	local adDisclaimer = AdFilter:GetAdDisclaimer(playerLocaleId)

	local adsFilteredForUser = Filters:FilterAdsByPlayerTargeting(
		adsFilteredForGame,
		playerCountry,
		playerLocaleId,
		playerMembershipType,
		playerDevice,
		playerGender,
		areAdsAllowed
	)
	adsFilteredForUser = Filters:FilterAdsByExternalLinks(adsFilteredForUser, playerAllowedExternalLinkReferences)
	adsFilteredForUser = Filters:FilterAdsByFreqCap(adsFilteredForUser, playerId)
	adsFilteredForUser = Filters:FilterAdsByPlayerId(adsFilteredForUser, playerId)

	local availableAds = {}

	for _, filteredAd in adsFilteredForUser do
		local ad = self:BuildAudioAdItem(filteredAd, adDisclaimer)
		table.insert(availableAds, ad)
	end

	return availableAds
end

function AdFilter:GetAds(getAdData, alternateAdList)
	local startTime = tick()

	local expectedParameters = GET_ADS_PARAMETERS

	local bloxbizVersion = tonumber(getAdData["bloxbiz_version"] or 0)
	local gameId = getAdData["game_id"]

	local blocklist = getAdData["blocklist"] or {}
	local gifsEnabled = getAdData["gifs_enabled"] or false
	local videoEnabled = getAdData["video_enabled"] or false
	local ad3DRequest = getAdData["3d_ad_request"] or false
	local portalRequest = getAdData["portal_ad_request"] or false
	local audioAd = getAdData["audio_ad_request"] or false

	-- TODO: these can be swapped if the part_orientation is non standard
	local adWidth = getAdData["surface_gui_size_x"] or 0
	local adHeight = getAdData["surface_gui_size_y"] or 0

	local partName = getAdData["part_name"]
	local partSizeX = getAdData["part_size_x"]
	local partSizeY = getAdData["part_size_y"]
	local partSizeZ = getAdData["part_size_z"]

	local unitHeightOverWidthRatio = FilterUtils.SafeDiv(adHeight, adWidth)
	unitHeightOverWidthRatio = FilterUtils.Round(unitHeightOverWidthRatio, 4)
	unitHeightOverWidthRatio = tonumber(tostring(unitHeightOverWidthRatio))

	local adFormatsRequested = {}

	if portalRequest then
		table.insert(adFormatsRequested, "portal")
	elseif ad3DRequest then
		table.insert(adFormatsRequested, "3d")
	else
		table.insert(adFormatsRequested, "static")

		if gifsEnabled then
			table.insert(adFormatsRequested, "gif")
		end

		if videoEnabled then
			table.insert(adFormatsRequested, "video")
		end

		if audioAd then
			table.insert(adFormatsRequested, "audio")
		end
	end

	if not audioAd then
		FilterUtils.ValidateParams(expectedParameters, getAdData)
	end

	local players = getAdData["players"]
	local baseItem = getAdData
	baseItem["players"] = nil

	local initialAdList = alternateAdList or AdFilter:GetAllEnabledAds()

	local adsFilteredForGame = Filters:FilterAdsByAdFormat(initialAdList, adFormatsRequested)
	adsFilteredForGame = Filters:FilterAdsByGameTargeting(adsFilteredForGame, bloxbizVersion, partName)

	if not audioAd then
		if portalRequest then
			adsFilteredForGame = Filters:FilterAdsBySizePortal(adsFilteredForGame, partSizeX, partSizeY, partSizeZ)
		elseif ad3DRequest then
			adsFilteredForGame = Filters:FilterAdsBySize3D(adsFilteredForGame, partSizeX, partSizeY, partSizeZ)
		else
			adsFilteredForGame = Filters:FilterAdsBySize2D(adsFilteredForGame, unitHeightOverWidthRatio)
		end
	end

	adsFilteredForGame = Filters:FilterAdsByBlocklist(adsFilteredForGame, blocklist)

	local adUrlPerPlayer = {}

	local playerIds = {}

	for _, player in ipairs(players) do
		table.insert(playerIds, player["player_id"])
	end

	local playerGenders = {}

	for _, playerId in ipairs(playerIds) do
		playerGenders[playerId] = InferredPlayerData:Get(playerId).gender
	end

	local adDeliveries = {}

	for _, player in ipairs(players) do
		local playerId = player["player_id"]
		local playerLocaleId = player["player_locale_id"]
		local playerCountry = player["country_code"]
		local playerMembershipType = player["player_membership_type"]
		local playerAllowedExternalLinkReferences = player["allowed_external_link_references"] or {}
		local playerDevice = FilterUtils.GetDeviceType(player)
		local playerGender = playerGenders[playerId]
		local areAdsAllowed = player["are_ads_allowed"]
		local adDisclaimer = AdFilter:GetAdDisclaimer(playerLocaleId)

		local adsFilteredForUser = Filters:FilterAdsByPlayerTargeting(
			adsFilteredForGame,
			playerCountry,
			playerLocaleId,
			playerMembershipType,
			playerDevice,
			playerGender,
			areAdsAllowed
		)
		adsFilteredForUser = Filters:FilterAdsByExternalLinks(adsFilteredForUser, playerAllowedExternalLinkReferences)
		adsFilteredForUser = Filters:FilterAdsByFreqCap(adsFilteredForUser, playerId)
		adsFilteredForUser = Filters:FilterAdsByPlayerId(adsFilteredForUser, playerId)

		local ad = AdFilter:SelectAdToDisplay(adsFilteredForUser)

		local adToShowPlayer

		if portalRequest then
			adToShowPlayer = self:BuildPortalAdItem(ad, adDisclaimer)
		elseif ad3DRequest then
			adToShowPlayer = self:Build3DAdItem(ad, adDisclaimer)
		elseif audioAd then
			adToShowPlayer = self:BuildAudioAdItem(ad, adDisclaimer)
		else
			adToShowPlayer = self:Build2DAdItem(ad, adDisclaimer)
		end

		adUrlPerPlayer[playerId] = adToShowPlayer

		FilterUtils.ValidateParams(GET_ADS_PLAYER_PARAMETERS, player)

		local playerItem = player
		--local guid = FilterUtils.GetHexGUID()

		playerItem["player_device"] = playerDevice
		playerItem["gender"] = playerGender
		--playerItem['GUID'] = guid
		playerItem["ad_url"] = adToShowPlayer["ad_url"]
		playerItem["bloxbiz_ad_id"] = adToShowPlayer["bloxbiz_ad_id"]
		playerItem["timestamp"] = tonumber(os.time())

		FilterUtils.PythonUpdate(playerItem, baseItem)

		playerItem = FilterUtils.CapIntegerValues(playerItem)

		table.insert(adDeliveries, playerItem)
	end

	--]] TO-DO: Replace the following with BatchHttp event

	--[[
    local success = batch_put_items_firehose(ad_delivery_stream, ad_deliveries)

    if not success then
        batch_put_items_s3(ad_delivery_bucket, ad_deliveries)
    end]]

	local endTime = tick()
	local timeTaken = FilterUtils.Round(endTime - startTime, 2)

	Utils.pprint(
		"[SuperBiz] Ads delivered to "
			.. FilterUtils.CountDictionary(adUrlPerPlayer)
			.. " players in game ("
			.. gameId
			.. ") (Took "
			.. timeTaken
			.. "s)"
	)

	return adUrlPerPlayer
end

return AdFilter
