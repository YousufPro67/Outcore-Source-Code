local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local teams_service = game:GetService("Teams")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local smooth = TweenInfo.new(.7, Enum.EasingStyle.Exponential)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local content = frame.content
local scroll = content.scroll

local background = frame.Parent

local close = frame.close

local container = scroll.section.container

--//

container.global_announcement.MouseEnter:Connect(function()
	tween_service:Create(container.global_announcement.canvas, smooth, {Position = UDim2.fromScale(1, .5), Size = UDim2.fromScale(1, 1)}):Play()
	tween_service:Create(container.global_announcement.context, smooth, {Position = UDim2.fromOffset(20, 20)}):Play()

	tween_service:Create(container.global_announcement.canvas.viewport.announcement_panel, smooth, {CFrame = container.global_announcement.canvas.viewport.last.CFrame}):Play()
end)

container.global_announcement.MouseLeave:Connect(function()
	tween_service:Create(container.global_announcement.canvas, smooth, {Position = UDim2.new(1, -20, .5, 0), Size = UDim2.fromOffset(400, 200)}):Play()
	tween_service:Create(container.global_announcement.context, smooth, {Position = UDim2.fromOffset(5, 5)}):Play()

	tween_service:Create(container.global_announcement.canvas.viewport.announcement_panel, smooth, {CFrame = container.global_announcement.canvas.viewport.start.CFrame}):Play()
end)


container.ban_api.MouseEnter:Connect(function()
	tween_service:Create(container.ban_api.canvas, smooth, {Position = UDim2.fromScale(1, .5), Size = UDim2.fromScale(1, 1)}):Play()
	tween_service:Create(container.ban_api.context, smooth, {Position = UDim2.fromOffset(20, 20)}):Play()

	tween_service:Create(container.ban_api.canvas.viewport.ban_page, smooth, {CFrame = container.ban_api.canvas.viewport.ban_end.CFrame}):Play()
	tween_service:Create(container.ban_api.canvas.viewport.manage_page, smooth, {CFrame = container.ban_api.canvas.viewport.manage_end.CFrame}):Play()
end)

container.ban_api.MouseLeave:Connect(function()
	tween_service:Create(container.ban_api.canvas, smooth, {Position = UDim2.new(1, -20, .5, 0), Size = UDim2.fromOffset(400, 200)}):Play()
	tween_service:Create(container.ban_api.context, smooth, {Position = UDim2.fromOffset(5, 5)}):Play()

	tween_service:Create(container.ban_api.canvas.viewport.ban_page, smooth, {CFrame = container.ban_api.canvas.viewport.ban_start.CFrame}):Play()
	tween_service:Create(container.ban_api.canvas.viewport.manage_page, smooth, {CFrame = container.ban_api.canvas.viewport.manage_start.CFrame}):Play()
end)



container.more.dashboard.MouseEnter:Connect(function()
	container.more.dashboard.stroke.Enabled = true

	tween_service:Create(container.more.dashboard, info, {BackgroundTransparency = .95}):Play()
	tween_service:Create(container.more.dashboard.padding, info, {PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 20)}):Play()
end)

container.more.dashboard.MouseLeave:Connect(function()
	container.more.dashboard.stroke.Enabled = false

	tween_service:Create(container.more.dashboard, info, {BackgroundTransparency = 1}):Play()
	tween_service:Create(container.more.dashboard.padding, info, {PaddingTop = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0)}):Play()
end)



container.more.perms.MouseEnter:Connect(function()
	container.more.perms.stroke.Enabled = true

	tween_service:Create(container.more.perms, info, {BackgroundTransparency = .95}):Play()
	tween_service:Create(container.more.perms.padding, info, {PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 20)}):Play()
end)

container.more.perms.MouseLeave:Connect(function()
	container.more.perms.stroke.Enabled = false

	tween_service:Create(container.more.perms, info, {BackgroundTransparency = 1}):Play()
	tween_service:Create(container.more.perms.padding, info, {PaddingTop = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0)}):Play()
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("snapshot", false)
end)

--// HOVER

tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()

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
	exe_module:direct_panels("snapshot", false)
end)