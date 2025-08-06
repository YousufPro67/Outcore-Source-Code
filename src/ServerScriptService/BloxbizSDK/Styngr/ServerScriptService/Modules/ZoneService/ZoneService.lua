local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GetClosestPlayer = require(script.Parent.Parent.Parent.Utils.GetClosestPlayer)

local Zone = require(ReplicatedStorage.Styngr.Zone)

local Sphere = require(script.Parent.Sphere)
local Zones = require(script.Parent.Zones)

local function weld(part0, part1)
	local Weld = Instance.new("WeldConstraint")
	Weld.Name = "Welding"
	Weld.Parent = part1
	Weld.Part0 = part0
	Weld.Part1 = part1
end

type Callback = (Player, Player) -> nil

export type IZoneService = {
	add: (player: Player) -> nil,
	remove: (player: Player) -> nil,
	reJoin: (player: Player) -> nil,
}

local ZoneService: IZoneService = {}

ZoneService.__index = ZoneService

function ZoneService.New(playerEntered: Callback | nil, playerExited: Callback | nil)
	local self = {
		_playerEntered = playerEntered,
		_playerExited = playerExited,
	}

	setmetatable(self, ZoneService)

	return self
end

function ZoneService:add(owner: Player): nil
	Zones:init(owner.UserId)

	local Character = owner.Character or owner.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

	local part = Sphere:Clone()
	part.CFrame = HumanoidRootPart.CFrame
	part.Parent = HumanoidRootPart

	weld(HumanoidRootPart, part)

	local zone = Zone.new(part)

	zone.playerEntered:Connect(function(player)
		self:_onPlayerEntered(owner, player)
	end)

	zone.playerExited:Connect(function(player)
		self:_onPlayerExited(owner, player)
	end)
end

function ZoneService:remove(player: Player): nil
	Zones:clear(player.UserId)

	local Character = player.Character or player.CharacterAdded:Wait()
	local Part = Character:WaitForChild("HumanoidRootPart"):FindFirstChild(Sphere.Name)

	if Part then
		Part:Destroy()
	end
end

function ZoneService:reJoin(player: Player): nil
	local closestOwner = GetClosestPlayer(Zones:PlayerInZones(player.UserId), player)

	if not closestOwner then
		return
	end

	Zones:add(closestOwner.UserId, player.UserId)
	print(("%s re-joined the zone of %s!"):format(player.Name, closestOwner.Name))
	if self._playerEntered then
		self._playerEntered(closestOwner, player)
	end
end

function ZoneService:_onPlayerEntered(owner: Player, player: Player): nil
	if owner.Name == player.Name then
		print(("%s spawened"):format(owner.Name))
		return
	end

	if Zones:PlayersInZone(owner.UserId) and Zones:PlayersInZone(player.UserId) then
		Zones:remove(player.UserId, owner.UserId)

		print(("%s can not join zone since he is an owner."):format(player.Name))
		return
	end

	print(("%s entered the zone of %s!"):format(player.Name, owner.Name))

	Zones:add(owner.UserId, player.UserId)

	if self._playerEntered then
		self._playerEntered(owner, player)
	end
end

function ZoneService:_onPlayerExited(owner: Player, player: Player): nil
	if owner.Name == player.Name then
		print(("%s left the game"):format(owner.Name))
		return
	end

	if Zones:PlayersInZone(owner.UserId) and Zones:PlayersInZone(player.UserId) then
		return
	end

	print(("%s exited the zone %s!"):format(player.Name, owner.Name))

	Zones:remove(owner.UserId, player.UserId)

	if self._playerExited then
		self._playerExited(owner, player)
	end
end

function ZoneService:Init(): nil
	Players.PlayerAdded:Connect(function(player: Player): nil
		Zones:init(player.UserId)
		self:add(player)
	end)
end

return ZoneService
