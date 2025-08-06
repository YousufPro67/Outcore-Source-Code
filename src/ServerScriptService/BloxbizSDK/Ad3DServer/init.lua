local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local REMOTES_FOLDER = "BloxbizRemotes"
local AD_ASSETS_FOLDER = "Bloxbiz3DAdAssets"
--local TIME_BETWEEN_3D_ADS = 3

local module = {}
module.Ad3DServerInstances = {}
module.hasInventorySizing = false
module.__index = module

local Utils = require(script.Parent.Utils)
local merge = Utils.merge
local ConfigReader = require(script.Parent.ConfigReader)
local BatchHTTP = require(script.Parent.BatchHTTP)
local AnalyticsDataStoreQueue = require(script.Parent.AnalyticsDataStoreQueue)
local PlayerAnalyticsHistory = require(script.Parent.AnalyticsDataStoreQueue.PlayerAnalyticsHistory)
local AdRequestStats = require(script.Parent.AdRequestStats)
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local LoadAd = require(script.LoadAd)
local adAssetsFolder = ReplicatedStorage:FindFirstChild(AD_ASSETS_FOLDER)

if not adAssetsFolder then
	adAssetsFolder = Instance.new("Folder")
	adAssetsFolder.Parent = ReplicatedStorage
	adAssetsFolder.Name = AD_ASSETS_FOLDER
end

local function queueBranchEntryHttp(player, branchEntry)
	local event = { event_type = "branch_entry", data = branchEntry }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueBranchEntryDataStore(player, branchEntry)
	local bloxbizAdId = branchEntry.bloxbiz_ad_id
	AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "chatting_time", branchEntry.response_time)

	local isFirstEverBranch = branchEntry.previous_branch == ""
	local isResponse = not isFirstEverBranch
	if isFirstEverBranch then
		AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "chats", 1)

		local analyticsHistory = PlayerAnalyticsHistory:getPlayerHistory(player.UserId)
		if not analyticsHistory["3dAdUniqueChats"][tostring(bloxbizAdId)] then
			analyticsHistory["3dAdUniqueChats"][tostring(bloxbizAdId)] = true
			AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "unique_chats", 1)
		end
	end
	if isResponse then
		AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "responses", 1)

		local analyticsHistory = PlayerAnalyticsHistory:getPlayerHistory(player.UserId)
		if not analyticsHistory["3dAdUniqueResponse"][tostring(bloxbizAdId)] then
			analyticsHistory["3dAdUniqueResponse"][tostring(bloxbizAdId)] = true
			AnalyticsDataStoreQueue:queueChange(bloxbizAdId, "unique_responses", 1)
		end
	end
end

local function dialogueBranchEntryFired(player, branchEntered, clientPlayerStats, partStats)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local branchEntry = merge(merge(merge(merge(branchEntered, partStats), gameStats), playerStats), clientPlayerStats)

	local ad = Utils.getAdUsingBloxbizAdId(branchEntry.bloxbiz_ad_id)
	if ad and ad.analytics_protocol == "datastore" then
		queueBranchEntryDataStore(player, branchEntry)
	else
		queueBranchEntryHttp(player, branchEntry)
	end

	Utils.pprint("[SuperBiz] Queue branch entry.")
end

function module:getAdsStats(playerStats)
	local partStats = {
		["part_name"] = self.adBoxModel.AdBox:GetFullName(),
		["part_shape"] = tostring(self.adBoxModel.AdBox.Shape),
		["part_color"] = tostring(self.adBoxModel.AdBox.Color),
		["part_orientation"] = tostring(self.adBoxModel.AdBox.Orientation),
		["part_position"] = tostring(self.adBoxModel.AdBox.Position),
		["part_size"] = tostring(self.adBoxModel.AdBox.Size),
		["part_size_x"] = self.adBoxModel.AdBox.Size.X,
		["part_size_y"] = self.adBoxModel.AdBox.Size.Y,
		["part_size_z"] = self.adBoxModel.AdBox.Size.Z,
	}

	local gameStats = AdRequestStats:getGameStats()
	local lightingStats = AdRequestStats:getGameLightingStats()

	local stats = merge(merge(gameStats, partStats), lightingStats)
	stats["blocklist"] = ConfigReader:read("AdBlocklistURL")
	stats["players"] = playerStats
	stats["3d_ad_request"] = true

	return stats
end

function module:getAds(stats)
	local AdFilter = require(script.Parent.AdFilter)
	local adUrlPerPlayer
	if self.hardcodedAd then
		adUrlPerPlayer = AdFilter:GetAds(stats, {self.hardcodedAd})
	else
		adUrlPerPlayer = AdFilter:GetAds(stats)
	end

	return adUrlPerPlayer
end

local adModelDefaults = {
	["ad_rotate_disabled"] = false,
	["ad_dialogue_disabled"] = false,
	["prompt_action_text"] = "Talk",
	["ad_disclaimer_text"] = "Paid Ad",

	["show_question_mark_in_model"] = true,
	["show_ad_disclaimer_in_model"] = true,
	["show_ad_disclaimer_in_dialogue"] = true,

	["camera_lock_enabled"] = true,
	["camera_distance"] = 12.5,
	["camera_height"] = 4,

	["ad_exclusive_animations"] = {},
}

function module:fillAdModelDefaults(adData)
	for _, modelData in pairs(adData.ad_model_data) do
		for defaultKey, defaultVal in pairs(adModelDefaults) do
			if modelData[defaultKey] == nil then
				modelData[defaultKey] = defaultVal
			end
		end
	end
end

function module:isCustomAnimationsValid(adData)
	for _, modelData in ipairs(adData.ad_model_data) do
		if not modelData.ad_exclusive_animations then
			continue
		end

		for _, animationName in ipairs(modelData.ad_exclusive_animations) do
			if not script.Character:FindFirstChild(animationName) then
				return false
			end
		end
	end

	return true
end

function module:formatAdData(adData)
	adData.bloxbiz_ad_id = tonumber(adData.bloxbiz_ad_id)

	local params = {}
	params.adValid = true
	params.animationsValid = true
	params.idValid = (adData.bloxbiz_ad_id ~= -1)
	params.scaleModel = true
	params.debugMode = ConfigReader:read("DebugModeCharacterAd")

	if params.idValid then
		params.animationsValid = self:isCustomAnimationsValid(adData)
	end

	if params.debugMode or not params.animationsValid or not params.idValid then
		params.adValid = false
		adData.ad_type = adData.ad_type or "Character"
		adData.bloxbiz_ad_id = -1
		adData.ad_serialized_model = require(script.Parent.Ad3DClient.CharacterAd.Character.DefaultEmpty)

		adData.ad_box_width_max = 6
		adData.ad_box_height_max = 6
		adData.ad_box_depth_max = 6

		adData.ad_model_data = {}

		if params.debugMode then
			adData.ad_serialized_model = require(script.Parent.Ad3DClient.CharacterAd.Character.DefaultCharacter)

			adData.ad_model_data[1] = {}
			adData.ad_model_data[1].ad_model_name = "BloxbizTeamMember"
			adData.ad_model_data[1].ad_character_name = "Bloxbiz Team Member"
			adData.ad_model_data[1].ad_dialogue_tree =
				require(script.Parent.Ad3DClient.CharacterAd.Character.DefaultBranchData)
		end
	end

	self:fillAdModelDefaults(adData)

	return adData, params
end

function module:getAdPerPlayer(singlePlayer, clientPlayerStats)
	local playerStats
	if not singlePlayer then
		playerStats = AdRequestStats:getAllPlayerStatsWithClientStats()
	elseif singlePlayer then
		if not clientPlayerStats then
			clientPlayerStats = AdRequestStats:getClientPlayerStats(singlePlayer)
		end

		playerStats = merge(clientPlayerStats, AdRequestStats:getPlayerStats(singlePlayer))
		playerStats = { playerStats }
	end

	local stats = self:getAdsStats(playerStats)
	local result = self:getAds(stats)

	return result
end

function module:requestInitAdBoxToPlayer(player, adPerPlayer)
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	if not adPerPlayer then
		adPerPlayer = self:getAdPerPlayer(player)
	end

	for playerId, ad in pairs(adPerPlayer) do
		local recipient = Players:GetPlayerByUserId(playerId)
		local formattedAd = self:formatAdData(ad)
		local adLoadSuccess = LoadAd(self, formattedAd)

		if recipient and adLoadSuccess then
			remotesFolder.Update3DAdEvent:FireClient(recipient, "Construct", self.adBoxName, formattedAd)
		end
	end
end

function module:requestInitAdBoxAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		self:requestInitAdBoxToPlayer(player)
	end
end

--[[
function module:StartAdCycle()
	while true do
		self:updateAd()
		task.wait(TIME_BETWEEN_3D_ADS)
	end
end
]]

local function duplicateInstanceCheck(adBox)
	for _, ad3DServerInstance in pairs(module.Ad3DServerInstances) do
		if ad3DServerInstance.adBoxName == adBox:GetFullName() then
			return true
		end
	end

	return false
end

function module.new(adBox, dynamicallyLoaded, hardcodedAd)
	if duplicateInstanceCheck(adBox) then
		Utils.pprint("[SuperBiz] Duplicate 3D ad box initialization attempt")
		return
	end

	local ad3DServerInstance = setmetatable({}, module)
	table.insert(module.Ad3DServerInstances, ad3DServerInstance)

	if hardcodedAd and hardcodedAd.ad_type == "BoxInventorySizing" then
		module.hasInventorySizing = true
	end

	local adBoxModel = adBox.Parent

	adBoxModel.AdBox.Transparency = 1
	adBoxModel.AdBox.Material = Enum.Material.Plastic
	adBoxModel.AdBox:ClearAllChildren()

	if adBoxModel:FindFirstChild("Cosmetic") then
		adBoxModel.Cosmetic:Destroy()
	end

	ad3DServerInstance.adBoxModel = adBoxModel
	ad3DServerInstance.adBoxName = adBox:GetFullName()
	ad3DServerInstance.hardcodedAd = hardcodedAd

	module.destroyAdBoxInstanceOnAdBoxRemoval(ad3DServerInstance)

	if dynamicallyLoaded then
		ad3DServerInstance:requestInitAdBoxAllPlayers()
	end

	--ad3DServerInstance:StartAdCycle()

	return ad3DServerInstance
end

function module.destroyAdBoxInstanceOnAdBoxRemoval(ad3DServerInstance)
	local adBoxModel = ad3DServerInstance.adBoxModel
	local adBoxName = ad3DServerInstance.adBoxName

	adBoxModel.ChildRemoved:Connect(function(child)
		if child.Name ~= "AdBox" then
			return
		end

		for _, player in pairs(Players:GetPlayers()) do
			local Update3DAdEvent = ReplicatedStorage:WaitForChild(REMOTES_FOLDER).Update3DAdEvent
			Update3DAdEvent:FireClient(player, "Destruct", ad3DServerInstance.adBoxName)
		end

		for index, indexedInstance in pairs(module.Ad3DServerInstances) do
			if indexedInstance.adBoxName == adBoxName then
				table.remove(module.Ad3DServerInstances, index)
				break
			end
		end
	end)
end

function module.request3dAdFired(player, ad)
	ad["ad_type"] = "Character"
	ad["ad_disclaimer_text"] = "Paid Ad"
	ad["external_link_references"] = ad["external_link_references"] or {}

	for _, ad3DServerInstance in pairs(module.Ad3DServerInstances) do
		ReplicatedStorage:WaitForChild(REMOTES_FOLDER).Update3DAdEvent
			:FireClient(player, "Destruct", ad3DServerInstance.adBoxName)

		ad3DServerInstance:requestInitAdBoxToPlayer(player, { [player.UserId] = ad })
	end
end

function module.newPlayerFired(player, clientPlayerStats)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	for _, ad3DServerInstance in pairs(module.Ad3DServerInstances) do
		local adPerPlayer = ad3DServerInstance:getAdPerPlayer(player, clientPlayerStats)
		ad3DServerInstance:requestInitAdBoxToPlayer(player, adPerPlayer)
	end
end

function module.connectToEvents()
	local bloxbizFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER)

	bloxbizFolder.NewPlayerEvent.OnServerEvent:connect(module.newPlayerFired)
	bloxbizFolder.DialogueBranchEntryEvent.OnServerEvent:Connect(dialogueBranchEntryFired)
	bloxbizFolder.Request3dAdEvent.OnServerEvent:Connect(module.request3dAdFired)
end

return module
