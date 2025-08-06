local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local BillboardClientModule = script.Parent.BillboardClient
local billboardClient = require(BillboardClientModule)
local ad3DClient = require(script.Parent.Ad3DClient)
local portalClient = require(script.Parent.PortalClient)
local ConfigReader = require(script.Parent.ConfigReader)
local AdRequestStats = require(script.Parent.AdRequestStats)

local REMOTES_FOLDER = "BloxbizRemotes"

local remotesFolder = game.ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
local newAdEvent = remotesFolder:WaitForChild("NewAdEvent")
local update3DAdEvent = remotesFolder:WaitForChild("Update3DAdEvent")
local updatePortalEvent = remotesFolder:WaitForChild("UpdatePortalEvent")
local preloadAdsEvent = remotesFolder:WaitForChild("PreloadAdsEvent")
local getSubscriptionProductInfoRemote = remotesFolder:WaitForChild("getSubscriptionProductInfo")
local getSubsetClientPlayerStatsRemote = remotesFolder:WaitForChild("getSubsetClientPlayerStats")
local getClientLogsRemote = remotesFolder:WaitForChild("getClientLogs")

local billboardAdUnits = ConfigReader:read("Ads")

local LocalPlayer = Players.LocalPlayer

local function initClientInstance(ad)
	task.spawn(function()
		local newBillboardClientModule = BillboardClientModule:Clone()
		newBillboardClientModule.Parent = script.Parent

		local newBillboardClient = require(newBillboardClientModule)
		newBillboardClient:initAd(ad)
	end)
end

local function clientLogsRequested(amount)
	local requestedLogs = {}

	local clientLogs = game:GetService('LogService'):GetLogHistory()
	local numClientLogs = #clientLogs

	for i = amount, 1, -1 do
		local logToSend = clientLogs[numClientLogs - i + 1]
		table.insert(requestedLogs, logToSend)
	end

	return requestedLogs
end

local function initClientEvents()
	newAdEvent.OnClientEvent:Connect(initClientInstance)
	getClientLogsRemote.OnClientInvoke = clientLogsRequested

	game.Players.LocalPlayer.Idled:Connect(function(time)
		billboardClient:sendUserIdling(time)
	end)

	preloadAdsEvent.OnClientEvent:Connect(function(listToPreload)
		billboardClient:preloadList(listToPreload)
	end)

	getSubscriptionProductInfoRemote.OnClientInvoke = function(subscriptionId)
		local success, respose = pcall(function()
			return MarketplaceService:GetSubscriptionProductInfoAsync(subscriptionId)
		end)

		return success, respose
	end

	getSubsetClientPlayerStatsRemote.OnClientInvoke = function()
		return AdRequestStats:getSubsetClientPlayerStats()
	end

	update3DAdEvent.OnClientEvent:Connect(function(action, adBoxName, adToLoad)
		if action == "Construct" then
			ad3DClient.init(adBoxName, adToLoad)
		end
	end)

	updatePortalEvent.OnClientEvent:Connect(function(action, adBoxName, adToLoad)
		if action == "Construct" then
			portalClient.init(adBoxName, adToLoad)
		end
	end)
end

local function initAdModels()
	local assertConfigAdUnits = require(script.Parent.ConfigReader.AssertConfigAdUnits)
	if assertConfigAdUnits() then
		return
	end

	for _, ad in ipairs(billboardAdUnits) do
		if type(ad) == "table" then
			ad = ad["partInstance"]
		end

		initClientInstance(ad:GetFullName())
	end

	billboardClient:sendNewPlayer()
end

local function initSalesMeasurement()
	if ConfigReader:read("SalesMeasurement") then
		require(script.Parent.TrackMonetization.TrackMonetizationClient)
	end
end

local function initCatalog()
	if ConfigReader:read("CatalogEnabled") then
		local CatalogClient = require(script.Parent.CatalogClient)
		CatalogClient.Init()
	end
end

local function initScreenshotTool()
	local ScreenshotTool = require(script.Parent.ScreenshotTool)
	ScreenshotTool.init()
end

local function initPopfeed()
	if not ConfigReader:read("PopfeedEnabled") then
		return
	end

	local PopfeedClient = require(script.Parent.PopfeedClient)
	PopfeedClient.init()
end

local function initGuiTracking()
	local GuiTrackingClient = require(script.Parent.GuiTrackingClient)
	GuiTrackingClient.init()
end

local function initStyngr()
	if not ConfigReader:read("StyngrEnabled") then
		return
	end

	local StyngrClient = require(script.Parent.StyngrClient)
	StyngrClient.Init()
end
  
local function initRewards()
	local RewardsClient = require(script.Parent.Rewards.Client)
	RewardsClient.init()
end

local function checkForOldTopbarPlus()
	local isPopfeedEnabled = ConfigReader:read("PopfeedEnabled")
	local isPopmallEnabled = ConfigReader:read("CatalogEnabled")

	if not isPopfeedEnabled and not isPopmallEnabled then
		return
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TopbarPlus" then
			warn("[Super Biz]: Your game might be using an outdated version of TopbarPlus!\nPlease update it to the latest version at https://docs.superbiz.gg/topbarplus")
		end
	end)

	local foundOldTopbarPlus = playerGui:FindFirstChild("TopbarPlus")
	if foundOldTopbarPlus then
		warn("[Super Biz]: Your game might be using an outdated version of TopbarPlus!\nPlease update it to the latest version at https://docs.superbiz.gg/topbarplus")
	end
end

local function initHeadphones()
	local isMusicPlayerEnabled = ConfigReader:read("MusicPlayerEnabled")
	if not isMusicPlayerEnabled then
		return
	end

	local Headphones = require(script.Parent.Headphones.Client)
	Headphones.Init()
end

local function initCommandTool()
	local isEnabled = ConfigReader:read("SBCommandsEnabled")
	if not isEnabled then
		return
	end

	local CommandTool = require(script.Parent.CommandTool.Client)
	CommandTool.Init()
end

initClientEvents()
initAdModels()
task.spawn(initSalesMeasurement)
task.spawn(initCatalog)
task.spawn(initScreenshotTool)
task.spawn(initPopfeed)
task.spawn(initGuiTracking)
task.spawn(initStyngr)
task.spawn(initRewards)
task.spawn(checkForOldTopbarPlus)
task.spawn(initHeadphones)
task.spawn(initCommandTool)
