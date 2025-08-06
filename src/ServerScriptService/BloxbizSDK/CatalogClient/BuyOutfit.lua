local UserInputService = game:GetService("UserInputService")
local BloxbizSDK = script.Parent.Parent

local Components = BloxbizSDK:WaitForChild("CatalogClient"):WaitForChild("Components")
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Camera = workspace.CurrentCamera

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring
local Computed = Fusion.Computed

local IconButton = require(Components.IconButton)

local function IsMobile(): boolean
	local viewPortSize = Camera.ViewportSize
	local touchEnabled = UserInputService.TouchEnabled
	return (viewPortSize.X <= 1200 or viewPortSize.Y <= 800) and touchEnabled
end

local TEXT_COLOR = Color3.fromRGB(201, 44, 44)

return function(props)
	props = FP.GetValues(props, {
		Parent = FP.Nil,
		OnBuy = FP.Callback,
		Visible = true,
		LayoutOrder = 1
	})

	local btn = IconButton({
		Name = "Buy",
		Parent = props.Parent,
		AnchorPoint = Vector2.new(1, 0.5),
		LayoutOrder = props.LayoutOrder,
		Position = UDim2.new(1, -60, 0, 20),
		Size = UDim2.new(0, 80, 1, 0),
		Icon = "rbxassetid://15245041780",
		IconSize = 0.75,
		Text = "Buy Outfit",
		Visible = props.Visible,
		OnClick = props.OnBuy
	})
	return btn
end
