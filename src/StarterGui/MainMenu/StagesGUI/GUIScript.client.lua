local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local PLRSERVICE = knit.GetService("PlayerState")
local SettingService = knit.GetService("SettingService")
local plrdataservice = knit.GetService("PlayerDataManager")
local gui = script.Parent
local canvas = gui.CanvasGroup
local frame = canvas.Frame.Frame
local TweenService = game:GetService("TweenService")
local uiblur = game.Lighting.SecondaryGUIBlur

local Quests = {}
local names = {
	{Name = "Tutorial",ImageId = "rbxassetid://125139323160390"},
	{Name = "Practice",ImageId = "rbxassetid://19006052513"},
	{Name = "Sandbox2",ImageId = "rbxassetid://19006052223"},
	{Name = "Sandbox3",ImageId = "rbxassetid://19006051974"},
	{Name = "Sandbox4",ImageId = "rbxassetid://19006051164"},
	{Name = "Sandbox5",ImageId = "rbxassetid://132072861772725"},
	{Name = "Sandbox6",ImageId = "rbxassetid://92504859742564"},
	{Name = "Sandbox7",ImageId = "rbxassetid://139500922637947"},
	{Name = "Sandbox8",ImageId = "rbxassetid://129039314417013"}
}

local plrdata = plrdataservice:Get()
plrdataservice.OnValueChanged:Connect(function(name,val)
	plrdata[name] = val
	if name == "LEVELS" then
		for _,button in frame.Dimensions.Sandbox:GetChildren() do
			if not button:IsA("ImageButton") then
				continue
			end
			if button.ZIndex > 9 then
				button.ComingSoon.Visible = true
			else
				if button.ZIndex > plrdata.LEVELS then
					button.CanvasGroup.Visible = false
					button.Lock.Visible = true
				else
					button.CanvasGroup.Visible = true
					button.Lock.Visible = false
				end
			end
		end
	end
end)

game.ReplicatedStorage.RemoteEvents.UpdateButton.OnClientEvent:Connect(function(i,timer) 
	for _,OrignalButton in frame.Dimensions.Sandbox:GetChildren() do
		if OrignalButton.Name == "Button"..i then
			if timer then
				OrignalButton.CanvasGroup.Frame.BESTTIME.Text = timer
			end
		end
	end
end)

for i = 1, 9 do
	button = frame.Dimensions.Sandbox.Button:Clone()
	button.Parent = frame.Dimensions.Sandbox
	button.Name = "Button"..i
	button.ZIndex = i
	button.CanvasGroup.Frame.TextLabel.Text = names[i].Name
	local timer = plrdata.BEST_TIMES[i]
	if timer then
		button.CanvasGroup.Frame.BESTTIME.Text = timer
	else
		button.CanvasGroup.Frame.BESTTIME.Text = "--:--:--"
	end
	if button.ZIndex > 9 then
		button.ComingSoon.Visible = true
	else
		if button.ZIndex > plrdata.LEVELS then
			button.CanvasGroup.Visible = false
			button.Lock.Visible = true
		else
			button.CanvasGroup.Visible = true
			button.Lock.Visible = false
		end
	end
	if tostring(names[i].ImageId) then
		button.Image = names[i].ImageId
	end 
end

frame.Dimensions.Sandbox.Button:Destroy()

for i,button in frame.Dimensions.Sandbox:GetChildren() do
	if button:IsA('ImageButton') then
		button.MouseButton1Click:Connect(function()
			if not button.Lock.Visible and not button.ComingSoon.Visible then
				uiblur.Size = 0
				SettingService:Set("sps",button.ZIndex)
				SettingService:Set("ingame",true)
				PLRSERVICE:SpawnPlayer()
				TweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {GroupTransparency = 1}):Play()
				TweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {Position = UDim2.new(-1, 0, 0, 0)}):Play()
				wait(.5)
				script.Parent.Enabled = false
			end
		end)
	end
end

--//QUESTS
local QuestB = script.Parent.CanvasGroup.Quests

QuestB.MouseButton1Click:Connect(function()
	local qf = QuestB.Parent.Frame.Frame
	local color1 = ColorSequence.new(Color3.fromRGB(255,85,0), Color3.fromRGB(255,170,0))
	local color2 = ColorSequence.new(Color3.fromRGB(255,51,51))
	local ispagequest = qf.UIPageLayout.CurrentPage == qf.Quests
	qf.UIPageLayout:JumpTo(ispagequest and qf.Dimensions or qf.Quests)
	QuestB.UIGradient.Color = not ispagequest and color2 or color1
	QuestB.CanvasGroup.Icon.Visible = ispagequest
	QuestB.CanvasGroup.Icon2.Visible = not ispagequest
end)

local template = QuestB.Parent.Frame.Frame.Quests.ScrollingFrame.Frame
local function CheckQuest(tquest:Frame, quest)
	local pbar:Frame = tquest.Frame.Frame

	if quest.COMPLETED then
		pbar.Size = UDim2.new(1,0,1,0)
		tquest.BackgroundColor3 = Color3.fromRGB(0,198,96)
		pbar.BackgroundColor3 = Color3.fromRGB(0,150,70)
	else
		tquest.TextLabel.Text = string.format(quest.CONTEXT, quest.CURRENT_VALUE, quest.GOAL)
		pbar.Size = UDim2.new(quest.CURRENT_VALUE > 0 and quest.CURRENT_VALUE/quest.GOAL or 0,0,1,0)
	end
	return quest.COMPLETED
end

local questframes = {}
local function MakeQuests(Dimension)
	local qs = plrdata.DIMENSIONS[Dimension].QUESTS
	for n, q in pairs(qs) do
		local exists = false
		for _, questobj in pairs(questframes) do
			if questobj.Name == n then
				exists = true
				break
			end
		end

		if not exists then
			local newq = template:Clone()
			newq.Visible = true
			newq.Goal.Value = q.GOAL
			newq.TextLabel.Text = string.format(q.CONTEXT, q.CURRENT_VALUE, q.GOAL)
			newq.Name = n
			newq.Icon.Image = q.ICON
			newq.Parent = template.Parent
			table.insert(questframes, newq)
			CheckQuest(newq, q)
		end
	end
	return questframes
end

--1 = speed, 2 = jumps, 3 = finishes, 4 = kills
Quests["SKYHOP"] = MakeQuests("SKYHOP")

plrdataservice.OnDataChanged:Connect(function()
	Quests["SKYHOP"] = MakeQuests("SKYHOP")
end)
template.Visible = false

game.ReplicatedStorage.RemoteEvents.UpdateQuests.OnClientEvent:Connect(function()
	for _,v in Quests["SKYHOP"] do
		--print(v)
		CheckQuest(v, plrdata.DIMENSIONS["SKYHOP"].QUESTS[v.Name])
	end
end)