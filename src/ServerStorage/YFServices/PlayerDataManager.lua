local knit = require(game.ReplicatedStorage.Packages.Knit)
local ProfileStore = require(game.ServerScriptService.PlayerData.ProfileStore)
local ProfileTemplate = require(game.ReplicatedStorage.YFTools.DataTemplate)

local Players = game:GetService("Players")

local module = knit.CreateService({
    Name = "PlayerDataManager",
    Client = {
		OnValueChanged = knit.CreateSignal(),
		OnDataChanged = knit.CreateSignal()
    	}
})

module.Profiles = {}
module.OnValueChanged = {}
module.OnDataChanged = {}

local ProfileStoreInstance = ProfileStore.New("Test", ProfileTemplate)

-- Profile loading and releasing

function module:LoadProfile(player)
    local profile = ProfileStoreInstance:StartSessionAsync("Player_" .. player.UserId, {
       Cancel = function()
          return player.Parent ~= Players
       end,
    })

    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        profile.OnSessionEnd:Connect(function()
            module.Profiles[player.UserId] = nil
            warn("Data issue, try again shortly. If issue persists, contact us!")
            player:Kick("Data issue, try again shortly. If issue persists, contact us!")
        end)
        if player:IsDescendantOf(Players) then
            module.Profiles[player.UserId] = profile
			print(`Profile loaded for {player.DisplayName}!`)
            module.Client.OnDataChanged:Fire(player, profile.Data)
			for k, v in pairs(profile.Data) do 
				module.Client.OnValueChanged:Fire(player, k, v)
			end
        else
            profile:EndSession()
        end
    else
        warn("Data issue, try again shortly. If issue persists, contact us!")
        player:Kick("Data issue, try again shortly. If issue persists, contact us!")
    end
end

function module:ReleaseProfile(player)
    local profile = module.Profiles[player.UserId]
    if profile ~= nil then
        profile:EndSession()
    end
end

-- Knit lifecycle
function module:KnitInit()
    -- Load profiles for players already in game (e.g. on server restart)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:LoadProfile(player)
            print(player.Name .. "'s profile loaded successfully.")
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        self:LoadProfile(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:ReleaseProfile(player)
    end)
end

-- Data accessors
function module:CheckData(plr: Player): boolean
    local profile = module.Profiles[plr.UserId]
    if not profile then return end
    if not profile:IsActive() then return end
    return true
end

function module:Get(plr: Player): {any}
    local profile = module.Profiles[plr.UserId]
    return profile and profile.Data or ProfileTemplate
end

function module:Set(plr: Player, settingn: string, value: any): ()
    if not module:CheckData(plr) then return end
    local setting = tostring(settingn):upper()
    local profile = module.Profiles[plr.UserId]
    profile.Data[setting] = value
    module.Client.OnValueChanged:Fire(plr, setting, value)
	module.Client.OnDataChanged:Fire(plr, profile.Data)
    for _, callback in ipairs(module.OnValueChanged) do
        callback(plr, value, setting)
    end
    for _, callback in ipairs(module.OnDataChanged) do
        callback(plr, profile.Data)
    end
end

function module:Save(player: Player): ()
    local profile = module.Profiles[player.UserId]
    if profile then
        profile:Save()
    end
end

function module.OnValueChanged:Connect(_, callback): ()
    table.insert(module.OnValueChanged, callback)
end

function module.OnDataChanged:Connect(_, callback): ()
    table.insert(module.OnDataChanged, callback)
end

for k, func in pairs(module) do
	local Excluded = {
		"KnitInit",
		"LoadProfile",
		"ReleaseProfile",
		"Set",
		"Profiles",
		"OnValueChanged",
		"OnDataChanged"
	}
	if table.find(Excluded, k) then
		continue
	end
	print("Adding data control: " .. k)
    module.Client[k] = func
end

return module