local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CommonTypes = require(ReplicatedStorage.Styngr.Types)
local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)
local TrackType = require(ReplicatedStorage.Styngr.TrackType)

local AudioService = require(script.Parent.Parent.AudioService)
local MiniPlayer = require(script.Parent.MiniPlayer)
local NowPlaying = require(script.Parent.Parent.StateValues.NowPlaying)
local PlaylistsOpen = require(script.Parent.Parent.StateValues.PlaylistsOpen)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local pauseId = "rbxassetid://15953508871"
local playId = "rbxassetid://13548540206"

local notAvailable = Fusion.Value({})

local TIME = 8 -- specifies how long it should take for the value to animate to the goal, in seconds.
local REPEAT_COUNT = -1

local function PlaylistItem(props)
	local title = New("TextLabel")({
		Name = "Title",
		Position = UDim2.new(1, 0, 0, 0),
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = props.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(110, 18),
		TextSize = 16,
	})

	local style = TweenInfo.new(TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, REPEAT_COUNT)
	TweenService:Create(title, style, { Position = UDim2.new(-1, 0, 0, 0) }):Play()

	return New("Frame")({
		Name = "PlaylistItem",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		Size = UDim2.new(0.98, 0, 0, 40),

		[Children] = {
			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.25, 0),
			}),
			New("UIPadding")({
				Name = "UIPadding",
				PaddingBottom = UDim.new(0.133, 0),
				PaddingLeft = UDim.new(0.04, 0),
				PaddingRight = UDim.new(0.0267, 0),
				PaddingTop = UDim.new(0.1, 0),
			}),
			New("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			New("Frame")({
				Name = "Content",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.new(0.77, 0, 0, 50),

				[Children] = {
					New("UIListLayout")({
						Name = "UIListLayout",
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					New("Frame")({
						Name = "TitleFrame",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(110, 18),
						ClipsDescendants = true,

						[Children] = {
							title,
						},
					}),

					New("TextLabel")({
						Name = "Tracks",
						FontFace = Font.new(
							"rbxasset://fonts/families/GothamSSm.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Text = props.TrackCount .. " Songs",
						TextColor3 = Color3.fromRGB(170, 170, 170),
						TextScaled = false,
						FontSize = Enum.FontSize.Size11,
						TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(110, 14),
					}),
				},
			}),
			New("Frame")({
				Name = "PlaylistType",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(20, 40),
			}),
			New("Frame")({
				Name = "PlayPauseFrame",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.new(0.1, 0, 0, 40),

				[Children] = {
					New("UIListLayout")({
						Name = "UIListLayout",
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
					}),
					New("TextButton")({
						Name = "PlayButton",
						Text = "",
						BackgroundColor3 = Color3.new(1, 1, 1),
						Size = UDim2.fromOffset(20, 20),
						Active = Computed(function()
							local nowPlaying = NowPlaying:get()

							return not nowPlaying
								or nowPlaying.type == TrackType.MUSICAL
								or nowPlaying.playlistId == props.Id
						end),

						[OnEvent("Activated")] = props.PlayHandler,

						[Children] = {
							New("UIAspectRatioConstraint")({
								Name = "UIAspectRatioConstraint",
							}),
							New("UICorner")({
								Name = "UICorner",
								CornerRadius = UDim.new(1, 0),
							}),

							New("ImageLabel")({
								Name = "ArrowIcon",
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.fromScale(1, 0.5),
								BackgroundTransparency = 1,
								Image = Computed(function()
									local nowPlaying = NowPlaying:get()

									if
										nowPlaying
										and nowPlaying.playlistId == props.Id
										and not AudioService:IsPaused()
									then
										return pauseId
									else
										return playId
									end
								end),

								[Children] = {
									New("UIAspectRatioConstraint")({
										Name = "UIAspectRatioConstraint",
									}),
								},
							}),
						},
					}),
				},
			}),
		},
	})
end

local function Playlist()
	local playlists = ReplicatedStorage.Styngr.GetPlaylists:InvokeServer() or {}
	local playlistCount = #playlists
	local playlistHeight = if playlistCount < 4 then playlistCount * 0.25 else 1
	local isScrollOpen = playlistCount > 4

	local items = {}
	for _, playlist in playlists do
		if table.find(notAvailable:get(), playlist.id) then
			continue
		end

		table.insert(
			items,
			PlaylistItem({
				["Title"] = playlist.title,
				["TrackCount"] = playlist.trackCount,
				["Id"] = playlist.id,
				PlayHandler = function()
					PlaylistsOpen:set(false)
					MiniPlayer.DisableAllButtons()
					local nowPlaying = NowPlaying:get()

					if nowPlaying and nowPlaying.playlistId == playlist.id then
						AudioService:PlayPause()
						PlaylistsOpen:set(false)

						MiniPlayer.EnableAllButtons()
						return
					end

					local track: CommonTypes.ClientTrack =
						ReplicatedStorage.Styngr.StartPlaylistSession:InvokeServer(playlist.id, playlist.type)

					if not track or typeof(track) == "string" then
						if track == "empty" then
							local current = notAvailable:get()
							table.insert(current, playlist.id)
							notAvailable:set(current)
						end

						AudioService:Stop()
						MiniPlayer.EnableAllButtons()
						return
					end

					AudioService:PlaySound(track)
					MiniPlayer.EnableAllButtons()
				end,
			})
		)
	end

	local scrollingFrame = New("ScrollingFrame")({
		Name = "ScrollingFrame",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Active = true,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
		ScrollBarThickness = 9,
		ScrollBarImageColor3 = Color3.fromRGB(41, 40, 40),
		BackgroundColor3 = Color3.fromRGB(255, 252, 252),
		BackgroundTransparency = 1,
		ScrollingEnabled = isScrollOpen,
		VerticalScrollBarInset = if isScrollOpen then Enum.ScrollBarInset.Always else Enum.ScrollBarInset.None,
		Size = UDim2.fromScale(1, 1),

		[Children] = {
			New("UIListLayout")({
				Name = "UIListLayout",
				Padding = UDim.new(0.0214, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New("UIPadding")({
				Name = "UIPadding",
				PaddingLeft = if isScrollOpen then UDim.new(0.05, 0) else UDim.new(0.01, 0),
				PaddingRight = UDim.new(0.015, 0),
			}),
			items,
		},
	})

	return New("Frame")({
		Name = "Playlist",
		Size = UDim2.fromScale(1, playlistHeight),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = {
			New("Frame")({
				Name = "Content",
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(3, 3, 3),
				BackgroundTransparency = 0.6,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(1, 1),

				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(0.0588, 0),
					}),
					New("UIPadding")({
						Name = "UIPadding",
						PaddingLeft = UDim.new(0.04, 0),
						PaddingRight = UDim.new(0.015, 0),
						PaddingTop = UDim.new(0.035, 0),
					}),
					scrollingFrame,
				},
			}),
		},
	})
end

return Playlist
