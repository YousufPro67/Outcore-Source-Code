local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local long = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local prog = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local player_list = frame.Parent.player_list
local properties = frame.Parent.properties

local hold = false
local pressing = false

function drag_initiate()
	local mouse_location = input_service:GetMouseLocation()
	local drag_info = TweenInfo.new(.1, Enum.EasingStyle.Sine)

	local position = UDim2.fromOffset(mouse_location.X - frame.AbsolutePosition.X, (mouse_location.Y - frame.AbsolutePosition.Y) - 20)

	tween_service:Create(properties.dragging_element, drag_info, {Position = position}):Play()
end

function setup_effects()
	for i, button in pairs(frame:GetChildren()) do
		if button:IsA("ImageButton") then

			button.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					button.properties.drag_effect.progress.Position = UDim2.new(0, -40, .5, 0)

					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							if properties.dragging.Value and properties.hovering.Value then
								local recipient = players:GetPlayerByUserId(properties.hovering.Value.properties.id.Value)

								banit_events.apply_effect:FireServer(recipient, button.properties.effect.Value)
							end

							--

							hold = false
							pressing = false

							properties.dragging.Value = nil

							tween_service:Create(button.properties.drag_effect, info, {GroupTransparency = 1}):Play()
							tween_service:Create(properties.dragging_element, info, {GroupTransparency = 1}):Play()
						end
					end)

					--

					pressing = true

					button.stroke.gradient.Offset = Vector2.new(-1, 0)

					tween_service:Create(button.properties.drag_effect, long, {GroupTransparency = .6}):Play()
					tween_service:Create(button.properties.drag_effect.progress, prog, {Position = UDim2.fromScale(1, .5)}):Play()

					--
					task.wait(1)
					--

					if pressing then
						local mouse_location = input_service:GetMouseLocation()

						hold = true

						properties.dragging.Value = button
						properties.dragging_element.Position = UDim2.fromOffset(mouse_location.X - frame.AbsolutePosition.X, mouse_location.Y - frame.AbsolutePosition.Y)
						properties.dragging_element.texture.Image = button.texture.Image
						properties.dragging_element.effect_name.value.Text = button.Name

						--

						tween_service:Create(button.stroke.gradient, long, {Offset = Vector2.new(1, 0)}):Play()
						tween_service:Create(button.properties.drag_effect, long, {GroupTransparency = .8}):Play()
					else
						tween_service:Create(button.properties.drag_effect, long, {GroupTransparency = 1}):Play()
					end
				end
			end)

			input_service.InputChanged:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					if hold and pressing then
						tween_service:Create(properties.dragging_element, info, {GroupTransparency = 0}):Play()

						drag_initiate()
					end
				end
			end)

			input_service.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					if not hold and pressing then
						pressing = false
					end
				end
			end)
		end
	end
end

function setup_players()
	for i, button in pairs(player_list:GetChildren()) do
		if button:IsA("ImageButton") then

			button.MouseEnter:Connect(function()
				if properties.dragging.Value then
					properties.hovering.Value = button

					tween_service:Create(button.properties.drag_effect, long, {GroupTransparency = .7}):Play()
					tween_service:Create(properties.dragging_element.effect_name, info, {BackgroundColor3 = Color3.fromRGB(27, 158, 88)}):Play()
				end
			end)

			button.MouseLeave:Connect(function()
				properties.hovering.Value = nil

				tween_service:Create(button.properties.drag_effect, long, {GroupTransparency = 1}):Play()
				tween_service:Create(properties.dragging_element.effect_name, info, {BackgroundColor3 = Color3.fromRGB(65, 122, 255)}):Play()
			end)

		end
	end
end

frame.ChildAdded:Connect(setup_effects)
player_list.ChildAdded:Connect(setup_players)

setup_effects()
setup_players()