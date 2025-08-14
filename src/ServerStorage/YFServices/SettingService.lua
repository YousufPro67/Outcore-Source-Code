local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
Settings = knit.CreateService({
	Name = "SettingService",
	Client = {OnValueChanged = knit.CreateSignal()},
	Players = {
		OnValueChanged = {},
		OnDataChanged = {}
	},
	Server = {}
})

function Settings.Players:Initialize(player:Player)
	Settings.Players[player.UserId] = {
		INGAME = false,
		FOLLOW = true,
		PAUSED = false,
		FINISHED = false,
		RETRY = false,
		SPS = 0,
		LEVEL_NAME = "",
		CAMPART = workspace.CameraParts:WaitForChild("MainCam"),
		OnValueChanged = {},
		OnDataChanged = {}
	}
	repeat wait(0.001) until Settings.Players[player.UserId]
	print('Player '..player.Name.."'s Settings are ready to be used!")
	
end

function Settings.Players:Cleanup(player)
	Settings.Players[player.UserId] = nil
end

function Settings.Players:Get(player)
	return Settings.Players[player.UserId]
end

function Settings.Players:Set(player, SettingName, Value)
	local Setting = tostring(SettingName).upper(SettingName)
	if Settings.Players[player.UserId] then
		Settings.Players[player.UserId][Setting] = Value
		Settings.Client.OnValueChanged:Fire(player,Setting,Value)
		for _, callback in ipairs(Settings.Players[player.UserId].OnValueChanged) do
			callback(player, Value, Setting)
		end
		for _, callback in ipairs(Settings.Players[player.UserId].OnDataChanged) do
			callback(player, Settings.Players[player.UserId])
		end
	end
end

function Settings.Players.OnValueChanged:Connect(plr, callback)
	table.insert(Settings.Players[plr.UserId].OnValueChanged, callback)
end

function Settings.Players.OnDataChanged:Connect(plr, callback)
	table.insert(Settings.Players[plr.UserId].OnDataChanged, callback)
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	Settings.Players:Cleanup(player)
end)

local func = Settings.Players
for k, funcs in pairs(func) do
	if k == "Get" or k == "Set" then
		Settings.Client[k] = funcs
	end
end

return Settings
