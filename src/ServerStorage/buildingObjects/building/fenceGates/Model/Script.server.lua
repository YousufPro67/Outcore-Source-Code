local door = script.Parent
local prompt = Instance.new("ProximityPrompt")
prompt.RequiresLineOfSight = false
prompt.ActionText = "Open"

local part = Instance.new("Part")
part.Size = Vector3.new(1,1,1)
part.Transparency = 1
part.CFrame = door:GetPivot()
part.Parent = door
part.CanCollide = false
part.Anchored = true

prompt.Parent = part

local function createWeldedAnchor(door)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Anchored = true
	anchor.CFrame = door:GetPivot()
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Parent = door
	anchor.Name = "doorAnchor"

	for _, part in ipairs(door:GetDescendants()) do
		if part:IsA("BasePart") and part ~= anchor then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = anchor
			weld.Part1 = part
			weld.Parent = anchor
			part.Anchored = false
		end
	end
	
	if door:IsA("BasePart") then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchor
		weld.Part1 = door
		weld.Parent = anchor
		door.Anchored = false
	end

	return anchor
end

local function toggleCollision(door1, door2, canGo)
	for i,v in pairs(door1:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = canGo
		end
	end
	for i,v in pairs(door2:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = canGo
		end
	end
	if door1:IsA("BasePart") then
		door1.CanCollide = canGo
	end
	if door2:IsA("BasePart") then
		door1.CanCollide = canGo
	end
end

local function animateDoor(anchor, angle)
	local initialCFrame = anchor:GetPivot()
	local goal = {CFrame = initialCFrame * CFrame.Angles(0, math.rad(angle), 0)}
	local tween = game.TweenService:Create(anchor, TweenInfo.new(0.8, Enum.EasingStyle.Linear), goal)
	tween:Play()
end

local function setupDoorsAnimation(door1, door2)
	

	
	local	anchor1 = createWeldedAnchor(door1)
	local	anchor2 = createWeldedAnchor(door2)

	
	local open = false
	local debounce = true

	prompt.Triggered:Connect(function()
		if debounce then
			debounce = false

			toggleCollision(door1, door2, false)
			animateDoor(anchor1, (open and -90) or 90)
			animateDoor(anchor2, (open and 90) or -90)
			task.wait(0.8)
			toggleCollision(door1, door2, true)

			open = not open
			debounce = true
		end
	end)
end



setupDoorsAnimation(script.Parent.Door1, script.Parent.Door2)
