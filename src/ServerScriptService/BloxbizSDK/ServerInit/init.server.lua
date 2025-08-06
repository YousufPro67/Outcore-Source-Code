local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloxbizConfig = game.ReplicatedStorage:FindFirstChild("BloxbizConfig")
local DataStoreService = game:GetService("DataStoreService")

if not BloxbizConfig then
	error([[[SuperBiz] Bloxbiz config file not found. 
You must have a Bloxbiz config file at the root of ReplicatedStorage.
https://www.notion.so/Bloxbiz-Developer-Docs-962006ae5c0f49a99e7cbbb46c60354e for more info")]])
end

local REMOTES_FOLDER = "BloxbizRemotes"

local ConfigReader = require(script.Parent.ConfigReader)
local AdFilter, BatchHttp, AnalyticsDataStoreQueue

local BillboardServer = script.Parent.BillboardServer
local PortalServer = require(script.Parent.PortalServer)
local ad3DServer = require(script.Parent.Ad3DServer)
local centralBillboardServer = require(BillboardServer)
local CreateDebugGui = require(script.Parent.CreateDebugGui)

local AdFolder = game.ServerScriptService.BloxbizSDK

local billboardAdUnits = ConfigReader:read("Ads")
local _3dAdUnits = ConfigReader:read("Ads3D")
local portalAdUnits = ConfigReader:read("AdsPortals")

local function replicateSDK()
	AdFolder:Clone().Parent = game.ReplicatedStorage
	AdFolder:Clone().Parent = game.StarterPlayer.StarterPlayerScripts
end

local function replicateDebugMode()
	local debugModeEnabled = ConfigReader:read("DebugMode") or ConfigReader:read("DebugModeVideoAd")
	if debugModeEnabled then
		local DebugGui = CreateDebugGui()
		DebugGui.Parent = game:GetService("StarterGui")
	end
end

local function initDependencies()
	AdFilter = require(script.Parent.AdFilter)

	BatchHttp = require(script.Parent.BatchHTTP)
	BatchHttp.init()

	AnalyticsDataStoreQueue = require(script.Parent.AnalyticsDataStoreQueue)
	AnalyticsDataStoreQueue:initializeQueue()

	BillboardServer = script.Parent.BillboardServer
	PortalServer = require(script.Parent.PortalServer)
	ad3DServer = require(script.Parent.Ad3DServer)
	centralBillboardServer = require(BillboardServer)
end

local function createGeneralRemotes()
	local bloxbizFolder = Instance.new("Folder", ReplicatedStorage)
	bloxbizFolder.Name = REMOTES_FOLDER

	local impressionEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local videoPlayedEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local userIdlingEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local newAdEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local newPlayerEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local adInteractionEvent = Instance.new("RemoteEvent", bloxbizFolder)
	--local adChatOpportunityEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local dialogueBranchEntryEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local update3DAdEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local preloadAdsEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local updatePortalEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local portalTeleportRequestEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local request3dAdEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local requestPortalAdEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local requestAudioAdEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local popUpShopEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local playerReceivedPromoCode = Instance.new("RemoteEvent", bloxbizFolder)
	local playerReceivedReward = Instance.new("RemoteEvent", bloxbizFolder)
	local catalogItemPromptEvent = Instance.new("RemoteEvent", bloxbizFolder)
	local popupShopItemPromptEvent = Instance.new("BindableEvent", bloxbizFolder)

	popupShopItemPromptEvent.Name = "popupShopItemPromptEvent"
	catalogItemPromptEvent.Name = "catalogItemPromptEvent"
	impressionEvent.Name = "ImpressionEvent"
	videoPlayedEvent.Name = "VideoPlayedEvent"
	userIdlingEvent.Name = "UserIdlingEvent"
	newAdEvent.Name = "NewAdEvent"
	newPlayerEvent.Name = "NewPlayerEvent"
	adInteractionEvent.Name = "AdInteractionEvent"
	--adChatOpportunityEvent.Name = "AdChatOpportunityEvent"
	dialogueBranchEntryEvent.Name = "DialogueBranchEntryEvent"
	update3DAdEvent.Name = "Update3DAdEvent"
	preloadAdsEvent.Name = "PreloadAdsEvent"
	updatePortalEvent.Name = "UpdatePortalEvent"
	portalTeleportRequestEvent.Name = "PortalTeleportRequestEvent"
	request3dAdEvent.Name = "Request3dAdEvent"
	requestPortalAdEvent.Name = "RequestPortalAdEvent"
	requestAudioAdEvent.Name = "RequestAudioAdEvent"
	popUpShopEvent.Name = "PopUpShopEvent"
	playerReceivedPromoCode.Name = "PlayerReceivedPromoCode"
	playerReceivedReward.Name = "PlayerReceivedReward"

	local getSubscriptionProductInfo = Instance.new("RemoteFunction", bloxbizFolder)
	local getSubsetClientPlayerStats = Instance.new("RemoteFunction", bloxbizFolder)
	local getAdStorage = Instance.new("RemoteFunction", bloxbizFolder)
	local getClientLogs = Instance.new("RemoteFunction", bloxbizFolder)
	local marketplaceServiceWrapper = Instance.new("RemoteFunction", bloxbizFolder)

	getSubscriptionProductInfo.Name = "getSubscriptionProductInfo"
	getSubsetClientPlayerStats.Name = "getSubsetClientPlayerStats"
	getAdStorage.Name = "getAdStorage"
	getClientLogs.Name = "getClientLogs"
	marketplaceServiceWrapper.Name = "marketplaceServiceWrapper"
end

local function initServerEvents()
	local sendServerConfigEvent = require(script.ServerConfigEvent)
	sendServerConfigEvent()

	local heartbeatEvent = require(script.HeartbeatEvent)
	heartbeatEvent.init()

	local newPlayerStatsCollector = require(script.Parent.AdRequestStats.Player)
	newPlayerStatsCollector.init()

	local userIdlingEvent = require(script.UserIdlingEvent)
	userIdlingEvent.init()

	local teleportsAndJoinsEvent = require(script.TeleportsAndJoinsEvent)
	teleportsAndJoinsEvent.init()

	local popUpShopEvents = require(script.PopUpShopEvents)
	popUpShopEvents.init()

	centralBillboardServer.CentralBillboardServer = centralBillboardServer

	task.spawn(function()
		AdFilter:connectToEvents()
		centralBillboardServer:connectToEvents()
		ad3DServer.connectToEvents()
		PortalServer.connectToEvents()
	end)

	return centralBillboardServer
end

local function initSalesMeasurement()
	if not ConfigReader:read("SalesMeasurement") then
		return
	end

	local monetizationTracker = require(script.Parent.TrackMonetization)
	monetizationTracker:init()
end

local function initCatalog()
	if not ConfigReader:read("CatalogEnabled") then
		return
	end

	task.spawn(function()
		local CatalogServer = require(script.Parent.CatalogServer)
		CatalogServer.Init()
	end)
end

local function initPopfeed()
	if not ConfigReader:read("PopfeedEnabled") then
		return
	end

	task.spawn(function()
		local PopfeedServer = require(script.Parent.PopfeedServer)
		PopfeedServer.init()
	end)
end

local function initAdModels()
	local assertConfigAdUnits = require(script.Parent.ConfigReader.AssertConfigAdUnits)
	if assertConfigAdUnits() then
		return
	end

	for _, ad in ipairs(billboardAdUnits) do
		centralBillboardServer:initInstance(ad, false)
	end

	for _, ad in ipairs(_3dAdUnits) do
		ad3DServer.new(ad)
	end

	for _, placeholderPortal in ipairs(portalAdUnits) do
		PortalServer.new(placeholderPortal)
	end
end

local function initMarketplaceServiceWrapper()
	if not ConfigReader:read("VariablePricing") then
		return
	end

	local MarketplaceServiceWrapper = require(ReplicatedStorage.BloxbizSDK.MarketplaceServiceWrapper)
	MarketplaceServiceWrapper:initServer()
end

local function initPromoCodes()
	if not ConfigReader:read("PromoCodesEnabled") then
		return
	end

	task.spawn(function() 
		local promoCodes = require(script.Parent.PromoCodes.Server)
		promoCodes.init()
		promoCodes.getCampaignId()  -- show warning in output if no campaign ID set
	end)
end

local function initRewards()
	task.spawn(function() 
		local rewards = require(script.Parent.Rewards.Server)
		rewards.init()
	end)
end

local function initGuiTracking()
	task.spawn(function()
		local GuiTrackingServer = require(script.Parent.GuiTrackingServer)
		GuiTrackingServer.init()
	end)
end

local function checkApiKey()
	task.spawn(function()
		-- check API key
		local success, checkKeyResp = BatchHttp.request("POST", "/check-key", {
			game_id = game.GameId,
			account_id = ConfigReader:read("AccountID")
		}, true)
	
		if not success then
			warn("BloxbizConfig Error - " .. checkKeyResp.message)
		end
	end)
end

local function createStyngrEvents()
	local SongEvents = Instance.new("RemoteEvent")
	SongEvents.Name = "SongEvents"
	SongEvents.Parent = ReplicatedStorage.Styngr

	local TokenReceivedEvent = Instance.new("RemoteEvent")
	TokenReceivedEvent.Name = "TokenReceivedEvent"
	TokenReceivedEvent.Parent = ReplicatedStorage.Styngr

	local TokenLostEvent = Instance.new("RemoteEvent")
	TokenLostEvent.Name = "TokenLostEvent"
	TokenLostEvent.Parent = ReplicatedStorage.Styngr

	local FocusChangedEvent = Instance.new("RemoteEvent")
	FocusChangedEvent.Name = "FocusChangedEvent"
	FocusChangedEvent.Parent = ReplicatedStorage.Styngr

	local PurchaseEvent = Instance.new("RemoteEvent")
	PurchaseEvent.Name = "PurchaseEvent"
	PurchaseEvent.Parent = ReplicatedStorage.Styngr

	local ListenToGroupSessionEvent = Instance.new("RemoteEvent")
	ListenToGroupSessionEvent.Name = "ListenToGroupSessionEvent"
	ListenToGroupSessionEvent.Parent = ReplicatedStorage.Styngr

	local RemoveGroupSessionEvent = Instance.new("RemoteEvent")
	RemoveGroupSessionEvent.Name = "RemoveGroupSessionEvent"
	RemoveGroupSessionEvent.Parent = ReplicatedStorage.Styngr

	local GroupSessionSongEvent = Instance.new("RemoteEvent")
	GroupSessionSongEvent.Name = "GroupSessionSongEvent"
	GroupSessionSongEvent.Parent = ReplicatedStorage.Styngr

	local GroupSessionSetNewSongEvent = Instance.new("RemoteEvent")
	GroupSessionSetNewSongEvent.Name = "GroupSessionSetNewSongEvent"
	GroupSessionSetNewSongEvent.Parent = ReplicatedStorage.Styngr

	local GetPlaylists = Instance.new("RemoteFunction")
	GetPlaylists.Name = "GetPlaylists"
	GetPlaylists.Parent = ReplicatedStorage.Styngr

	local StartPlaylistSession = Instance.new("RemoteFunction")
	StartPlaylistSession.Name = "StartPlaylistSession"
	StartPlaylistSession.Parent = ReplicatedStorage.Styngr

	local RequestNextTrack = Instance.new("RemoteFunction")
	RequestNextTrack.Name = "RequestNextTrack"
	RequestNextTrack.Parent = ReplicatedStorage.Styngr

	local SkipTrack = Instance.new("RemoteFunction")
	SkipTrack.Name = "SkipTrack"
	SkipTrack.Parent = ReplicatedStorage.Styngr

	local Purchase = Instance.new("RemoteFunction")
	Purchase.Name = "Purchase"
	Purchase.Parent = ReplicatedStorage.Styngr

	local SubscriptionInfo = Instance.new("RemoteFunction")
	SubscriptionInfo.Name = "SubscriptionInfo"
	SubscriptionInfo.Parent = ReplicatedStorage.Styngr

	local GetPurchaseItems = Instance.new("RemoteFunction")
	GetPurchaseItems.Name = "GetPurchaseItems"
	GetPurchaseItems.Parent = ReplicatedStorage.Styngr

	local ContinuePlaylistSession = Instance.new("RemoteFunction")
	ContinuePlaylistSession.Name = "ContinuePlaylistSession"
	ContinuePlaylistSession.Parent = ReplicatedStorage.Styngr

	local AutoStartPlaylistSession = Instance.new("RemoteFunction")
	AutoStartPlaylistSession.Name = "AutoStartPlaylistSession"
	AutoStartPlaylistSession.Parent = ReplicatedStorage.Styngr

	local UnavailableTrack = Instance.new("RemoteFunction")
	UnavailableTrack.Name = "UnavailableTrack"
	UnavailableTrack.Parent = ReplicatedStorage.Styngr

	local AudioPlaybackEvent = Instance.new("BindableEvent")
	AudioPlaybackEvent.Name = "AudioPlaybackEvent"
	AudioPlaybackEvent.Parent = game.StarterPlayer.StarterPlayerScripts.Styngr
end

local function initStyngr()
	task.spawn(function()
		if not ConfigReader:read("StyngrEnabled") then
			return
		end

		local styngrFolder = script.Parent.Styngr

		local replicated = styngrFolder.ReplicatedStorage
		replicated.Name = "Styngr"
		replicated.Parent = ReplicatedStorage

		local server = styngrFolder.ServerScriptService
		server.Name = "Styngr"
		server.Parent = game.ServerScriptService

		local starterPlayer = styngrFolder.StarterPlayer.StarterPlayerScripts
		starterPlayer.Name = "Styngr"
		starterPlayer.Parent = game.StarterPlayer.StarterPlayerScripts

		createStyngrEvents()

		local StyngrServer = require(script.Parent.StyngrServer)
		StyngrServer.Init()
	end)
end

local function initCommandTool()
	task.spawn(function()
		local CommandTool = require(script.Parent.CommandTool.Server)

		local isEnabled = ConfigReader:read("SBCommandsEnabled")
		if not isEnabled then
			return
		end

		CommandTool.Init()
	end)
end

replicateSDK()
replicateDebugMode()
initDependencies()
createGeneralRemotes()
initServerEvents()
initSalesMeasurement()
initCatalog()
initMarketplaceServiceWrapper()
initAdModels()
initPopfeed()
initPromoCodes()
initRewards()
initGuiTracking()
checkApiKey()
initStyngr()
initCommandTool()
