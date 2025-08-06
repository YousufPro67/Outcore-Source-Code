local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local rev = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local slow = TweenInfo.new(5, Enum.EasingStyle.Exponential)

local exe_storage = replicated_storage.exe_storage

local events = exe_storage.events

local exe_module = require(exe_storage:WaitForChild("exe_module"))
local main_module = require(script.Parent.Parent.Parent.exe_main_module)

local frame = script.Parent

local navi = frame.navigation_buttons
local scroll = frame.scroll

local checking = false

--// NAVIGATION

navi.menu.MouseButton1Click:Connect(function()
	exe_module:menu(true)
end)

navi.close.MouseButton1Click:Connect(function()
	main_module:exe_admin_panel(false)
end)

--// NAVIGATION HOVERS

function hover()
	for i, button in pairs(frame.scroll:GetChildren()) do
		if button:IsA("TextButton") then

			button.MouseEnter:Connect(function()
				tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(17, 17, 17)}):Play()
			end)

			button.InputEnded:Connect(function()
				tween_service:Create(button, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
			end)

		end
	end
end

function hover_navi()
	for i, button in pairs(navi:GetChildren()) do
		if button:IsA("ImageButton") then

			button.gradient.Rotation = 0

			tween_service:Create(button.gradient, loop, {Rotation = 360}):Play()

			button.MouseEnter:Connect(function()
				button.gradient.Enabled = true

				tween_service:Create(button.icon.scale, info, {Scale = 1.2}):Play()
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

local function restate()
	scroll.system.build.value.Text = frame.Parent.Parent:GetAttribute("build")
	scroll.system.model.value.Text = "Exe " .. frame.Parent.Parent:GetAttribute("version")
end

exe_storage.events.setup.OnClientEvent:Connect(restate)