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
local clear = frame.clear
local refresh = frame.refresh

--// BACKPACK LIST

function adjust_color(hex, percent)
	local color = Color3.fromHex(hex)
	local hue, saturation, value = color:ToHSV()

	if value > .5 then
		value = value - percent
	else
		value = value + percent
	end

	local adjusted = Color3.fromHSV(hue, saturation, value)

	return adjusted
end

function increase_value(hex, sat, val)
	local color = Color3.fromHex(hex)
	local hue, saturation, value = color:ToHSV()

	value = value + val

	local adjusted = Color3.fromHSV(hue, saturation, value)

	return adjusted
end

function add(tool:Tool)
	if #tool:GetTags() == 0 then
		local template = frame.scroll.list.tool:Clone()

		template.Name = tool.Name
		template.Parent = frame.scroll
		template.Size = UDim2.new(0, 0, 0, 60)

		template.properties.tool.Value = tool

		template.texture.Image = tool.TextureId
		template.tool_name.Text = tool.Name

		if tool.TextureId == "" then
			template.texture.Image = "rbxassetid://14189176316"
		else
			template.texture.Image = tool.TextureId
		end

		--

		tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()

		--

		for i, quick in pairs(template.actions:GetChildren()) do
			if quick:IsA("ImageButton") then
				tween_service:Create(quick.gradient, loop, {Rotation = 360}):Play()
			end
		end
	else
		local template = frame.scroll.list.badged_tool:Clone()

		template.Name = tool.Name
		template.Parent = frame.scroll
		template.Size = UDim2.new(0, 0, 0, 60)

		template.properties.tool.Value = tool

		template.tool_name.Text = tool.Name

		if tool.TextureId == "" then
			template.texture.Image = "rbxassetid://14189176316"
		else
			template.texture.Image = tool.TextureId
		end

		--

		for i, tags in pairs(tool:GetTags()) do
			local badge = string.split(tags, ";")
			local text = template.badges.list.badge:Clone()
			
			if badge[1] == "exe" then
				text.Name = badge[2]
				text.Text = badge[2]
				text.BackgroundColor3 = adjust_color(badge[3], .4)
				text.TextColor3 = increase_value(badge[3], .1, .3)
				text.LayoutOrder = tonumber(badge[4]) or 1
				text.Parent = template.badges
			end
		end

		--

		tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()
	end

	--

	players[background.properties.username.Value].Backpack.ChildRemoved:Connect(function(child)
		if tool == child then
			remove(tool)
		end
	end)
end

function remove(tool:Tool)
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			if items.properties.tool.Value == tool then
				items:Destroy()
			end
		end
	end
end

function fetch_tools(player)
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

			items:Destroy()
		end
	end

	for i, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			add(tool)
		end
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.actions.delete.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(background.properties.id.Value)

				banit_events.delete_tool:FireServer(background.properties.username.Value, items.properties.tool.Value)

			end)

			--

			for i, quick in pairs(items.actions:GetChildren()) do
				if quick:IsA("ImageButton") then

					quick.MouseEnter:Connect(function()
						quick.gradient.Enabled = true

						tween_service:Create(quick, info, {BackgroundTransparency = .2}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = 1.2}):Play()
					end)

					quick.MouseButton1Down:Connect(function()
						tween_service:Create(quick, info, {BackgroundTransparency = .4}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = .8}):Play()
					end)

					quick.InputEnded:Connect(function()
						quick.gradient.Enabled = false

						tween_service:Create(quick, info, {BackgroundTransparency = 0}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = 1}):Play()
					end)

				end
			end

		end
	end
end

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and background.page.CurrentPage == frame) then
		local player = players:GetPlayerByUserId(background.properties.id.Value)

		exe_module:prompt_resync(true, "Fetching...", "assets")

		--

		task.wait(.5)

		--

		fetch_tools(player)
		run()

		--

		task.wait(Random.new():NextNumber(.5, 1))

		--

		exe_module:prompt_resync(false)
	end
end)

--

frame.scroll.list.Changed:Connect(function()
	if frame.scroll.list.AbsoluteContentSize.Y <= 0 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
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

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:assets_panels("tools", false)
end)

--// HOVER

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(clear.gradient, loop, {Rotation = 360}):Play()
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
	exe_module:assets_panels("tools", false)
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
	local player = players:GetPlayerByUserId(background.properties.id.Value)

	exe_module:prompt_resync(true, "Fetching...")

	--

	task.wait(.5)

	--

	fetch_tools(player)
	run()

	--

	task.wait(Random.new():NextNumber(.5, 1))

	exe_module:prompt_resync(false)
end)

--

clear.MouseEnter:Connect(function()
	clear.gradient.Enabled = true

	tween_service:Create(clear.icon.scale, info, {Scale = 1.2}):Play()
end)

clear.MouseButton1Down:Connect(function()
	tween_service:Create(clear.icon.scale, info, {Scale = .8}):Play()
end)

clear.InputEnded:Connect(function()
	clear.gradient.Enabled = false

	tween_service:Create(clear.icon.scale, info, {Scale = 1}):Play()
end)

clear.MouseButton1Click:Connect(function()
	banit_events.clear_tools:FireServer(background.properties.username.Value)
	
	exe_module:assets_panels("tools", false)
end)