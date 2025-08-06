local tween_service = game:GetService("TweenService")
local player_service = game:GetService("Players")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")

local exe_storage = replicated_storage:WaitForChild("exe_storage")

local info = TweenInfo.new(.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local slow = TweenInfo.new(.8, Enum.EasingStyle.Exponential)

local local_player = player_service.LocalPlayer

local exe = script.Parent
local frame = exe.frame

local accessibility_button = exe.accessibility_button
local options = accessibility_button.button.page.options

local blur = lighting:WaitForChild("exe_admin_panel_blur")

local exe_module = require(exe_storage.exe_module)

--

local module = {}

function module:exe_admin_panel(state)
	if state then
		if not frame.Visible then
			exe.storage.opened.Value = true

			frame.Visible = true
			frame.BackgroundTransparency = 1
			frame.ImageTransparency = 1

			frame.scale.Scale = 1.2

			frame.dashboard_frame.GroupTransparency = 1
			frame.main_frame.GroupTransparency = 1
			frame.window_controls.GroupTransparency = 1

			--

			tween_service:Create(frame, info, {BackgroundTransparency = .1, ImageTransparency = .8}):Play()

			tween_service:Create(frame.dashboard_frame, info, {GroupTransparency = 0}):Play()
			tween_service:Create(frame.main_frame, info, {GroupTransparency = 0}):Play()
			tween_service:Create(frame.credits_frame, info, {GroupTransparency = 0}):Play()

			tween_service:Create(frame.window_controls, info, {GroupTransparency = 0}):Play()

			tween_service:Create(blur, info, {Size = 40}):Play()

			if exe.storage.fullscreen.Value then
				tween_service:Create(frame.scale, info, {Scale = 1}):Play()
			else
				tween_service:Create(frame.shadow, info, {ImageTransparency = 0}):Play()
				tween_service:Create(frame.scale, info, {Scale = exe.storage.scale_on_window.Value}):Play()
			end
		end
	else
		exe.storage.opened.Value = false

		tween_service:Create(frame, info, {BackgroundTransparency = 1, ImageTransparency = 1}):Play()

		tween_service:Create(frame.dashboard_frame, info, {GroupTransparency = 1}):Play()
		tween_service:Create(frame.main_frame, info, {GroupTransparency = 1}):Play()
		tween_service:Create(frame.credits_frame, info, {GroupTransparency = 1}):Play()

		tween_service:Create(frame.shadow, info, {ImageTransparency = 1}):Play()

		tween_service:Create(frame.window_controls, info, {GroupTransparency = 1}):Play()

		tween_service:Create(blur, info, {Size = 0}):Play()

		tween_service:Create(frame.scale, info, {Scale = 1.2}):Play()

		--

		task.wait(.5)

		--

		frame.Visible = false
	end
end

local main_frame = exe.frame

type pages = "Players" | "Dashboard" | "Credits"

function module:Go_To(page:pages)
	if page == "Players" then
		main_frame.ClipsDescendants = true

		main_frame.credits_frame.Visible = false
		main_frame.dashboard_frame.Visible = false
		main_frame.main_frame.Visible = true

		--

		tween_service:Create(main_frame.credits_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()
		tween_service:Create(main_frame.dashboard_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()
		tween_service:Create(main_frame.main_frame, slow, {Position = UDim2.new(.5, 0, 1, 0), GroupTransparency = 0}):Play()

		--

		exe_module:menu(false)

		main_frame.ClipsDescendants = false

	elseif page == "Dashboard" then

		main_frame.ClipsDescendants = true

		main_frame.credits_frame.Visible = false
		main_frame.dashboard_frame.Visible = true
		main_frame.main_frame.Visible = false

		--

		tween_service:Create(main_frame.credits_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()
		tween_service:Create(main_frame.dashboard_frame, slow, {Position = UDim2.new(.5, 0, 1, 0), GroupTransparency = 0}):Play()
		tween_service:Create(main_frame.main_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()

		--

		exe_module:menu(false)

		main_frame.ClipsDescendants = false

	elseif page == "Credits" then

		main_frame.ClipsDescendants = true

		main_frame.credits_frame.Visible = true
		main_frame.dashboard_frame.Visible = false
		main_frame.main_frame.Visible = false

		--// ACCESSIBILITY BUTTON RECENT

		options.recent.icon.Image = "rbxassetid://11419720347"
		options.recent.icon.corner.CornerRadius = UDim.new(0, 0)

		options.recent.func:SetAttribute("profile", false)
		options.recent.func:SetAttribute("dashboard", false)
		options.recent.func:SetAttribute("credits", true)

		--

		tween_service:Create(main_frame.credits_frame, slow, {Position = UDim2.new(.5, 0, 1, 0), GroupTransparency = 0}):Play()
		tween_service:Create(main_frame.dashboard_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()
		tween_service:Create(main_frame.main_frame, slow, {Position = UDim2.new(.5, 0, 1.2, 0), GroupTransparency = 1}):Play()

		--

		exe_module:menu(false)

		main_frame.ClipsDescendants = false
	end
end

return module