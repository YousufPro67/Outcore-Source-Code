local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local Common = require(script.Parent.Parent.Utils.Common)
local ElementSizes = require(script.Parent.Parent.Utils.ElementSizes)

local MiniPlayerOpen = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.MiniPlayerOpen)
local PlaylistsOpen = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.PlaylistsOpen)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local textLabel = "Boombox"
local waveImageAssetId = "rbxassetid://15681938375"

local xPos = Common.calcualteXPosition(ElementSizes.WIDTH.BUTTON)

local button = New("Frame")({
	Name = "BoomboxButton",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.4,
	Position = UDim2.fromOffset(xPos, 0),
	Size = UDim2.fromOffset(ElementSizes.WIDTH.BUTTON, 32),

	[Children] = {
		New("UICorner")({
			CornerRadius = UDim.new(0.35, 0),
		}),
		New("UIPadding")({
			PaddingBottom = UDim.new(0.027, 0),
			PaddingLeft = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.03, 0),
			PaddingTop = UDim.new(0.027, 0),
		}),
		New("TextButton")({
			Name = "BoomboxGroup",
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.fromOffset(150, 32),

			[OnEvent("Activated")] = function()
				PlaylistsOpen:toggle()
			end,

			[Children] = {
				New("UIListLayout")({
					Padding = UDim.new(0, 0.5),
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				New("ImageLabel")({
					Name = "Icon",
					Image = waveImageAssetId,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(50, 32),
				}),
				New("TextLabel")({
					Name = "PlayPauseText",
					BackgroundTransparency = 1,
					Position = UDim2.new(1, 0, 0, 0),
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = textLabel,
					TextYAlignment = Enum.TextYAlignment.Top,
					Size = UDim2.fromOffset(100, 32),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					FontSize = Enum.FontSize.Size18,

					[Children] = {
						New("UIPadding")({
							PaddingTop = UDim.new(0.2, 0),
							PaddingRight = UDim.new(0.1, 0),
						}),
					},
				}),
			},
		}),
	},
})

local function BoomboxButton()
	return New("Frame")({
		BackgroundTransparency = 1,
		Name = "BoomboxButtonTopLevel",
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 1,
		Active = false,
		Visible = Fusion.Computed(function()
			return not MiniPlayerOpen:get()
		end),

		[Children] = {
			New("Frame")({
				BackgroundTransparency = 1,
				Name = "BoomboxButtonContainer",
				Size = UDim2.new(1, 0, 0, 32),
				ZIndex = 1,
				Active = false,

				[Children] = {
					button,
				},
			}),
		},
	})
end

return BoomboxButton
