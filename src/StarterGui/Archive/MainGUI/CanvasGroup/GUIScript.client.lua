local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local plrstates = knit.GetService("SettingService")
local buttons:{Instance} = script.Parent:GetDescendants()
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local plrdata = knit.GetService("PlayerDataManager")
local clientdata = knit.GetService("ClientData")
local uiblur = game.Lighting.SecondaryGUIBlur

local plrdatatable = plrdata:Get()
if plrdatatable.ABOUT_VERSION_CHECKED < script.Parent.Parent.Parent.AboutGUI:GetAttribute("Version") then
	script.Parent.Frame.ABOUT.New.Visible = true
else
	script.Parent.Frame.ABOUT.New.Visible = false
end

local function CreateTween(instanc:CanvasGroup)
	local tweenin = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 1,Position = UDim2.new(-1,0,0,0)})
	local tweenout = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 0,Position = UDim2.new(0,0,0,0)})	
	return tweenin,tweenout
end

local function ButtonTween()
	for _,button:TextButton in script.Parent.Frame:GetChildren() do
		if button:IsA("TextButton") then
			local tweenin = TweenService:Create(button.UIPadding,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{PaddingLeft = UDim.new(0.125,0), PaddingRight = UDim.new(-0.125,0)})
			local tweenout = TweenService:Create(button.UIPadding,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{PaddingLeft = UDim.new(0.025,0), PaddingRight = UDim.new(0.025,0)})	
			
			button.MouseEnter:Connect(function()
				tweenin:Play()
			end)
			button.MouseLeave:Connect(function()
				tweenout:Play()
			end)
		end
	end
end

local function OnButtonClicked(button  :  TextButton)
	if button.Name ~= "HELP" or button.Name ~= "DONATE" then
		TweenService:Create(uiblur, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = 50}):Play()
	end
	if button.Name == "PLAY" then
		plrstates:Set("campart",workspace.CameraParts:WaitForChild('PlayCam'))
		local tweenin,_ = CreateTween(script.Parent.Parent.CanvasGroup)
		tweenin:Play()
		tweenin.Completed:Wait()
		script.Parent.Parent.Parent.StagesGUI.Enabled = true
		local _,tweenout = CreateTween(script.Parent.Parent.Parent.StagesGUI.CanvasGroup)
		tweenout:Play()
		tweenout.Completed:Wait()
		script.Parent.Parent.Enabled = false
		
	elseif button.Name == "SETTINGS" then
		plrstates:Set("campart",workspace.CameraParts:WaitForChild('SettingsCam'))
		local tweenin,_ = CreateTween(script.Parent.Parent.CanvasGroup)
		tweenin:Play()
		tweenin.Completed:Wait()
		script.Parent.Parent.Parent.SettingsGUI.Enabled = true
		script.Parent.Parent.Enabled = false
		local _,tweenout = CreateTween(script.Parent.Parent.Parent.SettingsGUI.CanvasGroup)
		tweenout:Play()
		tweenout.Completed:Wait()
		
	elseif button.Name == "GAME MODES" then
		plrstates:Set("campart",workspace.CameraParts:WaitForChild('ModeCam'))
		local tweenin,_ = CreateTween(script.Parent.Parent.CanvasGroup)
		tweenin:Play()
		tweenin.Completed:Wait()
		script.Parent.Parent.Parent.GameModesGUI.Enabled = true
		script.Parent.Parent.Enabled = false
		local _,tweenout = CreateTween(script.Parent.Parent.Parent.GameModesGUI.CanvasGroup)
		tweenout:Play()
		tweenout.Completed:Wait()
		
	elseif button.Name == "ABOUT" then
		clientdata:SET("ABOUT_VERSION_CHECKED", script.Parent.Parent.Parent.AboutGUI:GetAttribute("Version"))
		script.Parent.Frame.ABOUT.New.Visible = false
		plrstates:Set("campart",workspace.CameraParts:WaitForChild('AboutCam'))
		local tweenin,_ = CreateTween(script.Parent.Parent.CanvasGroup)
		tweenin:Play()
		tweenin.Completed:Wait()
		script.Parent.Parent.Parent.AboutGUI.Enabled = true
		script.Parent.Parent.Enabled = false
		local _,tweenout = CreateTween(script.Parent.Parent.Parent.AboutGUI.CanvasGroup)
		tweenout:Play()
		tweenout.Completed:Wait()
		
	elseif button.Name == "DONATE" then
		script.Parent.Parent.Parent.DonateGUI.Enabled =
			not script.Parent.Parent.Parent.DonateGUI.Enabled
		uiblur.Enabled = not uiblur.Enabled
	elseif button.Name == "HELP" then
		script.Parent.Parent.Parent.HelpGUI.Enabled = true
		uiblur.Enabled = not uiblur.Enabled
	end
	
end

ButtonTween()
for _,button in buttons do
	if button:IsA("TextButton") then
		button.Activated:Connect(function()
			OnButtonClicked(button)
		end)
	end
end
