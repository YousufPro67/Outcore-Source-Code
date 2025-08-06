local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local rev = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local slow = TweenInfo.new(5, Enum.EasingStyle.Exponential)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local banit_events = exe_storage.events.banit_events

local frame = script.Parent
local background = frame.Parent

local properties = background.properties.revoke

local close = frame.close
local expanded = frame.scroll.expanded
local minimized = frame.scroll.minimized

local db = false

function fetch_datas(id)
	local server_bans = banit_events.Parent.get_server_bans:InvokeServer()
	local name = players:GetNameFromUserIdAsync(id)
	local profile = players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	if #server_bans > 0 then
		for i, ids in pairs(server_bans) do
			if ids == tostring(id) then
				expanded.details.info.Text = "Type: Server"
				expanded.details.username.Text = "@" .. name
				expanded.profile.Image = profile

				expanded.Visible = true
				minimized.Visible = false
			else
				minimized.profile.Image = profile
				minimized.username.Text = "@" .. name

				expanded.Visible = false
				minimized.Visible = true

			end
		end
	else
		minimized.profile.Image = profile
		minimized.username.Text = "@" .. name

		expanded.Visible = false
		minimized.Visible = true
	end
end

--

minimized.actions.history.MouseButton1Click:Connect(function()
	if properties.username.Value ~= "" then
		local id

		local success, error = pcall(function()
			id = players:GetUserIdFromNameAsync(properties.username.Value)
		end)

		if success and id then
			exe_module:assets_panels("ban_history", true, {["ID"] = id, ["USERNAME"] = properties.username.Value})
		else
			exe_module:notify("An error occurred upon atempting to check Ban History.", 4)
		end
	end
end)

frame.confirm.MouseButton1Click:Connect(function()
	local plr
	local success, error = pcall(function()
		plr = players:GetUserIdFromNameAsync(frame.scroll.username.textbox.Text)
	end)

	if success then
		if not db then
			db = true

			exe_module:prompt_confirmation(true, "revoke",
				"Revoke @" .. properties.username.Value .. "'s ban?",
				"Revoking this player's ban will make them be able to join this game again."
			)

			db = false
		end
	else
		exe_module:notify("Fetching failed, unknown player.", 4, "rbxassetid://11433646681")
	end
end)

banit_events.Parent.confirmation_events.confirmation_closed.Event:Connect(function(confirmed, id)
	if confirmed and id == "revoke" then
		if expanded.Visible and not minimized.Visible then
			banit_events.unban:FireServer(properties.username.Value, "Server Ban")
		else
			banit_events.unban:FireServer(properties.username.Value, "")
		end

		exe_module:direct_panels("revoke", false)
	end
end)

--

frame.scroll.username.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.username, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

frame.scroll.username.textbox.FocusLost:Connect(function()
	local id
	local success, error = pcall(function()
		id = players:GetUserIdFromNameAsync(frame.scroll.username.textbox.Text)
	end)

	tween_service:Create(frame.scroll.username, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()

	if success then
		exe_module:prompt_resync(true, "Fetching...")

		fetch_datas(id)

		properties.username.Value = frame.scroll.username.textbox.Text

		exe_module:prompt_resync(false)
	else
		frame.scroll.username.textbox.Text = properties.username.Value

		properties.username.Value = ""

		exe_module:notify("Fetching failed, unknown player.", 4, "rbxassetid://11433646681")
	end
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("revoke", false)
end)

--// HOVER

tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(frame.scroll.username.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

close.MouseEnter:Connect(function()
	close.gradient.Enabled = true

	tween_service:Create(close.icon.scale, info, {Scale = 1.2}):Play()
end)

close.MouseButton1Down:Connect(function()
	tween_service:Create(close.icon.scale, info, {Scale = .8}):Play()
end)

close.InputEnded:Connect(function()
	close.gradient.Enabled = false

	tween_service:Create(close.icon.scale, info, {Scale = 1}):Play()
end)

close.MouseButton1Click:Connect(function()
	exe_module:direct_panels("revoke", false)
end)

--

frame.confirm.MouseEnter:Connect(function()
	tween_service:Create(frame.confirm, info, {BackgroundColor3 = Color3.fromRGB(112, 117, 120)}):Play()
end)

frame.confirm.MouseButton1Down:Connect(function()
	tween_service:Create(frame.confirm, info, {BackgroundColor3 = Color3.fromRGB(58, 61, 62)}):Play()
end)

frame.confirm.InputEnded:Connect(function()
	tween_service:Create(frame.confirm, info, {BackgroundColor3 = Color3.fromRGB(85, 89, 91)}):Play()
end)