local FilterParams = {}

FilterParams.GET_ADS_PLAYER_PARAMETERS = {
	["player_id"] = "N",
	["player_age"] = "N",
	["player_locale_id"] = "S",
	["player_membership_type"] = "N",
	["country_code"] = "S",
}

FilterParams.GET_ADS_PARAMETERS = {
	["bloxbiz_version"] = "N",
	["bloxbiz_id"] = "N",
	["game_id"] = "N",
	["creator_id"] = "N",
	["place_id"] = "N",
	["job_id"] = "S",
	["private_server_id"] = "S",
	["part_name"] = "S",
	["part_shape"] = "S",
	["part_size"] = "S",
	["part_color"] = "S",
	["part_orientation"] = "S",
	["part_position"] = "S",
	["is_studio"] = "BOOL",
}

return FilterParams
