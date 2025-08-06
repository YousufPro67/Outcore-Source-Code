local knit = require(game.ReplicatedStorage.Packages.Knit)
local module = knit.CreateController({
	Name = "TimeEffect"
})

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local timeStopDuration = math.huge
local isTimeStopped = false

local anchor = {}

local function freezeCharacter(character)
	for _, desc in pairs(character:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end
end

local function unfreezeCharacter(character)
	for _, desc in pairs(character:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
		end
	end
end

function module:StopTime(value)
	isTimeStopped = value
	if isTimeStopped then
		for _, object in pairs(workspace:GetDescendants()) do
			if object:IsA("BasePart") and not object:IsDescendantOf(workspace.CameraParts) then
				if not object.Anchored then
					table.insert(anchor,object)
				end
				object.Anchored = true
			end
		end
	else

		for i, object in anchor do
			object.Anchored = false
		end
		anchor = {}
	end
end


return module
