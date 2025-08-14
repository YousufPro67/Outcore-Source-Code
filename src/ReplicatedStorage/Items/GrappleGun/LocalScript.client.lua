local Loaded = false
script.Parent:WaitForChild("RemoteEvent").OnClientEvent:Once(function()
	Loaded = true
end)
while not Loaded do wait() end

local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local ClientDataManager = knit.GetService("ClientData")
local PlayerDataManager = knit.GetService("PlayerDataManager")
local Player:Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart", 60)
local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
local Animator: Animator = Humanoid:WaitForChild("Animator",5)
local Mouse = Player:GetMouse()

local Debounce = false
local IsMouseButton1Down = false
local IsMouseButton2Down = false
local Tool: Tool = script.Parent
local Shoot = Tool:WaitForChild('Handle')

local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local GrappleGunSoundEffect = game.ReplicatedStorage.SFX["Grappling Gun Fire"]
local TweenService = game:GetService("TweenService")
local IsEquiped

local Max_Distance = 600 -- This is the max length that the grapple hook can get to
local WinchSpeed = 25 -- Winch Speed.
local RopeVisible = true -- Is the rope visible?
local RopeColor = BrickColor.new("Black")

local HookDivider = 600
local HookAnimationSpeed = 0.25

local HookMainAnimation = Animator:LoadAnimation(script:WaitForChild("hookmain",5))
local HookStartAnimation = Animator:LoadAnimation(script:WaitForChild("hookstart",5))
local HookInitialAnimation = Animator:LoadAnimation(script:WaitForChild("hookinit",5))
local GrappleAnimation = Animator:LoadAnimation(script:WaitForChild("grapple",5))

local GrappleAim = workspace.VFX[Player.UserId.. "GrappleAim"]

local GrappleAimRotSpeed = 0
local ClawAnimation = Animator:LoadAnimation(script:WaitForChild("claw",5))

local SlashVFX1 = workspace.VFX:WaitForChild(Player.UserId.."VFXGrapple", 10):WaitForChild("vfx1",5)
local SlashVFX2 = workspace.VFX:WaitForChild(Player.UserId.."VFXGrapple", 10):WaitForChild("vfx2",5)


-- Calculate the distance between two Vector3 objects
local function distance_between_vectors(u, v)
	return (u - v).Magnitude
end

local function createAttachment(parent)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	return attachment
end

local function removeAttachment(parent)
	local attachment = parent:FindFirstChildOfClass("Attachment")
	if attachment then
		attachment:Destroy()
	end
end

local function GetRayTarget(origin, direction, radius, tag)
	-- First, if the mouse is directly over a tagged part, return it.
	if Mouse.Target and CollectionService:HasTag(Mouse.Target, tag) then
		return Mouse.Target
	end

	-- Create the region as before.
	local region = Region3.new(
		Vector3.new(
			math.min(origin.X, origin.X + direction.X) - radius,
			math.min(origin.Y, origin.Y + direction.Y) - radius,
			math.min(origin.Z, origin.Z + direction.Z) - radius
		),
		Vector3.new(
			math.max(origin.X, origin.X + direction.X) + radius,
			math.max(origin.Y, origin.Y + direction.Y) + radius,
			math.max(origin.Z, origin.Z + direction.Z) + radius
		)
	)

	local ignoreList = {Player.Character}
	local parts = workspace:FindPartsInRegion3WithIgnoreList(region, ignoreList, 100)
	local grappleparts = {}

	for _, part in ipairs(parts) do
		if CollectionService:HasTag(part, tag) then
			table.insert(grappleparts, part)
		end
	end

	local camera = workspace.CurrentCamera
	local mouseScreenPos = Vector2.new(Mouse.X, Mouse.Y)

	table.sort(grappleparts, function(p1, p2)
		local screenPos1 = camera:WorldToViewportPoint(p1.Position)
		local screenPos2 = camera:WorldToViewportPoint(p2.Position)
		local v1 = Vector2.new(screenPos1.X, screenPos1.Y)
		local v2 = Vector2.new(screenPos2.X, screenPos2.Y)
		return (v1 - mouseScreenPos).Magnitude < (v2 - mouseScreenPos).Magnitude
	end)

	return grappleparts[1]
end

local function HandleMouseButton(IsMouse1)
	if not Debounce and IsEquiped and Tool.Enabled then
		Debounce = true
		local mouseDown = IsMouse1 and IsMouseButton1Down or IsMouseButton2Down
		if not mouseDown then
			Debounce = false
			return
		end

		local RayOrigin = HumanoidRootPart.Position
		local RayDirection = (Mouse.Hit.Position - RayOrigin).Unit * Max_Distance
		local RayRadius = 3.75
		local TargetPart:BasePart = GetRayTarget(RayOrigin, RayDirection, RayRadius, IsMouse1 and "Grapple" or "Hook")

		if TargetPart then
			local HitPosition = TargetPart.Position
			local distance = distance_between_vectors(HitPosition, HumanoidRootPart.Position)
			if distance <= Max_Distance then
				GrappleGunSoundEffect:Play()
				local NewPart = Instance.new("Part")
				NewPart.Anchored = true
				NewPart.Parent = workspace
				NewPart.Position = HitPosition
				NewPart.Transparency = 1

				local attachment0 = createAttachment(NewPart)
				local attachment1 = createAttachment(Shoot)
				attachment1.Position = Vector3.new(0, 0.341, -1.24)
				local Rope;
				local Beam;
				local Tween;
				local Boost;
				
				if IsMouse1 then
					GrappleAim.Highlight.Adornee = TargetPart
					GrappleAim.BillboardGui.Adornee = TargetPart
					
					local AimSizeTween = TweenService:Create(GrappleAim.BillboardGui, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = UDim2.new(32, 0, 32, 0)})
					local AimColorTween = TweenService:Create(GrappleAim.BillboardGui.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {ImageColor3 = Color3.fromRGB(1, 136, 255)})
					AimSizeTween:Play()
					AimColorTween:Play()
					
					if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						GrappleAnimation:Play(0.5)
					end
					Rope = Instance.new("RopeConstraint")
					Rope.Parent = NewPart
					Rope.Attachment0 = attachment0
					Rope.Attachment1 = attachment1
					Rope.WinchEnabled = true
					Rope.WinchTarget = 5
					Rope.WinchForce = math.huge
					Rope.Restitution = 1
					Rope.Color = RopeColor
					Rope.Visible = RopeVisible
					Rope.Length = distance / 2
					Rope.WinchSpeed = 50
					Rope.Thickness = 0.5
					
					Boost = false
				else
					local HookSpeed = distance / HookDivider
					
					Beam = Instance.new("Beam")
					Beam.Parent = NewPart
					Beam.Attachment0 = attachment0
					Beam.Attachment1 = attachment1
					Beam.Width0 = 0.5
					Beam.Width1 = 0.5
					Beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
					Beam.LightEmission = 1
					
					local function HitEnemy(Target: BasePart)
						local HTweenInfo = TweenInfo.new(HookSpeed, Enum.EasingStyle.Linear)
						Tween = TweenService:Create(HumanoidRootPart, HTweenInfo, {CFrame = CFrame.new(Target.Parent.HumanoidRootPart.Position) * CFrame.Angles(math.rad(-TargetPart.Parent.HumanoidRootPart.CFrame.Rotation.X), math.rad(HumanoidRootPart.CFrame.Rotation.Y), math.rad(-TargetPart.Parent.HumanoidRootPart.Orientation.Z))})
						Target.Anchored = true
						Target.Parent:TranslateBy(HumanoidRootPart.CFrame.Rotation.LookVector.Unit * Vector3.new(7,0,7))
						Tween:Play()	

						local TweenCompleted = false
						local Canceled = false

						Tween.Completed:Once(function()
							TweenCompleted = true
						end)

						while not TweenCompleted do
							task.wait()
							if not (not IsMouse1 and IsMouseButton2Down) then
								Tween:Cancel()	
								Canceled = true
								break
							end
						end
						HookInitialAnimation:Stop()
						HookMainAnimation:Stop(0.2)
						local AimSizeTween = TweenService:Create(GrappleAim.BillboardGui, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = UDim2.new(40, 0, 40, 0)})
						local AimColorTween = TweenService:Create(GrappleAim.BillboardGui.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
						AimSizeTween:Play()
						AimColorTween:Play()

						GrappleAimRotSpeed = 0
						removeAttachment(NewPart)
						removeAttachment(Shoot)
						if Rope then
							Rope:Destroy()
							GrappleAnimation:Stop(0.5)
						elseif Beam then
							Beam:Destroy()
							Tween:Cancel()
						end
						if not Canceled then
							ClawAnimation:Play()
							task.wait(0.2)
							game.ReplicatedStorage.SFX.SlashSFX:Play()
							--slashvfx1.Rotation = Vector3.new(0,0,math.rad(HumanoidRootPart.Rotation.Z -45))
							SlashVFX1.Parent.Weld.C1 = CFrame.new(0,0,0) * CFrame.Angles(0,0,math.rad(35))
							SlashVFX1.Alpha.Rotation = NumberRange.new(HumanoidRootPart.CFrame.Rotation.LookVector.Z - 180)
							SlashVFX1.Colored.Rotation = NumberRange.new(HumanoidRootPart.CFrame.Rotation.LookVector.Z - 180)
							SlashVFX1.Slash.Rotation = NumberRange.new(HumanoidRootPart.CFrame.Rotation.LookVector.Z - 135)
							SlashVFX2.PointLight.Enabled = true
							for _,v in SlashVFX1:GetChildren() do
								if v:IsA("ParticleEmitter") then
									v:Emit(v:GetAttribute("EmitCount"))
								end
							end
							for _,v in SlashVFX2:GetChildren() do
								if v:IsA("ParticleEmitter") then
									v:Emit(v:GetAttribute("EmitCount"))
								end
							end
							Target.Parent:FindFirstChildOfClass("Humanoid").Health = 0
							--[[for _,v in Target.Parent:GetDescendants() do
								if not v:IsA("BasePart") then continue end
								v.CanCollide = false
							end]]
							ClientDataManager:SET("KILLS", PlayerDataManager:Get().KILLS + 1)
						end
						HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
						HumanoidRootPart.Anchored = false	
					
						NewPart:Destroy()
						task.wait(0.3)
						SlashVFX2.PointLight.Enabled = false
						TargetPart.Anchored = false
					end
					local function NormalHook(Target: BasePart)
						local ti = TweenInfo.new(HookSpeed, Enum.EasingStyle.Linear)
						Tween = TweenService:Create(HumanoidRootPart, ti, {CFrame = CFrame.new(NewPart.Position + Vector3.new(0,Target.Size.Y / 2,0) + Vector3.new(0, HumanoidRootPart.Parent["Right Leg"].Size.Y + 2,0))})
						Tween:Play()
						task.wait(HookAnimationSpeed)
						HookMainAnimation:Play(HookAnimationSpeed)
						HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
					end
					
					HookInitialAnimation:Play(HookAnimationSpeed)
					TargetPart.CanCollide = false
					HumanoidRootPart.Anchored = true
					local TargetHumanoid = TargetPart.Parent:FindFirstChildOfClass("Humanoid")
					if TargetHumanoid and TargetPart:HasTag("Enemy") then
						if TargetHumanoid.Health > 1 then
							HitEnemy(TargetPart)
						else
							HookInitialAnimation:Stop()
							HookMainAnimation:Stop(0.5)
						end
					else
						NormalHook(TargetPart)
					end
				end
				if Tween then
					Tween.Completed:Connect(function()
						HookInitialAnimation:Stop()
						HookMainAnimation:Stop(0.5)
					end)
				end
				game.UserInputService.InputBegan:Connect(function(i,p)
					if not p and i.KeyCode == Enum.KeyCode.F then
						if IsMouse1 and IsMouseButton1Down then
							Boost = true
						end
					end
				end)
				game.UserInputService.InputEnded:Connect(function(i,p)
					if not p and i.KeyCode == Enum.KeyCode.F then
						if IsMouse1 and IsMouseButton1Down then
							Boost = false
						end
					end
				end)
				while (IsMouse1 and IsMouseButton1Down or not IsMouse1 and IsMouseButton2Down) do
					wait()
					if IsMouseButton1Down and IsMouse1 then
						local motor:Motor6D = Character.Torso:FindFirstChild("Right Shoulder")
						local socket:BallSocketConstraint = Character.Torso:FindFirstChild("GrappleSwing")
						socket.Enabled = true
						motor.Enabled = false
						
						if Boost then
							if Rope.WinchSpeed <= 200 then
								Rope.WinchSpeed = Rope.WinchSpeed + 10
							end
						else
							Rope.WinchSpeed = 50
						end
						GrappleAimRotSpeed = Rope.WinchSpeed
					end
				end
				local motor:Motor6D = Character.Torso:FindFirstChild("Right Shoulder")
				local socket:BallSocketConstraint = Character.Torso:FindFirstChild("GrappleSwing")
				socket.Enabled = false
				motor.Enabled = true
				local aimsizetween = TweenService:Create(GrappleAim.BillboardGui, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = UDim2.new(40, 0, 40, 0)})
				local aimcolortween = TweenService:Create(GrappleAim.BillboardGui.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
				aimsizetween:Play()
				aimcolortween:Play()
				
				GrappleAimRotSpeed = 0
				removeAttachment(NewPart)
				removeAttachment(Shoot)
				if Rope then
					Rope:Destroy()
					GrappleAnimation:Stop(0.5)
				elseif Beam then
					Beam:Destroy()
					if Tween then
						Tween:Cancel()
					end
					HumanoidRootPart.Anchored = false
					TargetPart.CanCollide = true
					HookMainAnimation:Stop(0.5)
				end
				NewPart:Destroy()
			else
				
			end
		end
		Debounce = false
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then	
		IsMouseButton1Down = true
		HandleMouseButton(true)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		IsMouseButton2Down = true
		HandleMouseButton(false)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsMouseButton1Down = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		IsMouseButton2Down = false
	end
end)


Tool.Equipped:Connect(function()
	IsEquiped = true
end)
Tool.Unequipped:Connect(function()
	IsEquiped = false
end)

local connection = game["Run Service"].PreRender:Connect(function(dt)
	if not GrappleAim:FindFirstChild("BillboardGui") then return end
	GrappleAim.BillboardGui.ImageLabel.Rotation = GrappleAim.BillboardGui.ImageLabel.Rotation + (dt * GrappleAimRotSpeed)

	if not IsEquiped then 
		GrappleAim.Highlight.Enabled = false
		GrappleAim.HookHighlight.Enabled = false
		GrappleAim.BillboardGui.Enabled = false
	else
		GrappleAim.HookHighlight.Enabled = true
		GrappleAim.Highlight.Enabled = true
		GrappleAim.BillboardGui.Enabled = true
	end
	if IsMouseButton1Down or IsMouseButton2Down then return end
	local origin = HumanoidRootPart.Position
	local direction = (Mouse.Hit.Position - origin).Unit * Max_Distance
	local radius = 3.75
	local istarget:BasePart = GetRayTarget(origin, direction, radius, "Grapple")
	local ishooktarget:BasePart = GetRayTarget(origin, direction, radius, "Hook")
	
	GrappleAim.Highlight.Adornee = istarget
	GrappleAim.BillboardGui.Adornee = istarget
	GrappleAim.HookHighlight.Adornee = ishooktarget and (ishooktarget.Parent:IsA("Model") and ishooktarget.Parent or ishooktarget)
	if GrappleAim.BillboardGui.Adornee == istarget then return end
	GrappleAim.BillboardGui.ImageLabel.Rotation = 0
	--script.Parent.RemoteEvent:FireServer(istarget)
end)

script.Destroying:Connect(function()
	connection:Disconnect()
end)