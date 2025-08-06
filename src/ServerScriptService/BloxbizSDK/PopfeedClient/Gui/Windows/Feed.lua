local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Utils = require(script.Parent.Parent.Parent.Parent.Utils)

local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Post = require(GuiComponents.Post)
local Boost = require(GuiComponents.Boost)
local Screen = require(GuiComponents.Screen)
local Options = require(GuiComponents.Options)
local FeedTop = require(GuiComponents.FeedTop)
local UserList = require(GuiComponents.UserList)
local ExploreTab = require(GuiComponents.ExploreTab)
local FeedBottom = require(GuiComponents.FeedBottom)
local ExploreTop = require(GuiComponents.ExploreTop)
local RepliesTop = require(GuiComponents.RepliesTop)
local ProfileTop = require(GuiComponents.ProfileTop)
local NotificationsTop = require(GuiComponents.NotificationsTop)
local LoadingState = require(GuiComponents.LoadingState)
local FollowFriends = require(GuiComponents.FollowFriends)
local PopupNotification = require(GuiComponents.PopupNotification)

local cachedExplorePagePosition

return function(props)
	local isReadOnly = props.Config.permissions == "read_only"

	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = true

	local spinnerValue = Value()

	local connection
	local function spinnerVisible()
		if props.FetchingFeedTypeValue:get() == "explore" then
			return false
		end

		local isLoading = props.ContentFetchDebounce:get()
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

	local uIListLayout = props.UIListLayout
	local contentFrame = props.ContentFrame
	local scrollingFrame = props.ScrollingFrame

	local isOpenedState = props.IsOpened

	local postsSeen = {}

	RunService.Heartbeat:Connect(function()
		local postsFrame = contentFrame:get()
		local listFrame = scrollingFrame:get()

		local posts = props.PostsForImpressionCheck

		if #posts == 0 or not postsFrame or not listFrame then
			return
		end

		local listSize = listFrame.AbsoluteSize.Y
		local listPosition = listFrame.AbsolutePosition.Y

		for _, post in posts do
			if typeof(post) ~= "table" then
				continue
			end

			local id = post.Id

			local postFrame = postsFrame[post.Id]

			local postSize = postFrame.AbsoluteSize.Y
			local postPosition = postFrame.AbsolutePosition.Y - listPosition

			local postHalfSize = postSize * 0.5
			local postMaxY = postPosition + postSize

			local isVisibleMin = postMaxY > postHalfSize
			local isVisibleMax = postMaxY < listSize + postHalfSize

			if isVisibleMin and isVisibleMax then
				if postsSeen[id] then
					return
				end
				postsSeen[id] = true

				table.insert(props.PostImpressions, id)
			else
				postsSeen[id] = nil
			end
		end
	end)

	local function visible()
		return isOpenedState:get()
	end

	local function loadUserInfoForPosts(posts)
		local userIds = {}
		for _, post in posts do
			table.insert(userIds, post.Profile.UserId)
		end

		props.getUserInfoFromUserIds(userIds)
	end

	local function loadUserInfoForNotifications(contentDataList)
		local usersToLoad = {}
		for _, contentData in contentDataList do
			if not contentData.player_ids then
				continue
			end

			for _, userId in contentData.player_ids do
				table.insert(usersToLoad, userId)
			end
		end

		local userInfo = props.getUserInfoFromUserIds(usersToLoad)
		for _, contentData in contentDataList do
			if not contentData.player_ids then
				continue
			end

			contentData.topUserInfo = userInfo[contentData.player_ids[1]]
		end
	end

	local function updateScrollingFrame(changeData)
		local list = scrollingFrame:get()
		if not list then
			props.IsLoading:set(false)
			props.ContentFetchDebounce:set(nil)
			return
		end

		list.CanvasPosition = Vector2.zero
		list.CanvasSize = UDim2.new(0, 0, 0, uIListLayout:get().AbsoluteContentSize.Y)

		local currentFeed = props.CurrentFeedTypeValue:get()
		local lastViewedPost = changeData and changeData.LastViewedPost or props.LastViewedPost[currentFeed]
		if lastViewedPost and lastViewedPost.Id then
			local postFrame = contentFrame:get():FindFirstChild(lastViewedPost.Id)
			if postFrame then
				list.CanvasPosition = Vector2.new(0, postFrame.AbsolutePosition.Y - lastViewedPost.Position + 1)
			end
		end

		props.IsLoading:set(false)
		props.ContentFetchDebounce:set(nil)
	end

	local function renderProfileItems(posts, donateionItems)
		local profileView = require(GuiComponents.Profile)(props)
		if not profileView then
			return
		end

		posts = props.ContentToRender:get()
		table.insert(posts, profileView)

		local onShopTab = props.CurrentFeedType == "shop"
		local onDonateTab = props.CurrentFeedType == "donations"

		if onShopTab then
			local shopTable = require(GuiComponents.Profile.ShopTable)(props)
			table.insert(posts, shopTable)
		elseif onDonateTab then
			local donateTable = require(GuiComponents.Profile.DonateTable)(props, donateionItems)
			table.insert(posts, donateTable)
		end

		props.ContentToRender:set(posts)
	end

	props.RenderPosts.Event:Connect(function(extraData, changeData)
		local previousFeed = props.CurrentFeedTypeValue:get()
		if previousFeed then
			props.LastViewedPost[previousFeed] = props.CalculateCanvasOffset()
		end

		if props.CurrentFeedType ~= "notifications" then
			loadUserInfoForPosts(props.CurrentPosts)
		else
			loadUserInfoForNotifications(props.CurrentPosts)
		end

		local fillRenderTableWithPosts = props.CurrentFeedType ~= "donations"
		if fillRenderTableWithPosts then
			local fetchingFeed = props.FetchingFeedTypeValue:get()
			if fetchingFeed == "following" then
				table.insert(
					props.CurrentPosts,
					FollowFriends({
						FeedProps = props,
						LayoutOrder = -1,
						Size = UDim2.fromScale(1, 0.43),
						LineSize = UDim2.fromScale(1, 0.005),
					})
				)
			end

			props.PostFrames = {}
			props.ContentToRender:set(props.CurrentPosts)
		else
			props.PostFrames = {}
			props.ContentToRender:set({})
		end

		props.PostsForImpressionCheck = props.CurrentFeedType ~= "notifications" and Utils.copyTable(props.ContentToRender:get()) or {}

		local isProfileFeed = props.isProfileFeed(props.CurrentFeedType)
		if isProfileFeed then
			props.IsFollowing = props.CurrentProfileData:get().is_following
			renderProfileItems(props.CurrentPosts, extraData)
		else
			props.IsFollowing = nil
		end

		props.CurrentFeedTypeValue:set(props.CurrentFeedType)

		props.DisableHomeButtons = false

		task.defer(updateScrollingFrame, changeData)
	end)

	local function initiatePost(postData)
		local postFrame

		if typeof(postData) == "Instance" then
			postFrame = postData
		elseif props.CurrentFeedType == "notifications" then
			postData.FeedProps = props

			postFrame = require(GuiComponents.Notification)(postData)
		else
			local cachedUserInfo = props.cachedUserInfos[postData.Profile.UserId]
			postData.Profile.Name = cachedUserInfo.Username
			postData.Profile.DisplayName = cachedUserInfo.DisplayName
			postData.FeedProps = props

			if postData.IsParent then
				postFrame = require(GuiComponents.PostView)(postData)
			else
				postFrame = require(GuiComponents.Content)(postData)
			end
		end

		table.insert(props.PostFrames, postFrame)

		return postFrame
	end

	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36

	return Screen({
		Name = "Popfeed",
		DisplayOrder = 999,

		Children = {
			New("Frame")({
				Name = "Container",
				Visible = Computed(visible),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),

				Size = Computed(function()
					if props.IsVertical:get() == true then
						return UDim2.new(1, 0, 1, isNewTopBar and -55 or -40)
					else
						return UDim2.fromScale(0.9, 0.9)
					end
				end),

				Position = Computed(function()
					if props.IsVertical:get() == true then
						return UDim2.new(0.5, 0, 0.5, isNewTopBar and 27.5 or 20)
					else
						return UDim2.fromScale(0.5, 0.5)
					end
				end),

				[Children] = {
					New("TextButton")({
						Name = "PostButton",
						Position = UDim2.fromScale(0.9, 0.85),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(0, 170, 255),
						ZIndex = 2,

						Size = Computed(function()
							if props.IsVertical:get() then
								return UDim2.fromScale(0.15, 0.15)
							else
								return UDim2.fromScale(0.12, 0.12)
							end
						end),

						Visible = Computed(function()
							local feed = props.CurrentFeedTypeValue:get()

							return feed ~= "replies" and feed ~= "donations" and feed ~= "explore"
						end),

						[OnEvent("Activated")] = function()
							if isReadOnly then
								props.EnablePopupMessage:set(true)
								return
							end

							props.IsPosting:set(true)
						end,

						[Children] = {
							New "ImageLabel" {
								Image = "rbxassetid://104282639933907",
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								ZIndex = 2,
							},

							New "UICorner" {
								CornerRadius = UDim.new(0.5, 0),
							},

							New "UIAspectRatioConstraint" {
								AspectRatio = 1,
								DominantAxis = Enum.DominantAxis.Height,
							},
						},
					}),

					New("TextButton")({
						Name = "CloseButton",
						Size = UDim2.fromScale(0.1, 0.1),
						Position = UDim2.fromScale(1, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(231, 60, 60),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						ZIndex = 500,

						Visible = Computed(function()
							return props.IsVertical:get() ~= true
						end),

						[OnEvent("Activated")] = function()
							if props.TopbarButton then
								props.TopbarButton:deselect()
							else
								props.closePopfeed()
							end
						end,

						[Children] = {
							New("ImageLabel")({
								Image = "rbxassetid://14542644751",
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								ZIndex = 501,
							}),

							New("UICorner")({
								CornerRadius = UDim.new(0, 8),
							}),
						},
					}),

					Post(props),
					Boost(props),
					Options(props),
					UserList(props),

					Computed(function()
						local newFeedType = props.FetchingFeedTypeValue:get()
						local scrollFrame = props.ExploreTabScrollingFrame:get()

						if scrollFrame then
							cachedExplorePagePosition = scrollFrame.CanvasPosition
						end

						if newFeedType == "explore" then
							return ExploreTab(props, cachedExplorePagePosition)
						end
					end, Fusion.cleanup),

					New("ScrollingFrame")({
						Name = "List",
						AnchorPoint = Vector2.new(0.5, 0),
						ScrollBarThickness = 0,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						BackgroundTransparency = 1,
						ClipsDescendants = true,

						Size = Computed(function()
							local feedType = props.FetchingFeedTypeValue:get()

							if props.isFeedTypeHomeFeed(feedType) then
								return UDim2.fromScale(0.95, 0.763)
							else
								return UDim2.fromScale(0.95, 0.81)
							end
						end),

						Position = Computed(function()
							local feedType = props.FetchingFeedTypeValue:get()

							if props.isFeedTypeHomeFeed(feedType) then
								return UDim2.fromScale(0.5, 0.151)
							else
								return UDim2.fromScale(0.5, 0.1)
							end
						end),

						Visible = Computed(function()
							return not props.IsLoading:get()
						end),

						ScrollingEnabled = Computed(function()
							return not props.IsLoading:get()
						end),

						[Ref] = scrollingFrame,

						[OnChange("CanvasPosition")] = function(newPosition)
							props.OnCanvasPositionChanged(scrollingFrame:get(), newPosition)
						end,

						[Children] = {
							New("Frame")({
								Name = "Content",
								Size = UDim2.fromScale(0.95, 0.692),
								Position = UDim2.fromScale(0.5, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								BackgroundTransparency = 1,

								[Ref] = contentFrame,

								[Children] = {
									New("UIListLayout")({
										Padding = UDim.new(0.01, 0),
										SortOrder = Enum.SortOrder.LayoutOrder,
										FillDirection = Enum.FillDirection.Vertical,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,

										[Ref] = uIListLayout,
									}),

									ForValues(props.ContentToRender, initiatePost, Fusion.cleanup),

									New("Frame")({
										Name = "SpinnerFrame",
										Size = UDim2.fromScale(1, 0.175),
										SizeConstraint = Enum.SizeConstraint.RelativeXX,
										BackgroundTransparency = 1,

										LayoutOrder = Computed(function()
											return props.ContentLoadSpinnerLayoutOrder:get()
										end),

										Visible = Computed(spinnerVisible),

										[OnChange("Visible")] = function()
											local list = scrollingFrame:get()
											if list then
												task.defer(function()
													local layoutOrder = props.ContentLoadSpinnerLayoutOrder:get()
													if layoutOrder == -1 then
														list.CanvasPosition =
															Vector2.new(0, spinnerValue:get().Parent.AbsoluteSize.Y)
													end

													list.CanvasSize = UDim2.fromOffset(
														0,
														list.Content.UIListLayout.AbsoluteContentSize.Y
													)
												end)
											end
										end,

										[Children] = {
											New("ImageLabel")({
												Name = "Spinner",
												Size = UDim2.fromScale(0.8, 0.8),
												Position = UDim2.fromScale(0.5, 0.5),
												AnchorPoint = Vector2.new(0.5, 0.5),
												Image = "rbxassetid://11304130802",
												SizeConstraint = Enum.SizeConstraint.RelativeYY,
												BackgroundTransparency = 1,

												[Ref] = spinnerValue,
											}),
										},
									}),

									New("Frame")({
										Name = "RepliesEmptyState",
										BackgroundTransparency = 1,
										Size = UDim2.fromScale(1, 0.112),

										Visible = Computed(function()
											local parentPost = props.ContentToRender:get()[1]
											local isRepliesView = parentPost
												and type(parentPost) == "table"
												and parentPost.IsParent
											local isRepliesEmpty = isRepliesView and parentPost.Comments == 0
											return isRepliesView and isRepliesEmpty
										end),

										[Children] = {
											New("Frame")({
												Name = "BlankSpace",
												Size = UDim2.fromScale(1, 0.357),
												BackgroundTransparency = 1,
											}),
											New("TextLabel")({
												Name = "NoRepliesYet",
												Size = UDim2.fromScale(1, 0.643),
												AnchorPoint = Vector2.new(0.5, 0),
												Position = UDim2.fromScale(0.5, 0.357),
												BackgroundTransparency = 1,
												Text = "No Replies Yet",
												TextScaled = true,
												TextWrapped = true,
												FontFace = font,
												TextColor3 = Color3.fromRGB(142, 142, 142),
												TextXAlignment = Enum.TextXAlignment.Center,
												TextYAlignment = Enum.TextYAlignment.Top,
											}),
										},
									}),
								},
							}),
						},
					}),

					New("Frame")({
						Name = "Bottom",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 0.085),
						Position = UDim2.fromScale(0.5, 1),
						AnchorPoint = Vector2.new(0.5, 1),

						[Children] = Computed(function()
							local feedType = props.CurrentFeedTypeValue:get()
							if not feedType then
								return {}
							end

							return FeedBottom(props)
						end, Fusion.cleanup),
					}),

					LoadingState(props),

					Computed(function()
						if props.IsVertical:get() == true then
							return
						else
							return New("UIAspectRatioConstraint")({
								AspectRatio = 0.7,
							})
						end
					end, Fusion.cleanup),

					Computed(function()
						if props.EnablePopupMessage:get() == true then
							return PopupNotification(props)
						end
					end, Fusion.cleanup),

					New("UICorner")({
						CornerRadius = Computed(function()
							if props.IsVertical:get() == true then
								return UDim.new(0, 0)
							else
								return UDim.new(0, 16)
							end
						end),
					}),

					New("Frame")({
						Name = "Top",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0),

						Size = Computed(function()
							local feedType = props.FetchingFeedTypeValue:get()
							local isHomeFeed = not not props.isFeedTypeHomeFeed(feedType)

							if not feedType then
								return UDim2.fromScale(1, 0.15)
							end

							local size
							if not feedType or isHomeFeed or not props.Config then
								size = UDim2.fromScale(1, 0.15)
							else
								size = UDim2.fromScale(1, 0.1)
							end

							return size
						end),

						[Children] = {
							FeedTop(props),

							Computed(function()
								local feedType = props.FetchingFeedTypeValue:get()
								if not feedType then
									return {}
								end

								if props.isProfileFeed(feedType) then
									return ProfileTop(props)
								elseif feedType == "replies" then
									return RepliesTop(props)
								elseif feedType == "notifications" then
									return NotificationsTop(props)
								elseif feedType == "explore" then
									return ExploreTop(props)
								else
									return {} --FeedTop(props)
								end
							end, Fusion.cleanup),
						},
					}),
				},
			}),
		},
	})
end
