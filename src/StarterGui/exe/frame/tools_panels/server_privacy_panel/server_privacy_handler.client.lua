local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local starter_gui = game:GetService("StarterGui")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)

local exe_storage = replicated_storage.exe_storage
local events = exe_storage.events
local configuration = exe_storage.configuration
local exe_module = require(exe_storage:WaitForChild("exe_module"))

local frame = script.Parent
local background = frame.Parent

local close = frame.close
local scroll = frame.scroll

function format_uptime(seconds)
	local days = math.floor(seconds / (24 * 3600))
	local hours = math.floor((seconds % (24 * 3600)) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remaining_seconds = seconds % 60

	return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, remaining_seconds)
end

--// DIRECT ACTIONS

exe_storage.objects.uptime.Changed:Connect(function(value)
	scroll.status.server_uptime.value.Text = format_uptime(value)
end)

scroll.console.console.MouseButton1Click:Connect(function()
	local success, error = pcall(function()
		starter_gui:SetCore("DevConsoleVisible", true)
	end)

	if not success then
		warn("Error while setting Developer Console visibility:", error)
		
		exe_module:notify("There was an error upon opening Developer Console, please try again.", 3, "rbxassetid://11419713314")
	end
end)

scroll.shutdown.shutdown.MouseButton1Click:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
		events.banit_events.server_shutdown:FireServer()
	else
		exe_module:prompt_confirmation(true, "shutdown", "Close Down this Server?",
			"Shutting down the server will kick all the players and eventually will end the server.")
	end
end)

events.confirmation_events.confirmation_closed.Event:Connect(function(confirmed, id)
	if (id == "shutdown" and confirmed) then
		events.banit_events.server_shutdown:FireServer()
	end
end)

--// CORE NAVIGATIONS

function run()
	for i, privacy in pairs(scroll.privacy:GetChildren()) do
		if privacy:IsA("ImageButton") then
			
			privacy.MouseButton1Click:Connect(function()
				frame.properties.privacy.Value = privacy.Name:lower()
				
				if privacy.Name == "holders" then
					events.banit_events.server_lock:FireServer(true, true)
				elseif privacy.Name == "private" then
					events.banit_events.server_lock:FireServer(true, false)
				elseif privacy.Name == "public" then
					events.banit_events.server_lock:FireServer(false, false)
				end
			end)
		end
	end
end

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

run()
hover()

background.MouseButton1Click:Connect(function()
	exe_module:tools_panels("server_privacy", false)
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
	exe_module:tools_panels("server_privacy", false)
end)