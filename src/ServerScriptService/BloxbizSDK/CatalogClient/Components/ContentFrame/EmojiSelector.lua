local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local Components = script.Parent.Parent
local ItemGrid = require(Components.ItemGrid)
local ScaledText = require(Components.ScaledText)
local Button = require(script.Parent.Button)

local function getAllEmojiCodes()
    local emojis = {}

    local ranges = {
        {0x1F600, 0x1F64F},
        {0x1F300, 0x1F5FF},
        {0x1F680, 0x1F6FF},
        {0x2600,  0x26FF},
        {0x2700,  0x27BF},
        {0x1F900, 0x1F9FF},
    }

	local bannedEmojis = {"🍆", "🍌", "🍒", "🍑", "🔞", "🖕"}

    for _, range in ranges do
        for code = range[1], range[2] do
            local emoji = utf8.char(code)

			if table.find(bannedEmojis, emoji) then
				continue
			end

            table.insert(emojis, emoji)
        end
    end

    return emojis
end

local EMOJIS = getAllEmojiCodes()

return function(props)
	local parent = props.Parent
	local visible = props.Visible
	local selectedEmoji = props.SelectedEmoji

	return New "TextButton" {
		Name = "EmojiSelector",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(2, 2),
		BackgroundTransparency = 0.75,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		Selectable = false,
		Text = "",
		Visible = visible,
		Parent = parent,

		[Children] = {
			New "Frame" {
				Name = "Container",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.175, 0.31),

				[Children] = {
					ItemGrid {
						Size = UDim2.fromScale(0.9, 0.8),
						Position = UDim2.fromScale(0.5, 0.195),
						AnchorPoint = Vector2.new(0.5, 0),

						Gap = 15,
						Columns = 7,
						ItemRatio = 1 / 1,

						[Children] = {
							ForValues(EMOJIS, function(emojiCode)
								return New "TextButton" {
									AutoButtonColor = true,
									Text = emojiCode,
									TextScaled = true,
									BackgroundTransparency = 1,

									[OnEvent "Activated"] = function()
										visible:set(false)
										selectedEmoji:set(emojiCode)
										print(emojiCode)
									end,
								}
							end, Fusion.cleanup)
						},
					},

					Button({
						Text = "X",
						TextSize = UDim2.fromScale(0.6, 0.8),
						Size = UDim2.fromScale(0.1, 0.1),
						Position = UDim2.fromScale(0.86, 0.04),

						Color = {
							Default = Color3.fromRGB(231, 87, 87),
							MouseDown = Color3.fromRGB(177, 66, 66),
							Hover = Color3.fromRGB(141, 47, 47),
							Selected = Color3.fromRGB(255, 255, 255)
						},
						--TextColor3 = Color3.fromRGB(25, 25, 25),

						OnClick = function()
							visible:set(false)
						end,
					}),

					New "TextLabel" {
						Name = "Title",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						Text = "Select emoji",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 21,
						TextWrapped = true,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.05, 0.04),
						Size = UDim2.fromScale(0.45, 0.1),
					},

					New "UICorner" {
						Name = "UICorner",
						CornerRadius = UDim.new(0.065, 0),
					},

					New("UIStroke")({
                        Name = "UIStroke",
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Transparency = 0.5,
					}),
				},
			},
		},
	}
end
