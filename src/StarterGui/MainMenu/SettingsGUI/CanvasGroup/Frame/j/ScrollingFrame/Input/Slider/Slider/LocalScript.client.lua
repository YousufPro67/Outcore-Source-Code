local UIS = game:GetService("UserInputService")
local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local plrdata = knit.GetService("PlayerDataManager")
local clientdata = knit.GetService("ClientData")
local Dragging = false
local minsize = UDim2.new(0,0,1,0)
local setting = script.Parent:GetAttribute("Setting")
local minVal = script.Parent:GetAttribute("Min") or 0
local maxVal = script.Parent:GetAttribute("Max") or 100
local decNumber = script.Parent:GetAttribute("DecimalPoints")
local frame = script.Parent.Frame
local decimalNumber = 1
local plrdatatable = plrdata:Get()
local dataloaded = false

plrdata.OnDataChanged:Connect(function(data)
	if not dataloaded then 
		plrdatatable = data
		dataloaded = true
	end
end)

while not dataloaded do
	wait(0.1)
end

if decNumber > 0 then
	for i = 1, decNumber do
		decimalNumber = decimalNumber * 10
	end
end


local currentVal = plrdatatable[setting]
local initialPercent = (currentVal - minVal) / (maxVal - minVal)
initialPercent = math.clamp(initialPercent, 0, 1)

frame.Size = UDim2.new(initialPercent, 0, 1, 0)
script.Parent.TextLabel.Text = currentVal

script.Parent.TextButton.MouseButton1Down:Connect(function()
	Dragging = true
end)

UIS.InputChanged:Connect(function()
	if Dragging then
		local MousePos = UIS:GetMouseLocation() + Vector2.new(0, -36)
		local RelPos = MousePos - script.Parent.AbsolutePosition
		local Percent = math.clamp(RelPos.X / script.Parent.AbsoluteSize.X, 0, 1)

		frame.Size = UDim2.new(Percent, 0, 1, 0)
		if frame.Size.X.Scale <= minsize.X.Scale then 
			frame.Size = minsize
			Percent = minsize.X.Scale
		end
		frame.Position = UDim2.new(0, 0, 0, 0)

		local actualValue = minVal + (maxVal - minVal) * Percent
		actualValue = math.clamp(actualValue, minVal, maxVal)

		script.Parent.Percentage.Value = math.floor(actualValue * decimalNumber + 0.5) / decimalNumber
		script.Parent.TextLabel.Text = math.floor(actualValue * decimalNumber + 0.5) / decimalNumber
		clientdata:SET(setting, math.floor(actualValue * decimalNumber + 0.5) / decimalNumber)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = false
		plrdata:Save()
	end
end)