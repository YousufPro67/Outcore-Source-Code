local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(script.Parent.Utils)
local BatchHTTP = require(script.Parent.BatchHTTP)
local AdRequestStats = require(script.Parent.AdRequestStats)

local GuiTrackingServer = {}

local function queueButtonImpression(player, buttonImpression)
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	local event = { event_type = "gui_button_press", data = Utils.merge(Utils.merge(buttonImpression, game_stats), playerStats) }
	table.insert(BatchHTTP.eventQueue, event)
end

local function onBatchGuiImpressions(player, buttonImpressions)
	for _, buttonImpression in buttonImpressions do
		queueButtonImpression(player, buttonImpression)
	end
end

function GuiTrackingServer.init()
    local onSendGuiImpressions = Instance.new("RemoteEvent")
	onSendGuiImpressions.Name = "OnSendGuiImpressions"
	onSendGuiImpressions.OnServerEvent:Connect(onBatchGuiImpressions)
	onSendGuiImpressions.Parent = ReplicatedStorage.BloxbizRemotes
end

return GuiTrackingServer