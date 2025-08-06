local knit = require(game.ReplicatedStorage.Packages.Knit)
local module = knit.CreateService({
	Name = "ExplosionService",
	Client = {}
})
function boomson(hit:Part, model)
	if hit:IsA("BasePart") then
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent) or game.Players:GetPlayerFromCharacter(hit.Parent.Parent)
		if plr then
			return
		end
	end
	local dir = (hit.Position - model.Main.Position).Unit
	if hit.Anchored==false and hit:FindFirstChild("fire")==nil and math.random(1,2)==1 then
		local fire = script.fire:Clone()
		if hit:GetMass()>10 then
			fire.Rate = (hit:GetMass())^0.7
		else
			fire.Rate = (hit:GetMass())*10
		end
		fire.Size = NumberSequence.new((hit:GetMass()^0.3)+1.75,0)
		fire.Acceleration = Vector3.new(0,(hit:GetMass()/15)+25,0)
		fire.Enabled=true
		fire.Script.Disabled=false
		fire.Parent = hit
	end
end

function module.Client:explode(plr, model: Model)
	if not module[model] then module[model] = {exploded = false} end
	if not module[model].exploded then
		module[model].exploded = true
		for _,v in model.Main:GetChildren() do
			if v:IsA("Weld") then
				v:Destroy()
			end
		end
		model.Main.dp:Emit(50)
		model.Main.dsp:Emit(50)
		model.Main.ds:Emit(50)
		model.Main.dp2:Emit(50)
		model.Main.dp3:Emit(50)
		local exp = Instance.new("Explosion")
		exp.Parent = game.Workspace
		exp.Position = model.Main.Position-Vector3.new(0,5,0) -- launch stuff upwards (looks cooler)
		exp.BlastRadius = 100
		exp.Visible=false
		exp.BlastPressure = 500000
		exp.DestroyJointRadiusPercent = 0
		model.Main.boeam:Play()
		model.Main.flames:Play()
		
		
		
	end
end


return module
