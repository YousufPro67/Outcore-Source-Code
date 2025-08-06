local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Spring = Fusion.Spring
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Children = Fusion.Children
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local configLoaded = Instance.new("BindableEvent")

local isDragging = false
local dragOldX
local delta = 0

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function validateInput(input: InputObject): boolean
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

	return isTouch or isClick
end

local function offsetToScale(parent: GuiObject, offset: Vector2): Vector2
	local viewPortSize = parent.AbsoluteSize
	if viewPortSize == Vector2.zero then
		viewPortSize = Vector2.new(1, 1)
	end

	return Vector2.new(offset.X / viewPortSize.X, offset.Y / viewPortSize.Y)
end

local function getUnderline(parent: GuiObject, underline: GuiObject, element: GuiObject): UDim2
	local underlineParent = underline.Parent
	if underlineParent then
		local elemPos = element.AbsolutePosition
		local elemSize = element.AbsoluteSize

		local desiredAbsolutePosition = Vector2.new(elemPos.X + elemSize.X / 2, elemPos.Y + elemSize.Y)

		local relativePosition = desiredAbsolutePosition - underlineParent.AbsolutePosition
		local scaleVector2 = offsetToScale(parent, relativePosition)

		return UDim2.fromScale(scaleVector2.X, scaleVector2.Y)
	end

	return UDim2.fromScale(0, 0)
end

return function(props)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	Observer(props.FetchingFeedTypeValue):onChange(function()
		configLoaded:Fire()
	end)

	configLoaded.Event:Wait()

	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = true

	local feeds = {}
	for _, feed in props.Config.feeds.main do
		table.insert(feeds, feed)
	end

	local tabNames = {}
	for _, feed in feeds do
		table.insert(tabNames, feed.name)
	end

	local function visibleNavigationBar()
		local feedType = props.FetchingFeedTypeValue:get()
		if not feedType then
			return
		end

		if props.isProfileFeed(feedType) then
			return false
		elseif feedType == "replies" then
			return false
		elseif feedType == "notifications" then
			return false
		elseif feedType == "explore" then
			return false
		else
			return true
		end
	end

	local holderValue = Value()
	local scrollingFrame = Value()
	local underlineValue = Value()
	local selectedButton = Value()

	task.defer(function()
		selectedButton:set(feeds[1].id)
	end)

	local underlinePosSpring = Spring(
		Computed(function()
			local button = selectedButton:get()
			local holder = holderValue:get()
			local underline = underlineValue:get()

			if button and holder and underlineValue then
				button = holder:FindFirstChild(button)

				return getUnderline(holder, underline, button)
			end

			return UDim2.new(0.147, 0, 1, 0)
		end),
		40,
		1
	)

	local function hoveringOverScrollingFrame(): boolean
		local guis = playerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)

		for _, gui in guis do
			if gui == scrollingFrame:get() then
				return true
			end
		end

		return false
	end

	local function dragScroll()
		local frame = scrollingFrame:get()

		if not isDragging or not frame then
			return
		end

		local X = Mouse.X

		delta = X - (dragOldX or X)
		frame.CanvasPosition = Vector2.new(math.floor(frame.CanvasPosition.X - delta), 0)

		dragOldX = X
	end

	if not UserInputService.TouchEnabled then
		RunService:BindToRenderStep("CategoryButtonScroll", 1, dragScroll)
	end

	UserInputService.InputBegan:Connect(function(input: InputObject)
		if validateInput(input) and hoveringOverScrollingFrame() then
			isDragging = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if validateInput(input) then
			isDragging = false
			dragOldX = nil
		end
	end)

	return {
		New("ImageButton")({
			Name = "Info",
			Image = "rbxassetid://13758970742",
			Size = UDim2.fromScale(0.07, 0.07),
			Position = UDim2.fromScale(0.95, 0.2),
			AnchorPoint = Vector2.new(1, 0),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 1,

			Visible = false, --Computed(visibleNavigationBar),
		}),

		New("ImageLabel")({
			Name = "Logo",
			Image = "rbxassetid://16743008992",
			Size = UDim2.fromScale(0.3, 0.25),
			Position = UDim2.fromScale(0.05, 0.2),
			ScaleType = Enum.ScaleType.Fit,
			BackgroundTransparency = 1,

			Visible = Computed(visibleNavigationBar),
		}),

		New("ScrollingFrame")({
			Name = "Navigation",
			Size = UDim2.fromScale(0.95, 0.35),
			Position = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(1, 1),
			CanvasSize = UDim2.fromScale(0, 0),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,

			Visible = Computed(visibleNavigationBar),

			[Ref] = scrollingFrame,

			[Children] = {
				New("Frame")({
					Name = "Container",
					Size = UDim2.fromScale(17.956, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,

					[Children] = {
						New("Frame")({
							Name = "Underline",
							AnchorPoint = Vector2.new(0.5, 1),
							BackgroundColor3 = Color3.fromRGB(0, 170, 255),
							Position = underlinePosSpring,
							Size = UDim2.fromScale(0.06, 0.15),

							[Ref] = underlineValue,

							[Children] = {
								New("UICorner")({
									CornerRadius = UDim.new(0.5, 0),
								}),
							},
						}),

						New("Frame")({
							Name = "Holder",
							Size = UDim2.fromScale(1, 0.6),
							BackgroundTransparency = 1,

							[Ref] = holderValue,

							[Children] = {
								New("UIListLayout")({
									Padding = UDim.new(0.05, 0),
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Horizontal,
								}),

								ForValues(feeds, function(feedData)
									return New("TextButton")({
										Name = feedData.id,
										Text = feedData.name,
										Size = UDim2.fromScale(0, 1),
										AutomaticSize = Enum.AutomaticSize.X,
										BackgroundTransparency = 1,
										TextScaled = true,
										FontFace = font,

										TextColor3 = Computed(function()
											local selected = selectedButton:get()
											if selected == feedData.id then
												return Color3.fromRGB(255, 255, 255)
											else
												return Color3.fromRGB(134, 134, 134)
											end
										end),

										[OnEvent("Activated")] = function()
											selectedButton:set(feedData.id)

											if feedData.id == "player" then
												props.OnSwitchFeedClicked(feedData.id, LocalPlayer.UserId)
											else
												props.OnSwitchFeedClicked(feedData.id, nil)
											end
										end,
									})
								end, Fusion.cleanup),
							},
						}),
					},
				}),
			},
		}),

		Line({
			Size = UDim2.fromScale(1, 0.02),
		}),
	}
end
