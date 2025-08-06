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

local close = frame.close
local refresh = frame.refresh

--// PLAYER LIST

function add(plr:Player)
	local template = frame.player_list.list.player:Clone()

	template.Name = plr.Name
	template.Parent = frame.player_list
	template.Size = UDim2.new(0, 0, 0, 60)

	template.properties.id.Value = plr.UserId
	template.properties.username.Value = plr.Name

	template.profile.Image = players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	template.details.username.Text = "@" .. plr.Name

	if plr == players.LocalPlayer then
		template.LayoutOrder = 1
		template.details.display.Text = plr.DisplayName .. " (You)"
	else
		template.LayoutOrder = 2
		template.details.display.Text = plr.DisplayName
	end

	--

	tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()

	--

	for i, quick in pairs(template.actions:GetChildren()) do
		if quick:IsA("ImageButton") then
			tween_service:Create(quick.gradient, loop, {Rotation = 360}):Play()
		end
	end
end

function remove(plr:Player)
	for i, items in pairs(frame.player_list:GetChildren()) do
		if items.Name == plr.Name then
			tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

			--

			task.wait(.5)

			--

			items:Destroy()
		end
	end
end

function initialize()
	for i, items in pairs(frame.player_list:GetChildren()) do
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
	for i, items in pairs(frame.player_list:GetChildren()) do
		if items:IsA("ImageButton") then

			items.actions.clear.MouseButton1Click:Connect(function()
				events.banit_events.clear_tools:FireServer(items.properties.username.Value)
			end)

			items.actions.manage.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(items.properties.id.Value)

				exe_module:assets_panels("tools", true, plr)
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

players.PlayerAdded:Connect(add)
players.PlayerRemoving:Connect(remove)

frame.player_list.ChildAdded:Connect(run)
frame.player_list.ChildRemoved:Connect(run)

--// TOOL LIST

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

function fetch_tools()
	for i, tool in pairs(exe_storage.tools:GetChildren()) do
		add_tool(tool)
	end
end

function add_tool(tool:Tool)
	if #tool:GetTags() == 0 then
		local template = frame.tool_list.list.tool:Clone()

		template.Name = tool.Name
		template.Parent = frame.tool_list
		template.Size = UDim2.new(0, 0, 0, 60)

		template.properties.tool.Value = tool

		template.tool_name.Text = tool.Name

		if tool.TextureId == "" then
			template.texture.Image = "rbxassetid://14189176316"
		else
			template.texture.Image = tool.TextureId
		end

		--

		tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()
	else
		local template = frame.tool_list.list.badged_tool:Clone()

		template.Name = tool.Name
		template.Parent = frame.tool_list
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
end

local opened = 0

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if background.Visible then
		if (opened == 0 and background.page.CurrentPage == frame) then
			opened += 1

			exe_module:prompt_resync(true, "Initializing...", "tools_effects")

			--

			task.wait(.5)

			--

			fetch_tools()
			initialize()

			--

			task.wait(Random.new():NextNumber(.5, 1))

			--

			exe_module:prompt_resync(false)
		end
	end
end)

--

frame.tool_list.list.Changed:Connect(function()
	if frame.tool_list.list.AbsoluteContentSize.Y <= 0 then
		tween_service:Create(frame.empty_tools, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty_tools, info, {GroupTransparency = 1}):Play()
	end
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:tools_panels("tools", false)
end)

--// HOVER

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
	exe_module:tools_panels("tools", false)
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

	--

	task.wait(Random.new():NextNumber(.5, 1))

	--

	exe_module:prompt_resync(false)
end)