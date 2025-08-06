--[=[
	@class CloudService

	Middleware for external API calls
]=]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)

local Configuration = require(script.Parent.CloudService.Configuration)
local Common = require(script.Parent.Parent.Utils.Common)
local Endpoints = require(script.Parent.Endpoints)
local GetCountryRegionForPlayer = require(script.Parent.Parent.Utils.GetCountryRegionForPlayer)
local HttpMethods = require(script.Parent.CloudService.HttpMethods)
local SendTokenReceived = require(script.Parent.Parent.Utils.SendTokenReceived)
local SendTokenLost = require(script.Parent.Parent.Utils.SendTokenLost)
local TokenType = require(script.Parent.CloudService.TokenType)
local Types = require(script.Parent.Parent.Types)

local PLATFORM = "Roblox-Unknown"
local DEVICE_ID = "DeviceID"
local DEFAULTS = {
	timer = {
		duration = 10800, -- in seconds
		minimum = 3600, -- in seconds
	},
	apiServer = "https://api.styngr.com/api",
}
local UPDATE_AGE_TIMEOUT = 86400 -- in seconds
local TIMEOUT_BUFFER = 10 -- in seconds

local ageDataStore = DataStoreService:GetDataStore("AgeUpdate", "Styngr")

local function getGender()
	local FEMALE_TO_MALE_RATIO = 44

	if math.random(0, 100) > FEMALE_TO_MALE_RATIO then
		return "MALE"
	else
		return "FEMALE"
	end
end

local function setAgeUpdateInStore(player: Player, areAdsAllowed: boolean)
	assert(player:IsA("Player"), "player must be instance of Player")
	assert(type(areAdsAllowed) == "boolean", "areAdsAllowed must be boolean")
	local ok, result = pcall(ageDataStore.SetAsync, ageDataStore, player.UserId, areAdsAllowed)

	if not ok then
		warn("AgeUpdatedInDataStore error:", result)
	end
end

export type ICloudService = {
	GetToken: (player: Player) -> string,
	ClearStoreToken: (player: Player) -> nil,
	Call: (player: Player, endpoint: string, body: table | nil, parameters: table | nil) -> any,
}

local CloudService: ICloudService = {}

CloudService.__index = CloudService

--[=[
	Creates a new CloudService instance with the specified configuration

	@param inputConfiguration { apiKey: string, appId: string, apiServer: string? } -- Configuration
]=]
function CloudService.New(inputConfiguration: Types.CloudServiceConfiguration)
	assert(
		inputConfiguration
			and typeof(inputConfiguration.apiKey) == "string"
			and inputConfiguration.apiKey ~= ""
			and typeof(inputConfiguration.appId) == "string"
			and inputConfiguration.appId ~= "",
		"Please ensure all CloudService constructor params are filled out!"
	)

	local self = {
		_tokens = {},
		_storeTokens = {},
		_timers = {},
		_tokensLoading = {},
		_userCanListenAds = {},
		_appId = inputConfiguration.appId,
		_configuration = inputConfiguration,
		_tokenDuration = {
			duration = inputConfiguration.tokenDuration or DEFAULTS.timer.duration,
			minimum = inputConfiguration.minimalTokenDuration or DEFAULTS.timer.minimum,
		},
		_apiServer = inputConfiguration.apiServer or DEFAULTS.apiServer,
		_updateUserAge = {},
	}

	setmetatable(self, CloudService)

	return self
end

function CloudService:_shouldUpdateUser(player: Player): boolean
	if self._updateUserAge[player.UserId] ~= nil then
		return self._updateUserAge[player.UserId]
	end

	local ok, areAdsAllowed, keyInfo = pcall(ageDataStore.GetAsync, ageDataStore, player.UserId)

	if not ok then
		warn("Error: data not retrieved from data store")
		return true
	end

	self._updateUserAge[player.UserId] = not keyInfo
		or (not areAdsAllowed and (os.time() + UPDATE_AGE_TIMEOUT < (keyInfo.UpdatedTime / 1000)))

	Promise.delay(UPDATE_AGE_TIMEOUT - TIMEOUT_BUFFER):andThen(function()
		self._updateUserAge[player.UserId] = nil
	end)

	return self._updateUserAge[player.UserId]
end

--[[
	Makes a HttpService call to the external API that returns a token for the specified userId
]]
function CloudService:_createToken(player: Player)
	assert(
		self._tokens,
		"Please make sure that you have set up a new CloudService instance before calling this method!"
	)

	assert(player:IsA("Player"), "Please pass in a valid player!")

	local countryOk, countryCode = GetCountryRegionForPlayer(player)

	assert(typeof(countryCode) == "string", "Error in retrieving countryCode!")

	local duration = self:_getTokenDuration()

	local body = {
		appId = self._configuration.appId,
		deviceId = DEVICE_ID .. tostring(player.UserId),
		expiresIn = "PT" .. tostring(duration) .. "S",
		userId = tostring(player.UserId),
		platform = PLATFORM,
		countryCode = countryCode,
	}

	while not self._tokens[player.UserId] and self._tokensLoading[player.UserId] do
		task.wait(0.1)
	end

	if self._tokens[player.UserId] then
		return Promise.resolve(self._tokens[player.UserId])
	end
	self._tokensLoading[player.UserId] = true

	return self:Call(player, Endpoints.CreateToken, body)
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				local resultBody = HttpService:JSONDecode(result.Body)

				if resultBody["token"] then
					self._tokens[player.UserId] = resultBody["token"]
					self:_updateUser(player)
					SendTokenReceived(player)

					Promise.delay(duration - TIMEOUT_BUFFER):andThen(function()
						self._tokens[player.UserId] = nil
					end)

					resolve(resultBody["token"])
				else
					SendTokenLost(player)
					reject(result)
				end
			end)
		end)
		:catch(function(error)
			warn(error)
			SendTokenLost(player)
		end)
		:finally(function()
			self._tokensLoading[player.UserId] = false
		end)
end

--[=[
	Gets or creates token for the specified player

	@param player Player -- User to get or create token for
]=]
function CloudService:GetToken(player: Player): string
	assert(
		self._tokens,
		"Please make sure that you have set up a new CloudService instance before calling this method!"
	)

	assert(player, "Please pass in a valid player!")

	return Promise.new(function(resolve, reject)
		if self._tokens[player.UserId] then
			SendTokenReceived(player)
			resolve(self._tokens[player.UserId])
		else
			self:_createToken(player):andThen(resolve, reject)
		end
	end)
end

function CloudService:_storeToken(player: Player): string
	assert(
		self._storeTokens,
		"Please, make sure that you have set up a new CloudService instance before calling this method!"
	)

	assert(player, "Please, pass in a valid player")

	local function getToken()
		return Promise.new(function(resolve, reject)
			local existingToken = self._storeTokens[player.UserId]
			if existingToken then
				resolve(existingToken)
			else
				reject()
			end
		end)
	end

	local function processResult(result: string): string
		return Promise.new(function(resolve, reject)
			local resultBody = HttpService:JSONDecode(result.Body)

			if resultBody ~= nil and resultBody["accessToken"] ~= nil then
				self._storeTokens[player.UserId] = resultBody["accessToken"]
				resolve(resultBody["accessToken"])
			else
				reject(result)
			end
		end)
	end

	return Promise.new(function(resolve, reject)
		return getToken():andThen(resolve, function()
			return self:Call(player, Endpoints.CreateStoreToken):andThen(processResult):andThen(resolve, reject)
		end)
	end)
end

function CloudService:ClearStoreToken(player: Player): nil
	assert(
		self._storeTokens,
		"Please, make sure that you have set up a new CloudService instance before calling this method!"
	)

	assert(player, "Please, pass in a valid player")

	if self._storeTokens[player.UserId] then
		self._storeTokens[player.UserId] = nil
	end
end

--[=[
	Wraps around the default `HttpService:Request()` method to include headers and additional metadata for the API request

	@param token string -- API token to authenticate request with
	@param endpoint string -- The endpoint to call externally
	@param method string -- The method to use (GET, POST, PATCH, DELETE, PUT)
	@param body table? -- A table containing any data you want to follow along with your request
]=]
function CloudService:Call(
	player: Player,
	endpoint: string,
	body: table | nil,
	parameters: table | nil,
	headers: table | nil
)
	assert(
		Configuration[endpoint] ~= nil
			and endpoint
			and typeof(endpoint) == "string"
			and (body == nil or typeof(body) == "table")
			and (parameters == nil or typeof(parameters) == "table")
			and (headers == nil or typeof(headers) == "table")
			and (
				(player and player:IsA("Player"))
				or (not player and Configuration[endpoint].TokenType == TokenType.NO_TOKEN)
			),
		"Please ensure all parameters have been passed in and are of correct type!"
	)

	local tokenType = Configuration[endpoint].TokenType

	headers = headers or {}

	if tokenType == TokenType.NO_TOKEN then
		headers["x-api-token"] = self._configuration.apiKey
		return self:_call(endpoint, headers, body, parameters)
	end

	local function call(token)
		headers["Authorization"] = "Bearer " .. token
		return self:_call(endpoint, headers, body, parameters)
	end

	if tokenType == TokenType.STORE_TOKEN then
		return self:_storeToken(player):andThen(call)
	end

	return self:GetToken(player):andThen(call)
end

function CloudService:_call(endpoint, headers, body, parameters)
	local method = Configuration[endpoint].Method
	local uri = Configuration[endpoint].Endpoint

	parameters = parameters or {}
	if uri:find("{appId}") then
		uri = uri:gsub("{appId}", self._appId)
	end

	for key, value in pairs(parameters) do
		uri = uri:gsub("{" .. key .. "}", value)
	end

	local request = {
		Url = self._apiServer .. uri,
		Method = method,
		Headers = {
			Accept = "application/json",
			["Content-Type"] = "application/json",
		},
	}

	for key, value in headers do
		request.Headers[key] = value
	end

	if body then
		request.Body = HttpService:JSONEncode(body)
	else
		if method == HttpMethods.POST then
			request.Body = ""
		end
	end

	return Promise.new(function(resolve, reject)
		local ok, result = pcall(HttpService.RequestAsync, HttpService, request)

		if ok and result.Success == true then
			resolve(result)
		else
			reject(result)
		end
	end)
end

function CloudService:_updateUser(player: Player): nil
	assert(player:IsA("Player"), "player must be an instance of Player")

	if self:_shouldUpdateUser(player) == false then
		return
	end

	local age, areAdsAllowed = Common.getPlayerAgeInfo(player)
	local body = {
		appId = self._appId,
		birthdate = age,
		gender = getGender(),
	}

	self:Call(player, Endpoints.UpdateUserInformation, body, { userId = player.UserId })
		:andThen(function()
			setAgeUpdateInStore(player, areAdsAllowed)
		end)
		:catch(function(error)
			warn(error)
		end)
		:await()
end

function CloudService:_getTokenDuration()
	return if self._tokenDuration.duration < self._tokenDuration.minimum
		then self._tokenDuration.minimum
		else self._tokenDuration.duration
end

return CloudService
