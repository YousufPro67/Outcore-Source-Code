local http_service = game:GetService("HttpService")
local group_service = game:GetService("GroupService")
local messaging_service = game:GetService("MessagingService")
local policy_service = game:GetService("PolicyService")
local players_service = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_script_service = game:GetService("ServerScriptService")

local exe_manager = server_script_service.exe_manager
local exe_storage = replicated_storage:WaitForChild("exe_storage")
local events = exe_storage.events.banit_events
local webhook_events = exe_storage.events.webhook_events

local notify_module = require(exe_storage.notify_module)

local ELEMENTS = require(exe_manager.ELEMENTS)
local IDSAVING = require(exe_manager.IDSAVING)
local CUSTOM_COMMAND = require(exe_storage.custom_commands)

exe_storage.events.get_bans.OnServerInvoke = function(player)
	local index = IDSAVING.GET_USERIDS()
	local expiring_index = IDSAVING.GET_EXPIRING_USERIDS()

	return index, expiring_index
end

exe_storage.events.get_server_bans.OnServerInvoke = function(player)
	local ids = {}

	for i, items in pairs(script.Parent.server_bans:GetChildren()) do
		table.insert(ids, items.Name)
	end

	return ids
end

exe_storage.events.get_id_info.OnServerInvoke = function(player, id)
	local full_index = {}
	local success, history = pcall(function()
		return players_service:GetBanHistoryAsync(id)
	end)

	if success then
		repeat
			local page = history:GetCurrentPage()

			for caseId, case in page do
				table.insert(full_index, case)
			end

			if history.IsFinished then
				break
			end

			history:AdvanceToNextPageAsync()

		until history.IsFinished == true

		return full_index

	else
		warn("Error:", history)

		return nil
	end
end

--// GLOBAL BAN

events.global_ban.OnServerEvent:Connect(function(player, data)
	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "GLOBAL BAN")) then

		local ref = {}

		for i, id in pairs(data.PLAYERS) do
			if ELEMENTS.HAS_ACCESS_OFFLINE(id) then
				if not ELEMENTS.GET_PLAYER_PROPERTIES(id, "BANNABLE") or not ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(id), "BANNABLE") then
					table.remove(data.PLAYERS, table.find(data.PLAYERS, id))
				end
			end
		end

		for i, id in pairs(data.PLAYERS) do
			table.insert(ref, players_service:GetNameFromUserIdAsync(id))
		end

		local config = {
			UserIds = data.PLAYERS,

			Duration = -1,

			DisplayReason = data.DISPLAY_REASON,
			PrivateReason = data.PRIVATE_REASON,

			ExcludeAltAccounts = data.EXCLUDE_ALT,
			ApplyToUniverse = data.UNIVERSE
		}

		local success, error = pcall(function()
			return players_service:BanAsync(config)
		end)

		if success then
			notify_module:notify(#data.PLAYERS .. " player(s) are successfully banned!", 4, "rbxassetid://11419666746", player)

			local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. table.concat(ref, ", ")  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: Permanent"

			webhook_events.send_message:Fire(player, message)

			--

			for i, id in pairs(data.PLAYERS) do
				IDSAVING.SAVE_USERID(id)
			end
		else
			warn(error)

			notify_module:notify("There was a problem banning " .. #data.PLAYERS .. " player(s)." , 4, "rbxassetid://11419666746", player)
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// GLOBAL TIMED BAN

events.global_timed_ban.OnServerEvent:Connect(function(player, data)
	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "GLOBAL BAN")) then

		local ref = {}

		for i, id in pairs(data.PLAYERS) do
			if ELEMENTS.HAS_ACCESS_OFFLINE(id) then
				if not ELEMENTS.GET_PLAYER_PROPERTIES(id, "BANNABLE") or not ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(id), "BANNABLE") then
					table.remove(data.PLAYERS, table.find(data.PLAYERS, id))
				end
			end
		end

		for i, id in pairs(data.PLAYERS) do
			table.insert(ref, players_service:GetNameFromUserIdAsync(id))
		end

		local config = {
			UserIds = data.PLAYERS,

			Duration = data.DURATION,

			DisplayReason = data.DISPLAY_REASON,
			PrivateReason = data.PRIVATE_REASON,

			ExcludeAltAccounts = data.EXCLUDE_ALT,
			ApplyToUniverse = data.UNIVERSE
		}

		local success, error = pcall(function()
			return players_service:BanAsync(config)
		end)

		if success then
			notify_module:notify(#data.PLAYERS .. " player(s) are successfully banned!", 4, "rbxassetid://11419666746", player)

			local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. table.concat(ref, ", ")  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: " .. data.DURATION .. " seconds"

			webhook_events.send_message:Fire(player, message)

			--

			for i, id in pairs(data.PLAYERS) do
				IDSAVING.SAVE_USERID(id)
			end
		else
			warn(error)

			notify_module:notify("There was a problem banning " .. #data.PLAYERS .. " player(s)." , 4, "rbxassetid://11419666746", player)
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// BAN

events.ban.OnServerEvent:Connect(function(player, data)
	local recipient
	local id = players_service:GetUserIdFromNameAsync(data["USERNAME"])

	local success, err = pcall(function()
		recipient = players_service[data["USERNAME"]]
	end)

	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "BAN")) then

		if ELEMENTS.HAS_ACCESS(recipient) then

			if ELEMENTS.GET_PLAYER_PROPERTIES(id, "BANNABLE") or ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(id), "BANNABLE") then

				local config: BanConfigType = {
					UserIds = {players_service:GetUserIdFromNameAsync(data["USERNAME"])},

					Duration = -1,

					DisplayReason = data["DISPLAY_REASON"],
					PrivateReason = data["PRIVATE_REASON"],

					ExcludeAltAccounts = data["EXCLUDE_ALT"],
					ApplyToUniverse = data["UNIVERSE"]
				}

				local success, error = pcall(function()
					return players_service:BanAsync(config)
				end)

				if success then
					notify_module:notify(data["USERNAME"] .. " is successfully banned!", 4, "rbxassetid://11419666746", player)

					local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. data["USERNAME"]  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: " .. data["DURATION"] .. " seconds"

					webhook_events.send_message:Fire(player, message)

					--

					IDSAVING.SAVE_USERID(id)
				else
					warn(error)

					notify_module:notify("There was a problem banning " .. data["USERNAME"], 4, "rbxassetid://11419666746", player)
				end
			else
				notify_module:notify("You cannot ban this player.", 4, "rbxassetid://11419666746", player)
			end
		else

			local config: BanConfigType = {
				UserIds = {players_service:GetUserIdFromNameAsync(data["USERNAME"])},

				Duration = -1,

				DisplayReason = data["DISPLAY_REASON"],
				PrivateReason = data["PRIVATE_REASON"],

				ExcludeAltAccounts = data["EXCLUDE_ALT"],
				ApplyToUniverse = data["UNIVERSE"]
			}

			local success, error = pcall(function()
				return players_service:BanAsync(config)
			end)

			if success then
				notify_module:notify(data["USERNAME"] .. " is successfully banned!", 4, "rbxassetid://11419666746", player)

				local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. data["USERNAME"]  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: " .. data["DURATION"] .. " seconds"

				webhook_events.send_message:Fire(player, message)

				--

				IDSAVING.SAVE_USERID(id)
			else
				warn(error)

				notify_module:notify("There was a problem banning " .. data["USERNAME"], 4, "rbxassetid://11419666746", player)
			end

		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// TIMED BAN

events.timed_ban.OnServerEvent:Connect(function(player, data)
	local recipient
	local id = players_service:GetUserIdFromNameAsync(data["USERNAME"])

	local success, err = pcall(function()
		recipient = players_service[data["USERNAME"]]
	end)

	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "BAN")) then

		if ELEMENTS.HAS_ACCESS(recipient) then

			if ELEMENTS.GET_PLAYER_PROPERTIES(id, "BANNABLE") or ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(id), "BANNABLE") then

				local config: BanConfigType = {
					UserIds = {players_service:GetUserIdFromNameAsync(data["USERNAME"])},

					Duration = data["DURATION"],

					DisplayReason = data["DISPLAY_REASON"],
					PrivateReason = data["PRIVATE_REASON"],

					ExcludeAltAccounts = data["EXCLUDE_ALT"],
					ApplyToUniverse = data["UNIVERSE"]
				}

				local success, error = pcall(function()
					return players_service:BanAsync(config)
				end)

				if success then
					notify_module:notify(data["USERNAME"] .. " is successfully banned!", 4, "rbxassetid://11419666746", player)

					local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. data["USERNAME"]  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: " .. data["DURATION"] .. " seconds"

					webhook_events.send_message:Fire(player, message)

					--

					IDSAVING.SAVE_EXPIRING_USERID(id, data["DURATION"])
				else
					warn(error)

					notify_module:notify("There was a problem banning " .. data["USERNAME"], 4, "rbxassetid://11419666746", player)
				end
			else
				notify_module:notify("You cannot ban this player.", 4, "rbxassetid://11419666746", player)
			end
		else

			local config: BanConfigType = {
				UserIds = {players_service:GetUserIdFromNameAsync(data["USERNAME"])},

				Duration = data["DURATION"],

				DisplayReason = data["DISPLAY_REASON"],
				PrivateReason = data["PRIVATE_REASON"],

				ExcludeAltAccounts = data["EXCLUDE_ALT"],
				ApplyToUniverse = data["UNIVERSE"]
			}

			local success, error = pcall(function()
				return players_service:BanAsync(config)
			end)

			if success then
				notify_module:notify(data["USERNAME"] .. " is successfully banned!", 4, "rbxassetid://11419666746", player)

				local message = "Action: Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. data["USERNAME"]  .. "\n Reason: " .. data["DISPLAY_REASON"]  .. "\n Moderator Note: " .. data["PRIVATE_REASON"]  .. "\n Duration: " .. data["DURATION"] .. " seconds"

				webhook_events.send_message:Fire(player, message)

				--

				IDSAVING.SAVE_EXPIRING_USERID(id, data["DURATION"])
			else
				warn(error)

				notify_module:notify("There was a problem banning " .. data["USERNAME"], 4, "rbxassetid://11419666746", player)
			end
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// SERVER BAN

events.server_ban.OnServerEvent:Connect(function(player, username, reason)
	local recipient

	local success, err = pcall(function()
		recipient = players_service[username]
	end)

	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "SERVER BAN")) then

		if ELEMENTS.HAS_ACCESS(recipient) then

			if ELEMENTS.GET_PLAYER_PROPERTIES(recipient.UserId, "BANNABLE") or ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(recipient.UserId), "BANNABLE") then

				local id_item = script.userid:Clone()

				id_item.Name = recipient.UserId
				id_item.Parent = script.Parent.server_bans
				id_item:SetAttribute("reason", reason)

				recipient:Kick(reason)

				--

				notify_module:notify(username .. " is successfully server banned!", 4, "rbxassetid://11419666746", player)

				--

				local message = "Action: Server Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

				webhook_events.send_message:Fire(player, message)
			else
				notify_module:notify("You cannot server ban this player.", 4, "rbxassetid://11419666746", player)
			end
		else
			local id_item = script.userid:Clone()

			id_item.Name = recipient.UserId
			id_item.Parent = script.Parent.server_bans
			id_item:SetAttribute("reason", reason)

			recipient:Kick(reason)

			--

			notify_module:notify(username .. " is successfully server banned!", 4, "rbxassetid://11419666746", player)

			--

			local message = "Action: Server Ban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

			webhook_events.send_message:Fire(player, message)
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// UNBAN

events.unban.OnServerEvent:Connect(function(player, username, ban_type)
	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "UNBAN")) then

		if ban_type == "Server Ban" then
			local id = players_service:GetUserIdFromNameAsync(username)
			local item = script.Parent.server_bans:FindFirstChild(id)

			if item then
				item:Destroy()

				--

				notify_module:notify(username .. " is successfully been server unbanned!", 4, "rbxassetid://12974219084", player)

				local message = "Action: Server Unban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

				webhook_events.send_message:Fire(player, message)
			end

		else

			local id = players_service:GetUserIdFromNameAsync(username)
			local config: UnbanConfigType = {
				UserIds = {id},
				ApplyToUniverse = true
			}

			local success, error = pcall(function()
				return players_service:UnbanAsync(config)
			end)

			if success then
				notify_module:notify(username .. " is successfully been unbanned!", 4, "rbxassetid://12974219084", player)

				local message = "Action: Unban" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

				webhook_events.send_message:Fire(player, message)

				--

				IDSAVING.REMOVE_USERID(id)
			else
				warn(error)

				notify_module:notify("There was a problem revoking the ban of " .. username, 4, "rbxassetid://11419666746", player)
			end
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// KICK

events.kick.OnServerEvent:Connect(function(player, username, reason)
	local recipient = players_service[username]

	if (ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "KICK")) then

		if ELEMENTS.HAS_ACCESS(recipient) then

			if ELEMENTS.GET_PLAYER_PROPERTIES(recipient.UserId, "KICKABLE") or ELEMENTS.GET_RANK_PROPERTIES(ELEMENTS.GET_RANK_IN_PERMITTED_GROUP(recipient.UserId), "KICKABLE") then

				recipient:Kick(reason)

				notify_module:notify(username .. " is successfully kicked!", 4, "rbxassetid://11295285778", player)

				--

				local message = "Action: Kick" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

				webhook_events.send_message:Fire(player, message)
			else
				notify_module:notify("You cannot kick this player.", 4, "rbxassetid://11419666746", player)
			end

		else

			recipient:Kick(reason)

			notify_module:notify(username .. " is successfully kicked!", 4, "rbxassetid://11295285778", player)

			--

			local message = "Action: Kick" .. "\n Moderator: @" .. player.Name  .. "\n Player: @" .. username

			webhook_events.send_message:Fire(player, message)
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// NOTIFY

events.notify.OnServerEvent:Connect(function(player, recipient, text, duration, icon)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "NOTIFY") then

		notify_module:notify(text, duration, icon, recipient)

	end
end)

--// SERVER ANNOUNCEMENT

local operational = false

events.announce.OnServerEvent:Connect(function(player, text, icon, duration, fullscreen)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "SERVER ANNOUNCE") then
		if not operational then
			operational = true

			events.announce:FireAllClients(player.UserId, text, icon, duration, fullscreen)
			notify_module:notify("Successfully announced the server!", 4, "rbxassetid://12966403319", player)

			--
			task.wait(duration)
			--

			operational = false
		else
			notify_module:notify("The server is still in announcement screen. Try again later.", 4, "rbxassetid://11430233477", player)
		end
	end
end)

--// SERVER PRIVACY

events.server_lock.OnServerEvent:Connect(function(player, locked, holders_only)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "SERVER PRIVACY") then

		if script.Parent.server_status.shutting_down.Value then

			notify_module:notify("Unable to modify, server is already shutting down...", 4, "rbxassetid://11419702673", player)
		else

			local status = script.Parent.server_status

			if (locked and holders_only) then
				status.server_locked.Value = true
				status.server_locked:SetAttribute("holders_only", true)

				notify_module:notify("Players are now unable to join except for EXE Panel holders.", 4, "rbxassetid://14187755345", player)
			elseif (locked and not holders_only) then

				status.server_locked.Value = true
				status.server_locked:SetAttribute("holders_only", false)

				notify_module:notify("Players are now unable to join.", 4, "rbxassetid://14187755345", player)
			else
				status.server_locked.Value = false

				notify_module:notify("Server is unlocked. Players are able to join this server.", 4, "rbxassetid://14187749511", player)
			end
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

events.server_shutdown.OnServerEvent:Connect(function(player)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "SERVER SHUTDOWN") then

		local status = script.Parent.server_status

		script.Parent.server_status.shutting_down.Value = true
		status.server_locked.Value = true

		local message = "Action: Server Shutdown" .. "\n Moderator: @" .. player.Name  .. "\n Action: Server Shutdown"

		webhook_events.send_message:Fire(player, message)

		events.server_shutdown:FireAllClients()

		for i, plrs in pairs(players_service:GetPlayers()) do
			notify_module:notify(player.DisplayName .. " shut down the server and you will be kicked anytime now.", 
				5, "rbxassetid://12967561554", plrs)
		end

		--

		task.wait(3)

		--

		for i, plrs in pairs(players_service:GetPlayers()) do
			plrs.Character.HumanoidRootPart.Anchored = true

			--

			plrs:Kick(player.DisplayName .. " shut down the server.")
		end
	end
end)

--// TELEPORT

events.teleport.OnServerEvent:Connect(function(player, teleport_type, recipient)
	if ELEMENTS.HAS_ACCESS(player) then
		local attachment = exe_storage.objects.container_sparkles.attachment:Clone()

		attachment.Parent = recipient.Character:WaitForChild("HumanoidRootPart")
		attachment.sparkles:Emit(50)

		if teleport_type == "bring" then
			local char_a = recipient.Character
			local char_b = player.Character

			--

			char_a:PivotTo(char_b.Head.CFrame)
		elseif teleport_type == "follow" then
			local char_a = recipient.Character
			local char_b = player.Character

			--

			char_b:PivotTo(char_a.Head.CFrame)
		end

		--
		task.wait(5)
		--

		attachment.sparkles:Destroy()
	end
end)

--// INVISIBLE, VISIBLE

events.visibility.OnServerEvent:Connect(function(player, visible, recipient:Player)
	if ELEMENTS.HAS_ACCESS(player) then
		local character = recipient.Character or recipient.CharacterAdded:Wait()
		local attachment = exe_storage.objects.container_sparkles.attachment:Clone()

		attachment.Parent = character:WaitForChild("HumanoidRootPart")
		attachment.sparkles:Emit(50)

		if visible then
			for i, parts in pairs(character:GetDescendants()) do
				if parts.Name ~= "HumanoidRootPart" then
					if (parts:IsA("MeshPart") or parts:IsA("Part") or parts:IsA("Decal")) then
						parts.Transparency = 0
					end
				end
			end

		else
			for i, parts in pairs(character:GetDescendants()) do
				if parts.Name ~= "HumanoidRootPart" then
					if (parts:IsA("MeshPart") or parts:IsA("Part") or parts:IsA("Decal")) then
						parts.Transparency = 1
					end
				end
			end
		end


		--
		task.wait(5)
		--

		attachment.sparkles:Destroy()
	end
end)

--// CONFIGURE HUMANOID

events.configure.OnServerEvent:Connect(function(player, recipient, configure_type, value)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "CONFIGURE HUMANOID") then

		local character = recipient.Character or recipient.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")

		if configure_type == "walk" then
			humanoid.WalkSpeed = value

			notify_module:notify("Successfully set the Walk Speed to " .. value .. "!", 4, "rbxassetid://12975608939", player)

		elseif configure_type == "jump" then
			if humanoid.UseJumpPower then
				humanoid.JumpPower = value
			else
				humanoid.JumpHeight = value
			end

			notify_module:notify("Successfully set the Jump to " .. value .. "!", 4, "rbxassetid://11432834725", player)

		elseif configure_type == "health" then
			humanoid.Health = value

			if value > 0 then
				notify_module:notify("Successfully set the Health to " .. value .. "!", 4, "rbxassetid://11419717444", player)
			else
				notify_module:notify("Executed " .. recipient.Name .. ".", 4, "rbxassetid://11432853212", player)
			end
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// CHANGE TEAM

events.change_team.OnServerEvent:Connect(function(player, recipient, team)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "CHANGE TEAM") then

		recipient.Team = team

		notify_module:notify("Changed " .. recipient.DisplayName .. " team to " .. team.Name .. "!", 4, "rbxassetid://11432831988", 
			player)
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

--// EFFECTS

events.give_tool.OnServerEvent:Connect(function(player, recipient, tool:Tool)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "GIVE TOOL") then

		local copy = tool:Clone()

		copy.Parent = recipient.Backpack

		notify_module:notify(tool.Name .. " is distributed to " .. recipient.DisplayName, 5, "rbxassetid://11432855214", player)
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

events.apply_effect.OnServerEvent:Connect(function(player, recipient, obj)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "APPLY EFFECT") then

		local character = recipient.Character or recipient.CharacterAdded:Wait()

		if obj:IsA("Folder") then
			local folder = obj:Clone()

			for i, effect in pairs(folder:GetChildren()) do
				local to = character:FindFirstChild(effect:GetAttribute("To") or "HumanoidRootPart")

				if to then
					effect.Parent = to
				end
			end

			folder:Destroy()
		else
			local effect = obj:Clone()
			local to = character:FindFirstChild(obj:GetAttribute("To"))

			if to then
				effect.Parent = to
			end
		end

		notify_module:notify(obj.Name .. " is applied to " .. recipient.DisplayName, 4, "rbxassetid://14187764914", player)
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", player)
	end
end)

events.clear_effects.OnServerEvent:Connect(function(player, username)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "CLEAR EFFECTS") then

		local recipient = players_service[username]
		local character = recipient.Character or recipient.CharacterAdded:Wait()

		for i, effects in pairs(character:GetDescendants()) do
			if effects:GetAttribute("EffectIcon") then
				effects:Destroy()
			end
		end

		notify_module:notify("Cleared all " .. recipient.DisplayName .. "'s effects.", 4, "rbxassetid://12967390417", player)
	end
end)

--// TOOLS

events.clear_tools.OnServerEvent:Connect(function(player, username)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "CLEAR TOOLS") then

		local recipient = players_service[username]
		local character = recipient.Character or recipient.CharacterAdded:Wait()

		character.Humanoid:UnequipTools()
		recipient.Backpack:ClearAllChildren()

		notify_module:notify("Cleared all " .. recipient.DisplayName .. "'s tools.", 4, "rbxassetid://12967390417", player)
	end 
end)

events.delete_tool.OnServerEvent:Connect(function(player, username, tool)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "DELETE TOOL") then

		local recipient = players_service[username]
		local character = recipient.Character or recipient.CharacterAdded:Wait()

		tool:Destroy()

		notify_module:notify("Deleted " .. tool.Name .. " from " .. recipient.DisplayName, 5, "rbxassetid://11326877488", player)
	end
end)

events.delete_effect.OnServerEvent:Connect(function(player, username, effect)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "DELETE EFFECT") then

		local recipient = players_service[username]
		local character = recipient.Character or recipient.CharacterAdded:Wait()

		if type(effect) == "string" then
			for i, elements in pairs(character:GetDescendants()) do
				if elements:GetAttribute("tagged") == effect then
					elements:Destroy()
				end
			end
		else
			effect:Destroy()

			notify_module:notify("Deleted " .. effect.Name .. " from " .. recipient.DisplayName, 5, "rbxassetid://11326877488", player)
		end
	end
end)

--// JAIL

events.jail.OnServerEvent:Connect(function(mod, duration, userid, params)	
	if ELEMENTS.HAS_ACCESS(mod) and ELEMENTS.ALLOWED(mod.UserId, "JAIL") then
		local player = players_service:GetPlayerByUserId(userid)
		local char = player.Character or player.CharacterAdded:Wait()
		local c = CFrame.new(Vector3.new(char.PrimaryPart.Position.X, char.Head.Position.Y + 2, char.PrimaryPart.Position.Z))
		local jail = params.OBJECT:Clone()
		local spawn = jail:FindFirstChild("SPAWN", true)
		
		if spawn then
			char.HumanoidRootPart.Anchored = params.ANCHOR_PLAYER

			jail:PivotTo(c)
			jail.Parent = workspace

			char:PivotTo(jail.SPAWN.CFrame)

			--
			task.wait(duration)
			--

			char.HumanoidRootPart.Anchored = false

			for i, parts in pairs(jail:GetDescendants()) do
				if parts:IsA("BasePart") then
					parts.CanCollide = false
					parts.Anchored = false
				end
			end

			--

			local message = "Action: Jail" .. "\n Moderator: @" .. mod.Name  .. "\n Player: @" .. player.Name .. "\n Duration: " .. tostring(duration) .. " seconds"

			webhook_events.send_message:Fire(mod, message)
		else
			warn("There was no SPAWN part in " .. jail.Name .. ". Make sure it's all in uppercase.")
		end
	else
		notify_module:notify("You have been forbidden to use this feature.", 4, "rbxassetid://12974197533", mod)
	end
end)

--// GLOBAL ANNOUNCEMENT

local topic = "GLOBAL ANNOUNCEMENT"

events.global_announce.OnServerEvent:Connect(function(player, text, icon, duration, fullscreen)
	if ELEMENTS.HAS_ACCESS(player) and ELEMENTS.ALLOWED(player.UserId, "GLOBAL ANNOUNCE") then
		if not operational then
			operational = true

			events.announce:FireAllClients(player.UserId, text, icon, duration, fullscreen)

			messaging_service:PublishAsync(topic, tostring(player.UserId) .. ";" .. text .. ";" .. icon .. ";" .. tostring(duration) .. ";" .. tostring(fullscreen))

			notify_module:notify("Announcement is pushed to all of the servers.", 4, "rbxassetid://12966403319", player)

			--
			task.wait(duration)
			--

			operational = false
		end
	end
end)

local function SUBSCRIPTION()
	local connection = messaging_service:SubscribeAsync(topic, function(message)
		local decoded = string.split(message.Data, ";")
		local player, text, icon, duration, fullscreen = tonumber(decoded[1]), decoded[2], decoded[3], tonumber(decoded[4]), tonumber(decoded[5])

		if not operational then
			operational = true

			events.announce:FireAllClients(player, text, icon, duration, fullscreen)

			--
			task.wait(duration)
			--

			operational = false
		end
	end)
end

SUBSCRIPTION()