local chat_service = game:GetService("Chat")
local replicated_storage = game:GetService("ReplicatedStorage")

local exe_storage = replicated_storage:WaitForChild("exe_storage")

exe_storage.events.filter_string.OnServerInvoke = function(player, text)
	
	local filteredText = text

	local success, errorMessage = pcall(function()
		filteredText = chat_service:FilterStringForBroadcast(text, player)

		return filteredText
	end)

	if not success then warn("Had issues filtering message. " .. errorMessage) return end

	return filteredText
end