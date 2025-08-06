local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local showErrorToPlayer = require(script.Parent.Message)

local Children = Fusion.Children
local New = Fusion.New

local function Item(props)
	local function _getInformationInfo()
		local info = ReplicatedStorage.Styngr.SubscriptionInfo:InvokeServer()

		if not info then
			showErrorToPlayer("There was an issue in communication to the server. Please, try again later.")
			return
		end

		local function displayPopup(popup_info)
			local function dictionaryToString(dictionary)
				local result = ""
				for key, value in pairs(dictionary) do
					result = result .. key .. ": " .. value .. "\n"
				end
				return result
			end

			local popup = New("ScreenGui")({
				Name = "Popup",
			})

			local frame = New("Frame")({
				Parent = popup,
				Size = UDim2.new(0.5, 0, 0.5, 0),
				Position = UDim2.new(0.25, 0, 0.25, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 5,
				[Children] = {
					New("TextLabel")({
						Size = UDim2.new(1, 0, 1, 0),
						Text = dictionaryToString(popup_info),
						TextScaled = true,
						TextColor3 = Color3.new(0, 0, 0),
					}),
				},
			})

			local closeButton = New("TextButton")({
				Parent = frame,
				Size = UDim2.new(0.2, 0, 0.1, 0),
				Position = UDim2.new(0.4, 0, 0.95, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				TextColor3 = Color3.new(1, 1, 1),
				Text = "Close",
			})

			local function closePopup()
				popup:Destroy()
			end

			-- Bind the close function to the close button
			closeButton.MouseButton1Click:Connect(closePopup)

			popup.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		end

		displayPopup(info)
	end

	return New("TextButton")({
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromOffset(0, 0),
		TextWrapped = true,

		Text = props.Name,

		[Fusion.OnEvent("Activated")] = _getInformationInfo,

		[Children] = { New("UICorner")({
			CornerRadius = UDim.new(0.167, 0),
		}) },
	})
end

function SubscriptionInfo()
	return New("Frame")({
		Name = "SubscriptionInfo",
		BackgroundColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.fromOffset(200, 200),
		Position = UDim2.fromOffset(0, 210),

		[Children] = {
			New("UIListLayout")({
				Name = "UIListLayout",
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Item({
				["Name"] = "Subscription Information",
			}),
		},
	})
end

return SubscriptionInfo
