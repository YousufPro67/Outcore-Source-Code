local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)
local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local SurroundService = require(script.Parent.SurroundService)

-- This has to stay like this. When used in a shorthand form with script the NowPlaying variable
-- change is not detected in the hud button to show that a track is being played.
-- We don't know what is the connection.
local InterfaceService = require(StarterPlayer.StarterPlayerScripts.Styngr.InterfaceService)

local Configuration = {}
local config = ReplicatedStorage.Styngr:FindFirstChild("Configuration")
if config then
	Configuration = require(config)
end

local TokenReceivedEvent = ReplicatedStorage.Styngr.TokenReceivedEvent
local TokenLostEvent = ReplicatedStorage.Styngr.TokenLostEvent

local New = Fusion.New
local Children = Fusion.Children

local StyngrClient = {}

function StyngrClient:InitializeTokenMessageWindow()
	local popup = New("ScreenGui")({
		Name = "Popup",
	})

	-- Calculate the position to center the popup
	local screenWidth = game.Workspace.CurrentCamera.ViewportSize.X
	local screenHeight = game.Workspace.CurrentCamera.ViewportSize.Y
	local popupWidth = 0.25 * screenWidth
	local popupHeight = 0.25 * screenHeight
	local xPos = (screenWidth - popupWidth) / 2
	local yPos = (screenHeight - popupHeight) / 2

	local frame = New("Frame")({
		Parent = popup,
		Size = UDim2.new(0.25, 0, 0.25, 0),
		Position = UDim2.new(0, xPos, 0, yPos),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 5,
		[Children] = {
			New("TextLabel")({
				Size = UDim2.new(1, 0, 1, 0),
				Text = "Unable to get token from server",
				TextScaled = false,
				TextColor3 = Color3.new(1, 0, 0),
			}),
		},
	})

	-- Create a close button
	local closeButton = New("TextButton")({
		Parent = frame,
		Size = UDim2.new(0.4, 0, 0.2, 0),
		Position = UDim2.new(0.3, 0, 0.95, 0),
		BackgroundColor3 = Color3.new(0.368627, 0.219607, 0.219607),
		TextColor3 = Color3.new(1, 1, 1),
		Text = "Close",
	})
	-- Function to close the popup
	local function closePopup()
		self:HideTokenLostMessage()
	end

	-- Bind the close function to the close button
	closeButton.MouseButton1Click:Connect(closePopup)

	popup.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	return popup
end

function StyngrClient:ShowTokenLostMessage()
	self.messageGui.Enabled = true
end

function StyngrClient:HideTokenLostMessage()
	self.messageGui.Enabled = false
end

function StyngrClient:ShowStyngrInterface()
	self.styngrInterface.Enabled = true
end

function StyngrClient:HideStyngrInterface()
	self.styngrInterface.Enabled = false
end

--[=[
	Initialize the Styngr service on the client side and establish a connection
	to the server for serving music
]=]
function StyngrClient:Init(): nil
	local userInteraction = Configuration.userInteraction == nil or Configuration.userInteraction

	if not userInteraction then
		local _ = ReplicatedStorage.Styngr.ContinuePlaylistSession:InvokeServer()
		return
	end

	if not Configuration.playbackAutoStart and FeatureFlags.groupListening then
		SurroundService:init()
	end

	if FeatureFlags.alwaysOnUI then
		self.styngrInterface = InterfaceService:Init()
		return
	end

	self.tokenReceived = nil
	self.styngrInterface = nil
	-- TODO: Showing/hiding token lost message should be configurable by the developer
	-- self.messageGui = self:InitializeTokenMessageWindow()

	TokenReceivedEvent.OnClientEvent:Connect(function()
		if self.tokenReceived ~= nil and self.tokenReceived then
			return
		end

		if self.styngrInterface == nil then
			self.styngrInterface = InterfaceService:Init()
		end

		-- TODO: Showing/hiding token lost message should be configurable by the developer
		-- self:HideTokenLostMessage()
		self.tokenReceived = true
	end)

	TokenLostEvent.OnClientEvent:Connect(function()
		if self.tokenReceived ~= nil and not self.tokenReceived then
			return
		end

		if self.styngrInterface ~= nil then
			self.styngrInterface:Destroy()
			self.styngrInterface = nil
		end

		self.tokenReceived = false
		-- TODO: Showing/hiding token lost message should be configurable by the developer
		-- self:ShowTokenLostMessage()
	end)
end

return StyngrClient
