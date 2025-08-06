local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local Common = require(script.Parent.Parent.Utils.Common)
local ElementSizes = require(script.Parent.Parent.Utils.ElementSizes)

local Notification = require(StarterPlayer.StarterPlayerScripts.Styngr.StateValues.Notification)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local TIME = 7 -- specifies how long it should take for the value to animate to the goal, in seconds.
local REPEAT_COUNT = 0

local xPos = Common.calcualteXPosition(ElementSizes.WIDTH.NOTIFICATION)
local startingTextPosition = UDim2.fromScale(0.8, 0)

local textLabel = Computed(function()
	local notification = Notification:get()

	if not notification then
		return ""
	end

	return notification
end)

local notificationText = New("TextLabel")({
	Name = "PlayPauseText",
	BackgroundTransparency = 1,
	Position = startingTextPosition,
	FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Text = textLabel,
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.fromOffset(210, 32),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	FontSize = Enum.FontSize.Size14,

	[Children] = {
		New("UIPadding")({
			PaddingTop = UDim.new(0.09, 0),
		}),
	},
})

notificationText:GetPropertyChangedSignal("Text"):Connect(function()
	if #notificationText.Text > 0 then
		notificationText.Position = startingTextPosition

		local style = TweenInfo.new(TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, REPEAT_COUNT)
		TweenService:Create(notificationText, style, { Position = UDim2.fromScale(-0.7, 0) }):Play()
	end
end)

local notificationContainer = New("Frame")({
	Name = "NotificationContainer",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(210, 32),
	ClipsDescendants = true,

	[Children] = {
		New("UICorner")({
			CornerRadius = UDim.new(0.15, 0),
		}),
		notificationText,
	},
})

local notificationGroup = New("Frame")({
	Name = "NotificationGroup",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.4,
	Position = UDim2.fromOffset(xPos, 40),
	Size = UDim2.fromOffset(ElementSizes.WIDTH.NOTIFICATION, 32),

	[Children] = {
		New("UICorner")({
			CornerRadius = UDim.new(0.25, 0),
		}),
		New("UIPadding")({
			PaddingBottom = UDim.new(0.027, 0),

			PaddingTop = UDim.new(0.2, 0),
		}),

		New("UIListLayout")({
			Padding = UDim.new(0, 0.5),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		notificationContainer,
	},
})

local function NotificationBox()
	return New("Frame")({
		BackgroundTransparency = 1,
		Name = "NotificationTopLevel",
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 1,
		Active = false,
		Visible = Computed(function()
			return Notification:get()
		end),

		[Children] = {
			New("Frame")({
				BackgroundTransparency = 1,
				Name = "NotificationContainer",
				Size = UDim2.new(1, 0, 0, 32),
				ZIndex = 1,
				Active = false,

				[Children] = {
					notificationGroup,
				},
			}),
		},
	})
end

return NotificationBox
