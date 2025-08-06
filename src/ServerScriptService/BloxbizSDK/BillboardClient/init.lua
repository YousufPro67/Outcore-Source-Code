local BillboardClient = {
	adPart = nil,
	adPartName = nil,
	isAdDisplaying = false,
	debugAPI = nil,

	currentAdFormat = nil,
	currentURL = nil,
	currentURLsDict = { ["blank"] = true },
	currentBloxbizAdId = -1,
	currentBillType = nil,
	currentGIFFPS = nil,
	currentGIFVersion = nil,
	currentGIF = nil,
	currentVideo = nil,
	showAdDisclaimer = nil,

	aggregateImpressionTime = 0,

	viewabilityMetEvent = nil,
	updateAdEvent = nil,

	isClientPart = false,
	clientPartData = nil,
}

local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Utils = require(script.Parent.Utils)
local GIF = require(script.Parent.GIF)
local VideoPlayer = require(script.VideoPlayer)
local Raycast = require(script.Raycast)
local AdRequestStats = require(script.Parent.AdRequestStats)

local LocalPlayer = game:GetService("Players").LocalPlayer
local Cam = workspace.CurrentCamera
local REMOTES_FOLDER_NAME = "BloxbizRemotes"
local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
local impressionEvent = remotesFolder:WaitForChild("ImpressionEvent")
local userIdlingEvent = remotesFolder:WaitForChild("UserIdlingEvent")
local newPlayerEvent = remotesFolder:WaitForChild("NewPlayerEvent")
local adInteractionEvent = remotesFolder:WaitForChild("AdInteractionEvent")

local ConfigReader = require(script.Parent.ConfigReader)

local InternalConfig = require(script.Parent.InternalConfig)

local DETECT_IMPRESSION_WAIT_TIME = InternalConfig.DETECT_IMPRESSION_WAIT_TIME
local IMPRESSION_TIME_UNTIL_IMG_GIF_ROTATION = InternalConfig.IMPRESSION_TIME_UNTIL_IMG_GIF_ROTATION
local DRAW_RAYCAST = InternalConfig.DRAW_RAYCAST
local WAIT_FOR_PART_MAX_TIME = 120
local MAX_RAY_COUNT = 200
local AD_3D_MAX_RAYCAST_DISTANCE = ConfigReader:read("Ad3DMaxRaycastDistance")

function BillboardClient:checkAd()
	if not self.adPart:IsA('Part') then
		error("[SuperBiz] Don't modify the AdUnit's class, it has to be a Part")
	end

	if not self.adPart:FindFirstChild("AdSurfaceGui") then
		error("[SuperBiz] Ad part must have a SurfaceGui attached to it with the name 'AdSurfaceGui'")
	end
end

function BillboardClient:gridOfRays()
	local part = self.adPart

	local topLeftCorner = { 1, 1, -1 } -- top left
	local bottomRightCorner = { -1, -1, -1 }

	local adSizeX = self.adPart.Size.X -- these change based off the which face the gui is on
	local adSizeY = self.adPart.Size.Y

	local numXRays = 8
	local numYRays = 4

	local changeInX = 0.05
	local changeInY = 0.1

	local newPoint = topLeftCorner

	for i = 1, numXRays do
		newPoint[1] = newPoint[1] - changeInX

		local tmp = newPoint[1]
		for j = 1, numYRays do
			newPoint[2] = newPoint[2] - changeInY

			local newPointPos = (part.CFrame * CFrame.new(
				part.size.X / 2 * newPoint[1],
				part.size.Y / 2 * newPoint[2],
				part.size.Z / 2 * newPoint[3]
			)).Position
			local result, _ = self:buildRay(newPointPos)
		end

		newPoint[1] = tmp
	end

	--local corner = {.95, .9, -1}
end

function BillboardClient:getCornerScreenPoints()
	local part = self.adPart

	local FaceToCorners = require(script.FaceToCorners)

	local adCorners = FaceToCorners[part.AdSurfaceGui.Face]

	local corners = {}

	for _, vector in pairs(adCorners) do
		local cornerPos = (part.CFrame * CFrame.new(
			part.size.X / 2 * vector[1],
			part.size.Y / 2 * vector[2],
			part.size.Z / 2 * vector[3]
		)).Position

		--local result, _ = self:buildRay(CornerPos) --debug only, remove after
		--local vectorToCorner = BillboardClient:vectorFromCameraToPosition(CornerPos) -- debug only

		local screenVector, onScreen = Cam:WorldToViewportPoint(cornerPos)

		if not onScreen then
			if screenVector.X < 0 then
				screenVector = Vector3.new(0, screenVector.Y, screenVector.Z)
			elseif screenVector.X > Cam.ViewportSize.X then
				screenVector = Vector3.new(Cam.ViewportSize.X, screenVector.Y, screenVector.Z)
			end

			if screenVector.Y < 0 then
				screenVector = Vector3.new(screenVector.X, 0, screenVector.Z)
			elseif screenVector.Y > Cam.ViewportSize.Y then
				screenVector = Vector3.new(screenVector.X, Cam.ViewportSize.Y, screenVector.Z)
			end
		end

		table.insert(corners, screenVector)
	end

	return corners
end

function BillboardClient:vectorFromCameraToPosition(position)
	local cf = Cam.CFrame
	local origin = cf.Position
	local vector = position - origin

	return vector
end

function BillboardClient:isFirstPerson(head)
	return (head.CFrame.p - Cam.CFrame.p).Magnitude < 1.75
end

function BillboardClient:buildRay(position)
	local params = RaycastParams.new()
	local raycastFilterList = ConfigReader:read("RaycastFilterList")()

	params.FilterType = ConfigReader:read("RaycastFilterType")

	if params.FilterType == Enum.RaycastFilterType.Blacklist then
		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()

		local head = character:FindFirstChild("Head")

		if head and self:isFirstPerson(head) then
			local characterParts = character:GetDescendants()

			for _, part in ipairs(characterParts) do
				table.insert(raycastFilterList, part)
			end
		end
	end

	params.FilterDescendantsInstances = raycastFilterList

	local ray = Raycast.new(params, 0, false, false, 0)

	local cf = Cam.CFrame
	local origin = cf.Position
	local vector = position - origin
	local direction = vector.unit
	local distance = vector.Magnitude
	local result = ray:Raycast(origin, direction * distance)

	if DRAW_RAYCAST then
		self:drawRaycast(origin, distance, position)
	end

	return result, vector
end

function BillboardClient:areaOfTriangle(A, B, C)
	return math.abs((A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y)) / 2)
end

-- TODO: Take into account obstruction of ad when measuring the area
function BillboardClient:getSizeAtDistance()
	local viewportSize = Cam.ViewportSize

	local cornerPoints = BillboardClient:getCornerScreenPoints()

	local areaOfTriangle1 = BillboardClient:areaOfTriangle(cornerPoints[1], cornerPoints[2], cornerPoints[3])
	local areaOfTriangle2 = BillboardClient:areaOfTriangle(cornerPoints[3], cornerPoints[4], cornerPoints[1])

	local areaOfAd = areaOfTriangle1 + areaOfTriangle2

	local screenArea = viewportSize.Y * viewportSize.X

	local screenCoveragePercentage = areaOfAd / screenArea * 100
	local width = math.abs(cornerPoints[2].x - cornerPoints[3].x)
	local height = math.abs(cornerPoints[2].y - cornerPoints[1].y)

	return screenArea, screenCoveragePercentage, width, height
end

function BillboardClient:drawRaycast(origin, distance, position)
	local p = Instance.new("Part")
	p.Name = "Raycast"
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.1, 0.1, distance)
	p.CFrame = lookAt(position, origin) * CFrame.new(0, 0, -distance / 2)
	p.Parent = workspace
end

function BillboardClient:detectRaycast()
	local prevTransparency = self.adPart.Transparency
	self.adPart.Transparency = 0
	local result, vector = self:buildRay(self.adPart.Position)
	self.adPart.Transparency = prevTransparency

	--if result then
	--	print(result.Instance:GetFullName())
	--end

	if result and result.Instance == self.adPart then
		--detect side
		if normalToFace(result.Normal, self.adPart, { self.adPart.AdSurfaceGui.Face }) then
			local viewAngle = 180 - math.deg(math.acos(vector.Unit:Dot(result.Normal.Unit)))

			return vector, viewAngle
		end
	else
		--print(Result.Instance.Name)
		return false
	end
end

function lookAt(target, eye)
	local forwardVector = (target - eye).Unit
	local upVector = Vector3.new(0, 1, 0)
	-- Remember the right-hand rule
	local rightVector = forwardVector:Cross(upVector)
	local upVector2 = rightVector:Cross(forwardVector)

	return CFrame.fromMatrix(eye, rightVector, upVector2)
end

--[[**
   https://devforum.roblox.com/t/how-do-you-find-the-side-of-a-part-using-raycasting/655452/2
   ^Taken from here and modified
   
   This function returns the face that we hit on the given part based on
   an input normal. If the normal vector is not within a certain tolerance of
   any face normal on the part, we return nil.

    @param normalVector (Vector3) The normal vector we are comparing to the normals of the faces of the given part.
    @param part (BasePart) The part in question.

    @return (Enum.NormalId) The face we hit.
**--]]
function normalToFace(normalVector, part, facesToCheck)
	local TOLERANCE_VALUE = 1 - 0.001

	for _, normalId in pairs(facesToCheck) do
		-- If the two vectors are almost parallel,
		if getNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
			return true -- We found it!
		end
	end

	return false -- None found within tolerance.
end

--[[**
    This function returns a vector representing the normal for the given
    face of the given part.

    @param part (BasePart) The part for which to find the normal of the given face.
    @param normalId (Enum.NormalId) The face to find the normal of.

    @returns (Vector3) The normal for the given face.
**--]]
function getNormalFromFace(part, normalId)
	return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

function BillboardClient:detectScreenpoint()
	local _, onScreen = Cam:WorldToViewportPoint(self.adPart.Position)

	if onScreen then
		return true
	else
		return false
	end
end

function BillboardClient:sendImpression(adUrl, bloxbizAdId, timestamp, timeSeen, rays, isClientPart)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(LocalPlayer)
	local clientGuid = HttpService:GenerateGUID(false)
	local adPart = (not isClientPart and self.adPart) or AdRequestStats:getPartStats(self.adPart)

	impressionEvent:FireServer(
		clientPlayerStats,
		adUrl,
		bloxbizAdId,
		adPart,
		timestamp,
		timeSeen,
		rays,
		clientGuid,
		isClientPart,
		self.currentAdFormat
	)
end

function BillboardClient:sendInteraction(interactionType, ...)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(LocalPlayer)
	local adUrl = self.adPart.AdSurfaceGui.ImageLabel.Image
	local bloxbizAdId = self.currentBloxbizAdId

	if interactionType == "hover" then
		local hoverTime = (...)
		local startTime = os.time() - hoverTime
		adInteractionEvent:FireServer(
			interactionType,
			clientPlayerStats,
			adUrl,
			bloxbizAdId,
			self.adPart,
			startTime,
			hoverTime
		)
	elseif interactionType == "click" then
		local startTime = os.time()
		adInteractionEvent:FireServer(interactionType, clientPlayerStats, adUrl, bloxbizAdId, self.adPart, startTime)
	end
end

function BillboardClient:sendUserIdling(time)
	Utils.pprint("[SuperBiz] Player has been idle for " .. time .. " seconds")
	userIdlingEvent:FireServer(time)
end

function BillboardClient:sendNewPlayer()
	newPlayerEvent:FireServer(AdRequestStats:getClientPlayerStats(LocalPlayer))
end

function BillboardClient:needsAdRotationForImgOrGifAd()
	local impressionLimited = self.aggregateImpressionTime >= IMPRESSION_TIME_UNTIL_IMG_GIF_ROTATION
	local isNotPopUpShopOr3dAd = not self.isClientPart
	local isImageAd = not self.currentGIF and not self.currentVideo
	local isGifAd = not isImageAd and self.currentGIF

	if (isImageAd or isGifAd) and impressionLimited and isNotPopUpShopOr3dAd then
		return true
	else
		return false
	end
end

function BillboardClient:requestAdRotation()
	self.updateAdEvent:FireServer(AdRequestStats:getClientPlayerStats(LocalPlayer))
end

function BillboardClient:waitOrDeletePart()
	while self.adPart == nil or self.adPart.Parent == nil do
		self.isAdDisplaying = false

		local adHasLoaded = remotesFolder:WaitForChild("updateAdEvent-" .. self.adPartName, 5)

		if not adHasLoaded then
			Utils.pprint("[SuperBiz] Ad client stopped!")

			self:cleanupGif()
			self:cleanupVideo()
			script:Destroy()

			return false
		else
			self.adPart = BillboardClient:waitForPart(self.adPartName, WAIT_FOR_PART_MAX_TIME)
		end
	end

	return self.adPart
end

function BillboardClient:backgroundProcess()
	while true do
		if self.debugAPI and self.adPart and self.adPart.Parent then
			self.debugAPI.EndImpression(self.adPart.AdSurfaceGui)
		end

		if not self:waitOrDeletePart() then
			return
		end

		local isImageAd = not self.currentGIF and not self.currentVideo
		if not self.isAdDisplaying and self.currentURL and isImageAd then
			self:displayAd(
				self.currentAdFormat,
				self.currentURL,
				self.currentBloxbizAdId,
				self.currentAdExternalLinkReferences,
				self.currentGIFFPS,
				self.currentGIFVersion,
				self.currentAudioUrl,
				self.showAdDisclaimer,
				self.ad_disclaimer_url,
				self.ad_disclaimer_scale_x,
				self.ad_disclaimer_scale_y,
				self.currentBillType
			)
		end

		self.isAdDisplaying = true

		local success, result = pcall(function()
			BillboardClient:detectAndMeasureImpression()
		end)

		if not success or self.adPart.Parent == nil then
			if result then
				Utils.pprint("[SuperBiz] Error: " .. result)
			else
				Utils.pprint("[SuperBiz] Warning: Ad part has no parent. Possibly due to streaming.")
			end
		end

		if self:needsAdRotationForImgOrGifAd() then
			self:requestAdRotation()
		end

		task.wait(DETECT_IMPRESSION_WAIT_TIME)
	end
end

function timeInMs()
	return os.clock()
end

function BillboardClient:detectAndMeasureImpression()
	local cf = Cam.CFrame
	local origin = cf.Position
	local vector = self.adPart.Position - origin
	local direction = vector.unit
	local distance = vector.Magnitude

	if self.isClientPart and distance > AD_3D_MAX_RAYCAST_DISTANCE then
		return
	end

	local vector, viewAngle = self:detectImpression()
	if vector then
		local adArea, adPercentageOfScreen, width, height = self:getSizeAtDistance(distance)

		local timestamp = os.time()
		local timeStart = timeInMs()
		local adUrl = self.adPart.AdSurfaceGui.ImageLabel.Image
		local bloxbizAdId = self.currentBloxbizAdId
		local currentURLsDict = self.currentURLsDict
		local currentVideoAd = self.currentVideo

		if not currentURLsDict[adUrl] and not self.isClientPart then
			task.wait(DETECT_IMPRESSION_WAIT_TIME)
			return
		end

		local rays = { { timeStart, viewAngle, adPercentageOfScreen } }

		local IUI = nil
		if self.debugAPI then
			IUI = self.debugAPI.StartImpression(self.adPart.AdSurfaceGui, {
				URL = adUrl,
				PixelWidth = width,
				PixelHeight = height,
				Time = 0,
				VideoTime = 0,
				Per = adPercentageOfScreen,
				Angle = viewAngle,
			})
		end

		local rayCount = 1
		local impressionTime = 0
		local initialAggregateImpressionTime = self.aggregateImpressionTime

		--If ad changes while user is looking at ad or user stops looking at ad, end the impression
		local imageLabelValid = self.isClientPart
			or (not self.isClientPart and currentURLsDict[self.adPart.AdSurfaceGui.ImageLabel.Image])
		local videoAdNotRotated = currentVideoAd == self.currentVideo
		while imageLabelValid and videoAdNotRotated and rayCount < MAX_RAY_COUNT and not self:needsAdRotationForImgOrGifAd() do
			local vector, viewAngle = self:detectImpression()
			if vector then
				local adArea, adPercentageOfScreen = self:getSizeAtDistance()
				self.viewabilityMetEvent:Fire(true, adPercentageOfScreen, viewAngle)
				table.insert(rays, { timeInMs(), viewAngle, adPercentageOfScreen })

				if self.debugAPI then
					local videoAnalytics = self.currentVideo and self.currentVideo:getAnalytics()
					local videoTime = videoAnalytics and videoAnalytics.playEndSeconds or 0

					self.debugAPI.UpdateImpressions(IUI, {
						URL = adUrl,
						PixelWidth = width,
						PixelHeight = height,
						Time = timeInMs() - timeStart,
						VideoTime = videoTime,
						Per = adPercentageOfScreen,
						Angle = viewAngle,
					})
				end
			else
				self.viewabilityMetEvent:Fire(false)
				break
			end

			rayCount += 1
			task.wait(DETECT_IMPRESSION_WAIT_TIME)

			local timeEnd = timeInMs()
			impressionTime = timeEnd - timeStart
			self.aggregateImpressionTime = initialAggregateImpressionTime + impressionTime

			imageLabelValid = self.isClientPart
				or (not self.isClientPart and currentURLsDict[self.adPart.AdSurfaceGui.ImageLabel.Image])
			videoAdNotRotated = currentVideoAd == self.currentVideo
		end

		if self.debugAPI then
			local videoAnalytics = self.currentVideo and self.currentVideo:getAnalytics()
			local videoTime = videoAnalytics and videoAnalytics.playEndSeconds or 0

			self.debugAPI.UpdateImpressions(IUI, {
				URL = adUrl,
				PixelWidth = width,
				PixelHeight = height,
				Time = timeInMs() - timeStart,
				VideoTime = videoTime,
				Per = adPercentageOfScreen,
				Angle = viewAngle,
			})
			self.debugAPI.EndImpression(self.adPart.AdSurfaceGui)
		end

		self:sendImpression(adUrl, bloxbizAdId, timestamp, impressionTime, rays, self.isClientPart)
	else
		--Utils.pprint("[SuperBiz] " .. self.adPart.Name .. " No impression")
	end
end

function BillboardClient:detectImpression()
	if self:detectScreenpoint() then
		return self:detectRaycast()
	else
		return false
	end
end

function BillboardClient:setDisclaimer(visible, adDisclaimerUrl, adDisclaimerScaleX, adDisclaimerScaleY)
	local doesntHaveDisclaimerGUI = self.isClientPart == true
	if doesntHaveDisclaimerGUI then
		return
	end

	local adDisclaimerLabel = self.adPart.AdSurfaceGui.DisclaimerHolder.AdDisclaimerLabel

	adDisclaimerLabel.Visible = visible
	adDisclaimerLabel.Image = adDisclaimerUrl
	adDisclaimerLabel.Size = UDim2.new(adDisclaimerScaleX, 0, adDisclaimerScaleY, 0)
end

function BillboardClient:preloadList(listToPreload)
	task.spawn(function()
		ContentProvider:PreloadAsync(listToPreload)
	end)
end

function tableToDict(values)
	local dict = {}

	for _, value in ipairs(values) do
		dict[value] = true
	end

	return dict
end

function BillboardClient:cleanupGif()
	if self.currentGIF then
		self.currentGIF:cleanup()
		self.currentGIF = nil
	end
end

function BillboardClient:cleanupVideo()
	if self.currentVideo then
		self.currentVideo:cleanup()
		self.currentVideo = nil
	end
end

function BillboardClient:isAdCompliantWithPolicy(adExternalLinkReferences)
	if #adExternalLinkReferences == 0 then
		return true
	end

	local allowedExternalLinkReferences = AdRequestStats:getPlayerPolicyInfo(LocalPlayer).AllowedExternalLinkReferences
	allowedExternalLinkReferences = tableToDict(allowedExternalLinkReferences)

	local isCompliant = true

	for _, link in ipairs(adExternalLinkReferences) do
		if not allowedExternalLinkReferences[link] then
			isCompliant = false
			break
		end
	end

	return isCompliant
end

function BillboardClient:displayAd(
	adFormat,
	adUrl,
	bloxbizAdId,
	adExternalLinkReferences,
	gifFPS,
	gifVersion,
	audioUrl,
	showAdDisclaimer,
	adDisclaimerUrl,
	adDisclaimerScaleX,
	adDisclaimerScaleY,
	billType
)
	if not self:isAdCompliantWithPolicy(adExternalLinkReferences) then
		return
	end

	local adUrlArray = adUrl

	if (adFormat == "gif" or adFormat == "video") and gifVersion ~= 1 then
		adUrlArray = {}

		for _, adData in ipairs(adUrl) do
			table.insert(adUrlArray, adData.ad_url)
		end
	end

	self.currentAdFormat = adFormat
	self.currentURL = adUrl
	self.currentURLsDict = tableToDict(adUrlArray)
	self.currentBloxbizAdId = bloxbizAdId
	self.currentBillType = billType
	self.currentAdExternalLinkReferences = adExternalLinkReferences

	self.currentGIFFPS = gifFPS
	self.currentGIFVersion = gifVersion
	self.currentAudioUrl = audioUrl

	self.aggregateImpressionTime = 0

	self.showAdDisclaimer = showAdDisclaimer
	self.ad_disclaimer_url = adDisclaimerUrl
	self.ad_disclaimer_scale_x = adDisclaimerScaleX
	self.ad_disclaimer_scale_y = adDisclaimerScaleY

	local success, result = pcall(function()
		self:setDisclaimer(showAdDisclaimer, adDisclaimerUrl, adDisclaimerScaleX, adDisclaimerScaleY)

		self:cleanupGif()
		self:cleanupVideo()

		if adFormat == "static" then
			self.adPart.AdSurfaceGui.ImageLabel.Image = adUrl[1]
		elseif adFormat == "gif" then
			if not self.currentGIF then
				self.currentGIF = GIF:init(adUrl, gifFPS, self.adPart, gifVersion)
			end
		elseif adFormat == "video" then
			if not self.currentVideo then
				self.currentVideo =
					VideoPlayer:init(self, adUrl, gifFPS, self.adPart, gifVersion, audioUrl, bloxbizAdId, billType)
			end
		end
	end)
end

function BillboardClient:waitForPart(partName, timeout)
	local ancestors = partName:split(".")
	table.remove(ancestors, 1)

	local current = workspace

	for _, name in ipairs(ancestors) do
		current = current:WaitForChild(name, timeout)
	end

	return current
end

function BillboardClient:initAd(partName, clientPart, clientPartData)
	local part = nil
	local updateAdEvent = nil

	local debugModeEnabled = ConfigReader:read("DebugMode") or ConfigReader:read("DebugModeVideoAd")
    if debugModeEnabled then
		self.debugAPI = require(ConfigReader:read("DebugAPI")())
	end

	if clientPart then
		part = clientPart
		self.isClientPart = true
	else
		self.isClientPart = false
	end

	while part == nil do
		part = BillboardClient:waitForPart(partName, WAIT_FOR_PART_MAX_TIME)
		updateAdEvent = remotesFolder:WaitForChild("updateAdEvent-" .. partName, 5)

		if updateAdEvent == nil then
			Utils.pprint("[SuperBiz] Ad client never started, possibly due to streaming.")
			script:Destroy()
			return
		end
	end

	Utils.pprint("[SuperBiz] Ad client started!")
	self.adPart = part
	self.adPartName = partName
	self.viewabilityMetEvent = Instance.new("BindableEvent")
	self.updateAdEvent = updateAdEvent

	self:checkAd()

	if not self.isClientPart then
		updateAdEvent.OnClientEvent:Connect(function(ad)
			local adUrl = ad["ad_url"]
			local adFormat = ad["ad_format"]
			local bloxbizAdId = ad["bloxbiz_ad_id"]
			local adExternalLinkReferences = ad["external_link_references"]

			local gifFPS = ad["gif_fps"]
			local gifVersion = ad["gif_version"]
			local audioUrl = ad["audio_url"]
			local billType = ad["bill_type"]

			local showAdDisclaimer = ad["show_ad_disclaimer"]
			local adDisclaimerUrl = ad["ad_disclaimer_url"]
			local adDisclaimerScaleX = ad["ad_disclaimer_scale_x"]
			local adDisclaimerScaleY = ad["ad_disclaimer_scale_y"]

			self:displayAd(
				adFormat,
				adUrl,
				bloxbizAdId,
				adExternalLinkReferences,
				gifFPS,
				gifVersion,
				audioUrl,
				showAdDisclaimer,
				adDisclaimerUrl,
				adDisclaimerScaleX,
				adDisclaimerScaleY,
				billType
			)
		end)

		--local TrackInteraction = require(script.TrackInteraction)
		--TrackInteraction:init(BillboardClient)
	elseif self.isClientPart then
		if clientPartData then
			self.clientPartData = clientPartData
			self.currentBloxbizAdId = clientPartData.bloxbiz_ad_id
		elseif self.adPart:FindFirstChild("BLOXBIZ_CONSTANT_ID") then
			self.currentBloxbizAdId = self.adPart.BLOXBIZ_CONSTANT_ID.Value
		end
	end

	spawn(function()
		self:backgroundProcess()
	end)
end

return BillboardClient
