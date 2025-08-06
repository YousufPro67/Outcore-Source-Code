local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--Leave the spacing here to avoid MarketplaceServiceWrappper replacements
local MarketplaceService = game:GetService( "MarketplaceService" )

--server side only
local BatchHTTP
local InferredPlayerData

local HashLib = require(script.Parent.HashLib)
local AdRequestStats = require(script.Parent.AdRequestStats)
local Utils = require(script.Parent.Utils)

local DEFAULT_EXPERIMENT_GUID = 0
local VAR_PRICING_FETCH_INTERVAL = 5
local MAX_RETRY_FETCH = 5
local REMOTES_FOLDER = "BloxbizRemotes"

local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
local remoteFunction = remotesFolder:WaitForChild("marketplaceServiceWrapper")

local module = {}
module._variablePricingData = {}
module._experimentData = {}

--Only one instance of the module should exist on client/server
--Since devs require through ReplicatedStorage on client, we'll keep that consistency on the server
if script.Parent.Parent ~= ReplicatedStorage then
	error("[Super Biz] Module should only be required through ReplicatedStorage")
end

function module:createWrapper()
	return setmetatable(self, {
		__index = function(_, index)
			local success, result = pcall(function()
				return rawget(module, index) or MarketplaceService[index]
			end)

			if not success then
				error("[Super Biz] " .. tostring(index) .. " is not a valid member of MarketplaceService or cannot be read")
			end

			if type(result) == "function" then
				--self below will be this module instead of MarketplaceService when using this wrapper
				--this errors with Roblox, so we must replace it with original service instance
				return function(self, ...)
					return result(MarketplaceService, ...)
				end
			end

			return result
		end,
		__newindex = function(_, index, value)
			if index == "ProcessReceipt" then
				if type(value) ~= "function" then
					error("[Super Biz] Attempt to set ProcessReceipt with a non-function value")
				end

				MarketplaceService.ProcessReceipt = function(receiptInfo)
					receiptInfo.ProductId = module:getBaseIdFromGenericId(receiptInfo.ProductId)
					return value(receiptInfo)
				end

				return
			end

			local success, result = pcall(function()
				MarketplaceService[index] = value
			end)

			if not success then
				error("[Super Biz] " .. result)
			end
		end,
		__metatable = function()
			error("[Super Biz] Attempt to access metatable for MarketplaceService wrapper")
		end,
	})
end

function module:PromptProductPurchase(player, productId, ...)
	if not player or not productId then
		error("[SuperBiz] Attempt to call PromptProductPurchase with missing argument")
	end

	local variantId = self:_getVariantIdForPlayer(player.UserId, productId)

	return MarketplaceService:PromptProductPurchase(player, variantId, ...)
end

function module:PromptGamePassPurchase(player, gamePassId)
	if not player or not gamePassId then
		error("[SuperBiz] Attempt to call PromptGamePassPurchase with missing argument")
	end

	local variantId = self:_getVariantIdForPlayer(player.UserId, gamePassId)

	return MarketplaceService:PromptGamePassPurchase(player, variantId)
end

function module:UserOwnsGamePassAsync(playerId, gamePassId)
	if not playerId or not gamePassId then
		error("[Super Biz] Attempt to call UserOwnsGamePassAsync with missing argument")
	end

	local variantId = self:_getVariantIdForPlayer(playerId, gamePassId)

	return MarketplaceService:UserOwnsGamePassAsync(playerId, variantId)
end

function module:GetProductInfo(productId, infoType)
	if not productId or not infoType then
		error("[Super Biz] Attempt to call GetProductInfo with missing argument")
	end

	local playerId = nil
	if RunService:IsClient() then
		playerId = Players.LocalPlayer.UserId
	end

	local variantId = self:_getVariantIdForPlayer(playerId, productId)

	return MarketplaceService:GetProductInfo(variantId, infoType)
end

local function countDictionary(dict)
	local count = 0
	for _, _ in dict do
		count += 1
	end
	return count
end

function module:getPlayerExperimentGroup(playerId, variantId)
	local experimentGuid = DEFAULT_EXPERIMENT_GUID

	InferredPlayerData = require(script.Parent.AdFilter.InferredPlayerData)
	local playerTier = InferredPlayerData:Get(playerId).tier
	local baseId = self:getBaseIdFromVariantId(variantId)
	local experimentKey = tostring(baseId) .. playerTier
	local experimentGroups = self._experimentData[experimentKey]

	if not experimentGroups then
		return nil
	end

	local seed = tostring(playerId) .. tostring(experimentGuid)
	local hash = string.sub(HashLib.sha256(seed), 1, 8)
	hash = tonumber(hash, 16) / 0xFFFFFFFF

	local numGroups = countDictionary(experimentGroups)
	return math.floor(numGroups * hash)
end

function module:_getVariantIdForPlayer(playerId, baseId)
	if not playerId then
		return baseId
	end

	if RunService:IsClient() then
		return remoteFunction:InvokeServer("getVariantIdForPlayer", playerId, baseId)
	end

	if not self._variablePricingData[baseId] then
		return baseId
	end

	InferredPlayerData = require(script.Parent.AdFilter.InferredPlayerData)

	local playerTier = InferredPlayerData:Get(playerId).tier
	local variantId = self._variablePricingData[baseId][playerTier]
	if not variantId then
		return baseId
	end

	local experimentKey = tostring(baseId) .. playerTier
	local productExperimentExists = self._experimentData[experimentKey]
	if productExperimentExists then
		local playerGroup = self:getPlayerExperimentGroup(playerId, variantId)
		local experimentVariantId = self._experimentData[experimentKey][playerGroup]

		return experimentVariantId
	end

	return variantId
end

-- Note: one experiment per tier but multiple groups per experiment
function module:_formatPriceExperiments(productData)
	for _, experiment in productData.price_experiments do
		if experiment.enabled == false then
			continue
		end

		local tierName = experiment.tier
		local baseId = productData.product_id
		local experimentKey = tostring(baseId) .. tierName
		self._experimentData[experimentKey] = {}

		for _, experimentGroup in experiment.price_options do
			local experimentVariantId = experimentGroup.product_variant_id
			local groupNum = experimentGroup.group
			self._experimentData[experimentKey][groupNum] = experimentVariantId
		end
	end
end

function module:_formatPricingDataFetch(fetch)
	local formatted = {}

	for _, productData in ipairs(fetch) do
		local baseId = productData.product_id
		formatted[baseId] = {}

		for _, variantData in ipairs(productData.price_tiers) do
			local tierName = variantData.tier
			local variantId = variantData.product_variant_id
			formatted[baseId][tierName] = variantId
		end

		self:_formatPriceExperiments(productData)
	end

	return formatted
end

function module:_refreshVariablePricingData()
	local postData = {
		--N/A?
	}
	local gameStats = AdRequestStats:getGameStats()

	postData = Utils.merge(postData, gameStats)

	BatchHTTP = require(script.Parent.BatchHTTP)
	local url = BatchHTTP.getNewUrl("product-price")
	local jsonedData = HttpService:JSONEncode(postData)
	local httpOkay, result = pcall(HttpService.PostAsync, HttpService, url, jsonedData)

	if httpOkay then
		result = HttpService:JSONDecode(result).data
		result = self:_formatPricingDataFetch(result)
		self._variablePricingData = result

		return true
	else
		return result
	end
end

function module:_refreshVariablePricingOnInterval()
	while true do
		Utils.callWithRetry(function()
			module:_refreshVariablePricingData()
		end, MAX_RETRY_FETCH)

		task.wait(VAR_PRICING_FETCH_INTERVAL * 60)
	end
end

function module:getVariantIdFromExperimentVariantId(experimentVariantId)
	for experimentKey, experimentGroups in self._experimentData do
		for groupNum, idToCompare in experimentGroups do
			if idToCompare == experimentVariantId then
				local baseId = tonumber(string.match(experimentKey, "%d+"))
				local tierName = string.match(experimentKey, "%d+(.+)")
				local variantId = self._variablePricingData[baseId][tierName]
				return variantId
			end
		end
	end
end

function module:getBaseIdFromVariantId(variantId)
	for baseId, variantDict in self._variablePricingData do
		for tier, dictVariantId in variantDict do
			if variantId == dictVariantId then
				return baseId
			end
		end
	end
end

--Exposed to be used by monetization analytics
--Dev workflow: variant IDs shouldn't be considered in dev work/code
function module:getBaseIdFromGenericId(variantId)
	local experimentToVariant = self:getVariantIdFromExperimentVariantId(variantId)
	if experimentToVariant then
		variantId = experimentToVariant
	end

	local variantToBase = self:getBaseIdFromVariantId(variantId)
	if variantToBase then
		variantId = variantToBase
	end

	return variantId
end

function module:_connectToEventsServer()
	remoteFunction.OnServerInvoke = function(player, query, ...)
		if query == "getVariantIdForPlayer" then
			return self:_getVariantIdForPlayer(...)
		end
	end
end

function module:initServer()
	self:_connectToEventsServer()

	task.spawn(function()
		self:_refreshVariablePricingOnInterval()
	end)
end

return module:createWrapper()
