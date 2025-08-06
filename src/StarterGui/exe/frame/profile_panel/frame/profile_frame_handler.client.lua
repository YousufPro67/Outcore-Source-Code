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

local configs = require(exe_storage.configuration):GET_CONFIGS()
local exe_module = require(exe_storage:WaitForChild("exe_module"))

local frame = script.Parent
local background = frame.Parent

local properties = background.properties

local close = frame.close
local scroll = frame.scroll

if not configs.PROFILE.humanoid_configs.health and not configs.PROFILE.humanoid_configs.jump and not configs.PROFILE.humanoid_configs.walkspeed then
	scroll.humanoid_actions.Visible = false
else
	scroll.humanoid_actions.health.Visible = configs.PROFILE.humanoid_configs.health
	scroll.humanoid_actions.jump.Visible = configs.PROFILE.humanoid_configs.jump
	scroll.humanoid_actions.walk.Visible = configs.PROFILE.humanoid_configs.walkspeed
end

scroll.visibility_actions.Visible = configs.PROFILE.visibility_actions
scroll.teleport_actions.Visible = configs.PROFILE.teleport_actions
scroll.teams_action.Visible = configs.PROFILE.teams_actions

--// DIRECT ACTIONS

scroll.direct_actions.kick.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
		exe_storage.events.banit_events.kick:FireServer(plr.Name)
	else
		exe_module:direct_panels("kick", true, plr)
	end
end)

scroll.direct_actions.ban.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	exe_module:direct_panels("ban", true, plr)
end)

scroll.direct_actions.notify.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	exe_module:direct_panels("notify", true, plr)
end)

scroll.direct_actions.jail.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	exe_module:direct_panels("jail", true, plr)
end)

--// TELEPORT ACTIONS

scroll.teleport_actions.follow.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	events.banit_events.teleport:FireServer("follow", plr)

	exe_module:profile_view(false)
	exe_module:notify("Successfully followed " .. plr.DisplayName .. "!", 3, "rbxassetid://12974362186")
end)

scroll.teleport_actions.bring.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	events.banit_events.teleport:FireServer("bring", plr)

	exe_module:profile_view(false)
	exe_module:notify("Successfully brought " .. plr.DisplayName .. "!", 3, "rbxassetid://12967404433")
end)

--// HUMANOID ACTIONS

scroll.humanoid_actions.health.MouseButton1Click:Connect(function()
	scroll.humanoid_actions.health.textbox.Visible = true
	scroll.humanoid_actions.health.textbox.Text = ""
	scroll.humanoid_actions.health.textbox:CaptureFocus()

	tween_service:Create(scroll.humanoid_actions.health.icon, info, {ImageTransparency = 1}):Play()	
	tween_service:Create(scroll.humanoid_actions.health.icon.scale, info, {Scale = 0}):Play()
end)

scroll.humanoid_actions.health.textbox.FocusLost:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)
	local num = tonumber(scroll.humanoid_actions.health.textbox.Text)

	if num and (num >= 0 and num <= 100) then
		events.banit_events.configure:FireServer(plr, "health", num)
	else
		exe_module:notify("Failed to apply.", 3, "rbxassetid://14187764914")
	end

	scroll.humanoid_actions.health.textbox.Visible = false

	tween_service:Create(scroll.humanoid_actions.health.icon, info, {ImageTransparency = .1}):Play()	
	tween_service:Create(scroll.humanoid_actions.health.icon.scale, info, {Scale = 1}):Play()
end)

--

scroll.humanoid_actions.jump.MouseButton1Click:Connect(function()
	scroll.humanoid_actions.jump.textbox.Visible = true
	scroll.humanoid_actions.jump.textbox.Text = ""
	scroll.humanoid_actions.jump.textbox:CaptureFocus()

	tween_service:Create(scroll.humanoid_actions.jump.icon, info, {ImageTransparency = 1}):Play()	
	tween_service:Create(scroll.humanoid_actions.jump.icon.scale, info, {Scale = 0}):Play()
end)

scroll.humanoid_actions.jump.textbox.FocusLost:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)
	local num = tonumber(scroll.humanoid_actions.jump.textbox.Text)

	if num and 
		(num >= configs.PROFILE.jump_min and num <= configs.PROFILE.jump_max) then

		events.banit_events.configure:FireServer(plr, "jump", num)
	else
		if num then
			exe_module:notify("Exceeds the minimum and maximum value.", 3, "rbxassetid://14187764914")
		else
			exe_module:notify("Failed to apply.", 3, "rbxassetid://14187764914")
		end
	end

	scroll.humanoid_actions.jump.textbox.Visible = false

	tween_service:Create(scroll.humanoid_actions.jump.icon, info, {ImageTransparency = .1}):Play()	
	tween_service:Create(scroll.humanoid_actions.jump.icon.scale, info, {Scale = 1}):Play()
end)

--

scroll.humanoid_actions.walk.MouseButton1Click:Connect(function()
	scroll.humanoid_actions.walk.textbox.Visible = true
	scroll.humanoid_actions.walk.textbox.Text = ""
	scroll.humanoid_actions.walk.textbox:CaptureFocus()

	tween_service:Create(scroll.humanoid_actions.walk.icon, info, {ImageTransparency = 1}):Play()	
	tween_service:Create(scroll.humanoid_actions.walk.icon.scale, info, {Scale = 0}):Play()
end)

scroll.humanoid_actions.walk.textbox.FocusLost:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)
	local num = tonumber(scroll.humanoid_actions.walk.textbox.Text)

	if num and 
		(num >= configs.PROFILE.walkspeed_min and num <= configs.PROFILE.walkspeed_max) then

		events.banit_events.configure:FireServer(plr, "walk", num)
	else
		if num then
			exe_module:notify("Exceeds the minimum and maximum value.", 3, "rbxassetid://14187764914")
		else
			exe_module:notify("Failed to apply.", 3, "rbxassetid://14187764914")
		end
	end

	scroll.humanoid_actions.walk.textbox.Visible = false

	tween_service:Create(scroll.humanoid_actions.walk.icon, info, {ImageTransparency = .1}):Play()	
	tween_service:Create(scroll.humanoid_actions.walk.icon.scale, info, {Scale = 1}):Play()
end)

--// VISIBILITY ACTIONS

scroll.visibility_actions.visi.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	events.banit_events.visibility:FireServer(true, plr)

	exe_module:profile_view(false)
	exe_module:notify(plr.DisplayName .. " is visible!", 3, "rbxassetid://11963367322")
end)

scroll.visibility_actions.invisi.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)

	events.banit_events.visibility:FireServer(false, plr)

	exe_module:profile_view(false)
	exe_module:notify(plr.DisplayName .. " is invisible!", 3, "rbxassetid://11419717224")
end)

--TEAMS ACTION

scroll.teams_action.team.MouseButton1Click:Connect(function()
	local plr = players:GetPlayerByUserId(properties.id.Value)
	
	exe_module:profile_view(false)
	exe_module:direct_panels("teams", true, plr)
end)

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and properties.id.Value ~= 0) then
		local plr = players:GetPlayerByUserId(properties.id.Value)

		if plr.Team then
			scroll.teams_action.team.value.Text = plr.Team.Name
		else
			scroll.teams_action.team.value.Text = "No Team"
		end
	end
end)

--// CORE NAVIGATIONS

function hover()
	for i, actions in pairs(scroll:GetDescendants()) do
		if actions:IsA("ImageButton") then

			actions.MouseEnter:Connect(function()
				tween_service:Create(actions, info, {ImageColor3 = Color3.fromRGB(53, 53, 53)}):Play()
			end)

			actions.MouseButton1Down:Connect(function()
				tween_service:Create(actions, info, {ImageColor3 = Color3.fromRGB(33, 33, 33)}):Play()
			end)

			actions.InputEnded:Connect(function()
				tween_service:Create(actions, info, {ImageColor3 = Color3.fromRGB(0, 0, 0)}):Play()
			end)
		end
	end
end

hover()

background.MouseButton1Click:Connect(function()
	exe_module:profile_view(false)
end)

--//HOVER

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
	exe_module:profile_view(false)
end)