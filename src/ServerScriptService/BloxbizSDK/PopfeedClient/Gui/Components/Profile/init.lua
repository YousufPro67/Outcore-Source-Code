local Players = game:GetService("Players")
local UserService = game:GetService("UserService")

local PopfeedClient = script.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local ActionButton = require(GuiComponents.ActionButton)

local LocalPlayer = Players.LocalPlayer

local selectedButton = Value()
local previousLoadedUserId = 0

return function(props)
	local isReadOnly = props.Config.permissions == "read_only"

	local profileData = props.CurrentProfileData:get()
	local profileInfo = UserService:GetUserInfosByUserIdsAsync({ props.CurrentViewingProfileId:get() })[1]

	if profileInfo.Id ~= previousLoadedUserId then
		selectedButton:set()
		previousLoadedUserId = profileInfo.Id
	end

	--local donationsEmpty = #profileData.donations == 0
	local shopItemsEmpty = #profileData.shop_items == 0

	if not profileInfo then
		return
	end

	local nameFont = Font.fromEnum(Enum.Font.Arial)
	local displayNameFont = Font.fromEnum(Enum.Font.Arial)
	displayNameFont.Bold = true

	local userName = "@" .. profileInfo.Username
	local displayName = profileInfo.DisplayName

	local followers = profileData.follower_count
	local following = profileData.following_count
	local robuxDonated = profileData.robux_donated
	local robuxRaised = profileData.robux_raised

	local profileTabNamesInOrder = {}
	for _, tabString in props.Config.profile_tab_order do
		local feedIdInTabString = string.match(tabString, ":[%s]*(.-)[%s]*$")

		--[[if donationsEmpty and feedIdInTabString == "donations" then
			continue
		end]]

		if shopItemsEmpty and feedIdInTabString == "shop" then
			continue
		end

		for _, feedData in props.ProfileFeeds do
			if feedIdInTabString ~= feedData.id then
				continue
			end

			table.insert(profileTabNamesInOrder, feedData)
		end
	end

	local followButtonVisible = LocalPlayer.UserId ~= props.CurrentViewingProfileId:get()
	local isFollowing = Value(props.IsFollowing)

	task.defer(function()
		if not selectedButton:get() then
			selectedButton:set(profileTabNamesInOrder[1].id)
		end
	end)

	local uIListLayout = Value()
	local navScrollingFrame = Value()

	task.defer(function()
		task.wait()

		local layout = uIListLayout:get()
		local scrollFrame = navScrollingFrame:get()

		scrollFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, 0)
	end)

	return New("Frame")({
		Name = "Profile",
		Size = UDim2.fromScale(0.95, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = -math.huge,

		[Children] = {
			New("UIListLayout")({
				Padding = UDim.new(0.04, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(0, 0.035),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}),

			New("Frame")({
				Name = "Info",
				Size = UDim2.fromScale(1, 0.14),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 2,

				[Children] = {
					New("Frame")({
						Name = "Container",
						Size = UDim2.fromScale(1, 1),
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
								Image = props.GetUserProfilePicture(profileInfo.Id),
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
										Text = displayName,
										Size = UDim2.fromScale(1, 0.5),
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextXAlignment = Enum.TextXAlignment.Left,
										BackgroundTransparency = 1,
										LayoutOrder = 1,
										TextScaled = true,
										FontFace = displayNameFont,
									}),

									New("TextLabel")({
										Name = "Username",
										Text = userName,
										Size = UDim2.fromScale(1, 0.5),
										TextColor3 = Color3.fromRGB(134, 134, 134),
										TextXAlignment = Enum.TextXAlignment.Left,
										BackgroundTransparency = 1,
										LayoutOrder = 2,
										TextScaled = true,
										FontFace = nameFont,
									}),
								},
							}),
						},
					}),

					ActionButton({
						Name = "FollowButton",
						Size = UDim2.fromScale(0, 0.56),
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),

						Padding = 0.015,
						BackOffset = 0.4,
						FrontOffset = 0.4,
						MiddleOffset = 0.1,

						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor = Color3.fromRGB(0, 170, 255),

						Text = Computed(function()
							if isFollowing:get() == true then
								return "Following"
							else
								return "Follow"
							end
						end),
						TextSize = UDim2.fromScale(0, 0.6),
						Font = displayNameFont,

						Icon = Computed(function()
							if isFollowing:get() == true then
								return "rbxassetid://13479450009"
							else
								return "rbxassetid://13479598082"
							end
						end),
						IconSize = UDim2.fromScale(0.6, 0.6),

						Visible = followButtonVisible,

						OnActivated = function()
							if isReadOnly then
								props.EnablePopupMessage:set(true)
								return
							end

							local follows = isFollowing:get() == true

							if follows then
								props.OnFollowButtonClicked(props.CurrentViewingProfileId:get(), false)
								isFollowing:set(false)
							else
								props.OnFollowButtonClicked(props.CurrentViewingProfileId:get(), true)
								isFollowing:set(true)
							end
						end,
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(0, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}),

			New("Frame")({
				Name = "FollowCounters",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.08),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = 5,

				[Children] = {
					New("UIListLayout")({
						Padding = UDim.new(0.02, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					ActionButton({
						Name = "Following",

						Padding = 0.015,
						BackOffset = 0.2,
						FrontOffset = 0.2,
						MiddleOffset = 0.1,

						LayoutOrder = 1,
						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor = Color3.fromRGB(55, 56, 56),

						Text = "<font color='rgb(255, 255, 255)'><b>" .. following .. "</b></font> Following",
						TextSize = UDim2.fromScale(0, 0.6),
						TextColor = Color3.fromRGB(200, 200, 200),

						Icon = "rbxassetid://13468517870",
						IconSize = UDim2.fromScale(0.6, 0.6),

						OnActivated = function()
							props.OnFollowingButtonClicked(profileData.user_id, 1)
							props.UserListVisible:set(true)
						end,
					}),

					ActionButton({
						Name = "Followers",

						Padding = 0.015,
						BackOffset = 0.2,
						FrontOffset = 0.2,
						MiddleOffset = 0.1,

						LayoutOrder = 1,
						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor = Color3.fromRGB(55, 56, 56),

						Text = "<font color='rgb(255, 255, 255)'><b>" .. followers .. "</b></font> Followers",
						TextSize = UDim2.fromScale(0, 0.6),
						TextColor = Color3.fromRGB(200, 200, 200),

						Icon = "rbxassetid://13468517870",
						IconSize = UDim2.fromScale(0.6, 0.6),

						OnActivated = function()
							props.OnFollowersButtonClicked(profileData.user_id, 1)
							props.UserListVisible:set(true)
						end,
					}),
				},
			}),
			New("Frame")({
				Name = "DonateCounters",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.08),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = 6,

				[Children] = {
					New("UIListLayout")({
						Padding = UDim.new(0.02, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					ActionButton({
						Name = "Donated",

						Padding = 0.015,
						BackOffset = 0.2,
						FrontOffset = 0.2,
						MiddleOffset = 0.1,

						LayoutOrder = 1,
						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor = Color3.fromRGB(55, 56, 56),

						Text = "<font color='rgb(255, 255, 255)'><b>" .. robuxDonated .. "</b></font> Donated",
						TextSize = UDim2.fromScale(0, 0.6),
						TextColor = Color3.fromRGB(200, 200, 200),

						Icon = "rbxassetid://13468488252",
						IconSize = UDim2.fromScale(0.6, 0.6),

						OnActivated = function() end,
					}),

					ActionButton({
						Name = "Followers",

						Padding = 0.015,
						BackOffset = 0.2,
						FrontOffset = 0.2,
						MiddleOffset = 0.1,

						LayoutOrder = 1,
						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor = Color3.fromRGB(55, 56, 56),

						Text = "<font color='rgb(255, 255, 255)'><b>" .. robuxRaised .. "</b></font> Earned",
						TextSize = UDim2.fromScale(0, 0.6),
						TextColor = Color3.fromRGB(200, 200, 200),

						Icon = "rbxassetid://13468488252",
						IconSize = UDim2.fromScale(0.6, 0.6),

						OnActivated = function() end,
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(0, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 7,
			}),

			New("ScrollingFrame")({
				Name = "Navigation",
				Size = UDim2.fromScale(1, 0.1),
				Position = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(1, 1),
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.X,
				BackgroundTransparency = 1,
				LayoutOrder = 8,

				[Ref] = navScrollingFrame,

				[Children] = {
					New("Frame")({
						Name = "Container",
						Size = UDim2.fromScale(17.956, 0.65),
						Position = UDim2.fromScale(0, 0.5),
						AnchorPoint = Vector2.new(0, 0.5),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						BackgroundTransparency = 1,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.07, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,

								[Ref] = uIListLayout,
							}),

							ForValues(profileTabNamesInOrder, function(tabData)
								return New("TextButton")({
									Name = tabData.id,
									Text = tabData.name,
									Size = UDim2.fromScale(0, 1),
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,
									--TextScaled = true,
									--RichText = true,
									TextSize = props.IsVertical:get() and workspace.CurrentCamera.ViewportSize.Y / 50 or workspace.CurrentCamera.ViewportSize.Y / 40,
									FontFace = displayNameFont,

									TextColor3 = Computed(function()
										local selected = selectedButton:get()
										if selected == tabData.id then
											return Color3.fromRGB(255, 255, 255)
										else
											return Color3.fromRGB(134, 134, 134)
										end
									end),

									[OnEvent("Activated")] = function()
										selectedButton:set(tabData.id)

										props.LastLoadedProfileTab = tabData.id
										props.OnSwitchFeedClicked(tabData.id, profileInfo.Id)
									end,
								})
							end, Fusion.cleanup),
						},
					}),
				},
			}),

			Line({
				Size = UDim2.fromScale(1.11, 0.004),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = 9,
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(0, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 10,
			}),
		},
	})
end
