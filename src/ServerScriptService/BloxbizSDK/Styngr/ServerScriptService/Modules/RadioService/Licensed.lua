local HttpService = game:GetService("HttpService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DateTimeOffset = require(ReplicatedStorage.Styngr.Utils.DateTimeOffset)
local ISODurations = require(ReplicatedStorage.Styngr.Utils.ISODurations)
local PlaylistType = require(ReplicatedStorage.Styngr.PlaylistType)
local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)
local TrackType = require(ReplicatedStorage.Styngr.TrackType)

local AppState = require(script.Parent.Parent.Parent.Utils.AppState)
local CloudService = require(script.Parent.Parent.CloudService)
local Endpoints = require(script.Parent.Parent.Endpoints)
local ErrorService = require(script.Parent.Parent.ErrorService)
local Session = require(script.Parent.Session)
local Tracking = require(script.Parent.Tracking)
local Version = require(script.Parent.Parent.Version)

local AudioAdServer = {}
local blockbiz = game.ServerScriptService:FindFirstChild("BloxbizSDK")
if blockbiz then
	local blockbizAdServer = blockbiz:FindFirstChild("AudioAdServer")
	if blockbizAdServer then
		AudioAdServer = require(blockbizAdServer)
	end
end

local END_STREAM_REASON = {
	COMPLETED = "completed",
	SKIP = "skip",
	END_SESSION = "endSession",
	UNAVAILABLE = "Unavailable",
}

local AD_MESSAGE = "This is an Advertisement."

local Licensed: Session.ISession = {
	type = PlaylistType.LICENSED,
}

Licensed.__index = Licensed

function Licensed.New(
	cloudService: CloudService.ICloudService,
	player: Player,
	playlistId: string,
	previousPlaylistId: string
)
	local self = {
		_cloudService = cloudService,
		_player = player,
		playlistId = playlistId,
		tracking = nil,
		_session = nil,
		_previousPlaylistId = previousPlaylistId,
		_previousTrackId = nil,
	}

	setmetatable(self, Licensed)

	return self
end

function Licensed:Start()
	return self._cloudService
		:Call(self._player, Endpoints.Licensed.Start, nil, { playlistId = self.playlistId })
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				Session._destroyTracking(self)

				self._session = HttpService:JSONDecode(result.Body)
				self._session.playlistId = self.playlistId
				self._session.track.artistNames = self._session.track.artistNames or {}
				self._session.track.playlistId = self.playlistId

				self:_setAd()

				self:_startTrack()
				self:_checkTrack(resolve, reject)
			end)
		end)
end

function Licensed:Next()
	return self:_getNextTrack(END_STREAM_REASON.COMPLETED)
end

function Licensed:Skip()
	return self:_getNextTrack(END_STREAM_REASON.SKIP)
end

function Licensed:Unavailable(error)
	error = error or "There was an issue loading the track"
	ErrorService:Send(error, self._session.track)
	return self:_getNextTrack(END_STREAM_REASON.UNAVAILABLE)
end

function Licensed:Stop()
	if not self._session or self._session.track.trackType ~= TrackType.MUSICAL then
		return Promise.resolve(nil)
	end

	local function clear()
		self._previousPlaylistId = nil
		Session._destroyTracking(self)
	end

	self.tracking:Ended()
	if self._session.ad then
		return self._processAd():andThen(function()
			clear()
			return Promise.resolve()
		end)
	end

	return self._cloudService
		:Call(self._player, Endpoints.Licensed.PlaybackStatistics, {
			statistics = self:_getStatistics(END_STREAM_REASON.END_SESSION),
		})
		:andThen(function()
			clear()
			return Promise.resolve()
		end)
		:catch(function(error)
			warn(error)
		end)
end

function Licensed:_getNextTrack(reason)
	assert(self._session, "No session found!")

	if self._session and self._session.ad then
		return self:_processAd()
	end

	local endpoints = {
		[END_STREAM_REASON.SKIP] = Endpoints.Licensed.Skip,
		[END_STREAM_REASON.COMPLETED] = Endpoints.Licensed.Next,
		[END_STREAM_REASON.UNAVAILABLE] = Endpoints.Licensed.Skip,
	}

	if self._session.track.trackType == TrackType.COMMERCIAL then
		endpoints[END_STREAM_REASON.UNAVAILABLE] = Endpoints.Licensed.Next
	end

	return self._cloudService
		:Call(
			self._player,
			endpoints[reason],
			self:_getRequest(reason),
			{ playlistId = self._session.playlistId },
			{ ["X-App-Version"] = Version }
		)
		:andThen(function(result)
			return self:_processNextTrack(result, reason)
		end)
end

function Licensed:_getRequest(endStreamReason)
	return {
		sessionId = self._session.sessionId,
		format = "AAC",
		statistics = self:_getStatistics(endStreamReason),
	}
end

function Licensed:_getStatistics(endStreamReason: string)
	local statistics = self.tracking
	local started = statistics.started or os.time()
	local endTime = statistics.ended or os.time()

	local duration = endTime - started - statistics.totalPaused
	if duration < 0 then
		ErrorService:Send(
			"Duration negative",
			{ start = started, endTime = endTime, paused = statistics.totalPaused, duration = duration }
		)
		duration = 0
	end

	return {
		{
			trackId = self._session.track.trackId or "ad",
			playlistId = self._session.playlistId,
			start = DateTime.fromUnixTimestamp(started):ToIsoDate(),
			duration = ISODurations.TranslateSecondsToDuration(duration),
			useType = if self._session.track.trackType == TrackType.COMMERCIAL then "ad" else "streaming",
			autoplay = true,
			isMuted = false,
			endStreamReason = endStreamReason,
			clientTimestampOffset = DateTimeOffset.GetCurrentUtcOffset(),
			playlistSessionId = self._session.sessionId,
			previousTrackId = if self._session.track.trackType == TrackType.MUSICAL then self._previousTrackId else nil,
			previousPlaylistId = if self._session.track.trackType == TrackType.MUSICAL
				then self._previousPlaylistId
				else nil,
			appStateStart = statistics.appStateStart,
			appState = AppState:Get(self._player),
		},
	}
end

function Licensed:_processNextTrack(result, reason)
	return Promise.new(function(resolve, reject)
		Session._destroyTracking(self)

		if self._session.track.trackType == TrackType.MUSICAL and reason ~= END_STREAM_REASON.UNAVAILABLE then
			self._previousTrackId = self._session.track.trackId
		end

		local track = HttpService:JSONDecode(result.Body)

		track.playlistId = self.playlistId
		track.artistNames = track.artistNames or {}
		self._session.track = track

		self:_setAd()

		self:_startTrack()
		self:_checkTrack(resolve, reject)
	end)
end

function Licensed:_processAd()
	return Promise.new(function(resolve)
		local endTime = if self.tracking.ended then self.tracking.ended else os.time()
		local duration = endTime - self.tracking.started - self.tracking.totalPaused

		if AudioAdServer.triggerImpression then
			AudioAdServer:triggerImpression(self._player, duration)
		end

		self._session.ad = nil
		Session._destroyTracking(self)

		self:_startTrack()
		resolve(self._session)
	end)
end

function Licensed:_setAd()
	if not AudioAdServer.getAds then
		return
	end

	local ok, result = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, self._player)

	if not ok or not result or not result.AreAdsAllowed then
		return
	end

	local adAssetId = AudioAdServer:getAds(self._player)
	if adAssetId then
		self._session.ad = {
			assetId = adAssetId,
			title = AD_MESSAGE,
			type = TrackType.AD,
			isSkippable = false,
		}
	end
end

function Licensed:_startTrack()
	self.tracking = Tracking.New(AppState:GetStart(self._player))
end

function Licensed:Load(data: table): table
	Session.Load(self, data)

	return self._session
end

function Licensed:Save(): table
	return Session.Save(self)
end

function Licensed:_checkTrack(resolve, reject): nil
	if Session:_isValidTrack(self._session.track) then
		resolve(self._session)
		return
	end

	if self._session.track.trackType == TrackType.COMMERCIAL then
		-- Ads must wait before being able to request the next track. Send back track with bad metadata so the client can handle the waiting.
		self._session.track.customMetadata = '{"id":"", "key": ""}'
		self._session.track.playlistId = self.playlistId
		resolve(self._session)
		return
	end

	local ok, newSession = self:_getNextTrack(END_STREAM_REASON.UNAVAILABLE):await()
	if ok then
		resolve(newSession)
	else
		-- There are no more tracks in the playlist. Reject, so the caller can start a new session.
		self.tracking:Played()
		reject(newSession)
	end
end

return Licensed
