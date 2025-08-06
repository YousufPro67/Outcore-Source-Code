local CollectionService = game:GetService("CollectionService")

-- settings --
local Speed = 4000
local Gravity = 5
local JumpPower = 75
local MaxWallrunRadius = 10
local CameraTiltAmount = 15
local Cooldown = 0

-- script --
local char = script.Parent
local plr = game.Players:GetPlayerFromCharacter(char)
local HRP:BasePart = char:WaitForChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = CollectionService:GetTagged('Wallrun')

local Attach = Instance.new("Attachment")
Attach.Parent = HRP

local Velocity = Instance.new("LinearVelocity")
Velocity.Parent = HRP
Velocity.MaxForce = math.huge
Velocity.Enabled = false
Velocity.Attachment0 = Attach

local Signal = script.Parent:WaitForChild("WallrunSignal")
local RS = game:GetService("RunService")

local Wallrunning = false
local WallrunningNormal = Vector3.new(0, 0, 0)
local lastWallrun = 0
local track = nil
local track2 = nil
local holdingspace = false

local sfx = game.ReplicatedStorage.SFX.WallrunSFX
sfx.Looped = true

Signal.OnServerEvent:Connect(function(plr, val)
	if not track then
		track = plr.Character.Humanoid:LoadAnimation(script.Animation)
		track2 = plr.Character.Humanoid:LoadAnimation(script.Animation2)
	end

	if hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.FallingDown then
		Wallrunning = false
	end

	if val then
		holdingspace = true
		if tick() - lastWallrun < Cooldown then return end
		lastWallrun = tick()
		local right = workspace:Raycast(HRP.Position, HRP.CFrame.RightVector * MaxWallrunRadius, params)
		if right then
			sfx:Play()
			track2:Stop(0.5)
			track:Play(0.5)
			Wallrunning = 1
			WallrunningNormal = Vector3.new(right.Normal.Z, 0, -right.Normal.X)
			Signal:FireClient(plr, CameraTiltAmount)
		else
			local left = workspace:Raycast(HRP.Position, -HRP.CFrame.RightVector * MaxWallrunRadius, params)
			if left then
				sfx:Play()
				track:Stop(0.5)
				track2:Play(0.5)
				Wallrunning = -1
				WallrunningNormal = Vector3.new(left.Normal.Z, 0, -left.Normal.X)
				Signal:FireClient(plr, -CameraTiltAmount)
			end
		end
	else
		holdingspace = false
	end
end)

RS.Heartbeat:Connect(function(dt)
	if hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.FallingDown then
		Wallrunning = false
	end

	if Wallrunning then
		Velocity.Enabled = true
		local result = workspace:Raycast(HRP.Position, HRP.CFrame.RightVector * MaxWallrunRadius * Wallrunning, params)
		if result and holdingspace then
			local v = WallrunningNormal * Speed * -Wallrunning * dt
			Velocity.VectorVelocity = Vector3.new(v.X, -Gravity, v.Z)
		else
			Wallrunning = false
			sfx:Stop()
			track:Stop(0.5)
			track2:Stop(0.5)
			Velocity.Enabled = false
			Signal:FireClient(plr, 0)
			Velocity.VectorVelocity = Vector3.new(0, 0, 0)
			HRP.AssemblyLinearVelocity = Vector3.new(0,JumpPower,0)
		end
	elseif Velocity.Enabled then
		Velocity.Enabled = false
		Signal:FireClient(plr, 0)
		Velocity.VectorVelocity = Vector3.new(0, 0, 0)
	end
end)
