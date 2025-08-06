------------------------------------------
-- This Script manages XYZ on the server
-- AverageRobloxDev2 - All rights reserved
------------------------------------------

-------------------------
--// Preset Variables
-------------------------
local tweenService = game:GetService("TweenService")

-------------------------
--// Variables
-------------------------
local doorFrame = script.Parent.doorFrame -- Static model representing the boundary of the door 
local doorPiece = script.Parent.doorPiece -- Dynamic model representing the door 
local proximity = script.Parent.Part.ProximityPrompt
local hingeLocation = script.Parent.Part.hingeLocation -- Attachment representing the hinge of the door, which the door piece both anchor and tween relative to.
local doorIsClosed = true -- starts off closed.
local initialCFrame = doorPiece:GetPivot() -- Store the initial CFrame of the door

-------------------------
--// Functions
-------------------------
function changeDoorState(isSolid)
	for i, v in pairs(doorPiece:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = isSolid
			v.Anchored = true
		end
	end
end

function prepareDoorForTween()
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1) -- Set an appropriate size
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Name = "goodPiece"
	part.CFrame = hingeLocation.WorldCFrame
	part.Parent = doorPiece

	for _, v in pairs(doorPiece:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "goodPiece" then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = v
			weld.Parent = part
			v.Anchored = false
		end
	end

	return part
end

-------------------------
--// Events
-------------------------

local open = hingeLocation.WorldCFrame * CFrame.Angles(0, math.rad(90), 0) 
local close = hingeLocation.WorldCFrame * CFrame.Angles(0, math.rad(-90), 0)
local debounce = false

proximity.Triggered:Connect(function()
	
	if debounce == false then
		debounce = true
		doorIsClosed = not doorIsClosed

		changeDoorState(false)

		local part = prepareDoorForTween()

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		local goalCFrame
		if not doorIsClosed then
			goalCFrame = open-- Adjust as necessary for the open position
		else
			goalCFrame =  close-- Adjust as necessary for the open position
		end

		local tween = tweenService:Create(part, tweenInfo, {CFrame = goalCFrame})
		tween:Play()
		tween.Completed:Wait()


		changeDoorState(true)

		task.wait()

		part:Destroy()
		debounce = false
	end
	
end)

-------------------------
--// Code
-------------------------

----------------------
--All rights reserved. 
----------------------
