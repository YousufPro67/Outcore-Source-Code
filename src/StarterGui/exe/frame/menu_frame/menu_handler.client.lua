local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local slow = TweenInfo.new(.8, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))

local frame = script.Parent
local menu = frame.menu

local main_frame = frame.Parent

local main_module = require(main_frame.Parent.exe_main_module)

main_frame.credits_frame.Position = UDim2.new(.5, 0, 1.2, 0)
main_frame.dashboard_frame.Position = UDim2.new(.5, 0, 1.2, 0)

--

menu.buttons.players.MouseButton1Click:Connect(function()
	main_module:Go_To("Players")
end)

menu.buttons.dashboard.MouseButton1Click:Connect(function()
	main_module:Go_To("Dashboard")
end)

menu.buttons.credits.MouseButton1Click:Connect(function()
	main_module:Go_To("Credits")
end)

frame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		exe_module:menu(false)
	end
end)

--

function hover()
	for i, button in pairs(frame.menu.buttons:GetChildren()) do
		if button:IsA("ImageButton") then

			button.gradient.Rotation = 0
			tween_service:Create(button.gradient, loop, {Rotation = 360}):Play()


			button.MouseEnter:Connect(function()
				button.gradient.Enabled = true

				tween_service:Create(button, info, {BackgroundTransparency = .8}):Play()
				tween_service:Create(button.icon.scale, info, {Scale = 1.4}):Play()
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button, info, {BackgroundTransparency = .95}):Play()
				tween_service:Create(button.icon.scale, info, {Scale = .8}):Play()

				tween_service:Create(frame.menu.scale, slow, {Scale = .95}):Play()
			end)

			button.InputEnded:Connect(function()
				button.gradient.Enabled = false

				tween_service:Create(button, info, {BackgroundTransparency = 1}):Play()
				tween_service:Create(button.icon.scale, info, {Scale = 1}):Play()

				tween_service:Create(frame.menu.scale, slow, {Scale = 1}):Play()
			end)
		end
	end
end

hover()