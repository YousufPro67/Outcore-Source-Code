local Players = game:GetService("Players")

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

local GuiComponents = Gui.Components
local SelectButton = require(GuiComponents.SelectButton)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

local followingCache = {}

return function(props, friendData)
	local isReadOnly = props.Config.permissions == "read_only"

	local id = friendData.Id

	local isFollowing = Value(followingCache[id] == true)

	return New("TextButton")({
		Size = UDim2.fromScale(0.25, 1),
		BackgroundColor3 = Color3.fromRGB(63, 63, 63),

		[OnEvent("Activated")] = function()
			props.OnSwitchFeedClicked(props.initialProfileFeed, id)
		end,

		[Children] = {
			New("ImageLabel")({
				Name = "ProfilePicture",
				Size = UDim2.fromScale(0.4, 0.4),
				Position = UDim2.fromScale(0.1, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Image = props.GetUserProfilePicture(id),
				BackgroundTransparency = 1,
				ZIndex = 2,

				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					New("Frame")({
						Name = "Background",
						Position = UDim2.new(0, 0, 0, -1),
						Size = UDim2.fromScale(1, 1),
						ZIndex = 1,

						[Children] = New("UICorner")({
							CornerRadius = UDim.new(1, 0),
						}),
					}),
				},
			}),

			New("TextLabel")({
				Name = "DisplayName",
				Text = friendData.DisplayName,
				Size = UDim2.fromScale(0.8, 0.14),
				Position = UDim2.fromScale(0.5, 0.55),
				AnchorPoint = Vector2.new(0.5, 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				TextScaled = true,
				FontFace = font,
				AutomaticSize = Enum.AutomaticSize.X,
			}),

			SelectButton({
				Name = "Follow",
				Size = UDim2.fromScale(0, 0.14),
				Position = UDim2.fromScale(0.1, 0.775),
				Color = Color3.fromRGB(85, 170, 255),
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Left,
				Bold = true,

				Text = Computed(function()
					return isFollowing:get() and "Following" or "Follow"
				end),

				OnActivated = function()
					if isReadOnly then
						props.EnablePopupMessage:set(true)
						return
					end

					if followingCache[id] then
						return
					end

					props.OnFollowButtonClicked(id, true)
					followingCache[id] = true
					isFollowing:set(true)
				end,
			}),

			New("UICorner")({
				CornerRadius = UDim.new(0, 8),
			}),
		},
	})
end
