local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local slidingFriction = 0.01 -- Very low friction value for sliding
local originalFriction = 2 -- Default friction value

local anim = script:WaitForChild("Animation")
local animTrack = character:WaitForChild("Humanoid"):LoadAnimation(anim)

-- Function to set friction for all parts of the character
local function setCharacterFriction(friction)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			local customProperties = part.CurrentPhysicalProperties
			part.CustomPhysicalProperties = PhysicalProperties.new(
				customProperties.Density,
				friction, -- Set the new friction value
				customProperties.Elasticity,
				100,
				customProperties.ElasticityWeight
			)
		end
	end
end

-- Function to start sliding
local function startSlide()
	animTrack:Play()
	setCharacterFriction(slidingFriction)
end

-- Function to stop sliding
local function stopSlide()
	animTrack:Stop()
	setCharacterFriction(originalFriction)
end

-- Listen for slide input (e.g., a key press)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		startSlide()
	end
end)

-- Listen for when the slide key is released
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E  then
		stopSlide()
	end
end)
