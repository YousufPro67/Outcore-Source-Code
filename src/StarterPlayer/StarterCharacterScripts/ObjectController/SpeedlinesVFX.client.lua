local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp:BasePart = character:WaitForChild("HumanoidRootPart",60)
local Speed_Lines;
local plrdataservice = knit.GetService("PlayerDataManager")

local plrdata = {}

plrdata = plrdataservice:Get()
plrdataservice.OnValueChanged:Connect(function(name,val)
	plrdata[name] = val
end)

local speedline = script:WaitForChild("Speed Lines", 60)
--if speedline then
--	if not workspace:FindFirstChild("Speed Lines") then
--		speedline:Clone().Parent = workspace
--	end
--	no = 0
--	for _,v in workspace:GetChildren() do
--		if v.Name == "Speed Lines" then
--			no += 1
--		end
--	end
--	if no >= 2 then
--		Speed_Lines = workspace:FindFirstChild("Speed Lines")
--	else
--		Speed_Lines = speedline:Clone()
--	end
--	Speed_Lines.Parent = workspace
--else
--	speedline = workspace:FindFirstChild("Speed Lines")
--	no = 0
--	for _,v in workspace:GetChildren() do
--		if v.Name == "Speed Lines" then
--			no += 1
--		end
--	end
--	if no >= 2 then
--		Speed_Lines = workspace:FindFirstChild("Speed Lines")
--	else
--		pcall(function()
--			Speed_Lines = speedline:Clone()
--		end)
--	end
--	pcall(function()
--		Speed_Lines.Parent = workspace
--	end)
--end
Speed_Lines = speedline:Clone()
Speed_Lines.Parent = workspace.VFX
--pos = Speed_Lines.Position
--Speed_Lines.CanQuery = false
--Speed_Lines.TopSurface = Enum.SurfaceType.Smooth
--Speed_Lines.Anchored = true
--Speed_Lines.CanTouch = false
--Speed_Lines.Size = Vector3.new(50.00, 50.00, 0.20)
--Speed_Lines.BottomSurface = Enum.SurfaceType.Smooth
--Speed_Lines.CanCollide = false
--Speed_Lines.Rotation = Vector3.new(92.93, 0.00, 0.00)
--Speed_Lines.BrickColor = BrickColor.new("Medium stone grey")
--Speed_Lines.Transparency = 1

local ParticleEmitter = Speed_Lines.ParticleEmitter
--ParticleEmitter.Lifetime = NumberRange.new(0.50, 0.50)
--ParticleEmitter.ZOffset = 5
--ParticleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
--ParticleEmitter.Squash = NumberSequence.new({
--	NumberSequenceKeypoint.new(0.00, 2.00, 0.00),
--	NumberSequenceKeypoint.new(1.00, 2.00, 0.00)
--})
--ParticleEmitter.Speed = NumberRange.new(80.00, 80.00)
--ParticleEmitter.Texture = "rbxassetid://17661312487"
--ParticleEmitter.Rotation = NumberRange.new(-90.00, -90.00)
--ParticleEmitter.LockedToPart = true
--ParticleEmitter.Rate = 100
--ParticleEmitter.EmissionDirection = Enum.NormalId.Back
--ParticleEmitter.Transparency = NumberSequence.new({
--	NumberSequenceKeypoint.new(0.00, 0.00, 0.00),
--	NumberSequenceKeypoint.new(1.00, 0.00, 0.00)
--})
ParticleEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
ParticleEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 2.00, 0.00),
	NumberSequenceKeypoint.new(1.00, 2.00, 0.00)
})
ParticleEmitter.Shape = Enum.ParticleEmitterShape.Disc
ParticleEmitter.LightEmission = 1
local Unit = Vector3.new(0,0,0)

local connection = game:GetService("RunService").Heartbeat:Connect(function()
	if plrdata.SHOW_SPEEDLINES then
		local velocity = hrp.AssemblyLinearVelocity
		local target
		if velocity.Magnitude > 1 then
			target = CFrame.lookAt(hrp.Position, hrp.Position + velocity.Unit) * CFrame.new(0, 0, -2)
			Speed_Lines.Position = hrp.Position + (Vector3.new(50,50,50) * velocity.Unit)
			Unit = velocity.Unit
			if Unit == nil then
				Unit = Vector3.new(0,0,0)
			end
		else
			target = CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector.Unit) * CFrame.new(0, 0, -2)
			Speed_Lines.Position = hrp.Position
		end
		Speed_Lines.CFrame = Speed_Lines.CFrame:Lerp(target, 0.1)
		--Speed_Lines.CFrame = target
		local keypoints = {
			NumberSequenceKeypoint.new(0, hrp.AssemblyLinearVelocity.Magnitude/100),
			NumberSequenceKeypoint.new(0.8, hrp.AssemblyLinearVelocity.Magnitude/100),
			NumberSequenceKeypoint.new(1, -2)  -- Optional, to define the end value
		}
		Speed_Lines.ParticleEmitter.Squash = NumberSequence.new(keypoints)
		Speed_Lines.ParticleEmitter.Rate = hrp.AssemblyLinearVelocity.Magnitude/10
		Speed_Lines.ParticleEmitter.Speed = NumberRange.new(hrp.AssemblyLinearVelocity.Magnitude/10)
		Speed_Lines.ParticleEmitter.Enabled = math.round(hrp.AssemblyLinearVelocity.Magnitude) > 90
		Speed_Lines.ParticleEmitter.Color = math.round(hrp.AssemblyLinearVelocity.Magnitude) > 250 and ColorSequence.new(Color3.fromRGB(255, 85, 0)) or ColorSequence.new(Color3.fromRGB(255, 255, 255))
		player.PlayerGui.SpeedrunTimer.Vignette_Game.Visible = math.round(hrp.AssemblyLinearVelocity.Magnitude) > 250
		for _, v in player.PlayerGui.SpeedrunTimer.FlameVFX:GetChildren() do
			v.Emitter:SetAttribute("Enabled", math.round(hrp.AssemblyLinearVelocity.Magnitude) > 250)
		end
		Speed_Lines.ParticleEmitter.LightEmission = math.round(hrp.AssemblyLinearVelocity.Magnitude) > 250 and 1 or 0
		Speed_Lines.ParticleEmitter.Brightness = math.round(hrp.AssemblyLinearVelocity.Magnitude) > 250 and 10 or 1
	end
end)

player.CharacterRemoving:Once(function()
	connection:Disconnect()
	Speed_Lines:Destroy()
end)
character:FindFirstChildOfClass("Humanoid").Died:Once(function()
	connection:Disconnect()
	player.PlayerGui.SpeedrunTimer.Vignette_Game.Visible = false
	for _, v in player.PlayerGui.SpeedrunTimer.FlameVFX:GetChildren() do
		v.Emitter:SetAttribute("Enabled", false)
	end
	Speed_Lines:Destroy()
end)


