local UIS = game:GetService("UserInputService")
local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start({ServicePromises = false}):await()
local plrdata = knit.GetService("PlayerDataManager")
local clientdata = knit.GetService("ClientData")
local ON = false
local setting = script.Parent:GetAttribute("Setting")
local button = script.Parent.TextButton
local ts = game:GetService("TweenService")
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

local function MakeTweens(obj:GuiBase)
	if obj:IsA("TextLabel") then
		local white = ts:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {TextColor3 = Color3.fromRGB(255, 255, 255)})
		local black = ts:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {TextColor3 = Color3.fromRGB(0, 0, 0)})
		return white, black
	elseif obj:IsA("Frame") then
		local On = ts:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1,0)
		})
		local Off = ts:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0)
		})
		return On, Off
	end
end

local function MakeAnimation(ONN: boolean)
	local on, off = MakeTweens(script.Parent.Frame)
	if ONN then
		local white,_ = MakeTweens(script.Parent.OFF)
		local _,black = MakeTweens(script.Parent.ON)
		black:Play()
		white:Play()
		on:Play()
	else
		local white,_ = MakeTweens(script.Parent.ON)
		local _,black = MakeTweens(script.Parent.OFF)
		black:Play()
		white:Play()
		off:Play()
	end
end

button.MouseButton1Click:Connect(function()
	if ON then
		ON = false
	else
		ON = true
	end
	clientdata:SET(setting, ON)
	MakeAnimation(ON)
	plrdata:Save()
end)

MakeAnimation(plrdatatable[setting])
ON = plrdatatable[setting]



