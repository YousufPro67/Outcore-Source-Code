local PopfeedClient = script.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local Tween = Fusion.Tween
local Computed = Fusion.Computed
local Children = Fusion.Children

local DEFAULT_DURATION = 1
local FADE_IN_DURATION = 0.2
local FADE_IN_TWEEN_INFO = TweenInfo.new(FADE_IN_DURATION, Enum.EasingStyle.Sine)

return function(props)
    local GoalSize = UDim2.fromScale(0.9, 0.175)
    local StartSize = UDim2.fromScale(0, 0)

    local SizeValue = Value(StartSize)
    local SizeTween = Tween(SizeValue, FADE_IN_TWEEN_INFO)
    SizeValue:set(GoalSize)

	task.delay(DEFAULT_DURATION, function()
        SizeValue:set(StartSize)

        task.wait(FADE_IN_DURATION)

		props.EnablePopupMessage:set(false)
    end)

    return New "Frame" {
		Name = "Popup",
		Position = UDim2.fromScale(0.5, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		ZIndex = 10,

		Size = Computed(function()
            return SizeTween:get()
        end),

		[Children] = {
			New("TextLabel")({
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = "Popfeed actions aren't supported in this experience.",
				TextScaled = true,
				FontFace = Font.fromEnum(Enum.Font.Arial),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 10,
			}),

			New "UICorner" {
				CornerRadius = UDim.new(0.5, 0),
			},

			New "UIStroke" {
				Color = Color3.fromRGB(50, 50, 50),
				Thickness = 2,
			},
		},
	}
end
