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
local configs = require(exe_storage.configuration)
local jails = configs:GET_CONFIGS().JAIL.JAIL_OPTIONS

local banit_events = exe_storage.events.banit_events

local frame = script.Parent
local background = frame.Parent

local properties = background.properties

local close = frame.close

local texture = {
	["top"] = {
		["id"] = "rbxassetid://16287196357";
		["scale"] = .12;
		["slice"] = Rect.new(512, 214, 512, 214)
	};
	
	["middle"] = {
		["id"] = "rbxassetid://16286719854";
		["scale"] = .001;
		["slice"] = Rect.new(512, 601, 512, 601)
	};
	
	["bottom"] = {
		["id"] = "rbxassetid://16287194510";
		["scale"] = .12;
		["slice"] = Rect.new(512, 0, 512, 0)
	};
}

local db = false

frame.confirm.MouseButton1Click:Connect(function()
	if not db then
		local recipient = players:GetPlayerByUserId(properties.id.Value)

		db = true

		banit_events.jail:FireServer(properties.jail_duration.Value, properties.id.Value, jails[properties.jail_type.Value])

		exe_module:direct_panels("jail", false)

		--

		db = false
	end
end)

--

frame.scroll.duration.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.duration, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

frame.scroll.duration.textbox.FocusLost:Connect(function()
	local num = tonumber(frame.scroll.duration.textbox.Text)

	if num and (num > 0 and num <= configs:GET_CONFIGS().JAIL.duration_limit) then
		properties.jail_duration.Value = num

		if num <= 1 then
			frame.scroll.duration.textbox.Text = num .. " second"
		else
			frame.scroll.duration.textbox.Text = num .. " seconds"
		end
	else
		if num then
			if num then
				properties.jail_duration.Value = 5

				frame.scroll.duration.textbox.Text = "5 seconds"
				
				exe_module:notify("Exceeds the minimum and maximum value.", 3, "rbxassetid://14187764914")
			else
				properties.jail_duration.Value = 5

				frame.scroll.duration.textbox.Text = "5 seconds"
				
				exe_module:notify("Failed to apply.", 3, "rbxassetid://14187764914")
			end
		end
	end

	tween_service:Create(frame.scroll.duration, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end)

--

local logged = 0
local count = 0

for _, _ in pairs(jails) do
	count = count + 1
end

for name, params in pairs(jails) do
	local item = frame.scroll.jail_type.list.template:Clone()
	
	logged += 1
	
	item.Name = name
	item.label.Text = name
	
	if logged == 1 then
		item.check.ImageTransparency = .2
		item.check.scale.Scale = 1
		
		item.Image = texture.top.id
		item.SliceScale = texture.top.scale
		item.SliceCenter = texture.top.slice
		
		properties.jail_type.Value = name
		
	elseif logged == count then
		item.check.ImageTransparency = 1
		item.check.scale.Scale = 0

		item.Image = texture.bottom.id
		item.SliceScale = texture.bottom.scale
		item.SliceCenter = texture.bottom.slice
		
	else
		item.check.ImageTransparency = 1
		item.check.scale.Scale = 0

		item.Image = texture.middle.id
		item.SliceScale = texture.middle.scale
		item.SliceCenter = texture.middle.slice
	end
	
	item.Parent = frame.scroll.jail_type
end

for i, jail_type in pairs(frame.scroll.jail_type:GetChildren()) do
	if jail_type:IsA("ImageButton") then

		jail_type.MouseButton1Click:Connect(function()
			properties.jail_type.Value = jail_type.Name
		end)

		jail_type.MouseEnter:Connect(function()
			tween_service:Create(jail_type, info, {ImageColor3 = Color3.fromRGB(53, 53, 53)}):Play()
		end)

		jail_type.MouseButton1Down:Connect(function()
			tween_service:Create(jail_type, info, {ImageColor3 = Color3.fromRGB(33, 33, 33)}):Play()
		end)

		jail_type.InputEnded:Connect(function()
			tween_service:Create(jail_type, info, {ImageColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		end)

		--

		properties.jail_type.Changed:Connect(function(value)
			if jail_type.Name == value then
				jail_type.check.ImageTransparency = 1

				tween_service:Create(jail_type.check, info, {ImageTransparency = .2}):Play()
				tween_service:Create(jail_type.check.scale, info, {Scale = 1}):Play()
			else
				tween_service:Create(jail_type.check, info, {ImageTransparency = 1}):Play()
				tween_service:Create(jail_type.check.scale, info, {Scale = 0}):Play()
			end
		end)

	end
end

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("jail", false)
end)

--// HOVER

tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
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
	exe_module:direct_panels("jail", false)
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