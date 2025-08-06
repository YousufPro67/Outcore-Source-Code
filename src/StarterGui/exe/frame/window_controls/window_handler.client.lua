local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local textchat_service = game:GetService("TextChatService")

local info = TweenInfo.new(.4, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(.7, Enum.EasingStyle.Exponential)

local blur = lighting:WaitForChild("exe_admin_panel_blur")

local frame = script.Parent
local button = frame.button
local controls = frame.controls
local layer = frame.layer

local main_frame = frame.Parent

local resizing = false
local requesting_fullscreen = false

local start_mouse_pos
local start_frame_size
local start_frame_pos

local size
local dragging = false
local start_position
local start_frame_pos

local camera = workspace.CurrentCamera
local viewport = camera.ViewportSize

local storage = frame.Parent.Parent.storage

local min_size = Vector2.new(550, 350)
local max_size = Vector2.new(viewport.X - 50, viewport.Y - 50)

local last_pos = UDim2.fromScale(.5, .5)
local last_size = UDim2.fromOffset(min_size.X, min_size.Y)

local main_module = require(script.Parent.Parent.Parent.exe_main_module)
local configs = require(replicated_storage:WaitForChild("exe_storage").configuration):GET_CONFIGS()

--// RESIZE

function scale_ratio()
	local ratio = viewport.X + viewport.Y

	if ratio > 1500 then
		frame.Visible = true
	else
		frame.Visible = false
	end
end

scale_ratio()

local function fullscreen(state, transform, delete_cache)
	if state then
		storage.fullscreen.Value = true
		blur.Enabled = true

		controls.restore.icon.Image = "rbxassetid://11422140434"

		controls.resize.Visible = false
		controls.resize_disabled.Visible = true

		--

		main_frame.corner.CornerRadius = UDim.new(0, 0)
		main_frame.menu_frame.corner.CornerRadius = UDim.new(0, 0)
		main_frame.assets_panels.corner.CornerRadius = UDim.new(0, 0)
		main_frame.confirmation_prompt.corner.CornerRadius = UDim.new(0, 0)
		main_frame.direct_action_panels.corner.CornerRadius = UDim.new(0, 0)
		main_frame.profile_panel.corner.CornerRadius = UDim.new(0, 0)
		main_frame.resyncing_screen.corner.CornerRadius = UDim.new(0, 0)
		main_frame.tools_panels.corner.CornerRadius = UDim.new(0, 0)
		main_frame.window_controls.corner.CornerRadius = UDim.new(0, 0)

		main_frame.shadow.Visible = false

		--

		if not delete_cache then
			last_pos = main_frame.Position
			last_size = main_frame.Size
		end

		if transform then
			tween_service:Create(main_frame, info, {Position = UDim2.fromScale(.5, .5)}):Play()
			tween_service:Create(main_frame, smooth, {Size = UDim2.fromScale(1, 1)}):Play()
		end
	else
		storage.fullscreen.Value = false
		blur.Enabled = false

		controls.restore.icon.Image = "rbxassetid://11295287158"

		controls.resize.Visible = true
		controls.resize_disabled.Visible = false

		--

		main_frame.corner.CornerRadius = UDim.new(0, 20)
		main_frame.menu_frame.corner.CornerRadius = UDim.new(0, 20)
		main_frame.assets_panels.corner.CornerRadius = UDim.new(0, 20)
		main_frame.confirmation_prompt.corner.CornerRadius = UDim.new(0, 20)
		main_frame.direct_action_panels.corner.CornerRadius = UDim.new(0, 20)
		main_frame.profile_panel.corner.CornerRadius = UDim.new(0, 20)
		main_frame.resyncing_screen.corner.CornerRadius = UDim.new(0, 20)
		main_frame.tools_panels.corner.CornerRadius = UDim.new(0, 20)
		main_frame.window_controls.corner.CornerRadius = UDim.new(0, 20)

		main_frame.shadow.Visible = true

		--

		if transform then
			tween_service:Create(main_frame, smooth, {Position = last_pos}):Play()
			tween_service:Create(main_frame, info, {Size = last_size}):Play()
		end
	end
end

local function start_resize(input)
	resizing = true
	start_mouse_pos = Vector2.new(input.Position.X, input.Position.Y)
	start_frame_size = main_frame.Size
	start_frame_pos = main_frame.Position

	layer.Visible = true
end

local function stop()
	resizing = false
	layer.Visible = false

	--

	tween_service:Create(controls.resize.icon.scale, info, {Scale = 1}):Play()

	tween_service:Create(controls.resize.selection, info, {ImageTransparency = 1}):Play()
	tween_service:Create(controls.resize.selection.scale, info, {Scale = .5}):Play()
end

local function resize(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local currentMousePosition = Vector2.new(input.Position.X, input.Position.Y)
		local mouseDelta = currentMousePosition - start_mouse_pos
		local newSizeX = start_frame_size.X.Offset + (mouseDelta.X * 2)
		local newSizeY = start_frame_size.Y.Offset + (mouseDelta.Y * 2)

		newSizeX = math.clamp(newSizeX, min_size.X, max_size.X)
		newSizeY = math.clamp(newSizeY, min_size.Y, max_size.Y)

		local newSize = Vector2.new(newSizeX, newSizeY)

		local newFrameWidth = main_frame.AbsoluteSize.X
		local newFrameHeight = main_frame.AbsoluteSize.Y

		--

		tween_service:Create(main_frame, smooth, {Size = UDim2.new(0, newSizeX, 0, newSizeY)}):Play()
		tween_service:Create(main_frame, info, {Position = UDim2.new(start_frame_pos.X.Scale, start_frame_pos.X.Offset - (newFrameWidth - main_frame.AbsoluteSize.X) / 2,
			start_frame_pos.Y.Scale, start_frame_pos.Y.Offset - (newFrameHeight - main_frame.AbsoluteSize.Y) / 2)}):Play()

		--

		fullscreen(false, false)

		requesting_fullscreen = false
		blur.Enabled = false
		storage.fullscreen.Value = false

		last_pos = main_frame.Position
		last_size = main_frame.Size

		controls.restore.icon.Image = "rbxassetid://11295287158"
	end
end

controls.resize.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		start_resize(input)
	end
end)

input_service.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		stop()
	end
end)

input_service.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and resizing then
		resize(input)
	end
end)

--// DRAGGING

function start_dragging(input)
	if dragging or resizing then
		return
	end

	dragging = true
	start_position = input.Position
	start_frame_pos = main_frame.Position

	layer.Visible = true
end

function update(input)
	if dragging and start_position and start_frame_pos then
		if storage.fullscreen then
			fullscreen(false, false)

			tween_service:Create(main_frame, info, {Size = last_size}):Play()
		end

		local viewport = workspace.CurrentCamera.ViewportSize
		local delta = input.Position - start_position
		local position = UDim2.new(start_frame_pos.X.Scale, start_frame_pos.X.Offset + delta.X, start_frame_pos.Y.Scale, start_frame_pos.Y.Offset + delta.Y)

		tween_service:Create(main_frame, info, {Position = position}):Play()
	end
end

function end_drag()
	dragging = false
	last_pos = main_frame.Position

	layer.Visible = false
end

button.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		start_dragging(input)
	end
end)

input_service.InputChanged:Connect(function(input)
	update(input)
end)

input_service.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and dragging) then
		end_drag()
	end
end)

--// BUTTON

local hold = false

button.MouseButton1Click:Connect(function()
	if controls.Visible and not hold then
		hold = true

		tween_service:Create(controls, info, {Position = UDim2.new(1, 100, 1, 0), Size = UDim2.fromOffset(50, 50)}):Play()

		--
		task.wait(.5)
		--

		controls.Visible = false
		hold = false

	elseif not controls.Visible and not hold then
		hold = true

		controls.Visible = true
		controls.Position = UDim2.new(1, 100, 1, 0)
		controls.Size = UDim2.fromOffset(50, 50)

		--

		tween_service:Create(controls, info, {Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(100, 50)}):Play()

		--
		task.wait(.5)
		--

		hold = false
	end
end)

controls.restore.MouseButton1Click:Connect(function()
	fullscreen(not storage.fullscreen.Value, true)
end)



controls.resize.MouseEnter:Connect(function()
	if not resizing then
		controls.resize.selection.ImageTransparency = 1
		controls.resize.selection.scale.Scale = .5

		tween_service:Create(controls.resize.icon.scale, info, {Scale = 1.2}):Play()

		tween_service:Create(controls.resize.selection, info, {ImageTransparency = .8}):Play()
		tween_service:Create(controls.resize.selection.scale, info, {Scale = 1}):Play()
	end
end)

controls.resize.MouseButton1Down:Connect(function()
	tween_service:Create(controls.resize.icon.scale, info, {Scale = .5}):Play()

	tween_service:Create(controls.resize.selection, info, {ImageTransparency = .9}):Play()
	tween_service:Create(controls.resize.selection.scale, info, {Scale = .8}):Play()
end)

controls.resize.InputEnded:Connect(function()
	if not resizing then
		tween_service:Create(controls.resize.icon.scale, info, {Scale = 1}):Play()

		tween_service:Create(controls.resize.selection, info, {ImageTransparency = 1}):Play()
		tween_service:Create(controls.resize.selection.scale, info, {Scale = .5}):Play()
	end
end)



controls.restore.MouseEnter:Connect(function()
	controls.restore.selection.ImageTransparency = 1
	controls.restore.selection.scale.Scale = .5

	tween_service:Create(controls.restore.icon.scale, info, {Scale = 1.2}):Play()

	tween_service:Create(controls.restore.selection, info, {ImageTransparency = .8}):Play()
	tween_service:Create(controls.restore.selection.scale, info, {Scale = 1}):Play()
end)

controls.restore.MouseButton1Down:Connect(function()
	tween_service:Create(controls.restore.icon.scale, info, {Scale = .5}):Play()

	tween_service:Create(controls.restore.selection, info, {ImageTransparency = .9}):Play()
	tween_service:Create(controls.restore.selection.scale, info, {Scale = .8}):Play()
end)

controls.restore.InputEnded:Connect(function()
	tween_service:Create(controls.restore.icon.scale, info, {Scale = 1}):Play()

	tween_service:Create(controls.restore.selection, info, {ImageTransparency = 1}):Play()
	tween_service:Create(controls.restore.selection.scale, info, {Scale = .5}):Play()
end)

--// TEXT COMMANDS

local db = false

textchat_service.toggle_exe.Triggered:Connect(function()
	if not db  then
		db = true

		main_module:exe_admin_panel(not main_frame.Visible)

		--
		task.wait(1)
		--

		db = false
	end
end)

players.LocalPlayer.Chatted:Connect(function(message)
	if message == "/exe" then
		if not db  then
			db = true

			main_module:exe_admin_panel(not main_frame.Visible)

			--
			task.wait(1)
			--

			db = false
		end
	elseif message == "/resetexe" then
		fullscreen(true, true, true)
	end
end)

input_service.InputBegan:Connect(function(input)
	local key1, key2 = configs.SYSTEM.RESET_SCALE_BIND[1], configs.SYSTEM.RESET_SCALE_BIND[2]

	if (input.KeyCode == key2 and not input_service:IsKeyDown(key1)) then
		if not db  then
			db = true

			main_module:exe_admin_panel(not main_frame.Visible)

			--
			task.wait(1)
			--

			db = false
		end
	end
end)

--// RESETTING

textchat_service.reset_exe.Triggered:Connect(function()
	fullscreen(true, true, true)
end)

--// SCALING

frame.MouseWheelForward:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftControl) then
		local to_scale = math.clamp(main_frame.Parent.scale.Scale + .1, .5, 2)

		tween_service:Create(main_frame.Parent.scale, info, {Scale = to_scale}):Play()
	end
end)

frame.MouseWheelBackward:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftControl) then
		local to_scale = math.clamp(main_frame.Parent.scale.Scale - .1, .5, 2)

		tween_service:Create(main_frame.Parent.scale, info, {Scale = to_scale}):Play()
	end
end)

frame.InputBegan:Connect(function(input)
	if (input.KeyCode == Enum.KeyCode.F2 and input_service:IsKeyDown(Enum.KeyCode.LeftControl)) then
		tween_service:Create(main_frame.Parent.scale, info, {Scale = 1}):Play()
	end
end)