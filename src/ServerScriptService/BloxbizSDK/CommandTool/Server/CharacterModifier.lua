local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

local CharacterModifier = {}

local cachedBundleDescriptions = {}

function CharacterModifier.GetCharacter(player)
    return player.Character
end

function CharacterModifier.GetHumanoid(player)
    local char = CharacterModifier.GetCharacter(player)
    if not char then
        return
    end

    return char:FindFirstChild("Humanoid")
end

function CharacterModifier.GetRootPart(player)
    local char = CharacterModifier.GetCharacter(player)
    if not char then
        return
    end

    return char:FindFirstChild("HumanoidRootPart")
end

function CharacterModifier.AddSFX(player, effectName)
	local root = CharacterModifier.GetRootPart(player)
	if not root then
		return
	end

	local effectParent = root
	if effectName == "ForceField" then
		effectParent = player.Character
	end

	local name = "SBCommands" .. effectName
	local effect = effectParent:FindFirstChild(effectName)
	if not effect then
		effect = Instance.new(effectName)
		effect.Name = name
		effect.Parent = effectParent
	end
end

function CharacterModifier.RemoveSFX(player, effectName)
	local name = "SBCommands" .. effectName
	if player.Character then
		for _, child in player.Character:GetDescendants() do
			if child.Name == name then
				child:Destroy()
				break
			end
		end
	end
end

function CharacterModifier.GetBundleDescription(bundleId)
	local stringId = tostring(bundleId)
	local bundleDescription = cachedBundleDescriptions[stringId]
	if bundleDescription then
		return bundleDescription
	end

	local success, bundleDetails = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	if not success then
		return false, bundleDetails
	end

	local bundleOutfitId
	for _, item in bundleDetails.Items do
		if item.Type == "UserOutfit" then
			bundleOutfitId = item.Id
			break
		end
	end
	if not bundleOutfitId then
		return false, "Missing Bundle Outfit"
	end

	success, bundleDescription = pcall(function()
		return Players:GetHumanoidDescriptionFromOutfitId(bundleOutfitId)
	end)
	if not success then
		return false, bundleDescription
	end

	cachedBundleDescriptions[stringId] = bundleDescription

	return bundleDescription
end

function CharacterModifier.ApplyBundle(player, bundleId)
    local hum = CharacterModifier.GetHumanoid(player)
    if not hum then
        return
    end

    local description = CharacterModifier.GetBundleDescription(bundleId)
    if not description then
        return
    end

    hum:ApplyDescriptionReset(description, Enum.AssetTypeVerification.Always)
end

local cachedDescriptions = {}

function CharacterModifier.UnapplyBundle(player)
	local humanoid = CharacterModifier.GetHumanoid(player)
	if not humanoid then
		return
	end

	local description = cachedDescriptions[player]
	if not description then
		local success, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)

		if not success then
			return
		end

		description = result
		cachedDescriptions[player] = description
	end

	humanoid:ApplyDescriptionReset(description, Enum.AssetTypeVerification.Always)
end

local accessoryTypes = {
	[8] = "HatAccessory",
    [41] = "HairAccessory",
    [42] = "FaceAccessory",
    [43] = "NeckAccessory",
    [44] = "ShouldersAccessory",
    [45] = "FrontAccessory",
    [46] = "BackAccessory",
    [47] = "WaistAccessory",
}
function CharacterModifier.ClearAccessories(player)
    local humanoid = CharacterModifier.GetHumanoid(player)
    if not humanoid then
        return
    end

	local desc = humanoid:GetAppliedDescription()
	for id, accessory in accessoryTypes do
		desc[accessory] = ""
	end
	desc.HatAccessory = ""

    pcall(function()
        humanoid:ApplyDescription(desc)
    end)
end

function CharacterModifier.ChangeHumanoidDescriptionProperty(player, propertyName, propertyValue)
    local hum = CharacterModifier.GetHumanoid(player)
    if not hum then
        return
    end

    local desc = hum:GetAppliedDescription()
    desc[propertyName] = propertyValue

    pcall(function()
        hum:ApplyDescription(desc)
    end)
end

local playingTrack = {}

function CharacterModifier.StopAnimation(player)
	local track = playingTrack[player]
	if track then
		track:Stop()
		playingTrack[player] = nil
	end
end

function CharacterModifier.PlayAnimation(player, animationId, looped)
	local humanoid = CharacterModifier.GetHumanoid(player)
	if not humanoid then
		return
	end

	local character = humanoid.Parent

	CharacterModifier.StopAnimation(player)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local animation = character:FindFirstChild("SBCommands" .. animationId)
	if not animation then
		animation = Instance.new("Animation")
		animation.Name = "SBCommands" .. animationId
		animation.AnimationId = "rbxassetid://" .. animationId
		animation.Parent = character
	end

	task.wait()

	local track = animator:LoadAnimation(animation)
	if not track then
		return
	end

	playingTrack[player] = track

	track.Looped = looped
	track:Play()
end

Players.PlayerRemoving:Connect(function(player)
	CharacterModifier.StopAnimation(player)
	cachedDescriptions[player] = nil
end)

return CharacterModifier

