local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)

local CommonUtils = require(script.Parent.Parent.Utils.Common)
local CloudService = require(script.Parent.CloudService)
local Endpoints = require(script.Parent.Endpoints)
local GetCountryRegionForPlayer = require(script.Parent.Parent.Utils.GetCountryRegionForPlayer)
local PurchaseTypes = require(script.Parent.PurchaseService.Type)
local Types = require(script.Parent.Parent.Types)

local TRASNSACTION_ID_STRING = "transactionId"

local SubscriptionType = {
	["STORE"] = "STORE",
	["BUNDLE"] = "BUNDLE",
}

local PurchaseService = {}

function PurchaseService:SetConfiguration(
	cloudService: CloudService.ICloudService,
	inputConfiguration: Types.PurchaseServiceConfiguration
)
	assert(
		inputConfiguration and inputConfiguration.appId and typeof(inputConfiguration.appId) == "string",
		"Please ensure all CloudService constructor params are filled out!"
	)

	self._cloudService = cloudService
	self._appId = inputConfiguration.appId
	self._apiKey = inputConfiguration.apiKey
	self._purchases = {}

	ReplicatedStorage.Styngr.Purchase.OnServerInvoke = function(player, passId)
		assert(player, "Please, pass in a valid player")

		local passIdType = self:_determinePurchaseType(passId)

		if passIdType == nil then
			local errorMessage = "pass ID cannot be nil!"
			error(errorMessage)
		else
			local ok, transactionId = false, nil
			if passIdType == SubscriptionType.STORE then
				ok, transactionId = self:Subscribe(player, passId):await()
			elseif passIdType == SubscriptionType.BUNDLE then
				ok, transactionId = self:PurchaseBundle(player, passId):await()
			end

			if not ok or not transactionId then
				warn(transactionId)
				return nil
			end

			return transactionId
		end
	end

	ReplicatedStorage.Styngr.SubscriptionInfo.OnServerInvoke = function(player)
		assert(player, "Please, pass in a valid player")

		local ok, infoTable = self:GetMySubscriptionInfo(player):await()

		if not ok or not infoTable then
			warn(infoTable)
			return nil
		end

		return infoTable
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, purchasedPassID: string, purchaseSuccess: boolean): Enum.ProductPurchaseDecision
			purchasedPassID = tostring(purchasedPassID)
			if
				self._purchases == nil
				or self._purchases[player.UserId] == nil
				or self._purchases[player.UserId][purchasedPassID] == nil
			then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local result = false
			if purchaseSuccess then
				local purchasePassType = self:_determinePurchaseType(purchasedPassID)
				print(
					player.Name .. " purchased the Pass with ID " .. purchasedPassID .. " and type " .. purchasePassType
				)
				result = self:ConfirmTransaction(player, purchasedPassID, purchasePassType)
			else
				print(player.Name .. " didn't purchase the Pass with ID " .. purchasedPassID)
				result = self:CancelTransaction(player, purchasedPassID)
			end

			ReplicatedStorage.Styngr.PurchaseEvent:FireClient(player)

			return result
		end
	)

	ReplicatedStorage.Styngr.GetPurchaseItems.OnServerInvoke = function(player)
		assert(player, "Please, pass in a valid player")

		local ok, availablePurchaseItems = self:GetAllSubscriptions(player):await()

		if not ok and not availablePurchaseItems and not PurchaseTypes then
			return nil
		end

		local purchaseItems = self._getPurchaseItems(availablePurchaseItems, PurchaseTypes)

		return purchaseItems
	end
end

function PurchaseService:Subscribe(player: Player, passId: number): string
	assert(
		self._cloudService,
		"Please initialize PurchaseService using PurchaseService.SetConfiguration() before calling this method!"
	)

	local countryResult, countryCode = GetCountryRegionForPlayer(player)
	if not countryResult then
		return "Invalid country"
	end

	return self._cloudService:Call(player, Endpoints.Subscription.Pay):andThen(function(result)
		return Promise.new(function(resolve, reject)
			local parsedBody = HttpService:JSONDecode(result.Body)

			if parsedBody ~= nil and parsedBody[TRASNSACTION_ID_STRING] then
				local transactionId = parsedBody[TRASNSACTION_ID_STRING]
				if self._purchases[player.UserId] == nil then
					self._purchases[player.UserId] = {}
				end
				self._purchases[player.UserId][passId] = {
					billingCountry = countryCode,
					trxId = transactionId,
				}
				resolve(transactionId)
			else
				reject("Invalid response.")
			end
		end):catch(function(error)
			warn(error)
		end)
	end)
end

function PurchaseService:GetAllSubscriptions(player: Player): string
	assert(
		self._cloudService,
		"Please initialize PurchaseService using PurchaseService.SetConfiguration() before calling this method!"
	)

	return self._cloudService
		:Call(player, Endpoints.Subscription.Available)
		:andThen(function(result)
			return Promise.new(function(resolve, reject)
				local body = HttpService:JSONDecode(result.Body)

				if body ~= nil and body["radioBundles"] or body["subscriptions"] then
					resolve(body)
				else
					reject()
				end
			end)
		end)
		:catch(function(error)
			warn(error)
		end)
end

function PurchaseService:PurchaseBundle(player: Player, passId: number): string
	assert(
		self._cloudService,
		"Please initialize PurchaseService using PurchaseService.SetConfiguration() before calling this method!"
	)

	local countryResult, countryCode = GetCountryRegionForPlayer(player)
	if not countryResult then
		return "Invalid country"
	end

	local body = {
		bundleToPurchase = self:_determineBundleName(passId),
	}

	return self._cloudService:Call(player, Endpoints.Subscription.PurchaseBundle, body):andThen(function(result)
		return Promise.new(function(resolve, reject)
			local parsedBody = HttpService:JSONDecode(result.Body)

			if parsedBody ~= nil and parsedBody[TRASNSACTION_ID_STRING] then
				local transactionId = parsedBody[TRASNSACTION_ID_STRING]
				if self._purchases[player.UserId] == nil then
					self._purchases[player.UserId] = {}
				end
				self._purchases[player.UserId][passId] = {
					billingCountry = countryCode,
					trxId = transactionId,
				}
				resolve(transactionId)
			else
				reject("Invalid response.")
			end
		end):catch(function(error)
			warn(error)
		end)
	end)
end

function PurchaseService:GetMySubscriptionInfo(player: Player)
	assert(
		self._cloudService,
		"Please initialize StyngrService using PurchaseService.SetConfiguration() before calling this method!"
	)

	return self._cloudService:Call(player, Endpoints.Subscription.Info):andThen(function(result)
		return Promise.new(function(resolve, reject)
			local body = HttpService:JSONDecode(result.Body)

			if
				body ~= nil
				and body["productType"]
				and body["remainingSecondsCount"]
				and body["remainingStreamCount"]
				and body["sdkUserId"]
				and body["subscriptionEndDate"]
				and body["subscriptionStartDate"]
			then
				resolve(body)
			else
				reject()
			end
		end)
	end)
end

function PurchaseService:ConfirmTransaction(
	player: Player,
	purchasedPassID: number,
	purchasedPassType: string
): Enum.ProductPurchaseDecision
	assert(
		self._cloudService,
		"Please initialize PurchaseService using PurchaseService.SetConfiguration() before calling this method!"
	)

	assert(purchasedPassType ~= nil, "purchasedPassType must be specified!")

	local body = self._purchases[player.UserId][purchasedPassID]
	body["appId"] = self._appId
	body["billingType"] = purchasedPassType
	body["payType"] = "VC"
	body["subscriptionId"] = purchasedPassID
	body["userIp"] = "0.0.0.0"

	return self._cloudService
		:Call(player, Endpoints.Subscription.ConfirmPayment, body)
		:andThen(function()
			self._cloudService:ClearStoreToken(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end)
		:catch(function(error)
			warn(error)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end)
end

function PurchaseService:CancelTransaction(player: Player, purchasedPassID: number): Enum.ProductPurchaseDecision
	assert(
		self._cloudService,
		"Please initialize PurchaseService using PurchaseService.SetConfiguration() before calling this method!"
	)

	local body = {
		applicationId = self._appId,
		transactionId = self._purchases[player.UserId][purchasedPassID]["trxId"],
	}

	return self._cloudService
		:Call(player, Endpoints.Subscription.CancelPendingPaymentTransaction, body)
		:andThen(function()
			self._cloudService:ClearStoreToken(player)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end)
		:catch(function(error)
			warn(error)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end)
end

function PurchaseService:_determinePurchaseType(passID: string)
	local function checkCategory(category)
		if category then
			for _, value in pairs(category) do
				for _, str in pairs(value) do
					if str == passID then
						return true
					end
				end
			end
		end
		return false
	end

	if checkCategory(PurchaseTypes.radioBundles) then
		return "BUNDLE"
	elseif checkCategory(PurchaseTypes.subscriptions) then
		return "STORE"
	else
		local errorMessage = "passID is in an invalid category!"
		error(errorMessage)
		return nil
	end
end

function PurchaseService:_determineBundleName(passID: string)
	if PurchaseTypes.radioBundles then
		for key, value in pairs(PurchaseTypes.radioBundles) do
			for _, str in pairs(value) do
				if str == passID then
					return key
				end
			end
		end
	end

	local errorMessage = "no bundle with passID!"
	error(errorMessage)
end

function PurchaseService._getPurchaseItems(availablePurchaseItems: table, configPurchaseItems: table): table
	local purchaseItems = {}

	for k, _ in availablePurchaseItems do
		local keys = CommonUtils.filterTableByKey(availablePurchaseItems[k], "name")
		purchaseItems[k] = CommonUtils.filterByTableKeys(configPurchaseItems[k], keys)
	end

	return purchaseItems
end

return PurchaseService
