local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaylistType = require(ReplicatedStorage.Styngr.PlaylistType)
local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)

local CloudService = require(script.Parent.Parent.CloudService)
local Endpoints = require(script.Parent.Parent.Endpoints)
local ErrorService = require(script.Parent.Parent.ErrorService)
local Session = require(script.Parent.Session)
local Tracking = require(script.Parent.Tracking)

local TRACK_STATUS = {
	COMPLETE = "TRACK_COMPLETE",
	STOPPED = "TRACK_STOPPED",
	SKIPPED = "TRACK_SKIPPED",
	UNAVAILABLE = "TRACK_UNAVAILABLE",
}

local function processTrackData(body: table, playlistId: string): table
	local clonedBody = table.clone(body)
	clonedBody.artistNames = { clonedBody.artistName }
	clonedBody.title = clonedBody.trackName
	clonedBody.playlistId = playlistId
	clonedBody.isSkippable = true

	return {
		track = clonedBody,
	}
end

local RoyaltyFree: Session.ISession = {
	tracking = nil,
	type = PlaylistType.ROYALTY_FREE,
}

RoyaltyFree.__index = RoyaltyFree

function RoyaltyFree.New(cloudService: CloudService.ICloudService, player: Player, playlistId: string, _: any)
	local self = {
		_cloudService = cloudService,
		_player = player,
		playlistId = playlistId,
		_session = nil,
		_tracking = nil,
		_usageReportId = nil,
	}

	setmetatable(self, RoyaltyFree)

	return self
end

function RoyaltyFree:Start()
	return self._cloudService
		:Call(self._player, Endpoints.RoyaltyFree.Start, nil, { playlistId = self.playlistId })
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				local body = HttpService:JSONDecode(result.Body)
				self._session = processTrackData(body, self.playlistId)
				self._session.track.playlistId = self.playlistId
				self._session.track.isSkippable = true
				self:_startTrack()

				self:_checkTrack(resolve, reject)
			end)
		end)
		:catch(function(error)
			warn(error)
		end)
end

function RoyaltyFree:Stop()
	self.tracking:Ended()

	return self._cloudService
		:Call(self._player, Endpoints.RoyaltyFree.Stop, {
			statistics = self:_getStatistics(TRACK_STATUS.STOPPED),
		}, { playlistId = self.playlistId })
		:andThen(function(_)
			Session._destroyTracking(self)
			return Promise.resolve()
		end)
		:catch(function(error)
			warn(error)
		end)
end

function RoyaltyFree:Next()
	return self:_getNextTrack(TRACK_STATUS.COMPLETE)
end

function RoyaltyFree:Skip()
	return self:_getNextTrack(TRACK_STATUS.SKIPPED)
end

function RoyaltyFree:Unavailable(error)
	error = error or "There was an issue with loading the track"
	ErrorService:Send(error, self._session.track)
	return self:_getNextTrack(TRACK_STATUS.UNAVAILABLE)
end

function RoyaltyFree:Load(data: table): table
	Session.Load(self, data)

	return self._session
end

function RoyaltyFree:Save(): table
	return Session.Save(self)
end

function RoyaltyFree:_destroyTracking()
	if self.tracking then
		self.tracking:Destroy()
		self.tracking = nil
	end
end

function RoyaltyFree:_startTrack()
	self.tracking = Tracking.New()
end

function RoyaltyFree:_getNextTrack(trackStatus: string)
	return self._cloudService
		:Call(self._player, Endpoints.RoyaltyFree.Next, {
			statistics = self:_getStatistics(trackStatus),
		}, { playlistId = self.playlistId })
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				Session._destroyTracking(self)

				local body = HttpService:JSONDecode(result.Body)
				self._session = processTrackData(body, self.playlistId)

				self:_startTrack()

				self:_checkTrack(resolve, reject)
			end)
		end)
		:catch(function(error)
			warn(error)
		end)
end

function RoyaltyFree:_getStatistics(trackStatus: string)
	assert(self._session.track.usageReportId, "usageReportId does not exist for player")

	local statistics = self.tracking
	local started: number = statistics.started or os.time()
	local endTime: number = statistics.ended or os.time()
	local playtime: number = endTime - started - statistics.totalPaused

	if playtime < 0 then
		ErrorService:Send(
			"Playtime negative",
			{ started = started, ended = endTime, paused = statistics.totalPaused, playtime = playtime }
		)
		playtime = 0
	end

	return {
		playtimeInSeconds = playtime,
		trackStatus = trackStatus,
		usageReportId = self._session.track.usageReportId,
	}
end

function RoyaltyFree:_checkTrack(resolve, reject)
	if Session:_isValidTrack(self._session.track) then
		resolve(self._session)
		return
	end

	local ok, newSession = self:_getNextTrack(TRACK_STATUS.UNAVAILABLE):await()
	if ok then
		resolve(newSession)
		return
	end

	-- There are no more tracks in the playlist. Reject, so the caller can start a new session.
	self.tracking:Played()
	reject(newSession)
end

return RoyaltyFree
