local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local Value = Fusion.Value

type Values = { [number]: { [number]: number } }
type Callback = (Values) -> nil

local Zones = Value({})

function Zones:add(zone: number, player: number): Values
	Zones:update(function(prev)
		table.insert(prev[zone], player)

		return prev
	end)
end

function Zones:clear(player: number): Values
	Zones:update(function(prev)
		table.remove(prev, table.find(prev, player))

		return prev
	end)
end

function Zones:init(player: number): Values
	Zones:update(function(prev: Values): Values
		prev[player] = {}

		return prev
	end)
end

function Zones:remove(zone: number, player: number): Values
	Zones:update(function(prev)
		table.remove(prev[zone], table.find(prev[zone], player))

		return prev
	end)
end

function Zones:update(callback: Callback): Values
	local newValue = callback(Zones:get())

	assert(newValue and typeof(newValue) == "table", "Invalid values")

	return Zones:set(newValue)
end

function Zones:PlayersInZone(zone): { [number]: number }
	local zones = Zones:get()

	return zones[zone]
end

function Zones:PlayerInZones(player): { [number]: number }
	local allZones = Zones:get()
	local zones = {}

	for zone, players in pairs(allZones) do
		if table.find(players, player) then
			table.insert(zones, zone)
		end
	end

	return zones
end

return Zones
