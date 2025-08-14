local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local timeeffect = knit.GetController("TimeEffect")
local plrsetting = knit.GetService("SettingService")
local plrstate = knit.GetService("PlayerState")
local TweenService = game:GetService("TweenService")
local frame = script.Parent:WaitForChild("A")
local retry = frame.RETRY
local menu = frame.MENU
local cs = knit.GetService("CounterService")
local blur = nil

if script.Parent.Enabled then
	plrsetting:Set("RETRY", true)
	plrsetting:Set("follow",false)
	timeeffect:StopTime(true)
	blur = Instance.new("BlurEffect",game.Lighting)
	blur.Name = "MUIBlur"
end

local function CreateTween(instanc:CanvasGroup)
	local tweenout = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 1,Position = UDim2.new(-1,0,0,0)})
	local tweenin = TweenService:Create(instanc,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{GroupTransparency = 0,Position = UDim2.new(0,0,0,0)})	
	return tweenin,tweenout
end

for i,button in script.Parent.A:GetChildren() do
	 if button:IsA("TextButton") then
		button.Activated:Connect(function()
			timeeffect:StopTime(false)
			plrsetting:Set("RETRY", false)
			blur:Destroy()
			if button.Name == "RETRY" then
				plrstate:SpawnPlayer()
				plrsetting:Set("follow",true)
				script.Parent:Destroy()
				cs:StopTimer()
			elseif button.Name == "MENU" then
				plrstate:SpawnPlayer()
				plrsetting:Set("FOLLOW",true)
				plrsetting:Set("INGAME",false)
				plrsetting:Set("CAMPART",workspace.CameraParts:WaitForChild("MainCam"))
				workspace.CurrentCamera.CFrame = workspace.CameraParts:WaitForChild("MainCam").CFrame
				script.Parent.Parent.MainGUI.Enabled = true
				local tween,_ = CreateTween(script.Parent.Parent.MainGUI.CanvasGroup)
				tween:Play()
				script.Parent:Destroy()
				cs:StopTimer()
			end
		end)
	 end
end

script.Parent.Parent.ChildAdded:Connect(function()
	if script.Parent.Enabled == true then
		if plrsetting:Get().FINISHED then
			blur:Destroy()
			timeeffect:StopTime(false)
			script.Parent:Destroy()
		end
	end
end)