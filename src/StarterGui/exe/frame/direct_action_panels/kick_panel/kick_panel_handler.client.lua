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
local banit_events = exe_storage.events.banit_events

local frame = script.Parent
local background = frame.Parent

local properties = background.properties

local close = frame.close

local db = false

frame.confirm.MouseButton1Click:Connect(function()
	if not db then
		db = true
		
		banit_events.kick:FireServer(properties.username.Value, frame.reason.container.textbox.Text)
		
		exe_module:direct_panels("kick", false)
		
		--
		
		task.wait(1)
		
		--
		
		db = false
	end
end)

frame.reason.container.textbox.Focused:Connect(function()
	tween_service:Create(frame.reason, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

frame.reason.container.textbox.FocusLost:Connect(function()
	tween_service:Create(frame.reason, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("kick", false)
end)

--// HOVER

tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(frame.reason.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

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
	exe_module:direct_panels("kick", false)
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