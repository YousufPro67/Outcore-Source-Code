-- A simple state machine implementation for hooking a ControllerManager to a Humanoid.
-- Runs an update function on the PreAnimate event that sets ControllerManager movement inputs 
-- and checks for state transition events.
-- Creates a Jump action and "JumpImpulse" attribute on the ControllerManager.

local RS = game:GetService("RunService")
local cas = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")

local character = script.Parent
local cm:ControllerManager = character:WaitForChild("ControllerManager")
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart",5)

local jumping = false
local Sliding = false
local groundController = cm.GroundController
local climbcontroller = cm.ClimbController
local aircontroller = cm.AirController
local WallrunTiltSpeed = 1.5

local WallrunSignal = script.Parent:WaitForChild("WallrunSignal2")
local WallrunGoal = 0
local WallrunCurrentAngle = 0
local cam = workspace.CurrentCamera
local Wallrunserverscript = script.Parent:WaitForChild("WallrunScript")

local Wallruntrack = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(Wallrunserverscript:WaitForChild("Animation"))
local Wallruntrack2 = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(Wallrunserverscript:WaitForChild("Animation2"))

-- Returns true if the controller is assigned, in world, and being simulated
local function isControllerActive(controller : ControllerBase)
	return cm.ActiveController == controller and controller.Active
end

-- Returns true if the Buoyancy sensor detects the root part is submerged in water, and we aren't already swimming
local function checkSwimmingState()
	return character.HumanoidRootPart.BuoyancySensor.TouchingSurface and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming
end

-- Returns true if neither the GroundSensor or ClimbSensor found a Part and, we don't have the AirController active.
local function checkFreefallState()
	return (cm.GroundSensor.SensedPart == nil and cm.ClimbSensor.SensedPart == nil 
		and not (isControllerActive(cm.AirController) or character.HumanoidRootPart.BuoyancySensor.TouchingSurface))
		or humanoid:GetState() == Enum.HumanoidStateType.Jumping
end

-- Returns true if the GroundSensor found a Part, we don't have the GroundController active, and we didn't just Jump
local function checkRunningState()
	return cm.GroundSensor.SensedPart ~= nil and not isControllerActive(cm.GroundController) 
		and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
end

-- Returns true of the ClimbSensor found a Part and we don't have the ClimbController active.
local function checkClimbingState()
	return cm.ClimbSensor.SensedPart ~= nil and not isControllerActive(cm.ClimbController)
end

local function checkVoidState()
	return hrp.Position.Y <= workspace.FallenPartsDestroyHeight
end
-- The Controller determines the type of locomotion and physics behavior
-- Setting the humanoid state is just so animations will play, not required
local function updateStateAndActiveController()
	if checkSwimmingState() then
		cm.ActiveController = cm.SwimController
		humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	elseif checkClimbingState() then
		cm.ActiveController = cm.ClimbController
		humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
	elseif checkRunningState() then
		cm.ActiveController = cm.GroundController
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	elseif checkFreefallState() then
		cm.ActiveController = cm.AirController
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	if checkVoidState() then
		humanoid:TakeDamage(humanoid.MaxHealth)
	end
end

-- Take player input from Humanoid and apply directly to the ControllerManager.
local function updateMovementDirection()
	local dir = character.Humanoid.MoveDirection
	cm.MovingDirection = dir
    cm.BaseMoveSpeed = humanoid.WalkSpeed

	if dir.Magnitude > 0 then
		cm.FacingDirection = dir
	else

		if isControllerActive(cm.SwimController) then
			cm.FacingDirection = cm.RootPart.CFrame.UpVector
		else
			cm.FacingDirection = cm.RootPart.CFrame.LookVector
		end
	end

end

local track:AnimationTrack = humanoid.Animator:LoadAnimation(script.Animation)
local jumpanim:AnimationTrack = humanoid.Animator:LoadAnimation(script.Jump)
local slidesound = game.ReplicatedStorage.SFX.SlideSFX
slidesound.PlaybackSpeed = 0.5
slidesound:Play()
slidesound:Pause()
local function StartSlide() 
	Sliding = true
	groundController.Friction = 0.2
	groundController.MoveSpeedFactor = 0
	track:Play(0.5)
	slidesound:Resume()
	for _,obj:BasePart in game.CollectionService:GetTagged("Slide") do
		if obj:IsA("Part") then
			obj.CanCollide = false
		end
	end
end
local function StopSlide() 
	Sliding = false
	groundController.Friction = 2
	groundController.MoveSpeedFactor = 1
	track:Stop(0.5)
	slidesound:Pause()
	for _,obj:BasePart in game.CollectionService:GetTagged("Slide") do
		if obj:IsA("Part") then
			obj.CanCollide = true
		end
	end
end
WallrunSignal.Event:Connect(function(angle)
	WallrunGoal = angle
end)




-- Manage attribute for configuring Jump power
cm:SetAttribute("JumpImpulse", Vector3.new(0,humanoid.JumpPower*10,0))

-- Jump input
local function doJump()
	while jumping do
		if isControllerActive(cm.GroundController) and not Sliding then
			local jumpImpulse = cm:GetAttribute("JumpImpulse")
			cm.RootPart:ApplyImpulse(jumpImpulse)

			character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			jumpanim:Play()
			cm.ActiveController = cm.AirController

			-- floor receives equal and opposite force
			local floor = cm.GroundSensor.SensedPart
			if floor then
				floor:ApplyImpulseAtPosition(-jumpImpulse, cm.GroundSensor.HitFrame.Position)
			end
		end
		wait(0.1)
	end
end
UIS.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if input.KeyCode == Enum.KeyCode.E then
		if not gameProcessedEvent then StartSlide() end
	elseif input.KeyCode == Enum.KeyCode.Space then
		WallrunSignal:Fire(true)
		jumping = true
		doJump()
	end
end)
UIS.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if input.KeyCode == Enum.KeyCode.E then
		if not gameProcessedEvent then StopSlide() end
	elseif input.KeyCode == Enum.KeyCode.Space then
		WallrunSignal:Fire(false)
		jumping = false
	end
end)
--------------------------------
-- Main character update loop --
local function stepController(t, dt)

	if hrp:IsDescendantOf(character) then
		updateMovementDirection()

		updateStateAndActiveController()
	end

end
humanoid.HealthChanged:Connect(function(health)
	local hum:Humanoid = humanoid
	game.ReplicatedStorage.DeathEvent:FireServer()
	hum:ChangeState(Enum.HumanoidStateType.Dead)
end)
RS.PreAnimation:Connect(stepController)
RS.PreRender:Connect(function()
	local sign = WallrunGoal / math.abs(WallrunGoal)
	if WallrunCurrentAngle * sign < WallrunGoal * sign then
		WallrunCurrentAngle = WallrunCurrentAngle + sign * WallrunTiltSpeed
	elseif WallrunCurrentAngle ~= 0 then
		sign = WallrunCurrentAngle / math.abs(WallrunCurrentAngle)
		WallrunCurrentAngle = WallrunCurrentAngle - sign * WallrunTiltSpeed
	end
	if math.abs(WallrunCurrentAngle - WallrunGoal) <= WallrunTiltSpeed then 
		WallrunCurrentAngle = WallrunGoal 
	end
	cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(WallrunCurrentAngle))
end)

-----------------
-- Debug info ---

--humanoid.StateChanged:Connect(function(oldState, newState)
--	print("Change state: " .. tostring(newState) .. " | Change controller: " .. tostring(cm.ActiveController))
--end)

