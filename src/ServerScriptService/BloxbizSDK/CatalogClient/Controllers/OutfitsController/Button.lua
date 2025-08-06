local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = BloxbizSDK.CatalogClient.Components

local ScaledText = require(Components.ScaledText)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local TOUCH_ENABLED = UserInputService.TouchEnabled

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForPairs = Fusion.ForPairs
local OnChange = Fusion.OnChange
local Out = Fusion.Out

local GUI_SETTINGS = {
	TextColor = {
		Default = Color3.fromRGB(255, 255, 255),
		MouseDown = Color3.fromRGB(60, 60, 60),
		Hover = Color3.fromRGB(255, 255, 255),
		Selected = Color3.fromRGB(0, 0, 0),
	},

	BackgroundColor = {
		Default = Color3.fromRGB(20, 20, 20),
		MouseDown = Color3.fromRGB(15, 15, 15),
		Hover = Color3.fromRGB(30, 30, 30),
		Selected = Color3.fromRGB(255, 255, 255)
	},
}

return function (props)
    props = FusionProps.GetValues(props, {
        Parent = FusionProps.Nil,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.zero,
        Id = 0,
        SelectedId = -1,
        OnClick = FusionProps.Callback,
		Icon = FusionProps.Nil,
        Text = "",
		LayoutOrder = 1,
		SizeRef = Vector2.zero,
		MaxWidth = math.huge
    })

	local absSize = props.SizeRef
	local textSize = Computed(function()
		return absSize:get().Y / 2
	end)
	local textWidth = Computed(function()
		return TextService:GetTextSize(props.Text:get(), textSize:get(), Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge)).X
	end)
	local iconSize = Computed(function()
		return absSize:get().Y / 2
	end)

	local totalWidth = Computed(function()
		local width = textSize:get() + textWidth:get()

		if props.Icon:get() then
			width += iconSize:get()

			if #props.Text:get() > 0 then
				width += textSize:get() / 2
			end
		end

		return width
	end)

    local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isSelected = props.IsSelected or Computed(function()
		return props.SelectedId:get() == props.Id:get()
	end)

	local bgSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return GUI_SETTINGS.BackgroundColor.Selected
			elseif isHovering:get() then
				return GUI_SETTINGS.BackgroundColor.Hover
			elseif isHeldDown:get() then
				return GUI_SETTINGS.BackgroundColor.MouseDown
			else
				return GUI_SETTINGS.BackgroundColor.Default
			end
		end),
		20,
		1
	)

	local textColorSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return GUI_SETTINGS.TextColor.Selected
			elseif isHovering:get() then
				return GUI_SETTINGS.TextColor.Hover
			elseif isHeldDown:get() then
				return GUI_SETTINGS.TextColor.MouseDown
			else
				return GUI_SETTINGS.TextColor.Default
			end
		end),
		20,
		1
	)

	local name = props.Id:get() or "feed"

	return New "TextButton" {
		Name = name,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		BackgroundColor3 = bgSpring,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		Size = Computed(function()
            return UDim2.new(0, math.min(totalWidth:get(), props.MaxWidth:get()), 1, 0)
        end),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Visible = true,

		[Out "AbsoluteSize"] = absSize,

		[Children] = {
			New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.21, 0),
			},
			New "UIStroke" {
				Name = "StandardStroke",
				Color = Color3.fromRGB(79, 84, 95),
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			},
			New "UIPadding" {
				PaddingLeft = Computed(function() return UDim.new(0, textSize:get()) end),
				PaddingRight = Computed(function() return UDim.new(0, textSize:get()) end)
			},
			New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Computed(function() return UDim.new(0, textSize:get()/2) end)
			},

			-- icon
			Computed(function()
				if props.Icon:get() then
					return New "ImageLabel" {
						Name = "Icon",
						Size = Computed(function() return UDim2.fromOffset(iconSize:get(), iconSize:get()) end),
						BackgroundTransparency = 1,
						ImageColor3 = textColorSpring,
						Image = props.Icon:get()
					}
				end
			end, Fusion.cleanup),

			ScaledText {
				LayoutOrder = 2,
				Text = props.Text,
				TextColor3 = textColorSpring,
				TextSize = textSize,
				TextWrapped = false,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = Computed(function()
					return UDim2.new(0, absSize:get().X - iconSize:get() - textSize:get() * 2.5, 0.5, 0)
				end),
				Visible = Computed(function()
					return #props.Text:get() > 0
				end)
			},
		},

		[OnEvent("Activated")] = function()
			local cb = props.OnClick:get()
			cb()
		end,

		[OnEvent("MouseButton1Down")] = function()
			if not TOUCH_ENABLED then
				isHeldDown:set(true)
			end
		end,

		[OnEvent("MouseButton1Up")] = function()
			if not TOUCH_ENABLED then
				isHeldDown:set(false)
			end
		end,

		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end
	}
end