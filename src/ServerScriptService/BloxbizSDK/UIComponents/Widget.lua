local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local GuiService = game:GetService("GuiService")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local BloxbizSDK = script.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local IconModule = require(UtilsStorage:WaitForChild("Icon"))

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local Cleanup = Fusion.Cleanup
local Ref = Fusion.Ref

return function (props)
    props = FP.GetValues(props, {
        Parent = PlayerGui,
        Name = "Widget",
        Side = "right",
        Offset = 0,
        Margin = 10,
        Visible = true,
        Minimized = false,
        CornerRadius = UDim.new(0, 0),
        Size = UDim2.new(0, 300, 0, 250),
        BackgroundColor3 = Color3.new(0.160784, 0.160784, 0.164705),
        [Children] = FP.Nil,
    })

    local realSize = props.Size:get()

    local screenSize = Value(Vector2.new(800, 600))
    local widgetSize = Value(Vector2.new(realSize.X.Offset, realSize.Y.Offset))
    local isDragging = Value(false)
    local dragStart = Value(nil)
    local dragOffset = Value(Vector2.new(0, 0))
    local hideButton = Value(false)

    local widgetRef = Value()

    local anchoredPosition = Computed(function()
        local _side = props.Side:get()
        local _offset = props.Offset:get()
        local _margin = props.Margin:get()
        local _minimized = props.Minimized:get()
        local _screenSize = screenSize:get()
        local _widgetSize = widgetSize:get()

        if _side == "left" then
            return _minimized and UDim2.new(
                0, -_widgetSize.X - 1,
                0, _offset + _margin
            ) or UDim2.new(
                0, _margin,
                0, _offset + _margin
            )
        elseif _side == "right" then
            return _minimized and UDim2.new(
                0, _screenSize.X + 1,
                0, _offset + _margin
            ) or UDim2.new(
                0, _screenSize.X -_widgetSize.X - _margin,
                0, _offset + _margin
            )
        elseif _side == "top" then
            return UDim2.new(
                0, _offset + _margin,
                0, _margin
            )
        elseif _side == "bottom" then
            return UDim2.new(
                0, _offset + _margin,
                0, _screenSize.Y -_widgetSize.Y - _margin
            )
        else
            return UDim2.new(0, 0, 0, 0)
        end
    end)

    local mouse = Player:GetMouse()
    local onDown = function()
        if props.Visible:get() and Utils.isHovering(widgetRef:get(), mouse) then
            dragOffset:set(Vector2.new(0, 0))
            dragStart:set(Vector2.new(mouse.X, mouse.Y))
            isDragging:set(true)
        end
    end
    local onUp = function()
        if isDragging:get() then
            local _ogPos = anchoredPosition:get()
            local _newPos = Vector2.new(_ogPos.X.Offset, _ogPos.Y.Offset) + dragOffset:get()
            local _margin = props.Margin:get()
            local _screenSize = screenSize:get()
            local _widgetSize = widgetSize:get()

            local leftDist = _newPos.X - _margin
            local rightDist = _screenSize.X - _margin - _newPos.X - _widgetSize.X
            local topDist = _newPos.Y - _margin
            local bottomDist = _screenSize.Y - _margin - _newPos.Y - _widgetSize.Y
            local minDist = math.min(leftDist, rightDist, topDist, bottomDist)

            local prevSide = props.Side:get()
            if minDist == leftDist then
                props.Side:set("left")
                props.Offset:set(
                    math.max(
                        0, math.min(
                            _newPos.Y - _margin,
                            _screenSize.Y - _widgetSize.Y - 2 * _margin
                        )
                    )
                )

                if leftDist < -widgetSize:get().X / 2 then
                    props.Minimized:set(true)
                end
            elseif minDist == rightDist then
                props.Side:set("right")
                props.Offset:set(
                    math.max(
                        0, math.min(
                            _newPos.Y - _margin,
                            _screenSize.Y - _widgetSize.Y - 2 * _margin
                        )
                    )
                )

                if rightDist < -widgetSize:get().X / 2 then
                    props.Minimized:set(true)
                end
            elseif minDist == topDist then
                props.Side:set("top")
                props.Offset:set(
                    math.max(
                        0, math.min(
                            _newPos.X - _margin,
                            _screenSize.X - _widgetSize.X - 2 * _margin
                        )
                    )
                )
            elseif minDist == bottomDist then
                props.Side:set("bottom")
                props.Offset:set(
                    math.max(
                        0, math.min(
                            _newPos.X - _margin,
                            _screenSize.X - _widgetSize.X - 2 * _margin
                        )
                    )
                )
            end

            if props.Side:get() ~= prevSide and not props.Minimized:get() then
                hideButton:set(true)
                task.delay(0.5, function()
                    hideButton:set(false)
                end)
            end
        end

        isDragging:set(false)
        dragOffset:set(Vector2.new(0, 0))
        dragStart:set(nil)
    end
    local onMove = function()
        if isDragging:get() then
            local _start = dragStart:get()
            dragOffset:set(Vector2.new(mouse.X, mouse.Y) - _start)
        end
    end

    local _mouseDown = mouse.Button1Down:Connect(onDown)
    local _mouseUp = mouse.Button1Up:Connect(onUp)
    local _mouseMove = mouse.Move:Connect(onMove)

    local miniButtonAnchor = Spring(Computed(function()
        local _side = props.Side:get()
        if props.Minimized:get() then
            return _side == "right" and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
        else
            return _side == "right" and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
        end
    end), 30)

    return New "ScreenGui" {
        Name = props.Name,
        Parent = props.Parent,
        Enabled = props.Visible,

        [Out "AbsoluteSize"] = screenSize,

        [Children] = New "Frame" {
            Size = props.Size,
            Position = Spring(Computed(function()
                local _drag = isDragging:get()
                local _delta = dragOffset:get()

                return (
                    anchoredPosition:get() +
                    (_drag and UDim2.new(0, _delta.X, 0, _delta.Y) or UDim2.new())
                )
            end), 30),
            BackgroundTransparency = 1,

            [Ref] = widgetRef,
            [Children] = {
                New "CanvasGroup" {
                    Name = "Minimize",
                    GroupTransparency = 0.33,
                    BackgroundTransparency = 1,
                    AnchorPoint = miniButtonAnchor,
                    Visible = Computed(function()
                        local _side = props.Side:get()
                        local _anchorX = miniButtonAnchor:get().X

                        if hideButton:get() then
                            return false
                        end

                        return _side == "left" and _anchorX <= 0.99 or _side == "right" and _anchorX >= 0.01
                    end),
                    Size = UDim2.new(0, 32, 0.5, 0),
                    Position = Spring(Computed(function()
                        if props.Side:get() == "left" then
                            return UDim2.fromScale(1, 0.5)
                        else
                            return UDim2.fromScale(0, 0.5)
                        end
                    end), 20),
                    Rotation = Computed(function()
                        if props.Side:get() == "right" then
                            return 180
                        else
                            return 0
                        end
                    end),
                    [Children] = {
                        New "TextLabel" {
                            BackgroundColor3 = props.BackgroundColor3,
                            Size = UDim2.fromScale(0.5, 1),
                            Position = UDim2.fromScale(0, 0),
                            Text = "",
                        },
                        New "TextButton" {
                            BackgroundColor3 = props.BackgroundColor3,
                            Size = UDim2.fromScale(1, 1),
                            Text = "",
                            [Children] = New "UICorner" {
                                CornerRadius = UDim.new(0, 8)
                            },
                            [OnEvent "MouseButton1Click"] = function()
                                props.Minimized:set(false)
                            end
                        },
                        New "ImageLabel" {
                            BackgroundTransparency = 1,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(16, 16),
                            Image = "rbxassetid://119267428120720",
                            Rotation = 180
                        }
                    },
                },
                New "Frame" {
                    Name = "Container",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = props.BackgroundColor3,

                    [Children] = {
                        New "UICorner" {
                            CornerRadius = props.CornerRadius,
                        },
                        props[Children]
                    }
                }
            }
        },

        [Cleanup] = {_mouseDown, _mouseUp, _mouseMove}
    }
end