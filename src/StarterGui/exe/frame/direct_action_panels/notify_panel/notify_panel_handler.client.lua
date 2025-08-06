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
local filter_module = require(exe_storage.filter_module)
local configs = require(exe_storage.configuration):GET_CONFIGS()

local banit_events = exe_storage.events.banit_events

local frame = script.Parent
local background = frame.Parent

local properties = background.properties

local close = frame.close

local db = false
local filtering = false

frame.confirm.MouseButton1Click:Connect(function()
	if frame.scroll.description.container.textbox.Text == "" then
		exe_module:notify("No input typed.", 3, "rbxassetid://12967502115")
	else
		if not db and not filtering then
			local recipient = players:GetPlayerByUserId(properties.id.Value)

			db = true

			banit_events.notify:FireServer(recipient,
				frame.scroll.description.container.textbox.Text, properties.notification_duration.Value,
				properties.notification_icon.Value)

			exe_module:direct_panels("notify", false)

			--

			task.wait(1)

			--

			db = false
		end
	end
end)

frame.scroll.description.container.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.description, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

frame.scroll.description.container.textbox.FocusLost:Connect(function()
	tween_service:Create(frame.scroll.description, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
	
	--
	
	if configs.NOTIFY.filter_string and frame.scroll.description.container.textbox.Text ~= "" then
		filtering = true

		tween_service:Create(frame.scroll.description.filtering, info, {Position = UDim2.fromScale(.5, 1)}):Play()

		--

		frame.scroll.description.container.textbox.Text = filter_module:filter_string(
			frame.scroll.description.container.textbox.Text, players.LocalPlayer)

		--
		task.wait(.5)
		--

		filtering = false

		tween_service:Create(frame.scroll.description.filtering, info, {Position = UDim2.fromScale(.5, 3)}):Play()
	end
end)

--

frame.scroll.duration.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.duration, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

frame.scroll.duration.textbox.FocusLost:Connect(function()
	local limit = configs.NOTIFY.duration_limit
	local num = tonumber(frame.scroll.duration.textbox.Text)

	if num and (num > 0 and num <= limit) then
		properties.notification_duration.Value = num

		if num <= 1 then
			frame.scroll.duration.textbox.Text = num .. " second"
		else
			frame.scroll.duration.textbox.Text = num .. " seconds"
		end
	else
		properties.notification_duration.Value = 5

		frame.scroll.duration.textbox.Text = "5 seconds"
		
		if num and num > limit then
			exe_module:notify("The limit is " .. limit .. ".", 3, "rbxassetid://12967713729")
		end
	end

	tween_service:Create(frame.scroll.duration, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end)

--

for i, icon in pairs(frame.scroll.icons.sets:GetChildren()) do
	if icon:IsA("ImageButton") then

		tween_service:Create(icon.gradient, loop, {Rotation = 360}):Play()

		icon.MouseButton1Click:Connect(function()
			properties.notification_icon.Value = icon.icon.Image
		end)

		icon.MouseEnter:Connect(function()
			icon.gradient.Enabled = true

			tween_service:Create(icon.icon.scale, info, {Scale = 1.5}):Play()
		end)

		icon.MouseButton1Down:Connect(function()
			tween_service:Create(icon.icon.scale, info, {Scale = .6}):Play()
		end)

		icon.MouseButton2Down:Connect(function()
			tween_service:Create(icon.icon.scale, info, {Scale = 3}):Play()
		end)

		icon.InputEnded:Connect(function()
			icon.gradient.Enabled = false

			tween_service:Create(icon.icon.scale, info, {Scale = 1}):Play()
		end)

		--

		properties.notification_icon.Changed:Connect(function(value)
			if icon.icon.Image == value then
				tween_service:Create(icon, info, {BackgroundTransparency = .8}):Play()
			else
				tween_service:Create(icon, info, {BackgroundTransparency = .9}):Play()
			end
		end)

	end
end

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("notify", false)
end)

--// HOVER

tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(frame.scroll.description.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()
tween_service:Create(frame.scroll.duration.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

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
	exe_module:direct_panels("notify", false)
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