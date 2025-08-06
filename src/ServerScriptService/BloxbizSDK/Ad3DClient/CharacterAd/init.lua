local LocalPlayer = game.Players.LocalPlayer
local CharacterModule = require(script.Character)
local DialogueModule = require(script.Dialogue)
local CreateDialogueGui = require(script.CreateDialogueGui)

local module = {}
module.__index = module

function module:guiOpened()
	local dialogueGUI

	if not LocalPlayer.PlayerGui:FindFirstChild("BloxbizDialogue") then
		dialogueGUI = CreateDialogueGui()
		dialogueGUI.Parent = LocalPlayer.PlayerGui
	else
		dialogueGUI = LocalPlayer.PlayerGui:FindFirstChild("BloxbizDialogue")
	end

	DialogueModule.new(dialogueGUI.Main, self.adData, self.adModelData, self.adBoxModel, self.characterModel)
end

function module:handleCharacterAd()
	task.spawn(CharacterModule.init, self.adBoxModel, self.characterModel, self.adModelData)

	task.spawn(function()
		pcall(function()
			local proximityPrompt = self.characterModel.PrimaryPart.ProximityPrompt
			proximityPrompt.ObjectText = self.adModelData.ad_character_name
			proximityPrompt.ActionText = self.adModelData.prompt_action_text
			proximityPrompt.MaxActivationDistance = DialogueModule.TALKING_DISTANCE
			proximityPrompt.Triggered:Connect(function()
				self:guiOpened()
			end)
		end)
	end)
end

function module.new(ad3DClientInstance, adBoxModel, characterModel, adData, adModelData, scale)
	local characterAd = setmetatable({}, module)
	characterAd.adBoxModel = adBoxModel
	characterAd.characterModel = characterModel
	characterAd.adData = adData
	characterAd.adModelData = adModelData
	characterAd.ad3DClientInstance = ad3DClientInstance

	if not characterModel.PrimaryPart and characterModel:FindFirstChild("HumanoidRootPart") then
		characterModel.PrimaryPart = characterModel.HumanoidRootPart
	end

	characterModel.PrimaryPart.Anchored = true

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = characterModel.PrimaryPart

	local statusIcon = characterModel.PrimaryPart:FindFirstChild("StatusIcon")

	if statusIcon then
		statusIcon.ImageLabel.Visible = characterAd.adModelData.show_question_mark_in_model
		statusIcon.StudsOffset = statusIcon.StudsOffset * scale
		statusIcon.Size = UDim2.new(statusIcon.Size.X.Scale * scale, 0, statusIcon.Size.Y.Scale * scale, 0)

		if statusIcon:FindFirstChild("PaidAdLabel") then
			statusIcon.PaidAdLabel.Visible = characterAd.adModelData.show_ad_disclaimer_in_model
			statusIcon.PaidAdLabel.Text = characterAd.adModelData.ad_disclaimer_text
		end
	end

	if characterAd.adModelData.ad_dialogue_disabled == true then
		characterModel.PrimaryPart.ProximityPrompt.Enabled = false
		characterModel.PrimaryPart.ProximityPrompt:SetAttribute("PermanentDisabled", true)
	end

	local MetricsModule = require(script.MetricsClient)
	MetricsModule.init(adBoxModel, characterModel, adData)

	characterAd:handleCharacterAd()

	return characterAd
end

function module:destroy()
	self.characterModel:Destroy()
end

return module
