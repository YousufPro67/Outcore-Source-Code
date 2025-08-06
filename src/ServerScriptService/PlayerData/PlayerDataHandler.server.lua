-- ProfileTemplate table is what empty profiles will default to.
-- Updating the template will not include missing template values
--   in existing player profiles!

----- Loaded Modules -----
local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local ProfileService = require(script.Parent.ProfileService)
local ProfileTemplate = require(script.Parent.Template)
local Profiles = knit.GetService("PlayerDataManager")


----- Private Variables -----

local Players = game:GetService("Players")
local ProfileStore = ProfileService.GetProfileStore(
	"Test",
	ProfileTemplate
)


----- Private Functions -----



local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			Profiles.Profiles[player] = nil
			warn("Data issue, try again shortly. If issue persists, contact us!")
			player:Kick("Data issue, try again shortly. If issue persists, contact us!")
		end)
		if player:IsDescendantOf(Players) == true then
			Profiles.Profiles[player.UserId] = profile	
		else
			
			profile:Release()
		end
	else
		warn("Data issue, try again shortly. If issue persists, contact us!")
		player:Kick("Data issue, try again shortly. If issue persists, contact us!") 
	end
end

----- Initialize -----


for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

----- Connections -----

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles.Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end)


