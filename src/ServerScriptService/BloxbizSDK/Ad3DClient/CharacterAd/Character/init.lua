local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CHARACTER_MODEL_FOLDER = "Bloxbiz3DAdAssets"

local LocalPlayer = game.Players.LocalPlayer
local ModuleAnimator = require(script.Parent.ModuleAnimator)
local Utils = require(script.Parent.Parent.Parent.Utils)

local WAVING_DISTANCE = 50

local module = {}
module.lookAtObject = nil

local icons = {
	["Question"] = "http://www.roblox.com/asset/?id=8536287911",
}

function module.getCharacterDistance(characterModel)
	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local characterModelHRP = characterModel.PrimaryPart

	if Character.PrimaryPart then
		return (characterModelHRP.Position - Character.PrimaryPart.Position).magnitude
	elseif Character:FindFirstChild("HumanoidRootPart") then
		return (characterModelHRP.Position - Character.HumanoidRootPart.Position).magnitude
	else
		return math.huge
	end
end

function module.angleBetweenCFrames(origin, cf)
	local axisVector = origin.UpVector
	local rightCf = origin * CFrame.new(0, 0, 5)

	local p1Dir = (origin.Position - cf.Position).Unit
	local p2Dir = (origin.Position - rightCf.Position).Unit

	local angle = math.atan2(p1Dir:Cross(p2Dir).Magnitude, p1Dir:Dot(p2Dir))

	local signedAngle = angle * math.sign(axisVector:Dot(p1Dir:Cross(p2Dir)))
	return signedAngle
end

function module.lookAtPlayer(adBoxModel, characterModel)
	local isBasePart = pcall(function()
		return module.lookAtObject.Position
	end)

	if characterModel:GetAttribute("IsRotating") then
		characterModel:SetAttribute("IsRotating", false)
	end

	local adBoxCf = adBoxModel.AdBox.CFrame
	local lookAtPos = (isBasePart and module.lookAtObject.Position) or module.lookAtObject.Value.Position

	local inObjectSpace = adBoxCf:ToObjectSpace(CFrame.new(lookAtPos))
	local onZeroYPlane = adBoxCf:ToWorldSpace(CFrame.new(inObjectSpace.X, 0, inObjectSpace.Z))

	local x, y, z = adBoxCf:ToOrientation()

	local base = CFrame.new(characterModel.PrimaryPart.Position)
	local orientation = CFrame.fromOrientation(x, y, z)
	local targetCf = base * orientation

	y = module.angleBetweenCFrames(adBoxCf, onZeroYPlane)
	targetCf = targetCf * CFrame.fromOrientation(0, -y - math.pi, 0)

	local tweenInf = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = TweenService:Create(characterModel.PrimaryPart, tweenInf, { CFrame = targetCf })
	tween:Play()

	characterModel:SetAttribute("IsRotating", true)
end

function module.playIdleAnim(characterModel)
	local character = characterModel
	local idleTrack = ModuleAnimator.loadAnimation(character, "Idle", require(script.IdleAnim))
	ModuleAnimator.playAnimation(character, "Idle")
end

function module.playWaveAnim(characterModel)
	local character = characterModel
	local waveTrack = ModuleAnimator.loadAnimation(character, "Wave", require(script.WaveAnim))

	if not character:GetAttribute("Waving") then
		character:SetAttribute("Waving", true)
		ModuleAnimator.playAnimation(character, "Wave")

		repeat
			task.wait()
		until waveTrack.length > 0.01

		task.wait(waveTrack.length)
		character:SetAttribute("Waving", false)
	end
end

function module.showIcon(characterModel, visibility, iconType, adModelData)
	if not characterModel.PrimaryPart:FindFirstChild("StatusIcon") then
		return
	end

	local dialogueDisabled = adModelData.ad_dialogue_disabled == true

	characterModel.PrimaryPart.StatusIcon.Enabled = visibility

	if iconType then
		characterModel.PrimaryPart.StatusIcon.ImageLabel.Image = icons[iconType]
	end

	if dialogueDisabled then
		characterModel.PrimaryPart.StatusIcon.ImageLabel.Visible = false
	end
end

function module.whenNearby(adBoxModel, characterModel, adData, hasHumanoid)
	local rotate = (adData.ad_rotate_disabled ~= true)

	repeat
		task.wait(0.5)
	until module.getCharacterDistance(characterModel) <= WAVING_DISTANCE
		and (not characterModel:GetAttribute("DialogueActive"))

	local wavingStartTime = characterModel:GetAttribute("WavingStartTime")
	local dialogueActive = characterModel:GetAttribute("DialogueActive")
	local wavedOnceWithinDistance = false
	module.lookAtObject = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

	repeat
		local timeIsGood = not wavingStartTime or (Workspace:GetServerTimeNow() - wavingStartTime >= 8)

		if rotate then
			module.lookAtPlayer(adBoxModel, characterModel)
		end

		if timeIsGood and not dialogueActive and not wavedOnceWithinDistance and hasHumanoid and rotate then
			wavedOnceWithinDistance = true
			characterModel:SetAttribute("WavingStartTime", Workspace:GetServerTimeNow())
			module.playWaveAnim(characterModel)
		end

		task.wait(0.5)
	until module.getCharacterDistance(characterModel) > WAVING_DISTANCE

	module.whenNearby(adBoxModel, characterModel, adData, hasHumanoid)
end

function module.init(adBoxModel, characterModel, adData)
	local hasHumanoid = characterModel:FindFirstChild("Humanoid")
	local hasDialogue = adData.ad_dialogue_disabled == false

	if characterModel.PrimaryPart:FindFirstChild("StatusIcon") then
		characterModel.PrimaryPart.StatusIcon.Enabled = true
		if not hasDialogue then
			characterModel.PrimaryPart.StatusIcon.ImageLabel.Visible = false
		end
	end

	if hasHumanoid then
		module.playIdleAnim(characterModel)
	end

	local success, result = pcall(function()
		module.whenNearby(adBoxModel, characterModel, adData, hasHumanoid)
	end)

	if not success then
		Utils.pprint("[SuperBiz] Error: " .. result)
	end
end

return module
