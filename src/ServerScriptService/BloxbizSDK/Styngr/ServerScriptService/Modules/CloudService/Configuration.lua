local Endpoints = require(script.Parent.Parent.Endpoints)
local HttpMethods = require(script.Parent.HttpMethods)
local TokenType = require(script.Parent.TokenType)

local Configuration = {
	[Endpoints.CreateToken] = {
		Endpoint = "/v2/sdk/tokens",
		Method = HttpMethods.POST,
		TokenType = TokenType.NO_TOKEN,
	},
	[Endpoints.CreateStoreToken] = {
		Endpoint = "/v2/sdk/tokens/sdkuser",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Playlists] = {
		Endpoint = "/v3/sdk/apps/{appId}/playlists/all",
		Method = HttpMethods.GET,
		TokenType = TokenType.NO_TOKEN,
	},
	[Endpoints.Licensed.Next] = {
		Endpoint = "/v2/sdk/integration/playlists/{playlistId}/next?createAssetUrl=false",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Licensed.PlaybackStatistics] = {
		Endpoint = "/v1/sdk/statistics/playback",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Licensed.Skip] = {
		Endpoint = "/v2/sdk/integration/playlists/{playlistId}/skip?createAssetUrl=false",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Licensed.Start] = {
		Endpoint = "/v2/sdk/integration/playlists/{playlistId}/start?trackFormat=AAC&createAssetUrl=false",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.RoyaltyFree.Next] = {
		Endpoint = "/v3/sdk/royalty-free/playlists/{playlistId}/next",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.RoyaltyFree.Start] = {
		Endpoint = "/v3/sdk/royalty-free/playlists/{playlistId}/start",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.RoyaltyFree.Stop] = {
		Endpoint = "/v3/sdk/royalty-free/playlists/{playlistId}/stop",
		Method = HttpMethods.POST,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Subscription.Available] = {
		Endpoint = "/v1/sdk/radio/{appId}/subscriptions/available",
		Method = HttpMethods.GET,
		TokenType = TokenType.STORE_TOKEN,
	},
	[Endpoints.Subscription.CancelPendingPaymentTransaction] = {
		Endpoint = "/v1/sdk/payments/cancel",
		Method = HttpMethods.POST,
		TokenType = TokenType.NO_TOKEN,
	},
	[Endpoints.Subscription.ConfirmPayment] = {
		Endpoint = "/v1/sdk/payments/confirm",
		Method = HttpMethods.POST,
		TokenType = TokenType.NO_TOKEN,
	},
	[Endpoints.Subscription.Info] = {
		Endpoint = "/v1/sdk/subscription/my",
		Method = HttpMethods.GET,
		TokenType = TokenType.TOKEN,
	},
	[Endpoints.Subscription.Pay] = {
		Endpoint = "/v1/sdk/radio/{appId}/paySubscription",
		Method = HttpMethods.POST,
		TokenType = TokenType.STORE_TOKEN,
	},
	[Endpoints.Subscription.PurchaseBundle] = {
		Endpoint = "/v1/sdk/radio/{appId}/bundle/purchase",
		Method = HttpMethods.POST,
		TokenType = TokenType.STORE_TOKEN,
	},
	[Endpoints.UpdateUserInformation] = {
		Endpoint = "/v1/sdk/sdkusers/{userId}/statistics",
		Method = HttpMethods.POST,
		TokenType = TokenType.NO_TOKEN,
	},
	[Endpoints.Error] = {
		Endpoint = "/v1/sdk/application/{appId}/error",
		Method = HttpMethods.POST,
		TokenType = TokenType.NO_TOKEN,
	},
}

for _, value in Configuration do
	assert(
		value.TokenType == nil or TokenType[value.TokenType] ~= nil,
		"tokenType has to be undefined or be specific TokenType"
	)
	assert(HttpMethods[value.Method] ~= nil, "Invalid HTTP method.")
end

return Configuration
