local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CommonTypes = require(ReplicatedStorage.Styngr.Types)
local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)
local TrackEvent = require(ReplicatedStorage.Styngr.TrackEvent)
local TrackType = require(ReplicatedStorage.Styngr.TrackType)

local Common = require(script.Parent.Utils.Common)
local Counter = require(script.Parent.StateValues.Counter)
local Notification = require(script.Parent.StateValues.Notification)
local NowPlaying = require(script.Parent.StateValues.NowPlaying)
local PlaylistsOpen = require(script.Parent.StateValues.PlaylistsOpen)
local Skippable = require(script.Parent.StateValues.Skippable)

local AudioPlaybackEvent = script.Parent.AudioPlaybackEvent
local SongEvents = ReplicatedStorage.Styngr.SongEvents

local NOTIFICATION_DURATION_SECONDS = 5
local UNAVAILABLE_AD_TIMEOUT_OFFSET = 0.1 -- If there is no ad to be played, it's end is uncertain. Add a buffer to compensate.

local AudioService = {}

function AudioService:IsPaused()
	return not self._audio or self._audio.IsPaused
end

function AudioService:PlayPause()
	if not self._audio then
		return
	end

	if self._audio.IsPlaying then
		self._audio:Pause()
	else
		self._audio:Resume()
	end

	return self._audio.IsPlaying
end

function AudioService:Stop(): nil
	if not self._audio then
		return
	end

	self._audio:Stop()
	NowPlaying:set(nil)
end

function AudioService:CanSkip()
	if not self._hasSkips then
		return false
	end

	if not self._audio or self._isSkippable then
		return true
	end

	if self._audio.TimePosition < 30 then
		return false
	end

	return true
end

function AudioService:_playAudio(paused): nil
	local function formatSkipMessage(skipsLeft: number)
		local message = string.format("You have %d skips remaining", skipsLeft)
		if skipsLeft == 1 then
			message = "You have 1 skip remaining"
		elseif skipsLeft == 0 then
			message = "No skips currently available"
		end

		return message
	end

	if self._audio.IsPlaying then
		return
	end

	self._timer = 0
	self._unavailableTrack = false

	self._audio:Play()
	if paused then
		self._audio:Pause()
	end

	local track = self.lastTrack
	if track.remainingNumberOfSkips then
		Notification:notify(formatSkipMessage(track.remainingNumberOfSkips), NOTIFICATION_DURATION_SECONDS)
	end

	NowPlaying:set({
		playlistId = track.playlistId,
		artists = if track.artistNames then table.concat(track.artistNames, ", ") else "",
		title = track.title,
		type = track.type,
	})

	Skippable:set(false)
end

function AudioService:PlaySound(track: CommonTypes.ClientTrack, paused: boolean)
	self._isSkippable = track.isSkippable
	self._unavailableTrack = false
	self._timer = 0
	self._type = track.type

	if track.encryptionKey and track.encryptionKey ~= "" then
		ContentProvider:RegisterSessionEncryptedAsset(track.assetId, track.encryptionKey)
	end

	if not self._audio then
		self:_setup(track)
	end

	if self._audio.IsPlaying then
		self:Stop()
	end

	if not track.assetId or track.assetId == "" then
		self:_unavailableAd(track)
		return
	end

	self._audio.SoundId = track.assetId

	if track.encryptionKey == "" then
		ContentProvider:PreloadAsync({ self._audio })
	end

	-- necessary as last value of `track` is not passed correctly in some cases (it can have previous value if called as `playAudio(track)`)
	self.lastTrack = track
	self._hasSkips = if track.remainingNumberOfSkips then track.remainingNumberOfSkips > 0 else true

	if self._audio.IsLoaded then
		self:_playAudio(paused)
	else
		self:LoadAudioAssetAsync(paused)
	end
end

local function handleEvents(paused, trackEvent)
	AudioPlaybackEvent:Fire(paused)
	SongEvents:FireServer(trackEvent)
end

function AudioService:_setPausedListener()
	self._audio.Paused:Connect(function()
		handleEvents(false, TrackEvent.PAUSED)
	end)
end

function AudioService:_setResumedListener()
	self._audio.Resumed:Connect(function()
		handleEvents(true, TrackEvent.RESUMED)
	end)
end

function AudioService:_setPlayedListener()
	self._audio.Played:Connect(function()
		handleEvents(true, TrackEvent.PLAYED)
	end)
end

function AudioService:_setEndedListener()
	self._audio.Ended:Connect(function()
		handleEvents(false, TrackEvent.ENDED)

		local nextTrack: CommonTypes.ClientTrack = ReplicatedStorage.Styngr.RequestNextTrack:InvokeServer()

		if nextTrack then
			self._audio.TimePosition = 0
			self:PlaySound(nextTrack)
			return
		end

		if not PlaylistsOpen:get() then
			PlaylistsOpen:set(true)
		end

		NowPlaying:set(nil)
	end)
end

function AudioService:_setRenderer()
	RunService.RenderStepped:Connect(function(step)
		if not self._audio then
			return
		end

		local timePosition: number = 0
		if self._unavailableTrack then
			self._timer = self._timer + step
			timePosition = math.floor(self._timer)
		else
			timePosition = math.floor(self._audio.TimePosition) or 0
		end

		if self._type == TrackType.AD then
			Counter:set(math.floor(self._audio.TimeLength) - timePosition)
		else
			if not self._isSkippable and timePosition < Common.Enums.COUNTER_END_TIME then
				Counter:set(Common.Enums.COUNTER_END_TIME - timePosition)
			elseif not Skippable:get() then
				Skippable:set(true)
			end
		end
	end)
end

function AudioService:_setup(track)
	self._audio = Instance.new("Sound")
	self._audio.Looped = false
	self._audio.Parent = workspace
	self._audio.TimePosition = track.timePosition or 0

	self:_setPausedListener()
	self:_setResumedListener()
	self:_setPlayedListener()
	self:_setEndedListener()
	self:_setRenderer()
end

function AudioService:LoadAudioAssetAsync(paused)
	Promise.new(function(resolve)
		ContentProvider:PreloadAsync({ self._audio }, function(assetId, assetFetchStatus)
			resolve(assetFetchStatus == Enum.AssetFetchStatus.Success)
		end)
	end)
		:andThen(function(success)
			if success then
				self:_playAudio(paused)
				return
			end
			self:_unavailable(self.lastTrack, "Asset can't be loaded")
		end)
		:catch(function(error)
			warn(error)
			self:_unavailable(self.lastTrack, error)
		end)
end

local function _playReplacementTrack(error)
	local replacementTrack = ReplicatedStorage.Styngr.UnavailableTrack:InvokeServer(error)
	AudioService:PlaySound(replacementTrack)
end

function AudioService:_unavailable(track, error)
	if track.type == TrackType.MUSICAL then
		self._unavailableTrack = true
		_playReplacementTrack(error)
		return
	end

	self:_unavailableAd(track, error)
end

function AudioService:_unavailableAd(track, error)
	self._unavailableTrack = true
	NowPlaying:set({
		playlistId = track.playlistId,
		artists = "",
		title = "There's an issue with playback. Retrying...",
		type = track.type,
	})
	Skippable:set(false)
	AudioPlaybackEvent:Fire(true)
	SongEvents:FireServer(TrackEvent.PLAYED)
	Promise.delay(Common.Enums.COUNTER_END_TIME + UNAVAILABLE_AD_TIMEOUT_OFFSET):andThen(function(_)
		SongEvents:FireServer(TrackEvent.ENDED)
		_playReplacementTrack(error)
	end)
end

return AudioService
