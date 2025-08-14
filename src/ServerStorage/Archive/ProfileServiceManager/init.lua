-- services --

--local PlayersService = game:GetService("Players")

-- modules --

--local ProfileService = require(script.ProfileService)
local Knit = require(game.ReplicatedStorage.Packages.Knit)

-- variables --

--local dataStoreName = "test7"
--local profileStoreData = {}
--local profiles = {}
--local settingCallbacks = {}

------------------------------ setup ----------------------------

local ProfileServiceManager = Knit.CreateService({
	Name = "PlayerDataMafffffnager",
	Client = {OnDataChanged = Knit.CreateSignal()}
})
--local profileTemplete = {
--	FOV = 100,
--	MUSIC = true,
--	LEVELS = 1,
--	BEST_TIMES = {}
--}

--profileStoreData = ProfileService.GetProfileStore(dataStoreName, profileTemplete)

------------------------------ functions declare ----------------------------

--local function setAddedPlayerProfile(player: Player)
--	local profile = profileStoreData:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
--	if profile ~= nil then
--		profile:AddUserId(player.UserId)
--		profile:Reconcile()
--		profile:ListenToRelease(function()
--			profiles[player] = nil
--			player:Kick("Failed to load your data from data dictionary. Please try again.")
--		end)
--		if player:IsDescendantOf(PlayersService) == true then
--			profiles[player] = profile
--			local globalUpdates = profile.GlobalUpdates
--			for index, update in pairs(globalUpdates:GetActiveUpdates())do
--				globalUpdates:LockActiveUpdate(update[1])
--			end
--			for index, update in pairs(globalUpdates:GetLockedUpdates())do
--				globalUpdates:ClearLockedUpdate(update[1])
--			end
--			globalUpdates:ListenToNewActiveUpdate(function(id, data)
--				globalUpdates:LockActiveUpdate(id)
--			end)
--			globalUpdates:ListenToNewLockedUpdate(function(id, data)
--				globalUpdates:ClearLockedUpdate(update[1])
--			end)
--		else
--			profile:Release()
--		end
--	else
--		player:Kick("Failed to load your data from data dictionary. Please try again.")
--	end
--end

--for _, player in ipairs(PlayersService:GetPlayers()) do
--	task.spawn(setAddedPlayerProfile, player)
--end

------------------------------ events process ----------------------------

--PlayersService.PlayerAdded:Connect(setAddedPlayerProfile)

--PlayersService.PlayerRemoving:Connect(function(player)
--	local profile = profiles[player]
--	if profile ~= nil then
--		profile:Save()
--	end
--end)

------------------------------ module ----------------------------

--function ProfileServiceManager:Release(player: Player)
--	local profile = profiles[player]
--	if profile then
--		profile:Release()
--	end
--end

--function ProfileServiceManager:Get(player: Player)
--	local profile = profiles[player]
--	if profile then
--		return profile
--	else
--		return nil
--	end
--end

--local function constructKey(...)
--	local args = {...}
--	local key = tostring(args[3]).upper(args[3]) or args[3]
--	for i = 4, select('#', ...) do
--		local k = tostring(args[i]).upper(args[i]) or args[i]
--		key = key .. "." .. k
--	end
--	return key
--end

--function ProfileServiceManager:Set(...)
--	local player = select(1, ...)
--	local data = select(2, ...)
--	local key = constructKey(...)

--	local profile = profiles[player]
--	if profile then
--		local setting = key
--		if setting == "WINS" or setting == "TOTALMEDALS" then
--			if profile.Data[key] and profile.Data[key] > data then
--				return
--			end
--		end
--		profile.Data[key] = data
--	end
--end

--function ProfileServiceManager:Save(player:Player)
--	local profile = profiles[player]
--	if profile then
--		profile:Save()
--	end
--end

--function ProfileServiceManager:CheckData(plr:Player)
--	if ProfileServiceManager[plr] then
--		return true
--	else
--		return false
--	end
--end

--function ProfileServiceManager:registerCallback(player, setting, callback)
--	local settingName = typeof(setting) == "string" and tostring(setting).upper(setting) or setting
--	print(player,settingName,callback)
--	if not settingCallbacks[settingName] then
--		settingCallbacks[settingName] = {}
--	end
--	table.insert(settingCallbacks[settingName], callback)
--end

--for k,func in pairs(ProfileServiceManager) do
--	ProfileServiceManager.Client[k] = k ~= "Set" and func
--end

return ProfileServiceManager
