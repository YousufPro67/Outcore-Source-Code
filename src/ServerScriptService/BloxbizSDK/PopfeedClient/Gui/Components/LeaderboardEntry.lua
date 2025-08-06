local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local GuiComponents = Gui.Components
local ActionButton = require(GuiComponents.ActionButton)

local nameFont = Font.fromEnum(Enum.Font.Arial)
local displayNameFont = Font.fromEnum(Enum.Font.Arial)
displayNameFont.Bold = true

return function(props, index, entryData)
	local playerInfo = props.cachedUserInfos[entryData.UserId]

	return {
		New("TextButton")({
			Name = "LeaderboardEntry",
			Size = UDim2.fromScale(1, 0.2),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 1,
			AutoButtonColor = false,

			[OnEvent("Activated")] = function()
				props.OnSwitchFeedClicked(props.initialProfileFeed, entryData.UserId)
			end,

			[Children] = {
				New("Frame")({
					Name = "Container",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(63, 63, 63),

					[Children] = {
						ActionButton({
							Name = "Amount",
							Icon = entryData.Icon,
							Text = entryData.Text,
							IconSize = UDim2.fromScale(0.75, 0.75),
							Size = UDim2.fromScale(0, 0.35),
							Position = UDim2.fromScale(0.97, 0.5),
							AnchorPoint = Vector2.new(1, 0.5),
							MiddleOffset = 0.15,
							Padding = 0.015,
							Font = displayNameFont,
						}),

						New("TextLabel")({
							Name = "Number",
							Text = "#" .. index,
							Size = UDim2.fromScale(0.05, 0.275),
							Position = UDim2.fromScale(0.03, 0.5),
							AnchorPoint = Vector2.new(0, 0.5),
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextXAlignment = Enum.TextXAlignment.Center,
							--AutomaticSize = Enum.AutomaticSize.X,
							BackgroundTransparency = 1,
							TextScaled = true,
							FontFace = displayNameFont,
						}),

						New("Frame")({
							Name = "Info",
							Size = UDim2.fromScale(0, 0.125),
							Position = UDim2.fromScale(0.11, 0.5),
							AnchorPoint = Vector2.new(0, 0.5),
							AutomaticSize = Enum.AutomaticSize.X,
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							BackgroundTransparency = 1,

							[Children] = {
								New("Frame")({
									Name = "Container",
									Size = UDim2.fromScale(0, 1),
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,

									[Children] = {
										New("UIListLayout")({
											SortOrder = Enum.SortOrder.LayoutOrder,
											FillDirection = Enum.FillDirection.Horizontal,
											VerticalAlignment = Enum.VerticalAlignment.Center,
										}),

										New("ImageLabel")({
											Name = "ProfilePicture",
											Size = UDim2.fromScale(0.875, 0.875),
											SizeConstraint = Enum.SizeConstraint.RelativeYY,
											Image = props.GetUserProfilePicture(entryData.UserId),
											BackgroundTransparency = 1,
											ZIndex = 2,
											LayoutOrder = 1,

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

										New("Frame")({
											Name = "BlankSpace",
											Size = UDim2.fromScale(0.04, 0),
											BackgroundTransparency = 1,
											LayoutOrder = 2,
										}),

										New("Frame")({
											Name = "Names",
											Size = UDim2.fromScale(0.5, 0.75),
											BackgroundTransparency = 1,
											LayoutOrder = 3,

											[Children] = {
												New("UIListLayout")({
													Padding = UDim.new(0.04, 0),
													SortOrder = Enum.SortOrder.LayoutOrder,
													FillDirection = Enum.FillDirection.Vertical,
													VerticalAlignment = Enum.VerticalAlignment.Center,
												}),

												New("TextLabel")({
													Name = "DisplayName",
													Text = playerInfo.DisplayName,
													Size = UDim2.fromScale(0, 0.5),
													TextColor3 = Color3.fromRGB(255, 255, 255),
													TextXAlignment = Enum.TextXAlignment.Left,
													BackgroundTransparency = 1,
													LayoutOrder = 1,
													TextScaled = true,
													FontFace = displayNameFont,
													AutomaticSize = Enum.AutomaticSize.X,
												}),

												New("TextLabel")({
													Name = "Username",
													Text = "@" .. playerInfo.Username,
													Size = UDim2.fromScale(0, 0.5),
													TextColor3 = Color3.fromRGB(134, 134, 134),
													TextXAlignment = Enum.TextXAlignment.Left,
													BackgroundTransparency = 1,
													LayoutOrder = 2,
													TextScaled = true,
													FontFace = nameFont,
													AutomaticSize = Enum.AutomaticSize.X,
												}),
											},
										}),
									},
								}),
							},
						}),

						New("UICorner")({
							CornerRadius = UDim.new(0.1, 0),
						}),
					},
				}),
			},
		}),
	}
end
