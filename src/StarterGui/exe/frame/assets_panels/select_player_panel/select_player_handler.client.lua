local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local background = frame.Parent

local search = frame.scroll.search

local close = frame.close
local refresh = frame.refresh

function add(player)
	local template = frame.scroll.list.player:Clone()
	local profile = players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	template.Name = player.Name
	template.Parent = frame.scroll
	template.Size = UDim2.new(0, 0, 0, 60)

	template.profile.Image = profile
	template.details.username.Text = "@" .. player.Name

	if player == players.LocalPlayer then
		template.details.display_name.Text = player.DisplayName .. " (You)"
		template.LayoutOrder = 1
	else
		template.details.display_name.Text = player.DisplayName
		template.LayoutOrder = 2
	end

	--

	tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()
end

function remove(player)
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			if items.Name == player.Name then
				tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

				--

				task.wait(.3)

				--

				items:Destroy()
			end
		end
	end
end

function initialize()
	for i, dump in pairs(frame.scroll:GetChildren()) do
		if dump:IsA("ImageButton") then
			dump:Destroy()
		end
	end

	--

	for i, player in pairs(players:GetPlayers()) do
		add(player)
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.MouseEnter:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(98, 98, 99)}):Play()
			end)

			items.MouseButton1Down:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(66, 66, 67)}):Play()
			end)

			items.InputEnded:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(88, 88, 89)}):Play()
			end)

			items.MouseButton1Click:Connect(function()
				events.confirmation_events.selected_player:Fire(items.Name, items.profile.Image,
					background.properties.object_reference.Value)

				exe_module:assets_panels("players_selection", false)
			end)

		end
	end
end

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and background.page.CurrentPage == frame) then
		exe_module:prompt_resync(true, "Fetching...", "assets")

		--

		task.wait(.5)

		--

		initialize()
		run()

		--

		task.wait(Random.new():NextNumber(.5, 1))

		--

		exe_module:prompt_resync(false)
	end
end)

function results()
	local term = string.lower(search.textbox.Text)

	for i, v in pairs(frame.scroll:GetChildren()) do
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
				v.LayoutOrder = 1

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

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:assets_panels("players_selection", false)
end)

--// HOVER

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(refresh.gradient, loop, {Rotation = 360}):Play()

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
	exe_module:assets_panels("players_selection", false)
end)

--

refresh.MouseEnter:Connect(function()
	refresh.gradient.Enabled = true

	tween_service:Create(refresh.icon.scale, info, {Scale = 1.2}):Play()
end)

refresh.MouseButton1Down:Connect(function()
	tween_service:Create(refresh.icon.scale, info, {Scale = .8}):Play()
end)

refresh.InputEnded:Connect(function()
	refresh.gradient.Enabled = false

	tween_service:Create(refresh.icon.scale, info, {Scale = 1}):Play()
end)

refresh.MouseButton1Click:Connect(function()
	exe_module:prompt_resync(true, "Refreshing...")

	--

	task.wait(.5)

	--

	initialize()
	run()

	--

	task.wait(Random.new():NextNumber(.5, 1))

	--

	exe_module:prompt_resync(false)
end)