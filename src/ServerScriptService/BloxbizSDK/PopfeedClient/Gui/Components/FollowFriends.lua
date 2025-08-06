local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local ActionButton = require(GuiComponents.ActionButton)
local FollowFriendsEntry = require(GuiComponents.FollowFriendsEntry)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

local function pagesToTable(pages)
	local items = {}
	while true do
		table.insert(items, pages:GetCurrentPage())

		if pages.IsFinished then
			break
		end

		pages:AdvanceToNextPageAsync()
	end
	return items
end

local function iterPageItems(pages)
	local contents = pagesToTable(pages)

	local pageNum = 1
	local lastPageNum = #contents

	return coroutine.wrap(function()
		while pageNum <= lastPageNum do
			for _, item in contents[pageNum] do
				coroutine.yield(item, pageNum)
			end
			pageNum += 1
		end
	end)
end

local cachedFriends

local function getPlayersFriends()
	if not cachedFriends then
		cachedFriends = {}

		for item in iterPageItems(Players:GetFriendsAsync(LocalPlayer.UserId)) do
			table.insert(cachedFriends, item)
		end
	end

	return cachedFriends
end

return function(props)
	local scrollingFrame = Value()
	local friendsUIListLayout = Value()

	local friendsList = Value({})

	task.spawn(function()
		local friends = getPlayersFriends()
		friendsList:set(friends)

		task.wait()

		task.defer(function()
			local layout = friendsUIListLayout:get()
			local scrollFrame = scrollingFrame:get()

			if not layout or not scrollFrame then
				return
			end

			scrollFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, 0)
		end)
	end)

	return New("Frame")({
		Name = "FollowFriends",
		Size = props.Size,
		LayoutOrder = props.LayoutOrder,
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundTransparency = 1,

		[Children] = {
			New("Frame")({
				Name = "TitleContainer",
				Size = UDim2.fromScale(1, 0.0675),
				Position = UDim2.fromScale(0, 0.03),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,

				[Children] = {
					ActionButton({
						Name = "Title",
						Text = "Follow Roblox Friends",
						Icon = "rbxassetid://13468517870",
						IconSize = UDim2.fromScale(0.75, 0.75),
						MiddleOffset = 0.1,
						Padding = 0.015,
						Font = font,
					}),
				},
			}),

			New("ScrollingFrame")({
				Name = "List",
				Size = UDim2.fromScale(1, 0.695),
				Position = UDim2.fromScale(0, 0.2),
				CanvasSize = UDim2.fromScale(2, 0),
				ScrollingDirection = Enum.ScrollingDirection.X,
				ScrollBarThickness = 10,
				ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,

				[Ref] = scrollingFrame,

				[Children] = {
					New("Frame")({
						Name = "Container",
						Size = UDim2.new(3.24, 0, 1, -16),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						BackgroundTransparency = 1,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0, 5),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Left,

								[Ref] = friendsUIListLayout,
							}),

							ForPairs(friendsList, function(index, entryData)
								return index, FollowFriendsEntry(props.FeedProps, entryData)
							end, Fusion.cleanup),
						},
					}),
				},
			}),

			Line({
				Size = props.LineSize,
				Position = UDim2.fromScale(0.5, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
		},
	})
end
