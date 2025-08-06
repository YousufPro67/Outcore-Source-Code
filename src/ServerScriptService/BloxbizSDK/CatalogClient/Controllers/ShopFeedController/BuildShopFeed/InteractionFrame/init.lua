local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local AvatarHandler = require(CatalogClient.Classes:WaitForChild("AvatarHandler"))

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Value = Fusion.Value
local Cleanup = Fusion.Cleanup
local Ref = Fusion.Ref
local Observer = Fusion.Observer

type SourceBundleInfo = { AssetId: number, Price: number }
export type Props = {
	ItemData: AvatarHandler.ItemData,
	Equipped: boolean,
	Callbacks: { [string]: (...any) -> ...any },
	SourceBundleInfo: SourceBundleInfo?,
}

return function(props)
	props = FusionProps.GetValues(props, {
		Selected = false,
		[Children] = FusionProps.Nil
	})

	local frame = Value()

	local textTransparency = Spring(
		Computed(function()
			if props.Selected:get() then
				return 0
			else
				return 1
			end
		end),
		20,
		1
	)

	local disconnect = Observer(textTransparency):onChange(function()
		local layer = frame:get()

		if textTransparency:get() < 0.8 then
			layer.Visible = true
		else
			layer.Visible = false
		end
	end)

	return New("CanvasGroup")({
		GroupTransparency = textTransparency,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		BackgroundTransparency = 1,

		[Children] = {
			New("Frame")({
				Name = "HoverFrame",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Visible = false,
		
				[Ref] = frame,
				[Cleanup] = function()
					disconnect()
				end,
		
				[Children] = {
					New("UIListLayout")({
						Name = "UIListLayout",
						Padding = UDim.new(0.05, 0),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					New("UICorner")({
						Name = "UICorner",
						CornerRadius = UDim.new(0.05, 0),
					}),
					props[Children]
				},
			})
		}
	})
end
