local Workspace = game:GetService("Workspace")
local module = {}

local MAX_DISTANCE = 50 --studs

function module.raycastPositionToPart(position, part, ignoreList)
	local camera = Workspace.CurrentCamera

	if not camera then
		return nil
	end

	local origin = position
	local direction = (part.Position - origin).unit * MAX_DISTANCE
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ignoreList or {}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = false

	local raycastResult = workspace:Raycast(origin, direction, raycastParams)

	if raycastResult and raycastResult.Instance then
		return raycastResult.Instance
	else
		return false
	end
end

return module
