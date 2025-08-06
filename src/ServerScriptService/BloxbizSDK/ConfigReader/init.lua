local ConfigReader = {}
ConfigReader.BloxbizConfigDefaults = {}

local BloxbizConfigDefaults = ConfigReader.BloxbizConfigDefaults

BloxbizConfigDefaults.Ads = {}
BloxbizConfigDefaults.Ads3D = {}
BloxbizConfigDefaults.AdsPortals = {}
BloxbizConfigDefaults.AdFallbackURL = {}
BloxbizConfigDefaults.AdFallbackURLVertical = {}
BloxbizConfigDefaults.AdBlocklistURL = {}
BloxbizConfigDefaults.AdStorageEditMode = false

BloxbizConfigDefaults.GIFAdsDefault = false
BloxbizConfigDefaults.VideoAdsDefault = false
BloxbizConfigDefaults.VideoZoomEnabled = false

BloxbizConfigDefaults.RateLimitThreshold = 400

BloxbizConfigDefaults.AdsPortalMaxDisplayPercentage = 100

BloxbizConfigDefaults.Ad3DMaxRaycastDistance = 2000
BloxbizConfigDefaults.RaycastFilterType = Enum.RaycastFilterType.Blacklist
BloxbizConfigDefaults.RaycastFilterList = function()
	return {}
end

BloxbizConfigDefaults.DebugModeCustomEvents = true
BloxbizConfigDefaults.DebugMode = false
BloxbizConfigDefaults.DebugModeVideoAd = false
BloxbizConfigDefaults.DebugModeInteractions = false
BloxbizConfigDefaults.DebugModeCharacterAd = false
BloxbizConfigDefaults.DebugModePortalAd = false
BloxbizConfigDefaults.DebugAPI = function ()
	return game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("DebugGui"):WaitForChild("DebugAPI")
end

BloxbizConfigDefaults.SalesMeasurement = true
BloxbizConfigDefaults.VariablePricing = false

BloxbizConfigDefaults.CatalogEnabled = false
BloxbizConfigDefaults.CatalogOutfitFeedEnabled = true
BloxbizConfigDefaults.CatalogShowToolbarButton = true
BloxbizConfigDefaults.CatalogToolbarButtonLabel = "Avatar"
BloxbizConfigDefaults.CatalogToolbarIcon = 14693703386
BloxbizConfigDefaults.CatalogPersistentWear = false
BloxbizConfigDefaults.CatalogClothingLimits = true
BloxbizConfigDefaults.CatalogCopyOutfitsFromPlayersEnabled = false
BloxbizConfigDefaults.CatalogPurchaseBlockList = {}
BloxbizConfigDefaults.CatalogPurchaseAllowList = {}
BloxbizConfigDefaults.CatalogPrimaryButton = false
BloxbizConfigDefaults.CatalogToolbarButtonLocation = "right"

BloxbizConfigDefaults.PopfeedEnabled = false
BloxbizConfigDefaults.PopfeedShowToolbarButton = true
BloxbizConfigDefaults.PopfeedProfilePlayerBannersEnabled = false

BloxbizConfigDefaults.StyngrEnabled = false

BloxbizConfigDefaults.SBCommandsEnabled = false
BloxbizConfigDefaults.SBCommandsShowToolbarButton = true
BloxbizConfigDefaults.SBCommandsToolbarIcon = 81934689825286
BloxbizConfigDefaults.SBCommandsToolbarButtonLabel = "SB Commands"

BloxbizConfigDefaults.MusicPlayerEnabled = false
BloxbizConfigDefaults.MusicPlayerCompactDesign = false
BloxbizConfigDefaults.MusicPlayerToolbarButtonLabel = "Music Player"
BloxbizConfigDefaults.MusicPlayerPlaylist = {}

BloxbizConfigDefaults.DisplayPlayerList = true
BloxbizConfigDefaults.IsGameVoiceChatEnabled = false

BloxbizConfigDefaults.UseDataStoresNotHttp = false

BloxbizConfigDefaults.PromoCodesEnabled = false
BloxbizConfigDefaults.AutoValidatePromoCodesClaims = false

BloxbizConfigDefaults.RewardsAutoPromptUGC = false

BloxbizConfigDefaults.UnlockablesAutoVerifyUsers = false

local BloxbizConfig = require(game.ReplicatedStorage.BloxbizConfig)

function ConfigReader:read(config_name)
	if BloxbizConfig[config_name] ~= nil then
		return BloxbizConfig[config_name]
	elseif BloxbizConfigDefaults[config_name] ~= nil then
		return BloxbizConfigDefaults[config_name]
	else
		error(config_name .. " must be defined in BloxbizConfig")
	end
end

function ConfigReader:getFullConfigWithDefaults()
	local config = {}

	for key, val in pairs(ConfigReader.BloxbizConfigDefaults) do
		config[key] = val
	end

	for key, val in pairs(BloxbizConfig) do
		config[key] = val
	end

	return config
end

return ConfigReader