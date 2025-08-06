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
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local background = frame.Parent

local search = frame.scroll.search
local close = frame.close

local db = false
local throttle = false
local clicking = false
local opened = 0

function format_time(seconds)
	if seconds then
		local days = math.floor(seconds / (60 * 60 * 24))
		local hours = math.floor(seconds / (60 * 60)) % 24
		local minutes = math.floor(seconds / 60) % 60

		local time_string = ""
		if days > 0 then
			time_string = time_string .. days .. "d "
		end
		if hours > 0 then
			time_string = time_string .. hours .. "h "
		end
		if minutes > 0 then
			time_string = time_string .. minutes .. "m"
		end

		return time_string
	else
		return nil
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.actions.revoke.MouseButton1Click:Connect(function()
				if not clicking then
					clicking = true

					exe_module:prompt_resync(true, "Revoking...")
					banit_events.unban:FireServer(items.properties.username.Value, items.properties.info.Value)

					--
					task.wait(.5)
					--

					sync()

					--
					task.wait(2)
					--

					exe_module:prompt_resync(false)

					clicking = false
				end
			end)
			
			items.actions.history.MouseButton1Click:Connect(function()
				if not clicking then
					clicking = true

					exe_module:assets_panels("ban_history", true, {["ID"] = items.properties.id.Value, ["USERNAME"] = items.properties.username.Value})

					clicking = false
				end
			end)

			--

			for i, quick in pairs(items.actions:GetChildren()) do
				if quick:IsA("ImageButton") then

					quick.MouseEnter:Connect(function()
						tween_service:Create(quick, info, {BackgroundColor3 = Color3.fromRGB(136, 136, 136)}):Play()
					end)

					quick.MouseButton1Down:Connect(function()
						tween_service:Create(quick, info, {BackgroundColor3 = Color3.fromRGB(81, 81, 81)}):Play()
					end)

					quick.InputEnded:Connect(function()
						tween_service:Create(quick, info, {BackgroundColor3 = Color3.fromRGB(106, 106, 106)}):Play()
					end)

				end
			end

		end
	end
end

function sync()
	if not throttle then
		throttle = true

		--

		for i, items in pairs (frame.scroll:GetChildren()) do
			if items:IsA("ImageButton") or items:IsA("ImageLabel") then
				items:Destroy()
			end
		end
		
		local perm, exp = events.get_bans:InvokeServer()

		for i, id in pairs(perm) do
			id = tonumber(id)
			
			local username = players:GetNameFromUserIdAsync(id)
			local profile = players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			
			local item = frame.scroll.list.minimized:Clone()

			item.LayoutOrder = 1

			item.properties.id.Value = id
			item.properties.order.Value = 1
			item.properties.username.Value = username
			
			item.username.Text = "@" .. username

			item.profile.Image = profile

			item.Name = username
			item.Parent = frame.scroll
		end
		
		for i, code in pairs(exp) do
			local parts = string.split(code, ";")
			local id = tonumber(parts[1])
			
			if id then
				local username = players:GetNameFromUserIdAsync(id)
				local profile = players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

				local item = frame.scroll.list.minimized:Clone()

				item.LayoutOrder = 1

				item.properties.id.Value = id
				item.properties.order.Value = 1
				item.properties.username.Value = username

				item.username.Text = "@" .. username

				item.profile.Image = profile

				item.Name = username
				item.Parent = frame.scroll
			end
		end

		for i, ids in pairs(events.get_server_bans:InvokeServer()) do
			local name = players:GetNameFromUserIdAsync(ids)
			local profile = players:GetUserThumbnailAsync(ids, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			
			local item = frame.scroll.list.expanded:Clone()

			item.LayoutOrder = 2
			
			item.properties.id.Value = ids
			item.properties.info.Value = "Server Ban"
			item.properties.order.Value = 2
			item.properties.username.Value = name

			item.details.moderator.Visible = false
			item.details.info.Text = "Type: Server"
			item.details.reason.Visible = false
			item.details.username.Text = "@" .. name
			
			item.profile.Image = profile
			
			item.Name = name
			item.Parent = frame.scroll
		end

		--

		run()

		--
		task.wait(1)
		--

		throttle = false
	end
end

--

frame.resync.MouseButton1Click:Connect(function()
	exe_module:prompt_confirmation(true, "resync_request", "Resync?", 
		"Resyncing will make the list accurate and up to date however, this will take up to minutes depending on how many to load.")
end)

banit_events.Parent.confirmation_events.confirmation_closed.Event:Connect(function(confirmed, id)
	if confirmed and id == "resync_request" then
		if not db then
			db = true


			exe_module:prompt_resync(true)
			sync()

			--

			task.wait(Random.new():NextNumber(3, 4))

			--

			exe_module:prompt_resync(false)
			exe_module:notify("Syncing Finished, rejoin to sync thoroughly.", 5, "rbxassetid://11963357970")

			--

			db = false
		end
	end
end)

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if background.Visible then
		if (opened == 0 and background.page.CurrentPage == frame) then
			opened += 1

			exe_module:prompt_resync(true, "Initializing...", "manage")

			--

			task.wait(.5)

			--

			sync()

			--

			task.wait(Random.new():NextNumber(.5, 1))

			--

			exe_module:prompt_resync(false)
		end
	end
end)

frame.scroll.list.Changed:Connect(function()
	if frame.scroll.list.AbsoluteContentSize.Y <= 40 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	end
end)

--//SEARCHING

function results()
	local term = string.lower(search.textbox.Text)

	for i, v in pairs(frame.scroll:GetChildren()) do
		if v:IsA("ImageButton") then
			if term ~= "" then
				local item = string.lower(v.Name .. v.properties.id.Value)

				if string.find(item, term) then
					v.LayoutOrder = 2
				else
					v.LayoutOrder = 3
				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 1}):Play()
			else
				v.LayoutOrder = v.properties.order.Value

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 0}):Play()
			end
		end
	end
end

search.textbox.Changed:Connect(results)

search.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.search, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

search.textbox.FocusLost:Connect(function()
	tween_service:Create(frame.scroll.search, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end)

search.clear_button.MouseButton1Click:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
		search.textbox.Text = ""
		search.textbox:CaptureFocus()
	else
		search.textbox.Text = ""
	end
end)

search.clear_button.MouseEnter:Connect(function()
	if search.textbox.Text ~= "" then
		tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = .8}):Play()

		search.clear_button.background.gradient.Enabled = true
	end
end)

search.clear_button.InputEnded:Connect(function()
	tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = 1}):Play()

	search.clear_button.background.gradient.Enabled = false
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:tools_panels("manage", false)
end)

--// HOVER

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(search.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

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
	exe_module:tools_panels("manage", false)
end)

--

frame.resync.MouseEnter:Connect(function()
	tween_service:Create(frame.resync, info, {BackgroundColor3 = Color3.fromRGB(112, 117, 120)}):Play()
end)

frame.resync.MouseButton1Down:Connect(function()
	tween_service:Create(frame.resync, info, {BackgroundColor3 = Color3.fromRGB(58, 61, 62)}):Play()
end)

frame.resync.InputEnded:Connect(function()
	tween_service:Create(frame.resync, info, {BackgroundColor3 = Color3.fromRGB(85, 89, 91)}):Play()
end)