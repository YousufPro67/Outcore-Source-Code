local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local UserService = game:GetService("UserService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigReader = require(script.Parent.ConfigReader)
local GuiLoader = require(script.GuiLoader)
local Fusion = require(script.Parent.Utils.Fusion)

local IconModule = require(script.Parent.Utils.Icon)
--[[local IconController = require(script.Parent.Utils.Icon.IconController)
IconController.voiceChatEnabled = ConfigReader:read("IsGameVoiceChatEnabled")]]

local Value = Fusion.Value

local GuiWindows = script.Gui.Windows

local Remotes = ReplicatedStorage.BloxbizRemotes

local onRequestDonationItems, onReportPost, onSendPostImpressions, onLikePost, onBoostPost, onDeletePost, onFollowUser, onPostContent, onGetFollowersList, onGetFollowingList, onSearchImages, onSearchDecals, onSearchTermUpdate, onRequestConfig, onRequestContent, onNewNotifications

local onAnalyticsOpen

local PlayerGui, topbarButton

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HasFloatingBannersEnabled = ConfigReader:read("PopfeedProfilePlayerBannersEnabled")

local PopfeedClient = {}

local configLoaded = Instance.new("BindableEvent")
local popfeedLoaded = Instance.new("BindableEvent")

local props = {
	Config = nil,
	PostFrames = {},
	CurrentPage = nil,
	CurrentPosts = nil,
	CurrentFeedType = nil,
	FetchingFeedTypeValue = Value(),
	CurrentFeedTypeValue = Value(),
	CurrentViewingProfileId = Value(),
	CurrentProfileData = Value(),
	ContentToRender = Value({}),
	RenderPosts = Instance.new("BindableEvent"),
	ParentPost = nil,
	BoostingPostBoostValue = nil,

	PostImpressions = {},
	PostsForImpressionCheck = {},

	NotificationCount = Value(0),

	Images = Value({}),
	ImagesPage = 1,
	ImagesLoadedKeyword = "",
	ImageSearchTerms = Value({}),
	ImageScrollingFrame = Value(),
	DecalsNextPageCursor = nil,
	ScreenshotData = Value(),

	FollowersPage = 1,
	FollowingPage = 1,
	FollowingLoadedUserId = 0,
	FollowersLoadedUserId = 0,
	UserListLoaded = Value({}),
	UserListScrollingFrame = Value(),
	UserListVisible = Value(false),

	IsLoading = Value(),
	IsOpened = Value(false),
	IsPosting = Value(false),
	IsOptions = Value(false),
	IsBoosting = Value(false),
	IsVertical = Value(false),
	BoostingPostId = Value(),
	PostingContent = Value(),
	PostingCommentParent = Value(),
	UserSearchFailed = Value(false),

	InteractedWithPostId = nil,

	UIListLayout = Value(),
	ContentFrame = Value(),
	ScrollingFrame = Value(),
	ExploreTabScrollingFrame = Value(),

	LastViewedPost = {},
	LastViewedPage = {},
	LastBottomBtnPress = Value("home"),
	LastLocalPlayerProfileData = Value(),
	ResetLastViewedPost = nil,
	undoTable = {},

	EnablePopupMessage = Value(false),

	ContentFetchDebounce = Value(),
	ContentLoadSpinnerLayoutOrder = Value(1),

	TopbarButton = nil,

	ExplorePageContent = {
		top_donors = Value({}),
		--top_raisers = Value({}),
		top_boosters = Value({}),
	},

	UpdateHomeButtons = Value(false),
	DisableHomeButtons = false,

	ProfileFeeds = {},
	isProfileFeed = nil,
	initialProfileFeed = nil,
	LastLoadedProfileTab = nil,

	cachedUserInfos = {},
	getUserInfoFromUserIds = nil,
	getLocalPlayerProfileData = nil,

	closePopfeed = nil,
}

local postDebounce
local boostDebounce
local currentScreenOrientation

local lastActiveHomeFeed

local donationItemsDebounce
local cachedDonationItems = {}

function props.isFeedTypeHomeFeed(feedType)
	if not props.Config then
		return
	end

	for _, feed in props.Config.feeds.main do
		if feed.id == feedType then
			return true
		end
	end
end

function props.getUserInfoFromUserIds(userIdList)
	local userInfo = {}
	local userIdsNotInCache = {}

	for _, userId in userIdList do
		if props.cachedUserInfos[userId] then
			userInfo[userId] = props.cachedUserInfos[userId]
		else
			table.insert(userIdsNotInCache, userId)
		end
	end

	local success, infoNotInCache = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(userIdsNotInCache)
	end)
	local fetchIsEmpty = #infoNotInCache == 0
	for _, userId in userIdsNotInCache do
		if not success or fetchIsEmpty then
			break
		end

		local infoToCache = { DisplayName = "Unknown", Username = "Unknown" }
		for _, info in infoNotInCache do
			if userId == info.Id then
				infoToCache = info
			end
		end

		props.cachedUserInfos[userId] = infoToCache
		userInfo[userId] = infoToCache
	end

	return userInfo
end

function props.isProfileFeed(feedId)
	for _, feedData in props.ProfileFeeds do
		if feedId == feedData.id then
			return true
		end
	end
end

function props.getLocalPlayerProfileData()
	props.IsLoading:set(true)

	local requestData = {
		FeedType = "player",
		NewPageNum = 0,
		ProfileId = LocalPlayer.UserId,
	}

	local content, extraData = onRequestContent:InvokeServer(requestData)
	props.LastLocalPlayerProfileData:set(extraData.ProfileData)

	props.IsLoading:set(false)

	return content, extraData
end

--[[
    local requestData = {
        RequestId,
        FeedType,
        NewPageNum,
        OldPageNum,
        PostId,
        ProfileId,
        IsScrolling,
    }
]]

local fetchingRequestData = {}

local function isFetchingThisRequest(requestData)
	if not props.ContentFetchDebounce:get() then
		return false
	end

	if requestData.IsScrolling and fetchingRequestData.IsScrolling then
		return requestData.FeedType == fetchingRequestData.FeedType
	end
end

local function showLoadingState(requestData)
	props.IsLoading:set(requestData.IsScrolling ~= true)
end

local function isLatestRequest(fetchedRequestData)
	return fetchingRequestData.RequestId == fetchedRequestData.RequestId
end

local function requestContent(requestData)
	if requestData.NewPageNum < 1 then
		return
	end
	-- check if already fetching this request
	if isFetchingThisRequest(requestData) then
		return
	end

	showLoadingState(requestData)

	requestData.RequestId = HttpService:GenerateGUID(false)

	fetchingRequestData = requestData
	props.ContentFetchDebounce:set(true)
	props.FetchingFeedTypeValue:set(requestData.FeedType)
	--props.ContentLoadSpinnerLayoutOrder:set(requestData.NewPageNum > (props.CurrentPage or 1) and 1 or -1)

	local content, extraData = onRequestContent:InvokeServer(requestData)
	local fetchedRequestData = extraData.RequestData

	if not isLatestRequest(fetchedRequestData) then
		-- drop the results if it's not the most recent request
		return
	end

	return content, extraData
end

local function renderLeaderboard(content, pageNumber, leaderboardType)
	local explorePageContent = props.ExplorePageContent

	local oldContent = pageNumber > 1 and explorePageContent[leaderboardType]:get() or {}

	local userIdsToRequestForInfo = {}

	for _, entry in content[leaderboardType] do
		table.insert(oldContent, entry)
		table.insert(userIdsToRequestForInfo, entry.player_id)
	end

	props.getUserInfoFromUserIds(userIdsToRequestForInfo)

	explorePageContent[leaderboardType]:set(oldContent)
end

local function renderExplorePage(leaderboardsPageNumber, leaderboardType)
	local requestData = {
		FeedType = "explore",
		LeaderboardType = leaderboardType,
		NewPageNum = leaderboardsPageNumber,
		EntriesPerPage = 3,
	}

	local content = requestContent(requestData)
	if not content then
		props.IsLoading:set(false)
		return
	end

	if leaderboardType then
		renderLeaderboard(content, leaderboardsPageNumber, leaderboardType)
	else
		for thisLeaderboardType in content do
			renderLeaderboard(content, leaderboardsPageNumber, thisLeaderboardType)
		end
	end

	props.CurrentPage = nil
	props.CurrentPosts = nil
	props.CurrentFeedType = "explore"
	props.CurrentFeedTypeValue:set("explore")
	props.ContentToRender:set({})
	props.PostsForImpressionCheck = {}

	task.defer(function()
		local list = props.ExploreTabScrollingFrame:get()
		if not list then
			return
		end

		local contentFrame = list:FindFirstChild("Content")
		if not contentFrame then
			return
		end

		list.CanvasSize = UDim2.new(0, 0, 0, contentFrame.UIListLayout.AbsoluteContentSize.Y)
	end)

	props.IsLoading:set(false)

	return true
end

local function requestDonationItems(userId)
	if donationItemsDebounce then
		return "Loading"
	end
	donationItemsDebounce = true

	if not cachedDonationItems[userId] then
		cachedDonationItems[userId] = onRequestDonationItems:InvokeServer(userId)
	end

	donationItemsDebounce = nil

	return cachedDonationItems[userId]
end

local function renderDonationItems()
	props.IsLoading:set(true)

	local targetId = props.CurrentViewingProfileId:get()

	props.CurrentPage = 1
	props.CurrentPosts = {}
	props.CurrentFeedType = "donations"

	local items = requestDonationItems(targetId)

	props.RenderPosts:Fire(items)
end

local function renderPosts(pageNum, feedType, isScrolling, changeData, fetchProfileData)
	if feedType == "shop" and isScrolling then
		return
	end

	if feedType == "donations" then
		if not isScrolling then
			renderDonationItems()
		end

		return
	end

	if feedType == "explore" then
		renderExplorePage(1)
		return
	end

	local targetId = props.CurrentViewingProfileId:get()
	local profileId = fetchProfileData == true and targetId or nil
	local postId = profileId and nil or targetId

	local contentData, extraData = requestContent({
		FeedType = feedType,
		NewPageNum = pageNum,
		OldPageNum = props.CurrentPage,
		PostId = postId,
		ProfileId = profileId,
		IsScrolling = isScrolling,
	})

	if contentData then
		if feedType == "notifications" then
			props.NotificationCount:set(0)
			if topbarButton then
				topbarButton:clearNotices()
			end
		end

		if feedType ~= "replies" then
			props.PostingCommentParent:set(nil)
		end

		local fetchHasProfileData = extraData.ProfileData ~= nil
		if fetchHasProfileData then
			local newProfile = extraData.ProfileData
			local oldProfile = props.CurrentProfileData:get()

			props.CurrentProfileData:set(extraData.ProfileData)

			if targetId == LocalPlayer.UserId then
				props.LastLocalPlayerProfileData:set(newProfile)
			end

			local lastLoadedTab = props.LastLoadedProfileTab
			local firstTabId = string.match(props.Config.profile_tab_order[1], ":[%s]*(.-)[%s]*$")

			local isSameProfile = oldProfile and oldProfile.user_id == newProfile.user_id
			local hasPreviousLoadedTab = lastLoadedTab and lastLoadedTab ~= firstTabId

			if isSameProfile and hasPreviousLoadedTab then
				props.ContentFetchDebounce:set(nil)

				props.OnSwitchFeedClicked(lastLoadedTab, profileId)
				return
			end

			--[[local donationsEmpty = #newProfile.donations == 0
			local donationsTabIsFirst = props.Config.profile_tab_order[1] == "page:donations"
				and feedType == "donations"

			if donationsTabIsFirst and donationsEmpty then
				props.ContentFetchDebounce:set(nil)

				local nextFeedId = string.match(props.Config.profile_tab_order[2], ":[%s]*(.-)[%s]*$")
				props.OnSwitchFeedClicked(nextFeedId, profileId)
				return
			end]]

			props.LastLoadedProfileTab = feedType
		end

		props.CurrentPage = pageNum
		props.CurrentPosts = contentData
		props.CurrentFeedType = feedType

		props.RenderPosts:Fire(extraData, changeData)
	elseif extraData then
		props.ContentFetchDebounce:set(nil)
	end
end

local function onCanvasPositionChanged(scrollingFrame, newPosition)
	local y = math.floor(newPosition.Y)
	local maxCanvasY = math.floor(scrollingFrame.CanvasSize.Y.Offset - scrollingFrame.AbsoluteWindowSize.Y)

	local page = props.CurrentPage
	local feedType = props.CurrentFeedType

	if not page then
		return
	end

	if maxCanvasY <= y then
		renderPosts(page + 1, feedType, true)
	elseif 0 == y then
		renderPosts(page - 1, feedType, true)
	end
end

local function setScreenOrientation(isOpened)
	if isOpened == true then
		PlayerGui.ScreenOrientation = currentScreenOrientation
	else
		currentScreenOrientation = PlayerGui.ScreenOrientation
		PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
	end
end

local function loadProfileFeedsConfig()
	local feeds = {}

	for _, feedData in props.Config.feeds.profile do
		table.insert(feeds, feedData)
	end
	table.insert(feeds, {
		id = "shop",
		name = "Shop",
	})
	table.insert(feeds, {
		id = "donations",
		name = "Donate",
	})

	props.ProfileFeeds = feeds
	props.initialProfileFeed = string.match(props.Config.profile_tab_order[1], ":[%s]*(.-)[%s]*$")
end

local activeIcons = {}

local function toggleTopBarButtons(toggle)
	if toggle == true then
		local icons = IconModule.getIcons()
		activeIcons = {}

		for _, icon in icons do
			if icon.name == "Popfeed" then
				continue
			end

			if icon.enabled ~= true then
				continue
			end

			icon:setEnabled(false)
			table.insert(activeIcons, icon)
		end
	else
		for _, icon in activeIcons do
			icon:setEnabled(true)
		end
	end
end

local function togglePopfeedVisibility(toggle, noPostsRender)
	if popfeedLoaded then
		popfeedLoaded.Event:Wait()
	end

	local isOpened = props.IsOpened
	local isLoading = props.IsLoading

	if toggle == nil then
		setScreenOrientation(isOpened:get())
		isOpened:set(not isOpened:get())
	else
		setScreenOrientation(not toggle)
		isOpened:set(toggle)
	end

	isLoading:set(false)

	if topbarButton then
		topbarButton:clearNotices()
	end

	toggleTopBarButtons(isOpened:get())

	if isOpened:get() == true then
		if not props.Config then
			configLoaded.Event:Wait()
		end

		loadProfileFeedsConfig()

		local defaultFeedId = props.Config.feeds.main[1].id
		local feedToRenderId = lastActiveHomeFeed or defaultFeedId

		props.LastBottomBtnPress:set("home")
		props.IsPosting:set(false)
		topbarButton:select()

		StarterGui:SetCore("ChatActive", false)

		if not noPostsRender then
			renderPosts(1, feedToRenderId)
		end
	else
		for _ = 1, props.NotificationCount:get() do
			if topbarButton then
				topbarButton:notify()
			end
		end

		props.ChangeOutfit:FireServer()
		props.IsOptions:set(false)
	end

	onAnalyticsOpen:FireServer(isOpened:get())
end

function PopfeedClient.OpenPopfeed()
	local isOpened = props.IsOpened
	if isOpened:get() == true then
		return
	end

	togglePopfeedVisibility(true)
end

function PopfeedClient.ClosePopfeed()
	local isOpened = props.IsOpened
	if not isOpened:get() then
		return
	end

	togglePopfeedVisibility(false)
end

function PopfeedClient.TogglePopfeed()
	togglePopfeedVisibility()
end

local function openInviteFriendsMenu()
	game:GetService("SocialService"):PromptGameInvite(LocalPlayer)
end

local function setupTopbarButton()
	local theme = require(script.Parent.Utils.Icon.Themes.RedNotification)

	topbarButton = IconModule.new()
	topbarButton:setName("Popfeed")
	topbarButton:setImage(16743008992, "Deselected")
	topbarButton:setImage("", "Selected")
	topbarButton:setImageScale(0.85)
	topbarButton:setWidth(90)
	topbarButton:setImageRatio(4.87)
	topbarButton:align("Left")
	topbarButton:bindEvent("selected", PopfeedClient.OpenPopfeed)
	topbarButton:bindEvent("deselected", PopfeedClient.ClosePopfeed)
	topbarButton:modifyTheme(theme)

	props.TopbarButton = topbarButton

	if game.GameId == 4527425367 then
		local inviteFriendsButton = IconModule.new()
		inviteFriendsButton:setName("InviteFriends")
		inviteFriendsButton:setLabel("Invite Friends")
		inviteFriendsButton:setLeft()
		inviteFriendsButton:bindEvent("selected", openInviteFriendsMenu)
	end
end

local function onPostButtonClicked(imageIds, donationsEnabled)
	local content = props.PostingContent:get()
	if not content then
		return
	end

	if postDebounce then
		return
	end
	postDebounce = true

	if #content == 0 and #imageIds == 0 then
		return
	end

	local donationList
	if donationsEnabled then
		donationList = requestDonationItems(LocalPlayer.UserId)
		if donationList then
			donationList = donationList.donations
		end
	end

	local screenshotData = props.ScreenshotData:get()
	local size = #HttpService:JSONEncode(screenshotData) / 1000

	print("Size:", string.format("%.2f", size) .. " KB")

	local parentPostId = props.PostingCommentParent:get()
	local success = onPostContent:InvokeServer(content, imageIds, parentPostId, donationList, screenshotData)
	if success then
		if props.CurrentPage == 1 then
			renderPosts(1, props.CurrentFeedType)
		end
	end

	props.IsPosting:set(false)
	props.PostingContent:set(nil)

	postDebounce = nil
end

local function onCommentButtonClicked()
	props.IsPosting:set(true)
end

local function onLikeButtonClicked(postId, vote)
	onLikePost:FireServer(postId, vote)
end

local function onFollowButtonClicked(targetId, follow)
	onFollowUser:FireServer(targetId, follow)
end

local function calculateCanvasOffset()
	local postFrames = props.PostFrames
	local contentFrame = props.ContentFrame
	local uIListLayout = props.UIListLayout
	local scrollingFrame = props.ScrollingFrame

	if #postFrames == 0 then
		return
	end

	if not contentFrame:get() then
		return
	end

	local lastViewedPost = {}

	if props.ResetLastViewedPost == true then
		lastViewedPost = nil
		props.ResetLastViewedPost = nil
		return
	end

	local paddingSize = contentFrame:get().AbsoluteSize.Y * uIListLayout:get().Padding.Scale
	local canvasPosition = scrollingFrame:get().CanvasPosition.Y
	local positionSum = 0

	for _, postFrame in postFrames do
		local frameSize = postFrame.AbsoluteSize.Y + paddingSize
		positionSum += frameSize

		if positionSum >= canvasPosition then
			lastViewedPost = {
				Id = postFrame.Name,
				Position = postFrame.AbsolutePosition.Y,
			}
			break
		end
	end

	return lastViewedPost
end

local function onBackButtonClicked()
	local recentChange = props.undoTable[#props.undoTable]
	if not recentChange then
		return
	end

	props.CurrentViewingProfileId:set(recentChange.ProfileId)
	props.LastBottomBtnPress:set(recentChange.ActiveBottomBtn)

	if type(props.CurrentViewingProfileId:get()) == "string" then
		props.PostingCommentParent:set(props.CurrentViewingProfileId:get())
	end

	props.undoTable[#props.undoTable] = nil

	local fetchProfile = props.isProfileFeed(recentChange.FeedType)
	renderPosts(recentChange.PageNum, recentChange.FeedType, false, recentChange, fetchProfile)
end

local function onSwitchFeedClicked(nextFeedType, nextTargetId, exitedThroughBottomButton)
	props.UserSearchFailed:set(false)

	local currentTargetId = props.CurrentViewingProfileId:get()
	props.UserListVisible:set(false)

	if nextFeedType == "home" then
		local defaultFeed = props.Config.feeds.main[1]

		nextFeedType = lastActiveHomeFeed or defaultFeed.id
	end

	local storePageIntoHistory = not props.isProfileFeed(nextFeedType) or nextTargetId ~= currentTargetId
	local clearHistory = exitedThroughBottomButton
	if clearHistory then
		props.undoTable = {}
	elseif storePageIntoHistory then
		if props.CurrentFeedType then
			local lastViewedPost = calculateCanvasOffset()

			local data = {
				PageNum = props.CurrentPage,
				FeedType = props.CurrentFeedType,
				LastViewedPost = lastViewedPost,
				ProfileId = props.CurrentViewingProfileId:get(),
				ActiveBottomBtn = props.LastBottomBtnPress:get(),
			}

			table.insert(props.undoTable, data)
		end
	end

	props.CurrentViewingProfileId:set(nextTargetId)
	if props.CurrentFeedType then
		props.LastViewedPage[props.CurrentFeedType] = props.CurrentPage
	end

	local page = 1
	if nextFeedType == props.CurrentFeedType then
		page = 1
		props.ResetLastViewedPost = true
	else
		page = props.LastViewedPage[nextFeedType] or 1
	end

	if props.isFeedTypeHomeFeed(nextFeedType) then
		lastActiveHomeFeed = nextFeedType
	end

	local fetchProfileData = nextTargetId and nextTargetId ~= currentTargetId
	fetchProfileData = props.isProfileFeed(nextFeedType) and fetchProfileData
	renderPosts(page, nextFeedType, false, nil, fetchProfileData)
end

local function onDeletePostButtonClicked(postId)
	if not postId then
		return
	end

	if postDebounce then
		return
	end
	postDebounce = true

	local success = onDeletePost:InvokeServer(postId)
	if success then
		onBackButtonClicked()
	end

	props.IsOptions:set(false)

	postDebounce = nil
end

local function onReportPostButtonClicked(postId)
	if not postId then
		return
	end

	if postDebounce then
		return
	end
	postDebounce = true


	onReportPost:FireServer(postId)

	props.IsOptions:set(false)

	postDebounce = nil
end

local function onBoostButtonClicked()
	if boostDebounce then
		return
	end
	boostDebounce = true

	local postId = props.BoostingPostId:get()
	if not postId then
		return
	end

	onBoostPost:FireServer(postId, "copper")
end

local function getUserProfilePicture(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150&filters=circular"
end

local function searchFromAssetId(keyword)
	local assetId = keyword:match("%d+")
	if not assetId then
		return
	end

	return { { AssetId = assetId } }
end

local currentSearchParams = {}

local function onImagesButtonClicked(keyword, page, notShowLoadState)
	if not notShowLoadState then
		props.IsLoading:set(true)
	end

	local searchParams
	local response = searchFromAssetId(keyword)
	if not response then
		currentSearchParams.Page = page
		currentSearchParams.Keyword = keyword

		response, searchParams = onSearchImages:InvokeServer(keyword, page)
	end

	if response then
		if searchParams and searchParams.Keyword ~= currentSearchParams.Keyword then
			return
		end

		if #response == 0 then
			if page == 1 then
				props.Images:set({})
			end

			props.IsLoading:set(false)
			return true
		end

		local currentPage = props.ImagesPage
		local currentKeyword = props.ImagesLoadedKeyword

		props.ImagesPage = page
		props.ImagesLoadedKeyword = keyword

		local newImages
		if currentKeyword == keyword and currentPage ~= page then
			newImages = props.Images:get()
			for _, image in response do
				table.insert(newImages, image)
			end
		else
			newImages = response
		end
		props.Images:set(newImages)

		local list = props.ImageScrollingFrame:get()
		if list then
			if page == 1 then
				list.CanvasPosition = Vector2.zero
			end

			task.defer(function()
				list.CanvasSize = UDim2.fromOffset(0, list.Container.UIGridLayout.AbsoluteContentSize.Y)
			end)
		end
	end

	props.IsLoading:set(false)
end

local currentDecalSearchParams = {}

local function onDecalsButtonClicked(nextPageCursor, notShowLoadState)
	nextPageCursor = nextPageCursor or "first_page"

	if not notShowLoadState then
		props.IsLoading:set(true)
	end

	currentDecalSearchParams.nextPageCursor = nextPageCursor

	local response, currentNextPageCursor = onSearchDecals:InvokeServer(nextPageCursor)
	if response then
		if currentNextPageCursor ~= currentDecalSearchParams.nextPageCursor then
			return
		end

		local images = response.data
		if #images == 0 then
			if not nextPageCursor then
				props.Images:set({})
			end

			props.IsLoading:set(false)
			return true
		end

		currentNextPageCursor = props.DecalsNextPageCursor
		props.DecalsNextPageCursor = response.nextPageCursor

		local newImages = props.Images:get()
		for _, image in images do
			table.insert(newImages, image)
		end

		props.Images:set(newImages)

		local list = props.ImageScrollingFrame:get()
		if list then
			if nextPageCursor == "first_page" then
				list.CanvasPosition = Vector2.zero
			end

			task.defer(function()
				list.CanvasSize = UDim2.fromOffset(0, list.Container.UIGridLayout.AbsoluteContentSize.Y)
			end)
		end
	end

	props.IsLoading:set(false)
end

local currentGetFollowersParams = {}

local function onFollowersButtonClicked(userId, page, notShowLoadState)
	if not notShowLoadState then
		props.IsLoading:set(true)
	end

	currentGetFollowersParams.Page = page
	currentGetFollowersParams.UserId = userId

	local response, params = onGetFollowersList:InvokeServer(userId, page)
	if response then
		if params and params.UserId ~= currentGetFollowersParams.UserId then
			return
		end

		if #response == 0 then
			if page == 1 then
				props.UserListLoaded:set({})
			end

			props.IsLoading:set(false)
			return true
		end

		local currentPage = props.FollowersPage
		local currentUserId = props.FollowersLoadedUserId

		props.FollowersPage = page
		props.FollowersLoadedUserId = userId

		local newUsers
		local toLoadUserIds = {}

		if page == 1 then
			props.UserListLoaded:set({})
		end

		if currentUserId == userId and currentPage ~= page then
			newUsers = props.UserListLoaded:get()
			for _, user in response do
				table.insert(newUsers, user)
			end
		else
			newUsers = response
		end

		for _, user in response do
			table.insert(toLoadUserIds, user.follower or user.following)
		end

		props.getUserInfoFromUserIds(toLoadUserIds)
		props.UserListLoaded:set(newUsers)

		local list = props.UserListScrollingFrame:get()
		if list then
			if page == 1 then
				list.CanvasPosition = Vector2.zero
			end

			task.defer(function()
				list.CanvasSize = UDim2.fromOffset(0, list.Container.UIListLayout.AbsoluteContentSize.Y)
			end)
		end
	end

	props.IsLoading:set(false)
end

local currentGetFollowingParams = {}

local function onFollowingButtonClicked(userId, page, notShowLoadState)
	if not notShowLoadState then
		props.IsLoading:set(true)
	end

	currentGetFollowingParams.Page = page
	currentGetFollowingParams.UserId = userId

	local response, params = onGetFollowingList:InvokeServer(userId, page)
	if response then
		if params and params.UserId ~= currentGetFollowingParams.UserId then
			return
		end

		if #response == 0 then
			if page == 1 then
				props.UserListLoaded:set({})
			end

			props.IsLoading:set(false)
			return true
		end

		local currentPage = props.FollowingPage
		local currentUserId = props.FollowingLoadedUserId

		props.FollowingPage = page
		props.FollowingLoadedUserId = userId

		local newUsers
		local toLoadUserIds = {}

		if page == 1 then
			props.UserListLoaded:set({})
		end

		if currentUserId == userId and currentPage ~= page then
			newUsers = props.UserListLoaded:get()
			for _, user in response do
				table.insert(newUsers, user)
			end
		else
			newUsers = response
		end

		for _, user in response do
			table.insert(toLoadUserIds, user.follower or user.following)
		end

		props.getUserInfoFromUserIds(toLoadUserIds)
		props.UserListLoaded:set(newUsers)

		local list = props.UserListScrollingFrame:get()
		if list then
			if page == 1 then
				list.CanvasPosition = Vector2.zero
			end

			task.defer(function()
				list.CanvasSize = UDim2.fromOffset(0, list.Container.UIListLayout.AbsoluteContentSize.Y)
			end)
		end
	end

	props.IsLoading:set(false)
end

local function loadProfileFromFloatingBanner(player)
	if props.IsOpened:get() == true then
		return
	end

	props.DisableHomeButtons = true
	props.UpdateHomeButtons:set(not props.UpdateHomeButtons:get()) -- just to trigger computed update

	props.CurrentViewingProfileId:set(nil)

	props.TopbarButton:select()
	onSwitchFeedClicked(props.initialProfileFeed, player.UserId)
end

local function renderCameraView()
	return require(GuiWindows.CameraView)(props)
end

local cameraGui

local function toggleCamera(toggle)
	if toggle then
		toggleCamera(false)

		cameraGui = GuiLoader.Load(renderCameraView, PlayerGui, props)
	else
		if cameraGui then
			cameraGui:Destroy()
		end
	end
end

local function serializeCharacter(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

    local description = humanoid:GetAppliedDescription()

    local serialized = {}

    local partCframes = {}

    for _, part in character:GetChildren() do
        if part:IsA("BasePart") then
            partCframes[part.Name] = {part.CFrame:GetComponents()}
        end
    end

    serialized.Cframe = {character:GetPivot():GetComponents()}
    serialized.RigType = humanoid.RigType.Name
    serialized.PartCframes = partCframes

    serialized.Properties = {
        Shirt = description.Shirt,
        Pants = description.Pants,
        Face = description.Face,
        Torso = description.Torso,
        RightLeg = description.RightLeg,
        LeftLeg = description.LeftLeg,
        LeftArm = description.LeftArm,
        RightArm = description.RightArm,
        Head = description.Head,
        GraphicTShirt = description.GraphicTShirt,
        BodyTypeScale = description.BodyTypeScale,
        DepthScale = description.DepthScale,
        HeadScale = description.HeadScale,
        HeightScale = description.HeightScale,
        ProportionScale = description.ProportionScale,
        WidthScale = description.WidthScale,
        BackAccessory = description.BackAccessory,
        FaceAccessory = description.FaceAccessory,
        FrontAccessory = description.FrontAccessory,
        HairAccessory = description.HairAccessory,
        HatAccessory = description.HatAccessory,
        NeckAccessory = description.NeckAccessory,
        ShouldersAccessory = description.ShouldersAccessory,
        WaistAccessory = description.WaistAccessory,

        ClimbAnimation = description.ClimbAnimation,
        FallAnimation = description.FallAnimation,
        IdleAnimation = description.IdleAnimation,
        JumpAnimation = description.JumpAnimation,
        MoodAnimation = description.MoodAnimation,
        RunAnimation = description.RunAnimation,
        SwimAnimation = description.SwimAnimation,
        WalkAnimation = description.WalkAnimation,
    }

    serialized.Colors = {
        HeadColor = {description.HeadColor.R,description.HeadColor.G,description.HeadColor.B},
        LeftArmColor = {description.LeftArmColor.R,description.LeftArmColor.G,description.LeftArmColor.B},
        RightArmColor = {description.RightArmColor.R,description.RightArmColor.G,description.RightArmColor.B},
        LeftLegColor = {description.LeftLegColor.R,description.LeftLegColor.G,description.LeftLegColor.B},
        RightLegColor = {description.RightLegColor.R,description.RightLegColor.G,description.RightLegColor.B},
        TorsoColor = {description.TorsoColor.R,description.TorsoColor.G,description.TorsoColor.B},
    }

    return serialized
end

local function getSerializedCharacters(humanoids)
    local characters = {}

    for humanoid in humanoids do
        local serialized = serializeCharacter(humanoid.Parent)
		if serialized then
        	table.insert(characters, serialized)
		end
    end

    return characters
end

local function deserializeCharacter(serializedCharacter)
    local description = Instance.new("HumanoidDescription")

    for key, value in serializedCharacter.Properties do
        if value ~= 0 then
            description[key] = value
        end
    end

    for part, color in serializedCharacter.Colors do
        description[part] = Color3.new(color[1], color[2], color[3])
    end

    local rigType = serializedCharacter.RigType
    local partCframes = serializedCharacter.PartCframes
    local characterCframe = CFrame.new(table.unpack(serializedCharacter.Cframe))

    local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType[rigType])

    local animateScript = model:FindFirstChild("Animate", true)
    if animateScript then
        animateScript:Destroy()
    end

    local animator = model:FindFirstChildWhichIsA("Animator", true)
    if animator then
        animator:Destroy()
    end

    local faceControls = model:FindFirstChildWhichIsA("FaceControls", true)
    if faceControls then
        faceControls:Destroy()
    end

    model:PivotTo(characterCframe)

    for partName, partCframe in partCframes do
        local part = model:FindFirstChild(partName)
        if part then
            local motor = part:FindFirstChildOfClass("Motor6D")
            if motor then
                motor:Destroy()
            end

            part.Anchored = true
            part.CFrame = CFrame.new(table.unpack(partCframe))
        end
    end

    return model
end

local function getDeserializedCharacters(serializedCharacters)
    local folder = Instance.new("Folder")

    for _, serializedCharacter in serializedCharacters do
        local model = deserializeCharacter(serializedCharacter)
        model.Parent = folder
    end

    return folder
end

local function onScreenshotTaken(screenshotData)
	props.ScreenshotData:set(screenshotData)
end

local function renderFeed()
	return require(GuiWindows.Feed)(props)
end

function PopfeedClient.init()
	PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	onLikePost = Remotes:WaitForChild("PopfeedOnLikePost")
	onBoostPost = Remotes:WaitForChild("PopfeedOnBoostPost")
	onReportPost = Remotes:WaitForChild("PopfeedOnReportPost")
	onDeletePost = Remotes:WaitForChild("PopfeedOnDeletePost")
	onFollowUser = Remotes:WaitForChild("PopfeedOnFollowUser")
	onPostContent = Remotes:WaitForChild("PopfeedOnPostContent")
	onSearchDecals = Remotes:WaitForChild("PopfeedOnSearchDecals")
	onSearchImages = Remotes:WaitForChild("PopfeedOnSearchImages")
	onRequestConfig = Remotes:WaitForChild("PopfeedOnRequestConfig")
	onRequestContent = Remotes:WaitForChild("PopfeedOnRequestContent")
	onNewNotifications = Remotes:WaitForChild("PopfeedOnNewNotifications")
	onSearchTermUpdate = Remotes:WaitForChild("PopfeedOnSearchTermUpdate")
	onGetFollowersList = Remotes:WaitForChild("PopfeedOnGetFollowersList")
	onGetFollowingList = Remotes:WaitForChild("PopfeedOnGetFollowingList")
	onSendPostImpressions = Remotes:WaitForChild("PopfeedOnSendPostImpressions")
	onRequestDonationItems = Remotes:WaitForChild("PopfeedOnRequestDonationItems")

	onAnalyticsOpen = Remotes:WaitForChild("PopfeedAnalyticsOpen")

	props.ChangeOutfit = Remotes:WaitForChild("PopfeedChangeOutfit")
	props.ToggleCamera = toggleCamera
	props.OnScreenshotTaken = onScreenshotTaken
	props.OnSwitchFeedClicked = onSwitchFeedClicked
	props.OnLikeButtonClicked = onLikeButtonClicked
	props.OnPostButtonClicked = onPostButtonClicked
	props.OnBackButtonClicked = onBackButtonClicked
	props.RequestDonationItems = requestDonationItems
	props.OnBoostButtonClicked = onBoostButtonClicked
	props.GetUserProfilePicture = getUserProfilePicture
	props.OnFollowButtonClicked = onFollowButtonClicked
	props.OnImagesButtonClicked = onImagesButtonClicked
	props.OnDecalsButtonClicked = onDecalsButtonClicked
	props.OnCommentButtonClicked = onCommentButtonClicked
	props.TogglePopfeedVisibility = togglePopfeedVisibility
	props.OnFollowersButtonClicked = onFollowersButtonClicked
	props.OnFollowingButtonClicked = onFollowingButtonClicked
	props.OnDeletePostButtonClicked = onDeletePostButtonClicked
	props.OnReportPostButtonClicked = onReportPostButtonClicked
	props.LoadProfileFromFloatingBanner = loadProfileFromFloatingBanner

	props.GetSerializedCharacters = getSerializedCharacters
	props.GetDeserializedCharacters = getDeserializedCharacters

	props.RenderExplorePage = renderExplorePage
	props.closePopfeed = PopfeedClient.ClosePopfeed
	props.CalculateCanvasOffset = calculateCanvasOffset
	props.OnCanvasPositionChanged = onCanvasPositionChanged

	props.Config = onRequestConfig:InvokeServer()

	configLoaded:Fire()
	configLoaded:Destroy()
	configLoaded = nil

	if ConfigReader:read("PopfeedShowToolbarButton") then
		setupTopbarButton()
	end

	onNewNotifications.OnClientEvent:Connect(function(count)
		props.NotificationCount:set(count)

		if topbarButton then
			topbarButton:clearNotices()
			for _ = 1, count do
				topbarButton:notify()
			end
		end
	end)

	onBoostPost.OnClientEvent:Connect(function(success)
		if success then
			local boostValue = props.BoostingPostBoostValue
			if boostValue then
				boostValue:set(boostValue:get() + 1)
			end
		end

		props.IsBoosting:set(false)
		boostDebounce = nil
	end)

	onSearchTermUpdate.OnClientEvent:Connect(function(searchTerms)
		if type(searchTerms) ~= "table" then
			searchTerms = {}
		end

		props.ImageSearchTerms:set(searchTerms)
	end)

	onSearchTermUpdate:FireServer()

	local function setVertical()
		if Camera.ViewportSize.X < Camera.ViewportSize.Y then
			props.IsVertical:set(true)
		else
			props.IsVertical:set(false)
		end
	end

	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(setVertical)
	setVertical()

	if HasFloatingBannersEnabled then
		local function onCharacterAdded(character, player)
			local root = character:WaitForChild("HumanoidRootPart")

			local bannerProps = {
				Player = player,
				RootPart = root,
				FeedProps = props,
			}

			local humanoid = character:WaitForChild("Humanoid")
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "OpenProfile"
			prompt.ObjectText = "Popfeed"
			prompt.ActionText = "Open Profile"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 5
			prompt.RequiresLineOfSight = false

			prompt.Triggered:Connect(function()
				loadProfileFromFloatingBanner(player)
			end)

			prompt.Parent = root

			local billboard = GuiLoader.Load(function()
				return require(GuiWindows.FloatingProfile)(bannerProps)
			end, PlayerGui, bannerProps)

			character.Destroying:Connect(function()
				billboard:Destroy()
			end)
		end

		local function onPlayerAdded(player)
			if player == LocalPlayer then
				return
			end

			player.CharacterRemoving:Connect(function(character)
				character:Destroy()
			end)

			player.CharacterAdded:Connect(function(character)
				onCharacterAdded(character, player)
			end)

			if player.Character then
				onCharacterAdded(player.Character, player)
			end
		end

		Players.PlayerAdded:Connect(onPlayerAdded)

		for _, player in Players:GetPlayers() do
			onPlayerAdded(player)
		end
	end

	task.spawn(function()
		while task.wait(60) do
			local posts = props.PostImpressions
			if #posts == 0 then
				continue
			end

			onSendPostImpressions:FireServer(posts)

			props.PostImpressions = {}
		end
	end)
	task.defer(function()
		popfeedLoaded:Fire()
		popfeedLoaded:Destroy()
		popfeedLoaded = nil
	end)

	GuiLoader.Load(renderFeed, PlayerGui, props)
end

return PopfeedClient
