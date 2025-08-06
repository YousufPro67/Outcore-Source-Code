--!strict
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent
local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes

local OnGetFeaturedCategoriesRemote

local Payload = require(ServerScriptService.BloxbizSDK.CatalogShared.FeedUtils.Payload)
local AdRequestStats = require(BloxbizSDK.AdRequestStats)
local BatchHTTP = require(BloxbizSDK.BatchHTTP)
local InternalConfig = require(BloxbizSDK.InternalConfig)
local Utils = require(BloxbizSDK.Utils)
local Promise = require(BloxbizSDK.Utils.Promise)
local RateLimiter = require(BloxbizSDK.Utils.RateLimiter)

local CatalogShared = BloxbizSDK.CatalogShared
local FeedUtils = require(CatalogShared.FeedUtils)

local SAVE_IN_STUDIO = true
local IsStudio = RunService:IsStudio()

type Profile = FeedUtils.Profile
local DEFAULT_DATA: Profile = {
	Posted = {},
	Liked = {},
}

local FeaturedCategories = {}

local _cachedFeatured = nil

local function GetFeatured()
	if _cachedFeatured then
		return _cachedFeatured
	end

	local result = Utils.callWithRetry(function()
		local success, res = BatchHTTP.request("POST", "/catalog/categories/featured", {
			sdk_version = InternalConfig.SDK_VERSION
		})

		if not success then
			error(res)
		end

		return res
	end, 5)

	_cachedFeatured = result.categories
	return _cachedFeatured
end

function FeaturedCategories.Init() 
	-- impressions / try ons --

	OnGetFeaturedCategoriesRemote = Instance.new("RemoteFunction")
	OnGetFeaturedCategoriesRemote.Name = "CatalogOnGetFeatured"
	OnGetFeaturedCategoriesRemote.OnServerInvoke = GetFeatured
	OnGetFeaturedCategoriesRemote.Parent = BloxbizRemotes
end

return FeaturedCategories
