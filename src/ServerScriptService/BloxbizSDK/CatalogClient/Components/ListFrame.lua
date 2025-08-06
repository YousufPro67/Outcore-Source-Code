local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local function ScrollingFrame(filterBarCompensation: boolean?, presetGridLayout: UIGridLayout?): ScrollingFrame
	local size = UDim2.fromScale(1, 1)
	local cellSize = UDim2.fromScale(0.243, filterBarCompensation and 0.3 or 0.3)

	local uiGridLayout = presetGridLayout
		or New("UIGridLayout")({
			Name = "UIGridLayout",
			CellPadding = UDim2.fromScale(0.009, 0.012),
			CellSize = cellSize,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

	local scrollingFrame = New("ScrollingFrame")({
		Name = "ItemFrame",
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0),
		Size = size,
	})

	local frame = New("Frame")({
		Name = "Frame",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,

		[Children] = {
			uiGridLayout,
		},

		[OnEvent("ChildAdded")] = function()
			task.defer(function()
				scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiGridLayout.AbsoluteContentSize.Y)
			end)
		end,
	})
	frame.Parent = scrollingFrame

	return scrollingFrame, frame
end

return function(
	name: string?,
	filterBarCompensation: boolean?,
	skipListLayout: boolean?,
	presetGridLayout: UIGridLayout?
): (Frame, Frame, Frame)
	local scrollingFrame, itemFrame = ScrollingFrame(filterBarCompensation, presetGridLayout)

	local layout = not skipListLayout
		and New("UIListLayout")({
			Name = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

	local main = New("Frame")({
		Name = name or "Frame",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Selectable = false,
		Size = UDim2.fromScale(1, 1),

		[Children] = {
			layout,

			scrollingFrame,
		},
	})

	return main, scrollingFrame, itemFrame
end
