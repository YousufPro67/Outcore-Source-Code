local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer

local GuiComponents = Gui.Components
local UICorner = require(GuiComponents.UICorner)
local TextButton = require(GuiComponents.TextButton)

return function(props)
	local isOptions = props.IsOptions

	local confirmState = Value(false)
	local isReportState = Value(false)

	Observer(isOptions):onChange(function()
		if isOptions:get() == "NotOwnPost" then
			isReportState:set(true)
		elseif isOptions:get() == "OwnPost" then
			isReportState:set(false)
		end

		if isOptions:get() == false then
			confirmState:set(false)
		end
	end)

	return New("Frame")({
		Name = "Options",

		Size = UDim2.fromScale(0.35, 0.225),
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		ZIndex = 3,

		Visible = Computed(function()
			return isOptions:get()
		end),

		[Children] = {
			TextButton({
				Color = Color3.fromRGB(255, 255, 255),
				TextColor = Color3.fromRGB(255, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.1),
				Size = UDim2.fromScale(0.9, 0.325),
				ZIndex = 5,

				Text = Computed(function()
					if confirmState:get() == true then
						return isReportState:get() == true and "Confirm Report?" or "Confirm Delete?"
					else
						return isReportState:get() == true and "Report" or "Delete"
					end
				end),

				OnActivated = function()
					if confirmState:get() == true then
						if isReportState:get() == true then
							props.OnReportPostButtonClicked(props.InteractedWithPostId)
						else
							props.OnDeletePostButtonClicked(props.InteractedWithPostId)
						end
					else
						confirmState:set(true)
					end
				end,
			}),

			TextButton({
				Text = "Cancel",
				Name = "CancelButton",
				Color = Color3.fromRGB(255, 255, 255),
				TextColor = Color3.fromRGB(0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.55),
				Size = UDim2.fromScale(0.9, 0.325),
				ZIndex = 5,

				OnActivated = function()
					props.IsOptions:set(false)
					confirmState:set(false)
				end,
			}),

			New("TextButton")({
				Name = "Background",
				Size = UDim2.fromScale(10, 10),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				AutoButtonColor = false,
				ZIndex = 3,
			}),

			UICorner({}),
		},
	})
end
