-- A simple state machine implementation for hooking a ControllerManager to a Humanoid. 
-- Runs an update function on the PreAnimate event that sets ControllerManager movement inputs 
-- and checks for state transition events.
-- Creates a Jump action and "JumpImpulse" attribute on the ControllerManager.
local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local plrdataservice = knit.GetService("PlayerDataManager")
local clientdata = knit.GetService("ClientData")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("RunService")
local cas = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

local character = game.Players.LocalPlayer.Character
local cm:ControllerManager = character:WaitForChild("ControllerManager", 60)
local humanoid:Humanoid = character:WaitForChild("Humanoid", 60)
local hrp = character:WaitForChild("HumanoidRootPart", 60)

local jumping = false
local Sliding = false
local groundController = cm.GroundController
local climbcontroller = cm.ClimbController
local aircontroller = cm.AirController
local WallrunTiltSpeed = 1.5

local WallrunGoal = 0
local WallrunCurrentAngle = 0
local cam = workspace.CurrentCamera
local Wallrunning = false
local WallrunningNormal = Vector3.new(0, 0, 0)
local lastWallrun = 0
local holdingspace = false
local WallrunSFX = game.ReplicatedStorage.SFX.WallrunSFX
local WallrunParams = RaycastParams.new()
local WallrunSpeed = 100 * (humanoid.WalkSpeed /100)
local WallrunGravity = 5
local WallrunJumpPower = 60
local MaxWallrunRadius = 10
local WallrunCameraTiltAmount = 15
local WallrunCooldown = 0
WallrunParams.FilterType = Enum.RaycastFilterType.Include
WallrunParams.RespectCanCollide = true
WallrunParams.FilterDescendantsInstances = CollectionService:GetTagged('Wallrun')

local WallrunAttach = Instance.new("Attachment")
WallrunAttach.Parent = hrp

local WallrunVelocity = Instance.new("LinearVelocity")
WallrunVelocity.Parent = hrp
WallrunVelocity.MaxForce = math.huge
WallrunVelocity.Enabled = false
WallrunVelocity.Attachment0 = WallrunAttach

WallrunSFX.Looped = true

local Wallruntrack = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(script:WaitForChild("WallrunAnimation"))
local Wallruntrack2 = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(script:WaitForChild("WallrunAnimation2"))

local slidevfx1 = character["Right Arm"].SlideVFX:GetChildren()
local slidevfx2 = character["Left Leg"].SlideVFX:GetChildren()

local lastpos = hrp.Position
local PlayerData = plrdataservice:Get()
plrdataservice.OnDataChanged:Connect(function(data)
	PlayerData = data
end)

                    --|Setup|--

local slidevfxtable = {}
for _,vfx: ParticleEmitter in slidevfx1 do
	slidevfxtable[vfx] = vfx.Rate
end
for _,vfx: ParticleEmitter in slidevfx2 do
	slidevfxtable[vfx] = vfx.Rate
end

                    --|MAIN|--

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
	return hrp.Position.Y <= workspace.FallenPartsDestroyHeight + 50
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
	local currentPos = hrp.Position
	local delta = math.round((currentPos - lastpos).Magnitude)
	if isControllerActive(cm.GroundController) then
			if not PlayerData.STUDS then return end
			clientdata:SET("STUDS", PlayerData.STUDS + delta)
	end
	lastpos = currentPos
end

local track:AnimationTrack = humanoid.Animator:LoadAnimation(script.Animation)
local jumpanim:AnimationTrack = humanoid.Animator:LoadAnimation(script.Jump)
local slidesound = game.ReplicatedStorage.SFX.SlideSFX
slidesound.PlaybackSpeed = 0.5
slidesound:Play()
slidesound:Pause()

hrp.Touched:Connect(function(hit:BasePart)
	local Enemy = hit:FindFirstAncestorOfClass("Model")
	if not Enemy then return end
	local EHum = Enemy:FindFirstChildOfClass("Humanoid")
	if not EHum then return end
	if EHum.Health <= 0 then return end
	local ERoot = Enemy:FindFirstChild("HumanoidRootPart")
	if not ERoot then return end
	if (ERoot:HasTag("Enemy") and hrp.AssemblyLinearVelocity.Magnitude > 30) then
		EHum:TakeDamage(100)
		clientdata:SET("KILLS", PlayerData.KILLS + 1)
	end
end)

local function StartSlide() 
	Sliding = true
	groundController.Friction = 0.5
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

function Wallrun(val)
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.FallingDown then
		Wallrunning = false
	end
	if val then
		holdingspace = true
		if tick() - lastWallrun < WallrunCooldown then return end
		lastWallrun = tick()
		local right = workspace:Raycast(hrp.Position, hrp.CFrame.RightVector * MaxWallrunRadius, WallrunParams)
		if right then
			WallrunSFX:Play()
			Wallruntrack2:Stop(0.5)
			Wallruntrack:Play(0.5)
			Wallrunning = 1
			WallrunningNormal = Vector3.new(right.Normal.Z, 0, -right.Normal.X)
			WallrunGoal = WallrunCameraTiltAmount
		else
			local left = workspace:Raycast(hrp.Position, -hrp.CFrame.RightVector * MaxWallrunRadius, WallrunParams)
			if left then
				WallrunSFX:Play()
				Wallruntrack:Stop(0.5)
				Wallruntrack2:Play(0.5)
				Wallrunning = -1
				WallrunningNormal = Vector3.new(left.Normal.Z, 0, -left.Normal.X)
				WallrunGoal = -WallrunCameraTiltAmount
			end
		end
	else
		holdingspace = false
	end
end



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
			clientdata:SET("JUMPS", PlayerData.JUMPS + 1)
		end
		wait(0.1)
	end
end
UIS.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if input.KeyCode == Enum.KeyCode.E then
		if not gameProcessedEvent then StartSlide() end
	elseif input.KeyCode == Enum.KeyCode.Space then
		Wallrun(true)
		jumping = true
		doJump()
	end
end)
UIS.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if input.KeyCode == Enum.KeyCode.E then
		if not gameProcessedEvent then StopSlide() end
	elseif input.KeyCode == Enum.KeyCode.Space then
		Wallrun(false)
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
local function stepWallrun(dt)
	WallrunParams.FilterDescendantsInstances = CollectionService:GetTagged('Wallrun')
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.FallingDown then
		Wallrunning = false
	end

	if Wallrunning then
		WallrunVelocity.Enabled = true
		local result = workspace:Raycast(hrp.Position, hrp.CFrame.RightVector * MaxWallrunRadius * Wallrunning, WallrunParams)
		if result and holdingspace then
			WallrunningNormal = Vector3.new(result.Normal.Z, 0, -result.Normal.X)
			local v = WallrunningNormal * WallrunSpeed * -Wallrunning
			WallrunVelocity.VectorVelocity = Vector3.new(v.X, -WallrunGravity, v.Z)
		else
			local v = WallrunVelocity.VectorVelocity
			Wallrunning = false
			WallrunSFX:Stop()
			Wallruntrack:Stop(0.5)
			Wallruntrack2:Stop(0.5)
			WallrunVelocity.Enabled = false
			WallrunGoal = 0
			WallrunVelocity.VectorVelocity = Vector3.new(0, 0, 0)
			hrp.AssemblyLinearVelocity = Vector3.new(v.X,WallrunJumpPower,v.Z)
		end
	elseif WallrunVelocity.Enabled then
		WallrunVelocity.Enabled = false
		WallrunGoal = 0
		WallrunVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	end
end

RS.PreAnimation:Connect(stepController)
RS.Heartbeat:Connect(stepWallrun)
RS.PreRender:Connect(function()
	if not humanoid then return end
	for _,v in CollectionService:GetTagged("PlayerGroundAura") do
		v.Enabled = isControllerActive(cm.GroundController)
	end
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
	if Sliding then
		local human:BasePart = character:FindFirstChild("HumanoidRootPart")
		if not human then return end
		local v = human.AssemblyLinearVelocity.magnitude
		for _,vfx: ParticleEmitter in slidevfx1 do
			vfx.Enabled = true
			vfx.Rate = slidevfxtable[vfx] * math.clamp(v,1,100) / 100
		end
		for _,vfx: ParticleEmitter in slidevfx2 do
			vfx.Enabled = true
			vfx.Rate = slidevfxtable[vfx] * math.clamp(v,1,100) / 100
		end
	else
		for _,vfx: ParticleEmitter in slidevfx1 do
			vfx.Enabled = false
		end
		for _,vfx: ParticleEmitter in slidevfx2 do
			vfx.Enabled = false
		end
	end
end)

humanoid.HealthChanged:Connect(function()
	if humanoid.Health > 0 then
		local torso = character:FindFirstChild("Torso")
		if not torso then return end
		local aura:Attachment = torso:FindFirstChild("Aura")
		if not aura then return end
		aura.WorldOrientation = Vector3.zero
	else
		game.ReplicatedStorage.DeathEvent:FireServer()
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	end
end)
-----------------
-- Debug info ---

--humanoid.StateChanged:Connect(function(oldState, newState)
--	print("Change state: " .. tostring(newState) .. " | Change controller: " .. tostring(cm.ActiveController))
--end)

