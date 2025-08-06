local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local CommonTypes = require(ReplicatedStorage.Styngr.Types)
local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local Common = require(script.Parent.Parent.Utils.Common)
local ElementSizes = require(script.Parent.Parent.Utils.ElementSizes)

local AudioService = require(StarterPlayer.StarterPlayerScripts.Styngr.AudioService)
local Counter = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.Counter)
local MiniPlayerOpen = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.MiniPlayerOpen)
local NowPlaying = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.NowPlaying)
local PlaylistsCount = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.PlaylistsCount)
local PlaylistsOpen = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.PlaylistsOpen)
local Skippable = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.Skippable)

local AudioPlaybackEvent = StarterPlayer.StarterPlayerScripts.Styngr.AudioPlaybackEvent

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed

local Paused = Fusion.Value(false)
AudioPlaybackEvent.Event:Connect(function(value)
	Paused:set(value)
end)

local pauseId = "rbxassetid://13171728180"
local playId = "rbxassetid://13551674641"
local hamburgerId = "rbxassetid://13171794624"
local skipId = "rbxassetid://13172323318"

local TIME = 12 -- specifies how long it should take for the value to animate to the goal, in seconds.
local REPEAT_COUNT = -1

-- TODO : to be replaced with new get playlists call
if PlaylistsCount:get() == 0 then
	PlaylistsCount:set(#(ReplicatedStorage.Styngr.GetPlaylists:InvokeServer() or {}))
end

local NUMBER_OF_PLAYLISTS = PlaylistsCount:get()

local artistAndTitle = Computed(function()
	local nowPlaying = NowPlaying:get()

	if not nowPlaying then
		return ""
	end

	if not nowPlaying.artists or nowPlaying.artists == "" then
		return nowPlaying.title
	end

	return nowPlaying.artists .. " - " .. nowPlaying.title
end)

local menuImageLabel = New("ImageLabel")({
	Name = "Hamburger",
	Image = hamburgerId,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.467, 1),

	[Children] = {
		New("UIAspectRatioConstraint")({
			AspectRatio = 1.2,
		}),
	},
})

local menuButton = if NUMBER_OF_PLAYLISTS > 1
	then New("TextButton")({
		Name = "Menu",
		AutoButtonColor = true,
		BackgroundTransparency = 0.6,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.7, 0.7),

		[OnEvent("Activated")] = function()
			DisableAllButtons()
			PlaylistsOpen:toggle()
			EnableAllButtons()
		end,

		[Children] = {
			New("UIAspectRatioConstraint")({}),
			New("UICorner")({
				CornerRadius = UDim.new(1, 0),
			}),
			menuImageLabel,
		},
	})
	else nil

local playPauseImageLabel = New("ImageLabel")({
	Name = "PlayPause",
	Image = Computed(function()
		return if Paused:get() then pauseId else playId
	end),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.467, 1),

	[Children] = {
		New("UIAspectRatioConstraint")({
			AspectRatio = 1.2,
		}),
	},
})

local playPauseButton = New("ImageLabel")({
	Name = "PlayPause",
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1.4, 1.4),

	[Children] = {
		New("UIAspectRatioConstraint")({}),
		New("UICorner")({
			CornerRadius = UDim.new(1, 0),
		}),
		New("UIPadding")({
			PaddingTop = UDim.new(4, 0),
			PaddingBottom = UDim.new(4, 0),
			PaddingRight = UDim.new(0.25, 0),
		}),
		playPauseImageLabel,
	},
})

local skipImageLabel = New("ImageLabel")({
	Name = "SkipImageLabel",
	Image = skipId,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.467, 1),
	Visible = Computed(function()
		return Skippable:get()
	end),

	[Children] = {
		New("UIAspectRatioConstraint")({
			AspectRatio = 1.2,
		}),
	},
})

local skipCounterLabel = New("TextLabel")({
	Name = "SkipCounterText",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Text = Computed(function()
		return Counter:get()
	end),
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.fromScale(0.467, 1),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Visible = Computed(function()
		return not Skippable:get()
	end),

	[Children] = {
		New("UIPadding")({
			PaddingTop = UDim.new(0.18, 0),
			PaddingLeft = UDim.new(0.06, 0),
		}),
	},
})

local skipButton = New("TextButton")({
	Name = "Skip",
	AutoButtonColor = true,
	BackgroundTransparency = 0.6,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(0.7, 0.7),

	[OnEvent("Activated")] = function()
		if AudioService:IsPaused() or not AudioService:CanSkip() then
			return
		end

		DisableAllButtons()

		if PlaylistsOpen:get() then
			PlaylistsOpen:toggle()
		end

		local track: CommonTypes.ClientTrack | nil = ReplicatedStorage.Styngr.SkipTrack:InvokeServer()

		if not track then
			AudioService:Stop()
			PlaylistsOpen:set(true)

			EnableAllButtons()
			return
		end

		AudioService:PlaySound(track)
		EnableAllButtons()
	end,

	[Children] = {
		New("UIAspectRatioConstraint")({}),
		New("UICorner")({
			CornerRadius = UDim.new(1, 0),
		}),
		skipCounterLabel,
		skipImageLabel,
	},
})

local playPauseText = New("TextLabel")({
	Name = "PlayPauseText",
	BackgroundTransparency = 1,
	Position = UDim2.new(1, 0, 0, 0),
	FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	Text = artistAndTitle,
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.fromOffset(120, 26),
	TextColor3 = Color3.fromRGB(255, 255, 255),
})

local style = TweenInfo.new(TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, REPEAT_COUNT)
TweenService:Create(playPauseText, style, { Position = UDim2.new(-1, 0, 0, 0) }):Play()

local textLabelGroup = New("Frame")({
	Name = "TextFrame",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(120, 26),
	ClipsDescendants = true,

	[Children] = {
		New("UIPadding")({
			PaddingTop = UDim.new(0.2, 0),
		}),
		New("UICorner")({
			CornerRadius = UDim.new(0.15, 0),
		}),
		playPauseText,
	},
})

local playPauseGroup = New("TextButton")({
	Name = "PlayPauseGroup",
	BackgroundTransparency = 0.65,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Size = UDim2.fromOffset(150, 26),

	[OnEvent("Activated")] = function()
		if NowPlaying:get() then
			DisableAllButtons()

			if PlaylistsOpen:get() then
				PlaylistsOpen:toggle()
			end

			AudioService:PlayPause()

			EnableAllButtons()
		end
	end,

	[Children] = {
		New("UIListLayout")({
			Padding = UDim.new(0, 0.5),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		New("UIPadding")({
			PaddingLeft = UDim.new(0.03, 0),
		}),
		New("UICorner")({
			CornerRadius = UDim.new(5, 0),
		}),
		textLabelGroup,
		playPauseButton,
	},
})

local xPos = Common.calcualteXPosition(ElementSizes.WIDTH.MINIPLAYER)
local miniPlayerWidth = Common.calculatePlayerWidth(ElementSizes.WIDTH.MINIPLAYER, NUMBER_OF_PLAYLISTS)

local player = New("Frame")({
	Name = "Player",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.6,
	Position = UDim2.fromOffset(xPos, 0),
	Size = UDim2.fromOffset(miniPlayerWidth, 32),

	[Children] = {
		New("UIListLayout")({
			Padding = UDim.new(0, 3),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		New("UICorner")({
			CornerRadius = UDim.new(0.23, 0),
		}),
		New("UIPadding")({
			PaddingBottom = UDim.new(0.027, 0),
			PaddingLeft = UDim.new(0.03, 0),
			PaddingRight = UDim.new(0.03, 0),
			PaddingTop = UDim.new(0.027, 0),
		}),
		menuButton,
		playPauseGroup,
		skipButton,
	},
})

local function MiniPlayer()
	return New("Frame")({
		BackgroundTransparency = 1,
		Name = "MiniPlayerContainerTopLevel",
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 1,
		Active = false,
		Visible = Computed(function()
			return MiniPlayerOpen:get()
		end),

		[Children] = {
			New("Frame")({
				BackgroundTransparency = 1,
				Name = "MiniPlayerContainer",
				Size = UDim2.new(1, 0, 0, 32),
				ZIndex = 1,
				Active = false,

				[Children] = {
					player,
				},
			}),
		},
	})
end

function DisableAllButtons()
	skipButton.Active = false
	skipButton.BackgroundTransparency = 1
	skipImageLabel.ImageTransparency = 0.5

	playPauseGroup.Active = false
	playPauseGroup.BackgroundTransparency = 1
	playPauseImageLabel.ImageTransparency = 0.5

	if menuButton then
		menuButton.Active = false
		menuButton.BackgroundTransparency = 1
		menuImageLabel.ImageTransparency = 0.5
	end
end

function EnableAllButtons()
	skipButton.Active = true
	skipButton.BackgroundTransparency = 0.6
	skipImageLabel.ImageTransparency = 0

	playPauseGroup.Active = true
	playPauseGroup.BackgroundTransparency = 0.6
	playPauseImageLabel.ImageTransparency = 0

	if menuButton then
		menuButton.Active = true
		menuButton.BackgroundTransparency = 0.6
		menuImageLabel.ImageTransparency = 0
	end
end

return {
	MiniPlayer = MiniPlayer,
	DisableAllButtons = DisableAllButtons,
	EnableAllButtons = EnableAllButtons,
}
