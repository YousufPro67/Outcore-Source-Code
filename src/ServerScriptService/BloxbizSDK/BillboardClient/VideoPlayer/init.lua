local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local GIF = require(script.Parent.Parent.GIF)
local ConfigReader = require(script.Parent.Parent.ConfigReader)
local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local BillboardInputHelper = require(script.Parent.BillboardInputHelper)
local VideoFrame = require(script.VideoFrame)

local REMOTES_FOLDER_NAME = "BloxbizRemotes"

local VOLUME_ON_NUM = 1
local VOLUME_ON_ICON = "http://www.roblox.com/asset/?id=10647668132"

local VOLUME_OFF_NUM = 0
local VOLUME_OFF_ICON = "http://www.roblox.com/asset/?id=10647669422"

local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
local videoPlayedEvent = remotesFolder:WaitForChild("VideoPlayedEvent")

local VideoPlayer = {}
VideoPlayer.lastAudioData = {--[[
    [adUnitReference] = {bloxbiz_ad_id = 123123; isAudioOn = T/F}
]]
}

function VideoPlayer:saveAudioToggle()
	VideoPlayer.lastAudioData[self.adPart] = {
		bloxbizAdId = self.bloxbizAdId,
		isAudioOn = self.isAudioOn,
	}
end

function VideoPlayer:loadAudioIfSameVideoAd()
	local saveData = VideoPlayer.lastAudioData[self.adPart]
	local turnedAudioOn = nil

	if saveData then
		local loadedSameVideo = self.bloxbizAdId == saveData.bloxbizAdId
		local wasAudioOn = saveData.isAudioOn

		if loadedSameVideo then
			if wasAudioOn then
				self:turnAudioOn()
				self.videoFrame.AudioLabel.ImageTransparency = 1
				turnedAudioOn = true
			elseif not wasAudioOn then
				self:turnAudioOff()
				turnedAudioOn = false
			end
		end
	end

	self.audioToggleDataLoaded = true

	return turnedAudioOn
end

function VideoPlayer:pausePlayer(timePosition)
	self.GIF:pause(timePosition)

	local frameNumOnLastResume = self.analyticsData.frameNumOnLastResume

	if frameNumOnLastResume == nil then
		return
	end

	local frameDifference = self.GIF.runData.currentFrame - frameNumOnLastResume

	--GIF module starts at frame 1 not 0
	frameDifference += 1

	local playtime = frameDifference / self.GIF.framerate
	if playtime > self.analyticsData.maxContinuousPlaytime then
		self.analyticsData.maxContinuousPlaytime = playtime
	end
end

function VideoPlayer:resumePlayer(timePosition)
	self.GIF:resume(timePosition)

	self.analyticsData.numResumes += 1
	self.analyticsData.frameNumOnLastResume = self.GIF.runData.currentFrame
end

function VideoPlayer:getAnalytics()
	return {
		["playEndPercentage"] = self.GIF.runData.currentFrame / self.GIF.frameCount,
		["playEndSeconds"] = self.GIF.runData.currentFrame / self.GIF.framerate,
		["numResumes"] = self.analyticsData.numResumes,
		["audioActiveSeconds"] = self.GIF.runData.audioActiveSumFrames / self.GIF.framerate,
		["maxContinuousPlaytime"] = self.analyticsData.maxContinuousPlaytime,
	}
end

function VideoPlayer:sendAnalytics()
	if self.analyticsData.analyticsSent then
		return
	end

	self.analyticsData.analyticsSent = true

	local playStats = self:getAnalytics()
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(LocalPlayer)
	local clientGUID = HttpService:GenerateGUID(false)

	videoPlayedEvent:FireServer(playStats, clientPlayerStats, self.bloxbizAdId, self.adPart, clientGUID, self.billType)
end

function VideoPlayer:cleanup()
	if self.isLoading then
		self.cleanupAfterLoading = true
		return
	end

	if self.videoFrame then
		self.videoFrame:Destroy()
	end

	local gifWasPlayed = self.analyticsData.frameNumOnLastResume ~= nil
	if gifWasPlayed then
		self:pausePlayer()
		self:sendAnalytics()
	end

	self.GIF:cleanup()

	if self.viewabilityConnection then
		self.viewabilityConnection:Disconnect()
	end

	if self.audioToggleDataLoaded then
		self:saveAudioToggle()
	end

	for _, connection in pairs(self.inputConnections) do
		connection:Disconnect()
	end

	BillboardInputHelper:removeBillboard(self.adPart)
end

function VideoPlayer:turnAudioOn()
	self.isAudioOn = true
	self.GIF:setVolume(VOLUME_ON_NUM)

	self.videoFrame.AudioLabel.Image = VOLUME_ON_ICON
end

function VideoPlayer:turnAudioOff()
	self.isAudioOn = false
	self.GIF:setVolume(VOLUME_OFF_NUM)

	self.videoFrame.AudioLabel.Image = VOLUME_OFF_ICON
end

local function getCameraCframe(adPart, cameraDistanceMultiplier)
    local cframe, size = adPart.CFrame, adPart.Size
    local biggestSize = size.Y

    local cameraDistance = (biggestSize / 2) / math.tan(Camera.FieldOfView / 2)
	if cameraDistanceMultiplier then
		cameraDistance *= cameraDistanceMultiplier
	end

    cframe = (cframe + (cframe.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)

    return cframe
end

local savedCameraPosition

function VideoPlayer:zoomIn()
	if not ConfigReader:read("VideoZoomEnabled") then
		return
	end

	self.isZoomed = true

	savedCameraPosition = Camera.CFrame

	local cframe = getCameraCframe(self.adPart)
    Camera.CameraType = Enum.CameraType.Scriptable

    TweenService:Create(Camera, TweenInfo.new(0.3), {CFrame = cframe}):Play()
end

function VideoPlayer:zoomOut()
	if not ConfigReader:read("VideoZoomEnabled") then
		return
	end

	self.isZoomed = false

	TweenService:Create(Camera, TweenInfo.new(0.3), {CFrame = savedCameraPosition}):Play()

	task.wait(0.3)

	Camera.CameraType = Enum.CameraType.Custom
end

function VideoPlayer:setupAudioControls()
	local newVideoFrame = VideoFrame()
	newVideoFrame.Parent = self.adPart.AdSurfaceGui

	local audioIcon, onMouseLeave, onMouseMoved, onMouseClicked = newVideoFrame.AudioLabel, nil, nil, nil
	local enterConnection, leftConnection, clickConnection = nil, nil, nil
	local currentSizeTween, currentTransparencyTween = nil, nil
	local lastMouseState = "Leaving"

	local function tweenIconTransparency(num)
		if audioIcon.ImageTransparency == num then
			return
		end

		if currentTransparencyTween then
			currentTransparencyTween:Cancel()
		end

		currentTransparencyTween =
			TweenService:Create(audioIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { ImageTransparency = num })
		currentTransparencyTween:Play()
	end

	local function tweenIconSize(size)
		if audioIcon.Size == size then
			return
		end

		if currentSizeTween then
			currentSizeTween:Cancel()
		end

		local tween = TweenService:Create(audioIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Size = size })
		tween:Play()
	end

	onMouseClicked = function()
		lastMouseState = "Clicked"

		if self.isAudioOn then
			self:turnAudioOff()
			self:zoomOut()
		else
			self:turnAudioOn()
			self:zoomIn()
		end
	end

	onMouseMoved = function()
		local mouseAlreadyEntered = lastMouseState == "Moved"
		if mouseAlreadyEntered then
			return
		end

		lastMouseState = "Moved"

		UserInputService.MouseIcon = "rbxassetid://15936897912"

		tweenIconTransparency(0)

		if self.isAudioOn then
			tweenIconSize(UDim2.new(40 / 380, 0, 40 / 380, 0))
		else
			tweenIconSize(UDim2.new(50 / 380, 0, 50 / 380, 0))
		end
	end

	onMouseLeave = function()
		local playerMouse = LocalPlayer:GetMouse()
		local mouseOnBillboard = playerMouse.Target == self.adPart
		local mouseAlreadyLeft = lastMouseState == "Leaving"

		if mouseOnBillboard or mouseAlreadyLeft then
			return
		end

		lastMouseState = "Leaving"

		UserInputService.MouseIcon = ""

		tweenIconSize(UDim2.new(40 / 380, 0, 40 / 380, 0))

		if self.isAudioOn then
			tweenIconTransparency(1)
		else
			tweenIconTransparency(0)
		end
	end

	clickConnection = BillboardInputHelper.mouseClick.Event:Connect(function(adPartEntered)
		if adPartEntered == self.adPart then
			onMouseClicked()
		end
	end)

	newVideoFrame.AudioBtn.MouseEnter:Connect(onMouseMoved)
	newVideoFrame.AudioBtn.MouseMoved:Connect(onMouseMoved)
	newVideoFrame.AudioBtn.MouseLeave:Connect(onMouseLeave)

	enterConnection = BillboardInputHelper.mouseEntered.Event:Connect(function(adPartEntered)
		if adPartEntered == self.adPart then
			onMouseMoved()
		end
	end)

	leftConnection = BillboardInputHelper.mouseLeft.Event:Connect(function(adPartEntered)
		if adPartEntered == self.adPart then
			onMouseLeave()
		end
	end)

	table.insert(self.inputConnections, clickConnection)
	table.insert(self.inputConnections, enterConnection)
	table.insert(self.inputConnections, leftConnection)

	self.videoFrame = newVideoFrame
end

function VideoPlayer:setupViewabilityCriteria()
	local lastViewabilityMet = false

	self.viewabilityConnection = self.billboardClient.viewabilityMetEvent.Event:Connect(function(isOnScreen, percent, angle)
		local viewabilityMet = isOnScreen and percent >= 1.5 and angle <= 55

		if viewabilityMet == lastViewabilityMet then
			return
		else
			lastViewabilityMet = viewabilityMet
		end

		if viewabilityMet then
			self:resumePlayer()
		else
			self:pausePlayer()
		end
	end)
end

function VideoPlayer:init(billboardClient, imgURLs, framerate, adPart, gifVersion, audioUrl, bloxbizAdId, billType)
	local newVideo = setmetatable({}, { __index = VideoPlayer })

	newVideo.GIF = nil
	newVideo.isLoading = true
	newVideo.cleanupAfterLoading = false
	newVideo.billboardClient = billboardClient
	newVideo.adPart = adPart
	newVideo.bloxbizAdId = bloxbizAdId
	newVideo.billType = billType or "video_plays_cpm"
	newVideo.videoFrame = nil
	newVideo.audioToggleDataLoaded = false
	newVideo.isAudioOn = false
	newVideo.viewabilityConnection = nil
	newVideo.inputConnections = {}

	newVideo.analyticsData = {}
	newVideo.analyticsData.analyticsSent = false
	newVideo.analyticsData.numResumes = -1
	newVideo.analyticsData.maxContinuousPlaytime = 0
	newVideo.analyticsData.frameNumOnLastResume = nil

	task.spawn(function()
		newVideo.GIF = GIF:init(imgURLs, framerate, adPart, gifVersion, audioUrl, VOLUME_OFF_NUM)
		newVideo.isLoading = false

		if newVideo.GIF.loadingFailed then
			newVideo:cleanup()
			newVideo.billboardClient:requestAdRotation()
			return
		end

		if newVideo.cleanupAfterLoading then
			newVideo:cleanup()
		else
			newVideo:pausePlayer(0)

			newVideo:setupAudioControls()
			newVideo:setupViewabilityCriteria()
			newVideo:turnAudioOff()
			BillboardInputHelper:addBillboard(newVideo.adPart)

			local turnedAudioOnInitially = newVideo:loadAudioIfSameVideoAd()
			if turnedAudioOnInitially then
				newVideo.GIF.runData.audioActiveSumFrames = 1
			end

			newVideo.GIF.finishedCallback = function()
				newVideo:pausePlayer()
				newVideo:sendAnalytics()
				newVideo:cleanup()
				newVideo.billboardClient:requestAdRotation()
			end
		end
	end)

	return newVideo
end

return VideoPlayer
