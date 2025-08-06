local Raycast = {}
Raycast.__index = Raycast

--//

function Raycast.new(
	Params,
	Penetration,
	AllowCanCollideFalse,
	InvisiblePartsBlockRaycast,
	MaxPenetrations,
	MinTransparencyToBeInvisible
)
	local ray = {}
	ray.Parameters = Params or RaycastParams.new()
	ray.Penetration = Penetration or 0
	ray.AllowCanCollideFalse = AllowCanCollideFalse or false
	ray.InvisiblePartsBlockRaycast = InvisiblePartsBlockRaycast or false
	ray.MaxPenetrations = MaxPenetrations or 1
	ray.MinTransparencyToBeInvisible = MinTransparencyToBeInvisible or 1

	return setmetatable(ray, Raycast)
end

--//

function Raycast:Raycast(Origin, Direction)
	local CompletedRaycast = false
	local NumberPenetrations = 0
	local NumberChecks = 0
	local MaxChecks = 10000
	local FinalResult = nil

	while not CompletedRaycast do
		local RaycastResult = workspace:Raycast(Origin, Direction, self.Parameters)
		local NormalizedSize = RaycastResult and (RaycastResult.Instance.Size * RaycastResult.Normal)
		local Distance = RaycastResult and Direction.Unit * (RaycastResult.Position - Origin).Magnitude

		if NumberChecks == MaxChecks then
			break
		end

		local canCollideCheck, visibilityCheck, penetrateBecauseSmallSize, ignorePart

		if RaycastResult == nil then
			break
		else
			local transparency = RaycastResult.Instance.Transparency + (1 * RaycastResult.Instance.localTransparencyModifier)

			visibilityCheck = not self.InvisiblePartsBlockRaycast and transparency >= self.MinTransparencyToBeInvisible
			canCollideCheck = self.AllowCanCollideFalse and RaycastResult.Instance.CanCollide == false
			ignorePart = canCollideCheck or visibilityCheck

			penetrateBecauseSmallSize = NumberPenetrations < self.MaxPenetrations and NormalizedSize.Magnitude <= self.Penetration
		end

		if ignorePart then
			Origin = RaycastResult.Position - RaycastResult.Normal * 0.001
			Direction -= Distance
		elseif penetrateBecauseSmallSize then
			NumberPenetrations += 1
			Origin = RaycastResult.Position - RaycastResult.Normal * NormalizedSize.Magnitude * 0.999
			Direction -= Distance
		else
			FinalResult = RaycastResult
			CompletedRaycast = true
			break
		end

		NumberChecks += 1
	end

	return FinalResult, NumberPenetrations
end

--//

return Raycast
