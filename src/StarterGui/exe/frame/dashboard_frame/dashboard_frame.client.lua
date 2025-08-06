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
local main_module = require(script.Parent.Parent.Parent.exe_main_module)
local slider_module = require(exe_storage.slider_service)

local frame = script.Parent

local navi = frame.navigation_buttons
local scroll = frame.scroll

--// MODERATOR TOOLS

scroll.moderator_tools.features.global_ban.MouseButton1Click:Connect(function()
	exe_module:direct_panels("global", true)
end)

scroll.moderator_tools.features.manage_bans.MouseButton1Click:Connect(function()
	exe_module:tools_panels("manage", true)
end)

scroll.moderator_tools.features.revoke_ban.MouseButton1Click:Connect(function()
	exe_module:direct_panels("revoke", true)
end)

--// SERVER EQUIPMENT

scroll.server_equipment.features.server_announcement.MouseButton1Click:Connect(function()
	exe_module:tools_panels("announcement", true)
end)

scroll.server_equipment.features.server_announcement.quick_access.global.MouseButton1Click:Connect(function()
	exe_module:tools_panels("global_announcement", true)
end)

scroll.server_equipment.features.server_privacy.MouseButton1Click:Connect(function()
	exe_module:tools_panels("server_privacy", true)
end)

--// ADDITIONAL FEATURES

scroll.additional_features.features.custom_commands.MouseButton1Click:Connect(function()
	exe_module:tools_panels("custom_commands", true)
end)

scroll.additional_features.features.effects.MouseButton1Click:Connect(function()
	exe_module:tools_panels("effects", true)
end)

scroll.additional_features.features.tools.MouseButton1Click:Connect(function()
	exe_module:tools_panels("tools", true)
end)

--// NAVIGATION

navi.menu.MouseButton1Click:Connect(function()
	exe_module:menu(true)
end)

navi.close.MouseButton1Click:Connect(function()
	main_module:exe_admin_panel(false)
end)

--// NAVIGATION HOVERS

local allowed = true

function hover()
	for i, button in pairs(frame.scroll:GetDescendants()) do
		if button:IsA("ImageButton") then

			local folder = button:FindFirstChild("quick_access")

			button.MouseEnter:Connect(function()
				if allowed then
					tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
				end
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(17, 17, 17)}):Play()
			end)

			button.InputEnded:Connect(function()
				tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
			end)

			if folder then
				folder.global.MouseEnter:Connect(function()
					tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
					tween_service:Create(folder.global, info, {BackgroundTransparency = .5, 
						BackgroundColor3 = Color3.fromRGB(102, 102, 102)}):Play()
				end)

				folder.global.MouseLeave:Connect(function()
					tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
					tween_service:Create(folder.global, info, {BackgroundTransparency = .9, 
						BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
				end)
			end

		end
	end
end

function hover_navi()
	for i, button in pairs(navi:GetChildren()) do
		if button:IsA("ImageButton") then

			button.gradient.Rotation = 0

			tween_service:Create(button.gradient, loop, {Rotation = 360}):Play()

			button.MouseEnter:Connect(function()
				if allowed then
					button.gradient.Enabled = true

					tween_service:Create(button.icon.scale, info, {Scale = 1.2}):Play()
				end
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button.icon.scale, info, {Scale = .8}):Play()
			end)

			button.InputEnded:Connect(function()
				button.gradient.Enabled = false

				tween_service:Create(button.icon.scale, info, {Scale = 1}):Play()
			end)

		end
	end
end

hover()
hover_navi()

frame.Parent.tools_panels.Changed:Connect(function()
	allowed = not frame.Parent.tools_panels.Visible
end)

frame.Parent.direct_action_panels.Changed:Connect(function()
	allowed = not frame.Parent.direct_action_panels.Visible
end)