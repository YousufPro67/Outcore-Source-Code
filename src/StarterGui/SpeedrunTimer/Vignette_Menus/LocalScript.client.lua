local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local SettingService = knit.GetService("SettingService")

local function SetValue(plr,value,settingname)
	if settingname == "FOLLOW" then
		script.Parent.Visible = not value
	elseif settingname == "INGAME" then
		script.Parent.Visible = not value
	end
end
SettingService.callbackRE:Connect(function(settingname,value)
	SetValue(game.Players.LocalPlayer,value,settingname)
end)