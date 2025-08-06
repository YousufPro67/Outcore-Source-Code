local Players = game:GetService("Players")

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local GuiComponents = Gui.Components
local IconButton = require(GuiComponents.IconButton)

local LocalPlayer = Players.LocalPlayer

return function(props)
	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = true

	local mainFeeds = props.Config.feeds.main

	local bottomFeeds = {
		{
			Id = "home",
			Name = "Home",
			Icon = "rbxassetid://13367821505",
		},
		{
			Id = "explore",
			Name = "Explore",
			Icon = "rbxassetid://14299332292",
			IconSize = 0.8,
		},
		{
			Id = "notifications",
			Name = "Notifications",
			Icon = "rbxassetid://13367818387",
		},
		{
			Id = props.initialProfileFeed,
			Name = "Profile",
			Icon = "rbxassetid://13367820770",
		},
	}

	local function addNotificationCount()
		return New("ImageLabel")({
			Name = "Notice",
			Size = UDim2.fromScale(0.4, 0.4),
			Position = UDim2.fromScale(0.575, 0.28),
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = "rbxassetid://12776995467",
			ImageColor3 = Color3.fromRGB(224, 83, 83),
			Visible = Computed(function()
				return props.NotificationCount:get() > 0
			end),
			ZIndex = 3,

			[Children] = {
				New("TextLabel")({
					Name = "Count",
					Text = Computed(function()
						return props.NotificationCount:get()
					end),
					Size = UDim2.fromScale(0.9, 0.9),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					TextScaled = true,
					FontFace = font,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					ZIndex = 4,
				}),
			},
		})
	end

	local function insertFeed(feedsTable, feed, index)
		table.insert(
			feedsTable,
			IconButton({
				Name = feed.Name,
				Text = "",
				Icon = feed.Icon,
				IconSize = feed.IconSize or 0.7,
				IconPositionX = 0.5,
				LabelPositionX = 0,
				IconAnchorPointX = 0.5,
				CornerRadius = UDim.new(0, 8),
				LayoutOrder = index,
				Size = UDim2.fromScale(0.225, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundColor = Color3.fromRGB(63, 63, 63),
				SelectedBackgroundColor = Color3.fromRGB(255, 255, 255),
				SelectedIconColor = Color3.fromRGB(255, 255, 255),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,

				Selected = Computed(function()
					local update = props.UpdateHomeButtons:get()
					if props.DisableHomeButtons then
						return false
					end

					local currentFeed = props.CurrentFeedTypeValue:get()
					local lastBottomBtnFeed = props.LastBottomBtnPress:get()

					currentFeed = lastBottomBtnFeed or currentFeed
					currentFeed = (props.isProfileFeed(currentFeed) and props.initialProfileFeed) or currentFeed

					for _, feedInfo in mainFeeds do
						if feedInfo.id == currentFeed then
							currentFeed = "home"
							break
						end
					end

					if currentFeed == feed.Id then
						return true
					else
						return false
					end
				end),

				OnActivated = function()
					props.LastBottomBtnPress:set(feed.Id)

					if feed.Id == props.initialProfileFeed then
						props.OnSwitchFeedClicked(props.initialProfileFeed, LocalPlayer.UserId, true)
					else
						props.OnSwitchFeedClicked(feed.Id, nil, true)
					end
				end,

				[Children] = {
					feed.Id == "notifications" and addNotificationCount() or nil,
				},
			})
		)
	end

	local function fillFeeds()
		local feedsTable = {}

		for index, feedInfo in bottomFeeds do
			insertFeed(feedsTable, feedInfo, index)
		end

		return feedsTable
	end

	return {
		New("Frame")({
			Name = "Menu",
			Size = UDim2.fromScale(0.95, 0.791),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,

			[Children] = {
				New("UIListLayout")({
					Padding = UDim.new(0.019, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),

				fillFeeds(),
			},
		}),
	}
end
