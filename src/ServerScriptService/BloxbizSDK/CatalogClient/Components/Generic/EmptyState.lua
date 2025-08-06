--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

export type Props = {
	Action: string?,
	Enabled: boolean?,
	Visible: any,
	Description: string,
	Callback: () -> ()?,
}

local Components = script.Parent.Parent
local Generic = Components.Generic

local Button = require(Generic.Button)

return function(props: Props): Frame
	local button = nil
	if props.Action then
		local actionProps: Button.Props = {
			Name = "Action",
	
			Position = UDim2.fromScale(0.5, 0.75),
			Size = UDim2.fromScale(0.5, 1),
			AnchorPoint = Vector2.new(0.5, 0),
			CornerRadius = UDim.new(0.2, 0),
	
			Enabled = if props.Enabled ~= nil then props.Enabled else true,
			Text = props.Action,
	
			ImageTransparency = {
				Default = 0,
				Hover = 0.2,
				MouseDown = 0.5,
				Disabled = 0.8,
			},
	
			BackgroundColor3 = {
				Default = Color3.new(1,1,1),
				Hover = Color3.new(1,1,1),
				MouseDown = Color3.new(1,1,1),
				Disabled = Color3.new(1,1,1),
			},
			BackgroundTransparency = {
				Default = 0,
				Hover = 0.2,
				MouseDown = 0.5,
				Disabled = 0.8,
			},
			
			TextColor3 = {
				Default = Color3.new(0,0,0),
				Hover = Color3.new(0,0,0),
				MouseDown = Color3.new(0,0,0),
				Disabled = Color3.new(0,0,0),
			},
			TextTransparency = {
				Default = 0,
				Hover = 0.2,
				MouseDown = 0.5,
				Disabled = 0.8,
			},
	
			Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
				if enabled:get() and props.Callback then
					props.Callback()
				end
			end,
		}
		button = Button(actionProps)
	end

	return Fusion.New("Frame")({
		Name = "EmptyStateFrame",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.3),
		Visible = props.Visible,

		[Fusion.Children] = {
			Fusion.New("Frame")({
				Name = "EmptyStateFrame",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.3),
				Size = UDim2.new(0.5, 0, 0.2, 0),
				Visible = true,
				
				[Fusion.Children] = {
					Fusion.New("TextLabel")({
						Name = "Info",
						Text = props.Description,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 14,
						TextWrapped = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0),
						Size = UDim2.fromScale(1, 0.5),
					}),

					button,
				}
			}),
		},
	}) :: Frame
end
