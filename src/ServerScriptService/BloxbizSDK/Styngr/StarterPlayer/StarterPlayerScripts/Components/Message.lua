local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local function showErrorToPlayer(errorMessage)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CustomErrorDialog"
	screenGui.Parent = game.Players.LocalPlayer:FindFirstChild("PlayerGui")

	local okButton = New("TextButton")({
		Size = UDim2.new(0.2, 0, 0.1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Text = "OK",
		[OnEvent("Activated")] = function()
			screenGui:Destroy()
		end,

		[Children] = {
			New("UICorner")({
				CornerRadius = UDim.new(0.167, 0),
			}),
		},
	})

	local frame = New("Frame")({
		Size = UDim2.new(0.5, 0, 0.3, 0),
		Position = UDim2.new(0.25, 0, 0.35, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,

		[Children] = {
			New("UIListLayout")({
				Name = "UIListLayout",
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New("TextLabel")({
				Size = UDim2.new(1, 0, 0.9, 0),
				Text = errorMessage,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,
			}),
			okButton,
		},
	})
	frame.Parent = screenGui
end

return showErrorToPlayer
