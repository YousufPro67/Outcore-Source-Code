local RunService = game:GetService("RunService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = BloxbizSDK.CatalogClient.Components

local CatalogItem = require(Components.CatalogItem)

local Children = Fusion.Children
local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Ref = Fusion.Ref
local ForValues = Fusion.ForValues
local ForPairs = Fusion.ForPairs
local Out = Fusion.Out

export type DataSet = {
	MainFrame: Frame,
	ListFrame: ScrollingFrame,
}

export type AvatarFrame = {
	new: () -> DataSet,
}

local VIEWPORT_SIZE = Value(Vector2.new(1280, 720))
RunService.RenderStepped:Connect(function()
	if workspace.Camera.ViewportSize ~= VIEWPORT_SIZE:get() then
		VIEWPORT_SIZE:set(workspace.Camera.ViewportSize)
	end
end)

-- Position = UDim2.new(0.688, 0, 0.017, 0),
-- Size = UDim2.new(0.302, 0, 1 - 0.017, 0),

local function AvatarPreviewFrame(props): DataSet
	props = FP.GetValues(props, {
		Parent = FP.Nil,
		ZIndex = 100,
		AnchorPoint = Vector2.zero,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		ButtonHeight = 16,
		EquippedItems = {},
		ShowItems = false,
		CategoryName = "",
		AvatarPreviewController = FP.Nil,
		Scene = {
			Image = "http://www.roblox.com/asset/?id=10393363412",
			Color = Color3.new(1, 1, 1)
		},
		[Children] = {}
	})

	local listSize = Value(Vector2.zero)
	local listContentSize = Value(Vector2.zero)
	local selectedItem = Value()

	return New "Frame" {
		Parent = props.Parent,
		Name = "PreviewFrame",

		ZIndex = props.ZIndex,
		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		[Children] = {
			-- items list
			New "ScrollingFrame" {
				Name = "ListFrame",
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = Computed(function()
					return UDim2.new(
						1, -12,
						0, listContentSize:get().Y + 10
					)
				end),
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Active = true,
				BackgroundTransparency = 1,
				Position = Computed(function()
					return UDim2.new(0, 12, 0, (props.ButtonHeight:get()) + 8)
				end),
				Size = Computed(function()
					return UDim2.new(1, -12, 1, -(props.ButtonHeight:get())*2 - 20)
				end),
				Visible = props.ShowItems,
				ZIndex = 30,
		
				[Out "AbsoluteSize"] = listSize,
		
				[Children] = {
					New("UIGridLayout")({
						Name = "UIGridLayout",
						CellPadding = UDim2.fromScale(0.04, 0.03),
						CellSize = Computed(function()
							return UDim2.new(0.48, 0, 0, listSize:get().X * 0.48 * 1.1)
						end),
						SortOrder = Enum.SortOrder.LayoutOrder,
						[Out "AbsoluteContentSize"] = listContentSize,
					}),

					ForValues(props.EquippedItems, function(item)
						if not item.AssetId then
							return
						end

						return CatalogItem {
							AvatarPreviewController = props.AvatarPreviewController,
							ItemData = item,
							CategoryName = props.CategoryName,
							SelectedId = selectedItem,

							BackgroundColor3 = Color3.new(0, 0, 0),
							BackgroundTransparency = 0.5
						}
					end, Fusion.cleanup)
				},
			},

			New("ImageLabel")({
				Name = "Background",
				Image = Computed(function()
					return props.Scene:get().Image
				end),
				ImageColor3 = Computed(function()
					return props.Scene:get().Color
				end),
				ScaleType = Enum.ScaleType.Crop,
				BackgroundColor3 = Computed(function()
					return props.Scene:get().Color
				end),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -0.1),
				Size = UDim2.fromScale(1.05, 1.1),
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.02, 0),
			}),

			props[Children]
		},
	}
end

return AvatarPreviewFrame
