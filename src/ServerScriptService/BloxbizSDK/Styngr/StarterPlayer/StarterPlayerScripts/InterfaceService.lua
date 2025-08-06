local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioService = require(script.Parent.AudioService)
local Common = require(script.Parent.Utils.Common)
local ElementSizes = require(script.Parent.Utils.ElementSizes)
local PlaylistsOpen = require(script.Parent.StateValues.PlaylistsOpen)

local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)
local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local Components = script.Parent.Components

local Playlist = require(Components.Playlist)
local Purchase = require(Components.Purchase)
local SubscriptionInfo = require(Components.SubscriptionInfo)

local Configuration = {}
local config = script.Parent:FindFirstChild("Configuration")
if config then
	Configuration = require(config)
end

local ReplicatedConfiguration = {}
local rconfig = ReplicatedStorage.Styngr:FindFirstChild("Configuration")
if rconfig then
	ReplicatedConfiguration = require(rconfig)
end

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local updatedPlaylistXYPos
local startingPlaylistXPos = Common.calcualteXPosition(ElementSizes.WIDTH.PLAYLIST_MENU)
local startingPlaylistYPos = Common.calcualteYPosition(ElementSizes.HEIGHT.PLAYLIST_MENU)

local CanvasGroupTable = {
	Position = {
		UDim2.fromScale(0.5, 0.875),
		UDim2.fromOffset(startingPlaylistXPos, startingPlaylistYPos),
	},
	Size = { UDim2.fromScale(0, 0), UDim2.fromOffset(210, 180) },
	BackgroundColor3 = { Color3.new(), Color3.fromRGB(17, 17, 17) },
	BackgroundTransparency = { 1, 1 },
}

function getField(interfaceTable: table)
	return Computed(function()
		return interfaceTable[if PlaylistsOpen:get() then 2 else 1]
	end)
end

local InterfaceService = {}

local function StyngrFrame()
	if not PlaylistsOpen:get() then
		return {}
	end

	local children = {
		Playlist(),
		New("UISizeConstraint")({
			MinSize = Vector2.new(210, 85),
		}),
	}

	return New("CanvasGroup")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if updatedPlaylistXYPos
			then UDim2.fromOffset(updatedPlaylistXYPos.X, updatedPlaylistXYPos.Y)
			else getField(CanvasGroupTable.Position),
		Size = getField(CanvasGroupTable.Size),
		BackgroundColor3 = getField(CanvasGroupTable.BackgroundColor3),
		BackgroundTransparency = getField(CanvasGroupTable.BackgroundTransparency),
		Visible = PlaylistsOpen:get(),

		[Children] = children,
	})
end

function InterfaceService:Init()
	local track = ReplicatedStorage.Styngr.ContinuePlaylistSession:InvokeServer()
	local teleportAutoStart = Configuration.teleportAutoStart == nil or Configuration.teleportAutoStart
	local paused = not (track and track.playing and teleportAutoStart)

	local isPlaybackAutoStartEnabled = ReplicatedConfiguration.playbackAutoStart == nil
		or ReplicatedConfiguration.playbackAutoStart

	if not track and isPlaybackAutoStartEnabled then
		track = ReplicatedStorage.Styngr.AutoStartPlaylistSession:InvokeServer()
		paused = not isPlaybackAutoStartEnabled
	end

	if track then
		AudioService:PlaySound(track, paused)
	end

	local children = Computed(function()
		local styngrFrame = StyngrFrame()

		local elements = {
			styngrFrame,
		}

		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local xPos =
				Common.calcualteXPosition(ElementSizes.WIDTH.PLAYLIST_MENU, workspace.CurrentCamera.ViewportSize.X)
			local yPos =
				Common.calcualteYPosition(ElementSizes.HEIGHT.PLAYLIST_MENU, workspace.CurrentCamera.ViewportSize.Y)
			styngrFrame.Position = UDim2.fromOffset(xPos, yPos)
			updatedPlaylistXYPos = { X = xPos, Y = yPos }
		end)

		if FeatureFlags.radioPayments then
			table.insert(elements, Purchase())
			table.insert(elements, SubscriptionInfo())
		end

		return elements
	end, Fusion.cleanup)

	return New("ScreenGui")({
		Name = "StyngrUI",
		Enabled = true,
		DisplayOrder = 0,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),

		[Children] = children,
	})
end

return InterfaceService
