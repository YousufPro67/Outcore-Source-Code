local UserService = game:GetService("UserService")

local PopfeedClient = script.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)

local NOTI_INFO = {
	like = {
		Image = "rbxassetid://12721083010",
		Postfix = "liked your post",
	},
	follow = {
		Image = "rbxassetid://12721082910",
		Postfix = "followed you",
	},
	comment = {
		Image = "rbxassetid://12721083707",
		Postfix = "replied to your post",
	},
	donation = {
		Image = "rbxassetid://9764949186",
		Postfix = "donated <b>%d Robux</b> to you",
	},
}

local PREVIEW_PROFILE_IMAGE_COUNT = 3

return function(props)
	local info = NOTI_INFO[props.type]
	if not info then
		return New("ImageButton")({
			Visible = false,
		})
	end

	local images = {}
	table.insert(images, { userId = 0, url = info.Image })

	local usersWithDataCount = #props.player_ids
	local usersTotalCount = props.count
	local imageCount = math.max(0, usersWithDataCount - PREVIEW_PROFILE_IMAGE_COUNT)

	for i = 1, math.min(usersWithDataCount, PREVIEW_PROFILE_IMAGE_COUNT) do
		local userId = props.player_ids[i]
		local url = props.FeedProps.GetUserProfilePicture(userId)
		table.insert(images, { userId = userId, url = url })
	end

	local text = props.topUserInfo.DisplayName
	if usersTotalCount == 2 then
		text = text .. " and 1 other"
	elseif usersTotalCount > 2 then
		text = text .. " and " .. usersTotalCount - 1 .. " others"
	end

	local previewPictures = Value(images)

	local function initiatePicture(image)
		local isActionIcon = image.url == info.Image

		return New("ImageButton")({
			Name = isActionIcon and "ActionIcon" or "ProfilePicture",
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ZIndex = 2,
			Image = image.url,

			[OnEvent("Activated")] = isActionIcon and Fusion.doNothing or function()
				props.FeedProps.OnSwitchFeedClicked(props.FeedProps.initialProfileFeed, image.userId)
			end,

			[Children] = isActionIcon and {} or {
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
		})
	end

	local nameFont = Font.fromEnum(Enum.Font.Arial)
	local displayNameFont = Font.fromEnum(Enum.Font.Arial)
	displayNameFont.Bold = true

	return New("ImageButton")({
		Name = props.Id or "Notification",
		Size = UDim2.fromScale(1, 0.2),
		ImageTransparency = 1,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoLocalize = false,
		LayoutOrder = -1,

		[OnEvent("Activated")] = function()
			if props.type == "comment" or props.type == "like" then
				props.FeedProps.OnSwitchFeedClicked("replies", props.post_id)
			else
				props.FeedProps.OnSwitchFeedClicked(props.FeedProps.initialProfileFeed, props.player_ids[1])
			end
		end,

		[Children] = {
			New("UIListLayout")({
				Padding = UDim.new(0.01, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			}),

			New("Frame")({
				Name = "BlankSpace",
				Size = UDim2.fromScale(1, 0.018),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}),

			New("Frame")({
				Name = "UserDisplay",
				Size = UDim2.fromScale(1, 0.08),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 2,

				[Children] = {
					New("Frame")({
						Name = "Container",
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						BackgroundTransparency = 1,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.02, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),

							ForValues(previewPictures, initiatePicture, Fusion.cleanup),

							--[[ New "TextLabel" {
                                Name = "Count",
                                Text = imageCount > 0 and "+" .. imageCount or "",
                                Size = UDim2.fromScale(0.6, 0.6),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                TextScaled = true,
                                FontFace = displayNameFont,
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 1,
                            },]]
						},
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				Size = UDim2.fromScale(1, 0.01),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}),

			New("Frame")({
				Name = "ActionUser",
				Size = UDim2.fromScale(1, 0.045),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 4,

				[Children] = {
					New("Frame")({
						Name = "Container",
						Size = UDim2.fromScale(0.85, 1),
						Position = UDim2.fromScale(0.095, 0),
						BackgroundTransparency = 1,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.008, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),

							New("TextButton")({
								Name = "Users",
								Text = text,
								Size = UDim2.fromScale(0, 1),
								AutomaticSize = Enum.AutomaticSize.X,
								TextScaled = true,
								FontFace = displayNameFont,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								LayoutOrder = 1,

								[OnEvent("Activated")] = function()
									--print("Clicked on users")
								end,
							}),

							New("TextLabel")({
								Name = "Action",
								Text = Computed(function()
									if props.type == "donation" then
										return string.format(info.Postfix, tonumber(props.robux))
									else
										return info.Postfix
									end
								end),
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0, 1),
								TextScaled = true,
								RichText = true,
								FontFace = nameFont,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								LayoutOrder = 2,
								AutomaticSize = Enum.AutomaticSize.X,
							}),
						},
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				Size = UDim2.fromScale(1, 0.01),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 5,
			}),

			New("Frame")({
				Name = "Content",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 6,
				Visible = not not props.post_text,

				[Children] = {
					New("TextLabel")({
						Name = "Message",
						Size = UDim2.fromScale(0.81, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						BackgroundTransparency = 1,
						Text = props.post_text,
						TextWrapped = true,
						TextSize = workspace.CurrentCamera.ViewportSize.Y / 37,
						FontFace = nameFont,
						TextColor3 = Color3.fromRGB(135, 132, 138),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						AutomaticSize = Enum.AutomaticSize.Y,
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				Size = UDim2.fromScale(1, 0.025),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 7,
			}),

			Line({
				LayoutOrder = 8,
				Size = UDim2.fromScale(1, 0.004),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			}),
		},
	})
end
