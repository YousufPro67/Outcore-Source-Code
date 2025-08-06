local Players = game:GetService('Players')
local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local AdRequestStats = require(script.Parent.AdRequestStats)
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local TeleportsAndJoinsEventModule = require(script.Parent.ServerInit.TeleportsAndJoinsEvent)
local ConfigReader = require(script.Parent.ConfigReader)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge

local REMOTES_FOLDER = "BloxbizRemotes"
local DISCONTINUE_PORTALS_TIME_LIMIT = 10
local NUM_LATEST_LOGS_TO_REQUEST = 10
local MIN_PORTAL_SIZE = Vector3.new(24, 12.5, 7)

local PortalServer = {}
PortalServer.Instances = {}
PortalServer.gameHasMissingTeleportPermissions = false
PortalServer.__index = PortalServer

function PortalServer:getAdsStats(playerStats)
	local partStats = {
		["part_name"] = self.portalBox.AdBox:GetFullName(),
		["part_shape"] = tostring(self.portalBox.AdBox.Shape),
		["part_color"] = tostring(self.portalBox.AdBox.Color),
		["part_orientation"] = tostring(self.portalBox.AdBox.Orientation),
		["part_position"] = tostring(self.portalBox.AdBox.Position),
		["part_size"] = tostring(self.portalBox.AdBox.Size),
		["part_size_x"] = self.portalBox.AdBox.Size.X,
		["part_size_y"] = self.portalBox.AdBox.Size.Y,
		["part_size_z"] = self.portalBox.AdBox.Size.Z,
	}

	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()

	local stats = merge(merge(gameStats, partStats), lightingStats)
	stats["blocklist"] = ConfigReader:read("AdBlocklistURL")
	stats["players"] = playerStats
	stats["portal_ad_request"] = true

	return stats
end

function PortalServer:getAds(stats)
	local AdFilter = require(script.Parent.AdFilter)
	local adUrlPerPlayer = AdFilter:GetAds(stats)

	return adUrlPerPlayer
end

function PortalServer:sizeCheck()
	local adBox = self.portalBox:FindFirstChild('AdBox')

	if not adBox then
		Utils.pprint("[SuperBiz] Portal AdBox didn't exist while doing size check")
	end

	if adBox.Size.X >= MIN_PORTAL_SIZE.X and adBox.Size.Y >= MIN_PORTAL_SIZE.Y and adBox.Size.Z >= MIN_PORTAL_SIZE.Z then
		return true
	else
		Utils.pprint("[SuperBiz] Portal AdBox size was smaller than expected, please reset it to original size")
	end

	return false
end

function PortalServer:formatAdData(adData)
	adData.bloxbiz_ad_id = tonumber(adData.bloxbiz_ad_id)

	local idValid = (adData.bloxbiz_ad_id ~= -1)
	local debugMode = ConfigReader:read("DebugModePortalAd")

	if adData["ad_url"] and adData["ad_url"][1] == "" then
		adData["show_ad_disclaimer"] = true
	else
		adData["show_ad_disclaimer"] = false
	end

	if not adData["ad_disclaimer_url"] then
		adData["ad_disclaimer_url"] = "rbxassetid://7122215099"
		adData["ad_disclaimer_scale_x"] = 0.117
		adData["ad_disclaimer_scale_y"] = 0.08
	end

	if debugMode or not idValid then
		adData.bloxbiz_ad_id = -1

		local showDebugPortal = debugMode and self:sizeCheck()
		if showDebugPortal then
            adData.destination_place_id = 10395329385
            adData.ad_url = {"http://www.roblox.com/asset/?id=11315687547"}
			adData.show_ad_disclaimer = true
            adData.ad_disclaimer_url = "http://www.roblox.com/asset/?id=11315697627"
            adData.ad_disclaimer_scale_x = 0.133
            adData.ad_disclaimer_scale_y = 0.08
		end
	end

	return adData
end

function PortalServer:getAdPerPlayer(singlePlayer, clientPlayerStats)
	local playerStats

	if not singlePlayer then
		playerStats = AdRequestStats:getAllPlayerStatsWithClientStats()
	elseif singlePlayer then
		if not clientPlayerStats then
			clientPlayerStats = AdRequestStats:getClientPlayerStats(singlePlayer)
		end

		playerStats = merge(clientPlayerStats, AdRequestStats:getPlayerStats(singlePlayer))
		playerStats = {playerStats}
	end

	local stats = self:getAdsStats(playerStats)
	local result = self:getAds(stats)

	return result
end

function PortalServer:requestInitAdBoxToPlayer(player, adPerPlayer)
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	if not adPerPlayer then
		adPerPlayer = self:getAdPerPlayer(player)
	end

	for playerId, ad in pairs(adPerPlayer) do
		local recipient = Players:GetPlayerByUserId(playerId)
		local formattedAd = self:formatAdData(ad)

		if recipient then
			remotesFolder.UpdatePortalEvent:FireClient(recipient, "Construct", self.adBoxName, formattedAd)
		end
	end
end

function PortalServer:requestInitAdBoxAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		self:requestInitAdBoxToPlayer(player)
	end
end

function PortalServer:destruct()
	self.portalBox:Destroy()
end

local function removePlaceholderPortalFromBox(portalBox)
    for _, child in pairs(portalBox:GetChildren()) do
        if child.Name == 'AdBox' then
            child.Transparency = 1
            child.Material = Enum.Material.Plastic
            child:ClearAllChildren()

            continue
        end

        child:Destroy()
    end
end

local function duplicateInstanceCheck(adBox)
	for _, portalServerInstance in pairs(PortalServer.Instances) do
		if portalServerInstance.adBoxName == adBox:GetFullName() then
			return true
		end
	end

	return false
end

function PortalServer.new(adBox, dynamicallyLoaded)
	if duplicateInstanceCheck(adBox) then
		Utils.pprint("[SuperBiz] Duplicate portal box initialization attempt")
		return
	end

	if PortalServer.gameHasMissingTeleportPermissions then
		return
	end

	local portalServerInstance = setmetatable({}, PortalServer)
	table.insert(PortalServer.Instances, portalServerInstance)

    local portalBox = adBox.Parent
    removePlaceholderPortalFromBox(portalBox)

	portalServerInstance.portalBox = portalBox
	portalServerInstance.adBoxName = adBox:GetFullName()

	portalBox.ChildRemoved:Connect(function(child)
		if child == adBox then
			for _, player in pairs(Players:GetPlayers()) do
				ReplicatedStorage:WaitForChild(REMOTES_FOLDER).UpdatePortalEvent
					:FireClient(player, "Destruct", portalServerInstance.adBoxName)
			end
		end
	end)

	if dynamicallyLoaded then
		portalServerInstance:requestInitAdBoxAllPlayers()
	end
end

function PortalServer.requestPortalAdFired(player, ad)
	ad["external_link_references"] = ad["external_link_references"] or {}

	for _, portalServerInstance in pairs(PortalServer.Instances) do
		ReplicatedStorage:WaitForChild(REMOTES_FOLDER).UpdatePortalEvent
			:FireClient(player, "Destruct", portalServerInstance.adBoxName)

		portalServerInstance:requestInitAdBoxToPlayer(player, {[player.UserId] = ad})
	end
end

function PortalServer.newPlayerFired(player, clientPlayerStats)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	for _, portalServerInstance in pairs(PortalServer.Instances) do
		local adPerPlayer = portalServerInstance:getAdPerPlayer(player, clientPlayerStats)
		portalServerInstance:requestInitAdBoxToPlayer(player, adPerPlayer)
	end
end

function PortalServer.discontinueAllPortals()
	PortalServer.gameHasMissingTeleportPermissions = true

	for _, portalServerInstance in pairs(PortalServer.Instances) do
		portalServerInstance:destruct()
	end
end

function PortalServer.checkTeleportPermissions(playerName)
	local player = Players:FindFirstChild(playerName)
	local playerDoesntExist = (not player) or (player and player.Parent ~= Players)
	if playerDoesntExist then
		return
	end

	local pingSuccess, clientOutput = pcall(function()
		local bloxbizFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER)
		return bloxbizFolder.getClientLogs:InvokeClient(player, NUM_LATEST_LOGS_TO_REQUEST)
	end)

	if not pingSuccess then
		return
	end

	local invalidPermissions = false

	for _, output in pairs(clientOutput) do
		local message = output.message
		local failureIndicator1 = "raiseTeleportInitFailedEvent"
		local failureIndicator2 = "third party with teleport protections"


		if string.find(message, failureIndicator1) and string.find(message, failureIndicator2) then
			invalidPermissions = true
			break
		end
	end

	if invalidPermissions then
		PortalServer.discontinueAllPortals()
	end
end

local function teleportRequestEventFired(player, destinationId, billboardAdId)
	local teleportGuid = HttpService:GenerateGUID(false)

	TeleportsAndJoinsEventModule:setTeleported(player)

	task.spawn(function()
		TeleportsAndJoinsEventModule:trackGameTeleport(player, destinationId, billboardAdId, teleportGuid)
	end)

	local teleportOptions = Instance.new('TeleportOptions')
	local teleportData = {}
	teleportData.isBloxbizTeleport = true
	teleportData.teleportGuid = teleportGuid
	teleportData.bloxbizAdId = billboardAdId

	teleportOptions:SetTeleportData(teleportData)
	TeleportService:TeleportAsync(destinationId, {player}, teleportOptions)

	local playerName = player.Name

	task.delay(DISCONTINUE_PORTALS_TIME_LIMIT, function()
		PortalServer.checkTeleportPermissions(playerName)
	end)
end

function PortalServer.connectToEvents()
	local bloxbizFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER)

	bloxbizFolder.NewPlayerEvent.OnServerEvent:connect(PortalServer.newPlayerFired)
    bloxbizFolder.PortalTeleportRequestEvent.OnServerEvent:Connect(teleportRequestEventFired)
	bloxbizFolder.RequestPortalAdEvent.OnServerEvent:Connect(PortalServer.requestPortalAdFired)
end

return PortalServer