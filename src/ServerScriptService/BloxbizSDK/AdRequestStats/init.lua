local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalizationService = game:GetService("LocalizationService")
local PolicyService = game:GetService("PolicyService")
local Workspace = game:GetService("Workspace")

local PlayerStatsModule = require(script.Player)
local HashLib = require(script.Parent.HashLib)
local InternalConfig = require(script.Parent.InternalConfig)
local ConfigReader = require(script.Parent.ConfigReader)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge

local REMOTES_FOLDER = "BloxbizRemotes"
local CLIENT_RESPONSE_WAIT = 10
local WAIT_FOR_CAMERA_MAX_TIME = 2

local AdRequestStats = {}

function AdRequestStats:raycastIgnoreListString()
	local raycastIgnoreList = ""
	for _, instance in ipairs(ConfigReader:read("RaycastFilterList")()) do
		raycastIgnoreList = raycastIgnoreList .. instance:GetFullName() .. ","
	end

	return raycastIgnoreList:sub(1, -2)
end

function AdRequestStats:getGameLightingStats()
	return {
		["lighting_ambient"] = Lighting.Ambient,
		["lighting_outdoor_ambient"] = Lighting.OutdoorAmbient,
		["lighting_brightness"] = Lighting.Brightness,
		["lighting_clocktime"] = Lighting.ClockTime,
		["lighting_fogstart"] = Lighting.FogStart,
		["lighting_fogend"] = Lighting.FogEnd,
	}
end

function AdRequestStats:getGameStats()
	return {
		["bloxbiz_version"] = InternalConfig.SDK_VERSION,
		["bloxbiz_id"] = ConfigReader:read("AccountID"),
		["raycast_ignore_list"] = HashLib.md5(self:raycastIgnoreListString()),
		["game_id"] = game.GameId,
		["creator_id"] = game.CreatorId,
		["place_id"] = game.PlaceId,
		["job_id"] = game.JobId,
		["private_server_id"] = game.PrivateServerId,
		["is_studio"] = RunService:IsStudio(),
	}
end

function AdRequestStats:getSurfaceGuiStats(part)
	local surfaceGui = part.AdSurfaceGui
	return {
		["surface_gui_enabled"] = surfaceGui.Enabled,
		["surface_gui_face"] = tostring(surfaceGui.Face),
		["surface_gui_size_x"] = surfaceGui.AbsoluteSize.X,
		["surface_gui_size_y"] = surfaceGui.AbsoluteSize.Y,
	}
end

function AdRequestStats:getPartStats(part)
	local partStats = {
		["part_name"] = part:GetFullName(),
		["part_shape"] = tostring(part.Shape),
		["part_size"] = tostring(part.Size),
		["part_color"] = tostring(part.Color),
		["part_orientation"] = tostring(part.Orientation),
		["part_position"] = tostring(part.Position),
	}

	local surfaceGuiStats = AdRequestStats:getSurfaceGuiStats(part)

	return merge(partStats, surfaceGuiStats)
end

local OUTFIT_PROPERTIERS = {
	["Head"] = 17,
	["Face"] = 18,
	["Torso"] = 27,
	["RightArm"] = 28,
	["LeftArm"] = 29,
	["LeftLeg"] = 30,
	["RightLeg"] = 31,
	["HairAccessory"] = 41,
}

function AdRequestStats:getPlayerOutfit(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidDescription = character:WaitForChild("Humanoid"):WaitForChild("HumanoidDescription")

	local items = {}
	for property, slotId in OUTFIT_PROPERTIERS do
		local value = humanoidDescription[property]

		if property == "HairAccessory" then
			for itemId in string.gmatch(value, "([^,]+)") do
				table.insert(items, {item_id = tonumber(itemId), slot = 41})
			end
		else
			table.insert(items, {item_id = value, slot = slotId})
		end
	end

	return items
end

function AdRequestStats:getPlayerCountryCode(player)
	local _, code = pcall(function()
		return LocalizationService:GetCountryRegionForPlayerAsync(player)
	end)

	return code
end

function AdRequestStats:getPlayerPolicyInfo(player)
	local result, policyInfo = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)

	if not result then
		return {
			AreAdsAllowed = true,
			ArePaidRandomItemsRestricted = true,
			AllowedExternalLinkReferences = {},
			IsPaidItemTradingAllowed = false,
			IsSubjectToChinaPolicies = true,
		}
	end

	return policyInfo
end

function AdRequestStats:getClientResolution()
	local currentCamera = Workspace.CurrentCamera
	local clientResolution = { client_resolution_x = 0, client_resolution_y = 0 }

	if not currentCamera then
		local waitStart = Workspace:GetServerTimeNow()
		repeat
			task.wait()
			currentCamera = Workspace.CurrentCamera
		until currentCamera or Workspace:GetServerTimeNow() - waitStart > WAIT_FOR_CAMERA_MAX_TIME

		if Workspace:GetServerTimeNow() - waitStart > WAIT_FOR_CAMERA_MAX_TIME then
			Utils.pprint("[SuperBiz] You're repeatedly setting the CurrentCamera to nil, please stop.")
		elseif currentCamera then
			clientResolution = {
				client_resolution_x = currentCamera.ViewportSize.X,
				client_resolution_y = currentCamera.ViewportSize.Y,
			}
		end
	else
		clientResolution =
			{ client_resolution_x = currentCamera.ViewportSize.X, client_resolution_y = currentCamera.ViewportSize.Y }
	end

	--For console players and backup method
	if clientResolution.client_resolution_x <= 1 or clientResolution.client_resolution_y <= 1 then
		local playerMouse = game.Players.LocalPlayer:GetMouse()
		clientResolution =
			{ client_resolution_x = playerMouse.ViewSizeX, client_resolution_y = playerMouse.ViewSizeY + 72 }
	end

	return clientResolution
end

function AdRequestStats:getSubsetClientPlayerStatsFallback()
	return {
		["client_resolution"] = {client_resolution_x = 0, client_resolution_y = 0},
		["system_locale_id"] = "unknown",
		["is_ten_foot_interface"] = false,
		["accelerometer_enabled"] = false,
		["gamepad_enabled"] = false,
		["gyroscope_enabled"] = false,
		["keyboard_enabled"] = false,
		["mouse_enabled"] = false,
		["touch_enabled"] = false,
		["vr_enabled"] = false,
	}
end

function AdRequestStats:getSubsetClientPlayerStats()
	if not RunService:IsClient() then
		return
	end

	local GuiService = game:GetService("GuiService")
	local UserInputService = game:GetService("UserInputService")

	return {
		["client_resolution"] = self:getClientResolution(),
		["system_locale_id"] = LocalizationService.SystemLocaleId,
		["is_ten_foot_interface"] = GuiService:IsTenFootInterface() or false,
		["accelerometer_enabled"] = UserInputService.AccelerometerEnabled,
		["gamepad_enabled"] = UserInputService.GamepadEnabled,
		["gyroscope_enabled"] = UserInputService.GyroscopeEnabled,
		["keyboard_enabled"] = UserInputService.KeyboardEnabled,
		["mouse_enabled"] = UserInputService.MouseEnabled,
		["touch_enabled"] = UserInputService.TouchEnabled,
		["vr_enabled"] = UserInputService.VREnabled,
	}
end

function AdRequestStats:getClientPlayerStats(player, customWaitTime)
	local isClient = RunService:IsClient()
	local policyInfo = self:getPlayerPolicyInfo(player)

	--Some of the client player stats are collected on server
	--This is more reliable because of internal ROBLOX bugs
	local playerStats = {
		["country_code"] = self:getPlayerCountryCode(player),
		["allowed_external_link_references"] = policyInfo.AllowedExternalLinkReferences,
		["are_ads_allowed"] = policyInfo.AreAdsAllowed,
		["player_membership_type"] = player.MembershipType.Value,
	}
	local subsetStats = {}

	if isClient then
		subsetStats = self:getSubsetClientPlayerStats()
	else
		local getSubsetClientPlayerStatsRemFunction = ReplicatedStorage[REMOTES_FOLDER]:WaitForChild("getSubsetClientPlayerStats")
		local startTime = tick()
		local timeToWait = customWaitTime or CLIENT_RESPONSE_WAIT

		local success, result
		task.spawn(function()
			success, result = pcall(function()
				return getSubsetClientPlayerStatsRemFunction:InvokeClient(player)
			end)
		end)
	
		while (tick() - startTime < timeToWait) and success == nil do
			task.wait()
		end
	
		if success then
			subsetStats = result
		else
			subsetStats = self:getSubsetClientPlayerStatsFallback()
		end
	end

	return merge(playerStats, subsetStats)
end

function AdRequestStats:getPlayerStats(player)
	return {
		["player_id"] = player.UserId,
		["player_age"] = player.AccountAge,
		["player_locale_id"] = player.LocaleId,
	}
end

--Data from this function is fetched purely from the client unlike calling getClientPlayerStats from server
--This can result in missing fields if high latency?
--TODO: Test the safety of this function
function AdRequestStats:getPlayerStatsWithClientStatsYielding(player)
    local playerStats = PlayerStatsModule.playerStats[player.UserId]

    if not playerStats then
        local timeout = 3
        local startTime = tick()

        repeat
            playerStats = PlayerStatsModule.playerStats[player.UserId]
            task.wait()
        until playerStats or (tick() - startTime) > timeout

        if not playerStats then
            return nil
        end
    end

    return Utils.deepCopy(playerStats)
end

function AdRequestStats:getAllPlayerStatsWithClientStats()
	local players = Players:GetPlayers()
	local playersStats = {}

	local playersStillInGame = {}

	for _, player in pairs(players) do
		local playerStats = PlayerStatsModule.playerStats[player.UserId]

		if not playerStats then
			continue
		end

		playersStillInGame[player.UserId] = playerStats
		table.insert(playersStats, Utils.deepCopy(playerStats))
	end

	return playersStats
end

return AdRequestStats