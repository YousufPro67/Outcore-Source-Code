local Players = game:GetService("Players")

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local Computed = Fusion.Computed

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local SelectButton = require(GuiComponents.SelectButton)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

return function(props)
	local searchBox = Value()
	local searchBoxCancelVisible = Value(false)

	return {
		New("Frame")({
			Name = "Container",
			Size = UDim2.fromScale(0.9, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(70, 70, 70),
			ZIndex = 5,

			[Children] = {
				SelectButton({
					Text = "Cancel",
					Name = "CancelButton",
					Size = UDim2.fromScale(0, 0.41),
					Color = Color3.fromRGB(255, 255, 255),
					Position = UDim2.fromScale(0.83, 0.5),
					AnchorPoint = Vector2.new(0, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					ZIndex = 5,
					Bold = true,

					Visible = Computed(function()
						return searchBoxCancelVisible:get()
					end),

					OnActivated = function()
						searchBox:get().Text = ""
						searchBox:get():CaptureFocus()
						props.UserSearchFailed:set(false)
					end,
				}),

				New("TextBox")({
					Name = "SearchBox",
					Size = UDim2.fromScale(0.65, 0.45),
					Position = UDim2.fromScale(0.11, 0.5),
					AnchorPoint = Vector2.new(0, 0.5),
					FontFace = Font.fromEnum(Enum.Font.Arial),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					TextScaled = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderText = "Search people",
					PlaceholderColor3 = Color3.fromRGB(154, 154, 154),
					ZIndex = 5,

					[Ref] = searchBox,

					[OnChange("Text")] = function()
						if #searchBox:get().Text > 0 then
							searchBoxCancelVisible:set(true)
						else
							searchBoxCancelVisible:set(false)
						end
					end,

					[OnEvent("FocusLost")] = function(enterPressed)
						if not enterPressed then
							return
						end

						local username = searchBox:get().Text

						local success, userId = pcall(function()
							return Players:GetUserIdFromNameAsync(username)
						end)

						if success and userId then
							local profileImage = props.GetUserProfilePicture(userId)
							local userInfo = props.getUserInfoFromUserIds({userId})
							if not userInfo or not userInfo[userId] then
								props.UserSearchFailed:set(true)
								return
							end

							local foundUserData = userInfo[userId]
							foundUserData.ProfileImage = profileImage

							props.OnSwitchFeedClicked(props.initialProfileFeed, userId)
						else
							props.UserSearchFailed:set(true)
							return
						end
					end,
				}),

				New("ImageLabel")({
					Size = UDim2.fromScale(0.5, 0.5),
					Position = UDim2.fromScale(0.04, 0.5),
					AnchorPoint = Vector2.new(0, 0.5),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Image = "rbxassetid://13114890388",
					ZIndex = 5,
				}),

				New("UICorner")({
					CornerRadius = UDim.new(0.5, 0),
				}),
			},
		}),

		Line({
			Size = UDim2.fromScale(1, 0.02),
		}),
	}
end
