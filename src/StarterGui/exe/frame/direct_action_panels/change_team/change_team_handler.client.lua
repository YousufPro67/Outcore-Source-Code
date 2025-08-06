local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local teams_service = game:GetService("Teams")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local background = frame.Parent

local close = frame.close

function add(team:Team)
	local template = frame.scroll.list.team:Clone()

	template.Name = team.Name
	template.Parent = frame.scroll
	template.Size = UDim2.new(0, 0, 0, 40)

	template.properties.team.Value = team

	template.team_color.BackgroundColor3 = team.TeamColor.Color
	template.team_name.Text = team.Name

	--

	tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 40)}):Play()
end

function fetch_teams()
	for i, teams in pairs(teams_service:GetChildren()) do
		if teams:IsA("Team") then
			add(teams)
		end
	end
	
	if #teams_service:GetChildren() > 0 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then

			items.MouseButton1Click:Connect(function()
				local plr = players:GetPlayerByUserId(background.properties.id.Value)

				banit_events.change_team:FireServer(plr, items.properties.team.Value)
				
				exe_module:direct_panels("teams", false)
			end)
			
			items.MouseEnter:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(110, 110, 111)}):Play()
			end)
			
			items.MouseButton1Down:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(71, 71, 72)}):Play()
			end)
			
			items.InputEnded:Connect(function()
				tween_service:Create(items, info, {BackgroundColor3 = Color3.fromRGB(93, 93, 94)}):Play()
			end)
		end
	end
end

local opened = 0

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and background.page.CurrentPage == frame and opened == 0) then
		opened += 1

		exe_module:prompt_resync(true, "Fetching...")

		--

		task.wait(.5)

		--

		fetch_teams()
		run()

		--

		task.wait(Random.new():NextNumber(.5, 1))

		--

		exe_module:prompt_resync(false)
	end
end)

--

frame.scroll.list.Changed:Connect(function()
	if frame.scroll.list.AbsoluteContentSize.Y <= 0 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	end
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:direct_panels("teams", false)
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
	exe_module:direct_panels("teams", false)
end)