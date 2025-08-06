local Filters = {}
local FilterUtils = require(script.Parent.FilterUtils)

local MIN_PORTAL_SIZE = Vector3.new(24, 12.5, 7)

function Filters:FilterAdsByExternalLinks(ads, allowedExternalLinkReferences)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		local showAd = true
		local adLinks = ad["external_link_references"] or {}

		for _, link in ipairs(adLinks) do
			local isInTable = self.FilterUtils.PythonInOperator(link, allowedExternalLinkReferences)

			if not isInTable then
				showAd = false
				break
			end
		end

		if showAd then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:FilterAdsByPlayerId(ads, playerId)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		if self:AdTargetsDemographic(ad, "player_id", playerId) then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:FilterAdsByPlayerTargeting(ads, playerCountry, locale, playerMembershipType,
	playerDevice, playerGender, areAdsAllowed)

	local demographicsToFilter = {
		["country_code"] = playerCountry,
		["player_locale_id"] = locale,
		["player_membership_type"] = playerMembershipType,
		["player_device"] = playerDevice,
		["player_gender"] = playerGender,
		["are_ads_allowed"] = areAdsAllowed,
	}

	return Filters:FilterAdsByTargeting(ads, demographicsToFilter)
end

function Filters:FilterAdsByGameTargeting(ads, bloxbizVersion, partName)
	local demographicsToFilter = {
		["sdk_version"] = bloxbizVersion,
		["ad_unit"] = partName,
	}

	return Filters:FilterAdsByTargeting(ads, demographicsToFilter)
end

function Filters:FilterAdsByTargeting(ads, demographicsToFilter)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		local adMatchesDemographics = true

		for demographicName, demographicValue in pairs(demographicsToFilter) do
			if not Filters:AdTargetsDemographic(ad, demographicName, demographicValue) then
				adMatchesDemographics = false
				break
			end
		end

		if adMatchesDemographics then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:AdTargetsDemographic(ad, demographicName, demographicValue)
	local allowlist = ad[tostring(demographicName .. "_allowlist")] or {}
	local blocklist = ad[tostring(demographicName .. "_blocklist")] or {}

	if
		(#allowlist == 0 or FilterUtils.Within(demographicValue, allowlist))
		and not FilterUtils.Within(demographicValue, blocklist)
	then
		return true
	else
		return false
	end
end

function Filters:FilterAdsByFreqCap(ads, playerId)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		local adId = ad["bloxbiz_ad_id"]
		local dailyFrequencyCap = ad["daily_frequency_cap_delivery"] or 0

		if ad["daily_frequency_cap_delivery"] == 0 then
			dailyFrequencyCap = 999_999_999
		end

		if dailyFrequencyCap then
			local playerImpressions = self.FrequencyCapper:GetAdExposureCount(playerId, adId)

			if playerImpressions < dailyFrequencyCap then
				table.insert(filteredAds, ad)
			end
		else
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:FilterAdsByBlocklist(ads, blocklist)
	local filteredAds = {}

	for _, item in ipairs(ads) do
		local inTable = self.FilterUtils.PythonInOperator(item["ad_url"], blocklist)

		if not inTable then
			table.insert(filteredAds, item)
		end
	end

	return filteredAds
end

function Filters:FilterAdsByAdFormat(ads, adFormats)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		local adFormat = ad["ad_format"]

		if not adFormat then
			if ad["gif_ad"] then
				adFormat = "gif"
			else
				adFormat = "static"
			end
		end

		if self.FilterUtils.PythonInOperator(adFormat, adFormats) then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:FilterAdsBySize2D(ads, unitHeightOverWidthRatio)
	local filteredAds = {}

	for _, item in ipairs(ads) do
		local adHeightOverWidthRatio = item["ad_height_over_width_ratio"]

		if adHeightOverWidthRatio == unitHeightOverWidthRatio then
			table.insert(filteredAds, item)
		end
	end

	return filteredAds
end

function Filters:FilterAdsBySize3D(ads, partSizeX, partSizeY, partSizeZ)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		local adBoxWidthMin = ad["ad_box_width_min"]
		local adBoxHeightMin = ad["ad_box_height_min"]
		local adBoxDepthMin = ad["ad_box_depth_min"]

		if partSizeX >= adBoxWidthMin and partSizeY >= adBoxHeightMin and partSizeZ >= adBoxDepthMin then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

function Filters:FilterAdsBySizePortal(ads, partSizeX, partSizeY, partSizeZ)
	local filteredAds = {}

	for _, ad in ipairs(ads) do
		if partSizeX >= MIN_PORTAL_SIZE.X and partSizeY >= MIN_PORTAL_SIZE.Y and partSizeZ >= MIN_PORTAL_SIZE.Z then
			table.insert(filteredAds, ad)
		end
	end

	return filteredAds
end

return Filters
