local function connectBackgroundValues(debugGui)
    debugGui.Main.ChildRemoved:Connect(function(c)
        for _, v in pairs(debugGui.Colors:GetChildren()) do
            if v.Value == c.BackgroundColor3 or #debugGui.Main:GetChildren() <= 1 then
                v.Use.Value = false
            end
        end
    end)
end

return function()
	local DebugGui = Instance.new("ScreenGui")
	DebugGui.Name = "DebugGui"
	DebugGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	DebugGui.ResetOnSpawn = false

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Visible = false
	Main.Size = UDim2.new(1, 0, 0.07492, 0)
	Main.BackgroundTransparency = 0.9
	Main.Position = UDim2.new(0, 0, 0.9250801, 0)
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Main.Parent = DebugGui

	local UIGridLayout = Instance.new("UIGridLayout")
	UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout.CellSize = UDim2.new(0.12, 0, 1, 0)
	UIGridLayout.CellPadding = UDim2.new(0.001, 0, 0, 0)
	UIGridLayout.Parent = Main

	local Colors = Instance.new("Folder")
	Colors.Name = "Colors"
	Colors.Parent = DebugGui

	local Color3Value = Instance.new("Color3Value")
	Color3Value.Name = "1"
	Color3Value.Value = Color3.fromRGB(150, 59, 247)
	Color3Value.Parent = Colors

	local Use = Instance.new("BoolValue")
	Use.Name = "Use"
	Use.Parent = Color3Value

	local Color3Value1 = Instance.new("Color3Value")
	Color3Value1.Name = "2"
	Color3Value1.Value = Color3.fromRGB(59, 200, 247)
	Color3Value1.Parent = Colors

	local Use1 = Instance.new("BoolValue")
	Use1.Name = "Use"
	Use1.Parent = Color3Value1

	local Color3Value2 = Instance.new("Color3Value")
	Color3Value2.Name = "3"
	Color3Value2.Value = Color3.fromRGB(247, 125, 59)
	Color3Value2.Parent = Colors

	local Use2 = Instance.new("BoolValue")
	Use2.Name = "Use"
	Use2.Parent = Color3Value2

	local Color3Value3 = Instance.new("Color3Value")
	Color3Value3.Name = "4"
	Color3Value3.Value = Color3.fromRGB(156, 247, 59)
	Color3Value3.Parent = Colors

	local Use3 = Instance.new("BoolValue")
	Use3.Name = "Use"
	Use3.Parent = Color3Value3

	local Color3Value4 = Instance.new("Color3Value")
	Color3Value4.Name = "5"
	Color3Value4.Value = Color3.fromRGB(59, 128, 247)
	Color3Value4.Parent = Colors

	local Use4 = Instance.new("BoolValue")
	Use4.Name = "Use"
	Use4.Parent = Color3Value4

	local Color3Value5 = Instance.new("Color3Value")
	Color3Value5.Name = "6"
	Color3Value5.Value = Color3.fromRGB(247, 222, 59)
	Color3Value5.Parent = Colors

	local Use5 = Instance.new("BoolValue")
	Use5.Name = "Use"
	Use5.Parent = Color3Value5

	local Color3Value6 = Instance.new("Color3Value")
	Color3Value6.Name = "7"
	Color3Value6.Value = Color3.fromRGB(222, 59, 247)
	Color3Value6.Parent = Colors

	local Use6 = Instance.new("BoolValue")
	Use6.Name = "Use"
	Use6.Parent = Color3Value6

	local Color3Value7 = Instance.new("Color3Value")
	Color3Value7.Name = "8"
	Color3Value7.Value = Color3.fromRGB(247, 163, 59)
	Color3Value7.Parent = Colors

	local Use7 = Instance.new("BoolValue")
	Use7.Name = "Use"
	Use7.Parent = Color3Value7

	local Color3Value8 = Instance.new("Color3Value")
	Color3Value8.Name = "9"
	Color3Value8.Value = Color3.fromRGB(59, 247, 163)
	Color3Value8.Parent = Colors

	local Use8 = Instance.new("BoolValue")
	Use8.Name = "Use"
	Use8.Parent = Color3Value8

	local Color3Value9 = Instance.new("Color3Value")
	Color3Value9.Name = "10"
	Color3Value9.Value = Color3.fromRGB(247, 59, 125)
	Color3Value9.Parent = Colors

	local Use9 = Instance.new("BoolValue")
	Use9.Name = "Use"
	Use9.Parent = Color3Value9

	local Color3Value10 = Instance.new("Color3Value")
	Color3Value10.Name = "11"
	Color3Value10.Value = Color3.fromRGB(62, 59, 247)
	Color3Value10.Parent = Colors

	local Use10 = Instance.new("BoolValue")
	Use10.Name = "Use"
	Use10.Parent = Color3Value10

	local Color3Value11 = Instance.new("Color3Value")
	Color3Value11.Name = "12"
	Color3Value11.Value = Color3.fromRGB(247, 59, 59)
	Color3Value11.Parent = Colors

	local Use11 = Instance.new("BoolValue")
	Use11.Name = "Use"
	Use11.Parent = Color3Value11

	local Colorize = Instance.new("Frame")
	Colorize.Name = "Colorize"
	Colorize.AnchorPoint = Vector2.new(0.5, 0.5)
	Colorize.Visible = false
	Colorize.Size = UDim2.new(0.65, 0, 0.65, 0)
	Colorize.Position = UDim2.new(0.5, 0, 0.5, 0)
	Colorize.BorderSizePixel = 0
	Colorize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Colorize.Parent = DebugGui

	local UI = Instance.new("ObjectValue")
	UI.Name = "UI"
	UI.Parent = Colorize

	local ImpressionTime = Instance.new("TextLabel")
	ImpressionTime.Name = "ImpressionTime"
	ImpressionTime.AnchorPoint = Vector2.new(1, 1)
	ImpressionTime.Size = UDim2.new(0.1, 0, 0.025, 0)
	ImpressionTime.BackgroundTransparency = 1
	ImpressionTime.Position = UDim2.new(0.9975, 0, 1, 0)
	ImpressionTime.BorderSizePixel = 0
	ImpressionTime.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImpressionTime.FontSize = Enum.FontSize.Size14
	ImpressionTime.TextStrokeTransparency = 0.5
	ImpressionTime.TextSize = 14
	ImpressionTime.TextColor3 = Color3.fromRGB(255, 255, 255)
	ImpressionTime.Text = "0"
	ImpressionTime.TextWrapped = true
	ImpressionTime.TextWrap = true
	ImpressionTime.TextXAlignment = Enum.TextXAlignment.Right
	ImpressionTime.TextScaled = true
	ImpressionTime.Parent = DebugGui

	local Item = Instance.new("Frame")
	Item.Name = "Item"
	Item.Selectable = true
	Item.AnchorPoint = Vector2.new(0, 1)
	Item.Visible = false
	Item.Size = UDim2.new(0.12, 0, 0.07, 0)
	Item.BackgroundTransparency = 1
	Item.Position = UDim2.new(0, 0, 1, 0)
	Item.BorderSizePixel = 0
	Item.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
	Item.Parent = DebugGui

	local UIGridLayout1 = Instance.new("UIGridLayout")
	UIGridLayout1.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout1.CellSize = UDim2.new(1, 0, 0.5, 0)
	UIGridLayout1.CellPadding = UDim2.new(0, 0, 0, 0)
	UIGridLayout1.Parent = Item

	local Row1 = Instance.new("Frame")
	Row1.Name = "Row1"
	Row1.Size = UDim2.new(0, 100, 0, 100)
	Row1.BackgroundTransparency = 1
	Row1.BorderSizePixel = 0
	Row1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Row1.Parent = Item

	local Time = Instance.new("TextLabel")
	Time.Name = "Time"
	Time.Size = UDim2.new(1, 0, 0.7, 0)
	Time.BackgroundTransparency = 1
	Time.Position = UDim2.new(0, 0, 0.15, 0)
	Time.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Time.FontSize = Enum.FontSize.Size18
	Time.TextStrokeTransparency = 0.5
	Time.TextSize = 17
	Time.TextColor3 = Color3.fromRGB(255, 255, 255)
	Time.Text = "10"
	Time.TextWrapped = true
	Time.TextWrap = true
	Time.TextScaled = true
	Time.Parent = Row1

	local Row2 = Instance.new("Frame")
	Row2.Name = "Row2"
	Row2.Size = UDim2.new(0, 100, 0, 100)
	Row2.BorderSizePixel = 0
	Row2.BackgroundColor3 = Color3.fromRGB(150, 59, 247)
	Row2.Parent = Item

	local Angle = Instance.new("TextLabel")
	Angle.Name = "Angle"
	Angle.Size = UDim2.new(0.3654081, 0, 0.1904762, 0)
	Angle.BackgroundTransparency = 1
	Angle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Angle.FontSize = Enum.FontSize.Size18
	Angle.TextStrokeTransparency = 0.5
	Angle.TextSize = 17
	Angle.TextColor3 = Color3.fromRGB(0, 255, 28)
	Angle.Text = "180\176"
	Angle.TextWrapped = true
	Angle.TextWrap = true
	Angle.TextScaled = true
	Angle.Parent = Row2

	local ScreenPercentage = Instance.new("TextLabel")
	ScreenPercentage.Name = "ScreenPercentage"
	ScreenPercentage.Size = UDim2.new(0.25, 0, 1, 0)
	ScreenPercentage.BackgroundTransparency = 1
	ScreenPercentage.Position = UDim2.new(0.5, 0, 0, 0)
	ScreenPercentage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ScreenPercentage.FontSize = Enum.FontSize.Size18
	ScreenPercentage.TextStrokeTransparency = 0.5
	ScreenPercentage.TextSize = 17
	ScreenPercentage.TextColor3 = Color3.fromRGB(254, 252, 255)
	ScreenPercentage.Text = "25%"
	ScreenPercentage.TextWrapped = true
	ScreenPercentage.TextWrap = true
	ScreenPercentage.TextScaled = true
	ScreenPercentage.Parent = Row2

	local UIGridLayout2 = Instance.new("UIGridLayout")
	UIGridLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout2.CellSize = UDim2.new(0.5, 0, 1, 0)
	UIGridLayout2.CellPadding = UDim2.new(0, 0, 0, 0)
	UIGridLayout2.Parent = Row2

    connectBackgroundValues(DebugGui)

    local DebugAPI = script.DebugAPI:Clone()
    DebugAPI.Parent = DebugGui

	return DebugGui
end