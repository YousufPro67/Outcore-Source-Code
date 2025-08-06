local RunService = game:GetService("RunService")

local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer

return function(props)
	props = {
		Name = props.Name,
		BackgroundInvisible = props.BackgroundInvisible and 1 or 0,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(0.475, 1),
		BackgroundColor = props.BackgroundColor or Color3.fromRGB(50, 50, 50),
		SelectedBackgroundColor = props.SelectedBackgroundColor or Color3.fromRGB(255, 255, 255),
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		Selected = props.Selected,
		OnActivated = props.OnActivated,
		IsLoading = props.IsLoading,

		Text = props.Text,
		BoldText = props.BoldText,
		LabelSize = props.LabelSize or 0.6,
		LabelPositionX = props.LabelPositionX,
		Icon = props.Icon,
		IconAnchorPointX = props.IconAnchorPointX,
		SelectedTextColor = props.SelectedTextColor or Color3.fromRGB(0, 0, 0),
		TextColor = props.TextColor or Color3.fromRGB(255, 255, 255),
		IconSize = props.IconSize or 0.6,
		IconRotation = props.IconRotation or 0,
		IconPositionX = props.IconPositionX,
		SelectedIconColor = props.SelectedIconColor or Color3.fromRGB(0, 0, 0),
		IconColor = props.IconColor or Color3.fromRGB(255, 255, 255),
		CornerRadius = props.CornerRadius or UDim.new(0.3, 0),

		[Children] = props[Children],
	}

	local spinnerValue = Value()
	local loadingObserver

	if props.IsLoading then
		loadingObserver = Observer(props.IsLoading)

		local connection

		loadingObserver:onChange(function()
			if props.IsLoading:get() == true then
				connection = RunService.RenderStepped:Connect(function()
					local spinner = spinnerValue:get()
					if not spinner then
						return
					end

					spinner.Rotation += 1
				end)
			elseif props.IsLoading:get() == false then
				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end)
	end

	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = not not props.BoldText

	local LabelPosition = math.clamp(props.IconAnchorPointX, 0.05, 0.95)

	return New("TextButton")({
		Name = props.Name,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = props.BackgroundInvisible,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,

		BackgroundColor3 = Computed(function()
			if props.Selected:get() then
				return props.SelectedBackgroundColor
			else
				return props.BackgroundColor
			end
		end),

		[OnEvent("Activated")] = props.OnActivated,

		[Children] = {
			props[Children],

			New("TextLabel")({
				Text = props.Text,
				FontFace = font,
				TextScaled = true,
				Size = UDim2.fromScale(0, props.LabelSize),
				Position = UDim2.fromScale(LabelPosition - props.LabelPositionX or 0, 0.5),
				AnchorPoint = Vector2.new(props.IconAnchorPointX, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ZIndex = props.ZIndex,

				TextColor3 = Computed(function()
					if props.Selected:get() then
						return props.SelectedTextColor
					else
						return props.TextColor
					end
				end),

				Visible = Computed(function()
					if not props.IsLoading then
						return true
					end

					return not props.IsLoading:get()
				end),
			}),

			New("ImageLabel")({
				Name = "Icon",
				Size = UDim2.fromScale(props.IconSize, props.IconSize),
				Position = UDim2.fromScale(props.IconPositionX, 0.5),
				AnchorPoint = Vector2.new(math.abs(props.IconAnchorPointX - 1), 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
				Image = props.Icon,
				Rotation = props.IconRotation,
				ZIndex = props.ZIndex,

				ImageColor3 = Computed(function()
					if props.Selected:get() then
						return props.SelectedIconColor
					else
						return props.IconColor
					end
				end),

				Visible = Computed(function()
					if not props.IsLoading then
						return true
					end

					return not props.IsLoading:get()
				end),
			}),

			props.IsLoading and New("ImageLabel")({
				Name = "Spinner",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.8, 0.8),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://11304130802",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 101,

				Visible = Computed(function()
					return props.IsLoading:get()
				end),

				[Ref] = spinnerValue,
			}) or nil,

			New("UICorner")({
				CornerRadius = props.CornerRadius,
			}),
		},
	})
end
