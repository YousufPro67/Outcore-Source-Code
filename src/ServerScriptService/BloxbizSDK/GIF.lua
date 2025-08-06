local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local NUM_FRAMES_PRELOADED_DEFAULT = 8
local MAX_COLUMNS, MAX_ROWS = 2, 4

local GIF = {}
GIF.FRAME_SIZE_X = 512
GIF.FRAME_SIZE_Y = 256

function GIF:allAssetsLoadedSuccessfuly()
	local allLoaded = true

	for _, v in pairs(self.assetLoadedDict) do
		if v == false then
			allLoaded = false
			break
		end
	end

	return allLoaded
end

function GIF:onAssetLoaded(asset, status)
	if status ~= Enum.AssetFetchStatus.Success then
		--print("Failed to load " .. asset)
		if self.loadFailCount[asset] and self.loadFailCount[asset] > 3 then
			self.loadingFailed = true
		else
			self.loadFailCount[asset] = (self.loadFailCount[asset] or 0) + 1

			task.wait(0.5)

			ContentProvider:PreloadAsync({ asset }, function(_, newStatus)
				self:onAssetLoaded(asset, newStatus)
			end)
		end
	else
		self.assetLoadedDict[asset] = true

		local allLoaded = self:allAssetsLoadedSuccessfuly()

		if allLoaded and self.running == false then
			if self and not self.cleanedUp then
				self.running = true
				self:run()
			end
		end
	end
end

function GIF:cleanup()
	self.cleanedUp = true
	if self.renderFunc then
		self.renderFunc:Disconnect()
	end

	self.mainLabel.ImageRectOffset = Vector2.new()
	self.mainLabel.ImageRectSize = Vector2.new()

	for i = 1, #self.imageLabel do
		self.imageLabel[i]:Destroy()
	end

	if self.sound then
		self.sound:Destroy()
	end

	self = nil
end

function GIF:setRunDataFromTimePosition(timePosition)
	local maxTime = self.frameCount * (1 / self.framerate)
	timePosition = math.max(timePosition, 0.01)

	local frameToGoTo = math.floor(timePosition / maxTime * self.frameCount)
	frameToGoTo = math.max(frameToGoTo, 1) --avoid rounding down to 0

	if frameToGoTo > self.frameCount then
		frameToGoTo = 1
	end

	while self.runData.currentFrame ~= frameToGoTo do
		self:nextFrame()
	end
end

function GIF:setVolume(volumeToSet)
	self.sound.Volume = volumeToSet
end

function GIF:pause(timePosition)
	local currentPosition = self.runData.currentFrame / self.framerate
	timePosition = timePosition or currentPosition

	self.paused = true
	self:setRunDataFromTimePosition(timePosition)

	if self.sound then
		self.sound.Playing = false
		self.sound.TimePosition = timePosition
	end
end

function GIF:resume(timePosition)
	local currentPosition = self.runData.currentFrame / self.framerate
	timePosition = timePosition or currentPosition

	self.paused = false
	self:setRunDataFromTimePosition(timePosition)

	if self.sound then
		self.sound.Playing = true
		self.sound.TimePosition = timePosition
	end
end

function GIF:getFrameInfo(frame)
	local imgIndex, column, row

	if self.version == 1 then
		imgIndex = frame
		column = 0
		row = 0
	else
		imgIndex = math.ceil(frame / self.framesPerSheet)
		column = frame % MAX_COLUMNS == 0 and 1 or 0
		row = math.floor((frame - 1) / 2) % MAX_ROWS
	end

	return imgIndex, column, row
end

function GIF:updateImgLabel(imgLabel, imgIndex, frame)
	imgLabel.Image = self.imgUrls[imgIndex]

	if self.version ~= 1 then
		local _, column, row = self:getFrameInfo(frame)

		local upperLeftPos = Vector2.new(column * self.FRAME_SIZE_X, row * self.FRAME_SIZE_Y)
		local frameSize = Vector2.new(self.FRAME_SIZE_X, self.FRAME_SIZE_Y)

		imgLabel.ImageRectOffset = upperLeftPos
		imgLabel.ImageRectSize = frameSize

		self.mainLabel.ImageRectOffset = upperLeftPos
		self.mainLabel.ImageRectSize = frameSize
	end
end

function GIF:nextFrame()
	local prevImgLabelIndex = self.runData.currentImgLabelIndex - 1

	if prevImgLabelIndex == 0 then
		prevImgLabelIndex = self.runData.numFramesPreloaded
	end

	local currentImgLabel = self.imageLabel[self.runData.currentImgLabelIndex]
	local prevImgLabel = self.imageLabel[prevImgLabelIndex]

	currentImgLabel.ZIndex = 9
	prevImgLabel.ZIndex = 0

	local prevFrame = self.runData.currentFrame + self.runData.numFramesPreloaded - 1

	if prevFrame > self.frameCount then
		prevFrame -= self.frameCount
	end

	local prevImgIndex = self:getFrameInfo(prevFrame)

	--print(prevImgLabel, prevImgIndex, prevFrame)
	self:updateImgLabel(prevImgLabel, prevImgIndex, prevFrame)
	--print(currentImgLabelIndex, currentImgLabel.Image, prevImgLabelIndex, prevImgLabel.Image)

	--Have filler image when GIF is arbitrarily removed
	self.mainLabel.Image = currentImgLabel.Image

	self.runData.currentFrame += 1
	self.runData.currentImgLabelIndex += 1

	local goNextSheet = (self.runData.currentFrame % self.framesPerSheet) == 1 or (self.framesPerSheet == 1)
	if goNextSheet then
		self.runData.currentImgIndex += 1
	end

	local resetGIF = self.runData.currentFrame > self.frameCount
	if resetGIF then
		self.runData.currentFrame = 1
		self.runData.currentImgIndex = 1

		if self.sound then
			self.sound.Playing = true
			self.sound.TimePosition = 0
		end
	end

	if self.runData.currentImgLabelIndex > self.runData.numFramesPreloaded then
		self.runData.currentImgLabelIndex = 1
	end
end

function GIF:run()
	local timeDif = 0
	local secondsPerFrame = 1 / self.framerate

	if self.sound then
		self.sound.Playing = true
		self.sound.TimePosition = 0
	end

	self.renderFunc = RunService.Heartbeat:Connect(function(step)
		timeDif = timeDif + step

		if timeDif > secondsPerFrame then
			timeDif = timeDif - secondsPerFrame

			if self.paused then
				return
			end

			self:nextFrame()

			if self.sound and self.sound.Playing and self.sound.Volume > 0 then
				self.runData.audioActiveSumFrames += 1
			end
		end

		if self.runData.currentFrame == self.frameCount and self.finishedCallback then
			self.finishedCallback()
		end
	end)
end

function GIF:loadInitialFrame()
	for i = 1, self.runData.numFramesPreloaded do
		local imgClone = self.mainLabel:Clone()
		imgClone.Name = "GIFRenderImage-" .. tostring(i)
		imgClone.ZIndex = 0
		imgClone.Parent = self.mainLabel.Parent

		if self.version == 1 then
			imgClone.Image = self.imgUrls[i]
			imgClone.ImageRectOffset = Vector2.new()
			imgClone.ImageRectSize = Vector2.new()
		else
			self:updateImgLabel(imgClone, 1, i)
		end

		table.insert(self.imageLabel, imgClone)
	end

	self.mainLabel.Image = self.imgUrls[1]
	self.mainLabel.ImageRectOffset = Vector2.new()
end

function GIF:loadAssets()
	if self.version ~= 1 then
		local framesInLastSheet = self.imgUrls[#self.imgUrls].frames_per_sheet
		self.framesPerSheet = self.imgUrls[1].frames_per_sheet
		self.frameCount = (#self.imgUrls - 1) * self.framesPerSheet + framesInLastSheet

		local newImgURLs = {}

		for _, sheet in ipairs(self.imgUrls) do
			table.insert(newImgURLs, sheet.ad_url)
		end

		self.imgUrls = newImgURLs
	end

	for i = 1, #self.imgUrls do
		self.assetLoadedDict[self.imgUrls[i]] = false
	end

	self:loadInitialFrame()

	if self.sound then
		self.assetLoadedDict[self.sound.SoundId] = false

		ContentProvider:PreloadAsync({ self.sound }, function(asset, status)
			self:onAssetLoaded(asset, status)
		end)
	end

	ContentProvider:PreloadAsync(self.imgUrls, function(imageURL, status)
		self:onAssetLoaded(imageURL, status)
	end)
end

function GIF:init(imgURLs, framerate, obj, gifVersion, audioURL, initialVolume)
	local newGIF = setmetatable({}, { __index = GIF })

	newGIF.imgUrls = imgURLs
	newGIF.sound = nil
	newGIF.framerate = framerate
	newGIF.mainLabel = obj.AdSurfaceGui.ImageLabel
	newGIF.version = gifVersion
	newGIF.framesPerSheet = 1
	newGIF.frameCount = #imgURLs

	newGIF.assetLoadedDict = {}
	newGIF.imageLabel = {}
	newGIF.numLoaded = 0
	newGIF.loadingFailed = false
	newGIF.running = false
	newGIF.paused = false
	newGIF.renderFunc = nil
	newGIF.loadFailCount = {}
	newGIF.cleanedUp = false

	newGIF.runData = {}
	newGIF.runData.numFramesPreloaded = math.min(NUM_FRAMES_PRELOADED_DEFAULT, newGIF.imgUrls[1].frames_per_sheet)
	newGIF.runData.currentFrame = 1
	newGIF.runData.currentImgIndex = 1
	newGIF.runData.currentImgLabelIndex = 1
	newGIF.runData.audioActiveSumFrames = 0

	newGIF.finishedCallback = nil

	if audioURL then
		local soundObj = Instance.new("Sound")
		soundObj.Name = audioURL
		soundObj.SoundId = audioURL
		soundObj.Volume = initialVolume or 1
		soundObj.Parent = obj

		newGIF.sound = soundObj
	end

	task.spawn(function()
		newGIF:loadAssets()
	end)

	local loadingFinished = newGIF.loadingFailed == true or newGIF.running == true
	while not loadingFinished do
		RunService.Heartbeat:Wait()

		loadingFinished = newGIF.loadingFailed == true or newGIF.running == true

		if loadingFinished then
			break
		end
	end

	return newGIF
end

return GIF
