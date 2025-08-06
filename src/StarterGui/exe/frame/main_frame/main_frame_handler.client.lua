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
local main_module = require(script.Parent.Parent.Parent.exe_main_module)

local frame = script.Parent

local navi = frame.navigation_buttons
local search = frame.search
local scroll = frame.scroll

local allowed = true

--// PLAYERS LIST

function add(plr:Player)
	local template = scroll.list.player:Clone()

	template.Name = plr.Name
	template.Parent = scroll
	template.Size = UDim2.new(0, 0, 0, 60)

	template.properties.display.Value = plr.DisplayName
	template.properties.id.Value = plr.UserId
	template.properties.username.Value = plr.Name

	template.profile.Image = players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	template.details.username.Text = "@" .. plr.Name

	if plr.Name == players.LocalPlayer.Name then
		template.LayoutOrder = 1
		template.details.display_name.Text = plr.DisplayName .. " (You)"

		template.quick_actions.Visible = false
	else
		template.LayoutOrder = 2
		template.details.display_name.Text = plr.DisplayName
	end

	--

	tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()

	--

	for i, quick in pairs(template.quick_actions:GetChildren()) do
		if quick:IsA("ImageButton") then
			tween_service:Create(quick.gradient, loop, {Rotation = 360}):Play()
		end
	end
end

function remove(plr:Player)
	for i, items in pairs(scroll:GetChildren()) do
		if items.Name == plr.Name then
			items:Destroy()
		end
	end
end

function initialize()
	for i, items in pairs(scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

			--

			task.wait(.5)

			--

			items:Destroy()
		end
	end

	for i, plr in pairs(players:GetPlayers()) do
		add(plr)
	end
end

function run()
	for i, items in pairs(scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(items.properties.id.Value)

				exe_module:profile_view(true, plr)
			end)

			items.quick_actions.ban.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(items.properties.id.Value)

				exe_module:direct_panels("ban", true, plr)
			end)

			items.quick_actions.kick.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(items.properties.id.Value)

				exe_module:direct_panels("kick", true, plr)
			end)

			--

			items.MouseEnter:Connect(function()
				if allowed then
					tween_service:Create(items, info, {BackgroundTransparency = .9}):Play()
				end
			end)

			items.MouseButton1Down:Connect(function()
				tween_service:Create(items, info, {BackgroundTransparency = .95}):Play()
			end)

			items.InputEnded:Connect(function()
				tween_service:Create(items, info, {BackgroundTransparency = 1}):Play()
			end)

			--

			for i, quick in pairs(items.quick_actions:GetChildren()) do
				if quick:IsA("ImageButton") then

					quick.MouseEnter:Connect(function()
						if allowed then
							quick.gradient.Enabled = true

							tween_service:Create(quick, info, {BackgroundTransparency = .8}):Play()
							tween_service:Create(quick.icon.scale, info, {Scale = 1.2}):Play()
						end
					end)

					quick.MouseButton1Down:Connect(function()
						tween_service:Create(quick, info, {BackgroundTransparency = .95}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = .8}):Play()
					end)

					quick.InputEnded:Connect(function()
						quick.gradient.Enabled = false

						tween_service:Create(quick, info, {BackgroundTransparency = .9}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = 1}):Play()
					end)

				end
			end

		end
	end
end

players.PlayerAdded:Connect(add)
players.PlayerRemoving:Connect(remove)

scroll.ChildAdded:Connect(run)
scroll.ChildRemoved:Connect(run)

initialize()

--// SEARCHING

function results()
	local term = string.lower(search.textbox.Text)

	for i, v in pairs(scroll:GetChildren()) do
		if v:IsA("ImageButton") then
			if term ~= "" then
				local item = string.lower(v.Name)

				if string.find(item, term) then
					v.LayoutOrder = 1
				else
					v.LayoutOrder = 2
				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 1}):Play()
			else
				if v.Name == players.LocalPlayer.Name then
					v.LayoutOrder = 1
				else
					v.LayoutOrder = 2
				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 0}):Play()
			end
		end
	end

	if search.textbox:IsFocused() then
		tween_service:Create(search.icon, info, {ImageTransparency = Random.new():NextNumber(.3, .9)}):Play()
	else
		tween_service:Create(search.icon, info, {ImageTransparency = .5}):Play()
	end
end

search.textbox.Changed:Connect(results)

search.textbox.Focused:Connect(function()
	tween_service:Create(search, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0}):Play()
end)

search.textbox.FocusLost:Connect(function()
	tween_service:Create(search, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = .7}):Play()
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

--// GRADIENTS

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(search.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

--// NAVIGATION

navi.menu.MouseButton1Click:Connect(function()
	exe_module:menu(true)
end)

navi.close.MouseButton1Click:Connect(function()
	main_module:exe_admin_panel(false)
end)

navi.snapshot.MouseButton1Click:Connect(function()
	exe_module:direct_panels("snapshot", true)
end)

navi.refresh.MouseButton1Click:Connect(function()
	if navi.refresh.icon.Rotation == 0 then
		tween_service:Create(navi.refresh.icon, slow, {Rotation = 360}):Play()

		initialize()

		--

		task.wait(5)

		--

		navi.refresh.icon.Rotation = 0
	end
end)

--// NAVIGATION HOVERS

function hover()
	for i, button in pairs(navi:GetChildren()) do
		if button:IsA("ImageButton") then

			button.gradient.Rotation = 0

			tween_service:Create(button.gradient, loop, {Rotation = 360}):Play()

			button.MouseEnter:Connect(function()
				if allowed then
					button.gradient.Enabled = true

					tween_service:Create(button.icon.scale, info, {Scale = 1.2}):Play()
				end
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button.icon.scale, info, {Scale = .8}):Play()
			end)

			button.InputEnded:Connect(function()
				button.gradient.Enabled = false

				tween_service:Create(button.icon.scale, info, {Scale = 1}):Play()
			end)

		end
	end
end

hover()

frame.Parent.profile_panel.Changed:Connect(function()
	allowed = not frame.Parent.profile_panel.Visible
end)