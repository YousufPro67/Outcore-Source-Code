--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = script.Parent.Parent
local ScrollingFrame = require(Components.Generic.ScrollingFrame)
local UtilitiesHolder = require(script.Parent.Utilities)

type Utilities = UtilitiesHolder.Props
type ScrollingFrame = ScrollingFrame.Props

export type Props = {
	Name: string?,
	UtilitiesHolder: Utilities?,
	ScrollingFrame: ScrollingFrame?,
	SkipListLayout: boolean?,
}

return function(props: Props): Frame
	local utilitiesHolderCompensation = props.UtilitiesHolder == nil

	local utilitiesHolder = (props.UtilitiesHolder and UtilitiesHolder(props.UtilitiesHolder)) :: Instance
	local scrollingFrameProps: ScrollingFrame.Props = props.ScrollingFrame
		or {
			Size = UDim2.fromScale(1, utilitiesHolderCompensation and 1 or 1),
			Position = UDim2.fromScale(0.5, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			DragScrollDisabled = true,

			Layout = {
				Type = "UIGridLayout",
				FillDirection = Enum.FillDirection.Horizontal,

				Size = UDim2.fromScale(0.243, utilitiesHolderCompensation and 0.3 or 0.3),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim2.fromScale(0.009, 0.012),
			},
		}
	local scrollingFrame = ScrollingFrame(scrollingFrameProps)

	return Fusion.New("Frame")({
		Name = props.Name or "Frame",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Selectable = false,	
		Size = UDim2.fromScale(1, 1),

		[Fusion.Children] = {
			not props.SkipListLayout and Fusion.New("UIListLayout")({
				Name = "UIListLayout",
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			scrollingFrame,
			utilitiesHolder,
		},
	}) :: Frame
end
