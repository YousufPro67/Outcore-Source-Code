local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PopfeedClient = script.Parent.Parent.Parent

local TimeFormat = require(PopfeedClient.TimeFormat)
local RBLXSerialize = require(PopfeedClient.Parent.Utils.RBLXSerialize)

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs
local Observer = Fusion.Observer

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local ActionButton = require(GuiComponents.ActionButton)
local DonateRow = require(GuiComponents.Profile.DonateRow)

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local UPDATE_INTERVAL = 60
local IMAGE_FORMAT = "rbxthumb://type=Asset&id=%s&w=150&h=150"

local function validateInput(input: InputObject): boolean
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

	return isTouch or isClick
end

return function(props)
	local isReadOnly = props.FeedProps.Config.permissions == "read_only"

	local nameFont = Font.fromEnum(Enum.Font.Arial)
	local displayNameFont = Font.fromEnum(Enum.Font.Arial)
	displayNameFont.Bold = true

	local displayName = props.Profile.DisplayName
	local userName = "@" .. props.Profile.Name

	local formatedTime = TimeFormat.Format(props.Timestamp)
	local isParent = props.IsParent
	local isReplyToSomeone = props.ParentId ~= nil

	local isInPostDetail = props.FeedProps.CurrentFeedType == "replies"
	local visibleInRepliesFeed = (isInPostDetail and isParent) or not isInPostDetail

	local lastUpdate = tick()
	local timeValue = Value(formatedTime)
	local connection = RunService.RenderStepped:Connect(function()
		local now = tick()
		if lastUpdate + UPDATE_INTERVAL < now then
			timeValue:set(TimeFormat.Format(props.Timestamp))
			lastUpdate = now
		end
	end)

	local images = Value(props.Images)
	local boosts = Value(#props.Boosts)

	local hasScreenshots = #props.Screenshots > 0
	local hasImages = #props.Images > 0 or hasScreenshots
	local isSingleImage = #props.Images == 1

	local likes = Value(props.Likes)
	local hasLikedThePost = props.OwnLike == 1 and true or false
	local likeButtonImage = Value(hasLikedThePost and "rbxassetid://13468285537" or "rbxassetid://13468285399")

	local postFrame = Value()
	local profileImage = Value("")

	local moreButton = New("ImageButton")({
		Name = "MoreButton",
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.95, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://12651351573",
		ImageColor3 = Color3.fromRGB(156, 156, 156),

		[OnEvent("Activated")] = function()
			local isOptions = props.FeedProps.IsOptions

			props.FeedProps.InteractedWithPostId = props.Id

			if props.Profile.UserId == LocalPlayer.UserId then
				isOptions:set("OwnPost")
			else
				isOptions:set("NotOwnPost")
			end
		end,
	})

	task.spawn(function()
		local image = props.FeedProps.GetUserProfilePicture(props.Profile.UserId)
		profileImage:set(image)
	end)

	local imagesUIListLayout = Value()
	local imagesScrollingFrame = Value()

	if hasImages and not isSingleImage and not hasScreenshots then
		task.spawn(function()
			task.wait()

			task.defer(function()
				local layout = imagesUIListLayout:get()
				local scrollFrame = imagesScrollingFrame:get()

				scrollFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, 0)
			end)
		end)
	end

	local totalDragMovement = 0

	local function renderSingleImage()
		return {
			New("Frame")({
				Name = "Images",
				Size = UDim2.fromScale(0.775, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 3,

				[Children] = {
					ForPairs(images, function(index, imageData)
						local width = imageData.width
						local height = imageData.height

						local x = 1
						local y = 1

						if width < height then
							x *= width / height
						else
							y *= height / width
						end

						return index,
							New("ImageLabel")({
								Name = "Image",
								Size = UDim2.fromScale(x, y),
								Position = UDim2.fromScale(0.16, 0),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								BackgroundTransparency = 1,
								LayoutOrder = index,
								Image = IMAGE_FORMAT:format(imageData.decal_id),

								[Children] = New("UICorner")({
									CornerRadius = UDim.new(0, 8),
								}),
							})
					end, Fusion.cleanup),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}),
		}
	end

	local function renderMultipleImages()
		local connections = {}

		if not UserInputService.TouchEnabled then
			local playerGui = LocalPlayer:WaitForChild("PlayerGui")

			local isDragging = false
			local dragOldX
			local delta = 0

			local function hoveringOverScrollingFrame(): boolean
				local guis = playerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)

				for _, gui in guis do
					if gui == imagesScrollingFrame:get() then
						return true
					end
				end

				return false
			end

			local function dragScroll()
				if not isDragging then
					return
				end

				local frame = imagesScrollingFrame:get()
				if not frame then
					return
				end

				local X = Mouse.X

				delta = X - (dragOldX or X)
				dragOldX = X
				totalDragMovement += math.abs(delta)

				frame.CanvasPosition = Vector2.new(math.floor(frame.CanvasPosition.X - delta), 0)
			end

			table.insert(connections, RunService.RenderStepped:Connect(dragScroll))

			table.insert(
				connections,
				UserInputService.InputBegan:Connect(function(input: InputObject)
					if validateInput(input) and hoveringOverScrollingFrame() then
						isDragging = true
					end
				end)
			)

			table.insert(
				connections,
				UserInputService.InputEnded:Connect(function(input: InputObject)
					if validateInput(input) then
						totalDragMovement = 0
						isDragging = false
						dragOldX = nil
					end
				end)
			)
		end

		return {
			New("Frame")({
				Name = "Images",
				Size = UDim2.fromScale(0.7, 0.7),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 3,

				[Cleanup] = function()
					for _, conn in connections do
						conn:Disconnect()
					end

					connections = nil
				end,

				[Children] = {
					New("ScrollingFrame")({
						Name = "Images",
						Size = UDim2.fromScale(1.296, 1),
						Position = UDim2.fromScale(0.17, 0),
						CanvasSize = UDim2.fromScale(0, 0),
						ScrollingDirection = Enum.ScrollingDirection.X,
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						ScrollBarThickness = 10,
						ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						ClipsDescendants = false,

						[Ref] = imagesScrollingFrame,

						[Children] = {
							New("Frame")({
								Name = "Container",
								Size = UDim2.new(1, -16, 1, -16),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,

								[Children] = {
									New("UIListLayout")({
										Padding = UDim.new(0.04, 0),
										SortOrder = Enum.SortOrder.LayoutOrder,
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Left,

										[Ref] = imagesUIListLayout,
									}),

									ForPairs(images, function(index, imageData)
										local width = imageData.width
										local height = imageData.height

										local x = width / height
										local y = 1

										return index,
											New("ImageLabel")({
												Name = "Image",
												Size = UDim2.fromScale(x, y),
												SizeConstraint = Enum.SizeConstraint.RelativeXX,
												BackgroundTransparency = 1,
												LayoutOrder = index,
												Image = IMAGE_FORMAT:format(imageData.decal_id),

												[Children] = New("UICorner")({
													CornerRadius = UDim.new(0, 8),
												}),
											})
									end, Fusion.cleanup),
								},
							}),
						},
					}),
				},
			}),
		}
	end

	local function buildScreenshot(screenshotData)
		local loading = Value(false)

		local spinnerValue = Value()
		local loadingObserver = Observer(loading)
		local connection

		loadingObserver:onChange(function()
			if loading:get() == true then
				connection = RunService.RenderStepped:Connect(function()
					local spinner = spinnerValue:get()
					if not spinner then
						return
					end

					spinner.Rotation += 1
				end)
			elseif loading:get() == false then
				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end)

		local worldModel = Instance.new("WorldModel")

		local viewport = New "ViewportFrame" {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.16, 0),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,

			ImageColor3 = Computed(function()
				return loading:get() and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
			end),

			[Children] = {
				New("ImageLabel")({
					Name = "Spinner",
					Image = "rbxassetid://11304130802",
					Size = UDim2.fromScale(0.2, 0.2),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ImageColor3 = Color3.fromRGB(50, 50, 50),
					BackgroundTransparency = 1,
					ZIndex = 101,

					Visible = Computed(function()
						return loading:get()
					end),

					[Ref] = spinnerValue,
				}),

				New "UICorner" {
					CornerRadius = UDim.new(0, 8),
				},
			},
		}

		task.spawn(function()
			loading:set(true)

			local _, unserializedBackground = pcall(RBLXSerialize.Decode, screenshotData.background)
			local unserializedCharacters = props.FeedProps.GetDeserializedCharacters(screenshotData.characters)

			unserializedCharacters.Parent = worldModel
			unserializedBackground.Parent = worldModel

			worldModel.Parent = viewport

			viewport.CurrentCamera = unserializedBackground

			loading:set(false)
		end)

		return {
			New("Frame")({
				Name = "Images",
				AutomaticSize = Enum.AutomaticSize.Y,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 3,

				Size = Computed(function()
					return loading:get() and UDim2.fromScale(0.775, 0.775) or UDim2.fromScale(0.775, 0)
				end),

				[Children] = {
					viewport,
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}),
		}
	end

	local imageInstance = Value()

	local function renderImages()
		if hasScreenshots then
			imageInstance:set(buildScreenshot(props.Screenshots[1]))
			return
		end

		imageInstance:set(isSingleImage and renderSingleImage() or renderMultipleImages())
	end

	if hasImages then
		renderImages()
	end

	return New("ImageButton")({
		Name = props.Id,
		Size = UDim2.fromScale(1, 0.2),
		ImageTransparency = 1,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoLocalize = false,
		LayoutOrder = isParent and -math.huge or props.LayoutOrder,

		[OnEvent("Activated")] = function()
			if totalDragMovement > 10 then
				return
			end

			if isParent then
				return
			end
			props.FeedProps.OnSwitchFeedClicked("replies", props.Id)
		end,

		[Ref] = postFrame,

		[Children] = {
			New("UIListLayout")({
				Padding = UDim.new(0.01, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			}),

			New("Frame")({
				Visible = isReplyToSomeone and visibleInRepliesFeed,

				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.04),
				BackgroundTransparency = 1,
				LayoutOrder = -2,
			}),

			New("ImageButton")({
				Visible = isReplyToSomeone and visibleInRepliesFeed,

				Name = "ReplyingTo",
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = -1,
				AutomaticSize = Enum.AutomaticSize.Y,

				[OnEvent("Activated")] = function()
					props.FeedProps.OnSwitchFeedClicked("replies", props.Id)
				end,

				[Children] = {
					New("ImageLabel")({
						Name = "ReplyingIcon",
						Size = UDim2.fromScale(1.3, 1.3),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.075, 0.5),
						ImageColor3 = Color3.fromRGB(142, 142, 142),
						BackgroundTransparency = 1,
						Image = "rbxassetid://12120467571",
					}),

					New("TextLabel")({
						Name = "Message",
						Size = UDim2.fromScale(0.76, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						BackgroundTransparency = 1,
						Text = "Replying to someone",
						TextWrapped = true,
						TextSize = workspace.CurrentCamera.ViewportSize.Y / 45,
						FontFace = displayNameFont,
						TextColor3 = Color3.fromRGB(142, 142, 142),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						AutomaticSize = Enum.AutomaticSize.Y,
					}),
				},
			}),

			New("Frame")({
				Name = "PostInfo",
				Size = UDim2.fromScale(1, 0.072),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 0,

				[Children] = {
					moreButton,

					New("ImageButton")({
						Name = "ProfilePicture",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(0.1, 0.1),
						Position = UDim2.fromScale(0, 0.35),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						ZIndex = 2,

						Image = Computed(function()
							return profileImage:get()
						end),
						LayoutOrder = 0,

						[OnEvent("Activated")] = function()
							props.FeedProps.OnSwitchFeedClicked(
								props.FeedProps.initialProfileFeed,
								props.Profile.UserId
							)
						end,

						[Children] = {
							New("UICorner")({
								CornerRadius = UDim.new(1, 0),
							}),

							New("Frame")({
								Name = "Background",
								Position = UDim2.new(0, 0, 0, -1),
								Size = UDim2.fromScale(1, 1),
								ZIndex = 1,

								[Children] = New("UICorner")({
									CornerRadius = UDim.new(1, 0),
								}),
							}),
						},
					}),

					New("Frame")({
						Name = "Info",
						Size = UDim2.fromScale(0.145, 0.625),
						Position = UDim2.fromScale(0.12, 0.3),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						AutomaticSize = Enum.AutomaticSize.X,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.015, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),

							New("TextButton")({
								Name = "DisplayName",
								Text = displayName,
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0, 1),
								TextScaled = true,
								FontFace = displayNameFont,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								LayoutOrder = 1,
								AutomaticSize = Enum.AutomaticSize.X,

								[OnEvent("Activated")] = function()
									props.FeedProps.OnSwitchFeedClicked(
										props.FeedProps.initialProfileFeed,
										props.Profile.UserId
									)
								end,
							}),

							New("TextLabel")({
								Name = "Username",
								Text = userName,
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0, 1),
								TextScaled = true,
								FontFace = nameFont,
								TextColor3 = Color3.fromRGB(134, 134, 134),
								LayoutOrder = 2,
								AutomaticSize = Enum.AutomaticSize.X,
							}),

							New("ImageLabel")({
								Name = "Dot",
								Size = UDim2.fromScale(0.15, 0.15),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,
								Image = "rbxassetid://12119853392",
								ImageColor3 = Color3.fromRGB(134, 134, 134),
								LayoutOrder = 3,
							}),

							New("TextLabel")({
								Name = "Time",
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0, 0.85),
								TextScaled = true,
								FontFace = nameFont,
								TextColor3 = Color3.fromRGB(134, 134, 134),
								LayoutOrder = 4,
								AutomaticSize = Enum.AutomaticSize.X,

								Text = Computed(function()
									return timeValue:get()
								end),

								[Fusion.Cleanup] = connection,
							}),
						},
					}),
				},
			}),

			New("Frame")({
				Name = "Content",
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = props.Content ~= "",

				[Children] = {
					New("TextLabel")({
						Name = "Message",
						Size = UDim2.fromScale(0.76, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						BackgroundTransparency = 1,
						Text = props.Content,
						TextWrapped = true,
						TextSize = workspace.CurrentCamera.ViewportSize.Y / 37,
						FontFace = nameFont,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						AutomaticSize = Enum.AutomaticSize.Y,
						AutoLocalize = false,
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}),

			Computed(function()
				return imageInstance:get()
			end),

			--hasImages and renderImages() or nil,

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.01),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}),

			DonateRow({
				donationData = Computed(function()
					return props.Donations
				end),
				Visible = Computed(function()
					local donationsExist = #props.Donations ~= 0
					return donationsExist
				end),
				ZIndex = 1,
				LayoutOrder = 3,
				Size = UDim2.fromScale(1, 0.08),
				ScrollingFramePosition = UDim2.fromScale(0.122, 0),
				ScrollingFrameSize = UDim2.fromScale(1 - 0.122, 1),
			}),

			New("Frame")({
				Name = "Actions",
				Size = UDim2.fromScale(1, 0.06),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,
				LayoutOrder = 6,

				[Children] = {
					New("Frame")({
						Name = "Container",
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromScale(0.12, 0),
						Size = UDim2.fromScale(0.78, 1),
						BackgroundTransparency = 1,

						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.02, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),

							ActionButton({
								Name = "Likes",

								Padding = 0.015,
								BackOffset = 0.2,
								FrontOffset = 0.2,
								MiddleOffset = 0.2,

								LayoutOrder = 1,
								CornerRadius = UDim.new(0.5, 0),
								BackgroundColor = Color3.fromRGB(55, 56, 56),

								Text = Computed(function()
									return likes:get()
								end),

								Icon = Computed(function()
									return likeButtonImage:get()
								end),
								IconSize = UDim2.fromScale(0.7, 0.7),

								OnActivated = function()
									if isReadOnly then
										props.FeedProps.EnablePopupMessage:set(true)
										return
									end

									if hasLikedThePost then
										hasLikedThePost = false
										likes:set(likes:get() - 1)
										likeButtonImage:set("rbxassetid://13468285399")
										props.FeedProps.OnLikeButtonClicked(props.Id, 0)
									else
										hasLikedThePost = true
										likes:set(likes:get() + 1)
										likeButtonImage:set("rbxassetid://13468285537")
										props.FeedProps.OnLikeButtonClicked(props.Id, 1)
									end
								end,
							}),

							ActionButton({
								Name = "Comments",

								Padding = 0.015,
								BackOffset = 0.2,
								FrontOffset = 0.2,
								MiddleOffset = 0.2,

								LayoutOrder = 2,
								CornerRadius = UDim.new(0.5, 0),
								BackgroundColor = Color3.fromRGB(55, 56, 56),

								Text = props.Comments,

								Icon = "rbxassetid://13468336082",
								IconSize = UDim2.fromScale(0.7, 0.7),

								OnActivated = function()
									if isReadOnly then
										props.FeedProps.EnablePopupMessage:set(true)
										return
									end

									if isParent then
										return
									end
									props.FeedProps.OnSwitchFeedClicked("replies", props.Id)
								end,
							}),

							props.ParentId == nil and ActionButton({
								Name = "Boost",

								Padding = 0.015,
								BackOffset = 0.2,
								FrontOffset = 0.2,
								MiddleOffset = 0.1,

								LayoutOrder = 3,
								CornerRadius = UDim.new(0.5, 0),
								BackgroundColor = Color3.fromRGB(55, 56, 56),

								Text = Computed(function()
									local count = boosts:get()
									if count == 0 then
										return "Boost"
									elseif count == 1 then
										return "1 Boost"
									else
										return count .. " Boosts"
									end
								end),

								Icon = "rbxassetid://13468295672",
								IconSize = UDim2.fromScale(0.8, 0.8),

								OnActivated = function()
									if isReadOnly then
										props.FeedProps.EnablePopupMessage:set(true)
										return
									end

									props.FeedProps.IsBoosting:set(true)
									props.FeedProps.BoostingPostId:set(props.Id)
									props.FeedProps.BoostingPostBoostValue = boosts
									props.FeedProps.OnBoostButtonClicked()
								end,
							}) or nil,
						},
					}),
				},
			}),

			New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Size = UDim2.fromScale(1, 0.02),
				BackgroundTransparency = 1,
				LayoutOrder = 7,
			}),

			Line({
				LayoutOrder = 8,
				Size = UDim2.fromScale(1, 0.004),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundColor3 = isParent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50),
			}),
		},
	})
end
