local RunService = game:GetService("RunService")
local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Generic = script.Parent.Generic
local Button = require(Generic.Button)
local ScaledText = require(script.Parent.ScaledText)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Spring = Fusion.Spring
local Computed = Fusion.Computed
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent

return function(props): Frame
	props = FusionProps.GetValues(props, {
		Visible = false,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		MaxSize = Vector2.new(math.huge, math.huge),
		LayoutOrder = props.LayoutOrder or math.huge,
		ZIndex = 10,
		Text = "There's no items to show.",
		ButtonText = "Go Back",
		ButtonEnabled = true,
		Callback = FusionProps.Nil,
		Parent = FusionProps.Nil,
		CornerRadius = UDim.new(0.065, 0),
		MaxWidth = 0.25
	})

	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local textColorSpring = Spring(
		Computed(function()
			if isHeldDown:get() then
				return Color3.new(1.000000, 1.000000, 1.000000)
			else
				return Color3.new(0.000000, 0.000000, 0.000000)
			end
		end),
		20,
		1
	)

	local backgroundColorSpring = Spring(
		Computed(function()
			if isHeldDown:get() then
				return Color3.fromRGB(45, 45, 45)
			elseif isHovering:get() then
				return Color3.fromRGB(143, 143, 143)
			else
				return Color3.fromRGB(255, 255, 255)
			end
		end),
		20,
		1
	)

	local containerAbsSize = Value(Vector2.zero)
	local containerRatio = 16 / 9

	local screenWidth = Value(workspace.Camera.ViewportSize.X)
	local screenSizeSig =workspace.Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		screenWidth:set(workspace.Camera.ViewportSize.X)
	end)

	return New("ImageLabel")({
		Name = "LoadingFrame",
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		ImageTransparency = 1,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = props.BackgroundTransparency,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.Position,
		Size = props.Size,
		ZIndex = props.ZIndex,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,

		[Fusion.Cleanup] = function()
			screenSizeSig:Disconnect()
		end,

		[Children] = {
			New("UISizeConstraint")({
				MaxSize = props.MaxSize
			}),

			New "Frame" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = Computed(function()
					return UDim2.new(
						0.8, 0,
						0, containerAbsSize:get().X / containerRatio
					)
				end),

				[Out "AbsoluteSize"] = containerAbsSize,

				[Children] = {
					New "UISizeConstraint" {
						MaxSize = Computed(function()
							return Vector2.new(props.MaxWidth:get() * screenWidth:get(), math.huge)
						end)
					},

					ScaledText({
						Text = props.Text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 0.4),

						[Children] = New "UISizeConstraint" {
							MaxSize = Vector2.new(math.huge, 32)
						}
					}),
		
					New "TextButton" {
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0.6),
						Size = UDim2.fromScale(.6, 0.2),
				
						Text = "",
						BackgroundColor3 = backgroundColorSpring,
						Name = "Button",
						Visible = props.ButtonEnabled,
		
						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0.2, 0),
							},
		
							ScaledText({
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.fromScale(0.8, 0.5),
		
								Text = props.ButtonText,
								TextColor3 = textColorSpring,
							})
						},
		
						[OnEvent "Activated"] = function()
							local cb = props.Callback:get()
							if cb then
								cb()
							end
						end,
				
						[OnEvent "MouseEnter"] = function()
							isHovering:set(true)
						end,
						[OnEvent "MouseLeave"] = function()
							isHovering:set(false)
							isHeldDown:set(false)
						end,
						[OnEvent "MouseButton1Down"] = function()
							isHeldDown:set(true)
						end,
						[OnEvent "MouseButton1Up"] = function()
							isHeldDown:set(false)
						end,
					}
				}
			}
		},
	})
end
