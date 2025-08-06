local TweenService = game:GetService("TweenService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local ForPairs = Fusion.ForPairs
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local Ref = Fusion.Ref
local OnEvent = Fusion.OnEvent
local Cleanup = Fusion.Cleanup

local CatalogClient = BloxbizSDK.CatalogClient
local Components = CatalogClient.Components

local ScaledText = require(Components.ScaledText)

return function(props)
    props = FusionProps.GetValues(props, {
        ItemId = 0,
        IsBundle = false,
    })

    local iconInstance = Value()

    local isHovering = Value(false)

    return New "Frame" {
        Name = "Item",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        [Children] = {
            New "ImageLabel" {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),

                Size = Spring(Computed(function()
                    if isHovering:get() then
                        return UDim2.fromScale(1, 1)
                    else
                        return UDim2.fromScale(1, 1)
                    end
                end), 30),
                BackgroundTransparency = 1,
                [Ref] = iconInstance,

                [OnEvent "MouseEnter"] = function() isHovering:set(true) end,
                [OnEvent "MouseLeave"] = function() isHovering:set(false) end,

                Image = Computed(function()
                    local type = props.IsBundle:get() and "BundleThumbnail" or "Asset"

                    return string.format("rbxthumb://type=%s&id=%s&w=420&h=420", type, props.ItemId:get())
                end)
            }
        }
    }
end