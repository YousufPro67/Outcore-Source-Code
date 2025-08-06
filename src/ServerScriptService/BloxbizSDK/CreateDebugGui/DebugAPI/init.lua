local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local CLICK_TWEEN_TIME = 0.15

local LocalPlayer = Players.LocalPlayer
local DebugAPI = {}
local ImpressionTimes = {}

local function tweenGuiColors(objects, color, tweenTime)
	for _, object in pairs(objects) do
		local propertyTable = {}
		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		if object:IsA("ImageLabel") then
			propertyTable = { ImageColor3 = color }
		elseif object:IsA("Frame") then
			propertyTable = { BackgroundColor3 = color }
		end

		local tween = TweenService:Create(object, tweenInfo, propertyTable)
		tween:Play()
	end
end

function DebugAPI.GiveAdNewColor(Ad)
	for _, color in pairs(script.Parent.Colors:GetChildren()) do
		if color.Use.Value == false then
			color.Use.Value = true
			Ad:SetAttribute("AdColor", color.Value)

			return Ad:GetAttribute("AdColor")
		end
	end

	return nil
end

function DebugAPI.RemoveAdColor(Ad)
	if Ad:GetAttribute("AdColor") then
		for _, color in pairs(script.Parent.Colors:GetChildren()) do
			if color.Value == Ad:GetAttribute("AdColor") then
				color.Use.Value = false
				Ad:SetAttribute("AdColor", Color3.new())
			end
		end
	end
end

function DebugAPI.GetAdColor(Ad)
	local Color = Ad:GetAttribute("AdColor")

	if not Color or (Color and Color == Color3.new()) then
		Color = DebugAPI.GiveAdNewColor(Ad)
	end

	return Color
end

function DebugAPI.videoDebugModeEnabled()
    local PlayerScripts = LocalPlayer:WaitForChild('PlayerScripts')
	local BloxbizSDK = PlayerScripts:WaitForChild("BloxbizSDK")
	local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))

	return ConfigReader:read("DebugModeVideoAd")
end

local videoDebugAdInitialized = false
function DebugAPI.playVideoDebugAd()
	if videoDebugAdInitialized then
		return
	end

    local PlayerScripts = LocalPlayer:WaitForChild('PlayerScripts')
	local BloxbizSDK = PlayerScripts:WaitForChild("BloxbizSDK")
	local ScreenshotTool = require(BloxbizSDK:WaitForChild("ScreenshotTool"))

	videoDebugAdInitialized = true

	local targetedAd = require(script.VideoAd)
	ScreenshotTool.TurnOnTargeting(targetedAd)
end

function DebugAPI.GetImpressions()
	local Total = 0

	for i, v in pairs(ImpressionTimes) do
		Total = Total + math.floor(v / 10)
	end

	return Total
end

function DebugAPI.UpdateImpressions(UI, Info)
	if UI == nil then
		return
	end

	local GREEN_COLOR = Color3.fromRGB(43, 236, 12)
	local WHITE_COLOR = Color3.fromRGB(255, 255, 255)

	local OGTime = tonumber(UI.Row1.Time.Text)
	local Time = (Info.Time - OGTime)

	if ImpressionTimes[Info.URL] == nil then
		ImpressionTimes[Info.URL] = 0
	end

	if Info.Per > 1.5 and Info.Angle <= 55 and Info.Time > 0.5 then
		if Info.Time - Time <= 0.5 and Info.Time > 0.5 then
			Time = Info.Time
		end

		local B4 = math.floor(ImpressionTimes[Info.URL] / 10)
		ImpressionTimes[Info.URL] = ImpressionTimes[Info.URL] + Time
	end

	if Info.Per >= 1.5 then
		UI.Row2.ScreenPercentage.TextColor3 = GREEN_COLOR
	else
		UI.Row2.ScreenPercentage.TextColor3 = WHITE_COLOR
	end

	if Info.Angle <= 55 then
		UI.Row2.Angle.TextColor3 = GREEN_COLOR
	else
		UI.Row2.Angle.TextColor3 = WHITE_COLOR
	end

	UI.Row1.Time.Text = string.format("%.2f", Info.Time)
	UI.Row2.ScreenPercentage.Text = string.format("%.2f", Info.Per) .. "%"
	UI.Row2.Angle.Text = string.format("%.1f", Info.Angle) .. "°"

	if DebugAPI.videoDebugModeEnabled() and UI.Row1:FindFirstChild('VideoTime') then
		UI.Row1.VideoTime.Text = string.format("%.2f", Info.VideoTime)
	end

	script.Parent.ImpressionTime.Text = DebugAPI.GetImpressions()
end

function DebugAPI.StartImpression(Ad, Info)
	local Color = DebugAPI.GetAdColor(Ad)

	if Color == nil then
		warn("[SuperBiz] Can't track ad, too many on screen")
		return nil
	end

	if not Ad:FindFirstChild("Colorize") then
		local stats_widget = script.Parent.Item:Clone()
		local color_overlay = script.Parent.Colorize:Clone()

		color_overlay.Parent = Ad
		stats_widget.Parent = script.Parent.Main
		stats_widget.Parent.Visible = true

		color_overlay.Visible = true
		stats_widget.Visible = true

		color_overlay.BackgroundColor3 = Color
		color_overlay.UI.Value = stats_widget
		color_overlay.ZIndex = 99

		stats_widget.Row2.BackgroundColor3 = Color
		--stats_widget.Row1.Time.TextStrokeColor3 = Color

		if Info then
			DebugAPI.UpdateImpressions(stats_widget, Info)
		end

		if DebugAPI.videoDebugModeEnabled() then
			DebugAPI.playVideoDebugAd()

			local videoTime = stats_widget.Row1.Time:Clone()
			videoTime.Name = "VideoTime"
			videoTime.Parent = stats_widget.Row1
			videoTime.TextXAlignment = Enum.TextXAlignment.Left
			videoTime.TextStrokeTransparency = 0.5
			videoTime.TextColor3 = Color3.fromRGB(0, 255, 255)

			stats_widget.Row1.Time.TextXAlignment = Enum.TextXAlignment.Right
			color_overlay.Transparency = 0.5
		end

		return stats_widget
	else
		warn("[SuperBiz] New impression started before old impression ended")
		return nil
	end
end

function DebugAPI.EndImpression(Ad)
	if Ad:FindFirstChild("Colorize") then
		DebugAPI.RemoveAdColor(Ad)
		Ad.Colorize.UI.Value:Destroy()
		Ad.Colorize:Destroy()
	end
end

function DebugAPI.UpdateInteraction(Ad, interactionType)
	local CLICK_COLOR = Color3.fromRGB(0, 141, 19)
	local hoverColor = DebugAPI.GetAdColor(Ad)

	local interactionBorder = Ad.ImageLabel:FindFirstChild("InteractionBorder")

	if not interactionBorder then
		interactionBorder = Instance.new("ImageLabel")
		interactionBorder.Name = "InteractionBorder"
		interactionBorder.Parent = Ad.ImageLabel
		interactionBorder.Size = UDim2.new(1, 0, 1, 0)
		interactionBorder.Image = "http://www.roblox.com/asset/?id=8462561342"
		interactionBorder.ImageColor3 = hoverColor
		interactionBorder.BackgroundTransparency = 1
	end

	if interactionType == "click" then
		Ad:SetAttribute("LastClickTime", Workspace:GetServerTimeNow())

		local objectsToTween = { interactionBorder }

		if Ad:FindFirstChild("Colorize") then
			table.insert(objectsToTween, Ad.Colorize)
		end

		task.spawn(function()
			tweenGuiColors(objectsToTween, CLICK_COLOR, CLICK_TWEEN_TIME)

			task.wait(CLICK_TWEEN_TIME)

			if Workspace:GetServerTimeNow() - Ad:GetAttribute("LastClickTime") > CLICK_TWEEN_TIME then
				tweenGuiColors(objectsToTween, hoverColor, CLICK_TWEEN_TIME)
			end
		end)
	elseif interactionType == "hover" then
		local objectsToTween = { interactionBorder }

		if Ad:FindFirstChild("Colorize") then
			table.insert(objectsToTween, Ad.Colorize)
		end

		--tweenGuiColors(objectsToTween, hoverColor, CLICK_TWEEN_TIME)
	end
end

function DebugAPI.EndInteraction(Ad)
	local borderToDestroy = Ad.ImageLabel:FindFirstChild("InteractionBorder")

	if borderToDestroy then
		if not Ad:FindFirstChild("Colorize") then
			DebugAPI.RemoveAdColor(Ad)
		end

		borderToDestroy.Name = "Destroyed"

		task.spawn(function()
			local disappearTween = TweenService:Create(
				borderToDestroy,
				TweenInfo.new(CLICK_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ ImageTransparency = 1 }
			)
			disappearTween:Play()

			task.wait(CLICK_TWEEN_TIME)

			borderToDestroy:Destroy()
		end)
	end
end

return DebugAPI
