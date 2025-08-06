local knit = require(game.ReplicatedStorage.Packages.Knit)
local module = {
	Name = "PlayerPositionService"
}
local Player = game:GetService("Players").LocalPlayer

function module:FilterSpawn(Filtertype: string, SP: {Instances}, SPoints: Instance)
	for _,spoint in SPoints:GetDescendants() do
		if spoint:IsA("SpawnLocation") then
			if Filtertype == "Include" then
				if SP[spoint] then 
					spoint.Enabled = true
				else
					spoint.Enabled = false
				end
			elseif Filtertype == "Exclude" then
				if SP[spoint] then
					spoint.Enabled = false
				else
					spoint.Enabled = true
				end
			end
		end
	end
end

function module:onPlayerRespawn(IN_GAME: boolean, SPSetter: number, SPoints: {Instances})
	if IN_GAME then
		Player.RespawnLocation = SPoints[SPSetter]
	else
		Player.RespawnLocation = SPoints[1]
	end
	return SPSetter
end

return module
