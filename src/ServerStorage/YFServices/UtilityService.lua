local Knit = require(game.ReplicatedStorage.Packages.Knit)
local ts = game:GetService("TweenService")


local UtilityService = Knit.CreateService({
	Name = "UtilityService",
	Client = {}
})
UtilityService.Bouncepad = {}
UtilityService.BouncePads = {}


function UtilityService.Bouncepad.new(part, bounce, Mode)
	if not UtilityService.BouncePads[part] then
		UtilityService.BouncePads[part] = {
			Part = part,
			Bounce = {
					BounceForce = 0, 
					BounceMode = Mode,
					BounceFactor = 0,
					IsBouncing = false
				
			},
			Connections = {}
		}
		local function StartParticle(part0:Part)
			local particle = Instance.new("Part")
			particle.Name = "Particle"
			particle.Parent = part0
			particle.Position = part0.Position + Vector3.new(0, -0.1, 0)
			particle.CanCollide = false
			particle.CanTouch = false
			particle.CanQuery = false
			particle.Color = Color3.fromRGB(255,136,1)
			particle.Size = part0.Size
			particle.Transparency = 0.3
			particle.Anchored = true
			particle.Material = Enum.Material.Neon
			game.Debris:AddItem(particle, 0.8)
			
			local ti = TweenInfo.new(0.7, Enum.EasingStyle.Sine)
			local tween = ts:Create(particle, ti, {Size = particle.Size + Vector3.new(part0.Size.X, 0, part0.Size.Z), Transparency = 1, Position = part0.Position + Vector3.new(0, -10, 0)})
			tween:Play()
			part0.ParticleEmitter:Emit(10)
		end
		local function PlayerTouched(player)
			local hrp:BasePart = player.Character:WaitForChild("HumanoidRootPart")
			local bodyVel = hrp:FindFirstChildWhichIsA('BodyVelocity')
			if hrp and not bodyVel then
				if UtilityService.BouncePads[part].Bounce.BounceMode == "Static" then
					UtilityService.BouncePads[part].Bounce.BounceForce = bounce
					local newVel = Instance.new('BodyVelocity')
					newVel.Velocity = UtilityService.BouncePads[part].Bounce.BounceForce
					newVel.MaxForce = Vector3.new(7000000,7000000,7000000)
					newVel.P = 5000
					newVel.Parent = hrp
					StartParticle(UtilityService.BouncePads[part].Part)
					wait(1)
					newVel:Destroy()
				elseif UtilityService.BouncePads[part].Bounce.BounceMode == "Realistic" then
					UtilityService.BouncePads[part].Bounce.BounceFactor = bounce
					local bodyVelocity = Instance.new("BodyVelocity")
					local velocity = hrp.AssemblyLinearVelocity
					local factor  = UtilityService.BouncePads[part].Bounce.BounceFactor
					local bounceForce = Vector3.new(math.abs(velocity.X) * factor , math.abs(velocity.Y) * factor, math.abs(velocity.Z) * factor)
					bodyVelocity.Velocity = bounceForce
					bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bodyVelocity.Parent = hrp
					StartParticle(UtilityService.BouncePads[part].Part)
					
					game.Debris:AddItem(bodyVelocity, math.abs(velocity.Magnitude)*factor/1000)
				end

			end
		end
		UtilityService.BouncePads[part].Part.Touched:Connect(function(hit)
			if (hit.Parent:WaitForChild("Humanoid") or hit.Parent.Parent:WaitForChild("Humanoid")) and (game.Players:GetPlayerFromCharacter(hit.Parent) or game.Players:GetPlayerFromCharacter(hit.Parent.Parent)) then
				game.ReplicatedStorage.SFX.BounceSFX:Play()
				PlayerTouched(game.Players:GetPlayerFromCharacter(hit.Parent))
			end
		end)
	end
end


function UtilityService.Bouncepad.destroy(part)
	if UtilityService.BouncePads[part] then
		for _, conn in pairs(UtilityService.BouncePads[part].Connections) do
			conn:Disconnect()
		end
		UtilityService.BouncePads[part] = nil
	end
end


return UtilityService