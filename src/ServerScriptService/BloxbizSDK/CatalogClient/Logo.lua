local VoiceChatService = game:GetService("VoiceChatService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local BloxbizSDK = script.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

return function(props)
	props = FP.GetValues(props, {
		FullScreen = false,
		Visible = true
	})

	local voiceChatEnabledForUser = Value(false)

	task.spawn(function()
		if RunService:IsStudio() or not ConfigReader:read("IsGameVoiceChatEnabled") then
			return
		end

		if VoiceChatService:IsVoiceEnabledForUserIdAsync(Players.LocalPlayer.UserId) then
			voiceChatEnabledForUser:set(true)
		end
	end)

	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36

	return New "Frame" {
		Name = "LogoContainer",
		Position = UDim2.fromOffset(0, isNewTopBar and 34 or 22),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Visible = props.Visible,
		
		[Children] = New("ImageLabel")({
			Name = "Logo",
			Image = "rbxassetid://14555107778",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = Spring(Computed(function()
				local betaOffset = voiceChatEnabledForUser:get() and 45 or 0
				
				if props.FullScreen:get() then
					return UDim2.new(0.5, 0, 0, 0)
				else
					return UDim2.new(0, (isNewTopBar and 224 or 152) + betaOffset, 0, 0)
				end
			end), 30),
			Size = UDim2.fromScale(1, 1),
			[Children] = {
				New("TextLabel")({
					Name = "Info",
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "Purchase items to use in all experiences",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(1.15, 0.55),
					Size = Computed(function()
						return UDim2.new(3, 0, 1, 0)
					end),
					ZIndex = 2,
					Visible = false,
					--[[Visible = Computed(function()
						return not props.FullScreen:get()
					end)]]
				}),
	
				New("UIAspectRatioConstraint")({
					Name = "UIAspectRatioConstraint",
					AspectRatio = 902 / 190,  -- logo dimensions
					DominantAxis = Enum.DominantAxis.Height,
				}),
			},
		})
	}
end
