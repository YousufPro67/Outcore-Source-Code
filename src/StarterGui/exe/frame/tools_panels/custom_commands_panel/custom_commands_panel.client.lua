local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local short = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local rev = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local slider_service = require(exe_storage:WaitForChild("slider_service"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local background = frame.Parent

local search = frame.scroll.search
local close = frame.close

local db = false
local throttle = false
local clicking = false
local opened = 0

local CUSTOM_COMMANDS = require(exe_storage.custom_commands)

function number_range(number, from_min, from_max, to_min, to_max)
	return (number - from_min) / (from_max - from_min) * (to_max - to_min) + to_min
end

function add(library, name)
	if library.PROCEDURE.PLAYER_MENU and library.PROCEDURE.INPUT_MENU and
		library.PROCEDURE.SLIDER_MENU then

		local button = frame.scroll.list.player_input_slider_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION
		button.properties.textbox_type.Value = library.PROCEDURE.INPUT_SETTINGS

		button:SetAttribute("command_identifier", name)

		if library.PROCEDURE.SLIDER_DEFAULT >= library.PROCEDURE.SLIDER_SETTINGS.Min then

			button.properties.increment.Value = library.PROCEDURE.SLIDER_INCREMENT
			button.properties.default.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.slider_value.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.min.Value = library.PROCEDURE.SLIDER_SETTINGS.Min
			button.properties.max.Value = library.PROCEDURE.SLIDER_SETTINGS.Max

			button.requirements.slider.min_value.Text = button.properties.min.Value
			button.requirements.slider.max_value.Text = button.properties.max.Value
		end

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		elseif library.PROCEDURE.SLIDER_DEFAULT < library.PROCEDURE.SLIDER_SETTINGS.Min then
			button.details.label.Text = "Something's wrong with the Default value."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Player and Input. Slider Value:" ..  button.properties.default.Value
		end

		button.Parent = frame.scroll

		--

		button.requirements.choose_player.MouseButton1Click:Connect(function()
			exe_module:assets_panels("players_selection", true, nil, button)
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			if button.properties.textbox_type.Value == "number" then
				local number = tonumber(button.requirements.input.textbox.Text)

				if not number then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts numeric characters.", 3, "rbxassetid://12967738127")
				end
			elseif button.properties.textbox_type.Value == "string" then
				if button.requirements.input.textbox.Text:match("%d") then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts non-numeric characters.", 3, "rbxassetid://14187783356")
				end
			end
		end)

		button.requirements.input.textbox.Focused:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0}):Play()
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = .7}):Play()
		end)

		local slider = slider_service.new(button.requirements.slider, {
			AllowBackgroundClick = false,
			SliderData = {
				Start = button.properties.min.Value,
				End = button.properties.max.Value,
				DefaultValue = button.properties.default.Value,
				Increment = button.properties.increment.Value},
			MoveInfo = TweenInfo.new(.2, Enum.EasingStyle.Exponential),
			Padding = 0
		})

		slider:Track()

		slider.Changed:Connect(function(value)
			button.properties.slider_value.Value = value
			button.details.label.Text = "Requires Player and Input. Slider Value: " .. value

			--

			tween_service:Create(button.requirements.slider.min_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .5, .9)}):Play()

			tween_service:Create(button.requirements.slider.max_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .9, .5)}):Play()
		end)

		button.requirements.slider.Slider.MouseButton1Down:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = .8}):Play()
		end)

		button.requirements.slider.Slider.MouseLeave:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = 1}):Play()
		end)

		tween_service:Create(button.requirements.input.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

	elseif library.PROCEDURE.PLAYER_MENU and library.PROCEDURE.SLIDER_MENU then
		local button = frame.scroll.list.player_slider_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION

		button:SetAttribute("command_identifier", name)

		if library.PROCEDURE.SLIDER_DEFAULT >= library.PROCEDURE.SLIDER_SETTINGS.Min then

			button.properties.increment.Value = library.PROCEDURE.SLIDER_INCREMENT
			button.properties.default.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.slider_value.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.min.Value = library.PROCEDURE.SLIDER_SETTINGS.Min
			button.properties.max.Value = library.PROCEDURE.SLIDER_SETTINGS.Max

			button.requirements.slider.min_value.Text = button.properties.min.Value
			button.requirements.slider.max_value.Text = button.properties.max.Value
		end

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		elseif library.PROCEDURE.SLIDER_DEFAULT < library.PROCEDURE.SLIDER_SETTINGS.Min then
			button.details.label.Text = "Something's wrong with the Default value."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Player and Input. Slider Value:" ..  button.properties.default.Value
		end

		button.Parent = frame.scroll

		--

		button.requirements.choose_player.MouseButton1Click:Connect(function()
			exe_module:assets_panels("players_selection", true, nil, button)
		end)

		local slider = slider_service.new(button.requirements.slider, {
			AllowBackgroundClick = false,
			SliderData = {
				Start = button.properties.min.Value,
				End = button.properties.max.Value,
				DefaultValue = button.properties.default.Value,
				Increment = button.properties.increment.Value},
			MoveInfo = TweenInfo.new(.2, Enum.EasingStyle.Exponential),
			Padding = 0
		})

		slider:Track()

		slider.Changed:Connect(function(value)
			button.properties.slider_value.Value = value
			button.details.label.Text = "Requires Player. Slider Value: " .. value

			--

			tween_service:Create(button.requirements.slider.min_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .5, .9)}):Play()

			tween_service:Create(button.requirements.slider.max_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .9, .5)}):Play()
		end)

		button.requirements.slider.Slider.MouseButton1Down:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = .8}):Play()
		end)

		button.requirements.slider.Slider.MouseLeave:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = 1}):Play()
		end)

	elseif library.PROCEDURE.PLAYER_MENU and library.PROCEDURE.INPUT_MENU then
		local button = frame.scroll.list.player_input_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION
		button.properties.textbox_type.Value = library.PROCEDURE.INPUT_SETTINGS

		button:SetAttribute("command_identifier", name)

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Player and Input."
		end

		button.Parent = frame.scroll

		--

		button.requirements.choose_player.MouseButton1Click:Connect(function()
			exe_module:assets_panels("players_selection", true, nil, button)
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			if button.properties.textbox_type.Value == "number" then
				local number = tonumber(button.requirements.input.textbox.Text)

				if not number then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts numeric characters.", 3, "rbxassetid://12967738127")
				end
			elseif button.properties.textbox_type.Value == "string" then
				if button.requirements.input.textbox.Text:match("%d") then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts non-numeric characters.", 3, "rbxassetid://14187783356")
				end
			end
		end)

		button.requirements.input.textbox.Focused:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0}):Play()
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = .7}):Play()
		end)	

		tween_service:Create(button.requirements.input.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

	elseif library.PROCEDURE.INPUT_MENU and library.PROCEDURE.SLIDER_MENU then
		local button = frame.scroll.list.input_slider_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION
		button.properties.textbox_type.Value = library.PROCEDURE.INPUT_SETTINGS

		button:SetAttribute("command_identifier", name)

		if library.PROCEDURE.SLIDER_DEFAULT >= library.PROCEDURE.SLIDER_SETTINGS.Min then

			button.properties.increment.Value = library.PROCEDURE.SLIDER_INCREMENT
			button.properties.default.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.slider_value.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.min.Value = library.PROCEDURE.SLIDER_SETTINGS.Min
			button.properties.max.Value = library.PROCEDURE.SLIDER_SETTINGS.Max

			button.requirements.slider.min_value.Text = button.properties.min.Value
			button.requirements.slider.max_value.Text = button.properties.max.Value
		end

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		elseif library.PROCEDURE.SLIDER_DEFAULT < library.PROCEDURE.SLIDER_SETTINGS.Min then
			button.details.label.Text = "Something's wrong with the Default value."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Input. Slider Value:" ..  button.properties.default.Value
		end

		button.Parent = frame.scroll

		--

		button.requirements.input.textbox.FocusLost:Connect(function()
			if button.properties.textbox_type.Value == "number" then
				local number = tonumber(button.requirements.input.textbox.Text)

				if not number then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts numeric characters.", 3, "rbxassetid://12967738127")
				end
			elseif button.properties.textbox_type.Value == "string" then
				if button.requirements.input.textbox.Text:match("%d") then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts non-numeric characters.", 3, "rbxassetid://14187783356")
				end
			end
		end)

		button.requirements.input.textbox.Focused:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0}):Play()
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = .7}):Play()
		end)

		local slider = slider_service.new(button.requirements.slider, {
			AllowBackgroundClick = false,
			SliderData = {
				Start = button.properties.min.Value,
				End = button.properties.max.Value,
				DefaultValue = button.properties.default.Value,
				Increment = button.properties.increment.Value},
			MoveInfo = TweenInfo.new(.2, Enum.EasingStyle.Exponential),
			Padding = 0
		})

		slider:Track()

		slider.Changed:Connect(function(value)
			button.properties.slider_value.Value = value
			button.details.label.Text = "Requires Input. Slider Value: " .. value

			--

			tween_service:Create(button.requirements.slider.min_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .5, .9)}):Play()

			tween_service:Create(button.requirements.slider.max_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .9, .5)}):Play()
		end)

		button.requirements.slider.Slider.MouseButton1Down:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = .8}):Play()
		end)

		button.requirements.slider.Slider.MouseLeave:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = 1}):Play()
		end)

		tween_service:Create(button.requirements.input.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

	elseif library.PROCEDURE.PLAYER_MENU then

		local button = frame.scroll.list.player_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION

		button:SetAttribute("command_identifier", name)

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Player."
		end

		button.Parent = frame.scroll

		--

		button.requirements.choose_player.MouseButton1Click:Connect(function()
			exe_module:assets_panels("players_selection", true, nil, button)
		end)

	elseif library.PROCEDURE.INPUT_MENU then

		local button = frame.scroll.list.input_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION
		button.properties.textbox_type.Value = library.PROCEDURE.INPUT_SETTINGS

		button:SetAttribute("command_identifier", name)

		if not library.EVENT and library.PROCEDURE.INPUT_SETTINGS == "" then
			button.details.label.Text = "No registered event and no input settings."
		elseif not library.EVENT then
			button.details.label.Text = "No registered event."
		elseif library.PROCEDURE.INPUT_SETTINGS == "" then
			button.details.label.Text = "No input settings provided."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Requires Input."
		end

		button.Parent = frame.scroll

		--

		button.requirements.input.textbox.FocusLost:Connect(function()
			if button.properties.textbox_type.Value == "number" then
				local number = tonumber(button.requirements.input.textbox.Text)

				if not number then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts numeric characters.", 3, "rbxassetid://12967738127")
				end
			elseif button.properties.textbox_type.Value == "string" then
				if button.requirements.input.textbox.Text:match("%d") then
					button.requirements.input.textbox.Text = ""

					exe_module:notify("Only accepts non-numeric characters.", 3, "rbxassetid://14187783356")
				end
			end
		end)

		button.requirements.input.textbox.Focused:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0}):Play()
		end)

		button.requirements.input.textbox.FocusLost:Connect(function()
			tween_service:Create(button.requirements.input, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = .7}):Play()
		end)		

		tween_service:Create(button.requirements.input.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

	elseif library.PROCEDURE.SLIDER_MENU then

		local button = frame.scroll.list.slider_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION

		button:SetAttribute("command_identifier", name)

		if library.PROCEDURE.SLIDER_DEFAULT >= library.PROCEDURE.SLIDER_SETTINGS.Min then

			button.properties.increment.Value = library.PROCEDURE.SLIDER_INCREMENT
			button.properties.default.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.slider_value.Value = library.PROCEDURE.SLIDER_DEFAULT
			button.properties.min.Value = library.PROCEDURE.SLIDER_SETTINGS.Min
			button.properties.max.Value = library.PROCEDURE.SLIDER_SETTINGS.Max

			button.requirements.slider.min_value.Text = button.properties.min.Value
			button.requirements.slider.max_value.Text = button.properties.max.Value
		end

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		elseif library.PROCEDURE.SLIDER_DEFAULT < library.PROCEDURE.SLIDER_SETTINGS.Min then
			button.details.label.Text = "Something's wrong with the Default value."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "Slider Value:" ..  button.properties.default.Value
		end

		button.Parent = frame.scroll

		--

		local slider = slider_service.new(button.requirements.slider, {
			AllowBackgroundClick = false,
			SliderData = {
				Start = button.properties.min.Value,
				End = button.properties.max.Value,
				DefaultValue = button.properties.default.Value,
				Increment = button.properties.increment.Value},
			MoveInfo = TweenInfo.new(.2, Enum.EasingStyle.Exponential),
			Padding = 0
		})

		slider:Track()

		slider.Changed:Connect(function(value)
			button.properties.slider_value.Value = value
			button.details.label.Text = "Slider Value: " .. value

			--

			tween_service:Create(button.requirements.slider.min_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .5, .9)}):Play()

			tween_service:Create(button.requirements.slider.max_value, info, {
				TextTransparency = number_range(value, button.properties.min.Value, button.properties.max.Value, .9, .5)}):Play()
		end)

		button.requirements.slider.Slider.MouseButton1Down:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = .8}):Play()
		end)

		button.requirements.slider.Slider.MouseLeave:Connect(function()
			tween_service:Create(button.requirements.slider.Slider.handle.scale, short, {Scale = 1}):Play()
		end)

	elseif library.PROCEDURE.PLAIN_MENU then

		local button = frame.scroll.list.plain_command:Clone()

		button.details.command_name.Text = name
		button.icon.Image = library.ICON
		button.requirements.description.Text = library.DESCRIPTION

		button:SetAttribute("command_identifier", name)

		if not library.EVENT then
			button.details.label.Text = "No registered event."
		else
			button.properties.event.Value = library.EVENT
			button.details.label.Text = "No requirements."
		end

		button.Parent = frame.scroll

	end
end

events.confirmation_events.selected_player.Event:Connect(function(username, profile, object_reference)
	object_reference.properties.username.Value = username
	object_reference.requirements.choose_player.icon.Image = profile
	object_reference.requirements.choose_player.button_label.Text = username
end)

function initialize()
	for name, library in pairs(CUSTOM_COMMANDS:GET_CUSTOM_COMMANDS()) do
		add(library, name)
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.MouseButton1Click:Connect(function()
				if items.Name ~= "plain_command" then
					if items.requirements.Visible then
						items.requirements.Visible = false

						tween_service:Create(items, info, {Size = UDim2.new(1, 0, 0, 65)}):Play()
						tween_service:Create(items.requirements, info, {
							AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, 2)}):Play()

					else
						if items.Name == "input_slider_command" or items.Name == "player_input_command" or
							items.Name == "player_slider_command" then

							items.requirements.Visible = true
							items.requirements.AnchorPoint = Vector2.new(.5, 1)
							items.requirements.Position = UDim2.new(.5, 0, 1, 2)

							tween_service:Create(items, info, {Size = UDim2.new(1, 0, 0, 195)}):Play()
							tween_service:Create(items.requirements, info, {
								AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 2)}):Play()

						elseif items.Name == "player_input_slider_command" then

							items.requirements.Visible = true
							items.requirements.AnchorPoint = Vector2.new(.5, 1)
							items.requirements.Position = UDim2.new(.5, 0, 1, 2)

							tween_service:Create(items, info, {Size = UDim2.new(1, 0, 0, 245)}):Play()
							tween_service:Create(items.requirements, info, {
								AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 2)}):Play()

						else
							items.requirements.Visible = true
							items.requirements.AnchorPoint = Vector2.new(.5, 1)
							items.requirements.Position = UDim2.new(.5, 0, 1, 2)

							tween_service:Create(items, info, {Size = UDim2.new(1, 0, 0, 145)}):Play()
							tween_service:Create(items.requirements, info, {
								AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 2)}):Play()
						end
					end
				end
			end)

			items.requirements.execute.MouseButton1Click:Connect(function()
				if items.properties.event.Value then
					if items.Name == "plain_command" then
						if items.properties.event.Value:IsA("BindableEvent") then
							items.properties.event.Value:Fire()

						elseif items.properties.event.Value:IsA("RemoteEvent") then
							items.properties.event.Value:FireServer()

						end

					elseif items.Name == "player_command" then

						if items.properties.username.Value == "" then
							exe_module:notify("No player selected.",
								3, "rbxassetid://11422917326")
						else
							local recipient = players[items.properties.username.Value]

							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(recipient)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(recipient)

							end
						end

					elseif items.Name == "input_command" then

						if items.requirements.input.textbox.Text == "" then
							exe_module:notify("No input typed.",
								3, "rbxassetid://12975591097")
						else
							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(items.requirements.input.textbox.Text)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(items.requirements.input.textbox.Text)

							end
						end

					elseif items.Name == "slider_command" then

						if items.properties.event.Value:IsA("BindableEvent") then
							items.properties.event.Value:Fire(items.properties.slider_value.Value)

						elseif items.properties.event.Value:IsA("RemoteEvent") then
							items.properties.event.Value:FireServer(items.properties.slider_value.Value)

						end

					elseif items.Name == "input_slider_command" then

						if items.requirements.input.textbox.Text == "" then
							exe_module:notify("No input typed.",
								3, "rbxassetid://12975591097")
						else
							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(items.requirements.input.textbox.Text,
									items.properties.slider_value.Value)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(items.requirements.input.textbox.Text,
									items.properties.slider_value.Value)

							end
						end

					elseif items.Name == "player_input_command" then


						if items.properties.username.Value ~= "" and items.requirements.input.textbox.Text ~= "" then
							local recipient = players[items.properties.username.Value]

							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(recipient, 
									items.requirements.input.textbox.Text)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(recipient, 
									items.requirements.input.textbox.Text)

							end
						else
							if items.properties.username.Value == "" then
								exe_module:notify("No player selected.",
									3, "rbxassetid://11422917326")
							elseif items.requirements.input.textbox.Text == "" then
								exe_module:notify("No input typed.",
									3, "rbxassetid://12975591097")
							end
						end

					elseif items.Name == "player_slider_command" then

						if items.properties.username.Value ~= "" then
							local recipient = players[items.properties.username.Value]

							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(recipient, 
									items.properties.slider_value.Value)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(recipient, 
									items.properties.slider_value.Value)

							end
						else
							if items.properties.username.Value == "" then
								exe_module:notify("No player selected.",
									3, "rbxassetid://11422917326")
							end
						end

					elseif items.Name == "player_input_slider_command" then


						if items.properties.username.Value ~= "" and items.requirements.input.textbox.Text ~= "" then
							local recipient = players[items.properties.username.Value]

							if items.properties.event.Value:IsA("BindableEvent") then
								items.properties.event.Value:Fire(recipient, 
									items.requirements.input.textbox.Text, items.properties.slider_value.Value)

							elseif items.properties.event.Value:IsA("RemoteEvent") then
								items.properties.event.Value:FireServer(recipient, 
									items.requirements.input.textbox.Text, items.properties.slider_value.Value)
							end
						else
							if items.properties.username.Value == "" then
								exe_module:notify("No player selected.",
									3, "rbxassetid://11422917326")
							elseif items.requirements.input.textbox.Text == "" then
								exe_module:notify("No input typed.",
									3, "rbxassetid://12975591097")
							end
						end

					end
				else
					exe_module:notify("No registered event. You need to set one before executing.",
						5, "rbxassetid://12974384407")
				end

				if not input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
					exe_module:tools_panels("custom_commands", false)
				end
			end)

			--

			items.MouseEnter:Connect(function()
				tween_service:Create(items, info, {BackgroundTransparency = .85}):Play()
			end)

			items.InputEnded:Connect(function()
				tween_service:Create(items, info, {BackgroundTransparency = .95}):Play()
			end)

			items.requirements.execute.MouseEnter:Connect(function()
				tween_service:Create(items.requirements.execute, info, {BackgroundColor3 = Color3.fromRGB(26, 139, 60)}):Play()
			end)

			items.requirements.execute.MouseButton1Down:Connect(function()
				tween_service:Create(items.requirements.execute, info, {BackgroundColor3 = Color3.fromRGB(15, 83, 35)}):Play()
				tween_service:Create(items.requirements.execute.icon, info, {Size = UDim2.fromOffset(18, 20)}):Play()
			end)

			items.requirements.execute.InputEnded:Connect(function()
				tween_service:Create(items.requirements.execute, info, {BackgroundColor3 = Color3.fromRGB(32, 175, 77)}):Play()
				tween_service:Create(items.requirements.execute.icon, info, {Size = UDim2.fromOffset(20, 20)}):Play()
			end)
		end
	end
end

--

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if background.Visible then
		if (opened == 0 and background.page.CurrentPage == frame) then
			opened += 1

			exe_module:prompt_resync(true, "Registering...", "cc")

			--

			task.wait(.5)

			--

			initialize()
			run()

			--

			task.wait(Random.new():NextNumber(.5, 1))

			--

			exe_module:prompt_resync(false)
		end
	end
end)

frame.scroll.list.Changed:Connect(function()
	if frame.scroll.list.AbsoluteContentSize.Y <= 40 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	end
end)

--//SEARCHING

function results()
	local term = string.lower(search.textbox.Text)

	for i, v in pairs(frame.scroll:GetChildren()) do
		if v:IsA("ImageButton") then
			if term ~= "" then
				local item = string.lower(v.details.command_name.Text)

				if string.find(item, term) then
					v.LayoutOrder = 2
				else
					v.LayoutOrder = 3
				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 1}):Play()
			else
				if v.Name == "plain_command" then
					v.LayoutOrder = 1

				elseif v.Name == "player_command" then
					v.LayoutOrder = 2

				elseif v.Name == "input_command" then
					v.LayoutOrder = 3

				elseif v.Name == "slider_command" then
					v.LayoutOrder = 4

				elseif v.Name == "input_slider_command" then
					v.LayoutOrder = 5

				elseif v.Name == "player_input_command" then
					v.LayoutOrder = 6

				elseif v.Name == "player_slider_command" then
					v.LayoutOrder = 7

				elseif v.Name == "player_input_slider_command" then
					v.LayoutOrder = 8

				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 0}):Play()
			end
		end
	end
end

search.textbox.Changed:Connect(results)

search.textbox.Focused:Connect(function()
	tween_service:Create(frame.scroll.search, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0}):Play()
end)

search.textbox.FocusLost:Connect(function()
	tween_service:Create(frame.scroll.search, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = .7}):Play()
end)

search.clear_button.MouseButton1Click:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
		search.textbox.Text = ""
		search.textbox:CaptureFocus()
	else
		search.textbox.Text = ""
	end
end)

search.clear_button.MouseEnter:Connect(function()
	if search.textbox.Text ~= "" then
		tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = .8}):Play()

		search.clear_button.background.gradient.Enabled = true
	end
end)

search.clear_button.InputEnded:Connect(function()
	tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = 1}):Play()

	search.clear_button.background.gradient.Enabled = false
end)

--// SETTING VISIBILITY

local allowed

local function set_visibility()
	for _, cc in pairs(frame.scroll:GetChildren()) do
		if cc:IsA("ImageButton") then
			local commandIdentifier = cc:GetAttribute("command_identifier")

			if commandIdentifier then
				cc.Visible = table.find(allowed, commandIdentifier) ~= nil
			else
				cc.Visible = false
			end
		end
	end
end

exe_storage.events.banit_events.send_allowed_CC.OnClientEvent:Connect(function(t)
	allowed = t
end)

frame.scroll.ChildAdded:Connect(set_visibility)
frame.scroll.ChildRemoved:Connect(set_visibility)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:tools_panels("custom_commands", false)
end)

--// HOVER

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(search.focused_bg, rev, {Offset = Vector2.new(.5, 0)}):Play()

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
	exe_module:tools_panels("custom_commands", false)
end)