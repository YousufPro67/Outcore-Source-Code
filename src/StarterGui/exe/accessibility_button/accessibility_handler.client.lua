local tween_service = game:GetService("TweenService")
local input_service = game:GetService("UserInputService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local inst = TweenInfo.new(.01, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local exe_storage = replicated_storage:WaitForChild("exe_storage")

local frame = script.Parent
local button = frame.button

local page = button.page

local exe_module = require(exe_storage.exe_module)
local main_module = require(frame.Parent.exe_main_module)

local on_frame = false

local function accessibility(state)
	if state then
		page.page:JumpTo(page.options)

		--

		tween_service:Create(button, info, {Size = UDim2.fromOffset(270, 40)}):Play()

		tween_service:Create(button, info, {ImageTransparency = 0}):Play()
		tween_service:Create(button.scale, info, {Scale = 1.2}):Play()

		task.spawn(function()
			tween_service:Create(page.options.players.icon, inst, {ImageTransparency = 1}):Play()
			tween_service:Create(page.options.dashboard.icon, inst, {ImageTransparency = 1}):Play()
			tween_service:Create(page.options.recent.icon, inst, {ImageTransparency = 1}):Play()

			tween_service:Create(page.options.players.icon.scale, inst, {Scale = 0}):Play()
			tween_service:Create(page.options.dashboard.icon.scale, inst, {Scale = 0}):Play()
			tween_service:Create(page.options.recent.icon.scale, inst, {Scale = 0}):Play()

			--
			task.wait()
			--

			tween_service:Create(page.options.players.icon, quick, {ImageTransparency = 0}):Play()
			tween_service:Create(page.options.players.icon.scale, quick, {Scale = 1}):Play()

			--
			task.wait(.1)
			--

			tween_service:Create(page.options.dashboard.icon, quick, {ImageTransparency = 0}):Play()
			tween_service:Create(page.options.dashboard.icon.scale, quick, {Scale = 1}):Play()

			--
			task.wait(.1)
			--

			tween_service:Create(page.options.recent.icon, quick, {ImageTransparency = 0}):Play()
			tween_service:Create(page.options.recent.icon.scale, quick, {Scale = 1}):Play()

		end)
	else
		page.page:JumpTo(page.front)

		--

		tween_service:Create(button, info, {Size = UDim2.fromOffset(190, 40)}):Play()
	end
end

page.page:JumpTo(page.front)

button.page.front.open.MouseButton1Click:Connect(function()
	accessibility(true)
end)

button.page.options.players.MouseButton1Click:Connect(function()
	accessibility(false)
	
	main_module:exe_admin_panel(true)
	main_module:Go_To("Players")
end)

button.page.options.dashboard.MouseButton1Click:Connect(function()
	accessibility(false)
	
	main_module:exe_admin_panel(true)
	main_module:Go_To("Dashboard")
end)

button.page.options.recent.MouseButton1Click:Connect(function()
	local recent = page.options.recent
	
	accessibility(false)
	
	main_module:exe_admin_panel(true)
	
	if recent.func:GetAttribute("credits") then
		main_module:Go_To("Credits")
		
	elseif recent.func:GetAttribute("dashboard") then
		main_module:Go_To("Dashboard")
		
		exe_module:tools_panels(recent.func.panel.Value, true)
		
	elseif recent.func:GetAttribute("profile") then
		local plr = players:FindFirstChild(recent.func.player_name.Value)
		
		if plr then
			exe_module:profile_view(true, plr)
		else
			exe_module:notify("Failed to find the player.", 5, "rbxassetid://11433646681")
			
			--// ACCESSIBILITY BUTTON RECENT

			page.options.recent.icon.Image = "rbxassetid://11419720347"
			page.options.recent.icon.corner.CornerRadius = UDim.new(0, 0)

			page.options.recent.func:SetAttribute("profile", false)
			page.options.recent.func:SetAttribute("dashboard", false)
			page.options.recent.func:SetAttribute("credits", true)
		end
		
		main_module:Go_To("Players")
	end
end)

--

frame.MouseEnter:Connect(function()
	on_frame = true

	if not input_service.TouchEnabled then
		accessibility(true)
	end
end)

frame.MouseLeave:Connect(function()
	on_frame = false

	if not input_service.TouchEnabled then
		accessibility(false)
	end
end)

input_service.InputBegan:Connect(function()
	if not on_frame then
		
		accessibility(false)

		tween_service:Create(button, info, {ImageTransparency = .8}):Play()
		tween_service:Create(button.scale, info, {Scale = .7}):Play()

	end
end)

--

for i, options in pairs(page.options:GetChildren()) do
	if options:IsA("ImageButton") then

		options.MouseEnter:Connect(function()
			tween_service:Create(options.icon, quick, {ImageColor3 = Color3.fromRGB(255, 214, 10)}):Play()
			tween_service:Create(options.icon.scale, quick, {Scale = 1.4}):Play()
		end)

		options.MouseButton1Down:Connect(function()
			tween_service:Create(options.icon.scale, quick, {Scale = .7}):Play()
		end)

		options.InputEnded:Connect(function()
			tween_service:Create(options.icon, quick, {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			tween_service:Create(options.icon.scale, quick, {Scale = 1}):Play()
		end)
	end
end