local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)

local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = script.Parent.Parent
local Generic = Components.Generic

local Spring = require(Generic.Spring)

local Value = Fusion.Value
local Computed = Fusion.Computed
local New = Fusion.New

local GUI_SETTINGS = {
	Color = {
		Default = Color3.fromRGB(121, 121, 121),
		Selected = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(150, 150, 150),
		MouseDown = Color3.fromRGB(130, 130, 130),
	},

	UnderlineThickness = 1,
}

local function Button(props): Instance
	props = FusionProps.GetValues(props, {
		Cooldown = false,
		Selected = false,
		TotalWidth = FusionProps.Nil,
		Id = FusionProps.Nil,
		Data = FusionProps.Nil,
		OnClick = FusionProps.Nil,
		Parent = FusionProps.Nil,
		Text = "",
		TextSize = 30,
		TextScaled = false,
		Alignment = "Left"
	})

	local states = {
		Hovering = Fusion.Value(false),
		HeldDown = Fusion.Value(false),
		Selected = props.Selected,
		Enabled = Fusion.Computed(function()
			return not props.Cooldown:get()
		end, Fusion.cleanup),
	}

	local buttonColorSpring = Spring(states, {
		Default = Color3.fromRGB(121, 121, 121),
		Selected = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(150, 150, 150),
		MouseDown = Color3.fromRGB(130, 130, 130),
		Disabled = Color3.fromRGB(130, 130, 130)
	}, 40)

	-- local x = string.len(props.Text) > 5 and 0.28 or 0.15
	

	return Fusion.New("TextButton")({
		Name = props.Id,
		Parent = props.Parent,
		Text = props.Text,
		TextScaled = false,
		TextWrapped = false,
		TextColor3 = buttonColorSpring,
		TextSize = props.TextSize,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		LayoutOrder = 14,
		Position = UDim2.fromScale(-4.88e-08, 0),
		Size = props.Size,

		[Fusion.OnEvent("Activated")] = function()
			local cb = props.OnClick:get()

			if cb then
				cb(props.Id:get())
			end
		end,

		[Fusion.OnEvent("MouseButton1Down")] = function()
			states.HeldDown:set(true)
		end,

		[Fusion.OnEvent("MouseButton1Up")] = function()
			states.HeldDown:set(false)
		end,

		[Fusion.OnEvent("MouseEnter")] = function()
			states.Hovering:set(true)
		end,

		[Fusion.OnEvent("MouseLeave")] = function()
			states.Hovering:set(false)
			states.HeldDown:set(false)
		end,
	})
end

return function(props): (Instance, (id: string) -> ())
	local holder = Fusion.Value(nil)
	local underline = Fusion.Value(nil)
	local textSize = Fusion.Value(30)

	local signals = {}

	props = FusionProps.GetValues(props, {
		Parent = FusionProps.Nil,
		Buttons = {},
		UIListLayoutIncluded = false,
		Selected = FusionProps.Nil,
		OnButtonClick = FusionProps.Nil,
		Cooldown = false,
		Alignment = "Left",
		Padding = 0,
	})

	local sortHeight = Fusion.Computed(function()
		return props.Size:get().Y
	end)

	local maxWidth = Fusion.Computed(function()
		return props.Size:get().X
	end)

	local sortFrame = Value()
	local sortParent = Value()
	local sortSizePX = Value(Vector2.zero)
	local textSize = Computed(function()
		return sortSizePX:get().Y / 1.5
	end)
	local padding = Computed(function()
		return textSize:get() / 2
	end)

	local maxWidthPX = Computed(function()
		return sortSizePX:get().X
	end)

	local totalWidth = Computed(function()
		local buttonDatas = props.Buttons:get()
		local totalWidth = 0
		local visibleButtonCount = 0
		for _, button in ipairs(buttonDatas) do
			if button.Hidden then
				continue
			end
			
			local width = TextService:GetTextSize(button.Text, textSize:get(), Enum.Font.Gotham, Vector2.new(math.huge, math.huge)).X
			totalWidth += width
			visibleButtonCount += 1
		end

		return totalWidth + padding:get() * (visibleButtonCount - 1)
	end)

	local scale = Computed(function()
		return math.min(maxWidthPX:get() / totalWidth:get(), 1)
	end)

	local buttons = Fusion.ForValues(props.Buttons, function (v)
		props.Selected:get()
		props.Buttons:get()
		totalWidth:get()

		if not v.Hidden then
			local width = TextService:GetTextSize(v.Text, textSize:get(), Enum.Font.Gotham, Vector2.new(math.huge, math.huge)).X

			return Button({
				Id = v.Id,
				Text = v.Text,
				Data = v.Data,
				Cooldown = props.Cooldown,
				Selected = Computed(function()
					return props.Selected:get() == v.Id
				end),
				TextSize = textSize,
				Alignment = props.Alignment,
				OnClick = function()
					local cb = props.OnButtonClick:get()
					if cb then
						cb(v.Id)
					end

					if props.DontUpdateSelected then
						return
					end

					task.wait()
					if props.Selected:get() ~= v.Id then
						props.Selected:set(v.Id)
					end
				end,
				Size = UDim2.new(0, width, 1, 0)
			})
		end
	end, Fusion.cleanup)

	local function setSelected(id: string)
		props.Selected:set(id)
	end

	local frame = Fusion.New("Frame")({
		Name = "SortSelector",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Position = UDim2.fromScale(0, 0.5),
		Size = props.Size,
		Parent = props.Parent,
		Visible = props.Visible,

		[Fusion.Ref] = sortFrame,
		[Fusion.Out "AbsoluteSize"] = sortSizePX,
		[Fusion.Out "Parent"] = sortParent,

		[Fusion.Cleanup] = function()
			Fusion.cleanup(signals)
		end,

		[Fusion.Children] = {
			Fusion.New("Frame")({
				AnchorPoint = Vector2.new(0, 0.5),
				Name = "Holder",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(1, 1),

				[Fusion.Ref] = holder,

				[Fusion.Children] = {
					New "UIScale" {
						Scale = scale
					},
					
					Fusion.New("UIListLayout")({
						Name = "UIListLayout",
						Padding = Computed(function()
							return UDim.new(0, padding:get() + props.Padding:get())
						end),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					buttons
				},
			}),

			-- Fusion.New("UICorner")({
			-- 	Name = "UICorner",
			-- 	CornerRadius = UDim.new(0.225, 0),
			-- }),
		},
	})

	if props.IgnoreSetFunction then
		return frame
	end

	return frame, setSelected
end
