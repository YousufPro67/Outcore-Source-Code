--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

export type Props = {
	Name: string?,

	FocusLostCallback: (enterPressed: boolean) -> ()?,
	PlaceholderText: string?,

	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	TextXAlignment: Enum.TextXAlignment?,

	AnchorPoint: Vector2?,
	Size: UDim2?,
	Position: UDim2?,
	Text: string?,

    FeedbackOnEnter: boolean?,
}

return function(props: Props): TextBox
	props = FusionProps.GetValues(props, {
		Name = "SearchBox",
		Text = "",
		OnChange = FusionProps.Nil,
		FeedbackOnEnter = false,
		FocusLostCallback = FusionProps.Nil
	})

	local searchBox = Fusion.Value(nil)
	local placeHolderText = Fusion.Value(nil)

	return Fusion.New("TextBox")({
		Name = props.Name,
		PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
		Text = props.Text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,

		[Fusion.Ref] = searchBox,

		[Fusion.OnEvent("Focused")] = function()
			local sb = searchBox:get()
			local pht = placeHolderText:get()
			if sb and pht then
                props.Text:set("")

				sb.TextSize = sb.TextBounds.Y
				sb.TextScaled = true
			end
		end,

		[Fusion.OnChange("Text")] = function()
			local tb = searchBox:get()
			if tb then
				local newText = tb.Text:sub(1, 90)
				local cb = props.OnChange:get()

				if cb then
					cb(newText)
				else
					props.Text:set(newText)
				end
			end
		end,

		[Fusion.OnEvent("FocusLost")] = function(enterPressed: boolean)
			local sb = searchBox:get()
			local pht = placeHolderText:get()

			if sb and pht then
                if props.FeedbackOnEnter:get() then
                    if enterPressed then
						props.Text:set("")
                    end

					local cb = props.FocusLostCallback:get()
                    if cb then
                        cb(enterPressed)
                    end
                end
			end		
		end,

		[Fusion.OnChange("Text")] = function()
			local sb = searchBox:get()
			local pht = placeHolderText:get()
			if pht and sb then
				pht.Visible = sb.Text == ""
			end
		end,

		[Fusion.Children] = {
			Fusion.New("TextLabel")({
				Name = "Placeholder",
				Text = props.PlaceholderText or "",
                TextSize = 24,
                TextScaled = true,
				TextColor3 = Color3.fromRGB(196, 196, 196),
                TextTransparency = 0.5,
				TextWrapped = true,
				TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				--Size = UDim2.fromScale(.92, .8),
				Size = UDim2.fromScale(1, 1),

				[Fusion.Ref] = placeHolderText,
			}),

			Fusion.New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.065, 0),
			}),
		},
	}) :: TextBox
end
