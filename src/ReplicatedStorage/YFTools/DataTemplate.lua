local module = {
	
	--//SETTINGS
	FOV = 100,
	MUSIC = 100,
	SFX = 100,
	CAMERA_SHAKE = true,
	BRIGHTNESS = 3,
	SHADOWS = true,
	CLOCK_TIME = 0,
	EXPOSURE_COMPENSATION = 0,
	SHOW_SPEEDLINES = false,
	SHOW_BODY = false,
	SPEED = 100,
	
	--//STATS
	LEVELS = 2,
	ABOUT_VERSION_CHECKED = 0,
	STUDS = 0,
	JUMPS = 0,
	FINISHES = 0,
	KILLS = 0,
	DIMENSIONS = {
		SKYHOP = {
			QUESTS = {}
		}
	},
	BEST_TIMES = {};
	
}

return module
