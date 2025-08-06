local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_script_service = game:GetService("ServerScriptService")

local exe_storage = replicated_storage:WaitForChild("exe_storage")
local notify_module = require(exe_storage.notify_module)

local events = exe_storage.events.custom_command_events

local ELEMENTS = require(server_script_service.exe_manager.ELEMENTS)

events.change_time_night.OnServerEvent:Connect(function(player)
	if ELEMENTS.HAS_ACCESS(player) then
		local lighting = game:GetService("Lighting")

		lighting.ClockTime = 0
	end
end)

events.change_time_day.OnServerEvent:Connect(function(player)
	if ELEMENTS.HAS_ACCESS(player) then
		local lighting = game:GetService("Lighting")

		lighting.ClockTime = 10
	end
end)

events.clear_accessories.OnServerEvent:Connect(function(player, recipient)
	if ELEMENTS.HAS_ACCESS(player) then
		local character = recipient.Character

		for i, accessories in pairs(character:GetChildren()) do
			if accessories:IsA("Accessory") then
				accessories:Destroy()
			end
		end
	end
end)

events.exposure.OnServerEvent:Connect(function(player, input)
	if ELEMENTS.HAS_ACCESS(player) then
		local num = tonumber(input)

		if num then
			lighting.ExposureCompensation = input
		end
	end
end)

events.char_scale.OnServerEvent:Connect(function(player, recipient, input)
	if ELEMENTS.HAS_ACCESS(player) then
		local num = tonumber(input)
		
		if num then
			recipient.Character:ScaleTo(num)
		end
	end
end)

events.brightness.OnServerEvent:Connect(function(player, value)
	if ELEMENTS.HAS_ACCESS(player) then
		lighting.Brightness = value
	end
end)