local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local environmentImpactTemplate = ReplicatedStorage.Blaster.Objects.EnvironmentImpact
local characterImpactTemplate = ReplicatedStorage.Blaster.Objects.CharacterImpact

local function impactEffect(position: Vector3, normal: Vector3, isCharacter: boolean)
	local impact
	if isCharacter then
		impact = characterImpactTemplate:Clone()
		impact.CFrame = CFrame.lookAlong(position, normal)
		impact.Parent = Workspace

		impact.SparkEmitter:Emit(10)
		impact.CircleEmitter:Emit(2)
	else
		impact = environmentImpactTemplate:Clone()
		impact.CFrame = CFrame.lookAlong(position, normal)
		impact.Parent = Workspace

		for _,v:ParticleEmitter in impact:GetChildren() do
			if v.Name ~= "SparkEmitter" and v.Name ~= "CircleEmitter" then
				if ReplicatedStorage.Blaster:GetAttribute("ActiveBlaster") == "Blaster" then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end
		end
		impact.SparkEmitter:Emit(10)
		impact.CircleEmitter:Emit(2)
	end

	task.delay(0.5, function()
		impact:Destroy()
	end)
end

return impactEffect
