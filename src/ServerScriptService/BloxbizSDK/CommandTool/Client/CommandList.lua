local Players = game:GetService("Players")

local CommandTool = script.Parent.Parent
local BloxbizSDK = CommandTool.Parent

local Config = require(CommandTool.Config)
local Commands = require(CommandTool.Commands)

local UIComponents = BloxbizSDK.UIComponents
local ItemGrid = require(UIComponents.ItemGrid)
local SearchBar = require(UIComponents.SearchBar)

local Fusion = require(BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs
local Computed = Fusion.Computed

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local PREFIX = Config:Read("CommandPrefix")

return function(props)
    local screenSize = Camera.ViewportSize

    local playerRanks = props.PlayerRanks
    local selectingUser = props.SelectingUser
    local selectedCommand = props.SelectedCommand

    local searchQuery = Value()

    return New "Frame" {
        Name = "CommandList",
        Size = UDim2.fromScale(0.85, 0.755),
        Position = UDim2.fromScale(0.5, 0.18),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,

        Visible = Computed(function()
            return not selectingUser:get()
        end),

        [Children] = {
            SearchBar {
                PlaceholderText = "Search",
                Size = UDim2.fromScale(1, 0.15),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                CornerRadius = UDim.new(0.25, 0),
                HideStroke = true,

                OnSearch = function(text)
                    searchQuery:set(text)
                end,
            },

            ItemGrid {
                Size = UDim2.fromScale(1, 0.82),
                Position = UDim2.fromScale(0.5, 0.18),
                AnchorPoint = Vector2.new(0.5, 0),

                Gap = 7,
                Columns = 2,
                ItemRatio = 1 / 1,

                [Children] = {
                    ForPairs(Commands, function(id, data)
                        local commandName = data.Name
                        local lowerName = commandName:lower()

                        return id, New "TextButton" {
                            Name = id,
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(68, 128, 255),
                            AutoButtonColor = true,

                            Visible = Computed(function()
                                local query = searchQuery:get()
                                if not query then
                                    return true
                                end

                                local visible = lowerName:find(query:lower())
                                return visible
                            end),

                            [OnEvent "Activated"] = function()
                                if data.Args == "None" then
                                    props.RunCommand(LocalPlayer, id)
                                else
                                    selectedCommand:set(id)
                                    selectingUser:set(true)
                                end
                            end,

                            [Children] = {
                                New "TextLabel" {
                                    Text = string.format("%s<b>%s</b>", PREFIX, commandName),
                                    Size = UDim2.fromScale(0.85, 0.15),
                                    Position = UDim2.fromScale(0.5, 0.07),
                                    AnchorPoint = Vector2.new(0.5, 0),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = screenSize.Y / 35,
                                    BackgroundTransparency = 1,
                                    RichText = true,
                                },

                                New "TextLabel" {
                                    Text = string.format("<b>%s</b>", data.Description),
                                    Size = UDim2.fromScale(0.85, 0.5),
                                    Position = UDim2.fromScale(0.5, 0.22),
                                    AnchorPoint = Vector2.new(0.5, 0),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = screenSize.Y / 35,
                                    BackgroundTransparency = 1,
                                    TextTransparency = 0.3,
                                    TextWrapped = true,
                                    RichText = true,
                                },

                                New "ImageLabel" {
                                    Name = "Icon",
                                    Position = UDim2.fromScale(0.075, 0.925),
                                    SizeConstraint = Enum.SizeConstraint.RelativeXX,
                                    AnchorPoint = Vector2.new(0, 1),
                                    BackgroundTransparency = 1,

                                    Size = Computed(function()
                                        local ranks = playerRanks:get()
                                        for _, rank in ranks do
                                            if Config:CanUseCommand(rank, id) then
                                                return UDim2.fromScale(0.175, 0.175)
                                            end
                                        end
                                        return UDim2.fromScale(0.2, 0.2)
                                    end),

                                    Image = Computed(function()
                                        local ranks = playerRanks:get()
                                        for _, rank in ranks do
                                            if Config:CanUseCommand(rank, id) then
                                                return "rbxassetid://127514277773886"
                                            end
                                        end
                                        return "rbxassetid://80762101011296"
                                    end),
                                },

                                New "UICorner" {
                                    CornerRadius = UDim.new(0.1, 0),
                                },
                            },
                        }
                    end, Fusion.cleanup),
                },
            },
        },
    }
end