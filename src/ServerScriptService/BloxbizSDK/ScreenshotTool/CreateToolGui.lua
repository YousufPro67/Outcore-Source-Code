return function()
    local ScreenshotTool = Instance.new("ScreenGui")
    ScreenshotTool.Name = "ScreenshotTool"
    ScreenshotTool.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.ZIndex = 999
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Main.Size = UDim2.new(1.0140001, 0, 0.5, 0)
    Main.BackgroundTransparency = 0.05
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.BorderSizePixel = 0
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Main.Parent = ScreenshotTool

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 14)
    UICorner.Parent = Main

    local LineBreak = Instance.new("Frame")
    LineBreak.Name = "LineBreak"
    LineBreak.Size = UDim2.new(0.005, 0, 0.08, 0)
    LineBreak.Position = UDim2.new(0.5, 0, 0.04, 0)
    LineBreak.AnchorPoint = Vector2.new(0.5, 0)
    LineBreak.SizeConstraint = Enum.SizeConstraint.RelativeXX
    LineBreak.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LineBreak.Parent = Main

    local AnyButton = Instance.new("TextButton")
    AnyButton.Name = "AnyButton"
    AnyButton.AnchorPoint = Vector2.new(1, 0.5)
    AnyButton.Size = UDim2.new(0.1, 0, 0.07, 0)
    AnyButton.Position = UDim2.new(0.48, 0, 0.12, 0)
    AnyButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
    AnyButton.TextColor3 = Color3.fromRGB(22, 144, 255)
    AnyButton.TextXAlignment = Enum.TextXAlignment.Right
    AnyButton.BackgroundTransparency = 1
    AnyButton.TextScaled = true
    AnyButton.Text = "Any"
    AnyButton.Parent = Main

    local AudioButton = Instance.new("TextButton")
    AudioButton.Name = "AudioButton"
    AudioButton.AnchorPoint = Vector2.new(0, 0.5)
    AudioButton.Size = UDim2.new(0.14, 0, 0.07, 0)
    AudioButton.Position = UDim2.new(0.52, 0, 0.12, 0)
    AudioButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
    AudioButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AudioButton.TextXAlignment = Enum.TextXAlignment.Left
    AudioButton.BackgroundTransparency = 1
    AudioButton.TextScaled = true
    AudioButton.Text = "Audio"
    AudioButton.Parent = Main

    local Ad = Instance.new("Frame")
    Ad.Name = "Ad"
    Ad.Size = UDim2.new(0.893, 0, 0.184, 0)
    Ad.Position = UDim2.new(0.06, 0, 0.25, 0)
    Ad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ad.Parent = Main

    local UICorner1 = Instance.new("UICorner")
    UICorner1.CornerRadius = UDim.new(0, 3)
    UICorner1.Parent = Ad

    local TextBox = Instance.new("TextBox")
    TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
    TextBox.Size = UDim2.new(0.9, 0, 0.45, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextBox.BorderSizePixel = 0
    TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.FontSize = Enum.FontSize.Size14
    TextBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 135)
    TextBox.TextWrapped = true
    TextBox.TextSize = 14
    TextBox.TextWrap = true
    TextBox.TextColor3 = Color3.fromRGB(20, 20, 20)
    TextBox.Text = ""
    TextBox.PlaceholderText = "ID"
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.ClearTextOnFocus = false
    TextBox.TextScaled = true
    TextBox.Parent = Ad

    local FPS = Instance.new("Frame")
    FPS.Name = "FPS"
    FPS.Size = UDim2.new(0.893, 0, 0.184, 0)
    FPS.Position = UDim2.new(0.06, 0, 0.5, 0)
    FPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FPS.Parent = Main

    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 3)
    UICorner2.Parent = FPS

    local TextBox1 = Instance.new("TextBox")
    TextBox1.AnchorPoint = Vector2.new(0.5, 0.5)
    TextBox1.Size = UDim2.new(0.9, 0, 0.45, 0)
    TextBox1.BackgroundTransparency = 1
    TextBox1.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextBox1.BorderSizePixel = 0
    TextBox1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextBox1.FontSize = Enum.FontSize.Size14
    TextBox1.PlaceholderColor3 = Color3.fromRGB(135, 135, 135)
    TextBox1.TextWrapped = true
    TextBox1.TextSize = 14
    TextBox1.TextWrap = true
    TextBox1.TextColor3 = Color3.fromRGB(20, 20, 20)
    TextBox1.Text = ""
    TextBox1.PlaceholderText = "Framerate (default 0)"
    TextBox1.TextXAlignment = Enum.TextXAlignment.Left
    TextBox1.ClearTextOnFocus = false
    TextBox1.TextScaled = true
    TextBox1.Parent = FPS

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 1.3
    UIScale.Parent = Main

    local UISizeConstraint = Instance.new("UISizeConstraint")
    UISizeConstraint.MaxSize = Vector2.new(375, 185)
    UISizeConstraint.Parent = Main

    local UpdateBtn = Instance.new("TextButton")
    UpdateBtn.Name = "UpdateBtn"
    UpdateBtn.Selectable = false
    UpdateBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    UpdateBtn.Size = UDim2.new(0.24, 0, 0.184, 0)
    UpdateBtn.Position = UDim2.new(0.18, 0, 0.85, 0)
    UpdateBtn.BackgroundColor3 = Color3.fromRGB(22, 144, 255)
    UpdateBtn.TextTransparency = 1
    UpdateBtn.TextSize = 1
    UpdateBtn.Text = ""
    UpdateBtn.Parent = Main

    local UICorner3 = Instance.new("UICorner")
    UICorner3.CornerRadius = UDim.new(0, 3)
    UICorner3.Parent = UpdateBtn

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Selectable = true
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabel.BorderSizePixel = 0
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.FontSize = Enum.FontSize.Size14
    TextLabel.TextSize = 14
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Text = "Update"
    TextLabel.TextWrapped = true
    TextLabel.TextWrap = true
    TextLabel.TextScaled = true
    TextLabel.Parent = UpdateBtn

    local DebugModeBtn = Instance.new("TextButton")
    DebugModeBtn.Name = "DebugModeBtn"
    DebugModeBtn.Selectable = false
    DebugModeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    DebugModeBtn.Size = UDim2.new(0.4, 0, 0.184, 0)
    DebugModeBtn.Position = UDim2.new(0.75, 0, 0.85, 0)
    DebugModeBtn.BackgroundColor3 = Color3.fromRGB(22, 144, 255)
    DebugModeBtn.TextTransparency = 1
    DebugModeBtn.TextSize = 1
    DebugModeBtn.Text = ""
    DebugModeBtn.Parent = Main

    local UICorner4 = Instance.new("UICorner")
    UICorner4.CornerRadius = UDim.new(0, 3)
    UICorner4.Parent = DebugModeBtn

    local TextLabel1 = Instance.new("TextLabel")
    TextLabel1.Selectable = true
    TextLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel1.Size = UDim2.new(0.9, 0, 0.9, 0)
    TextLabel1.BackgroundTransparency = 1
    TextLabel1.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabel1.BorderSizePixel = 0
    TextLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel1.FontSize = Enum.FontSize.Size14
    TextLabel1.TextSize = 14
    TextLabel1.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel1.Text = "DebugMode: Off"
    TextLabel1.TextWrapped = true
    TextLabel1.TextWrap = true
    TextLabel1.TextScaled = true
    TextLabel1.Parent = DebugModeBtn
    
    return ScreenshotTool
end