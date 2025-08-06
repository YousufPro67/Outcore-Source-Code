local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MiniPlayerOpen = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.MiniPlayerOpen)

local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)
local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local BoomboxButton = require(script.Parent.Components.BoomboxButton)
local Common = require(script.Parent.Utils.Common)
local ElementSizes = require(script.Parent.Utils.ElementSizes)
local MiniPlayer = require(script.Parent.Components.MiniPlayer)
local NotificationBox = require(script.Parent.Components.NotificationBox)

local AudioPlaybackEvent = StarterPlayer.StarterPlayerScripts.Styngr.AudioPlaybackEvent

local connection
connection = AudioPlaybackEvent.Event:Connect(function(value)
	if value and not MiniPlayerOpen:get() then
		MiniPlayerOpen:set(true)
		connection:Disconnect()
	end
end)

local Children = Fusion.Children
local New = Fusion.New

local BoomboxTopbarManager = {}

function BoomboxTopbarManager:Init(configuration)
	if not configuration then
		return
	end

	self._miniPlayer = MiniPlayer.MiniPlayer()
	self._boomboxButton = BoomboxButton()
	self._notificationBox = NotificationBox()
	local children = {
		self._miniPlayer,
		self._boomboxButton,
		self._notificationBox,
	}

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local function getChildElement(parent)
			for _, child in parent:GetChildren() do
				return child
			end
		end

		local function reposition(element, elementWidth)
			local xPos = Common.calcualteXPosition(elementWidth, workspace.CurrentCamera.ViewportSize.X)

			local firstChild = getChildElement(element)
			local secondChild = getChildElement(firstChild)
			secondChild.Position = UDim2.fromOffset(xPos, 0)
		end

		reposition(self._boomboxButton, ElementSizes.WIDTH.BUTTON)
		reposition(self._miniPlayer, ElementSizes.WIDTH.MINIPLAYER)
	end)

	if FeatureFlags.alwaysOnUI then
		return New("ScreenGui")({
			Name = "TopBarUi",
			Enabled = true,
			DisplayOrder = 0,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),

			[Children] = children,
		})
	end
end

return BoomboxTopbarManager
