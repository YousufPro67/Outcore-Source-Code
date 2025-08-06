local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent

export type DataSet = {
	Instance: Frame,
	SearchBox: TextBox,
	PlaceHolderText: TextLabel,
	SearchButton: TextButton,
	CancelSearchButton: TextButton,
}

local function ToggleSearchBar(searchBox: TextBox, searchButton: ImageButton, expand: boolean)
	searchBox.Text = ""
	searchButton.Visible = not expand
end

local function CategorySearchBar(searchCallback: (keyword: string?) -> ()): DataSet
	local searchBox = Value()
	local placeHolderText = Value()
	local searchButton = Value()
	local cancelSearchButton = Value()

	local bar = New("Frame")({
		Name = "SearchBar",
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Position = UDim2.fromScale(0.262, 0),
		Size = UDim2.fromScale(0.3, 1),

		[Children] = {
			New("ImageLabel")({
				Name = "Icon",
				Image = "rbxassetid://10840634914",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.035, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 2,
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.225, 0),
			}),

			New("UIStroke")({
				Name = "StandardStroke",
				Color = Color3.fromRGB(79, 84, 95),
				Thickness = 1.5,
			}),

			New("TextBox")({
				Name = "SearchBox",
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 24,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.15, 0.5),
				Size = UDim2.fromScale(0.6, 0.505),

				[Ref] = searchBox,

				[OnEvent("Focused")] = function()
					searchBox:get().TextSize = searchBox:get().TextBounds.Y
					searchBox:get().TextScaled = false
				end,

				[OnEvent("FocusLost")] = function(enterPressed: boolean)
					searchBox:get().TextScaled = true

					if enterPressed then
						local text: string = searchBox:get().Text
						local strWithoutSpace = text:gsub(" ", "")
						ToggleSearchBar(searchBox:get(), searchButton:get(), false)

						if string.len(strWithoutSpace) > 0 then
							cancelSearchButton:get().Visible = true
							searchButton:get().Visible = false

							placeHolderText:get().Text = string.format('Searching for "%s"', text)
							searchCallback(text)
						end
					end
				end,

				[OnChange("Text")] = function()
					placeHolderText:get().Visible = searchBox:get().Text == ""
				end,

				[Children] = {
					New("TextLabel")({
						Name = "Placeholder",
						Text = "Search keyword",
						TextColor3 = Color3.fromRGB(128, 128, 128),
						TextScaled = true,
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),

						[Ref] = placeHolderText,
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
				Size = UDim2.fromScale(1, 1),
				Visible = false,
				ZIndex = 2,

				[Ref] = searchButton,

				[OnEvent("Activated")] = function()
					searchButton:get().Visible = false
					ToggleSearchBar(searchBox:get(), searchButton:get(), true)
					searchBox:get():CaptureFocus()
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
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.3, 1),
				Visible = false,

				[Ref] = cancelSearchButton,

				[OnEvent("Activated")] = function()
					cancelSearchButton:get().Visible = false
					placeHolderText:get().Text = "Search keyword"
					searchButton:get().Visible = true
					ToggleSearchBar(searchBox:get(), searchButton:get(), false)
					searchCallback()
				end,

				[Children] = {
					New("TextLabel")({
						Name = "TextLabel",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						Text = "Cancel",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 14,
						TextWrapped = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.55, 0.8),
					}),
				},
			}),
		},
	})

	return {
		Instance = bar,
		SearchBox = searchBox:get(),
		PlaceHolderText = placeHolderText:get(),
		SearchButton = searchButton:get(),
		CancelSearchButton = cancelSearchButton:get(),
		Reset = function()
			cancelSearchButton:get().Visible = false
			placeHolderText:get().Text = "Search keyword"
			searchButton:get().Visible = true
			ToggleSearchBar(searchBox:get(), searchButton:get(), false)
		end,
	}
end

return CategorySearchBar
