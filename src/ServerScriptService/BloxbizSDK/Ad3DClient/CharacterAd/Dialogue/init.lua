local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = game.Players.LocalPlayer

local module = {}
module.__index = module
module.TALKING_DISTANCE = 10
module.MOVEMENT_TIME_FOR_DIALOGUE_END = 1

local CharacterModule = require(script.Parent.Character)
local SetCamera = require(script.Parent.SetCamera)
local Controls = require(script.Parent.Controls)
module.DisplayBranch = require(script.DisplayBranch)
module.FormatText = require(script.Parent.FormatText)
module.currentDialogue = nil

function module.new(main, adData, adModelData, adBoxModel, characterModel)
	if module.currentDialogue then
		module.currentDialogue:endDialogue()
	end

	local dialogueObject = setmetatable({}, module)

	dialogueObject.adData = adData
	dialogueObject.adModelData = adModelData
	dialogueObject.branchData = HttpService:JSONDecode(adModelData.ad_dialogue_tree)
	dialogueObject.main = main
	dialogueObject.adBoxModel = adBoxModel
	dialogueObject.characterModel = characterModel
	dialogueObject.dialogueEnded = false
	dialogueObject.dialogueGUID = HttpService:GenerateGUID(false)
	dialogueObject.movementFinishedEvent = nil
	dialogueObject.cameraLocked = false

	dialogueObject.CAMERA_LOCK_ENABLED = adModelData.camera_lock_enabled

	dialogueObject:allDialoguePromptsEnabled(false)

	dialogueObject.main.Parent.Enabled = true
	characterModel:SetAttribute("DialogueActive", true)
	CharacterModule.showIcon(characterModel, false, false, dialogueObject.adModelData)
	module.currentDialogue = dialogueObject

	if dialogueObject.CAMERA_LOCK_ENABLED then
		local cameraSet = SetCamera.setCamera(adModelData, adBoxModel, characterModel, 0.5)

		if cameraSet then
			dialogueObject.cameraLocked = true
			CharacterModule.lookAtObject = SetCamera.currentCameraCf

			dialogueObject.movementFinishedEvent = Controls.watchForMovement(module.MOVEMENT_TIME_FOR_DIALOGUE_END)
			dialogueObject.movementFinishedEvent.Event:Connect(function(what, delta)
				if what == "TimeElapsed" then
					dialogueObject:endDialogue()
				end
			end)

			Controls.disablePlayerMovementControlGuiVisible(2)
		end
	end

	module.DisplayBranch.display(dialogueObject, nil, "Branch1")

	local windowSizeConnection
	windowSizeConnection = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if dialogueObject.dialogueEnded then
			windowSizeConnection:Disconnect()
			return
		end

		module.DisplayBranch.onWindowSizeChange(dialogueObject)
	end)

	dialogueObject:closeDialogueOnDistance()

	return dialogueObject
end

function module:allDialoguePromptsEnabled(enabled)
	for _, adModel in ipairs(self.adBoxModel:GetChildren()) do
		if not (adModel:IsA("Model") and adModel.Name == 'AdModel') then
			continue
		end

		for _, characterModel in pairs(adModel:GetChildren()) do
			if characterModel:IsA("Model") and characterModel.PrimaryPart and characterModel.PrimaryPart:FindFirstChild("ProximityPrompt") then
				if not characterModel.PrimaryPart.ProximityPrompt:GetAttribute("PermanentDisabled") then
					characterModel.PrimaryPart.ProximityPrompt.Enabled = enabled
				end
			end
		end
	end
end

function module:closeDialogueOnDistance()
	local currentDistance = 0

	repeat
		local Character = LocalPlayer.Character
		local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

		if not HumanoidRootPart or not self.characterModel:FindFirstAncestor("Workspace") then
			currentDistance = module.TALKING_DISTANCE + 1
			continue
		end

		currentDistance = (self.characterModel.PrimaryPart.Position - HumanoidRootPart.Position).magnitude

		task.wait(0.1)
	until currentDistance >= module.TALKING_DISTANCE

	self:endDialogue()
end

function module:endDialogue()
	if module.currentDialogue == self then
		module.currentDialogue = nil
		self.dialogueEnded = true
		self.main.Visible = false
		self.main.Parent.Enabled = false

		self.characterModel:SetAttribute("DialogueActive", false)

		if self.cameraLocked then
			self.cameraLocked = false
			self.movementFinishedEvent:Fire("StopWatching")
			SetCamera.resetCamera()
			Controls.enablePlayerMovementControlGuiVisible()
		end

		if LocalPlayer.Character and self.characterModel:FindFirstAncestor("Workspace") then
			CharacterModule.showIcon(self.characterModel, true, "Question", self.adData)
			CharacterModule.lookAtObject = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
			self:allDialoguePromptsEnabled(true)
		end
	end
end

function module:animateText1(textObj, text, secondsPerChar)
	local textLen = string.len(text)
	textObj.Text = ""

	for i = 1, textLen do
		if not self.dialogueEnded then
			textObj.Text = string.sub(text, 1, i)
			task.wait(secondsPerChar)
		end
	end
end

function module:handleEvent(Event)
	if Event.Name == "Krabby" then
		--do nothing
	end
end

return module
