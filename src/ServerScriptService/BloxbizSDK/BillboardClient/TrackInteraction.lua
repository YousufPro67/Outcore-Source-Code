--[[local Tracker = {}

local Workspace = game:GetService('Workspace')
local LocalPlayer = game:GetService('Players').LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Raycast = require(script.Parent.Raycast)

local ConfigReader = require(script.Parent.Parent.ConfigReader)
local DebugAPI

if ConfigReader:read("DebugModeInteractions") then
	DebugAPI = require(ConfigReader:read("DebugAPI")())
end

local function getCornerScreenPoints(part)
	local FaceToCorners = require(script.Parent.FaceToCorners)
	local adCorners = FaceToCorners[part.AdSurfaceGui.Face]

	local corners = {}

	for _, Vector in ipairs(adCorners) do
		local CornerPos = (part.CFrame * CFrame.new(part.size.X/2 * Vector[1], part.size.Y/2 * Vector[2], part.size.Z/2 * Vector[3])).Position
		table.insert(corners, CornerPos)
	end

	return corners
end

local function raycastFromCamera(position)
	local Params = RaycastParams.new()
	local raycastFilterList = {}
	Params.FilterType = Enum.RaycastFilterType.Blacklist
	Params.FilterDescendantsInstances = raycastFilterList

	local ray = Raycast.new(Params, 0, false, false, 0)

	local cf = workspace.CurrentCamera and workspace.CurrentCamera.CFrame
	
	if not cf then
		return nil
	end
	
	local origin = cf.Position
	local vector = position - origin
	local direction = vector.unit
	local distance = vector.Magnitude
	local result = ray:Raycast(origin, direction * distance)

	return result, vector
end]]

--[[
	Credit to @sleitnick for the geometry tech
	https://twitter.com/sleitnick/status/1475522069198745601

    NOTE: Points have to be in clockwise/counterclockwise order in the array/when traversing to count properly for angle
]]
--[[local function isMouseOnAd(AdUnit)
	if not Mouse.Hit or Mouse.Target ~= AdUnit then
		return false
	end
	
	if Mouse.TargetSurface ~= AdUnit.AdSurfaceGui.Face then
		return false
	end
	
	local mousePoint, surfacePoints = Mouse.Hit, getCornerScreenPoints(AdUnit)
	local raycastResult = raycastFromCamera(AdUnit.Position)

	if not raycastResult then
		return false
	end

	local axisVector = raycastResult.Normal
	
	local angleTotal = 0

	for i = 1, #surfacePoints do
		local p1 = surfacePoints[i-1] or surfacePoints[#surfacePoints]
		local p2 = surfacePoints[i]
		local p1Dir = (p1 - mousePoint.Position).Unit
		local p2Dir = (p2 - mousePoint.Position).Unit

		--Gets angle between the circle point vectors
		local angle = math.atan2(p1Dir:Cross(p2Dir).Magnitude, p1Dir:Dot(p2Dir))
		
		--Signs the angle by multiplying it by -1, 0, or 1
		local signedAngle = angle * math.sign(axisVector:Dot(p1Dir:Cross(p2Dir)))

		angleTotal += signedAngle
	end
	angleTotal = math.floor(math.deg(angleTotal) + 0.5)

	return angleTotal == 360
end

function Tracker:init(billboardClient)
    
    local lastHoverStart = nil

    local function MouseUpdated()
        if not billboardClient.adPart then
            return
        end
    
        if lastHoverStart and not isMouseOnAd(billboardClient.adPart) then
            local hoverTime = Workspace:GetServerTimeNow() - lastHoverStart
            lastHoverStart = nil
    
            billboardClient:sendInteraction("hover", hoverTime)
			
			if DebugAPI then
				DebugAPI.EndInteraction(billboardClient.adPart.AdSurfaceGui)
			end
		elseif lastHoverStart == nil and isMouseOnAd(billboardClient.adPart) then
            lastHoverStart = Workspace:GetServerTimeNow()
			
			if DebugAPI then
				DebugAPI.UpdateInteraction(billboardClient.adPart.AdSurfaceGui, "hover")
			end
        end
    end

    Mouse.Idle:Connect(MouseUpdated)
    Mouse.Move:Connect(MouseUpdated)
    
    Mouse.Button1Down:Connect(function()
        if not billboardClient.adPart then
            return
        end

        if isMouseOnAd(billboardClient.adPart) then
            billboardClient:sendInteraction("click")
			
			if DebugAPI then
				DebugAPI.UpdateInteraction(billboardClient.adPart.AdSurfaceGui, "click")
			end
        end
    end)
end

return Tracker]]
