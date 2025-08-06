local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local BatchHTTP = require(script.Parent.BatchHTTP)
local AdRequestStats = require(script.Parent.AdRequestStats)
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge

local IsStudio = RunService:IsStudio()

local PopfeedServer = {}
PopfeedServer.Donations = require(script.Donations)

local onRequestDonationItems, onReportPost, onChangeOutfit, onSendPostImpressions, onLikePost, onBoostPost, onDeletePost, onFollowUser, onPostContent, onGetFollowersList, onGetFollowingList, onSearchImages, onSearchDecals, onSearchTermUpdate, onRequestConfig, onRequestContent, onNewNotifications

local onAnalyticsOpen, onAnalyticsViewedPost
local analyticsOpenTimestamps = {}

local cachedFeed = {}
local cachedImages = {}
local cachedDecals = {}
local cachedImageTerms = {}
local cachedFollowers = {}
local cachedFollowings = {}

local cachedLeaderboards = {
	Pages = {
		top_donors = {},
		--top_raisers = {},
		top_boosters = {},
	},
	LastFetchedPage = 0,
}

local onlineUserIds = {}
local currentBoostingPost = {}
local promptedBoostPasses = {}
local batchedPostImpressions = {}

local cachedConfig
local onConfigLoaded = Instance.new("BindableEvent")

local LOCALHOST = "http://127.0.0.1:8081/popfeed/"
local USE_LOCALHOST = false

local PAGE_SIZE = nil
local PAGE_SORT = nil

local NOTIFICATIONS_UPDATE_INTERVAL = 60
local IMAGE_TERMS_UPDATE_INTERVAL = 60 * 2
local IMAGE_CACHE_CLEAR_INTERVAL = 60 * 60 * 24
local LEADERBOARD_CACHE_CLEAR_INTERVAL = 60 * 5
local POST_IMPRESSIONS_SEND_INTERVAL = 60 * 2

local function checkForDuplicatePosts(player, feedType, postId, pageNumber)
	local posts = cachedFeed[player][feedType]
	for pageNum, page in posts do
		if pageNumber == pageNum then
			continue
		end

		for _, post in page do
			if post.Id == postId then
				return true
			end
		end
	end
end

local function formatData(postData, playerWhoFetched, feedType, pageNumber)
	if checkForDuplicatePosts(playerWhoFetched, feedType, postData.post_id, pageNumber) then
		return
	end

	local formattedData = {
		Profile = {
			UserId = postData.player_id,
			Name = "Unknown",
			DisplayName = "Unknown",
		},
		Id = postData.post_id,
		Likes = postData.up_votes or 0,
		Boosts = postData.boosts_applied,
		OwnLike = postData.own_vote or 0,
		Comments = postData.reply_count or 0,
		Content = postData.text,
		PlaceId = postData.place_id,
		ParentId = postData.parent_id,
		Timestamp = DateTime.fromIsoDate(postData.timestamp).UnixTimestampMillis / 1000,
		Images = {},
		Donations = {},
		Screenshots = {},
	}

	for _, attachment in postData.attachments do
		if attachment.type == "donation" then
			local targetId = postData.player_id
			PopfeedServer.Donations.cacheDonations(playerWhoFetched, targetId, { attachment })

			table.insert(formattedData.Donations, attachment)
		elseif attachment.type == "image" then
			table.insert(formattedData.Images, attachment)
		elseif attachment.type == "screenshot" then
			table.insert(formattedData.Screenshots, attachment)
		end
	end

	return formattedData
end

local function processBoostPost(player, postId, gamePassId)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "/post/" .. postId .. "/boost"
	else
		url = BatchHTTP.getNewUrl("popfeed/post/" .. postId .. "/boost")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		player_id = player.UserId,
		gamepass_id = gamePassId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	promptedBoostPasses[player] = nil

	if not success then
		warn("Boosting a post failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchBoostPasses(player, tier)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "/info/boost-passes/" .. tier .. "/" .. player.UserId
	else
		url = BatchHTTP.getNewUrl("popfeed/info/boost-passes/" .. tier .. "/" .. player.UserId)
	end

	local gameStats = AdRequestStats:getGameStats()

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(gameStats),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching boost passes failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchConfig()
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "config"
	else
		url = BatchHTTP.getNewUrl("popfeed/config")
	end

	local gameStats = AdRequestStats:getGameStats()

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(gameStats),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching popfeed config failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function pagesToTable(pages)
	local items = {}
	while true do
		table.insert(items, pages:GetCurrentPage())

		if pages.IsFinished then
			break
		end

		pages:AdvanceToNextPageAsync()
	end
	return items
end

local function iterPageItems(pages)
	local contents = pagesToTable(pages)

	local pageNum = 1
	local lastPageNum = #contents

	return coroutine.wrap(function()
		while pageNum <= lastPageNum do
			for _, item in contents[pageNum] do
				coroutine.yield(item, pageNum)
			end
			pageNum += 1
		end
	end)
end

local function fetchProfileShopTabItems(userId)
	local items = {}

	local params = CatalogSearchParams.new()
	params.CreatorName = Players:GetNameFromUserIdAsync(userId)

	for item in iterPageItems(AvatarEditorService:SearchCatalog(params)) do
		table.insert(items, item)
	end

	return items
end

local function fetchProfile(player, targetId)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "profile/" .. targetId
	else
		url = BatchHTTP.getNewUrl("popfeed/profile/" .. targetId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player.UserId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching profile data failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	result.shop_items = fetchProfileShopTabItems(targetId)
	result.user_id = targetId

	return result
end

local function fetchDonations(player, targetId)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "donations/list/" .. targetId
	else
		url = BatchHTTP.getNewUrl("popfeed/donations/list/" .. targetId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player.UserId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching donation data failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	PopfeedServer.Donations.cacheDonations(player, targetId, result.donations)

	return result
end

local function fetchPlayerDecals(player, nextPageCursor)
	if nextPageCursor == "first_page" then
		nextPageCursor = nil
	end

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "image-search/from-inventory"
	else
		url = BatchHTTP.getNewUrl("popfeed/image-search/from-inventory")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		player_id = player.UserId,
		cursor = nextPageCursor,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching player's decals failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchImages(keyword, page)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "image-search"
	else
		url = BatchHTTP.getNewUrl("popfeed/image-search")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		keyword = keyword or "",
		page = page or 1,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching images failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchDefaultImageTerms(player)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "/image-search/explore"
	else
		url = BatchHTTP.getNewUrl("popfeed/image-search/explore")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player and player.UserId or 0,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching default image terms failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchFollowingList(player, userId, page)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "following/" .. userId
	else
		url = BatchHTTP.getNewUrl("popfeed/following/" .. userId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player.UserId,
		page = page or 1,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching followings list failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function fetchFollowersList(player, userId, page)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "followers/" .. userId
	else
		url = BatchHTTP.getNewUrl("popfeed/followers/" .. userId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player.UserId,
		page = page or 1,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching followers list failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result
end

local function readNotifications(player, notificationIds)
	local userId = player.UserId

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "notifications/" .. userId .. "/read"
	else
		url = BatchHTTP.getNewUrl("popfeed/notifications/" .. userId .. "/read")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		notifications = notificationIds or "all",
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Reading notifications failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	return result.status == "ok"
end

local function fetchNotificationCounts(userIds)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "notifications/summary"
	else
		url = BatchHTTP.getNewUrl("popfeed/notifications/summary")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		players = userIds or onlineUserIds,
		preview_size = 0,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching notification counts failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	if result.status == "ok" then
		return result.notifications
	end
end

local function fetchNotifications(player, pageNum)
	if pageNum < 1 then
		return
	end

	local userId = player.UserId

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "notifications/" .. userId
	else
		url = BatchHTTP.getNewUrl("popfeed/notifications/" .. userId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		page = pageNum,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching notifications data failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	if result.status == "ok" then
		if pageNum == 1 then
			readNotifications(player, "all")
		end

		return result.notifications, result.unread_count, result.total_count
	end
end

local function fetchLeaderboards(pageNum)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "leaderboard"
	else
		url = BatchHTTP.getNewUrl("popfeed/leaderboard")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		page = pageNum,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching leaderboards data failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	for leaderboardType in cachedLeaderboards.Pages do
		for _, entry in result[leaderboardType] do
			table.insert(cachedLeaderboards.Pages[leaderboardType], entry)
		end
	end

	cachedLeaderboards.LastFetchedPage = pageNum
end

local function fetchPostData(viewer, postId)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "post/" .. postId
	else
		url = BatchHTTP.getNewUrl("popfeed/post/" .. postId)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = viewer.UserId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Fetching post data failed!", result)
		return
	end

	result = HttpService:JSONDecode(result)

	if result.status == "ok" then
		return result.post
	end
end

local function iteratePosts(playerWhoFetched, result, feedType, pageNumber)
	local page = {}

	for _, post in result.posts do
		-- Skipping over comments to not show in the feed
		if not post.parent_id then
			local formatedPost = formatData(post, playerWhoFetched, feedType, pageNumber)
			if formatedPost then
				table.insert(page, formatedPost)
			end
		end
	end

	return page
end

local function iterateReplies(playerWhoFetched, result, pageNum, parentPostId, feedType)
	local page = {}

	if pageNum == 1 then
		local parentPost = fetchPostData(playerWhoFetched, parentPostId)
		if parentPost then
			local formatted = formatData(parentPost, playerWhoFetched, feedType, pageNum)
			if formatted then
				formatted.IsParent = true
				table.insert(page, formatted)
			end
		end
	end

	for _, post in result.replies do
		local formatedPost = formatData(post, playerWhoFetched, feedType, pageNum)
		if formatedPost then
			table.insert(page, formatedPost)
		end
	end

	return page
end

local function iterateWithNoFilter(playerWhoFetched, result, feedType, pageNumber)
	local page = {}

	for _, post in result.posts do
		local formatedPost = formatData(post, playerWhoFetched, feedType, pageNumber)
		if formatedPost then
			table.insert(page, formatedPost)
		end
	end

	return page
end

local function fetchFeed(player, pageNum, feedType, targetId)
	if pageNum < 1 then
		return
	end

	return Utils.benchmarkFn("Fetch feed " .. feedType, function()
		local endpoint = feedType == "replies" and "post/" .. targetId .. "/replies" or "feed/" .. feedType

		local url
		if USE_LOCALHOST then
			url = LOCALHOST .. endpoint
		else
			url = BatchHTTP.getNewUrl("popfeed/" .. endpoint)
		end
	
		local gameStats = AdRequestStats:getGameStats()
		local data = {
			player_id = feedType ~= "replies" and targetId or nil,
			viewer = player.UserId,
			sort = PAGE_SORT,
			page = pageNum,
			page_size = PAGE_SIZE,
		}
	
		local success, result = pcall(function()
			return HttpService:PostAsync(
				url,
				HttpService:JSONEncode(merge(data, gameStats)),
				nil,
				nil,
				BatchHTTP.getGeneralRequestHeaders()
			)
		end)
	
		if not success then
			warn("Fetching", feedType, "feed page", pageNum, "failed!", result)
			return
		end
	
		result = HttpService:JSONDecode(result)
	
		if result.status == "ok" then
			if feedType == "replies" then
				return iterateReplies(player, result, pageNum, targetId, feedType)
			elseif feedType == "comments" or feedType == "liked" then
				return iterateWithNoFilter(player, result, feedType, pageNum)
			else
				return iteratePosts(player, result, feedType, pageNum)
			end
		end
	end)
end

local function getContent(player, pageNum, feedType, targetId)
	local feed = cachedFeed[player][feedType]
	if not feed then
		feed = {}
		cachedFeed[player][feedType] = feed
	end

	local page = feed[pageNum]
	if not page then
		local content
		if feedType == "notifications" then
			content = fetchNotifications(player, pageNum)
		else
			content = fetchFeed(player, pageNum, feedType, targetId)
		end

		if not content or #content == 0 then
			return {}
		end

		page = content
		feed[pageNum] = page
	end

	return page
end

local function forceReload(player, feedType)
	if not cachedFeed[player] then
		cachedFeed[player] = {}
	end

	cachedFeed[player][feedType] = {}
end

local function getLeaderboards(pageNumber, entriesPerPage)
	local entryCount = pageNumber * entriesPerPage

	-- check if we need new page fetch
	for _, entries in cachedLeaderboards.Pages do
		if #entries < entryCount then
			fetchLeaderboards(cachedLeaderboards.LastFetchedPage + 1)
			break
		end
	end

	local results = {}

	local startIndex = entryCount - entriesPerPage + 1
	local endIndex = entryCount

	for leaderboardType, entries in cachedLeaderboards.Pages do
		results[leaderboardType] = {}

		for i = startIndex, endIndex do
			table.insert(results[leaderboardType], entries[i])
		end
	end

	return results
end

local function onRequestContentResponse(player, requestData)
	local profileData
	if requestData.ProfileId then
		profileData = fetchProfile(player, requestData.ProfileId)
	end

	local feedType = requestData.FeedType
	local pageNumber = requestData.NewPageNum
	local oldPageNumber = requestData.OldPageNum
	local postId = requestData.PostId

	if feedType == "shop" then
		return {}, {
			RequestData = requestData,
			ProfileData = profileData,
		}
	end

	if feedType == "explore" then
		local leaderboardData = getLeaderboards(pageNumber, requestData.EntriesPerPage)

		return leaderboardData, {
			RequestData = requestData,
		}
	end

	if feedType == "donations" then
		return {}, {
			RequestData = requestData,
			ProfileData = profileData,
		}
	end

	if pageNumber < 1 then
		return nil, {
			RequestData = requestData,
			ProfileData = profileData,
		}
	end
	pageNumber = pageNumber or 1

	if pageNumber == 1 and feedType ~= "notifications" then
		forceReload(player, feedType)
	end

	local content = getContent(player, pageNumber, feedType, postId)
	local nextContent = getContent(player, pageNumber - 1, feedType, postId)
	local previousContent = getContent(player, pageNumber + 1, feedType, postId)

	local contentTable = {}
	for _, post in nextContent do
		table.insert(contentTable, post)
	end
	for _, post in content do
		table.insert(contentTable, post)
	end
	for _, post in previousContent do
		table.insert(contentTable, post)
	end

	if oldPageNumber then
		if oldPageNumber < pageNumber and #previousContent == 0 then
			return nil, {
				RequestData = requestData,
			}
		end
	end

	return contentTable, {
		RequestData = requestData,
		ProfileData = profileData,
	}
end

local function onPostContentResponse(player, content, imageIds, parentPostId, donationList, screenshotData)
	local success, result = pcall(function()
		return TextService:FilterStringAsync(content, player.UserId)
	end)

	if not success then
		warn("Failed to filter post content", result)
		return
	end

	local filteredString = result:GetNonChatStringForUserAsync(player.UserId)
	if not filteredString then
		filteredString = "[Unknown]"
	end

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "post"
	else
		url = BatchHTTP.getNewUrl("popfeed/post")
	end

	local attachments

	if screenshotData then
		if typeof(screenshotData.Characters) == "table" and typeof(screenshotData.Background) == "string" then
			attachments = {}
			attachments.type = "screenshot"
			attachments.characters = screenshotData.Characters
			attachments.background = screenshotData.Background
		end
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		text = filteredString,
		images = imageIds,
		donations = donationList,
		parent = parentPostId,
		player_id = player.UserId,
		server_id = IsStudio and HttpService:GenerateGUID() or game.JobId,
		attachments = {attachments},
	}

	success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Posting failed!", result)
		return
	end

	return true
end

local function sendImpressions()
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "impressions"
	else
		url = BatchHTTP.getNewUrl("popfeed/impressions")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewers = batchedPostImpressions,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Sending impressions to backend failed!", result)
		return
	end

	batchedPostImpressions = {}
end

local function likePost(player, postId, vote)
	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "post/" .. postId .. "/vote"
	else
		url = BatchHTTP.getNewUrl("popfeed/post/" .. postId .. "/vote")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		vote = vote,
		player_id = player.UserId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Liking failed!", result)
		return
	end
end

local function followUser(player, targetId, follow)
	local endpoint = follow and "follow" or "unfollow"

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. endpoint
	else
		url = BatchHTTP.getNewUrl("popfeed/" .. endpoint)
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		followed_by = player.userId,
		following = targetId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Following failed!", result)
		return
	end
end

local function boostPost(player, postId, boostTier)
	if type(postId) ~= "string" then
		onBoostPost:FireClient(player, false)
		return
	end

	currentBoostingPost[player] = postId

	local data = fetchBoostPasses(player, boostTier)
	if not data or data.status ~= "ok" then
		onBoostPost:FireClient(player, false)
		return
	end

	local firstPass = data.passes[1]
	if not firstPass then
		warn("No boosting gamepass found!")
		onBoostPost:FireClient(player, false)
		return
	end

	promptedBoostPasses[player] = firstPass

	MarketplaceService:PromptGamePassPurchase(player, firstPass)
end

local function onDeletePostResponse(player, postId)
	if type(postId) ~= "string" then
		return
	end

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "post/" .. postId .. "/delete"
	else
		url = BatchHTTP.getNewUrl("popfeed/post/" .. postId .. "/delete")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		viewer = player.userId,
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Deleting post failed!", result)
		return
	end

	return true
end

local function reportPost(player, postId)
	if type(postId) ~= "string" then
		return
	end

	local url
	if USE_LOCALHOST then
		url = LOCALHOST .. "post/" .. postId .. "/report"
	else
		url = BatchHTTP.getNewUrl("popfeed/post/" .. postId .. "/report")
	end

	local gameStats = AdRequestStats:getGameStats()
	local data = {
		player_id = player.userId,
		message = "",
	}

	local success, result = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(merge(data, gameStats)),
			nil,
			nil,
			BatchHTTP.getGeneralRequestHeaders()
		)
	end)

	if not success then
		warn("Reporting post failed!", result)
		return
	end
end

local realOutfits = {}

local function cacheRealOutfit(player)
	local char = player.Character
	if not char then
		return
	end

	local hum = char:FindFirstChild("Humanoid")
	if not hum then
		return
	end

	realOutfits[player] = hum:GetAppliedDescription()
end

local function queueOpenEvent(openData)
	local event = { event_type = "popfeed_open", data = openData }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueViewedPostEvent(viewData)
	local event = { event_type = "popfeed_viewed_post", data = viewData }
	table.insert(BatchHTTP.eventQueue, event)
end

local function handleAnalyticsOpen(player, wasOpened)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	if wasOpened then
		cacheRealOutfit(player)

		analyticsOpenTimestamps[player] = tick()
		return
	end

	local missingTimestamp = not wasOpened and analyticsOpenTimestamps[player] == nil
	if missingTimestamp then
		return
	end

	if not wasOpened then
		local timeSpent = tick() - analyticsOpenTimestamps[player]
		analyticsOpenTimestamps[player] = nil

		local eventStats = {
			["time_spent"] = timeSpent,
			["timestamp"] = os.time(),
		}

		local gameStats = AdRequestStats:getGameStats()
		local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

		eventStats = merge(merge(eventStats, gameStats), playerStats)
		queueOpenEvent(eventStats)

		return
	end
end

local function handleAnalyticsViewedPost(player, postIds)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	if type(postIds) ~= "table" then
		return
	elseif #postIds == 0 then
		return
	end

	local cleanedIdTable = {}
	for i = 1, #postIds do
		table.insert(cleanedIdTable, tostring(postIds[i]))
	end

	local eventStats = {
		["viewed_posts"] = cleanedIdTable,
		["timestamp"] = os.time(),
	}

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	eventStats = merge(merge(eventStats, gameStats), playerStats)
	queueViewedPostEvent(eventStats)
end

local function replicateNotificationCounts(playerCounts)
	if not playerCounts then
		return
	end

	for _, data in playerCounts do
		local count = data.unread_count
		local player = Players:GetPlayerByUserId(data.for_player)

		if not player then
			continue
		end

		if count < 1 then
			continue
		end

		forceReload(player, "notifications")

		onNewNotifications:FireClient(player, count)
	end
end

local function onPromptPurchaseFinished(player, passId, success)
	local postId = currentBoostingPost[player]

	if promptedBoostPasses[player] ~= passId then
		return
	end

	--edge-case: if backend failed before but gamepass still purchased
	local _, boostPassAlreadyOwned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	local shouldProcessBoost = success or (not success and boostPassAlreadyOwned)
	if shouldProcessBoost and postId then
		local result = processBoostPost(player, postId, passId)
		if not result or result.status ~= "ok" then
			success = false
		end
	end

	onBoostPost:FireClient(player, success)
end

local function onRequestConfigResponse()
	if not cachedConfig then
		onConfigLoaded.Event:Wait()
	end

	return cachedConfig
end

local function onSearchDecalsResponse(player, nextPageCursor)
	nextPageCursor = nextPageCursor or "first_page"

	local results = cachedDecals[player][nextPageCursor]
	if not results then
		results = fetchPlayerDecals(player, nextPageCursor)
		cachedDecals[player][nextPageCursor] = results
	end

	return results, nextPageCursor
end

local function onSearchImagesResponse(player, keyword, page)
	local results = cachedImages[keyword .. page]
	if not results then
		results = fetchImages(keyword, page)
		cachedImages[keyword .. page] = results
	end

	return results, { Keyword = keyword, Page = page }
end

local function onGetFollowersListResponse(player, userId, page)
	--local key = userId .. "_" .. page

	--local results = cachedFollowers[key]
	--if not results then
		local results = fetchFollowersList(player, userId, page)
		--cachedFollowers[key] = results
	--end

	return results.followers, { UserId = userId, Page = page }
end

local function onGetFollowingListResponse(player, userId, page)
	--local key = userId .. "_" .. page

	--local results = cachedFollowings[key]
	--if not results then
		local results = fetchFollowingList(player, userId, page)
		--cachedFollowings[key] = results
	--end

	return results.following, { UserId = userId, Page = page }
end

local function requestSearchTerms(player)
	onSearchTermUpdate:FireClient(player, cachedImageTerms)
end

local function batchPostImpressions(player, impressions)
	table.insert(batchedPostImpressions, {
		player_id = player.UserId,
		posts = impressions,
	})
end

function PopfeedServer.init()
	onSendPostImpressions = Instance.new("RemoteEvent")
	onSendPostImpressions.Name = "PopfeedOnSendPostImpressions"
	onSendPostImpressions.OnServerEvent:Connect(batchPostImpressions)
	onSendPostImpressions.Parent = ReplicatedStorage.BloxbizRemotes

	onLikePost = Instance.new("RemoteEvent")
	onLikePost.Name = "PopfeedOnLikePost"
	onLikePost.OnServerEvent:Connect(likePost)
	onLikePost.Parent = ReplicatedStorage.BloxbizRemotes

	onBoostPost = Instance.new("RemoteEvent")
	onBoostPost.Name = "PopfeedOnBoostPost"
	onBoostPost.OnServerEvent:Connect(boostPost)
	onBoostPost.Parent = ReplicatedStorage.BloxbizRemotes

	onDeletePost = Instance.new("RemoteFunction")
	onDeletePost.Name = "PopfeedOnDeletePost"
	onDeletePost.OnServerInvoke = onDeletePostResponse
	onDeletePost.Parent = ReplicatedStorage.BloxbizRemotes

	onReportPost = Instance.new("RemoteEvent")
	onReportPost.Name = "PopfeedOnReportPost"
	onReportPost.OnServerEvent:Connect(reportPost)
	onReportPost.Parent = ReplicatedStorage.BloxbizRemotes

	onFollowUser = Instance.new("RemoteEvent")
	onFollowUser.Name = "PopfeedOnFollowUser"
	onFollowUser.OnServerEvent:Connect(followUser)
	onFollowUser.Parent = ReplicatedStorage.BloxbizRemotes

	onGetFollowersList = Instance.new("RemoteFunction")
	onGetFollowersList.Name = "PopfeedOnGetFollowersList"
	onGetFollowersList.OnServerInvoke = onGetFollowersListResponse
	onGetFollowersList.Parent = ReplicatedStorage.BloxbizRemotes

	onGetFollowingList = Instance.new("RemoteFunction")
	onGetFollowingList.Name = "PopfeedOnGetFollowingList"
	onGetFollowingList.OnServerInvoke = onGetFollowingListResponse
	onGetFollowingList.Parent = ReplicatedStorage.BloxbizRemotes

	onPostContent = Instance.new("RemoteFunction")
	onPostContent.Name = "PopfeedOnPostContent"
	onPostContent.OnServerInvoke = onPostContentResponse
	onPostContent.Parent = ReplicatedStorage.BloxbizRemotes

	onRequestContent = Instance.new("RemoteFunction")
	onRequestContent.Name = "PopfeedOnRequestContent"
	onRequestContent.OnServerInvoke = onRequestContentResponse
	onRequestContent.Parent = ReplicatedStorage.BloxbizRemotes

	onSearchDecals = Instance.new("RemoteFunction")
	onSearchDecals.Name = "PopfeedOnSearchDecals"
	onSearchDecals.OnServerInvoke = onSearchDecalsResponse
	onSearchDecals.Parent = ReplicatedStorage.BloxbizRemotes

	onSearchImages = Instance.new("RemoteFunction")
	onSearchImages.Name = "PopfeedOnSearchImages"
	onSearchImages.OnServerInvoke = onSearchImagesResponse
	onSearchImages.Parent = ReplicatedStorage.BloxbizRemotes

	onSearchTermUpdate = Instance.new("RemoteEvent")
	onSearchTermUpdate.Name = "PopfeedOnSearchTermUpdate"
	onSearchTermUpdate.OnServerEvent:Connect(requestSearchTerms)
	onSearchTermUpdate.Parent = ReplicatedStorage.BloxbizRemotes

	onRequestConfig = Instance.new("RemoteFunction")
	onRequestConfig.Name = "PopfeedOnRequestConfig"
	onRequestConfig.OnServerInvoke = onRequestConfigResponse
	onRequestConfig.Parent = ReplicatedStorage.BloxbizRemotes

	onRequestDonationItems = Instance.new("RemoteFunction")
	onRequestDonationItems.Name = "PopfeedOnRequestDonationItems"
	onRequestDonationItems.OnServerInvoke = fetchDonations
	onRequestDonationItems.Parent = ReplicatedStorage.BloxbizRemotes

	onNewNotifications = Instance.new("RemoteEvent")
	onNewNotifications.Name = "PopfeedOnNewNotifications"
	onNewNotifications.Parent = ReplicatedStorage.BloxbizRemotes

	onAnalyticsOpen = Instance.new("RemoteEvent")
	onAnalyticsOpen.Name = "PopfeedAnalyticsOpen"
	onAnalyticsOpen.OnServerEvent:Connect(handleAnalyticsOpen)
	onAnalyticsOpen.Parent = ReplicatedStorage.BloxbizRemotes

	onAnalyticsViewedPost = Instance.new("RemoteEvent")
	onAnalyticsViewedPost.Name = "PopfeedAnalyticsViewedPost"
	onAnalyticsViewedPost.OnServerEvent:Connect(handleAnalyticsViewedPost)
	onAnalyticsViewedPost.Parent = ReplicatedStorage.BloxbizRemotes

	onChangeOutfit = Instance.new("RemoteEvent")
	onChangeOutfit.Name = "PopfeedChangeOutfit"
	onChangeOutfit.OnServerEvent:Connect(function(player, outfitId)
		local char = player.Character
		if not char then
			return
		end

		local hum = char:FindFirstChild("Humanoid")
		if not hum then
			return
		end

		if not outfitId then
			if realOutfits[player] then
				hum:ApplyDescription(realOutfits[player])
			end
			return
		end

		local outfit = ReplicatedStorage.Outfits:FindFirstChild(outfitId)
		if not outfit then
			return
		end

		outfit.Face = realOutfits[player].Face
		outfit.Head = realOutfits[player].Head
		outfit.HeadScale = realOutfits[player].HeadScale
		outfit.HeadColor = realOutfits[player].HeadColor
		outfit.HatAccessory = realOutfits[player].HatAccessory
		outfit.FaceAccessory = realOutfits[player].FaceAccessory
		outfit.HairAccessory = realOutfits[player].HairAccessory

		hum:ApplyDescription(outfit)
	end)
	onChangeOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptPurchaseFinished)

	Players.PlayerRemoving:Connect(function(player)
		local index = table.find(onlineUserIds, player.UserId)
		if index then
			table.remove(onlineUserIds, index)
		end

		realOutfits[player] = nil
		cachedFeed[player] = nil
		cachedDecals[player] = nil
		currentBoostingPost[player] = nil
		promptedBoostPasses[player] = nil
		analyticsOpenTimestamps[player] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		cachedFeed[player] = {}
		cachedDecals[player] = {}

		table.insert(onlineUserIds, player.UserId)
		--populatePosts(player, 45)
		--followUser(player, player.UserId)
		--fetchProfile(player, player.UserId)
		--fetchNotifications(player, 1)
		--fetchNotificationCounts()
		--fetchBoostPasses(player, "copper")
		--fetchImages()
		--fetchDefaultImageTerms(player)
		--fetchDonations(player, player.UserId)

		replicateNotificationCounts(fetchNotificationCounts({ player.UserId }))
	end)

	task.spawn(function()
		while true do
			local result = fetchDefaultImageTerms()
			if result then
				cachedImageTerms = {}

				local terms = result.top_terms
				for i = 1, 8 do
					local term = terms[i]
					table.insert(cachedImageTerms, term)
				end

				onSearchTermUpdate:FireAllClients(cachedImageTerms)
			end

			task.wait(IMAGE_TERMS_UPDATE_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			replicateNotificationCounts(fetchNotificationCounts())

			task.wait(NOTIFICATIONS_UPDATE_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(IMAGE_CACHE_CLEAR_INTERVAL)

			cachedImages = {}
		end
	end)

	task.spawn(function()
		while true do
			task.wait(LEADERBOARD_CACHE_CLEAR_INTERVAL)

			cachedLeaderboards = {
				Pages = {
					top_donors = {},
					--top_raisers = {},
					top_boosters = {},
				},
				LastFetchedPage = 0,
			}
		end
	end)

	task.spawn(function()
		while true do
			task.wait(POST_IMPRESSIONS_SEND_INTERVAL)

			if #batchedPostImpressions == 0 then
				continue
			end

			sendImpressions()
		end
	end)

	cachedConfig = fetchConfig()
	onConfigLoaded:Fire()
end

return PopfeedServer
