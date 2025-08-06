return function()
	local BloxbizDialogue = Instance.new("ScreenGui")
	BloxbizDialogue.Name = "BloxbizDialogue"
	BloxbizDialogue.Enabled = false
	BloxbizDialogue.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	BloxbizDialogue.ResetOnSpawn = false

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.AnchorPoint = Vector2.new(0.5, 1)
	Main.SizeConstraint = Enum.SizeConstraint.RelativeYY
	Main.Size = UDim2.new(0.65, 0, 0.229, 0)
	Main.BackgroundTransparency = 1
	Main.Position = UDim2.new(0.5, 0, 0.9, 0)
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Main.Parent = BloxbizDialogue

	local LikertScale = Instance.new("Frame")
	LikertScale.Name = "LikertScale"
	LikertScale.AnchorPoint = Vector2.new(0.5, 0)
	LikertScale.Size = UDim2.new(1, 0, 0.6557, 0)
	LikertScale.Visible = false
	LikertScale.BackgroundTransparency = 1
	LikertScale.Position = UDim2.new(0.5, 0, 0.344, 0)
	LikertScale.BorderSizePixel = 0
	LikertScale.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	LikertScale.Parent = Main

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0.012, 0)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout.Parent = LikertScale

	local LSOption1 = Instance.new("TextButton")
	LSOption1.Text = ""
	LSOption1.Name = "Option1"
	LSOption1.AnchorPoint = Vector2.new(0.5, 0.5)
	LSOption1.Size = UDim2.fromScale(0.19, 0.5)
	LSOption1.BackgroundTransparency = 0.05
	LSOption1.BorderSizePixel = 0
	LSOption1.AutoButtonColor = false
	LSOption1.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	LSOption1.Parent = LikertScale

	local LSTextLabel = Instance.new("TextLabel")
	LSTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	LSTextLabel.Size = UDim2.new(0.845, 0, 0.6, 0)
	LSTextLabel.BackgroundTransparency = 1
	LSTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	LSTextLabel.TextColor3 = Color3.fromRGB(51, 51, 51)
	LSTextLabel.Text = "Strongly Disagree"
	LSTextLabel.TextScaled = true
	LSTextLabel.Font = Enum.Font.Ubuntu
	LSTextLabel.Parent = LSOption1

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0.15, 0)
	UICorner.Parent = LSOption1

	local LSOption2 = Instance.new("TextButton")
	LSOption2.Text = ""
	LSOption2.Name = "Option2"
	LSOption2.AnchorPoint = Vector2.new(0.5, 0.5)
	LSOption2.Size = UDim2.fromScale(0.19, 0.5)
	LSOption2.BackgroundTransparency = 0.05
	LSOption2.BorderSizePixel = 0
	LSOption2.AutoButtonColor = false
	LSOption2.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	LSOption2.Parent = LikertScale

	local LSTextLabel2 = Instance.new("TextLabel")
	LSTextLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
	LSTextLabel2.Size = UDim2.new(0.845, 0, 0.3, 0)
	LSTextLabel2.BackgroundTransparency = 1
	LSTextLabel2.Position = UDim2.new(0.5, 0, 0.5, 0)
	LSTextLabel2.TextColor3 = Color3.fromRGB(51, 51, 51)
	LSTextLabel2.Text = "Disagree"
	LSTextLabel2.TextScaled = true
	LSTextLabel2.Font = Enum.Font.Ubuntu
	LSTextLabel2.Parent = LSOption2

	local UICorner2 = Instance.new("UICorner")
	UICorner2.CornerRadius = UDim.new(0.15, 0)
	UICorner2.Parent = LSOption2

	local LSOption3 = Instance.new("TextButton")
	LSOption3.Text = ""
	LSOption3.Name = "Option3"
	LSOption3.AnchorPoint = Vector2.new(0.5, 0.5)
	LSOption3.Size = UDim2.fromScale(0.19, 0.5)
	LSOption3.BackgroundTransparency = 0.05
	LSOption3.BorderSizePixel = 0
	LSOption3.AutoButtonColor = false
	LSOption3.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	LSOption3.Parent = LikertScale

	local LSTextLabel3 = Instance.new("TextLabel")
	LSTextLabel3.AnchorPoint = Vector2.new(0.5, 0.5)
	LSTextLabel3.Size = UDim2.new(0.845, 0, 0.3, 0)
	LSTextLabel3.BackgroundTransparency = 1
	LSTextLabel3.Position = UDim2.new(0.5, 0, 0.5, 0)
	LSTextLabel3.TextColor3 = Color3.fromRGB(51, 51, 51)
	LSTextLabel3.Text = "Undecided"
	LSTextLabel3.TextScaled = true
	LSTextLabel3.Font = Enum.Font.Ubuntu
	LSTextLabel3.Parent = LSOption3

	local UICorner3 = Instance.new("UICorner")
	UICorner3.CornerRadius = UDim.new(0.15, 0)
	UICorner3.Parent = LSOption3

	local LSOption4 = Instance.new("TextButton")
	LSOption4.Text = ""
	LSOption4.Name = "Option4"
	LSOption4.AnchorPoint = Vector2.new(0.5, 0.5)
	LSOption4.Size = UDim2.fromScale(0.19, 0.5)
	LSOption4.BackgroundTransparency = 0.05
	LSOption4.BorderSizePixel = 0
	LSOption4.AutoButtonColor = false
	LSOption4.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	LSOption4.Parent = LikertScale

	local LSTextLabel4 = Instance.new("TextLabel")
	LSTextLabel4.AnchorPoint = Vector2.new(0.5, 0.5)
	LSTextLabel4.Size = UDim2.new(0.845, 0, 0.3, 0)
	LSTextLabel4.BackgroundTransparency = 1
	LSTextLabel4.Position = UDim2.new(0.5, 0, 0.5, 0)
	LSTextLabel4.TextColor3 = Color3.fromRGB(51, 51, 51)
	LSTextLabel4.Text = "Agree"
	LSTextLabel4.TextScaled = true
	LSTextLabel4.Font = Enum.Font.Ubuntu
	LSTextLabel4.Parent = LSOption4

	local UICorner4 = Instance.new("UICorner")
	UICorner4.CornerRadius = UDim.new(0.15, 0)
	UICorner4.Parent = LSOption4

	local LSOption5 = Instance.new("TextButton")
	LSOption5.Text = ""
	LSOption5.Name = "Option5"
	LSOption5.AnchorPoint = Vector2.new(0.5, 0.5)
	LSOption5.Size = UDim2.fromScale(0.19, 0.5)
	LSOption5.BackgroundTransparency = 0.05
	LSOption5.BorderSizePixel = 0
	LSOption5.AutoButtonColor = false
	LSOption5.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	LSOption5.Parent = LikertScale

	local LSTextLabel5 = Instance.new("TextLabel")
	LSTextLabel5.AnchorPoint = Vector2.new(0.5, 0.5)
	LSTextLabel5.Size = UDim2.new(0.845, 0, 0.6, 0)
	LSTextLabel5.BackgroundTransparency = 1
	LSTextLabel5.Position = UDim2.new(0.5, 0, 0.5, 0)
	LSTextLabel5.TextColor3 = Color3.fromRGB(51, 51, 51)
	LSTextLabel5.Text = "Strongly Agree"
	LSTextLabel5.TextScaled = true
	LSTextLabel5.Font = Enum.Font.Ubuntu
	LSTextLabel5.Parent = LSOption5

	local UICorner5 = Instance.new("UICorner")
	UICorner5.CornerRadius = UDim.new(0.15, 0)
	UICorner5.Parent = LSOption5

	local Options = Instance.new("Frame")
	Options.Name = "Options"
	Options.AnchorPoint = Vector2.new(0.5, 0)
	Options.Size = UDim2.new(1, 0, 0.6557, 0)
	Options.BackgroundTransparency = 1
	Options.Position = UDim2.new(0.5, 0, 0.344, 0)
	Options.BorderSizePixel = 0
	Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Options.Parent = Main

	local UIGridLayout = Instance.new("UIGridLayout")
	UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout.CellSize = UDim2.new(0.4941176, 0, 0.475, 0)
	UIGridLayout.CellPadding = UDim2.new(0.0117647, 0, 0.05, 0)
	UIGridLayout.Parent = Options

	local Option1 = Instance.new("Frame")
	Option1.Name = "Option1"
	Option1.AnchorPoint = Vector2.new(0.5, 0.5)
	Option1.Visible = false
	Option1.Size = UDim2.new(0, 100, 0, 100)
	Option1.BackgroundTransparency = 0.05
	Option1.BorderSizePixel = 0
	Option1.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	Option1.Parent = Options

	local TextButton = Instance.new("TextButton")
	TextButton.AnchorPoint = Vector2.new(0.5, 0.5)
	TextButton.Size = UDim2.new(0.845, 0, 0.8, 0)
	TextButton.BackgroundTransparency = 1
	TextButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextButton.BorderSizePixel = 0
	TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.FontSize = Enum.FontSize.Size24
	TextButton.TextSize = 20
	TextButton.TextColor3 = Color3.fromRGB(51, 51, 51)
	TextButton.Text = "[Reward] You launched a game?"
	TextButton.TextWrapped = true
	TextButton.Font = Enum.Font.Ubuntu
	TextButton.TextWrap = true
	TextButton.TextXAlignment = Enum.TextXAlignment.Left
	TextButton.Parent = Option1

	local UICorner6 = Instance.new("UICorner")
	UICorner6.CornerRadius = UDim.new(0.15, 0)
	UICorner6.Parent = Option1

	local Option2 = Instance.new("Frame")
	Option2.Name = "Option2"
	Option2.AnchorPoint = Vector2.new(0.5, 0.5)
	Option2.Visible = false
	Option2.Size = UDim2.new(0, 100, 0, 100)
	Option2.BackgroundTransparency = 0.05
	Option2.BorderSizePixel = 0
	Option2.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	Option2.Parent = Options

	local TextButton1 = Instance.new("TextButton")
	TextButton1.AnchorPoint = Vector2.new(0.5, 0.5)
	TextButton1.Size = UDim2.new(0.845, 0, 0.8, 0)
	TextButton1.BackgroundTransparency = 1
	TextButton1.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextButton1.BorderSizePixel = 0
	TextButton1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextButton1.FontSize = Enum.FontSize.Size24
	TextButton1.TextSize = 20
	TextButton1.TextColor3 = Color3.fromRGB(51, 51, 51)
	TextButton1.Text = "[Teleport] Take me there!"
	TextButton1.TextWrapped = true
	TextButton1.Font = Enum.Font.Ubuntu
	TextButton1.TextWrap = true
	TextButton1.TextXAlignment = Enum.TextXAlignment.Left
	TextButton1.Parent = Option2

	local UICorner1 = Instance.new("UICorner")
	UICorner1.CornerRadius = UDim.new(0.15, 0)
	UICorner1.Parent = Option2

	local Option3 = Instance.new("Frame")
	Option3.Name = "Option3"
	Option3.AnchorPoint = Vector2.new(0.5, 0.5)
	Option3.Visible = false
	Option3.Size = UDim2.new(0, 100, 0, 100)
	Option3.BackgroundTransparency = 0.05
	Option3.BorderSizePixel = 0
	Option3.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	Option3.Parent = Options

	local TextButton2 = Instance.new("TextButton")
	TextButton2.AnchorPoint = Vector2.new(0.5, 0.5)
	TextButton2.Size = UDim2.new(0.845, 0, 0.8, 0)
	TextButton2.BackgroundTransparency = 1
	TextButton2.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextButton2.BorderSizePixel = 0
	TextButton2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextButton2.FontSize = Enum.FontSize.Size24
	TextButton2.TextSize = 20
	TextButton2.TextColor3 = Color3.fromRGB(51, 51, 51)
	TextButton2.Text = "[Item] I love your clothes!"
	TextButton2.TextWrapped = true
	TextButton2.Font = Enum.Font.Ubuntu
	TextButton2.TextWrap = true
	TextButton2.TextXAlignment = Enum.TextXAlignment.Left
	TextButton2.Parent = Option3

	local UICorner7 = Instance.new("UICorner")
	UICorner7.CornerRadius = UDim.new(0.15, 0)
	UICorner7.Parent = Option3

	local Option4 = Instance.new("Frame")
	Option4.Name = "Option4"
	Option4.AnchorPoint = Vector2.new(0.5, 0.5)
	Option4.Visible = false
	Option4.Size = UDim2.new(0, 100, 0, 100)
	Option4.BackgroundTransparency = 0.05
	Option4.BorderSizePixel = 0
	Option4.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
	Option4.Parent = Options

	local TextButton3 = Instance.new("TextButton")
	TextButton3.AnchorPoint = Vector2.new(0.5, 0.5)
	TextButton3.Size = UDim2.new(0.845, 0, 0.8, 0)
	TextButton3.BackgroundTransparency = 1
	TextButton3.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextButton3.BorderSizePixel = 0
	TextButton3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextButton3.FontSize = Enum.FontSize.Size24
	TextButton3.TextSize = 20
	TextButton3.TextColor3 = Color3.fromRGB(51, 51, 51)
	TextButton3.Text = "[Survey] I like your sort of music."
	TextButton3.TextWrapped = true
	TextButton3.Font = Enum.Font.Ubuntu
	TextButton3.TextWrap = true
	TextButton3.TextXAlignment = Enum.TextXAlignment.Left
	TextButton3.Parent = Option4

	local UICorner8 = Instance.new("UICorner")
	UICorner8.CornerRadius = UDim.new(0.15, 0)
	UICorner8.Parent = Option4

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.AnchorPoint = Vector2.new(0.5, 0)
	Content.Size = UDim2.new(1, 0, 0.33, 0)
	Content.BackgroundTransparency = 0.05
	Content.Position = UDim2.new(0.5, 0, -0.019, 0)
	Content.BorderSizePixel = 0
	Content.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	Content.Parent = Main

	local UICorner9 = Instance.new("UICorner")
	UICorner9.CornerRadius = UDim.new(0.15, 0)
	UICorner9.Parent = Content

	local TextLabel = Instance.new("TextLabel")
	TextLabel.AnchorPoint = Vector2.new(0, 0.5)
	TextLabel.Size = UDim2.new(0.9, 0, 0.47, 0)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0.038, 0, 0.5, 0)
	TextLabel.BorderSizePixel = 0
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.FontSize = Enum.FontSize.Size24
	TextLabel.TextSize = 22
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.Text = ""
	TextLabel.Font = Enum.Font.Ubuntu
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = Content

	local CharacterName = Instance.new("Frame")
	CharacterName.Name = "CharacterName"
	CharacterName.AnchorPoint = Vector2.new(0, 0.5)
	CharacterName.Size = UDim2.new(0.188, 0, 0.133, 0)
	CharacterName.Position = UDim2.new(0.038, 0, -0.025, 0)
	CharacterName.BorderSizePixel = 0
	CharacterName.BackgroundColor3 = Color3.fromRGB(242, 201, 76)
	CharacterName.Parent = Main

	local UICorner10 = Instance.new("UICorner")
	UICorner10.CornerRadius = UDim.new(0.15, 0)
	UICorner10.Parent = CharacterName

	local TextLabel1 = Instance.new("TextLabel")
	TextLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel1.Size = UDim2.new(1, 0, 1, 0)
	TextLabel1.BackgroundTransparency = 1
	TextLabel1.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextLabel1.BorderSizePixel = 0
	TextLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel1.FontSize = Enum.FontSize.Size36
	TextLabel1.TextSize = 35
	TextLabel1.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel1.Text = ""
	TextLabel1.TextWrapped = true
	TextLabel1.Font = Enum.Font.SourceSansBold
	TextLabel1.TextWrap = true
	TextLabel1.Parent = CharacterName

	local PaidAdLabel = Instance.new("Frame")
	PaidAdLabel.Name = "PaidAdLabel"
	PaidAdLabel.AnchorPoint = Vector2.new(1, 0.5)
	PaidAdLabel.Size = UDim2.new(0.15, 0, 0.133, 0)
	PaidAdLabel.Position = UDim2.new(0.964, 0, -0.025, 0)
	PaidAdLabel.BorderSizePixel = 0
	PaidAdLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	PaidAdLabel.Parent = Main

	local UICorner11 = Instance.new("UICorner")
	UICorner11.CornerRadius = UDim.new(0.15, 0)
	UICorner11.Parent = PaidAdLabel

	local TextLabel2 = Instance.new("TextLabel")
	TextLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel2.Size = UDim2.new(1, 0, 0.799, 0)
	TextLabel2.BackgroundTransparency = 1
	TextLabel2.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextLabel2.BorderSizePixel = 0
	TextLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel2.FontSize = Enum.FontSize.Size36
	TextLabel2.TextSize = 35
	TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel2.Text = "Paid Ad"
	TextLabel2.TextWrapped = true
	TextLabel2.Font = Enum.Font.Ubuntu
	TextLabel2.TextWrap = true
	TextLabel2.TextScaled = true
	TextLabel2.Parent = PaidAdLabel

	local UISizeConstraint = Instance.new("UISizeConstraint")
	UISizeConstraint.Parent = Main

	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint.AspectRatio = 2.8436
	UIAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height
	UIAspectRatioConstraint.Parent = Main

	return BloxbizDialogue
end
