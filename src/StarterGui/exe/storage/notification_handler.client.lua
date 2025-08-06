local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local player_service = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local notif = TweenInfo.new(1.5, Enum.EasingStyle.Exponential)
local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local local_player = player_service.LocalPlayer

local exe = local_player.PlayerGui:WaitForChild("exe")
local exe_storage = replicated_storage.exe_storage
local events = exe_storage.events.banit_events

local module = require(exe_storage:WaitForChild("notify_module"))

local folder = script.Parent

exe_storage.notify_module.notify.OnClientEvent:Connect(function(text, duration, icon)
	module:notify(text, duration, icon)
end)

events.notify.OnClientEvent:Connect(function(text, duration)
	module:notify(text, duration)
end)

events.announce.OnClientEvent:Connect(function(announcer, text, icon, duration, fullscreen)
	module:announce(announcer, text, icon, duration, fullscreen)
end)

--

function hover()
	for i, notifs in pairs(folder:GetChildren()) do
		if notifs:IsA("ImageButton") then

			notifs.MouseButton1Click:Connect(function()
				if not notifs:GetAttribute("closing") then
					notifs:GetAttribute("closing", true)

					tween_service:Create(notifs, notif, {Position = UDim2.new(.5, 0, -1, 0)}):Play()

					--

					task.wait(1.5)

					--

					notifs:Destroy()
				end
			end)

			notifs.MouseEnter:Connect(function()
				notifs.timeline.Position = UDim2.new(.5, 0, 2, 0)

				tween_service:Create(notifs.icon, info, {ImageTransparency = 1}):Play()
				tween_service:Create(notifs.icon.scale, info, {Scale = 0}):Play()

				tween_service:Create(notifs.close, info, {ImageTransparency = 0}):Play()
				tween_service:Create(notifs.close.scale, info, {Scale = 1}):Play()

				tween_service:Create(notifs.timeline, info, {Position = UDim2.new(.5, 0, 1, 2)}):Play()
			end)

			notifs.InputEnded:Connect(function()
				tween_service:Create(notifs.icon, info, {ImageTransparency = 0}):Play()
				tween_service:Create(notifs.icon.scale, info, {Scale = 1}):Play()

				tween_service:Create(notifs.close, info, {ImageTransparency = 1}):Play()
				tween_service:Create(notifs.close.scale, info, {Scale = 0}):Play()

				tween_service:Create(notifs.timeline, info, {Position = UDim2.new(.5, 0, 1.5, 0)}):Play()
			end)

		end
	end
end

folder.ChildAdded:Connect(function(child)
	if child:IsA("ImageButton") then
		local dur_info = TweenInfo.new(child:GetAttribute("duration"), Enum.EasingStyle.Sine)

		hover()

		--

		tween_service:Create(child.timeline.bar, dur_info, {Size = UDim2.fromScale(1, 1)}):Play()

		--

		task.wait(child:GetAttribute("duration"))

		--

		if not child:GetAttribute("closing") then
			child:GetAttribute("closing", true)

			tween_service:Create(child, notif, {Position = UDim2.new(.5, 0, -1, 0)}):Play()

			--

			task.wait(1.5)

			--

			child:Destroy()
		end
	end
end)