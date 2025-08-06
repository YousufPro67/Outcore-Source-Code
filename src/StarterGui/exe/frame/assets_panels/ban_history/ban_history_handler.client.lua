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

local throttle = false

local function format_iso(iso)
	-- Adjust pattern to match optional fractional seconds
	local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.*(%d*)Z"
	local year, month, day, hour, min, sec, frac = iso:match(pattern)

	if not (year and month and day and hour and min and sec) then
		error("Invalid ISO 8601 format")
	end

	local utcTime = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec)
	})

	local localTime = os.date("*t", utcTime)

	local formattedTime = os.date("%B %d, %Y %I:%M:%S %p", utcTime)
	return formattedTime
end

function convert_seconds(seconds)
	local minutes = 60
	local hours = minutes * 60
	local days = hours * 24

	if seconds < minutes then
		return string.format("%d seconds", seconds)
	elseif seconds < hours then
		local mins = math.floor(seconds / minutes)
		return string.format("%d minutes", mins)
	elseif seconds < days then
		local hrs = math.floor(seconds / hours)
		return string.format("%d hours", hrs)
	else
		local dys = math.floor(seconds / days)
		return string.format("%d days", dys)
	end
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
end

local get_index = events.get_id_info

function run()
	exe_module:prompt_resync(true, "Fetching the Ban History...")
	
	local full_index: BanHistoryPages = get_index:InvokeServer(background.properties.id.Value)
	
	local success, error = pcall(function()
		
		for id, log in full_index do
			
			local case = frame.scroll.list.case:Clone()
			
			case.header.Text = format_iso(log.StartTime)
			case.action.Text = log.Ban and "Ban Applied" or "Ban Revoked"
			
			if log.DisplayReason == "" then
				case.display_reason.Text = "No reason provided."
			else
				case.display_reason.Text = log.DisplayReason
			end
			
			if log.PrivateReason == "" then
				case.private_reason.Text = "No moderator note provided."
			else
				case.private_reason.Text = log.PrivateReason
			end
			
			if log.Duration > 0 then
				case.duration.Text = convert_seconds(log.Duration)
			else
				case.duration.Text = "Permanent"
			end
			
			case.LayoutOrder = id
			case.Parent = frame.scroll
		end
		
	end)
	
	if success then
		exe_module:notify("Sucessfully loaded " .. background.properties.username.Value .. "'s Ban History.", 4)
		
		--
		task.wait(1)
		--

		exe_module.prompt_resync(false)
	else
		exe_module:notify("An error occurred while loading Ban History. Please try again.", 4)
		
		warn(error)

		--
		task.wait(1)
		--

		exe_module.prompt_resync(false)
	end
end

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and background.page.CurrentPage == frame) then
		initialize()
		run()
	end
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:assets_panels("ban_history", false)
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
	exe_module:assets_panels("ban_history", false)
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
	exe_module:prompt_resync(true, "Resyncing the Ban History...")

	--

	task.wait(.5)

	--

	initialize()
	run()
end)