local knit = require(game.ReplicatedStorage.Packages.Knit)
local input = require(game.ReplicatedStorage.Packages.Input)
knit.Start():await()
local timeeffect = knit.GetController("TimeEffect")
local plrsetting = knit.GetService("SettingService")
local plrstate = knit.GetService("PlayerState")
local TweenService = game:GetService("TweenService")
local retry = script.Parent.A.RETRY
local menu = script.Parent.A.MENU
local CounterService = knit.GetService("CounterService")
local Player: Player = game.Players.LocalPlayer

local blur = nil

input.Keyboard.new().KeyDown:Connect(function(key)
	if key == Enum.KeyCode.R then
		local data = plrsetting:Get()
		if data.INGAME and data.FOLLOW then
			CounterService:PauseTimer()
			plrsetting:Set("paused",true)
			plrsetting:Set("follow",false)
			timeeffect:StopTime(true)
			script.Parent.Enabled = true
			blur = Instance.new("BlurEffect",game.Lighting)
			blur.Name = "MUIBlur"
			Player.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
					local gui = script.Parent.Parent.RetryGUI:Clone()
					gui.Parent = script.Parent.Parent
					gui.Enabled = true
					script.Parent.Enabled = false
					blur:Destroy()
			end)
		else
			if plrsetting:Get().FINISHED or plrsetting:Get().RETRY then return end
			if blur then
				blur:Destroy()
			end 
			CounterService:StartTimer()
			timeeffect:StopTime(false)
			script.Parent.Enabled = false
			plrsetting:Set("follow",true)
			plrsetting:Set("Paused",false)
		end
	end
end)

local function CreateTween(instanc:CanvasGroup)
	local tweenout = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 1,Position = UDim2.new(-1,0,0,0)})
	local tweenin = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 0,Position = UDim2.new(0,0,0,0)})	
	return tweenin,tweenout
end

for i,button in script.Parent.A:GetChildren() do
	 if button:IsA("TextButton") then
		button.Activated:Connect(function()
			
			CounterService:StartTimer()
			blur:Destroy()
			timeeffect:StopTime(false)
			plrsetting:Set("FOLLOW",true)
			plrsetting:Set("Paused",false)
			
			if button.Name == "RETRY" then
				plrstate:SpawnPlayer()
				CounterService:StopTimer()
				script.Parent.Enabled = false
			elseif button.Name == "MENU" then
				plrstate:SpawnPlayer()
				plrsetting:Set("INGAME",false)
				plrsetting:Set("CAMPART",workspace.CameraParts:WaitForChild("MainCam"))
				workspace.CurrentCamera.CFrame = workspace.CameraParts:WaitForChild("MainCam").CFrame
				script.Parent.Parent.MainGUI.Enabled = true
				local tween,_ = CreateTween(script.Parent.Parent.MainGUI.CanvasGroup)
				tween:Play()
				script.Parent.Enabled = false
			elseif button.Name == "RESUME" then
				timeeffect:StopTime(false)
				script.Parent.Enabled = false
			end
		end)
	 end
end

local playersettings = plrsetting:Get()
plrsetting.callbackRE:Connect(function(settingn, value)
	playersettings[settingn] = value
end)

game["Run Service"].PreRender:Connect(function()
	if script.Parent.Enabled == true then
		if playersettings.FINISHED or playersettings.RETRY then
			script.Parent.Enabled = false
			blur:Destroy()
			timeeffect:StopTime(false)
		end
	end
end)