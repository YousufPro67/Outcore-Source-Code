local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
API = knit.CreateService({
	Name = "PlayerMovement",
	Client = {},
	Players = {}
})
function API:Init(plr : Player)
	local hum = plr.Character:FindFirstChildWhichIsA('Humanoid')
	API.Players[plr] = {
		IntialSpeed = 0,
		MaxSpeed = 0,
		Acceleration = 0
	}
	hum.WalkSpeed = API.Players[plr].IntialSpeed
end
function API:GetCurrentSpeed(plr : Player)
	return  plr.Character:FindFirstChildOfClass('Humanoid').WalkSpeed
end
function API:Accelerate(plr : Player,bool : boolean)
	local hum = plr.Character:FindFirstChildOfClass('Humanoid')
	if bool then
		if hum.WalkSpeed < API.Players[plr].MaxSpeed then
			hum.WalkSpeed += API.Players[plr].Acceleration
		end
	else
		hum.WalkSpeed = API.Players[plr].MaxSpeed
	end
end
function API:SetSpeed(plr : Player,intial : number,max : number,accel : number)
	plr.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = intial
	API.Players[plr].IntialSpeed = intial
	API.Players[plr].MaxSpeed = max
	API.Players[plr].Acceleration = accel
end
function API:CheckIdle(plr)
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum:Humanoid = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildWhichIsA("Animator")

	if hum and animator then
		local isIdle = true

		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			if track.Name == "Running" then
				isIdle = false
				break
			end
		end

		if not isIdle or hum.MoveDirection.Magnitude > 0 then 
			
			return false
			
		else
			
			return true
		end
	else
		return true
	end
end



API.Client["SetSpeed"] = API.SetSpeed
return API