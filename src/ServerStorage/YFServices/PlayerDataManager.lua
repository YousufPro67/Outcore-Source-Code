local knit = require(game.ReplicatedStorage.Packages.Knit)
module = knit.CreateService({
	Name = "PlayerDataManager",
	Client = {callbackRE = knit.CreateSignal()}
	
})
module.Profiles = {}
module.OnValueChanged = {}
module.OnDataChanged = {}

function module:CheckData(plr:Player)
	if not module.Profiles[plr.UserId] then
		return
	end
	if not module.Profiles[plr.UserId]:IsActive() then
		return
	end
	return true
end

function module:Get(plr:Player)
	local profile = module.Profiles[plr.UserId]
	if not profile then
		repeat
			wait(1)
		until
		module.Profiles[plr.UserId]
	end
	profile = module.Profiles[plr.UserId]
	print(profile)
	return profile.Data
end

function module:Set(plr,settingn,value)
	if not module:CheckData(plr) then return end
	local setting = tostring(settingn):upper()
	local profile = module.Profiles[plr.UserId]

	profile.Data[setting] = value
	module.Client.callbackRE:Fire(plr,setting,value)
	
	for _, callback in ipairs(module.OnValueChanged) do
		callback(plr, value, setting)
	end
	
	for _, callback in ipairs(module.OnDataChanged) do
		callback(plr, profile.Data)
	end
end

function module:Save(player:Player)
	local profile = module.Profiles[player.UserId]
	profile:Save()
end

function module.OnValueChanged:Connect(plr, callback)
	table.insert(module.OnValueChanged, callback)
end

function module.OnDataChanged:Connect(plr, callback)
	table.insert(module.OnDataChanged, callback)
end

for k,func in pairs(module) do
	module.Client[k] = k ~= "Set" and func
end
return module

