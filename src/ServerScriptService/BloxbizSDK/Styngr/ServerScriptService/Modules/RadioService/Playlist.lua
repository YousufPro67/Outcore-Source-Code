local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage.Styngr.Types)
local PlaylistType = require(ReplicatedStorage.Styngr.PlaylistType)
local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)

local CloudService = require(script.Parent.Parent.CloudService)
local Endpoints = require(script.Parent.Parent.Endpoints)
local GetCountryRegionForPlayer = require(script.Parent.Parent.Parent.Utils.GetCountryRegionForPlayer)
local Licensed = require(script.Parent.Licensed)
local RoyaltyFree = require(script.Parent.RoyaltyFree)
local Session = require(script.Parent.Session)

local CACHE_TIMEOUT = 60 * 60 -- seconds

local Playlist = {
	data = {},
	loading = false,
}

--[=[
	Get session for the specified playlist id and the type of the playlist

	@param cloudService CloudService.ICloudService -- Cloud service to use to get the data from
	@param player Player -- The player for whom the request is sent
	@param playlistId string -- The id of the playlist to create the session for
	@param previousSession table -- Previous session to send in statistics if another playlist was played before this
	@param type string -- Type of the playlist to instanciate

	@return Session -- Instance of a class containing the Session interface
]=]
function Playlist.Get(
	cloudService: CloudService.ICloudService,
	player: Player,
	playlistId: string,
	previousPlaylistId: string,
	type: string
): Session.ISession
	type = type or PlaylistType.LICENSED

	if type == PlaylistType.LICENSED then
		return Licensed.New(cloudService, player, playlistId, previousPlaylistId)
	end

	if type == PlaylistType.ROYALTY_FREE then
		return RoyaltyFree.New(cloudService, player, playlistId, previousPlaylistId)
	end

	error("Type for playlist not valid.")
end

--[=[
	Get all playlists.
    @param cloudService CloudService.ICloudService -- Cloud service to use to get the data from
	@param player Player -- The player for whom the request is sent

	@return table -- List of playlists
]=]
function Playlist:GetAll(cloudService: CloudService.ICloudService, player: Player): table
	local function filter(): table
		if not player then
			return self.data
		end

		local ok, countryCode = GetCountryRegionForPlayer(player)

		if not ok then
			return {}
		end

		local available = {}
		for _, playlist in ipairs(self.data) do
			if table.find(playlist.availability, countryCode) ~= nil then
				table.insert(available, playlist)
			end
		end

		return available
	end

	assert(
		cloudService,
		"Please initialize RadioService using RadioService.SetConfiguration() before calling this method!"
	)

	while not self.data and self.loading do
		task.wait(0.1)
	end

	if next(self.data) then
		return filter()
	end

	self.loading = true
	local ok, data = cloudService
		:Call(player, Endpoints.Playlists)
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				local body = HttpService:JSONDecode(result.Body)

				if body["playlists"] then
					self.data = body["playlists"]
					Promise.delay(CACHE_TIMEOUT):andThen(function()
						self.data = {}
					end)
					resolve(filter())
				else
					reject()
				end
			end)
		end)
		:catch(function(error)
			warn(error)
			return Promise.resolve({})
		end)
		:finally(function()
			self.loading = false
		end)
		:await()

	return if ok then data else {}
end

return Playlist
