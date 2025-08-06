local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

local raycastModule = require(script.Parent.Raycast)

local CAMERA_TWEEN = "BLOXBIZ_CAMERA_TWEEN"
local GET_CF = "BLOXBIZ_CAMERA_CF_FETCH"

local module = {}
module.cameraTweenActive = false
module.currentCameraTween = nil
module.currentCameraCf = nil
module.transparencyModule = nil
module.previousMinZoom = nil

function module.getCameraModuleCf()
	local cameraModuleCf = nil

	RunService:BindToRenderStep(GET_CF, Enum.RenderPriority.Camera.Value + 1, function()
		if Workspace.CurrentCamera then
			cameraModuleCf = Workspace.CurrentCamera.CFrame
		end
	end)

	repeat
		task.wait()
	until cameraModuleCf

	return cameraModuleCf
end

function module.makeCharacterVisible()
	module.transparencyModule:Update()
	module.transparencyModule.transparencyDirty = true
end

function module.storeCharacterTransparency(character)
	module.PreviousCharacterTransparency = {}
	module.transparencyModule =
		require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule").CameraModule.TransparencyController).new()
	module.transparencyModule:SetupTransparency(character)

	for i, _ in pairs(module.transparencyModule.cachedParts) do
		module.PreviousCharacterTransparency[i] = i.LocalTransparencyModifier
	end
end

function module.restoreCharacterTransparency()
	for i, _ in pairs(module.transparencyModule.cachedParts) do
		i.LocalTransparencyModifier = module.PreviousCharacterTransparency[i]
	end
end

function module.getInteractionPosition(adModelData, adBoxModel, characterModel)
	local modelCenterPart = characterModel.PrimaryPart
	local validPosition

	for degree = 270, -90, -15 do
		local radius = adModelData.camera_distance
		local camera_height_offset = adModelData.camera_height
		local position = modelCenterPart.CFrame
			* CFrame.new(radius * math.cos(math.rad(degree)), camera_height_offset, radius * math.sin(math.rad(degree)))
		position = position.Position

		local raycastPart = raycastModule.raycastPositionToPart(position, modelCenterPart)

		if
			raycastPart
			and (raycastPart == modelCenterPart or raycastPart:FindFirstAncestor(adBoxModel.Name) == adBoxModel)
		then
			validPosition = position
			break
		end
	end

	return validPosition
end

function module.getPlayerAngle(adBoxModel, playerCharacter)
	local cf = adBoxModel.AdModel.PrimaryPart.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0, 0, 1)))
	local p1 = adBoxModel.AdModel.PrimaryPart.Position
	local p2 = playerCharacter.PrimaryPart.Position
	local p1Dir = (p1 - cf.Position).Unit
	local p2Dir = (p2 - cf.Position).Unit

	return math.floor(math.deg(math.atan2(p1Dir:Cross(p2Dir).Magnitude, p1Dir:Dot(p2Dir))))
end

function module.setCamera(adModelData, adBoxModel, characterModel, tweenTime)
	if module.cameraTweenActive or module.currentCameraTween then
		return
	end

	local positionToSet = module.getInteractionPosition(adModelData, adBoxModel, characterModel)

	if not positionToSet then
		return false
	end

	local camera = Workspace.CurrentCamera

	--Developer has their own plans for the camera
	if camera.CameraType ~= Enum.CameraType.Custom then
		return false
	end

	local customPosition = characterModel:FindFirstChild("CustomCameraCf")
	local playerInFrontOfAd = module.getPlayerAngle(adBoxModel, LocalPlayer.Character) < 50
	if customPosition and not playerInFrontOfAd then
		positionToSet = (adBoxModel.AdModel.PrimaryPart.CFrame * customPosition.Value).Position
	end

	module.cameraTweenActive = true

	local cfValue = script:FindFirstChild("currentCameraCf")

	if not cfValue then
		cfValue = Instance.new("CFrameValue")
		cfValue.Name = "currentCameraCf"
		cfValue.Parent = script
		module.currentCameraCf = cfValue
	end

	--Remove first person temporarily + fixes player transparency conflicts
	module.previousMinZoom = LocalPlayer.CameraMinZoomDistance
	LocalPlayer.CameraMinZoomDistance = 15

	cfValue.Value = camera.CFrame
	--camera.CameraType = Enum.CameraType.Scriptable
	--module.storeCharacterTransparency(LocalPlayer.Character)
	--module.makeCharacterVisible()

	local modelCenterPartCf = characterModel.PrimaryPart.CFrame
	local cframeToSet = CFrame.new(positionToSet)
	cframeToSet = CFrame.new(cframeToSet.Position, modelCenterPartCf.Position)

	local tweenInfo = TweenInfo.new(tweenTime or 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local propertyTable = { Value = cframeToSet }
	local cameraTween = TweenService:Create(cfValue, tweenInfo, propertyTable)

	module.currentCameraTween = cameraTween
	cameraTween:Play()

	RunService:BindToRenderStep(CAMERA_TWEEN, Enum.RenderPriority.Last.Value + 999, function()
		camera.CFrame = cfValue.Value
	end)

	return true
end

function module.resetCamera(tweenTime)
	if module.cameraTweenActive == false then
		return
	end

	module.cameraTweenActive = false

	local camera = Workspace.CurrentCamera
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	camera.CameraSubject = character:WaitForChild("Humanoid")
	--camera.CameraType = Enum.CameraType.Custom
	--module.restoreCharacterTransparency(LocalPlayer.Character)
	LocalPlayer.CameraMinZoomDistance = module.previousMinZoom

	local cfValue = script:FindFirstChild("currentCameraCf")
	cfValue.Value = camera.CFrame
	module.currentCameraCf = cfValue

	local cframeToSet = module.getCameraModuleCf()

	local tweenInfo = TweenInfo.new(tweenTime or 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local propertyTable = { Value = cframeToSet }
	local cameraTween = TweenService:Create(cfValue, tweenInfo, propertyTable)

	module.currentCameraTween = cameraTween
	cameraTween:Play()

	RunService:UnbindFromRenderStep(CAMERA_TWEEN)
	RunService:BindToRenderStep(CAMERA_TWEEN, Enum.RenderPriority.Last.Value + 999, function()
		camera.CFrame = cfValue.Value
	end)

	task.wait(tweenTime or 0.3)

	RunService:UnbindFromRenderStep(CAMERA_TWEEN)
	module.currentCameraTween = nil
end

return module
