

local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")

local AvatarHandler = require(CatalogClient.Classes.AvatarHandler)

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = CatalogClient.Components

local InteractionFrame = require(script.Parent.InteractionFrame)
local Button = require(Components.Button)

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

return function (props)
    props = FP.GetValues(props, {
        AssetId = FP.Required,
        SelectedId = FP.Nil,
        OnTry = FP.Callback,
        OnBuy = FP.Callback,
        EquippedItems = FP.Required,
        CornerRadius = 3,

        BackgroundColor3 = Color3.fromHex("373B43")
    })

    local isSelected = Fusion.Computed(function()
        return props.SelectedId:get() == props.AssetId:get()
    end)

    local isEquipped = Fusion.Computed(function()
		local equipped = props.EquippedItems:get()
		
		for matchId, _ in pairs(equipped) do
			if tostring(props.AssetId:get()) == tostring(matchId) then
				return true
			end
		end

		return false
	end)

    return New "TextButton" {
        Size = UDim2.fromScale(1, 1),
        
        BackgroundColor3 = props.BackgroundColor3,
        AutoButtonColor = Computed(function()
            return not isSelected:get()
        end),

        [OnEvent "Activated"] = function()
            props.SelectedId:set(props.AssetId:get())
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = Computed(function()
                    return UDim.new(0, props.CornerRadius:get())
                end)
            },
            New "CanvasGroup" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [Children] = {
                    New "UICorner" {
                        CornerRadius = Computed(function()
                            return UDim.new(0, props.CornerRadius:get())
                        end)
                    },
        
                    -- preview image
                    New "ImageLabel" {
                        Image = Computed(function()
                            return string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", props.AssetId:get())
                        end),
        
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1
                    },

                    InteractionFrame {
                        Selected = isSelected,
                        [Children] = {
                            -- buy button
                            Button {
                                Size = UDim2.fromScale(0.8, 0.35),
                                Text = "Buy",
                                OnClick = props.OnBuy,
                                BackgroundColor3 = Color3.fromRGB(79, 173, 116),
                                TextColor3 = Color3.new(1, 1, 1)
                            },
                            -- try button
                            Button {
                                LayoutOrder = 2,
                                Size = UDim2.fromScale(0.8, 0.35),
                                Text = Computed(function()
                                    return isEquipped:get() and "Remove" or "Try"
                                end),
                                OnClick = props.OnTry
                            }
                        }
                    }
                }
            }
        }
    }
end