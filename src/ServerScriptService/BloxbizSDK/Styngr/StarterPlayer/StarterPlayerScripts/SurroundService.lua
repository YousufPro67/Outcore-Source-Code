local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)
local TrackEvent = require(ReplicatedStorage.Styngr.TrackEvent)

local SurroundService = {}

function SurroundService:_play(player: Player, track)
	if not self._audio then
		self._audio = Instance.new("Sound")
		self._audio.Name = "SurroundSound"
		self._audio.Looped = false
	end

	self._audio.Parent = player.Character.HumanoidRootPart

	if not track then
		return
	end

	ContentProvider:RegisterSessionEncryptedAsset(track.assetId, track.encryptionKey)

	self._audio.SoundId = track.assetId

	if self._audio.IsLoaded then
		self._audio.TimePosition = track.sync
		self._audio:Play()
	else
		Promise.fromEvent(self._audio.Loaded)
			:andThen(function()
				self._audio.TimePosition = track.sync
				self._audio:Play()
			end)
			:await()
	end
end

function SurroundService:_remove(): nil
	self._audio:Stop()
	self._audio:Destroy()
	self._audio = nil
end

function SurroundService:init()
	ReplicatedStorage.Styngr.ListenToGroupSessionEvent.OnClientEvent:Connect(function(owner, track)
		self:_play(owner, track)
	end)

	ReplicatedStorage.Styngr.RemoveGroupSessionEvent.OnClientEvent:Connect(function()
		self:_remove()
	end)

	ReplicatedStorage.Styngr.GroupSessionSongEvent.OnClientEvent:Connect(function(event: string)
		if event == TrackEvent.RESUMED then
			self:Play()
		elseif event == TrackEvent.PAUSED then
			self:Pause()
		else
			warn("Event", event, "not supported")
		end
	end)

	ReplicatedStorage.Styngr.GroupSessionSetNewSongEvent.OnClientEvent:Connect(function(owner, track)
		self:_play(owner, track)
	end)
end

function SurroundService:Play(): nil
	if not self._audio or self._audio.IsPlaying then
		return
	end

	self._audio:Resume()
end

function SurroundService:Pause(): nil
	if not self._audio or not self._audio.IsPlaying then
		return
	end

	self._audio:Pause()
end

return SurroundService
