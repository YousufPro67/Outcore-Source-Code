local knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
knit.Start():await()
local plrSetting = knit.GetService("SettingService")

local ITEMS = game.ReplicatedStorage.Items
local GRAPPLE_GUN = ITEMS.GrappleGun
local BLASTER = ITEMS.Blaster
local AUTO_BLASTER = ITEMS.AutoBlaster

local CHARACTER = script.Parent.Parent
local PLAYERS = game:GetService("Players")
local PLAYER = PLAYERS:GetPlayerFromCharacter(CHARACTER)
local BACKPACK = PLAYER:WaitForChild("Backpack")
local Settings = plrSetting.Players:Get(PLAYER)

CHARACTER:FindFirstChildOfClass("Humanoid"):UnequipTools()
BACKPACK:ClearAllChildren()

local value = Settings.LEVEL_NAME

if workspace.SkyHop:FindFirstChild(value) then
	if workspace.SkyHop[value]:GetAttribute("GrappleGun") then
		GRAPPLE_GUN:Clone().Parent = BACKPACK
	end
	if workspace.SkyHop[value]:GetAttribute("Blaster") then
		BLASTER:Clone().Parent = BACKPACK
	end
	if workspace.SkyHop[value]:GetAttribute("AutoBlaster") then
		AUTO_BLASTER:Clone().Parent = BACKPACK
	end
end
