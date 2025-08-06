local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
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

return function(isSelected: Fusion.Value<boolean>): (Fusion.Spring<number>, Frame)
	local frame = Value()

	local textTransparency = Spring(
		Computed(function()
			return isSelected:get() and 0 or 1
		end),
		20,
		1
	)

	local newObs = Observer(textTransparency)

	local disconnect = newObs:onChange(function()
		if textTransparency:get() < 0.8 then
			local layer = frame:get()
			layer.Visible = true
		else
			local layer = frame:get()
			layer.Visible = false
		end
	end)

	local selectedFrameSelectionSpring = Spring(
		Computed(function()
			return isSelected:get() and 0.5 or 1
		end),
		20,
		1
	)

	New("Frame")({
		Name = "HoverFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = selectedFrameSelectionSpring,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 2,

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
		},
	})

	return textTransparency, frame:get()
end
