local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local _CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local Camera = workspace.CurrentCamera

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")

local _UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
local Computed = Fusion.Computed
local Children = Fusion.Children
local Ref = Fusion.Ref
local OnEvent = Fusion.OnEvent
local ForValues = Fusion.ForValues

export type QuickSortValue = {
	SelectedValue: Fusion.Value<boolean>,
	SortType: number,
	Underline: Frame,
	TextLabel: TextLabel,
	Button: GuiObject,
}

type CurrentSelectedButton = Fusion.Value<QuickSortValue>

export type DataSet = {
	Instance: Frame,
	CurrentSelectedQuickSort: CurrentSelectedButton,
	DefaultSelection: QuickSortValue,
}

export type QuickSortTab = {
	new: (buttons: { { Text: string, SortType: number } }) -> DataSet,
}

local GUI_SETTINGS = {
	Color = {
		Default = Color3.fromRGB(121, 121, 121),
		Selected = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(150, 150, 150),
		MouseDown = Color3.fromRGB(130, 130, 130),
	},

	UnderlineThickness = 1,
}

local function OffsetToScale(parent: GuiObject, offset: Vector2): Vector2
	local viewPortSize = parent.AbsoluteSize
	if viewPortSize == Vector2.zero then
		viewPortSize = Vector2.new(1, 1)
	end

	return Vector2.new(offset.X / viewPortSize.X, offset.Y / viewPortSize.Y)
end

local function GetUnderline(parent: GuiObject, underline: GuiObject, element: GuiObject): UDim2
	local underlineParent = underline.Parent
	if underlineParent then
		local elemPos = element.AbsolutePosition
		local elemSize = element.AbsoluteSize

		local desiredAbsolutePosition = Vector2.new(elemPos.X + elemSize.X / 2, elemPos.Y + elemSize.Y)

		local relativePosition = desiredAbsolutePosition - underlineParent.AbsolutePosition
		local scaleVector2 = OffsetToScale(parent, relativePosition)

		return UDim2.fromScale(scaleVector2.X, scaleVector2.Y)
	end

	return UDim2.fromScale(0, 0)
end

local function GetTextSize(parent: GuiObject, textLabel: TextLabel): UDim2
	local vector2 = TextService:GetTextSize(
		textLabel.Text,
		textLabel.TextSize,
		textLabel.Font,
		Vector2.new(textLabel.Size.X.Offset, textLabel.Size.Y.Offset)
	)

	vector2 = Vector2.new(vector2.X, GUI_SETTINGS.UnderlineThickness)
	local sizeVector2 = OffsetToScale(parent, vector2)
	return UDim2.fromScale(sizeVector2.X, sizeVector2.Y)
end

local function QuickAccessButton(
	text: string,
	sortType: number,
	currentSelectedButton: CurrentSelectedButton,
	selectedByDefault: boolean
): (Instance, {
	SelectedValue: Fusion.Value<boolean>,
	UnderlineAnchor: Frame,
	TextLabel: TextLabel,
	Button: GuiButton,
}?)
	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isSelected = Value(false)

	local button = Value(nil)
	local underline = Value(nil)
	local textLabel = Value(nil)

	local buttonColorSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return GUI_SETTINGS.Color.Selected
			elseif isHeldDown:get() then
				return GUI_SETTINGS.Color.MouseDown
			elseif isHovering:get() then
				return GUI_SETTINGS.Color.Hover
			else
				return GUI_SETTINGS.Color.Default
			end
		end),
		40,
		1
	)

	local x = string.len(text) > 5 and 0.24 or 0.15

	local quickButton = New("TextButton")({
		Name = text,
		Text = "",
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		LayoutOrder = 14,
		Position = UDim2.fromScale(-4.88e-08, 0),
		Size = UDim2.fromScale(x, 1),

		[Ref] = button,

		[Children] = {
			New("Frame")({
				Name = "Underline",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.new(1, 0, 0, 2),
				ZIndex = 3,

				[Ref] = underline,
			}),

			New("TextLabel")({
				Name = "TextLabel",
				Text = text,
				TextColor3 = buttonColorSpring,
				TextSize = 27,
				TextScaled = true,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 0.8),

				[Ref] = textLabel,

				[Children] = {
					New("UITextSizeConstraint")({
						Name = "UITextSizeConstraint",
						MaxTextSize = 35,
					}),
				},
			}),
		},

		[OnEvent("Activated")] = function()
			local currentSelected = currentSelectedButton:get()
			if not currentSelected or (currentSelected and currentSelected.SelectedValue ~= isSelected) then
				if currentSelected then
					currentSelected.SelectedValue:set(false)
				end

				currentSelectedButton:set({
					SelectedValue = isSelected,
					SortType = sortType,
					UnderlineAnchor = underline:get(),
					TextLabel = textLabel:get(),
					Button = button:get(),
				})
				isSelected:set(true)
			end
		end,

		[OnEvent("MouseButton1Down")] = function()
			isHeldDown:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			isHeldDown:set(false)
		end,

		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end,
	})

	if selectedByDefault then
		return quickButton,
			{
				SelectedValue = isSelected,
				SortType = sortType,
				UnderlineAnchor = underline:get(),
				TextLabel = textLabel:get(),
				Button = button:get(),
			}
	else
		return quickButton
	end
end

return function(buttons: { { Text: string, SortType: number } })
	local holder = Value(nil)
	local underline = Value()
	local currentSelectedButton = Value(nil)

	local firstSelection = true
	local firstOptionData

	local underlinePosSpring = Spring(
		Computed(function()
			local currentSelected = currentSelectedButton:get()
			if currentSelected and holder:get() and underline:get() and currentSelected.Button then
				return GetUnderline(holder:get(), underline:get(), currentSelected.Button)
			end

			return UDim2.new(0.147, 0, 1, 0)
		end),
		40,
		1
	)

	local underlineSizeSpring = Spring(
		Computed(function()
			local currentSelected = currentSelectedButton:get()
			if currentSelected and holder:get() and currentSelected.TextLabel then
				local result = GetTextSize(holder:get(), currentSelected.TextLabel)
				return result
			end

			return UDim2.new(0.0, 0, 0, 0)
		end),
		40,
		1
	)

	local quickSortFrame = New("Frame")({
		Name = "Quick",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Position = UDim2.fromScale(0.17, 0.5),
		Size = UDim2.fromScale(0.45, 1),

		[Children] = {
			New("UIStroke")({
				Name = "StandardStroke",
				Color = Color3.fromRGB(79, 84, 95),
				Thickness = 1.5,
			}),

			New("Frame")({
				Name = "Underline",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Position = underlinePosSpring,
				Size = underlineSizeSpring,
				ZIndex = 3,

				[Ref] = underline,
			}),

			New("Frame")({
				Name = "Holder",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				[Ref] = holder,

				[Children] = {
					New("UIListLayout")({
						Name = "UIListLayout",
						Padding = UDim.new(0.02, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					ForValues(buttons, function(buttonData: { Text: string, SortType: number }): Instance
						local button, data = QuickAccessButton(
							buttonData.Text,
							buttonData.SortType,
							currentSelectedButton,
							firstSelection
						)
						if firstSelection then
							firstSelection = false
							firstOptionData = data
						end
						return button
					end, Fusion.cleanup),
				},
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.225, 0),
			}),
		},
	})

	return {
		Instance = quickSortFrame,
		CurrentSelectedQuickSort = currentSelectedButton,
		DefaultSelection = firstOptionData,
	}
end
