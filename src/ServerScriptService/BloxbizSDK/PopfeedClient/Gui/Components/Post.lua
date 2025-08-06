local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local ForPairs = Fusion.ForPairs
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local IconButton = require(GuiComponents.IconButton)
local TextButton = require(GuiComponents.TextButton)
local SelectButton = require(GuiComponents.SelectButton)
local DonateEmptyState = require(GuiComponents.Profile.DonateEmptyState)
local DonateRow = require(GuiComponents.Profile.DonateRow)

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local IMAGE_FORMAT = "rbxthumb://type=Asset&id=%s&w=150&h=150"
local IMAGES_PER_POST_LIMIT = 4

local noMoreResultsKeyword

local function validateInput(input: InputObject): boolean
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

	return isTouch or isClick
end

local function offsetToScale(parent: GuiObject, offset: Vector2): Vector2
	local viewPortSize = parent.AbsoluteSize
	if viewPortSize == Vector2.zero then
		viewPortSize = Vector2.new(1, 1)
	end

	return Vector2.new(offset.X / viewPortSize.X, offset.Y / viewPortSize.Y)
end

local function getUnderline(parent: GuiObject, underline: GuiObject, element: GuiObject): UDim2
	if not underline then
		return UDim2.fromScale(0, 0)
	end

	local underlineParent = underline.Parent
	if underlineParent then
		local elemPos = element.AbsolutePosition
		local elemSize = element.AbsoluteSize

		local desiredAbsolutePosition = Vector2.new(elemPos.X + elemSize.X / 2, elemPos.Y + elemSize.Y)

		local relativePosition = desiredAbsolutePosition - underlineParent.AbsolutePosition
		local scaleVector2 = offsetToScale(parent, relativePosition)

		return UDim2.fromScale(scaleVector2.X, scaleVector2.Y)
	end

	return UDim2.fromScale(0, 0)
end

return function(props)
	local textFont = Font.fromEnum(Enum.Font.Arial)
	textFont.Bold = true

	local images = props.Images

	local donationData = Value()
	local isLoadingDonations = Value(false)
	local showEmptyDonationsState = Value(false)

	local donationEnabledOnPost = Value(false)
	local imageMode = Value(false)
	local emptyStateMode = Value(false)
	local searchTermsMode = Value(false)

	local spinnerValue = Value()
	local selectedImages = Value({})
	local imageLoadDebounce = Value(false)

	local textBox = Value()
	local searchBox = Value()
	local searchBoxCancelVisible = Value(false)

	local viewportSize = workspace.CurrentCamera.ViewportSize.X

	local function visible()
		local isVisible = props.IsPosting:get()
		if isVisible then
			textBox:get():CaptureFocus()
		end

		return isVisible
	end

	local connection
	local function spinnerVisible()
		if #images:get() % 42 ~= 0 then
			return false
		end

		local isLoading = imageLoadDebounce:get()
		if isLoading == true and not connection then
			connection = RunService.RenderStepped:Connect(function()
				local spinner = spinnerValue:get()
				if not spinner then
					return
				end

				spinner.Rotation += 2
			end)
		else
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end

		return isLoading
	end

	local imageResultsObserver = Observer(images)
	imageResultsObserver:onChange(function()
		emptyStateMode:set(#images:get() == 0)
	end)

	local visibleImagesButton = Value(true)
	local visibleCameraButton = Value(true)

	local function onImageSelect(imageId)
		local selected = selectedImages:get()

		local index = table.find(selected, imageId)
		if index then
			table.remove(selected, index)
		else
			if #selected == IMAGES_PER_POST_LIMIT then
				return
			end

			table.insert(selected, imageId)
		end

		if #selected == 0 then
			visibleCameraButton:set(true)
		else
			visibleCameraButton:set(false)
		end

		selectedImages:set(selected)
	end

	local imagesUIListLayout = Value()
	local imagesScrollingFrame = Value()

	local screenshotTakenObserver = Observer(props.ScreenshotData)
	screenshotTakenObserver:onChange(function()
		local screenshotData = props.ScreenshotData:get()
		if not screenshotData then
			return
		end

		local viewport = screenshotData.Viewport

		props.IsOpened:set(true)

		task.defer(function()
			viewport.ZIndex = 7
			viewport.Size = UDim2.fromScale(1, 1)
			viewport.Visible = true

			local closeButton = New("TextButton")({
				Name = "CloseButton",
				Size = UDim2.fromScale(0.15, 0.15),
				Position = UDim2.fromScale(0.975, 0.025),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 0.2,
				ZIndex = 7,

				[OnEvent("Activated")] = function()
					onImageSelect(viewport)
					visibleImagesButton:set(true)
				end,

				[Children] = {
					New("ImageLabel")({
						Image = "rbxassetid://14542644751",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						ZIndex = 7,
					}),

					New("UICorner")({
						CornerRadius = UDim.new(0.5, 0),
					}),
				},
			})

			closeButton.Parent = viewport

			visibleImagesButton:set(false)

			local t = selectedImages:get()
			table.insert(t, viewport)
			selectedImages:set(t)
		end)
	end)

	task.defer(function()
		local layout = imagesUIListLayout:get()
		local scrollFrame = imagesScrollingFrame:get()

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scrollFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, 0)
		end)
	end)

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
			frame.CanvasPosition = Vector2.new(math.floor(frame.CanvasPosition.X - delta), 0)

			dragOldX = X
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
					isDragging = false
					dragOldX = nil
				end
			end)
		)
	end

	local holderValue = Value()
	local scrollingFrame = Value()
	local underlineValue = Value()
	local selectedImageButton = Value()

	Observer(imageMode):onChange(function()
		task.defer(function()
			task.wait()
			if imageMode:get() == true then
				selectedImageButton:set("ImagesButton")

				props.ImagesLoadedKeyword = ""
				props.DecalsNextPageCursor = nil
			else
				selectedImageButton:set()
			end
		end)
	end)

	local underlinePosSpring = Spring(
		Computed(function()
			local button = selectedImageButton:get()
			local holder = holderValue:get()
			local underline = underlineValue:get()

			if button and holder and underlineValue then
				button = holder:FindFirstChild(button)

				return getUnderline(holder, underline, button)
			end

			return UDim2.new(0.147, 0, 1, 0)
		end),
		40,
		1
	)

	return New("TextButton")({
		Name = "Post",
		Visible = Computed(visible),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		ZIndex = 5,

		[Cleanup] = function()
			for _, conn in connections do
				conn:Disconnect()
			end

			connections = nil
		end,

		[Children] = {
			New("Frame")({
				Name = "Bottom",
				Position = UDim2.fromScale(0.5, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				Size = Computed(function()
					local inImageMode = imageMode:get() == true
					if inImageMode then
						return UDim2.fromScale(1, 0.856)
					else
						return UDim2.fromScale(1, 0.928)
					end
				end),

				[Children] = {
					New("UIListLayout")({
						Padding = UDim.new(0.01, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Vertical,
					}),

					New("Frame")({
						Visible = Computed(function()
							local isReplying = props.PostingCommentParent:get() ~= nil
							if isReplying and not imageMode:get() then
								return true
							elseif imageMode:get() and selectedImageButton:get() == "DecalsButton" then
								return true
							end

							return false
						end),

						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Size = UDim2.fromScale(1, 0.04),
						BackgroundTransparency = 1,
						LayoutOrder = -2,
					}),

					New("ImageButton")({
						Visible = Computed(function()
							local isReplying = props.PostingCommentParent:get() ~= nil
							return isReplying and not imageMode:get()
						end),

						Name = "ReplyingTo",
						Size = UDim2.fromScale(1, 0),
						BackgroundTransparency = 1,
						ImageTransparency = 1,
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						LayoutOrder = -1,
						AutomaticSize = Enum.AutomaticSize.Y,

						[OnEvent("Activated")] = Fusion.doNothing,

						[Children] = {
							New("ImageLabel")({
								Name = "ReplyingIcon",
								Size = UDim2.fromScale(1.3, 1.3),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								AnchorPoint = Vector2.new(0.5, 0.5),
								ZIndex = 5,
								Position = UDim2.fromScale(0.075, 0.5),
								ImageColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								Image = "rbxassetid://12120467571",
							}),

							New("TextLabel")({
								Name = "Message",
								Size = UDim2.fromScale(0.76, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.5, 0),
								ZIndex = 5,
								BackgroundTransparency = 1,
								Text = "Replying to someone",
								TextWrapped = true,
								TextSize = workspace.CurrentCamera.ViewportSize.Y / 45,
								FontFace = textFont,
								TextColor3 = Color3.fromRGB(142, 142, 142),
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Top,
								AutomaticSize = Enum.AutomaticSize.Y,
							}),
						},
					}),

					New("Frame")({
						Name = "Actions",
						Size = UDim2.fromScale(1, 0.08),
						BackgroundTransparency = 1,
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						LayoutOrder = 6,
						ZIndex = 5,

						Visible = Computed(function()
							return not imageMode:get()
						end),

						[Children] = {
							New("Frame")({
								Name = "Container",
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.5, 0),
								Size = UDim2.fromScale(0.92, 1),
								BackgroundTransparency = 1,
								ZIndex = 5,

								[Children] = {
									New("UIListLayout")({
										Padding = UDim.new(0.0125, 0),
										SortOrder = Enum.SortOrder.LayoutOrder,
										FillDirection = Enum.FillDirection.Horizontal,
										VerticalAlignment = Enum.VerticalAlignment.Center,
									}),

									IconButton({
										Name = "Images",
										Text = "Images",
										Icon = "rbxassetid://13184649573",
										BoldText = true,
										IconSize = 0.6,
										LabelSize = 0.55,
										IconPositionX = 0.115,
										LabelPositionX = 0.065,
										IconAnchorPointX = 1,
										TextColor = Color3.fromRGB(255, 255, 255),
										BackgroundColor = Color3.fromRGB(70, 70, 70),
										CornerRadius = UDim.new(0.2, 0),
										Size = UDim2.fromScale(0.3, 1),
										LayoutOrder = 2,
										ZIndex = 5,

										Visible = Computed(function()
											return visibleImagesButton:get()
										end),

										Selected = Value(), --selectedImage,

										OnActivated = function()
											searchBox:get().Text = ""
											imageMode:set(true)
											searchTermsMode:set(true)
										end,
									}),

									IconButton({
										Name = "Donate",
										Text = "Donate",
										Icon = "rbxassetid://13184649429",
										BoldText = true,
										IconSize = 0.6,
										LabelSize = 0.55,
										IconPositionX = 0.125,
										LabelPositionX = 0.075,
										IconAnchorPointX = 1,
										TextColor = Color3.fromRGB(255, 255, 255),
										SelectedTextColor = Color3.fromRGB(30, 30, 30),
										BackgroundColor = Color3.fromRGB(71, 70, 70),
										SelectedBackgroundColor = Color3.fromRGB(255, 255, 255),
										CornerRadius = UDim.new(0.2, 0),
										Size = UDim2.fromScale(0.3, 1),
										LayoutOrder = 3,
										ZIndex = 5,

										Selected = donationEnabledOnPost,

										IsLoading = isLoadingDonations,

										OnActivated = function()
											isLoadingDonations:set(true)

											local items = props.RequestDonationItems(LocalPlayer.UserId)
											if items == "Loading" then
												return
											end

											local donationsEmpty = items == nil or #items.donations == 0

											isLoadingDonations:set(false)
											if not donationsEmpty then
												donationData:set(items.donations)
												donationEnabledOnPost:set(not donationEnabledOnPost:get())
												showEmptyDonationsState:set(false)
											else
												showEmptyDonationsState:set(true)
											end
										end,
									}),

									IconButton({
										Name = "Camera",
										Text = "Camera",
										Icon = "rbxassetid://16464224175",
										BoldText = true,
										IconSize = 0.6,
										LabelSize = 0.55,
										IconPositionX = 0.115,
										LabelPositionX = 0.065,
										IconAnchorPointX = 1,
										TextColor = Color3.fromRGB(255, 255, 255),
										SelectedTextColor = Color3.fromRGB(30, 30, 30),
										BackgroundColor = Color3.fromRGB(71, 70, 70),
										SelectedBackgroundColor = Color3.fromRGB(255, 255, 255),
										CornerRadius = UDim.new(0.2, 0),
										Size = UDim2.fromScale(0.32, 1),
										LayoutOrder = 1,
										ZIndex = 5,

										Visible = Computed(function()
											return visibleCameraButton:get()
										end),

										Selected = Value(),

										OnActivated = function()
											selectedImages:set({})
											props.IsOpened:set(false)
											props.ToggleCamera(true)
										end,
									}),
								},
							}),
						},
					}),

					New("ScrollingFrame")({
						Name = "DonationEmptyState",
						Size = UDim2.fromScale(1, 0.875),
						CanvasSize = UDim2.fromScale(1, 1),
						ScrollBarThickness = 0,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 6,
						ZIndex = 4,

						Visible = Computed(function()
							return showEmptyDonationsState:get()
						end),

						[Children] = New("Frame")({
							Name = "Container",
							Size = UDim2.fromScale(1, 0.65),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							ZIndex = 4,
							LayoutOrder = 5,

							[Children] = DonateEmptyState(props),
						}),
					}),

					DonateRow({
						ZIndex = 5,
						LayoutOrder = 3,
						Size = UDim2.fromScale(1, 0.1),
						ScrollingFramePosition = UDim2.fromScale(0.175, 0),
						ScrollingFrameSize = UDim2.fromScale(1 - 0.175, 1),

						donationData = Computed(function()
							return donationData:get() or {}
						end),

						Visible = Computed(function()
							return not imageMode:get() and donationEnabledOnPost:get()
						end),
					}),

					New("Frame")({
						Name = "SearchTerms",
						Size = UDim2.fromScale(1, 0.86),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						ZIndex = 5,

						Visible = Computed(function()
							return searchTermsMode:get()
						end),

						[Children] = {
							New("Frame")({
								Name = "List",
								Size = UDim2.fromScale(0.9, 0.5),
								Position = UDim2.fromScale(0.5, 0.015),
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundTransparency = 1,

								[Children] = {
									New("UIGridLayout")({
										CellSize = UDim2.fromScale(0.33, 0.1),
										CellPadding = UDim2.fromScale(0.1, 0.05),
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
									}),

									ForValues(props.ImageSearchTerms, function(searchTerm)
										return New("TextButton")({
											Name = searchTerm,
											ZIndex = 5,
											BackgroundTransparency = 1,

											[OnEvent("Activated")] = function()
												props.ImagesLoadedKeyword = searchTerm
												props.OnImagesButtonClicked(searchTerm, 1)
												searchTermsMode:set(false)

												searchBox:get().Text = searchTerm
												searchBoxCancelVisible:set(true)
											end,

											[Children] = {
												New("UIListLayout")({
													Padding = UDim.new(0.015, 0),
													SortOrder = Enum.SortOrder.LayoutOrder,
													FillDirection = Enum.FillDirection.Horizontal,
													VerticalAlignment = Enum.VerticalAlignment.Center,
												}),

												New("ImageLabel")({
													Size = UDim2.fromScale(0.7, 0.7),
													SizeConstraint = Enum.SizeConstraint.RelativeYY,
													BackgroundTransparency = 1,
													Image = "rbxassetid://13114890388",
													ImageColor3 = Color3.fromRGB(63, 160, 240),
													LayoutOrder = 1,
													ZIndex = 5,
												}),

												New("Frame")({
													Name = "BlankSpace",
													SizeConstraint = Enum.SizeConstraint.RelativeXX,
													Size = UDim2.fromScale(0.05, 0.01),
													BackgroundTransparency = 1,
													LayoutOrder = 2,
												}),

												New("TextLabel")({
													Name = "Term",
													Text = searchTerm,
													BackgroundTransparency = 1,
													Size = UDim2.fromScale(0, 1),
													TextScaled = true,
													FontFace = Font.fromEnum(Enum.Font.Arial),
													TextColor3 = Color3.fromRGB(63, 160, 240),
													AutomaticSize = Enum.AutomaticSize.X,
													LayoutOrder = 3,
													ZIndex = 5,
												}),
											},
										})
									end, Fusion.cleanup),
								},
							}),
						},
					}),

					New("ScrollingFrame")({
						Name = "ImageList",
						Size = UDim2.fromScale(1, 0.875),
						ScrollBarThickness = 0,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 4,
						ZIndex = 5,

						[Ref] = props.ImageScrollingFrame,

						Visible = Computed(function()
							if searchTermsMode:get() == false and imageMode:get() == true then
								return true
							end

							return false
						end),

						[OnChange("CanvasPosition")] = function()
							local list = props.ImageScrollingFrame:get()
							if not list then
								return
							end

							local MaxCanvasPosY = list.CanvasSize.Y.Offset - list.AbsoluteWindowSize.Y
							if MaxCanvasPosY - list.AbsoluteSize.Y * 3 < list.CanvasPosition.Y then
								if selectedImageButton:get() == "DecalsButton" then
									if imageLoadDebounce:get() then
										return
									end
									imageLoadDebounce:set(true)

									props.OnDecalsButtonClicked(props.DecalsNextPageCursor, true)

									imageLoadDebounce:set(false)
								else
									local keyword = searchBox:get().Text
									local page = props.ImagesPage + 1

									if noMoreResultsKeyword == keyword then
										return
									end

									if imageLoadDebounce:get() then
										return
									end
									imageLoadDebounce:set(true)

									local noMoreResults = props.OnImagesButtonClicked(keyword, page, true)
									if noMoreResults then
										noMoreResultsKeyword = keyword
									end

									imageLoadDebounce:set(false)
								end
							end
						end,

						[Children] = {
							New("TextLabel")({
								Name = "NoResults",
								BackgroundTransparency = 1,
								TextScaled = true,
								FontFace = textFont,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.5, 0.02),
								Size = UDim2.fromScale(0.8, 0.035),
								ZIndex = 5,

								Text = Computed(function()
									local isDecalMode = selectedImageButton:get() == "DecalsButton"
									if isDecalMode then
										return "Upload decals on the Roblox website"
									else
										return "No Results Found"
									end
								end),

								Visible = Computed(function()
									return emptyStateMode:get()
								end),
							}),

							New("Frame")({
								Name = "Container",
								Size = UDim2.fromScale(0.925, 1.4),
								Position = UDim2.fromScale(0.5, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								BackgroundTransparency = 1,
								ZIndex = 5,

								[Children] = {
									New("UIGridLayout")({
										CellPadding = UDim2.fromScale(0.02, 0.011),
										CellSize = UDim2.fromScale(0.32, 0.211),
										SortOrder = Enum.SortOrder.LayoutOrder,
									}),

									New("Frame")({
										Name = "PlaceHolder",
										LayoutOrder = 1000000,

										Visible = Computed(function()
											return imageLoadDebounce:get()
										end),
									}),

									New("Frame")({
										Name = "SpinnerFrame",
										LayoutOrder = 1000001,

										Visible = Computed(spinnerVisible),

										[OnChange("Visible")] = function()
											local list = props.ImageScrollingFrame:get()
											if list then
												task.defer(function()
													list.CanvasSize = UDim2.fromOffset(
														0,
														list.Container.UIGridLayout.AbsoluteContentSize.Y
													)
												end)
											end
										end,

										[Children] = {
											New("ImageLabel")({
												Name = "Spinner",
												Size = UDim2.fromScale(0.5, 0.5),
												Position = UDim2.fromScale(0.5, 0.425),
												AnchorPoint = Vector2.new(0.5, 0.5),
												Image = "rbxassetid://11304130802",
												SizeConstraint = Enum.SizeConstraint.RelativeYY,
												BackgroundTransparency = 1,
												ZIndex = 5,

												[Ref] = spinnerValue,
											}),
										},
									}),

									ForPairs(images, function(index, image)
										local assetId = image.AssetId or image.assetId

										return index,
											New("ImageButton")({
												Name = assetId,
												Image = IMAGE_FORMAT:format(assetId),
												BackgroundColor3 = Color3.fromRGB(70, 70, 70),
												LayoutOrder = index,
												ZIndex = 5,

												[OnEvent("Activated")] = function()
													onImageSelect(assetId)
												end,

												[Children] = {
													Computed(function()
														local imageIndex =
															table.find(selectedImages:get(), assetId)

														if imageIndex then
															return {
																New("Frame")({
																	Name = "Number",
																	Size = UDim2.fromScale(0.175, 0.175),
																	Position = UDim2.fromScale(0.875, 0.125),
																	AnchorPoint = Vector2.new(0.5, 0.5),
																	BackgroundColor3 = Color3.fromRGB(0, 170, 255),
																	ZIndex = 5,

																	[Children] = {
																		New("TextLabel")({
																			Text = imageIndex,
																			Size = UDim2.fromScale(0.8, 0.8),
																			Position = UDim2.fromScale(0.5, 0.5),
																			AnchorPoint = Vector2.new(0.5, 0.5),
																			TextColor3 = Color3.fromRGB(255, 255, 255),
																			BackgroundTransparency = 1,
																			ZIndex = 5,
																			FontFace = textFont,
																		}),

																		New("UICorner")({
																			CornerRadius = UDim.new(0.5, 0),
																		}),
																	},
																}),

																New("Frame")({
																	Name = "Top",
																	Size = UDim2.fromScale(1, 0.025),
																	Position = UDim2.fromScale(0, 0),
																	BackgroundColor3 = Color3.fromRGB(0, 170, 255),
																	ZIndex = 5,
																}),

																New("Frame")({
																	Name = "Bottom",
																	Size = UDim2.fromScale(1, 0.025),
																	Position = UDim2.fromScale(0, 1),
																	AnchorPoint = Vector2.new(0, 1),
																	BackgroundColor3 = Color3.fromRGB(0, 170, 255),
																	ZIndex = 5,
																}),

																New("Frame")({
																	Name = "Left",
																	Size = UDim2.fromScale(0.025, 1),
																	Position = UDim2.fromScale(0, 0),
																	BackgroundColor3 = Color3.fromRGB(0, 170, 255),
																	ZIndex = 5,
																}),

																New("Frame")({
																	Name = "Top",
																	Size = UDim2.fromScale(0.025, 1),
																	Position = UDim2.fromScale(1, 0),
																	AnchorPoint = Vector2.new(1, 0),
																	BackgroundColor3 = Color3.fromRGB(0, 170, 255),
																	ZIndex = 5,
																}),
															}
														end
													end, Fusion.cleanup),

													New("UIAspectRatioConstraint")({}),
												},
											})
									end, Fusion.cleanup),
								},
							}),
						},
					}),

					New("Frame")({
						Name = "ImageSearch",
						Size = UDim2.fromScale(1, 0.08),
						BackgroundTransparency = 1,
						LayoutOrder = 1,

						Visible = Computed(function()
							if imageMode:get() ~= true then
								return false
							end

							return selectedImageButton:get() == "ImagesButton"
						end),

						[Children] = {
							New("Frame")({
								Name = "Container",
								Size = UDim2.fromScale(0.9, 0.7),
								Position = UDim2.fromScale(0.5, 0.55),
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
											searchTermsMode:set(true)
											emptyStateMode:set(false)
											searchBox:get().Text = ""
											searchBox:get():CaptureFocus()
											images:set({})
											props.ImagesLoadedKeyword = ""
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
										PlaceholderText = "Search images by term or ID",
										PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
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

											searchTermsMode:set(false)

											local keyword = searchBox:get().Text
											if keyword == props.ImagesLoadedKeyword then
												return
											end

											props.OnImagesButtonClicked(keyword, 1)
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
						},
					}),

					New("Frame")({
						Name = "TextComposer",
						Size = UDim2.fromScale(1, 0),
						Position = UDim2.fromScale(0.5, 1),
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						AutomaticSize = Enum.AutomaticSize.Y,

						Visible = Computed(function()
							return not imageMode:get()
						end),

						[Children] = {
							New("ImageLabel")({
								Name = "ProfilePicture",
								Size = UDim2.fromScale(0.11, 0.11),
								Position = UDim2.fromScale(0.04, 0.3),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								Image = props.GetUserProfilePicture(LocalPlayer.UserId),
								BackgroundTransparency = 1,
								ZIndex = 6,

								[Children] = {
									New("UICorner")({
										CornerRadius = UDim.new(1, 0),
									}),

									New("Frame")({
										Name = "Background",
										Position = UDim2.new(0, 0, 0, -1),
										Size = UDim2.fromScale(1, 1),
										ZIndex = 5,

										[Children] = New("UICorner")({
											CornerRadius = UDim.new(1, 0),
										}),
									}),
								},
							}),

							New("TextBox")({
								Name = "Content",
								Size = UDim2.fromScale(0.75, 0.1),
								Position = UDim2.fromScale(0.175, 0.25),
								FontFace = Font.fromEnum(Enum.Font.Arial),
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Top,
								TextWrapped = true,
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								PlaceholderText = "Write something...",
								PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
								AutomaticSize = Enum.AutomaticSize.Y,
								ZIndex = 5,

								TextSize = Computed(function()
									if props.IsVertical:get() == true then
										return viewportSize / 40
									else
										return viewportSize / 60
									end
								end),

								Text = Computed(function()
									return props.PostingContent:get() or ""
								end),

								[OnEvent("FocusLost")] = function()
									props.PostingContent:set(textBox:get().Text)
								end,

								[OnChange("Text")] = function()
									local text = textBox:get().Text
									if #text > 280 then
										textBox:get().Text = text:sub(1, 280)
									end
								end,

								[Ref] = textBox,
							}),
						},
					}),

					New("Frame")({
						Name = "Images",
						Size = UDim2.fromScale(0.6, 0.6),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						ZIndex = 5,

						Visible = Computed(function()
							local isInImageMode = imageMode:get() == true
							local hasSelectedImage = #selectedImages:get() > 0

							return not isInImageMode and hasSelectedImage
						end),

						[Children] = {
							New("ScrollingFrame")({
								Name = "Images",
								Size = UDim2.fromScale(1.377, 1),
								Position = UDim2.fromScale(0.29, 0),
								CanvasSize = UDim2.fromScale(0, 0),
								ScrollingDirection = Enum.ScrollingDirection.X,
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								ScrollBarThickness = 10,
								ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								ClipsDescendants = false,
								ZIndex = 5,

								[Ref] = imagesScrollingFrame,

								[Children] = {
									New("Frame")({
										Name = "Container",
										Size = UDim2.new(1, -16, 1, -16),
										SizeConstraint = Enum.SizeConstraint.RelativeYY,
										BackgroundTransparency = 1,
										ZIndex = 5,

										[Children] = {
											New("UIListLayout")({
												Padding = UDim.new(0.04, 0),
												SortOrder = Enum.SortOrder.LayoutOrder,
												FillDirection = Enum.FillDirection.Horizontal,
												HorizontalAlignment = Enum.HorizontalAlignment.Left,

												[Ref] = imagesUIListLayout,
											}),

											ForPairs(selectedImages, function(index, imageId)
												if typeof(imageId) == "Instance" then
													return index, imageId
												end

												return index,
													New("ImageLabel")({
														Name = "Image",
														Size = UDim2.fromScale(1, 1),
														SizeConstraint = Enum.SizeConstraint.RelativeXX,
														BackgroundTransparency = 1,
														LayoutOrder = index,
														Image = IMAGE_FORMAT:format(imageId),
														ZIndex = 5,

														[Children] = {
															New("TextButton")({
																Name = "CloseButton",
																Size = UDim2.fromScale(0.15, 0.15),
																Position = UDim2.fromScale(0.975, 0.025),
																AnchorPoint = Vector2.new(1, 0),
																BackgroundColor3 = Color3.fromRGB(0, 0, 0),
																SizeConstraint = Enum.SizeConstraint.RelativeXX,
																BackgroundTransparency = 0.2,
																ZIndex = 5,

																[OnEvent("Activated")] = function()
																	onImageSelect(imageId)
																end,

																[Children] = {
																	New("ImageLabel")({
																		Image = "rbxassetid://14542644751",
																		BackgroundTransparency = 1,
																		Size = UDim2.fromScale(0.5, 0.5),
																		Position = UDim2.fromScale(0.5, 0.5),
																		AnchorPoint = Vector2.new(0.5, 0.5),
																		ZIndex = 5,
																	}),

																	New("UICorner")({
																		CornerRadius = UDim.new(0.5, 0),
																	}),
																},
															}),

															New("UICorner")({
																CornerRadius = UDim.new(0, 8),
															}),
														},
													})
											end, Fusion.cleanup),
										},
									}),
								},
							}),
						},
					}),

					Computed(function()
						local inImageMode = imageMode:get() == true
						if inImageMode then
							return nil
						else
							return Line({
								ZIndex = 5,
								LayoutOrder = 1,
								Size = UDim2.fromScale(1, 0.002),
								Position = UDim2.fromScale(0.5, 0.55),
								AnchorPoint = Vector2.new(0.5, 0),
							})
						end
					end, Fusion.cleanup),

					New("Frame")({
						Name = "BlankSpace",
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Size = UDim2.fromScale(1, 0 * 0.01),
						BackgroundTransparency = 1,
						LayoutOrder = 5,
					}),
				},
			}),

			New("Frame")({
				Name = "Top",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0),

				Size = Computed(function()
					local inImageMode = imageMode:get() == true
					if inImageMode then
						return UDim2.fromScale(1, 0.144)
					else
						return UDim2.fromScale(1, 0.072)
					end
				end),

				[Children] = {
					Computed(function()
						local inImageMode = imageMode:get() == true
						if inImageMode then
							return New("ScrollingFrame")({
								Name = "Navigation",
								Size = UDim2.fromScale(0.7, 0.34),
								Position = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 1),
								CanvasSize = UDim2.fromScale(0, 0),
								ScrollBarThickness = 0,
								ScrollingDirection = Enum.ScrollingDirection.X,
								AutomaticCanvasSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 1,

								--Visible = Computed(visibleNavigationBar),

								[Ref] = scrollingFrame,

								[Children] = {
									New("Frame")({
										Name = "Container",
										Size = UDim2.fromScale(1, 1),
										BackgroundTransparency = 1,

										[Children] = {
											New("Frame")({
												Name = "Underline",
												AnchorPoint = Vector2.new(0.5, 1),
												BackgroundColor3 = Color3.fromRGB(0, 170, 255),
												Position = underlinePosSpring,
												Size = UDim2.fromScale(0.09, 0.1),
												ZIndex = 5,

												[Ref] = underlineValue,

												[Children] = {
													New("UICorner")({
														CornerRadius = UDim.new(0.5, 0),
													}),
												},
											}),

											New("Frame")({
												Name = "Holder",
												Size = UDim2.fromScale(1, 0.6),
												BackgroundTransparency = 1,

												[Ref] = holderValue,

												[Children] = {
													New("UIListLayout")({
														Padding = UDim.new(0.15, 0),
														SortOrder = Enum.SortOrder.LayoutOrder,
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
													}),

													New("TextButton")({
														Name = "ImagesButton",
														Text = "All Images",
														Size = UDim2.fromScale(0, 1),
														AutomaticSize = Enum.AutomaticSize.X,
														BackgroundTransparency = 1,
														TextScaled = true,
														FontFace = textFont,
														ZIndex = 5,

														TextColor3 = Computed(function()
															local selected = selectedImageButton:get()
															if selected == "ImagesButton" then
																return Color3.fromRGB(255, 255, 255)
															else
																return Color3.fromRGB(134, 134, 134)
															end
														end),

														[OnEvent("Activated")] = function()
															selectedImageButton:set("ImagesButton")
															searchTermsMode:set(true)
															props.Images:set({})
															props.ImagesLoadedKeyword = ""
															props.DecalsNextPageCursor = nil
														end,
													}),

													New("TextButton")({
														Name = "DecalsButton",
														Text = "Your Decals",
														Size = UDim2.fromScale(0, 1),
														AutomaticSize = Enum.AutomaticSize.X,
														BackgroundTransparency = 1,
														TextScaled = true,
														FontFace = textFont,
														ZIndex = 5,

														TextColor3 = Computed(function()
															local selected = selectedImageButton:get()
															if selected == "DecalsButton" then
																return Color3.fromRGB(255, 255, 255)
															else
																return Color3.fromRGB(134, 134, 134)
															end
														end),

														[OnEvent("Activated")] = function()
															selectedImageButton:set("DecalsButton")
															props.Images:set({})

															props.OnDecalsButtonClicked(props.DecalsNextPageCursor)
															searchTermsMode:set(false)
														end,
													}),
												},
											}),
										},
									}),
								},
							})
						else
							return nil
						end
					end, Fusion.cleanup),

					TextButton({
						Name = "PostButton",
						AnchorPoint = Vector2.new(1, 0.5),
						TextSize = UDim2.fromScale(0.9, 0.58),
						CornerRadius = UDim.new(0.5, 0),
						ZIndex = 5,
						Bold = true,

						Position = Computed(function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								return UDim2.fromScale(0.94, 0.3)
							else
								return UDim2.fromScale(0.94, 0.5)
							end
						end),

						TextColor = Computed(function()
							local inImageMode = imageMode:get() == true
							local hasSelectedImage = #selectedImages:get() > 0

							if inImageMode and not hasSelectedImage then
								return Color3.fromRGB(180, 180, 180)
							else
								return Color3.fromRGB(255, 255, 255)
							end
						end),

						Color = Computed(function()
							local inImageMode = imageMode:get() == true
							local hasSelectedImage = #selectedImages:get() > 0

							if inImageMode and not selectedImages then
								return Color3.fromRGB(0, 103, 155)
							else
								return Color3.fromRGB(0, 170, 255)
							end
						end),

						Size = Computed(function()
							local inImageMode = imageMode:get() == true
							local hasSelectedImage = #selectedImages:get() > 0

							if inImageMode then
								if hasSelectedImage then
									return UDim2.fromScale(0.3, 0.375)
								else
									return UDim2.fromScale(0.4, 0.375)
								end
							else
								local isCommenting = not not props.PostingCommentParent:get()

								return UDim2.fromScale(isCommenting and 0.205 or 0.15, 0.65)
							end
						end),

						Text = Computed(function()
							local imageCount = #selectedImages:get()
							local hasSelectedImage = imageCount > 0
							local inImageMode = imageMode:get() == true

							if inImageMode then
								if hasSelectedImage then
									return "Add " .. imageCount .. " images"
								else
									return "Select an image"
								end
							else
								local isCommenting = not not props.PostingCommentParent:get()

								return isCommenting and "Reply" or "Post"
							end
						end),

						OnActivated = function()
							local inImageMode = imageMode:get() == true
							local selected = selectedImages:get()
							local hasSelectedImage = #selected > 0

							if inImageMode then
								if hasSelectedImage then
									imageMode:set(false)
									searchTermsMode:set(false)
								end
							else
								props.OnPostButtonClicked(selected, donationEnabledOnPost:get())
								props.ScreenshotData:set()
								selectedImages:set({})
								visibleCameraButton:set(true)
								visibleImagesButton:set(true)
							end
						end,
					}),

					SelectButton({
						Name = "CancelButton",
						Color = Color3.fromRGB(255, 255, 255),
						AnchorPoint = Vector2.new(0, 0.5),
						AutomaticSize = Enum.AutomaticSize.X,
						ZIndex = 5,
						Bold = true,

						Size = Computed(function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								return UDim2.fromScale(0, 0.22)
							else
								return UDim2.fromScale(0, 0.41)
							end
						end),

						Position = Computed(function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								return UDim2.fromScale(0.06, 0.3)
							else
								return UDim2.fromScale(0.06, 0.5)
							end
						end),

						Text = Computed(function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								return "< Back"
							else
								return "Cancel"
							end
						end),

						OnActivated = function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								props.ImagesLoadedKeyword = ""
								props.IsLoading:set(false)
								searchTermsMode:set(false)
								imageMode:set(false)
								searchBox:get().Text = ""
								images:set({})
							else
								props.IsPosting:set(false)
								props.PostingContent:set(nil)
								props.ScreenshotData:set()
							end

							selectedImages:set({})
							visibleCameraButton:set(true)
							visibleImagesButton:set(true)
						end,
					}),

					Line({
						ZIndex = 5,

						Size = Computed(function()
							local inImageMode = imageMode:get() == true
							if inImageMode then
								return UDim2.fromScale(1, 0.01)
							else
								return UDim2.fromScale(1, 0.02)
							end
						end),
					}),
				},
			}),

			New("UICorner")({
				CornerRadius = Computed(function()
					if props.IsVertical:get() == true then
						return UDim.new(0, 0)
					else
						return UDim.new(0, 16)
					end
				end),
			}),
		},
	})
end
