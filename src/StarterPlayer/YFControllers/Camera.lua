local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
local module = knit.CreateController({
	Name = "Camera",
	tweennew = nil,
})
local de = false
local uis = game:GetService("UserInputService")
local UGS = UserSettings().GameSettings

function module.ControlCamera(FOLLOW:boolean, CAM:Camera, PLR:Player, FOV:number, IN_GAME:boolean, MOUSE:Mouse, CAM_PART:Part, CAM_SPEED:number, SHAKE:boolean, speedline)
	local cursorgui = game.Players.LocalPlayer.PlayerGui.Cursor
	if FOLLOW then
		de = false
		if not IN_GAME then
			PLR.Character:FindFirstChildOfClass("Humanoid").CameraOffset = Vector3.new(0,0,0)
			uis.MouseIconEnabled = true
			uis.MouseBehavior = Enum.MouseBehavior.Default
			cursorgui.Enabled = false
			CAM.FieldOfView = 70
			CAM.CameraType = Enum.CameraType.Scriptable
			PLR.CameraMinZoomDistance = 10
			PLR.CameraMode = Enum.CameraMode.Classic
			CAM.Focus = CAM_PART.CFrame
			CAM.CameraSubject = CAM_PART
			local newcframe = CAM_PART.CFrame  * CFrame.Angles(
				math.rad((((MOUSE.Y - MOUSE.ViewSizeY / 2) / MOUSE.ViewSizeY)) * -CAM_SPEED ),
				math.rad((((MOUSE.X - MOUSE.ViewSizeX / 2) / MOUSE.ViewSizeX)) * -CAM_SPEED ),
				0
			)
			
			local ts = game:GetService("TweenService")
			local tweenspeed = 1
			if (CAM.CFrame.Position - CAM_PART.CFrame.Position).magnitude == 0 then
				tweenspeed = 1
			else
				tweenspeed = (CAM.CFrame.Position - CAM_PART.CFrame.Position).magnitude * 0.025
			end
			module.tweennew = ts:Create(CAM,TweenInfo.new(1),{CFrame = newcframe})
			module.tweennew:Play()
		elseif IN_GAME then
			local human = PLR.Character:FindFirstChildOfClass("Humanoid")
			local humanroot:BasePart = PLR.Character:FindFirstChild("HumanoidRootPart")
			
			--/Mouse
			uis.MouseIconEnabled = false
			cursorgui.Enabled = true
			uis.MouseBehavior = Enum.MouseBehavior.LockCenter
			PLR.Character:FindFirstChildOfClass("Humanoid").CameraOffset = Vector3.new(0,-0.25,-1.5)
			
			--/SoundEffect
			local s,velocity = pcall(function()
				return humanroot.AssemblyLinearVelocity
			end)
			if not s then
				velocity = Vector3.new(0,0,0)
			end
			local Gain = math.clamp(velocity.magnitude, 0, 90)
			game.ReplicatedStorage.MUSIC.OutcoreGame.EqualizerSoundEffect.MidGain = 90 - Gain
			game.ReplicatedStorage.MUSIC.OutcoreGame.EqualizerSoundEffect.LowGain = 90 - Gain
			
			--/CameraSettings
			CAM.CameraSubject = PLR.Character:FindFirstChildOfClass("Humanoid")
			PLR.CameraMode = Enum.CameraMode.Classic
			CAM.FieldOfView = FOV - math.clamp((100 - velocity.Magnitude)/20, 0, 20)
			CAM.CameraType = Enum.CameraType.Custom
			UGS.RotationType = Enum.RotationType.CameraRelative
			
			local defaultval = PLR.CameraMaxZoomDistance
			PLR.CameraMinZoomDistance = 0.5
			local function shakeCamera(intensity)
				local shakeOffset = Vector3.new(
					math.random() * intensity - intensity / 2,
					math.random() * intensity - intensity / 2,
					math.random() * intensity - intensity / 2
				)
				CAM.CFrame = CAM.CFrame * CFrame.new(shakeOffset)
			end
			
			local CT = tick()

			if human.MoveDirection.Magnitude > 0 then
				local BobbleX = math.cos(CT*5)*0.25
				local BobbleY = math.abs(math.sin(CT*5))*0.25
				local Bobble = Vector3.new(BobbleX,BobbleY,0)
				human.CameraOffset = human.CameraOffset:lerp(Bobble, 0.25)
			else
				human.CameraOffset = human.CameraOffset * 0.75
			end
			--/CameraShake
			local speed = velocity.Magnitude
			if speed > 200 and SHAKE then
				local shakeIntensity = math.clamp(speed / 10000, 0, 1)
				shakeCamera(shakeIntensity)
			end
		end

	elseif not FOLLOW then
		local ts = game:GetService("TweenService")
		local speed = 20
		if not de then
			module.tweennew = ts:Create(CAM,TweenInfo.new(speed,Enum.EasingStyle.Cubic),{FieldOfView = math.clamp(CAM.FieldOfView-20,0,120)})
			module.tweennew:Play()
			de = true
		end
		uis.MouseIconEnabled = true
		cursorgui.Enabled = false
		PLR.CameraMode = Enum.CameraMode.Classic
		CAM.CameraType = Enum.CameraType.Fixed
		game:GetService('UserInputService').MouseBehavior = Enum.MouseBehavior.Default
	end

end
return module
