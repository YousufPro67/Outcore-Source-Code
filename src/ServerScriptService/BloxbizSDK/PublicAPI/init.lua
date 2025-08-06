local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

export type PublicAPI = {
	dynamicLoadBillboardAd: (adUnit: any) -> (),
	dynamicLoadBoxAd: (adBox: any) -> (),
	dynamicLoadPortalAd: (adBox: any) -> (),
	registerEvent: (eventName: string, eventValue: number, playerId: number) -> (),

	openCatalog: () -> (),
	closeCatalog: () -> (),
	toggleCatalog: () -> (),

	getCatalogIcon: () -> (),
	getCatalogContainer: () -> (),
}

local PublicAPI = {} :: PublicAPI

local function registerEventHelper(eventName, eventValue, playerId, bloxbizAdId)
	local AdRequestStats = require(script.Parent.AdRequestStats)
	local BatchHTTP = require(script.Parent.BatchHTTP)
	local Utils = require(script.Parent.Utils)

	if type(eventName) ~= "string" then
		Utils.pprint("[Super Biz] Invalid type for eventName when registering custom event, must be string")
		return
	end
	if type(eventValue) ~= "number" then
		Utils.pprint("[Super Biz] Invalid type for eventValue when registering custom event, must be number")
		return
	end
	if type(playerId) ~= "number" then
		Utils.pprint("[Super Biz] Invalid type for playerId when registering custom event, must be number")
		return
	end
	if bloxbizAdId and type(bloxbizAdId) ~= "number" then
		Utils.pprint("[Super Biz] Invalid type for ad id when registering custom event, must be number")
		return
	end

	local customEvent = {
		["metric_name"] = eventName,
		["metric_value"] = eventValue,
		["player_id"] = playerId,
		["timestamp"] = os.time(),
		["bloxbiz_ad_id"] = bloxbizAdId,
	}
	local gameStats = AdRequestStats:getGameStats()
	local playerStatsFromPlayerId = AdRequestStats:getPlayerStatsWithClientStatsYielding({UserId = playerId})

	if type(playerStatsFromPlayerId) ~= "table" then
		Utils.pprint("[Super Biz] Player data was not available when registering custom event for", playerId)
		return
	end

	customEvent = Utils.merge(Utils.merge(customEvent, gameStats), playerStatsFromPlayerId)

	local event = { event_type = "custom_metric", data = customEvent }
	table.insert(BatchHTTP.eventQueue, event)

	Utils.custom_event_print("[Super Biz Custom Events] Event name: ", eventName, " Event value: ", eventValue)
end

if RunService:IsServer() then
	function PublicAPI.dynamicLoadBillboardAd(adUnit)
		local BillboardServer = require(script.Parent.BillboardServer)
		BillboardServer:initInstance(adUnit, true)
	end

	function PublicAPI.dynamicLoadBoxAd(adBox)
		local Ad3DServer = require(script.Parent.Ad3DServer)
		Ad3DServer.new(adBox, true)
	end

	function PublicAPI.dynamicLoadPortalAd(adBox)
		local PortalServer = require(script.Parent.PortalServer)
		PortalServer.new(adBox, true)
	end

	function PublicAPI.registerEvent(...)
		local eventName, eventValue, playerId = ...

		local args = {...}
		if #args == 2 then
			eventName, eventValue, playerId = args[1], 1, args[2]
		end

		task.spawn(function()
			registerEventHelper(eventName, eventValue, playerId)
		end)
	end

	function PublicAPI.registerEventForAd(...)
		local eventName, eventValue, playerId, bloxbizAdId = ...

		local args = {...}
		if #args == 3 then
			eventName, eventValue, playerId, bloxbizAdId = args[1], 1, args[2], args[3]
		end

		task.spawn(function()
			registerEventHelper(eventName, eventValue, playerId, bloxbizAdId)
		end)
	end

    function PublicAPI.registerPopUpAd(adUnit, adConfig)
        local PopUpAdHelper = require(script.PopUpAdHelper)
        return PopUpAdHelper.new(adUnit, adConfig)
    end

	PublicAPI.PromoCodes = require(script.Parent.PromoCodes.Server)
	PublicAPI.Rewards = require(script.Parent.Rewards.Server)

	local CommandTool = require(script.Parent.CommandTool.Server)

	function PublicAPI.GetRanks(player)
		return CommandTool.RankManager.GetRanks(player)
	end

	function PublicAPI.ClearRanks(player)
		return CommandTool.RankManager.ClearRanks(player)
	end

	function PublicAPI.HasRank(player, rankId)
		return CommandTool.RankManager.HasRank(player, rankId)
	end

	function PublicAPI.AddRank(player, rankId)
		return CommandTool.RankManager.AddRank(player, rankId)
	end

	function PublicAPI.RemoveRank(player, rankId)
		return CommandTool.RankManager.RemoveRank(player, rankId)
	end
elseif RunService:IsClient() then
	local Catalog = require(script.Parent.CatalogClient)
	local PopfeedClient = require(script.Parent.PopfeedClient)

	export type Catalog = Catalog.Catalog

	function PublicAPI.openCatalog(categoryOrSearchTerm: string?)
		Catalog.OpenCatalog(categoryOrSearchTerm)
	end

	PublicAPI.catalogEnabled = Catalog.Enabled

	function PublicAPI.closeCatalog()
		Catalog.CloseCatalog()
	end

	function PublicAPI.toggleCatalog(categoryOrSearchTerm: string?)
		Catalog.ToggleCatalog(categoryOrSearchTerm)
	end

	function PublicAPI.getCatalogIcon()
		Catalog.getCatalogIcon()
	end

	function PublicAPI.promptBuyOutfit()
		Catalog.PromptBuyOutfit()
	end

	function PublicAPI.getCatalogContainer()
		Catalog.getCatalogContainer()
	end

	function PublicAPI.openPopfeed()
		PopfeedClient.OpenPopfeed()
	end

	function PublicAPI.closePopfeed()
		PopfeedClient.ClosePopfeed()
	end

	function PublicAPI.togglePopfeed()
		PopfeedClient.TogglePopfeed()
	end

	local CommandTool = require(script.Parent.CommandTool.Client)

	function PublicAPI.OpenSBCommands()
		return CommandTool.Open()
	end

	function PublicAPI.CloseSBCommands()
		return CommandTool.Close()
	end

	function PublicAPI.ToggleSBCommands()
		return CommandTool.Toggle()
	end

	PublicAPI.PromoCodes = require(script.Parent.PromoCodes.Client)
	PublicAPI.Rewards = require(script.Parent.Rewards.Client)
end

return PublicAPI
