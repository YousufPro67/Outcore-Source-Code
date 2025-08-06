local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(1, Enum.EasingStyle.Exponential)

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Name = "exe_admin_extra_blur"
blur.Parent = lighting

local exe_storage = replicated_storage.exe_storage
local transparency_module = require(exe_storage.transparency_module)

local module = {}

function module:notify(text, duration, icon, player)
	if run_service:IsClient() then
		local local_player = players.LocalPlayer

		local exe = local_player.PlayerGui:WaitForChild("exe")
		local notification = exe.notification

		--

		local item = notification:Clone()

		item.Position = UDim2.new(.5, 0, -2, 0)
		item.Visible = true
		item.description.Text = text
		item:SetAttribute("duration", duration)

		if icon then
			item.icon.Image = icon
		else
			item.icon.Visible = false
			item.description.Position = UDim2.fromOffset(0, 0)
		end

		--

		item.Parent = exe.storage

		--

		tween_service:Create(item, info, {Position = UDim2.new(.5, 0, 0, 30)}):Play()
	elseif run_service:IsServer() then
		script.notify:FireClient(player, text, duration, icon)
	end
end

function module:announce(announcer, text, icon, duration, fullscreen)
	print(fullscreen)

	local local_player = players.LocalPlayer
	local profile = players:GetUserThumbnailAsync(announcer, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	local exe = local_player.PlayerGui:WaitForChild("exe")
	local announcement = exe.announcement

	--

	announcement.Visible = true

	announcement.container.padding.PaddingTop = UDim.new(2, 0)

	announcement.container.label.Text = text
	announcement.container.label.gradient.Offset = Vector2.new(-1, 0)

	announcement.container.announcer.player.profile.Image = profile
	announcement.container.announcer.player.username.Text = "@" .. players:GetNameFromUserIdAsync(announcer)

	announcement.container.announcer.icon.Image = icon

	if fullscreen == 1 then
		announcement.BackgroundTransparency = 1
		announcement.AnchorPoint = Vector2.new(.5, .5)
		announcement.Position = UDim2.fromScale(.5, .5)
		announcement.Size = UDim2.fromScale(2, 1)

		announcement.gradient.Enabled = false

		announcement.container.BackgroundTransparency = 1
		announcement.container.ImageTransparency = 1

		--

		tween_service:Create(announcement, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(announcement.container, info, {BackgroundTransparency = .8, ImageTransparency = 0}):Play()
		tween_service:Create(blur, info, {Size = 20}):Play()
	else
		announcement.BackgroundTransparency = 1
		announcement.AnchorPoint = Vector2.new(.5, 0)
		announcement.Position = UDim2.fromScale(.5, 0)
		announcement.Size = UDim2.new(2, 0, 0, 200)

		announcement.gradient.Enabled = true

		announcement.container.BackgroundTransparency = 1
		announcement.container.ImageTransparency = 1

		--

		tween_service:Create(announcement, info, {BackgroundTransparency = .2}):Play()
		tween_service:Create(announcement.container, info, {BackgroundTransparency = 1, ImageTransparency = 1}):Play()
	end

	--

	tween_service:Create(announcement.container.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()

	--
	task.wait(.5)
	--

	tween_service:Create(announcement.container.label.gradient, info, {Offset = Vector2.new(1, 0)}):Play()

	--
	task.wait(duration)
	--

	tween_service:Create(announcement.container.label.gradient, info, {Offset = Vector2.new(-1, 0)}):Play()

	--
	task.wait(.5)
	--

	tween_service:Create(announcement, info, {BackgroundTransparency = 1}):Play()

	tween_service:Create(announcement.container, info, {BackgroundTransparency = 1, ImageTransparency = 1}):Play()
	tween_service:Create(announcement.container.padding, info, {PaddingTop = UDim.new(2, 0)}):Play()
	tween_service:Create(blur, info, {Size = 0}):Play()

	--
	task.wait(1)
	--

	announcement.Visible = false
end

return module