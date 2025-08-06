-- Written by Lightning_Game27

--// Services
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local PlayerService = game:GetService("Players") 
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Values
local Camera = workspace.CurrentCamera
local BorderHighlight = script:WaitForChild("Highlight")
local PromptTemplate = script:WaitForChild("PromptTemplate")
local Offsett = 1.25

--// Prompt Images
local GamepadButtonImage = {
	--// Xbox
	ButtonX = "rbxasset://textures/ui/Controls/xboxX@3x.png",
	ButtonY = "rbxasset://textures/ui/Controls/xboxY@3x.png",
	ButtonA = "rbxasset://textures/ui/Controls/xboxA@3x.png",
	ButtonB = "rbxasset://textures/ui/Controls/xboxB@3x.png",
	ButtonSelect = "rbxasset://textures/ui/Controls/xboxView@3x.png",
	ButtonStart = "rbxasset://textures/ui/Controls/xboxmenu@3x.png",
	
	--// PlayStation
	ButtonSquare = "rbxasset://textures/ui/Controls/PlayStationController/ButtonSquare@3x.png",
	ButtonTriangle = "rbxasset://textures/ui/Controls/PlayStationController/ButtonTriangle@3x.png",
	ButtonCross = "rbxasset://textures/ui/Controls/PlayStationController/ButtonCross@3x.png",
	ButtonCircle = "rbxasset://textures/ui/Controls/PlayStationController/ButtonCircle@3x.png",
	DPadLeft = "rbxasset://textures/ui/Controls/PlayStationController/DPadLeft@3x.png",
	DPadRight = "rbxasset://textures/ui/Controls/PlayStationController/DPadRight@3x.png",
	DPadUp = "rbxasset://textures/ui/Controls/PlayStationController/DPadUp@3x.png",
	DPadDown = "rbxasset://textures/ui/Controls/PlayStationController/DPadDown@3x.png",
	ButtonTouchpad = "rbxasset://textures/ui/Controls/PlayStationController/ButtonTouchpad@3x.png",
	ButtonOptions = "rbxasset://textures/ui/Controls/PlayStationController/ButtonOptions@3x.png",
	ButtonL1 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonL1@3x.png",
	ButtonR1 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonR1@3x.png",
	ButtonL2 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonL2@3x.png",
	ButtonR2 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonR2@3x.png",
	ButtonL3 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonL3@3x.png",
	ButtonR3 = "rbxasset://textures/ui/Controls/PlayStationController/ButtonR3@3x.png",
	Thumbstick1 = "rbxasset://textures/ui/Controls/PlayStationController/Thumbstick1@3x.png",
	Thumbstick2 = "rbxasset://textures/ui/Controls/PlayStationController/Thumbstick2@3x.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}
local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}
local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

--// Player
local Player = PlayerService.LocalPlayer
local PlayerUI = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()

--// Common Functions
local function GetFaceNormals(Part: BasePart)
	local PartCF = Part.CFrame
	return {
		Back = -PartCF.LookVector,
		Front = PartCF.LookVector,
		Bottom = -PartCF.UpVector,
		Top = PartCF.UpVector,
		Left = PartCF.RightVector,
		Right = -PartCF.RightVector
	}
end

local function GetClosestFace(Part: BasePart, DisabledSides: {string})
	local FaceNormals = GetFaceNormals(Part)
	local ClosestFace = nil
	local HighestDotProduct = -math.huge

	local CameraPos = Camera.CFrame.Position
	local CameraLook = Camera.CFrame.LookVector
	
	DisabledSides = DisabledSides or {}

	for Face, Normal in pairs(FaceNormals) do
		if table.find(DisabledSides, Face) then
			continue
		end
		
		local DirectionToPart = (CameraPos - Part.Position).Unit
		local DotProduct = Normal:Dot(DirectionToPart)

		local ViewDotProduct = Normal:Dot(-CameraLook) -- Negative because we want the face facing the camera
		if DotProduct > HighestDotProduct and ViewDotProduct > 0 then -- Face must be visible (angle < 90°)
			HighestDotProduct = DotProduct
			ClosestFace = Face
		end
	end

	return ClosestFace
end

local Hologram = {}
Hologram.__index = Hologram

Hologram.GlobalTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)
Hologram.Holograms = {}

local function Tween(Object, Property: string, Value)
	local NewTween = TweenService:Create(Object, Hologram.GlobalTweenInfo, {[Property] = Value})
	NewTween:Play()

	return NewTween
end

function Hologram.InitialiseGlobally(CheckTag: boolean?, ShowBeam: boolean?)
	CheckTag = CheckTag or false
	ShowBeam = ShowBeam or false

	for _, Prompt in pairs(workspace:GetDescendants()) do
		if Prompt:IsA("ProximityPrompt") then
			Hologram.Holograms[Prompt] = Hologram.New(Prompt, Vector3.zero, CheckTag, ShowBeam)
		end
	end
end

function Hologram.New(Prompt: ProximityPrompt, StudsOffset: Vector3?, CheckTag: boolean?, ShowBeam: boolean?)
	if CheckTag then
		if not Prompt:HasTag("Hologram") then
			warn("ProximityPrompt does not have CollectionService Tag 'Hologram'.")
			return
		end
	end
	
	if Prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		warn("ProximityPrompt style is not custom. This prompt is not being registered.")
		return
	end

	local self = setmetatable({}, Hologram)
	self.ActionText = Prompt.ActionText
	self.ObjectText = Prompt.ObjectText
	self.PromptName = Prompt.Name
	self.KeyboardKeyCode = Prompt.KeyboardKeyCode
	self.HoldDuration = Prompt.HoldDuration
	self.Prompt = Prompt
	self.ShowBeam = ShowBeam or false
	self.StudsOffset = StudsOffset or Vector3.zero
	self.Colours = {
		Primary = Color3.fromRGB(0, 144, 255),
		Secondary = Color3.fromRGB(0, 0, 0),
		Tertiary = Color3.fromRGB(255, 255, 255)
	}
	self.UUID = os.clock() + math.random()
	self.BillboardActive = false
	self.DynamicUpdateActive = false
	self.isDeleting = false
	self.AlwaysOnTop = false
	self.DisabledSides = {}

	if Prompt.Parent:IsA("BasePart") or Prompt.Parent:IsA("Attachment") then
		self.PromptParent = Prompt.Parent
	elseif Prompt.Parent:IsA("Model") and Prompt.Parent.PrimaryPart ~= nil then
		self.PromptParent = Prompt.Parent.PrimaryPart
	else
		error("Hologram requires ProximityPrompt to be parented to a BasePart, Attachment or Model with a PrimaryPart.")
	end

	Prompt.PromptShown:Connect(function(InputType: Enum.ProximityPromptInputType)
		self:OnPromptShown(InputType)
	end)

	Prompt.PromptHidden:Connect(function(InputType: Enum.ProximityPromptInputType)
		self:OnPromptHidden(InputType)
	end)

	Prompt.PromptButtonHoldBegan:Connect(function()
		self:PromptHolding()
	end)

	Prompt.Triggered:Connect(function()
		self:PromptTriggered()
	end)

	Hologram.Holograms[Prompt] = self

	return self
end

function Hologram:CreatePrompt()	
	if self.ClonedPrompt ~= nil then
		self.ClonedPrompt:Destroy()
	end

	for _, Attachment in pairs(self.PromptParent:GetChildren()) do
		if Attachment:IsA("Attachment") and string.find(Attachment.Name, "Beam" .. self.PromptName .. self.UUID) then
			Attachment:Destroy()
		end
	end

	self.ClonedPrompt = PromptTemplate:Clone()

	self.KeyCodePart = self.ClonedPrompt.KeyCode
	self.KeyCodeUI = self.KeyCodePart.HologramKeyCodeUI
	self.KeyCodeBackground = self.KeyCodeUI.Background
	self.KeyCodeText = self.KeyCodeBackground.KeyCode
	self.KeyCodeImage = self.KeyCodeBackground.KeyCodeImage
	self.KeyCodeProgress = self.KeyCodeBackground.Progress

	self.InstructionPart = self.ClonedPrompt.Instruction
	self.InstructionUI = self.InstructionPart.HologramInstructionUI
	self.InstructionBackground = self.InstructionUI.Background
	self.ActionUIText = self.InstructionBackground.Action
	self.ObjectUIText = self.InstructionBackground.Object
	self.InvisibleButton = self.InstructionBackground.InvisiButton

	self.DesignPart = self.ClonedPrompt.Design
	self.DesignUI = self.DesignPart.HologramDesignUI
	self.DesignImage = self.DesignUI.Image

	self.KeyCodeUI.Name = "Hologram" .. self.PromptName .. self.UUID .. "KeyCodeUI"
	self.InstructionUI.Name = "Hologram" .. self.PromptName .. self.UUID .. "InstructionUI"
	self.DesignUI.Name = "Hologram" .. self.PromptName .. self.UUID .. "DesignUI"

	self.Beam = self.KeyCodePart.Beam
	self.BeamAttachment = self.KeyCodePart.Attachment
	self.BeamAttachment.Name = "Beam" .. self.PromptName .. self.UUID
	self.TransparencyValue = self.Beam:WaitForChild("TransparencyValue")

	self.ClonedPrompt.Name = "Hologram" .. self.PromptName .. self.UUID
	self.ClonedPrompt.Parent = self.PromptParent

	self.KeyCodeUI.Parent = PlayerUI
	self.InstructionUI.Parent = PlayerUI
	self.DesignUI.Parent = PlayerUI

	self.KeyCodeUI.AlwaysOnTop = self.AlwaysOnTop
	self.InstructionUI.AlwaysOnTop = self.AlwaysOnTop
	self.DesignUI.AlwaysOnTop = self.AlwaysOnTop

	self.BeamConnect = self.TransparencyValue:GetPropertyChangedSignal("Value"):Connect(function()
		self.Beam.Transparency = NumberSequence.new(self.TransparencyValue.Value)
	end)
end

function Hologram:DestroyPrompt()
	if self.ClonedPrompt == nil then return end

	for _, PromptUI in pairs(PlayerUI:GetChildren()) do
		if string.find(PromptUI.Name, "Hologram" .. self.PromptName .. self.UUID) then
			PromptUI:Destroy()
		end
	end

	if self.HoldEndedConnection then
		self.HoldEndedConnection:Disconnect()
	end

	self.BeamConnect:Disconnect()

	if self.InvisiButtonConnect then
		self.InvisiButtonConnect:Disconnect()
	end

	if self.BillboardUI then
		self.BillboardUI:Disconnect()
	end
	
	if self.DynamicUI then
		self.DynamicUI:Disconnect()
	end

	self.ClonedPrompt:Destroy()
	self.ClonedPrompt = nil

	--BorderHighlight.Adornee = nil

	self.isDeleting = false
end

function Hologram:OnPromptShown(InputType: Enum.ProximityPromptInputType)
	repeat RunService.PreRender:Wait() until self.isDeleting == false

	self:CreatePrompt()
	if not self.ClonedPrompt then return end

	local LastClosestFace = GetClosestFace(self.PromptParent, self.DisabledSides)
	
	if not LastClosestFace then
		self:OnPromptHidden(InputType)
		return
	end

	local FaceNormal = GetFaceNormals(self.PromptParent)[LastClosestFace]
	local FacePosition = self.PromptParent.Position + (FaceNormal * (self.PromptParent.Size / 2)) + (FaceNormal * 1)
	
	local KeyCodeLeftExtent = self.KeyCodePart.Size.X / 2
	local InstructionLeftExtent = self.InstructionPart.Size.X / 2
	local XOffset = KeyCodeLeftExtent - InstructionLeftExtent

	self.KeyCodeText.TextTransparency = 1
	self.ActionUIText.TextTransparency = 1
	self.ObjectUIText.TextTransparency = 1

	self.InstructionBackground.Transparency = 1
	self.KeyCodeBackground.Transparency = 1

	self.DesignImage.ImageTransparency = 1
	self.KeyCodeImage.ImageTransparency = 1

	self.DesignImage.ImageColor3 = self.Colours.Primary
	self.KeyCodeProgress.BackgroundColor3 = self.Colours.Primary

	self.InstructionBackground.BackgroundColor3 = self.Colours.Secondary
	self.KeyCodeBackground.BackgroundColor3 = self.Colours.Secondary

	self.KeyCodeText.TextColor3 = self.Colours.Tertiary
	self.KeyCodeImage.ImageColor3 = self.Colours.Tertiary
	self.ActionUIText.TextColor3 = self.Colours.Tertiary
	self.ObjectUIText.TextColor3 = self.Colours.Tertiary

	if self.BillboardActive == true then
		self.BillboardUI = RunService.PreRender:Connect(function()
			if not self.ClonedPrompt or not self.ClonedPrompt.PrimaryPart then self.BillboardUI:Disconnect() return end

			local PartCFrame = self.PromptParent.CFrame
			local WorldOffset = PartCFrame:PointToWorldSpace(self.StudsOffset)
			local CameraPosition = Camera.CFrame.Position

			self.ClonedPrompt:PivotTo(CFrame.lookAt(WorldOffset, CameraPosition, Vector3.new(0, 1, 0)))

			self.DesignPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * Offsett)
			self.InstructionPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * -Offsett) + (self.KeyCodePart.CFrame.RightVector * XOffset)
		end)
	elseif self.DynamicUpdateActive == true then
		self.ClonedPrompt:PivotTo(CFrame.new(FacePosition, FacePosition + FaceNormal))
		self.ClonedPrompt:PivotTo(self.ClonedPrompt.PrimaryPart.CFrame + (self.ClonedPrompt.PrimaryPart.CFrame.LookVector * (self.StudsOffset.Z)) + (self.ClonedPrompt.PrimaryPart.CFrame.RightVector * (self.StudsOffset.X)) + (self.ClonedPrompt.PrimaryPart.CFrame.UpVector * (self.StudsOffset.Y)))

		self.DesignPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * Offsett)
		self.InstructionPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * -Offsett) + (self.KeyCodePart.CFrame.RightVector * XOffset)
		
		self.DynamicUI = Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
			if not self.ClonedPrompt or not self.ClonedPrompt.PrimaryPart then
				self.DynamicUI:Disconnect()
				return
			end

			local CurrentClosestFace = GetClosestFace(self.PromptParent, self.DisabledSides)
			if CurrentClosestFace ~= LastClosestFace then
				FaceNormal = GetFaceNormals(self.PromptParent)[CurrentClosestFace]
				if FaceNormal == nil then return end
				FacePosition = self.PromptParent.Position + (FaceNormal * (self.PromptParent.Size / 2)) + (FaceNormal * 1)
				
				self.ClonedPrompt:PivotTo(CFrame.new(FacePosition, FacePosition + FaceNormal))
				self.ClonedPrompt:PivotTo(self.ClonedPrompt.PrimaryPart.CFrame + (self.ClonedPrompt.PrimaryPart.CFrame.LookVector * (self.StudsOffset.Z)) + (self.ClonedPrompt.PrimaryPart.CFrame.RightVector * (self.StudsOffset.X)) + (self.ClonedPrompt.PrimaryPart.CFrame.UpVector * (self.StudsOffset.Y)))

				self.DesignPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * Offsett)
				self.InstructionPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * -Offsett) + (self.KeyCodePart.CFrame.RightVector * XOffset)
				
				Tween(self.DesignPart, "CFrame", self.DesignPart.CFrame * CFrame.new(0, 0, 0.95))
				Tween(self.InstructionPart, "CFrame", self.InstructionPart.CFrame * CFrame.new(0, 0, -0.95))

				LastClosestFace = CurrentClosestFace
			end
		end)
	else
		self.ClonedPrompt:PivotTo(CFrame.new(FacePosition, FacePosition + FaceNormal))
		self.ClonedPrompt:PivotTo(self.ClonedPrompt.PrimaryPart.CFrame + (self.ClonedPrompt.PrimaryPart.CFrame.LookVector * (self.StudsOffset.Z)) + (self.ClonedPrompt.PrimaryPart.CFrame.RightVector * (self.StudsOffset.X)) + (self.ClonedPrompt.PrimaryPart.CFrame.UpVector * (self.StudsOffset.Y)))

		self.DesignPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * Offsett)
		self.InstructionPart.CFrame = self.KeyCodePart.CFrame + (self.KeyCodePart.CFrame.LookVector * -Offsett) + (self.KeyCodePart.CFrame.RightVector * XOffset)
	end

	if self.ShowBeam == true then
		BorderHighlight.Adornee = self.PromptParent
		
		local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
		
		if Humanoid then
			if Humanoid.RigType == Enum.HumanoidRigType.R6 then
				self.Beam.Attachment1 = Character.Torso.BodyFrontAttachment
			elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
				self.Beam.Attachment1 = Character.UpperTorso.BodyFrontAttachment
			end
			
			self.BeamAttachment.Parent = self.PromptParent
			Tween(self.TransparencyValue, "Value", 0)
		end
	end

	if InputType == Enum.ProximityPromptInputType.Gamepad then
		local MappedKey = UserInputService:GetStringForKeyCode(self.Prompt.GamepadKeyCode) 
		
		if GamepadButtonImage[MappedKey] then
			self.KeyCodeImage.Image = GamepadButtonImage[MappedKey]
		end
	elseif InputType == Enum.ProximityPromptInputType.Touch then
		self.KeyCodeImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
	else
		local ButtonTextString = UserInputService:GetStringForKeyCode(self.Prompt.KeyboardKeyCode)

		local ButtonTextImage = KeyboardButtonImage[self.Prompt.KeyboardKeyCode]
		if ButtonTextImage == nil then
			ButtonTextImage = KeyboardButtonIconMapping[ButtonTextString]
		end

		if ButtonTextImage == nil then
			local KeyCodeMappedText = KeyCodeToTextMapping[self.Prompt.KeyboardKeyCode]
			if KeyCodeMappedText then
				ButtonTextString = KeyCodeMappedText
			end
		end

		if ButtonTextImage then
			self.KeyCodeImage.Image = ButtonTextImage
		elseif ButtonTextString ~= nil and ButtonTextString ~= "" then
			self.KeyCodeText.Text = ButtonTextString
		else
			error(
				"ProximityPrompt '"
					.. self.Prompt.Name
					.. "' has an unsupported keycode for rendering UI: "
					.. tostring(self.Prompt.KeyboardKeyCode)
			)
		end
	end

	self.ActionUIText.Text = self.Prompt.ActionText
	self.ObjectUIText.Text = self.Prompt.ObjectText

	self.InvisiButtonConnect = self.InvisibleButton.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.Prompt:InputHoldBegin()
		end
	end)

	self.ImageHoldEndedConnection = self.InvisibleButton.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.Prompt:InputHoldEnd()
		end
	end)

	if self.BillboardActive == false then
		Tween(self.DesignPart, "CFrame", self.DesignPart.CFrame * CFrame.new(0, 0, 0.95))
		Tween(self.InstructionPart, "CFrame", self.InstructionPart.CFrame * CFrame.new(0, 0, -0.95))
	end

	Tween(self.DesignImage, "ImageTransparency", 0)
	Tween(self.KeyCodeImage, "ImageTransparency", 0)

	Tween(self.ActionUIText, "TextTransparency", 0)
	Tween(self.ObjectUIText, "TextTransparency", 0)
	Tween(self.KeyCodeText, "TextTransparency", 0)

	Tween(self.InstructionBackground, "Transparency", 0.8)
	local FinalTween = Tween(self.KeyCodeBackground, "Transparency", 0)
	FinalTween.Completed:Wait()
end

function Hologram:OnPromptHidden(InputType: Enum.ProximityPromptInputType)
	if not self.ClonedPrompt then return end
	self.isDeleting = true

	if self.ShowBeam then
		BorderHighlight.Adornee = nil
		Tween(self.TransparencyValue, "Value", 1)

		self.Beam.Attachment1 = nil
		self.BeamAttachment.Parent = self.KeyCodePart
	end

	Tween(self.DesignPart, "CFrame", self.DesignPart.CFrame * CFrame.new(0, 0, -0.95))
	Tween(self.InstructionPart, "CFrame", self.InstructionPart.CFrame * CFrame.new(0, 0, 0.95))

	Tween(self.DesignImage, "ImageTransparency", 1)
	Tween(self.KeyCodeImage, "ImageTransparency", 1)

	Tween(self.ActionUIText, "TextTransparency", 1)
	Tween(self.ObjectUIText, "TextTransparency", 1)
	Tween(self.KeyCodeText, "TextTransparency", 1)

	Tween(self.InstructionBackground, "Transparency", 1)
	local FinalTween = Tween(self.KeyCodeBackground, "Transparency", 1)
	FinalTween.Completed:Wait()

	self:DestroyPrompt()
end

function Hologram:PromptHolding()	
	local Fill = TweenService:Create(self.KeyCodeProgress, TweenInfo.new(self.HoldDuration, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(1, 1)})
	Fill:Play()

	local Size = TweenService:Create(self.DesignImage, TweenInfo.new(self.HoldDuration, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0.9, 0.9)})
	Size:Play()

	local function PromptHoldEnded()
		Fill:Cancel()
		Size:Cancel()

		Tween(self.KeyCodeProgress, "Size", UDim2.fromScale(1, 0))
		Tween(self.DesignImage, "Size", UDim2.fromScale(1, 1))

		if self.HoldEndedConnection then
			self.HoldEndedConnection:Disconnect()
		end
	end

	self.HoldEndedConnection = self.Prompt.PromptButtonHoldEnded:Connect(PromptHoldEnded)
end

function Hologram:PromptTriggered()
	if self.HoldDuration > 0 then return end

	local Size = TweenService:Create(self.DesignImage, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0.9, 0.9)})
	Size:Play()
	Size.Completed:Wait()

	TweenService:Create(self.DesignImage, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(1, 1)}):Play()
end

--// Settings

--[[
	Sets whether the Hologram is always visible, despite obstructions.
]]
function Hologram:SetAlwaysOnTop(isOnTop: boolean)
	self.AlwaysOnTop = isOnTop
end

--[[
	Sets primary colour of the Hologram. Default: Blue.
]]
function Hologram:SetPrimaryColour(Colour: Color3)
	self.Colours.Primary = Colour
end

--[[
	Sets secondary colour of the Hologram. Default: Black.
]]
function Hologram:SetSecondaryColour(Colour: Color3)
	self.Colours.Secondary = Colour
end

--[[
	Sets tertiary colour of the Hologram. Default: White.
]]
function Hologram:SetTertiaryColour(Colour: Color3)
	self.Colours.Tertiary = Colour
end

--[[
	Sets Vector3 offset of how far you want the Hologram from its Parent.
]]
function Hologram:SetStudsOffset(StudsOffset: Vector3)
	self.StudsOffset = StudsOffset
end

--[[
	Enable/Disable Beam+Highlight effect.
]]
function Hologram:SetBeam(ShowBeam: boolean)
	self.ShowBeam = ShowBeam
end

--[[
	Sets whether the Hologram acts like a BillboardGui.
]]
function Hologram:SetBillboardActive(isActive: boolean)
	self.BillboardActive = isActive
	self.DynamicUpdateActive = isActive and false 
end

--[[
	Sets whether the Hologram dynamically updates as player moves around.
]]
function Hologram:SetDynamicUpdate(isActive: boolean)
	self.DynamicUpdateActive = isActive
	self.BillboardActive = isActive and false
end

--[[

]]

function Hologram:SetDisabledSides(Sides: {string})
	self.DisabledSides = Sides or {}
end

return Hologram