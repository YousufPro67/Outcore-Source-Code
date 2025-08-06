--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")

local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = script.Parent.Parent
local Generic = Components.Generic

local Button = require(Generic.Button)
local TextBox = require(Generic.TextBox)

export type Props = {
	Creating: Fusion.Value<boolean>,
	Enabled: Fusion.Value<boolean>,
	
	CreateCallback: (name: string) -> (),
	CancelCallback: () -> (),
}

return function(props: Props): TextButton
	local outfitName = Fusion.Value("")
	local loading = Fusion.Value(false)

    local inputBox = TextBox({
        Name = "Input",
        PlaceholderText = "Name your outfit",

        BackgroundColor3 = Color3.fromHex("4F545F"),
        BackgroundTransparency = 0,

        AnchorPoint = Vector2.new(0.5, 0.5),

        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.9, 0.5),
		Text = outfitName
    }) :: TextBox

	local cancelProps: Button.Props = {
		Position = UDim2.fromScale(0.62, 0.86),
		Size = UDim2.fromScale(0.2, 0.15),
		AnchorPoint = Vector2.new(0.5, 0.5),
		CornerRadius = UDim.new(0.2, 0),

		Text = "Cancel",
		Name = "Cancel",

		ImageTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},

		BackgroundColor3 = Color3.fromHex("4F545F"),
		BackgroundTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},
		
		TextTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			if enabled:get() then
                inputBox.Text = ""
				loading:set(true)

				props.CancelCallback()

				loading:set(false)
			end
		end,
	}
	local cancelButton = Button(cancelProps)

	local createProps: Button.Props = {
		Position = UDim2.fromScale(0.843, 0.86),
		Size = UDim2.fromScale(0.2, 0.15),
		AnchorPoint = Vector2.new(0.5, 0.5),
		CornerRadius = UDim.new(0.2, 0),

		Text = "Share",
		Name = "Share",

		Enabled = Fusion.Computed(function()
			local isLoading = loading:get()
			local name = outfitName:get()

			if isLoading then
				return false
			end

			if #name < 4 then
				return false
			end

			return true
		end),

		ImageTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},

		BackgroundColor3 = Color3.fromHex("4FAD74"),
		BackgroundTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},
		TextTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.8,
		},

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			if enabled:get() then 
				loading:set(true)

				local name = "Untitled Outfit"
				local length = string.len(inputBox.Text)
                if length > 0 then
                    name = inputBox.Text
                end

                inputBox.Text = ""
				props.CreateCallback(name)

				loading:set(false)
			end
		end,
	}
	local createButton = Button(createProps)

	return Fusion.New("TextButton")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(2, 2),
		BackgroundTransparency = 0.75,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		Selectable = false,
		Text = "",
		Visible = Fusion.Computed(function()
			return props.Creating:get()
		end, Fusion.cleanup),

		[Fusion.Children] = {
			Fusion.New("Frame")({
				Name = "Input",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),

				[Fusion.Children] = {
                    Fusion.New("UIStroke")({
                        Name = "UIStroke",
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Transparency = 0.5,
                    }),

					Fusion.New("UICorner")({
						Name = "UICorner",
						CornerRadius = UDim.new(0.065, 0),
					}),

					Fusion.New("TextLabel")({
						Name = "Title",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						Text = "Share Outfit",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 21,
						TextWrapped = true,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.05, 0.04),
						Size = UDim2.fromScale(0.45, 0.2),
					}),

					Fusion.New("Frame")({
						Name = "InputHolder",
						BackgroundColor3 = Color3.fromHex("4F545F"),
						BackgroundTransparency = 0,

						AnchorPoint = Vector2.new(0.5, 0.5),

						Position = UDim2.fromScale(0.5, 0.66),
						Size = UDim2.fromScale(0.9, 0.18),

						[Fusion.Children] = {
							inputBox :: any,

							Fusion.New("UICorner")({
								CornerRadius = UDim.new(0.2, 0),
							}),
						}
					}),

					Fusion.New("Frame")({
						Name = "Warning",
						BackgroundColor3 = Color3.fromRGB(92, 0, 17),
						BackgroundTransparency = 0,

						AnchorPoint = Vector2.new(0.5, 0.5),

						Position = UDim2.fromScale(0.5, 0.4),
						Size = UDim2.fromScale(0.9, 0.27),

						[Fusion.Children] = {
							Fusion.New("UICorner")({
								CornerRadius = UDim.new(0.14, 0),
							}),

							Fusion.New("ImageLabel")({
								Image = "rbxassetid://16166071441",
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.fromScale(0.025, 0.5),
								Size = UDim2.fromScale(0.07, 0.07),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								BackgroundTransparency = 1,
							}),

							Fusion.New("TextLabel")({
								Text = "Help keep Popmall safe for everyone. Posting inappropriate outfits will result in a ban.",
								LineHeight = 1.3,
								TextScaled = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.fromScale(0.12, 0.5),
								Size = UDim2.fromScale(0.8, 0.8),
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(255, 255, 255),
							}),
						}
					}),

					createButton,
					cancelButton,
				},
			}),
		},
	}) :: TextButton
end
