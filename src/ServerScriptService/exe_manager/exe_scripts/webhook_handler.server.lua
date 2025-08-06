local chat_service = game:GetService("Chat")
local http_service = game:GetService("HttpService")
local players_service = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_script_service = game:GetService("ServerScriptService")

local exe_storage = replicated_storage:WaitForChild("exe_storage")
local webhook_events = exe_storage.events.webhook_events
local notify_module = require(exe_storage.notify_module)

local link = script.Parent.server_status.webhook_link

local ELEMENTS = require(server_script_service.exe_manager.ELEMENTS)

webhook_events.send_message.Event:Connect(function(author, message)
	if link.Value ~= "" then
		
		if ELEMENTS.HAS_ACCESS(author) then
			
			local formatted = http_service:JSONEncode({

				content = message;
				username = (author.Name .. " " .. '[' .. author.UserId .. ']');
				avatar_url = ('https://www.roblox.com/headshot-thumbnail/image?userId=' .. author.UserId .. '&width=150&height=150&format=png')

			})

			if link.Value then
				http_service:PostAsync(link.Value, formatted)
			end
		end
	end
end)