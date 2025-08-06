local InternalConfig = {}

InternalConfig.BASE_URL = "https://analytics-api-{GAME_ID}-{GUID}.superbiz.gg"
InternalConfig.USE_INTERNAL_CONFIG_BASE_URL = false

InternalConfig.API_KEY = nil
InternalConfig.USE_INTERNAL_CONFIG_API_KEY = false

InternalConfig.BATCH_EVENTS_WAIT_TIME = 10
InternalConfig.DETECT_IMPRESSION_WAIT_TIME = 0.25
InternalConfig.DRAW_RAYCAST = false
InternalConfig.MAX_EVENT_BATCH = 1000
InternalConfig.MAX_EVENT_BATCH_SIZE = 4_000_000
InternalConfig.MAX_RETRY_EVENTS = 5
InternalConfig.MAX_RETRY_GET_ADS = 5
InternalConfig.PRINT_DEBUG_STATEMENTS = false
InternalConfig.PRINT_IMPRESSIONS = false
InternalConfig.SDK_VERSION = 53
InternalConfig.IMPRESSION_TIME_UNTIL_IMG_GIF_ROTATION = 10
InternalConfig.TIME_BETWEEN_HEART_BEAT = 60

local function getConfig()
	local ConfigDev = game.ReplicatedStorage:FindFirstChild("InternalConfigDev")
	local ConfigProd = InternalConfig
	local Config

	if ConfigDev then
		Config = require(ConfigDev)
	else
		Config = ConfigProd
	end

	return Config
end

return getConfig()
