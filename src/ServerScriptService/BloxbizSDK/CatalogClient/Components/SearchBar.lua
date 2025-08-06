local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent

export type DataSet = {
	Instance: Frame,
	SearchBox: TextBox,
	PlaceHolderText: TextLabel,
	SearchButton: TextButton,
	CancelSearchButton: TextButton,
}

local Colors = {
	Default = Color3.fromRGB(41, 43, 48),
	Collapsed = Color3.fromRGB(0, 0, 0),
	MouseDown = Color3.fromRGB(15, 15, 15),
	Hover = Color3.fromRGB(30, 30, 30),
}

local ICON_RATIO = 1.04

local function CategorySearchBar(props): DataSet
	props = FusionProps.GetValues(props, {
		OnSearch = FusionProps.Nil,
		PlaceholderText = "Search keyword",
		Query = "",
		SearchBoxText = "",
		Visible = true,
		Disabled = false,
		Toggleable = false,
		Toggle = true
	})

	local viewportSize = Value(Vector2.zero)
	local viewportSig = game:GetService("RunService").RenderStepped:connect(function()
		if viewportSize:get() ~= workspace.Camera.ViewportSize then
			viewportSize:set(workspace.Camera.ViewportSize)
		end
	end)

	local searchInput = Value()
	local searchButton = Value()
	local cancelSearchButton = Value()

	local sbSize = Value(Vector2.zero)
	local sbHeight = Computed(function()
		return sbSize:get().Y
	end)

	local SearchBox = Value(nil)

	local isOpen = Fusion.Computed(function()
		if props.Toggleable:get() then
			return props.Toggle:get()
		else
			return true
		end
	end)

	local openSize = props.Size
	local closeSize = Fusion.Computed(function()
		local baseSize = props.Size:get()
		local height = sbHeight:get()
		local width = UDim.new(0, height * ICON_RATIO)
		return UDim2.new(width, baseSize.Y)
	end)
	local Size = -- Fusion.Spring(
		Computed(function()
			viewportSize:get()

			if isOpen:get() then
				return openSize:get()
			else
				return closeSize:get()
			end
		end)
	-- , 25)
	local TextTransparency = Spring(Computed(function()
		if isOpen:get() then
			return 0
		else
			return 1
		end
	end), 20)
	local TextVisible = Computed(function()
		if TextTransparency:get() == 1 then
			return false
		else
			return true
		end
	end)
	local CancelVisible = Computed(function()
		return TextVisible:get() and #(props.Query:get() or "") > 0
	end)

	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local function search(isCancel)
		local cb = props.OnSearch:get()

		local query = props.SearchBoxText:get()
		if props.Query.set then
			props.Query:set(query)
		end
		props.SearchBoxText:set("")

		if cb and (isCancel or (#query > 0)) then
			cb(query)
		end
	end

	return New("TextButton")({
		Name = "SearchBar",
		Text = "",
		BackgroundColor3 = Fusion.Spring(Fusion.Computed(function()
			if (not props.Toggleable:get()) or props.Toggle:get() then
				return Colors.Default
			end
			if isHeldDown:get() then
				return Colors.MouseDown
			elseif isHovering:get() then
				return Colors.Hover
			else
				return Colors.Collapsed
			end
		end)),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		Size = Size,
		Parent = props.Parent,
		Visible = props.Visible,
		[Ref] = SearchBox,

		[Out "AbsoluteSize"] = sbSize,

		[Fusion.Cleanup] = function()
			Fusion.cleanup(viewportSig)
		end,

		[OnEvent("MouseButton1Down")] = function()
            isHeldDown:set(true)
        end,

        [OnEvent("MouseButton1Up")] = function()
            isHeldDown:set(false)
        end,

        [OnEvent("MouseEnter")] = function()
            isHovering:set(true)
        end,

        [OnEvent("MouseLeave")] = function()
            isHovering:set(false)
            isHeldDown:set(false)
        end,

		[Children] = {
			New("ImageButton")({
				Name = "Icon",
				Image = "rbxassetid://10840634914",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = Fusion.Computed(function()
					return UDim2.new(0, sbHeight:get()/2 * ICON_RATIO, 0.5, 0)
				end),
				Size = UDim2.fromScale(0.5, 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 2,

				[OnEvent "Activated"] = function()
					props.Toggle:set(not props.Toggle:get())
				end,
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.225, 0),
			}),

			New("UIStroke")({
				Name = "StandardStroke",
				Color = Color3.fromRGB(79, 84, 95),
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),

			New("TextBox")({
				Name = "SearchBox",
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
				Text = props.SearchBoxText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 24,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				TextTransparency = TextTransparency,
				Visible = TextVisible,
				Position = Fusion.Computed(function()
					return UDim2.new(0, sbHeight:get() * ICON_RATIO, 0.5, 0)
				end),
				Size = Fusion.Computed(function()
					return UDim2.new(1, -sbHeight:get() * (ICON_RATIO + (CancelVisible:get() and 1 or 0.2)), 0.5, 0)
				end),

				[Out "Text"] = props.SearchBoxText,

				[Ref] = searchInput,

				[OnEvent("Focused")] = function()
					searchInput:get().TextSize = searchInput:get().TextBounds.Y
					searchInput:get().TextScaled = false
				end,

				[OnEvent("FocusLost")] = function(enterPressed: boolean)
					searchInput:get().TextScaled = true

					if enterPressed then
						search()
					end
				end,

				[Children] = {
					New("TextLabel")({
						Name = "Placeholder",
						Text = Fusion.Computed(function()
							local query = props.Query:get()
					
							if #(query or "") == 0 then
								return props.PlaceholderText:get()
							else
								return query
							end
						end),
						Visible = Fusion.Computed(function()
							return TextVisible:get() and #props.SearchBoxText:get() == 0
						end),
						TextColor3 = Color3.fromRGB(149, 149, 149),
						TextScaled = true,
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						TextTransparency = TextTransparency,
						Size = UDim2.fromScale(1, 1)
					}),
				},
			}),

			New("TextButton")({
				Name = "SearchButton",
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				TextTransparency = TextTransparency,
				Size = UDim2.fromScale(1, 1),
				Visible = Fusion.Computed(function()
					if props.Toggleable:get() then
						return not props.Toggle:get()
					else
						return false
					end
				end),
				ZIndex = 2,

				[Ref] = searchButton,

				[OnEvent("Activated")] = function()
					props.Toggle:set(not props.Toggle:get())
				end,
			}),

			New("TextButton")({
				Name = "CancelButton",
				RichText = true,
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 20,
				TextWrapped = true,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				TextTransparency = TextTransparency,
				Position = UDim2.fromScale(1, 0.5),
				Size = Computed(function()
					return UDim2.new(0, sbHeight:get(), 1, 0)
				end),
				Visible = CancelVisible,

				[Ref] = cancelSearchButton,

				[OnEvent("Activated")] = function()
					if props.Query.set then
						props.Query:set("")
					end

					props.SearchBoxText:set("")
					isHovering:set(false)
					isHeldDown:set(false)
					search(true)
				end,

				[Children] = {
					New("UISizeConstraint")({
						MaxSize = Vector2.new(100, math.huge)
					}),
					New("ImageLabel")({
						Name = "Icon",
						Image = "rbxassetid://14542644751",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						ImageTransparency = TextTransparency,
 						Visible = TextVisible,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.4, 0.4),
					}),
				},
			}),
		},
	})
end

return CategorySearchBar
