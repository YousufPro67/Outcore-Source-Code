local LocalizationService = game:GetService("LocalizationService")

local Configuration = require(script.Parent.Parent.Configuration)

local function GetCountryRegionForPlayer(player: Player): (boolean, string)
	assert(player, "Please pass in a valid player!")

	if Configuration then
		if Configuration.playerCountry and Configuration.playerCountry[player.UserId] then
			return true, Configuration.playerCountry[player.UserId]
		end

		if Configuration.countryCodeOverride then
			return true, Configuration.countryCodeOverride
		end
	end

	return pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)
end

return GetCountryRegionForPlayer
