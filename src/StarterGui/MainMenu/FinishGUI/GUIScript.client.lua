local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local timeeffect = knit.GetController("TimeEffect")
local plrsetting = knit.GetService("SettingService")
local plrstate = knit.GetService("PlayerState")
local TweenService = game:GetService("TweenService")
local frame = script.Parent:WaitForChild("A",99)
local retry = frame.RETRY
local menu = frame.MENU
local cs = knit.GetService("CounterService")
local blur = nil
local uis = game:GetService("UserInputService")

if script.Parent.Enabled then
	plrsetting:Set("finished", true)
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

local function Next()
	local stage = plrsetting:Get().SPS
	if stage >= 9 then
		game.Players.LocalPlayer:Kick("You won! Now go touch grass.")
		print("player kicked to touch grass XD")
	else
		timeeffect:StopTime(false)
		blur:Destroy()
		plrsetting:Set("FOLLOW",true)
		plrsetting:Set("sps",stage + 1)
		plrstate:SpawnPlayer()
		script.Parent:Destroy()
		cs:StopTimer()
	end
end

uis.InputBegan:Connect(function(i,p)
	if p then return end
	if i.KeyCode ~= Enum.KeyCode.C then return end
	if not script.Parent.Enabled then return end
	Next()
end)

for i,button in script.Parent.A:GetChildren() do
	 if button:IsA("TextButton") then
		button.Activated:Connect(function()
			timeeffect:StopTime(false)
			blur:Destroy()
			plrsetting:Set("FOLLOW",true)
			plrsetting:Set("finished", false)
			if button.Name == "RETRY" then
				plrstate:SpawnPlayer()
				script.Parent:Destroy()
				cs:StopTimer()
			elseif button.Name == "MENU" then
				plrstate:SpawnPlayer()
				plrsetting:Set("INGAME",false)
				plrsetting:Set("CAMPART",workspace.CameraParts:WaitForChild("MainCam"))
				workspace.CurrentCamera.CFrame = workspace.CameraParts:WaitForChild("MainCam").CFrame
				script.Parent.Parent.MainGUI.Enabled = true
				local tween,_ = CreateTween(script.Parent.Parent.MainGUI.CanvasGroup)
				tween:Play()
				script.Parent:Destroy()
				cs:StopTimer()
			elseif button.Name == "NEXT" then
				Next()
			end
		end)
	 end
end
