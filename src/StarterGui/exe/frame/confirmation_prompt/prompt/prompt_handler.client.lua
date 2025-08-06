local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events.confirmation_events

local frame = script.Parent
local background = frame.Parent

local db = false

frame.confirm.MouseButton1Click:Connect(function()
	if not db then
		db = true
		
		events.confirmation_closed:Fire(true, background.confirmation_id.Value)
		exe_module:prompt_confirmation(false)
		
		--
		
		task.wait()
		
		--
		
		db = false
	end
end)

frame.cancel.MouseButton1Click:Connect(function()
	events.confirmation_closed:Fire(false, background.confirmation_id.Value)
	exe_module:prompt_confirmation(false)
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	events.confirmation_closed:Fire(false, background.confirmation_id.Value)
	exe_module:prompt_confirmation(false)
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

--

frame.cancel.MouseEnter:Connect(function()
	tween_service:Create(frame.cancel, info, {BackgroundColor3 = Color3.fromRGB(112, 117, 120)}):Play()
end)

frame.cancel.MouseButton1Down:Connect(function()
	tween_service:Create(frame.cancel, info, {BackgroundColor3 = Color3.fromRGB(58, 61, 62)}):Play()
end)

frame.cancel.InputEnded:Connect(function()
	tween_service:Create(frame.cancel, info, {BackgroundColor3 = Color3.fromRGB(85, 89, 91)}):Play()
end)