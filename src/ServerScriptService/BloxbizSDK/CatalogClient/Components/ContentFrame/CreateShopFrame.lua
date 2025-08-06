local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local LocalPlayer = Players.LocalPlayer

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Ref = Fusion.Ref
local Out = Fusion.Out
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local OnChange = Fusion.OnChange

local Components = script.Parent.Parent
local Button = require(script.Parent.Button)
local ItemGrid = require(Components.ItemGrid)
local Dropdown = require(Components.Dropdown)
local ScaledText = require(Components.ScaledText)
local LoadingFrame = require(Components.LoadingFrame)
local ItemSelector = require(script.Parent.ItemSelector)

local function mapGroups(groups)
	local mapped = {}

	for _, group in groups do
		if group.Rank < 254 then
			continue
		end

		table.insert(mapped, {
			label = group.Name,
			value = group.Id,
			type = "Group",
		})
	end

	return mapped
end

return function(shopProps, props)
	local groups = GroupService:GetGroupsAsync(LocalPlayer.UserId)
	local groupOptions = mapGroups(groups)

	local nameTextBox = Value()
	local dropdownOpen = Value(false)

	local selectedName = shopProps.SelectedName
	local selectedGroup = shopProps.SelectedGroup
	local selectedGroupValue = shopProps.SelectedGroupValue
	local selectedItems = shopProps.SelectedItems
	local selectedEmoji = shopProps.SelectedEmoji
	local selectingEmoji = shopProps.SelectingEmoji

    return New "Frame" {
		Name = "ShopCreatingView",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Selectable = false,
		Size = UDim2.fromScale(1, 0.9),
		Visible = shopProps.Visible,

        [Fusion.Cleanup] = function()

        end,

        [Children] = {
			New "Frame" {
				Name = "ShopInfo",
				Size = UDim2.fromScale(0.32, 1),
				BackgroundTransparency = 1,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						FillDirection = Enum.FillDirection.Vertical,
					},

					ScaledText {
						Size = UDim2.fromScale(1, 0.035),
						Position = UDim2.fromScale(0, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Name & Emoji",
					},

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.015),
						BackgroundTransparency = 1,
					},

					New "Frame" {
						Name = "NameEmoji",
						Size = UDim2.fromScale(1, 0.07),
						BackgroundTransparency = 1,

						[Children] = {
							New "Frame" {
								Name = "ShopName",
								Size = UDim2.fromScale(0.825, 1),
								Position = UDim2.fromScale(0, 0),
								BackgroundColor3 = Color3.fromRGB(41, 43, 48),

								[Children] = {
									New "TextBox" {
										Name = "SearchBox",
										FontFace = Font.fromEnum(Enum.Font.GothamMedium),
										PlaceholderColor3 = Color3.fromRGB(149, 149, 149),
										PlaceholderText = "Name your shop",
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextScaled = true,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										Size = UDim2.fromScale(0.9, 0.52),
										Position = UDim2.fromScale(0.05, 0.5),
										AnchorPoint = Vector2.new(0, 0.5),

										Text = Computed(function()
											return selectedName:get() or ""
										end),

										[Ref] = nameTextBox,

										[Out "Text"] = selectedName,

										[OnChange "Text"] = function()
											local textBox = nameTextBox:get()
											textBox.Text = textBox.Text:sub(1, 40)
										end,
									},

									New "UICorner" {
										CornerRadius = UDim.new(0.3),
									},
								},
							},

							Button({
								Size = UDim2.fromScale(1, 1),
								Position = UDim2.fromScale(1, 0),
								AnchorPoint = Vector2.new(1, 0),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,

								Text = Computed(function()
									return selectedEmoji:get()
								end),

								OnClick = function()
									selectingEmoji:set(true)
								end,
							}),
						},
					},

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.03),
						BackgroundTransparency = 1,
					},

					ScaledText {
						Size = UDim2.fromScale(1, 0.035),
						Position = UDim2.fromScale(0, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Creator",
					},

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.015),
						BackgroundTransparency = 1,
					},

					Dropdown({
						Size = UDim2.fromScale(1, 0.075),
						Placeholder = "Group name",

						Options = groupOptions,
						SelectedOption = selectedGroup,
						Value = selectedGroupValue,

						Disabled = props.IsEditingShop,

						TrayOpen = dropdownOpen,

						Colors = {
							Default = Color3.fromRGB(41, 43, 48),
							MouseDown = Color3.fromRGB(15, 15, 15),
							Hover = Color3.fromRGB(30, 30, 30),
							Disabled = Color3.fromRGB(30, 30, 30),
						},

						HideStroke = true
					}),

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.01),
						BackgroundTransparency = 1,
					},

					New "TextLabel" {
						Size = UDim2.fromScale(1, 0.043),
						Text = "Group members with a 254 or greater rank will be able to edit the shop.",
						TextColor3 = Color3.new(0.7, 0.7, 0.7),
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundTransparency = 1,
						TextScaled = true,

						Visible = Computed(function()
							return not dropdownOpen:get()
						end),
					},
				},
			},

			New "Frame" {
				Name = "ShopItems",
				Size = UDim2.fromScale(0.66, 1),
				Position = UDim2.fromScale(0.34, 0),
				BackgroundTransparency = 1,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						FillDirection = Enum.FillDirection.Vertical,
					},

					ScaledText {
						Size = UDim2.fromScale(1, 0.035),
						Position = UDim2.fromScale(0, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Items",
					},

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.015),
						BackgroundTransparency = 1,
					},

					New "Frame" {
						Name = "ItemsContainer",
						Size = UDim2.fromScale(1, 0.07),
						BackgroundTransparency = 1,
						ZIndex = 2,

						[Children] = {
							ItemSelector({
								SelectedItems = selectedItems,
								SelectedGroup = selectedGroup,
							}),
						},
					},

					New "Frame" {
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						Size = UDim2.fromScale(0, 0.03),
						BackgroundTransparency = 1,
					},

					ItemGrid {
						Size = UDim2.fromScale(1, 0.86),

						Gap = 8,
						Columns = 1,
						ItemRatio = 1 / 0.1,

						[Children] = {
							ForPairs(selectedItems, function(id, item)
								return id, New "Frame" {
									Name = id,
									BackgroundTransparency = 1,

									[Children] = {
										New "TextButton" {
											Name = "RemoveButton",
											Size = UDim2.fromScale(0.2, 0.3),
											Position = UDim2.fromScale(1 - 0.025, 0.5),
											AnchorPoint = Vector2.new(1, 0.5),
											BackgroundTransparency = 1,

											[OnEvent "Activated"] = function()
												local items = selectedItems:get()
												items[id] = nil
												selectedItems:set(items)
											end,

											[Children] = {
												ScaledText {
													Text = "Remove",
													Size = UDim2.fromScale(1, 1),
													TextXAlignment = Enum.TextXAlignment.Right,
													TextColor3 = Color3.new(0.7, 0.7, 0.7),
												},
											},
										},

										ScaledText {
											Text = item.Data,
											Size = UDim2.fromScale(0.7, 0.3),
											Position = UDim2.fromScale(0.025, 0.1),
											TextXAlignment = Enum.TextXAlignment.Left,
										},

										ScaledText {
											Text = item.Type,
											Position = UDim2.fromScale(0.025, 0.5),
											Size = UDim2.fromScale(0.7, 0.3),
											TextXAlignment = Enum.TextXAlignment.Left,
											TextColor3 = Color3.new(0.7, 0.7, 0.7),
										},

										New "Frame" {
											Name = "Line",
											AnchorPoint = Vector2.new(0.5, 1),
											Position = UDim2.fromScale(0.5, 1),
											Size = UDim2.fromScale(1, 0.04),
											BackgroundColor3 = Color3.fromRGB(51, 51, 51),
										},
									},
								}
							end, Fusion.cleanup),
						},
					},
				},
			},

			LoadingFrame {
				Visible = shopProps.Loading,

				Text = "Loading edit mode...",
				CornerRadius = UDim.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			},
		}
    }
end
