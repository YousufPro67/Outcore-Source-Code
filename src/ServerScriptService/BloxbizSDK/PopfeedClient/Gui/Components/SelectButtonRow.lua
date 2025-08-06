local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Children = Fusion.Children
local ForValues = Fusion.ForValues

local SelectButton = require(script.Parent.SelectButton)

return function(props)
	props = {
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5),
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(50, 50, 50),
		SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeXY,
		HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Left,

		buttonNames = props.buttonNames,
		initialSelection = props.initialSelection,
		initialSelectionIsActive = (props.initialSelectionActive == nil and true) or props.initialSelectionActive,
		buttonSelectedCallback = props.buttonSelectedCallback,

		padding = props.padding,
		customButtonProps = props.customButtonProps or {
			--canBeSelected: true
		},
	}
	local currentlySelected = Value(props.initialSelection)

	local function onButtonActivated(buttonName, customButtonProps)
		if customButtonProps.canBeSelected ~= false then
			currentlySelected:set(buttonName)
		end

		props.buttonSelectedCallback(buttonName)
	end

	local selectButtonRow = New("Frame")({
		Name = "SelectButtonRow",
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = props.BackgroundTransparency,
		BackgroundColor3 = props.BackgroundColor3,
		SizeConstraint = props.SizeConstraint,
		Visible = props.Visible,

		[Children] = {
			New("UIListLayout")({
				Name = "List",
				Padding = props.padding,
				HorizontalAlignment = props.HorizontalAlignment,

				FillDirection = Enum.FillDirection.Horizontal,

				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			ForValues(props.buttonNames, function(buttonName)
				local customButtonProps = props.customButtonProps[buttonName] or {}

				local properties = {
					Name = buttonName,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = buttonName,
					Color = Color3.fromRGB(255, 255, 255),
					OnActivated = function()
						onButtonActivated(buttonName, customButtonProps)
					end,
					isSelected = Computed(function()
						if customButtonProps.canBeSelected == false then
							return false
						end

						return currentlySelected:get() == buttonName
					end),
				}

				for name, prop in pairs(customButtonProps) do
					properties[name] = prop
				end

				return SelectButton(properties)
			end, Fusion.cleanup),
		},
	})

	if props.initialSelection and props.initialSelectionActive then
		onButtonActivated(props.initialSelection)
	end

	return selectButtonRow
end
