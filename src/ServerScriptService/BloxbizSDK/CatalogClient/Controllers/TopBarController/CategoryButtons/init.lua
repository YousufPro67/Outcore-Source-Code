local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Mouse = player:GetMouse()
local Camera = workspace.CurrentCamera

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local Button = require(script.Button)

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local OnRequestPermissionRemote

local TOUCH_ENABLED = UserInputService.TouchEnabled

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForPairs = Fusion.ForPairs
local OnChange = Fusion.OnChange

local function validateInput(input: InputObject): boolean
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

	return isTouch or isClick
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local policy = PolicyService:GetPolicyInfoForPlayerAsync(player)

return function (props)
    props = FusionProps.GetValues(props, {
        Categories = {},
        CurrentCategory = 1,
        OnChange = FusionProps.Nil,

        Parent = FusionProps.Nil,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.zero,
    })

    local containerRef = Value()
    local absSize = Value(Vector2.zero)
    local isHovering = Value(false)

	local DragOldX = 0
	local LoggedX = 0
	local Delta = 0
	local Dragging = false

	local scrollX = Value(0)

	local buttonsData = {}
	local defaultSelection
	local currentSelectedCategory = Value()

	local screenSizeUpdate = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.wait()

		local mainFrame = containerRef:get()
		if mainFrame then
			local list = mainFrame:FindFirstChild("UIListLayout") :: UIListLayout
			if list then
				mainFrame.CanvasSize = UDim2.fromOffset(list.AbsoluteContentSize.X, 0)
			end
		end
	end)

    local function DragScroll()
        local X = Mouse.X
    
        local frame = containerRef:get()
        if Dragging and frame then
            Delta = X - (DragOldX or X)
        else
            Delta = lerp(Delta, 0, 0.05)
        end
    
        frame.CanvasPosition = Vector2.new(math.floor(frame.CanvasPosition.X - Delta), 0)
        DragOldX = X
    end

	if not TOUCH_ENABLED then
		RunService:BindToRenderStep("CategoryButtonScroll", 1, DragScroll)
	end

	local inputBegan = UserInputService.InputBegan:Connect(function(input: InputObject)
		if validateInput(input) and isHovering:get() then
			Dragging = true
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input: InputObject)
		if validateInput(input) then
			Dragging = false
			DragOldX = nil
		end
	end)

    local onCategoryClick = function(categoryId)
        local cb = props.OnChange:get()
        if cb then
            cb(categoryId)
        else
            props.CurrentCategory:set(categoryId)
        end
    end

    -- hide feed button if outfit feed is disabled globally
    local showFeedButton = Value(ConfigReader:read("CatalogOutfitFeedEnabled"))
    local showShopsFeedButton = Value(false)

    task.spawn(function()
        OnRequestPermissionRemote = BloxbizRemotes:WaitForChild("CatalogOnRequestPermissionRemote")
	    local _, feedPerms = OnRequestPermissionRemote:InvokeServer()

        if feedPerms.outfit_feed_disabled then
            showFeedButton:set(false)
        end

        if feedPerms.shops_enabled then
            showShopsFeedButton:set(true)
        end
    end)

    local feedButton = Button({
        LayoutOrder = 0,
        Id = "feed",
        Visible = showFeedButton,
        SelectedId = props.CurrentCategory,
        Text = "Outfits",
        Icon = "rbxassetid://15111160205",
        OnClick = function ()
            onCategoryClick("feed")
        end
    })

    local shopsButton = Button({
        LayoutOrder = 0,
        Id = "shops",
        Visible = showShopsFeedButton,
        SelectedId = props.CurrentCategory,
        Text = "Shops",
        Icon = "rbxassetid://135919290831398",
        OnClick = function ()
            onCategoryClick("shops")
        end,
    })

    -- tween to button on select --

    local tweenSig = Fusion.Observer(props.CurrentCategory):onChange(function()
        if not props.CurrentCategory:get() then
            return
        end

        local container = containerRef:get()
        local btnInstance = container:FindFirstChild(props.CurrentCategory:get())

        if not btnInstance then
            return
        end
		
		local btnOffset = btnInstance.AbsolutePosition.X - container.AbsolutePosition.X
		local preferredOffset = container.AbsoluteSize.X / 2 - btnInstance.AbsoluteSize.X / 2

		local newCanvasPos = math.max(0, container.CanvasPosition.X + (btnOffset - preferredOffset))
		
		if newCanvasPos ~= container.CanvasPosition.X then
			TweenService:Create(container, TweenInfo.new(0.5), {
				CanvasPosition = Vector2.new(newCanvasPos, 0)
			}):Play()
		end
    end)

    -- UI elements --

    return New "CanvasGroup" {
        Parent = props.Parent,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ClipsDescendants = true,

        [Out "AbsoluteSize"] = absSize,

        [OnEvent "MouseEnter"] = function()
            isHovering:set(true)
        end,
        [OnEvent "MouseLeave"] = function()
            isHovering:set(false)
        end,

        [Cleanup] = function()
            Fusion.cleanup(tweenSig)
        end,

        [Children] = {
            -- buttons --
            New "ScrollingFrame" {
                AutomaticCanvasSize = Enum.AutomaticSize.X,
                CanvasSize = UDim2.fromOffset(9084, 0),
                ElasticBehavior = Enum.ElasticBehavior.Always,
                ScrollBarImageTransparency = 1,
                ScrollingDirection = Enum.ScrollingDirection.X,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0, 0),
                Selectable = false,
                Size = UDim2.fromScale(1, 1),
                ClipsDescendants = false,

                [Ref] = containerRef,
                [OnChange("CanvasPosition")] = function(canvasPos)
                    scrollX:set(canvasPos.X)
                end,

                [Children] = {
                    -- New("UICorner")({
                    --     Name = "UICorner",
                    --     CornerRadius = UDim.new(0.2, 0),
                    -- }),

                    New("UIListLayout")({
                        Name = "UIListLayout",
                        Padding = Computed(function()
                            return UDim.new(0, absSize:get().Y / 8)
                        end),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    feedButton,
                    shopsButton,

                    ForPairs(
                        props.Categories,
                        function(categoryId: number, info: { [string]: any }): (number, TextButton?)
                            if not info.is_ad or (info.is_ad and policy.AreAdsAllowed) then
                                return categoryId, Button({
                                    Id = categoryId,
                                    SelectedId = props.CurrentCategory,

                                    LayoutOrder = categoryId,
                                    Text = info.name,

                                    OnClick = function ()
                                        onCategoryClick(categoryId)
                                    end
                                })
                            end

                            return categoryId, nil
                        end,
                        Fusion.cleanup
                    )
                },
            },

            -- gradient --
            New "UIGradient" {
                Transparency = Computed(function()
                    local fadeDistance = 20

                    local scroll = scrollX:get()
                    local fadeAlpha = math.clamp(scroll, 0, fadeDistance) / fadeDistance
                    local gradientStartAlpha = math.sin(fadeAlpha * math.pi/2)
                    local gradientEndAlpha = 1

                    local keypoints = {
                        NumberSequenceKeypoint.new(0, gradientStartAlpha)
                    }

                    -- add start keypoints
                    for i=0, 8 do
                        local alpha = (math.cos(i/8 * math.pi) + 1) / 2
                        
                        table.insert(keypoints,
                            NumberSequenceKeypoint.new((i/8 * 0.05) + 0.01, alpha * gradientStartAlpha)
                        )
                    end

                    -- add end keypoints
                    for i=0, 8 do
                        local alpha = (math.sin(i/8 * math.pi/2))
                        
                        table.insert(keypoints,
                            NumberSequenceKeypoint.new((i/8 * 0.05) + 0.95 - 0.01, alpha * gradientEndAlpha)
                        )
                    end
                    
                    table.insert(keypoints, NumberSequenceKeypoint.new(1, gradientEndAlpha))

                    return NumberSequence.new(keypoints)
                end)
            },
        }
    }
end