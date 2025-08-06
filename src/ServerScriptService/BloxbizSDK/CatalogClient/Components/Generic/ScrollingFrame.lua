--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

export type Props = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2?,

	ScrollBarThickness: number?,
	ScrollingDirection: Enum.ScrollingDirection,

	Layout: {
		Type: "UIGridLayout" | "UIListLayout",
		Padding: UDim | UDim2,
		SortOrder: Enum.SortOrder,

		FillDirection: Enum.FillDirection,

		--Grid layout properties
		Size: UDim2?,
		StartCorner: Enum.StartCorner?,
		FillDirectionMaxCells: number?,

		HorizontalAlignment: Enum.HorizontalAlignment?,
		VerticalAlignment: Enum.VerticalAlignment?,
	},
	DragScrollDisabled: boolean?,
}

local function Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function ValidateInput(input: InputObject): boolean
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

	return isTouch or isClick
end

local function HoveringOverMainFrame(scrollingFrame: Fusion.Value<ScrollingFrame?>): boolean
	local guis = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)

	for _, gui in pairs(guis) do
		if gui == scrollingFrame:get() then
			return true
		end
	end

	return false
end

local function DragScroll(
	dragging: boolean,
	scrollingFrame: Fusion.Value<ScrollingFrame?>,
	yBased: boolean,
	delta: number,
	oldPosValue: number?
): (number, number)
	local newPosValue = yBased and Mouse.Y or Mouse.X

	local sf = scrollingFrame:get()
	if sf then
		if dragging and scrollingFrame then
			delta = newPosValue - (oldPosValue or newPosValue)
		else
			delta = Lerp(delta, 0, 0.05)
		end

		local vec2 = Vector2.new()
		if yBased then
			vec2 = Vector2.new(0, math.floor(sf.CanvasPosition.Y - delta))
		else
			vec2 = Vector2.new(math.floor(sf.CanvasPosition.X - delta), 0)
		end

		sf.CanvasPosition = vec2
	end

	return delta, newPosValue
end

local function ResizeScrollingFrame(
	scrollingFrame: Fusion.Value<ScrollingFrame?>,
	uiLayout: Fusion.Value<UIGridLayout | UIListLayout | nil>,
	yBased: boolean,
	resetCanvasPosition: boolean?
)
	local sf = scrollingFrame:get()
	local ugl = uiLayout:get()

	if sf and ugl then
		if resetCanvasPosition then
			sf.CanvasPosition = Vector2.new(0, 0)
		end

		if yBased then
			sf.CanvasSize = UDim2.new(0, 0, 0, ugl.AbsoluteContentSize.Y)
		else
			sf.CanvasSize = UDim2.new(0, ugl.AbsoluteContentSize.X, 0, 0)
		end
	end
end

return function(props: Props): ScrollingFrame
	local posValue: number? = nil
	local delta = 0
	local dragging = false

	local scrollingFrame: Fusion.Value<ScrollingFrame?> = Fusion.Value(nil)
	local uiLayout: Fusion.Value<UIGridLayout | UIListLayout | nil> = Fusion.Value(nil)
	local yBased = props.ScrollingDirection == Enum.ScrollingDirection.Y

	local automaticSizing = yBased and Enum.AutomaticSize.Y or Enum.AutomaticSize.X
	local sizeConstraint = yBased and Enum.SizeConstraint.RelativeXX or Enum.SizeConstraint.RelativeYY
	local touchEnabled = UserInputService.TouchEnabled

	local screenSizeUpdate = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.wait()

		ResizeScrollingFrame(scrollingFrame, uiLayout, yBased, false)
	end)

	local scrollingFrameId = HttpService:GenerateGUID()
	local runServiceBindName = "CategoryButtonScroll" .. scrollingFrameId

	local inputBegan
	local inputEnded

	if not props.DragScrollDisabled then
		inputBegan = UserInputService.InputBegan:Connect(function(input: InputObject)
			if ValidateInput(input) and HoveringOverMainFrame(scrollingFrame) then
				dragging = true
			end
		end)
	
		inputEnded = UserInputService.InputEnded:Connect(function(input: InputObject)
			if ValidateInput(input) then
				dragging = false
				posValue = nil
			end
		end)
	end

	if not touchEnabled and not props.DragScrollDisabled then
		RunService:BindToRenderStep(runServiceBindName, 1, function()
			delta, posValue = DragScroll(dragging, scrollingFrame, yBased, delta, posValue)
		end)
	end

	if props.Layout.Type == "UIGridLayout" then
		Fusion.New("UIGridLayout")({
			Name = props.Layout.Type,
			CellPadding = props.Layout.Padding,
			CellSize = props.Layout.Size,

			SortOrder = props.Layout.SortOrder,
			FillDirection = props.Layout.FillDirection,

			FillDirectionMaxCells = props.Layout.FillDirectionMaxCells or 5,
			StartCorner = props.Layout.StartCorner or Enum.StartCorner.TopLeft,

			HorizontalAlignment = props.Layout.HorizontalAlignment or Enum.HorizontalAlignment.Left,
			VerticalAlignment = props.Layout.VerticalAlignment or Enum.VerticalAlignment.Top,

			[Fusion.Ref] = uiLayout,
		})
	else
		Fusion.New("UIListLayout")({
			Name = props.Layout.Type,
			Padding = props.Layout.Padding,

			SortOrder = props.Layout.SortOrder,
			FillDirection = props.Layout.FillDirection,

			HorizontalAlignment = props.Layout.HorizontalAlignment or Enum.HorizontalAlignment.Left,
			VerticalAlignment = props.Layout.VerticalAlignment or Enum.VerticalAlignment.Top,

			[Fusion.Ref] = uiLayout,
		})
	end

	return Fusion.New("ScrollingFrame")({
		Name = "ScrollingFrame",
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = props.ScrollBarThickness or 0,
		AutomaticCanvasSize = automaticSizing,
		ScrollingDirection = props.ScrollingDirection,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = props.Position,
		Size = props.Size,
		Visible = props.Visible,

		[Fusion.Cleanup] = function()
			RunService:UnbindFromRenderStep(runServiceBindName)
			screenSizeUpdate:Disconnect()

			if not props.DragScrollDisabled then
				if inputBegan then
					inputBegan:Disconnect()
				end
				if inputEnded then
					inputEnded:Disconnect()
				end
			end
		end,

		[Fusion.Ref] = scrollingFrame,

		[Fusion.OnChange "CanvasPosition"] = props.OnCanvasPositionChange,

		[Fusion.Children] = {
			Fusion.New("Frame")({
				Name = "ItemFrame",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = sizeConstraint,

				[Fusion.Ref] = props[Fusion.Ref],

				[Fusion.Children] = {
					uiLayout:get(),
					props[Fusion.Children]
				},

				[Fusion.OnEvent("ChildAdded")] = function()
					task.defer(function()
						ResizeScrollingFrame(scrollingFrame, uiLayout, yBased, false)
					end)
				end,
			}),
		},
	}) :: ScrollingFrame
end
