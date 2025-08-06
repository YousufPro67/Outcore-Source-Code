local RunService = game:GetService("RunService")

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer

local GuiComponents = Gui.Components
local UICorner = require(GuiComponents.UICorner)

local INVISIBLE_TIME = 0 --arbitrary time loading state should be invisible before displaying

return function(props)
	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = true

	local invisibleTimeElapsed = Value(false)
	local spinnerValue = Value()
	local loadingObserver = Observer(props.IsLoading)
	local connection

	loadingObserver:onChange(function()
		if props.IsLoading:get() == true then
			connection = RunService.RenderStepped:Connect(function()
				local spinner = spinnerValue:get()
				if not spinner then
					return
				end

				spinner.Rotation += 1
			end)

			task.delay(INVISIBLE_TIME, function()
				if not props.IsLoading:get() then
					return
				end
				invisibleTimeElapsed:set(true)
			end)
		elseif props.IsLoading:get() == false then
			if connection then
				connection:Disconnect()
				connection = nil
			end

			invisibleTimeElapsed:set(false)
		end
	end)

	return New("TextButton")({
		Name = "LoadingState",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BackgroundTransparency = 0.05,
		AutoButtonColor = false,
		ZIndex = 100,

		Size = Computed(function()
			local isHomeFeed = props.isFeedTypeHomeFeed(props.FetchingFeedTypeValue:get())

			if props.IsPosting:get() then
				return UDim2.fromScale(1, 0.85)
			elseif isHomeFeed then
				return UDim2.fromScale(1, 0.763)
			else
				return UDim2.fromScale(1, 0.82)
			end
		end),

		Position = Computed(function()
			local isHomeFeed = props.isFeedTypeHomeFeed(props.FetchingFeedTypeValue:get())

			if props.IsPosting:get() then
				return UDim2.fromScale(0.5, 0.145)
			elseif isHomeFeed then
				return UDim2.fromScale(0.5, 0.151)
			else
				return UDim2.fromScale(0.5, 0.1)
			end
		end),

		Visible = Computed(function()
			return invisibleTimeElapsed:get() and props.IsLoading:get()
		end),

		[Children] = {
			New("TextLabel")({
				Name = "Info",
				Text = "Loading...",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.5, 0.05),
				Position = UDim2.fromScale(0.5, 0.525),
				AnchorPoint = Vector2.new(0.5, 0.5),
				TextScaled = true,
				FontFace = font,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				ZIndex = 101,
			}),

			New("ImageLabel")({
				Name = "Spinner",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.1, 0.1),
				Position = UDim2.fromScale(0.5, 0.425),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://11304130802",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 101,

				[Ref] = spinnerValue,
			}),

			UICorner({}),
		},
	})
end
