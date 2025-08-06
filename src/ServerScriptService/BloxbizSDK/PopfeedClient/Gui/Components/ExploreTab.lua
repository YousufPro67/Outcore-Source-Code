local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local LocalPlayer = Players.LocalPlayer

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local TextButton = require(GuiComponents.TextButton)
local ActionButton = require(GuiComponents.ActionButton)
local FollowFriends = require(GuiComponents.FollowFriends)
local LeaderboardEntry = require(GuiComponents.LeaderboardEntry)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

local canSeeCommunityLink

local function canViewCommunityLink()
	if canSeeCommunityLink ~= nil then
		return canSeeCommunityLink
	end

	local success, result = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(LocalPlayer)
	end)

	if success then
		canSeeCommunityLink = not not table.find(result.AllowedExternalLinkReferences, "Discord")
	end

	return canSeeCommunityLink
end

return function(props, cachedPosition)
	local isMobile = props.IsVertical:get()

	local currentLoadedPage = {
		top_donors = 1,
		top_boosters = 1,
	}

	props.ExploreTabScrollingFrame = Value()

	local uIListLayout = Value()

	task.defer(function()
		task.wait()
		props.ExploreTabScrollingFrame:get().CanvasPosition = cachedPosition or Vector2.zero
	end)

	return {
		New("ScrollingFrame")({
			Name = "ExploreTabList",
			Size = UDim2.fromScale(1, 0.81),
			Position = UDim2.fromScale(0.5, 0.1),
			AnchorPoint = Vector2.new(0.5, 0),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			ClipsDescendants = true,

			[Ref] = props.ExploreTabScrollingFrame,

			[Children] = {
				New("TextLabel")({
					Text = "No results.\nOnly exact match usernames work.",
					Size = UDim2.fromScale(0.7, 0.036),
					Position = UDim2.fromScale(0.5, 0.02),
					AnchorPoint = Vector2.new(0.5, 0),
					FontFace = font,
					TextScaled = true,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),

					Visible = Computed(function()
						return props.UserSearchFailed:get()
					end),
				}),

				New("Frame")({
					Name = "Content",
					Size = UDim2.fromScale(1, 0.692),
					Position = UDim2.fromScale(0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					BackgroundTransparency = 1,

					Visible = Computed(function()
						return not props.UserSearchFailed:get()
					end),

					[Children] = {
						New("UIListLayout")({
							Padding = UDim.new(0.01, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
							FillDirection = Enum.FillDirection.Vertical,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,

							[Ref] = uIListLayout,
						}),

						FollowFriends({
							FeedProps = props,
							LayoutOrder = 3,
							Size = UDim2.fromScale(0.9, 0.43),
							LineSize = UDim2.fromScale(1.2, 0.005),
						}),

						New("Frame")({
							Name = "TopBoosters",
							Size = UDim2.fromScale(0.9, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							LayoutOrder = 4,

							[Children] = {
								New("UIListLayout")({
									Padding = UDim.new(0, 5),
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Vertical,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.018),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 1,
								-- }),

								New("Frame")({
									Name = "TitleContainer",
									Size = UDim2.fromScale(1, 0.0675),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									BackgroundTransparency = 1,
									LayoutOrder = 2,

									[Children] = {
										ActionButton({
											Name = "Title",
											Text = "Top Boosters This Week",
											Icon = "rbxassetid://13468295672",
											IconSize = UDim2.fromScale(0.75, 0.75),
											MiddleOffset = 0.1,
											Padding = 0.015,
											Font = font,
										}),
									},
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.01),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 3,
								-- }),

								New("Frame")({
									Name = "List",
									Size = UDim2.fromScale(1, 0),
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundTransparency = 1,
									LayoutOrder = 4,

									[Children] = {
										New("UIListLayout")({
											SortOrder = Enum.SortOrder.LayoutOrder,
											FillDirection = Enum.FillDirection.Vertical,
											HorizontalAlignment = Enum.HorizontalAlignment.Center,
											Padding = UDim.new(0, 5),
										}),

										ForPairs(props.ExplorePageContent.top_boosters, function(index, entryData)
											local data = {
												Icon = "rbxassetid://13468295672",
												Text = entryData.boost_count,
												UserId = entryData.player_id,
											}

											return index, LeaderboardEntry(props, index, data)
										end, Fusion.cleanup),
									},
								}),

								TextButton({
									Name = "ShowMore",
									Text = "Show 3 more",
									Size = UDim2.fromScale(1, 0.09),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									TextColor = Color3.fromRGB(255, 255, 255),
									Color = Color3.fromRGB(63, 63, 63),
									CornerRadius = UDim.new(0, 8),
									LayoutOrder = 5,
									ZIndex = 1,
									Bold = true,

									OnActivated = function()
										local success =
											props.RenderExplorePage(currentLoadedPage.top_boosters + 1, "top_boosters")
										if success then
											currentLoadedPage.top_boosters += 1
										end
									end,
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.04),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 6,
								-- }),

								Line({
									Size = UDim2.fromScale(1.2, 0.005),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									LayoutOrder = 7,
								}),
							},
						}),

						New("Frame")({
							Name = "TopDonators",
							Size = UDim2.fromScale(0.9, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							LayoutOrder = 2,

							[Children] = {
								New("UIListLayout")({
									Padding = UDim.new(0, 5),
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Vertical,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.018),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 1,
								-- }),

								New("Frame")({
									Name = "TitleContainer",
									Size = UDim2.fromScale(1, 0.0675),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									BackgroundTransparency = 1,
									LayoutOrder = 2,

									[Children] = {
										ActionButton({
											Name = "Title",
											Text = "Top Donators This Week",
											Icon = "rbxassetid://13184649429",
											IconSize = UDim2.fromScale(0.75, 0.75),
											MiddleOffset = 0.1,
											Padding = 0.015,
											Font = font,
										}),
									},
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.01),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 3,
								-- }),

								New("Frame")({
									Name = "List",
									Size = UDim2.fromScale(1, 0),
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundTransparency = 1,
									LayoutOrder = 4,

									[Children] = {
										New("UIListLayout")({
											SortOrder = Enum.SortOrder.LayoutOrder,
											FillDirection = Enum.FillDirection.Vertical,
											HorizontalAlignment = Enum.HorizontalAlignment.Center,
											Padding = UDim.new(0, 5),
										}),

										ForPairs(props.ExplorePageContent.top_donors, function(index, entryData)
											local data = {
												Icon = "rbxassetid://13184649429",
												Text = entryData.robux_donated,
												UserId = entryData.player_id,
											}

											return index, LeaderboardEntry(props, index, data)
										end, Fusion.cleanup),
									},
								}),

								TextButton({
									Name = "ShowMore",
									Text = "Show 3 more",
									Size = UDim2.fromScale(1, 0.09),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									TextColor = Color3.fromRGB(255, 255, 255),
									Color = Color3.fromRGB(63, 63, 63),
									CornerRadius = UDim.new(0, 8),
									LayoutOrder = 5,
									ZIndex = 1,
									Bold = true,

									OnActivated = function()
										local success =
											props.RenderExplorePage(currentLoadedPage.top_donors + 1, "top_donors")
										if success then
											currentLoadedPage.top_donors += 1
										end
									end,
								}),

								-- New("Frame")({
								-- 	Name = "BlankSpace",
								-- 	SizeConstraint = Enum.SizeConstraint.RelativeXX,
								-- 	Size = UDim2.fromScale(1, 0.04),
								-- 	BackgroundTransparency = 1,
								-- 	LayoutOrder = 6,
								-- }),

								Line({
									Size = UDim2.fromScale(1.2, 0.005),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									LayoutOrder = 7,
								}),
							},
						}),

						canViewCommunityLink() and New("Frame")({
							Name = "Community",
							Size = UDim2.fromScale(0.9, 0.3),
							BackgroundTransparency = 1,
							LayoutOrder = 1,

							[Children] = {
								ActionButton({
									Name = "Title",
									Text = "Join the Community",
									Icon = "rbxassetid://13468517870",
									IconSize = UDim2.fromScale(0.75, 0.75),
									Size = UDim2.fromScale(0, 0.3),
									Position = UDim2.fromScale(0, 0.11),
									Font = font,

									Padding = 0.015,
									MiddleOffset = 0.1,
								}),

								New("Frame")({
									Size = UDim2.fromScale(1, 0.35),
									Position = UDim2.fromScale(0, 0.45),
									BackgroundColor3 = Color3.fromRGB(63, 63, 63),

									[Children] = {
										isMobile and New("TextLabel")({
											Text = props.Config.discord_link,
											Size = UDim2.fromScale(0, 0.525),
											Position = UDim2.fromScale(0.03, 0.5),
											AnchorPoint = Vector2.new(0, 0.5),
											FontFace = Font.fromEnum(Enum.Font.Arial),
											TextScaled = true,
											AutomaticSize = Enum.AutomaticSize.X,
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(255, 255, 255),
										}) or New("TextBox")({
											Text = props.Config.discord_link,
											Size = UDim2.fromScale(0, 0.525),
											Position = UDim2.fromScale(0.03, 0.5),
											AnchorPoint = Vector2.new(0, 0.5),
											FontFace = Font.fromEnum(Enum.Font.Arial),
											TextScaled = true,
											TextEditable = false,
											AutomaticSize = Enum.AutomaticSize.X,
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(255, 255, 255),
										}),

										New("UICorner")({
											CornerRadius = UDim.new(0, 8),
										}),
									},
								}),

								Line({
									Size = UDim2.fromScale(1.2, 0.02),
								}),
							},
						}) or nil,
					},
				}),
			},
		}),
	}
end
