local character = script.Parent  -- Assuming this script is inside the character model
local partsToUnanchor = {}  -- Table to store the parts to unanchor
local weldsLoaded = false

-- Populate the partsToUnanchor table with the parts that need to be unanchored
for _, part in ipairs(character:GetDescendants()) do
	if part:IsA("MeshPart") and part.Anchored then
		table.insert(partsToUnanchor, part)
	end
end

-- Function to check if all welds are loaded
local function areWeldsLoaded()
	for _, weld in ipairs(character:GetDescendants()) do
		if weld:IsA("WeldConstraint") or weld:IsA("Weld") then
			if not weld.Part0 or not weld.Part1 then
				return false
			end
		end
	end
	return true
end

-- Continuously check if welds are loaded
while not weldsLoaded do
	weldsLoaded = areWeldsLoaded()
	if weldsLoaded then
		for _, part in ipairs(partsToUnanchor) do
			part.Anchored = false
		end
	else
		wait(0.1)  -- Wait a short time before checking again
	end
end
