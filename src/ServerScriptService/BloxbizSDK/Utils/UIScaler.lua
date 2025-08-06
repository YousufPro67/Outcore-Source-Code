--// Awesom3_Eric
--// 7/22/2022 @ 1:47AM
--// UIComponentsAdjuster

--// Unsorted
--// 4/25/2023 @ 1:12 AM
--// UI Text Scaler

local STUDIO_VIEWPORT_SIZE = Vector2.new(1920, 1079)

local BILLBOARD_TAG = "SuperBizBillboard"
local SCREEN_GUI_TAG = "SuperBizScreenGui"
local SCREEN_STROKE_TAG = "SuperBizScreenStroke"
local SCREEN_TEXT_TAG = "SuperBizScreenText"

local AUTO_TAG = false

local TEXT_SIZE_OFFSET = 7
local BILLBOARD_DISTANCE = 10 -- Estimated distance if "Distance" attribute of BillboardGui is not set

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui", 100)

local camera = workspace.CurrentCamera

local function average(vector: Vector2): number
	return (vector.X + vector.Y) / 2
end

local function getScreenRatio(): number
	return average(camera.ViewportSize) / average(STUDIO_VIEWPORT_SIZE)
end

-- Listens for added instances
local function tagRecursive(instance: Instance, objectType: string, tag: string)
	if instance:IsA(objectType) then
		CollectionService:AddTag(instance, tag)
	end
	for _, child in instance:GetChildren() do
		tagRecursive(child, objectType, tag)
	end
	instance.ChildAdded:Connect(function(child)
		tagRecursive(child, objectType, tag)
	end)
end

local function getInstancePosition(instance: Instance): Vector3
	if instance:IsA("Part") then
		return instance.Position
	elseif instance:IsA("Model") then
		local cf, _ = instance:GetBoundingBox()
		return cf.Position
	end
	return Vector3.new(0, 0, 0)
end

local ScreenStrokes = {}
local ScreenTexts = {}

CollectionService:GetInstanceAddedSignal(SCREEN_GUI_TAG):Connect(function(screenGui: ScreenGui)
	tagRecursive(screenGui, "UIStroke", SCREEN_STROKE_TAG)
	tagRecursive(screenGui, "TextLabel", SCREEN_TEXT_TAG)
	tagRecursive(screenGui, "TextBox", SCREEN_TEXT_TAG)
	tagRecursive(screenGui, "TextButton", SCREEN_TEXT_TAG)
end)

CollectionService:GetInstanceAddedSignal(SCREEN_STROKE_TAG):Connect(function(uiStroke: UIStroke)
	ScreenStrokes[uiStroke] = uiStroke.Thickness
	uiStroke.Thickness *= getScreenRatio()
end)

CollectionService:GetInstanceAddedSignal(SCREEN_TEXT_TAG):Connect(function(textObject: TextLabel & TextBox & TextButton)
	ScreenTexts[textObject] = textObject.TextSize
	-- textObject.TextSize *= getScreenRatio()
	-- textObject.TextSize += TEXT_SIZE_OFFSET

	if string.find(textObject.Name, "_custom_font") then
		return
	end

	textObject.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
end)

--|| BillboardGui Updating ||--

-- Initializes thickness update on BillboardGui's UIStrokes
CollectionService:GetInstanceAddedSignal(BILLBOARD_TAG):Connect(function(billboardGui: BillboardGui)
	-- Index BillboardGui's UIStrokes recursively
	local BillboardStrokes = {}
	local function getUiStrokeFromInstance(instance: Instance)
		if instance:IsA("UIStroke") then
			BillboardStrokes[instance] = instance.Thickness
		end
		for _, uiStroke in instance:GetChildren() do
			getUiStrokeFromInstance(uiStroke)
		end
		instance.ChildAdded:Connect(getUiStrokeFromInstance)
	end
	getUiStrokeFromInstance(billboardGui)

	-- Update UIStrokes
	local update
	update = RunService.Heartbeat:Connect(function()
		-- Disconnect if BillboardGui is deleted
		if not billboardGui.Parent then
			update:Disconnect()
		else
			-- Update
			local adornee = billboardGui.Adornee
			local origin = adornee and getInstancePosition(adornee) or getInstancePosition(billboardGui.Parent)
			local magnitude = (workspace.CurrentCamera.CFrame.Position - origin).Magnitude
			local distanceRatio = ((billboardGui:GetAttribute("Distance") or BILLBOARD_DISTANCE) / magnitude)
			for stroke, originalThickness in BillboardStrokes do
				if not stroke.Parent then
					BillboardStrokes[stroke] = nil
				else
					stroke.Thickness = originalThickness * distanceRatio * getScreenRatio()
				end
			end
		end
	end)
end)

-- Automatically tag ScreenGuis and BillboardGuis in PlayerGui if Auto_Tag == true
if AUTO_TAG then
	tagRecursive(PlayerGui, "ScreenGui", SCREEN_GUI_TAG)
	tagRecursive(PlayerGui, "BillboardGui", BILLBOARD_TAG)
end

--|| Module Functions ||--
local UIComponentsAdjuster = {}

function UIComponentsAdjuster:TagScreenGui(screenGui: ScreenGui)
	if screenGui:IsA("ScreenGui") then
		CollectionService:AddTag(screenGui, SCREEN_GUI_TAG)
	end
end

function UIComponentsAdjuster:TagBillboardGui(billboardGui: BillboardGui)
	if billboardGui:IsA("BillboardGui") then
		CollectionService:AddTag(billboardGui, BILLBOARD_TAG)
	end
end

return UIComponentsAdjuster
