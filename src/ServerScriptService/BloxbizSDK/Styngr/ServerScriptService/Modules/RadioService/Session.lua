local ErrorService = require(script.Parent.Parent.ErrorService)
local Tracking = require(script.Parent.Tracking)

export type ISession = {
	playlistId: string,
	tracking: Tracking.ITracking,

	Start: () -> any,
	Stop: () -> any,
	Next: () -> any,
	Skip: () -> any,
	Unavailable: () -> any,

	Load: (data: table) -> table,
	Save: () -> table,
}

local Session = {}

function Session.Load(instance: ISession, data: table): nil
	instance._previousSession = data.previousSession

	instance:_startTrack()
	instance.tracking:Load(data.tracking)

	instance._session = data.session
	instance.playlistId = data.playlistId

	instance._session.track.timePosition = data.tracking.forceEnded - data.tracking.started - data.tracking.totalPaused
	instance._session.track.playing = instance.tracking.playing
end

function Session.Save(instance: ISession): table
	return {
		session = instance._session,
		tracking = instance.tracking:Save(),
		playlistId = instance.playlistId,
		previousPlaylistId = instance._previousPlaylistId,
	}
end

function Session._destroyTracking(instance)
	if instance.tracking then
		instance.tracking:Destroy()
		instance.tracking = nil
	end
end

function Session:_isValidTrack(track): boolean
	if
		not track
		or typeof(track["customMetadata"]) ~= "table"
		or typeof(track["title"]) ~= "string"
		or typeof(track["playlistId"]) ~= "string"
	then
		ErrorService:Send("There is an issue with the track data", track)
		warn("Track not in correct format")
		return false
	end

	local customMetadata = track.customMetadata
	if typeof(customMetadata["key"]) ~= "string" or typeof(customMetadata["id"]) ~= "string" then
		ErrorService:Send("Error in track metadata", track)
		warn(
			"Metadata not in correct format",
			if typeof(track.artistNames) == "table" then table.concat(track.artistNames, ", ") else "",
			track.title
		)
		return false
	end

	return true
end

return Session
