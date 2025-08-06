local chat_service = game:GetService("Chat")
local text_service = game:GetService("TextChatService")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")

local exe_storage = replicated_storage.exe_storage

local module = {}

function module:filter_string(text, player)
	if run_service:IsServer() then
		
		local filteredText = text

		local success, errorMessage = pcall(function()
			filteredText = chat_service:FilterStringForBroadcast(text, player)

			print(text_service.ChatVersion)

			return filteredText
		end)

		if not success then warn("Had issues filtering message. " .. errorMessage) return end

		return filteredText
		
	elseif run_service:IsClient() then
		
		return exe_storage.events.filter_string:InvokeServer(text)
		
	end
end

return module