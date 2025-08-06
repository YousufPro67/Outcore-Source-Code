--[=[
	@class RadioService

	Core service for all radio related server side SDK methods
]=]
local MemoryStoreService = game:GetService("MemoryStoreService")
local NetworkServer = game:GetService("NetworkServer")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonType = require(ReplicatedStorage.Styngr.Types)
local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)
local PlaylistType = require(ReplicatedStorage.Styngr.PlaylistType)
local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)
local TrackType = require(ReplicatedStorage.Styngr.TrackType)
local TrackEvent = require(ReplicatedStorage.Styngr.TrackEvent)

local BoomboxModel = require(script.Parent.BoomboxModel)
local CloudService = require(script.Parent.CloudService)
local GroupService = require(script.Parent.GroupService)
local Playlist = require(script.Parent.RadioService.Playlist)
local Types = require(script.Parent.Parent.Types)

local ErrorCodes = require(script.Parent.ErrorCodes)

local Configuration = {}
local config = ReplicatedStorage.Styngr:FindFirstChild("Configuration")
if config then
	Configuration = require(config)
end

local MemoryStore = MemoryStoreService:GetSortedMap("TrackMemoryStore")

local DEFAULT = {
	MEMORY_STORE_DURATION = 60, -- seconds
}

local TIMEOUT_BUFFER = 10 -- seconds
local ON_CLOSE_SESSIONS_SEND = 20 -- Rounds of checks to wait before closing all sessions that are not taken to another place
local PLAYER_LIST_MEMORY_STORE_NAME = "PlayerListMemoryStore"

local function buildClientFriendlyTrack(userId: number, track: CommonType.Track, sync: number): CommonType.ClientTrack
	assert(userId and typeof(userId) == "number", "User id must be provided")

	local customMetadata = track.customMetadata
	local encryptionKey = if customMetadata.key and customMetadata.key ~= ""
		then NetworkServer:EncryptStringForPlayerId(customMetadata.key, userId)
		else ""
	local trackType = if TrackType[track.trackType] then TrackType[track.trackType] else TrackType.MUSICAL

	local result: CommonType.ClientTrack = {
		title = track.title,
		artistNames = track.artistNames or {},
		isLiked = track.isLiked or false,
		assetId = customMetadata.id,
		encryptionKey = encryptionKey,
		playlistId = track.playlistId,
		timePosition = track.timePosition or 0,
		type = trackType,
		playing = track.playing == nil or track.playing,
		isSkippable = track.isSkippable,
		remainingNumberOfSkips = track.remainingNumberOfSkips,
		sync = sync or 0,
	}

	return result
end

local RadioService = {}

--[=[
	For setting up the SDK with your API credentials

	@param inputConfiguration { apiKey: string, appId: string, apiServer: string? } -- Contains your API credentials
]=]
function RadioService:SetConfiguration(
	cloudService: CloudService.ICloudService,
	inputConfiguration: Types.RadioServiceConfiguration
)
	assert(
		inputConfiguration
			and inputConfiguration.appId
			and typeof(inputConfiguration.appId) == "string"
			and inputConfiguration.boombox
			and typeof(inputConfiguration.boombox) == "table"
			and inputConfiguration.boombox.textureId
			and typeof(inputConfiguration.boombox.textureId) == "string",
		"Please specify a configuration and ensure all values are correct!"
	)

	if self._connections then
		for _, connection in self._connections do
			connection:Disconnect()
		end
	end

	self._cloudService = cloudService
	self._configuration = inputConfiguration
	self._memoryStoreDuration = inputConfiguration.teleportStoreSessionDuration or DEFAULT.MEMORY_STORE_DURATION
	self._connections = {}
	self._playlists = {}
	self._boomboxModels = {}
	self._sessions = {}
	self._groupService = if not Configuration.playbackAutoStart and FeatureFlags.groupListening
		then GroupService.New(function(player: Player, owner: Player)
			self:_join(player, owner)
		end, function(player: Player)
			self:_leave(player)
		end, function(playerId: number, event: string)
			self:_syncAudioEventForSession(playerId, event)
		end, function(playerId: number, ownerId: number)
			self:_syncTrackForSession(playerId, ownerId)
		end)
		else nil
	self._delayedAction = {}

	local SongEventsConnection = ReplicatedStorage.Styngr.SongEvents.OnServerEvent:Connect(
		function(player: Player, event)
			if self._groupService and (event == TrackEvent.RESUMED or event == TrackEvent.PAUSED) then
				self._groupService:FireAudioEventForPlayersInSession(player, event)
			end

			-- Hide or show boombox model if not disabled in configuration
			if self._configuration.boombox.disabled == true then
				return
			end

			local boomboxModel = self._boomboxModels[player]
			if event == TrackEvent.PLAYED or event == TrackEvent.RESUMED then
				boomboxModel:Show()
			else
				boomboxModel:Hide()
			end
		end
	)

	Players.PlayerRemoving:Connect(function(player: Player)
		assert(player, "Please, pass in a valid player")

		if not self._sessions or not self._sessions[player.UserId] then
			return
		end

		local data = self._sessions[player.UserId]:Save()
		data.playlistType = self._sessions[player.UserId].type
		data.placeId = game.PlaceId
		pcall(MemoryStore.SetAsync, MemoryStore, player.UserId, data, self._memoryStoreDuration)

		self._delayedAction[player.UserId] = Promise.delay(self._memoryStoreDuration + TIMEOUT_BUFFER)
			:andThen(function()
				self:_sendPlaybackStatistics(player)
			end)
	end)

	table.insert(self._connections, SongEventsConnection)

	if self._configuration.boombox.disabled == nil then
		game.Workspace.ChildAdded:Connect(function(child)
			local player = Players:FindFirstChild(child.Name)

			if not player then
				return
			end

			local model = BoomboxModel.new(self._configuration.boombox.textureId, player)

			if
				self._sessions[player.UserId]
				and self._sessions[player.UserId].tracking
				and not self._sessions[player.UserId].tracking:IsPaused()
			then
				model:Show()
			end

			self._boomboxModels[player] = model
		end)
	end

	ReplicatedStorage.Styngr.GetPlaylists.OnServerInvoke = function(player)
		local result = self:GetPlaylists(player)

		return result or {}
	end

	ReplicatedStorage.Styngr.StartPlaylistSession.OnServerInvoke = function(
		player: Player,
		playlistId: string,
		playlistType: string
	): CommonType.ClientTrack
		assert(typeof(playlistId) == "string", "Playlist ID is not a string")
		assert(PlaylistType[playlistType], "Playlist type is not one of the predefined types")

		local ok, session = self:StartPlaylistSession(player, playlistId, playlistType):await()

		if not ok or not session then
			if session and session.StatusCode == ErrorCodes.EmptyPlaylist then
				return "empty"
			end
			warn(session)
			return nil
		end

		if session.ad then
			return session.ad
		end

		local trackData = buildClientFriendlyTrack(player.UserId, session.track)

		if self._groupService then
			-- Switch playlist if the session is already running, otherwise start the group session
			if self._groupService:IsOwnerInSession(player) then
				self._groupService:SendNewTrackDataToSession(player)
			else
				self._groupService:StartSession(player)
			end
		end

		return trackData
	end

	ReplicatedStorage.Styngr.ContinuePlaylistSession.OnServerInvoke = function(
		player: Player
	): CommonType.ClientTrack | nil
		local session = self:_continuePlaylistSession(player)

		if not session then
			return nil
		end

		local ok, token = self._cloudService:GetToken(player):await()
		if not ok or not token then
			return nil
		end

		if session.ad then
			session.ad.playing = session.track.playing == nil or session.track.playing
			session.ad.timePosition = session.track.timePosition or 0
			return session.ad
		end

		return buildClientFriendlyTrack(player.UserId, session.track)
	end

	ReplicatedStorage.Styngr.AutoStartPlaylistSession.OnServerInvoke = function(
		player: Player
	): CommonType.ClientTrack | nil
		local playlists = self:GetPlaylists(player)

		if not playlists then
			return nil
		end

		for _, p in playlists do
			local success, session = self:StartPlaylistSession(player, p.id, p.type):await()

			if session.ad then
				return session.ad
			end

			if success and session then
				return buildClientFriendlyTrack(player.UserId, session.track)
			end
		end
	end

	ReplicatedStorage.Styngr.RequestNextTrack.OnServerInvoke = function(player: Player): CommonType.ClientTrack
		return self:_handleSession(player, self:RequestNextTrack(player))
	end

	ReplicatedStorage.Styngr.SkipTrack.OnServerInvoke = function(player): CommonType.ClientTrack
		return self:_handleSession(player, self:SkipTrack(player))
	end

	self:_setUnavailableTrackListener()

	game:BindToClose(function()
		self:_onClose()
	end)
end

--[=[
	Gets all accessible playlists for the specified player

	@param player Player -- The player for whom the request is sent

	@return Promise<{{ description: string?, duration: number, id: string, title: string?, trackCount: number }}>
]=]
function RadioService:GetPlaylists(player: Player): table
	assert(
		self._cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	return Playlist:GetAll(self._cloudService, player)
end

--[=[
	Gets all accessible playlists for the specified player

	@param player Player -- The player for whom the request is sent
	@param playlistId number -- The id of the playlist thatt will be played to the user
	@param playlistType string -- Type of the playlist that will be played to the user. Valid values PlaylistType
	@param skipStop boolean -- don't call the stop function of the previous playlist

	@return Promise<{Session}>
]=]
function RadioService:StartPlaylistSession(player: Player, playlistId: string, playlistType: string, skipStop: boolean)
	assert(
		self._cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	local previousPlaylistId = if self._sessions[player.UserId] then self._sessions[player.UserId].playlistId else nil

	if not skipStop and self._sessions[player.UserId] then
		self._sessions[player.UserId]:Stop():await()
	end

	self._sessions[player.UserId] =
		Playlist.Get(self._cloudService, player, playlistId, previousPlaylistId, playlistType)

	return self._sessions[player.UserId]:Start()
end

--[=[
	Request next track to be played from the playlist the player is listening to
	Must be called when the player listened to the whole song till the end and is moving to the next song

	@param player Player -- The player for whom the request is sent

	@return Promise<{Session}>
]=]
function RadioService:RequestNextTrack(player: Player)
	assert(
		self._cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	if self._sessions[player.UserId] then
		local ok, session = self._sessions[player.UserId]:Next():await()

		if ok and session then
			return session
		end
	end
end

--[=[
	Request next track to be played from the playlist the player is listening to
	Must be called when the player explicitely requested the next track and not when the track reached the end

	@param player Player -- The player for whom the request is sent

	@return Promise<{Session}>
]=]
function RadioService:SkipTrack(player: Player)
	assert(
		self._cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	if self._sessions[player.UserId] then
		local ok, session = self._sessions[player.UserId]:Skip():await()

		if ok and session then
			return session
		end
	end
end

function RadioService:_continuePlaylistSession(player): CommonType.ClientTrack | nil
	local _, memoryData = pcall(MemoryStore.GetAsync, MemoryStore, player.UserId)

	if memoryData == nil then
		return nil
	end

	if memoryData.placeId == game.PlaceId then
		pcall(MemoryStore.RemoveAsync, MemoryStore, player.UserId)
		if self._delayedAction[player.UserId] then
			self._delayedAction[player.UserId]:cancel()
			self:_sendPlaybackStatistics(player)
		end
		return nil
	end

	self._sessions[player.UserId] = Playlist.Get(
		self._cloudService,
		player,
		memoryData.session.playlistId,
		memoryData.previousPlaylistId,
		memoryData.playlistType
	)
	local session = self._sessions[player.UserId]:Load(memoryData)

	local store = MemoryStoreService:GetSortedMap(PLAYER_LIST_MEMORY_STORE_NAME .. memoryData.placeId)
	pcall(store.SetAsync, store, player.UserId, true, 2 * self._memoryStoreDuration)
	pcall(MemoryStore.RemoveAsync, MemoryStore, player.UserId)

	return session
end

--[=[
	Send information about played track 

	@param player Player -- The player for whom the request is sent
	
	@return HttpResponse
]=]
function RadioService:_sendPlaybackStatistics(player: Player)
	assert(
		self._cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	if not self._sessions or not self._sessions[player.UserId] then
		return
	end

	local store = MemoryStoreService:GetSortedMap(PLAYER_LIST_MEMORY_STORE_NAME .. game.PlaceId)
	local _, ownershipTaken = pcall(store.GetAsync, store, player.UserId)
	if ownershipTaken then
		pcall(store.RemoveAsync, store, player.UserId)
	else
		self._sessions[player.UserId]:Stop():await()
	end

	self._sessions[player.UserId] = nil
end

function RadioService:_onClose()
	if game:GetService("RunService"):IsStudio() then
		return
	end
	-- playerIds is used for easier tracking of players that still have sessions in progress
	-- as assocciative tables are harder to handle
	local playerIds = {}
	for playerId, _ in pairs(self._sessions) do
		table.insert(playerIds, playerId)
	end

	if #playerIds == 0 then
		return
	end

	local function process()
		local store = MemoryStoreService:GetSortedMap(PLAYER_LIST_MEMORY_STORE_NAME .. game.PlaceId)

		for index = #playerIds, 1, -1 do
			local playerId = playerIds[index]
			local _, ownershipTaken = pcall(store.GetAsync, store, playerIds[index])
			if ownershipTaken then
				table.remove(playerIds, index)
				self._sessions[playerId] = nil
				pcall(store.RemoveAsync, store, playerId)
			end
		end
	end

	local function sendStatistics()
		local promises = {}
		for playerId, session in pairs(self._sessions) do
			table.insert(promises, session:Stop())
			pcall(MemoryStore.RemoveAsync, MemoryStore, playerId)
		end
		Promise:all(promises):await()
	end

	for _ = 0, ON_CLOSE_SESSIONS_SEND, 1 do
		task.wait(1)
		process()
		if #playerIds == 0 then
			return
		end
	end

	sendStatistics()
end

function RadioService:_startPlaylistSessionAgain(player: Player, trackSession: table): CommonType.ClientTrack | nil
	if trackSession and trackSession.StatusCode ~= ErrorCodes.PlaylistEnded then
		warn(trackSession)
		return nil
	end

	local playerSession = self._sessions[player.UserId]
	local ok, session = self:StartPlaylistSession(player, playerSession.playlistId, playerSession.type, true):await()

	if not ok and not session then
		return nil
	end

	return buildClientFriendlyTrack(player.UserId, session.track)
end

function RadioService:_setUnavailableTrackListener(): CommonType.ClientTrack
	ReplicatedStorage.Styngr.UnavailableTrack.OnServerInvoke = function(player: Player, error): CommonType.ClientTrack
		assert(
			self._cloudService,
			"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
		)

		if not self._sessions[player.UserId] then
			return "No playlist found"
		end

		local ok, session = self._sessions[player.UserId]:Unavailable(error):await()

		if not ok or not session then
			return self:_startPlaylistSessionAgain(player, session)
		end

		return buildClientFriendlyTrack(player.UserId, session.track)
	end
end

function RadioService:_join(player: Player, owner: Player): nil
	local session = self._sessions[owner.UserId]
	local tracking = session.tracking
	local sync = if tracking and tracking.started then os.time() - tracking.started + tracking.totalPaused else 0

	local clientTrack = buildClientFriendlyTrack(player.UserId, session._session.track, sync)
	ReplicatedStorage.Styngr.ListenToGroupSessionEvent:FireClient(player, owner, clientTrack)
end

function RadioService:_leave(player: Player): nil
	ReplicatedStorage.Styngr.RemoveGroupSessionEvent:FireClient(player)
end

function RadioService:_syncAudioEventForSession(player: Player, event: string): nil
	ReplicatedStorage.Styngr.GroupSessionSongEvent:FireClient(player, event)
end

function RadioService:_syncTrackForSession(player: Player, owner: Player): nil
	local session = self._sessions[owner.UserId]
	local tracking = session.tracking
	local sync = if tracking and tracking.started then os.time() - tracking.started + tracking.totalPaused else 0

	local clientTrack = buildClientFriendlyTrack(player.UserId, session._session.track, sync)
	ReplicatedStorage.Styngr.GroupSessionSetNewSongEvent:FireClient(player, owner, clientTrack)
end

function RadioService:_handleTrackData(player: Player, session: table)
	local trackData = buildClientFriendlyTrack(player.UserId, session.track)
	if self._groupService then
		self._groupService:SendNewTrackDataToSession(player)
	end
	return trackData
end

function RadioService:_handleSession(player, session)
	if not session then
		return self:_startPlaylistSessionAgain(player, session)
	end

	if session.ad then
		return session.ad
	end

	return self:_handleTrackData(player, session)
end

return RadioService
