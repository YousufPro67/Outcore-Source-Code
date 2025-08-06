local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local late = TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local rev = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local banit_events = exe_storage.events.banit_events

local frame = script.Parent
local background = frame.Parent

local properties = background.properties

local pages = frame.pages

local MAX_DISPLAY_REASON = 400
local MAX_PRIVATE_REASON = 1000

local db = false

function truncate(text, max)
	if string.len(text) > max then
		return text:sub(1, max)
	else
		return text
	end
end

function sentence(s)
	return string.sub(s, 0, 1):upper() .. string.sub(s, 2, #s):lower()
end

--//BAN PAGE

pages.ban_page.confirm.MouseButton1Click:Connect(function()
	if not db then
		db = true

		exe_module:prompt_confirmation(true, "ban",
			"Banning @" .. properties.username.Value .. "?",
			"Banning this player will make them unable to join this game."
		)

		--

		task.wait(1)

		--

		db = false
	end
end)

exe_storage.events.confirmation_events.confirmation_closed.Event:Connect(function(confirmed, id)
	if confirmed and id == "ban" then
		
		local PR = pages.ban_page.scroll.reason.container.textbox.Text

		if pages.ban_page.scroll.moderator_note.textbox.Text ~= "" then
			PR = pages.ban_page.scroll.moderator_note.textbox.Text
		end

		local data = {
			["USERNAME"] = properties.username.Value;
			["ID"] = id;

			["DISPLAY_REASON"] = pages.ban_page.scroll.reason.container.textbox.Text;
			["PRIVATE_REASON"] = PR;

			["DURATION"] = math.round(properties.ban_length.Value);

			["EXCLUDE_ALT"] = not properties.alt_inclusion.Value;
			["UNIVERSE"] = true;
		}
		
		if properties.ban_type.Value == "permanent" then

			banit_events.ban:FireServer(data)

		elseif properties.ban_type.Value == "server" then

			banit_events.server_ban:FireServer(properties.username.Value, pages.ban_page.scroll.reason.container.textbox.Text)
		else

			banit_events.timed_ban:FireServer(data)

		end

		exe_module:direct_panels("ban", false)
	end
end)

pages.ban_page.scroll.settings.MouseButton1Click:Connect(function()
	pages.page:JumpTo(pages.settings_page)

	pages.settings_page.blurred.ImageTransparency = .015
	pages.settings_page.scroll.CanvasPosition = Vector2.new(0, 0)

	tween_service:Create(pages.settings_page.blurred, late, {ImageTransparency = 1}):Play()
end)

pages.ban_page.scroll.reason.container.textbox.Focused:Connect(function()
	tween_service:Create(pages.ban_page.scroll.reason, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

pages.ban_page.scroll.reason.container.textbox.FocusLost:Connect(function()
	tween_service:Create(pages.ban_page.scroll.reason, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
	
	--
	
	local text = pages.ban_page.scroll.reason.container.textbox.Text
	
	if string.len(text) > MAX_DISPLAY_REASON then
		
		pages.ban_page.scroll.reason.container.textbox.Text = truncate(text, MAX_DISPLAY_REASON)
		
		exe_module:notify("Your reason was truncated because it was more than 400 characters.", 4)
	end
end)

pages.ban_page.scroll.moderator_note.textbox.Focused:Connect(function()
	tween_service:Create(pages.ban_page.scroll.moderator_note, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

pages.ban_page.scroll.moderator_note.textbox.FocusLost:Connect(function()
	tween_service:Create(pages.ban_page.scroll.moderator_note, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()

	--

	local text = pages.ban_page.scroll.moderator_note.textbox.Text

	if string.len(text) > MAX_PRIVATE_REASON then

		pages.ban_page.scroll.moderator_note.textbox.Text = truncate(text, MAX_PRIVATE_REASON)

		exe_module:notify("Your moderator note was truncated because it was more than 1,000 characters.", 4)
	end
end)

pages.ban_page.scroll.manage.MouseButton1Click:Connect(function()
	exe_module:tools_panels("manage", true)
end)

--//BAN SETTINGS PAGE

pages.settings_page.scroll.options.alt_inclusion.MouseButton1Click:Connect(function()
	properties.alt_inclusion.Value = not properties.alt_inclusion.Value
	pages.settings_page.scroll.options.alt_inclusion.check.Visible = properties.alt_inclusion.Value
	
	--
	
	frame.pages.ban_page.scroll.settings.preview.alt_inclusion.Text = (properties.alt_inclusion.Value and "Included" or "Not Included")
end)

pages.settings_page.scroll.length.textbox.Focused:Connect(function()
	tween_service:Create(pages.settings_page.scroll.length, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

function set_and_run()
	local extract = tonumber(pages.settings_page.scroll.length.textbox.Text)

	if extract and extract > 0 then
		local num = math.round(extract)

		if num < 1 then

			properties.ban_length.Value = 5
			pages.settings_page.scroll.length.textbox.Text = 5

			--

			tween_service:Create(pages.settings_page.scroll.length, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = .7}):Play()

			return
		end

		if properties.ban_type.Value == "days" then
			properties.ban_length.Value = num * 86400
			pages.settings_page.scroll.length.textbox.Text = num

		elseif properties.ban_type.Value == "hours" then
			properties.ban_length.Value = num * 3600
			pages.settings_page.scroll.length.textbox.Text = num

		elseif properties.ban_type.Value == "minutes" then
			properties.ban_length.Value = num * 60
			pages.settings_page.scroll.length.textbox.Text = num
		end
	else
		properties.ban_length.Value = 5
		pages.settings_page.scroll.length.textbox.Text = 5
	end

	if properties.ban_type.Value == "permanent" then
		frame.pages.ban_page.scroll.settings.preview.duration.Text = "Permanent"
	else
		frame.pages.ban_page.scroll.settings.preview.duration.Text = pages.settings_page.scroll.length.textbox.Text .. " " .. sentence(properties.ban_type.Value)
	end

	--

	tween_service:Create(pages.settings_page.scroll.length, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end

pages.settings_page.scroll.length.textbox.FocusLost:Connect(set_and_run)
properties.ban_type.Changed:Connect(set_and_run)

for i, ban_type in pairs(pages.settings_page.scroll.ban_type:GetChildren()) do
	if ban_type:IsA("ImageButton") then

		ban_type.MouseButton1Click:Connect(function()
			properties.ban_type.Value = ban_type.label.Text:lower()
		end)

		ban_type.MouseEnter:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(53, 53, 53)}):Play()
		end)

		ban_type.MouseButton1Down:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(33, 33, 33)}):Play()
		end)

		ban_type.InputEnded:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		end)

		properties.ban_type.Changed:Connect(function(value)
			if ban_type.label.Text:lower() == value then
				ban_type.check.ImageTransparency = 1

				tween_service:Create(ban_type.check, info, {ImageTransparency = .2}):Play()
				tween_service:Create(ban_type.check.scale, info, {Scale = 1}):Play()
			else
				tween_service:Create(ban_type.check, info, {ImageTransparency = 1}):Play()
				tween_service:Create(ban_type.check.scale, info, {Scale = 0}):Play()
			end

			if (value == "permanent" or value == "server") then
				pages.settings_page.scroll.length.Visible = false
			else
				pages.settings_page.scroll.length.Visible = true
			end
		end)

	end
end

for i, ban_type in pairs(pages.settings_page.scroll.options:GetChildren()) do
	if ban_type:IsA("ImageButton") then
		
		ban_type.MouseEnter:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(53, 53, 53)}):Play()
		end)

		ban_type.MouseButton1Down:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(33, 33, 33)}):Play()
		end)

		ban_type.InputEnded:Connect(function()
			tween_service:Create(ban_type, info, {ImageColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		end)

	end
end

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	if pages.page.CurrentPage == pages.ban_page then
		exe_module:direct_panels("ban", false)
	else
		pages.page:JumpTo(pages.ban_page)

		pages.ban_page.blurred.ImageTransparency = .015
		pages.ban_page.scroll.CanvasPosition = Vector2.new(0, 0)

		tween_service:Create(pages.ban_page.blurred, late, {ImageTransparency = 1}):Play()
	end
end)

--// HOVER

tween_service:Create(pages.ban_page.close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(pages.settings_page.back.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(pages.ban_page.scroll.reason.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()
tween_service:Create(pages.settings_page.scroll.length.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

--//CLOSE

pages.ban_page.close.MouseEnter:Connect(function()
	pages.ban_page.close.gradient.Enabled = true

	tween_service:Create(pages.ban_page.close.icon.scale, info, {Scale = 1.2}):Play()
end)

pages.ban_page.close.MouseButton1Down:Connect(function()
	tween_service:Create(pages.ban_page.close.icon.scale, info, {Scale = .8}):Play()
end)

pages.ban_page.close.InputEnded:Connect(function()
	pages.ban_page.close.gradient.Enabled = false

	tween_service:Create(pages.ban_page.close.icon.scale, info, {Scale = 1}):Play()
end)

pages.ban_page.close.MouseButton1Click:Connect(function()
	exe_module:direct_panels("ban", false)
end)

--//BACK

pages.settings_page.back.MouseEnter:Connect(function()
	pages.settings_page.back.gradient.Enabled = true

	tween_service:Create(pages.settings_page.back.icon.scale, info, {Scale = 1.2}):Play()
end)

pages.settings_page.back.MouseButton1Down:Connect(function()
	tween_service:Create(pages.settings_page.back.icon.scale, info, {Scale = .8}):Play()
end)

pages.settings_page.back.InputEnded:Connect(function()
	pages.settings_page.back.gradient.Enabled = false

	tween_service:Create(pages.settings_page.back.icon.scale, info, {Scale = 1}):Play()
end)

pages.settings_page.back.MouseButton1Click:Connect(function()
	pages.page:JumpTo(pages.ban_page)

	pages.ban_page.blurred.ImageTransparency = .015
	pages.ban_page.scroll.CanvasPosition = Vector2.new(0, 0)

	tween_service:Create(pages.ban_page.blurred, late, {ImageTransparency = 1}):Play()
end)

--

pages.ban_page.confirm.MouseEnter:Connect(function()
	tween_service:Create(pages.ban_page.confirm, info, {BackgroundColor3 = Color3.fromRGB(149, 156, 159)}):Play()
end)

pages.ban_page.confirm.MouseButton1Down:Connect(function()
	tween_service:Create(pages.ban_page.confirm, info, {BackgroundColor3 = Color3.fromRGB(69, 73, 74)}):Play()
end)

pages.ban_page.confirm.InputEnded:Connect(function()
	tween_service:Create(pages.ban_page.confirm, info, {BackgroundColor3 = Color3.fromRGB(108, 113, 115)}):Play()
end)