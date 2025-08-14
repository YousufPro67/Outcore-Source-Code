local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local SettingService = knit.GetService("SettingService")
local TS = game:GetService('TweenService')
local THover : Color3 = script:GetAttribute('THover')
local IHover = script:GetAttribute('IHover')
local SBHover = script:GetAttribute('SBHover')
local Tsize = script:GetAttribute('Tsize')
local objects = script.Parent:GetDescendants()
local camera = workspace.CurrentCamera
local buttonhover = game.ReplicatedStorage.SFX.ButtonHover
local buttonactive = game.ReplicatedStorage.SFX.ButtonActive
local uiblur = game.Lighting.SecondaryGUIBlur


local function Hover(object : GuiButton)
	if object:IsA('TextButton') then
	local ti
	local to
	local hover_size = Tsize*1.1
	local tlabel = object:FindFirstChild("TextLabel")
		if tlabel then
			ti = {TS:Create(tlabel,TweenInfo.new(0.2),{TextColor3 = THover})}
			to = {TS:Create(tlabel,TweenInfo.new(0.2),{TextColor3 = Color3.new(1, 1, 1)})}
		else
			ti = {TS:Create(object,TweenInfo.new(0.2),{TextColor3 = THover})}
			to = {TS:Create(object,TweenInfo.new(0.2),{TextColor3 = Color3.new(1, 1, 1)})}
		end
		return ti,to
	elseif object:IsA('ImageButton') then
		
		local ti = {TS:Create(object.UIStroke,TweenInfo.new(0.2),{Transparency = 0}),TS:Create(object.CanvasGroup.Frame,TweenInfo.new(0.2),{Position = UDim2.new(0,0,0,0)})}
		local to = {TS:Create(object.UIStroke,TweenInfo.new(0.2),{Transparency = 1}),TS:Create(object.CanvasGroup.Frame,TweenInfo.new(0.2),{Position = UDim2.new(0,0,1,0)})}
		return ti,to
	end
	
end
local function Back(button : GuiButton)
	if button.Name == "BACK" then
		TS:Create(uiblur, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = 0}):Play()
		local GUI = button:WaitForChild("Parent2").Value
		SettingService:Set("campart",workspace.CameraParts:WaitForChild('MainCam'))
		TS:Create(GUI.CanvasGroup,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 1,Position = UDim2.new(-1,0,0,0)}):Play()
		wait(.5)
		script.Parent.MainGUI.Enabled = true
		GUI.Enabled = false
		TS:Create(script.Parent.MainGUI.CanvasGroup,TweenInfo.new(0.5),{GroupTransparency = 0,Position = UDim2.new(0,0,0,0)}):Play()
		wait(.5)
		
		
	end
end


local function checkgui()
	for _, obj in objects do
		if obj:IsA('GuiButton') then
			obj.MouseEnter:Connect(function()
				local ti ,_ = Hover(obj)
				buttonhover:Play()
				for _,t:Tween in ti do
					t:Play()
				end
			end)
			obj.MouseLeave:Connect(function()
				local _, to = Hover(obj)
				for _,t:Tween in to do
					t:Play()
				end
			end)
			obj.Activated:Connect(function()
				local _, to = Hover(obj)
				buttonactive:Play()
				for _,t:Tween in to do
					t:Play()
				end
				Back(obj)
			end)
		end
	end
end

script.Parent.DescendantAdded:Connect(function(child) 
	
	if child:IsA("ScreenGui") then
			for _, obj in child:GetDescendants() do
				if obj:IsA('GuiButton') then
					obj.MouseEnter:Connect(function()
						local ti ,_ = Hover(obj)
						buttonhover:Play()
					for _,t:Tween in ti do
						t:Play()
					end
					end)
					obj.MouseLeave:Connect(function()
						local _, to = Hover(obj)
					for _,t:Tween in to do
						t:Play()
					end
					end)
					obj.Activated:Connect(function()
						local _, to = Hover(obj)
						buttonactive:Play()
					for _,t:Tween in to do
						t:Play()
					end
						Back(obj)
					end)
				end
			end
		
	elseif child:IsA("ImageButton") then
		local obj = child
			if obj:IsA('GuiButton') then
				obj.MouseEnter:Connect(function()
					local ti ,_ = Hover(obj)
					buttonhover:Play()
					for _,t:Tween in ti do
						if not obj.Lock.Visible and not obj.ComingSoon.Visible then t:Play() end
					end
				end)
				obj.MouseLeave:Connect(function()
					local _, to = Hover(obj)
					for _,t:Tween in to do
					if not obj.Lock.Visible and not obj.ComingSoon.Visible then t:Play() end
					end
				end)
				obj.Activated:Connect(function()
					local _, to = Hover(obj)
					buttonactive:Play()
					for _,t:Tween in to do
					if not obj.Lock.Visible and not obj.ComingSoon.Visible then t:Play() end
					end
					Back(obj)
				end)
			end
		end
end)

checkgui()
--script.Parent.MainGUI.Enabled = false
script.Parent.MainGUI.Enabled = true