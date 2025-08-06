local function createWeldedAnchor(door)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Anchored = true
	anchor.CFrame = door:GetPivot()
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Parent = door

	for _, part in ipairs(door:GetDescendants()) do
		if part:IsA("BasePart") and part ~= anchor then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = anchor
			weld.Part1 = part
			weld.Parent = anchor
			part.Anchored = false
		end
	end

	return anchor
end

local function animateDoor(anchor, angle)
	local initialCFrame = anchor.CFrame
	local goal = {CFrame = initialCFrame * CFrame.Angles(0, math.rad(angle), 0)}
	local tween = game.TweenService:Create(anchor, TweenInfo.new(0.8, Enum.EasingStyle.Linear), goal)
	tween:Play()
end

local function setupDoorsAnimation(door1, door2)
	local anchor1 = createWeldedAnchor(door1)
	local anchor2 = createWeldedAnchor(door2)
	local open = false
	local debounce = true

	local function toggleDoors()
		if debounce then
			debounce = false
			door1.Click.unlocked:Play()
			door2.Click.unlocked:Play()
			door1.Click.move:Play()
			door2.Click.move:Play()
			animateDoor(anchor1, (open and -90) or 90)
			animateDoor(anchor2, (open and 90) or -90)
			task.wait(0.8)
			door1.Click.stop:Play()
			door2.Click.stop:Play()
			open = not open
			debounce = true
		end
	end

	door1.Click.ClickDetector.MouseClick:Connect(toggleDoors)
	door2.Click.ClickDetector.MouseClick:Connect(toggleDoors)
end

setupDoorsAnimation(script.Parent.Door1, script.Parent.Door2)
