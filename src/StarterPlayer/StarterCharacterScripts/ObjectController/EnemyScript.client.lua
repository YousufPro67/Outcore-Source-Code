local KNIT = require(game:GetService("ReplicatedStorage").Packages.Knit)
KNIT.Start({ServicePromises = false}):await()
local PLAYER_SETTINGS_MANAGER = KNIT.GetService("SettingService")

local PLAYER_SETTINGS = PLAYER_SETTINGS_MANAGER:Get()
local RUN_SERVICE = game["Run Service"]
local CHARACTER: Model = game.Players.LocalPlayer.Character
local PLAYER_HUMANOID: BasePart = CHARACTER:WaitForChild("HumanoidRootPart", 20)
local TWEEN_SERVICE = game:GetService("TweenService")

local BULLET_SPEED = 100
local DELAY = 2
local DAMAGE = 100
local BULLET_COLOR = Color3.fromRGB(0, 170, 255)
local MAX_DIST = 300
local COLLIDER_RADIUS = 2

local CD = {}

local function SetValue(plr,value,settingname)
	if PLAYER_SETTINGS[settingname] then
		PLAYER_SETTINGS[settingname] = value
	end
end
PLAYER_SETTINGS_MANAGER.OnValueChanged:Connect(function(settingname,value)
	SetValue(game.Players.LocalPlayer, value, settingname)
end)

wait(3)
RUN_SERVICE.PreRender:Connect(function()
	if not workspace:FindFirstChild("OutcoreStorage") then return end
	for _, ENEMY: Model in workspace:FindFirstChild("OutcoreStorage").Enemies:GetChildren() do
		if ENEMY:IsA("Model") then
			if not CD[ENEMY] then
				CD[ENEMY] = false
			end
			local h:BasePart = ENEMY:FindFirstChild("HumanoidRootPart")
			if not h then continue end
			
			local hum:Humanoid = h.Parent:FindFirstChildOfClass("Humanoid")
			if hum.Health <= 0 then
				for _, v: BasePart in ENEMY:GetDescendants() do
					if not v:IsA("BasePart") then continue end
					local weld: Weld = v:FindFirstChild(v.Parent.Name)
					if weld then
						if weld:IsA("Weld") then
							v:Destroy()
						end
					end
					v.CanCollide = true
				end

				local etorso: BasePart = ENEMY:FindFirstChild("Torso")
				if not etorso then continue end
				if not etorso:FindFirstChildOfClass("BallSocketConstraint") then
					h.RootJoint:Destroy()
					for _, v in etorso:GetChildren() do
						if not v:IsA("Motor6D") then continue end

						local socket = Instance.new("BallSocketConstraint")
						local Attachment = Instance.new("Attachment")
						local Attachment2 = Instance.new("Attachment")

						Attachment.Parent = v.Part0
						Attachment.CFrame = v.C0
						Attachment2.Parent = v.Part1
						Attachment2.CFrame = v.C1

						socket.Enabled = true
						socket.Attachment0 = Attachment
						socket.Attachment1 = Attachment2
						socket.Parent = etorso
						socket.Name = v.Name
						
						v:Destroy()
					end
				end
			end
			if hum.Health <= 1 then continue end
			h.CFrame = CFrame.lookAt(h.Position, Vector3.new(PLAYER_HUMANOID.Position.X, h.Position.Y, PLAYER_HUMANOID.Position.Z))
			
			local dir = (h.Position - PLAYER_HUMANOID.Position).Unit
			local Head: BasePart = ENEMY.Head
			
			if CD[ENEMY] then continue end
			--raycast to the player
						
			if not workspace.SkyHop:FindFirstChild(PLAYER_SETTINGS.LEVEL_NAME) then continue end
			if not workspace.SkyHop[PLAYER_SETTINGS.LEVEL_NAME]:GetAttribute("EnemyCanShoot") then continue end
			local ray = workspace:Raycast(h.Position, -dir * MAX_DIST)
			
			if not ray then continue end
			if ray.Instance:IsDescendantOf(CHARACTER) then
				local Distance = (PLAYER_HUMANOID.Position - h.Position).Magnitude
				local Time = Distance/BULLET_SPEED
				if Distance > MAX_DIST then continue end
				
				--// Bullet stuff
				local Bullet: BasePart = Instance.new("Part")
				Bullet.Parent = workspace
				Bullet.Name = "Bullet"
				Bullet.CanCollide = false
				Bullet.CanQuery = false
				Bullet.CanTouch = false
				Bullet.Anchored = false
				Bullet.Material = Enum.Material.Neon
				Bullet.Color = BULLET_COLOR
				Bullet.Size = Vector3.new(0.2, 0.2, 0.7)
				Bullet.CFrame = CFrame.new(Head.Position, Head.Position + -dir)
				
				local Collider = Instance.new("Part")
				Collider.Parent = Bullet
				Collider.Name = "Collider"
				Collider.CanCollide = false
				Collider.Transparency = 1
				Collider.Shape = Enum.PartType.Ball
				Collider.Size = Vector3.new(COLLIDER_RADIUS, COLLIDER_RADIUS, COLLIDER_RADIUS)
				Collider.Massless = true
				
				local Weld = Instance.new("Weld", Bullet)
				Weld.Part0 = Bullet
				Weld.Part1 = Collider
				
				game.ReplicatedStorage.SFX.EnemyShoot:Play()
				--script.VFX.Shoot:Emit(script.VFX.Shoot:GetAttribute("EmitCount"))
				
				local Mover = Instance.new("BodyVelocity", Bullet)
				Mover.Velocity = -dir * BULLET_SPEED
				Mover.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				CD[ENEMY] = true
								
				Collider.Touched:Connect(function(hit)
					if hit:IsDescendantOf(ENEMY) then return end
					
					for _, x in script:GetChildren() do
						local fx = x:Clone()
						fx.Parent = Bullet
						fx:Emit(fx:GetAttribute("EmitCount"))
					end
					game.ReplicatedStorage.SFX.ShatterSFX:Play()
					
					--// Make Explosion
					local Explosion = Instance.new("Explosion")
					Explosion.Parent = workspace
					Explosion.Position = Bullet.Position
					Explosion.BlastRadius = 10
					Explosion.BlastPressure = 100000
					Explosion.DestroyJointRadiusPercent = 0
					Explosion.Visible = false
					Explosion.Hit:Connect(function(hit)
						if hit:IsDescendantOf(CHARACTER) then
							CHARACTER.Humanoid:TakeDamage(DAMAGE)
						end
					end)
					
					--//Destroy
					wait(0.1)
					Bullet:Destroy()
					Explosion:Destroy()
				end)
				
				Bullet.Destroying:Once(function()
					CD[ENEMY] = false
				end)
				
				game:GetService("Debris"):AddItem(Bullet, DELAY)
				
			end
		end
	end
end)
