local Gui = script.Parent.Parent

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local SelectButton = require(GuiComponents.SelectButton)
local TextButton = require(GuiComponents.TextButton)

return function(props)
	local isReadOnly = props.Config.permissions == "read_only"
    local replyButtonVisible = not isReadOnly

    return {
        replyButtonVisible and TextButton {
            Name = "ReplyButton",
            Size = UDim2.fromScale(0.204, 0.657),
            Position = UDim2.fromScale(0.95, 0.5),
            AnchorPoint = Vector2.new(1, 0.5),
            TextSize = UDim2.fromScale(0.9, 0.6),
            CornerRadius = UDim.new(1, 0),
            ZIndex = 1,
            Bold = true,
            TextColor = Color3.fromRGB(255, 255, 255),
            Color = Color3.fromRGB(0, 170, 255),
            Text = "Reply",

            OnActivated = function()
                local playerProfile = props.LastLocalPlayerProfileData:get()
                if playerProfile == nil then
                    props.getLocalPlayerProfileData()
                end

                props.OnCommentButtonClicked()
            end,
        } or nil,

        SelectButton {
            Name = "Back",
            Text = "< Back",
            Size = UDim2.fromScale(0, 0.41),
            Color = Color3.fromRGB(255, 255, 255),
            Position = UDim2.fromScale(0.05, 0.5),
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Bold = true,

            OnActivated = function()
                props.OnBackButtonClicked()
            end,
        },

        Line {
            Size = UDim2.fromScale(1, 0.02),
        },
    }
end