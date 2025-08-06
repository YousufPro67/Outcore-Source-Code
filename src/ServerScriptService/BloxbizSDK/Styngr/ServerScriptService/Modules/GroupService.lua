local Players = game:GetService("Players")
local ZoneService = require(script.Parent.ZoneService.ZoneService)

type JoinedCallback = (Player, Player) -> nil
type LeftCallback = (Player) -> nil
type SyncAudioEventForSessionCallback = (Player, string) -> nil
type SyncTrackForSessionCallback = (Player, Player) -> nil

export type IGroupService = {
	StartSession: (player: Player, playlistId: string) -> any,
}

local GroupService: IGroupService = {}
GroupService.__index = GroupService

function GroupService.New(
	joined: JoinedCallback | nil,
	left: LeftCallback | nil,
	syncAudioEventForSession: SyncAudioEventForSessionCallback | nil,
	syncTrackForSession: SyncTrackForSessionCallback | nil
)
	local self = {
		_joined = joined,
		_left = left,
		_syncAudioEventForSession = syncAudioEventForSession,
		_syncTrackForSession = syncTrackForSession,
		_playerInSession = {},
	}

	setmetatable(self, GroupService)

	self._zone = ZoneService.New(function(owner: Player, player: Player)
		self:_onEntered(owner, player)
	end, function(owner: Player, player: Player)
		self:_onExited(owner, player)
	end)

	return self
end

--[=[
	Start group playlist session listening
	Must leave existing group playlist session to start a new one

	@param player Player -- The player for whom the request is sent
	@param playlistId number -- The id of the playlist thatt will be played to the user

	@return Promise<{Response}>
]=]
function GroupService:StartSession(player: Player)
	if self._playerInSession[player.UserId] and self._left then
		self._left(player)
	end

	self._playerInSession[player.UserId] = player.UserId
	self._zone:add(player)
end

--[=[
	Check if current player is running the group playlist session as owner

	@param player Player -- The player to check the group session ownership
	@return bool -- true if the player runs session, false otherwise
]=]
function GroupService:IsOwnerInSession(player: Player)
	return self._playerInSession[player.UserId] == player.UserId
end

--[=[
	Send new track data to the players in session of the owner

	@param owner Player -- The owner of the session
	@param syncTrackForSession SyncTrackForSessionCallback | string -- callback for syning the track
]=]
function GroupService:SendNewTrackDataToSession(owner: Player)
	if self._syncTrackForSession == nil then
		return
	end

	for playerId, _ in self._playerInSession do
		if playerId == owner.UserId then
			continue
		end

		if self._playerInSession[playerId] == owner.UserId then
			local player = Players:GetPlayerByUserId(playerId)
			self._syncTrackForSession(player, owner)
		end
	end
end

--[=[
	Send new event to the players in session if owner plays/pauses the song

	@param owner Player -- The owner of the session
	@param event string -- The event to be executed on player side
]=]
function GroupService:FireAudioEventForPlayersInSession(owner: Player, event: string)
	if self._syncAudioEventForSession == nil then
		return
	end

	for playerId, _ in self._playerInSession do
		if playerId == owner.UserId then
			continue
		end

		local player = Players:GetPlayerByUserId(playerId)
		self._syncAudioEventForSession(player, event)
	end
end

function GroupService:_onEntered(owner: Player, player: Player): nil
	if self._playerInSession[player.UserId] ~= nil then
		return
	end

	self._playerInSession[player.UserId] = owner.UserId

	if self._joined then
		self._joined(player, owner)
	end
end

function GroupService:_onExited(owner: Player, player: Player)
	if not self._playerInSession[player.UserId] or self._playerInSession[player.UserId] ~= owner.UserId then
		return
	end

	self._playerInSession[player.UserId] = nil
	if self._left then
		self._left(player)
	end

	self._zone:reJoin(player)
end

return GroupService
