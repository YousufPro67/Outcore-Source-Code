local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrackEvent = require(ReplicatedStorage.Styngr.TrackEvent)

local Configuration = {}
local config = ReplicatedStorage.Styngr:FindFirstChild("Configuration")
if config then
	Configuration = require(config)
end

local SongEvents = ReplicatedStorage.Styngr.SongEvents

export type ITracking = {
	started: number | nil,
	ended: number | nil,
	forceEnded: number | nil,
	totalPaused: number | nil,
	playing: boolean,
	appStateStart: string,

	Played: () -> any,
	Ended: () -> any,
	Paused: () -> any,
	Resumed: () -> any,
	IsPaused: () -> boolean,
}

local Tracking: ITracking = {}

Tracking.__index = Tracking

function Tracking.New(appStateStart: string): ITracking
	local self = {
		started = nil,
		totalPaused = 0,
		appStateStart = appStateStart,
		ended = nil,
		forceEnded = nil,
		_paused = nil,
		playing = true,
	}

	setmetatable(self, Tracking)

	self._connection = SongEvents.OnServerEvent:Connect(function(_: Player, event: string): nil
		assert(
			event and (event == "PLAYED" or event == "ENDED" or event == "RESUMED" or event == "PAUSED"),
			"Invalid event"
		)

		if event == TrackEvent.PLAYED then
			self:Played()
		elseif event == TrackEvent.ENDED then
			self:Ended()
		elseif event == TrackEvent.PAUSED then
			self:Paused()
		elseif event == TrackEvent.RESUMED then
			self:Resumed()
		end
	end)

	return self
end

function Tracking:Destroy()
	self._connection:Disconnect()
end

function Tracking:Ended()
	assert(self.started, "Not started")

	local ended = os.time()

	assert(self.started <= ended, "Ended before it started")

	self.ended = ended
end

function Tracking:Paused()
	assert(not self._paused, "Already paused")

	self._paused = os.time()
end

function Tracking:Played()
	if self.started ~= nil then
		warn("Already started")
	else
		self.started = os.time()
	end
end

function Tracking:Resumed()
	local paused = os.time() - self._paused

	if paused < 0 then
		warn("Just paused")
	end

	self._paused = nil
	self.totalPaused += paused
end

function Tracking:Load(data: table): nil
	self.started = data.started
	self.appStateStart = data.appStateStart
	self.totalPaused = data.totalPaused + os.time() - data.forceEnded
	self.forceEnded = data.forceEnded
	self.playing = data.playing
end

function Tracking:Save(): table
	local paused = if self._paused then os.time() - self._paused else 0
	local userInteraction = Configuration.userInteraction == nil or Configuration.userInteraction

	return {
		started = self.started,
		totalPaused = self.totalPaused + paused,
		appStateStart = self.appStateStart,
		forceEnded = if userInteraction then os.time() else self.forceEnded,
		playing = self._paused == nil,
	}
end

function Tracking:IsPaused()
	return self._paused ~= nil
end

return Tracking
