local Players = game:GetService("Players")

local function GetClosestPlayer(players: table, player: Player): Player
	local closestOwner, closestDistance
	for _, ownerId in players do
		local owner = Players:GetPlayerByUserId(ownerId)
		local distance = owner:DistanceFromCharacter(player.Character.HumanoidRootPart.Position)
		if closestDistance and distance >= closestDistance then
			continue
		end

		closestDistance = distance
		closestOwner = owner
	end

	return closestOwner
end

return GetClosestPlayer
