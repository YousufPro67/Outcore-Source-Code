local SearchModule = {}

local HttpService = game:GetService("HttpService")

local URL_ENDPOINT = "&Limit=30&Keyword=%s&SortType=%s"

local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

type ItemData = {
	Name: string,
	Price: number,
	AssetId: number,
	AssetType: number,
	IsForSale: boolean,
	IsLimited: number,

	Available: number,
	Purchased: number,
}

export type ItemFilter = { Categories: { number }?, Subcategories: { number }?, AssetTypes: { number }? }

export type CreatorFilter = {
	CreatorId: number?,
	CreatorName: string?,
	CreatorType: number?
}

local ActivePlayerSearches = {}

local function buildAssetData(item): ItemData?
	if not item.assetType then
		return
	end

	local limitedType = 0
	if table.find(item.itemRestrictions, "LimitedUnique") or table.find(item.itemRestrictions, "Collectible") then
		limitedType = 1
	elseif table.find(item.itemRestrictions, "Limited") then
		limitedType = 2
	end

	return {
		Name = item.name,
		Price = item.lowestPrice or item.price,
		AssetId = item.id,
		AssetType = item.assetType,
		IsForSale = item.priceStatus ~= "Offsale",
		IsLimited = limitedType,

		Available = item.unitsAvailableForConsumption,
		Purchased = item.purchaseCount,
	}
end

local function buildBundleData(item)
	if not item.bundleType then
		return
	end

	return {
		Name = item.name,
		Price = item.lowestPrice or item.price,
		BundleId = item.id,
		BundleType = item.bundleType,
	}
end

local function DownloadPage(player: Player, url: string)
	local AdRequestStats = require(script.Parent.Parent.AdRequestStats)

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)

	local data = merge(merge(gameStats, playerStats), clientPlayerStats)
	data = HttpService:JSONEncode(data)

	local response = HttpService:PostAsync(url, data, Enum.HttpContentType.ApplicationJson)
	local responseArray = HttpService:JSONDecode(response)

	if not responseArray.data then
		return
	end

	local page = {}
	local nextPageCursor = responseArray.nextPageCursor

	for _, item in pairs(responseArray.data) do
		if item.itemType == "Asset" then
			local builtItem = buildAssetData(item)
			if builtItem then
				table.insert(page, builtItem)
			end
		else
			table.insert(page, buildBundleData(item))
		end
	end

	return page, nextPageCursor
end

local function RequestPage(
	player: Player,
	keyword: string,
	sortType: number,
	nextPageCursor: string,
	allowedTypes: ItemFilter?,
	creatorFilter: CreatorFilter?
)
	local BatchHTTP = require(script.Parent.Parent.BatchHTTP)

	local baseUrl = BatchHTTP.getNewUrl("catalog/proxy")
	baseUrl = baseUrl .. URL_ENDPOINT

	local newUrl = baseUrl:format(keyword, sortType)
	if allowedTypes then
		if allowedTypes.Categories then
			for _, value in pairs(allowedTypes.Categories) do
				newUrl ..= "&Category=" .. value
			end
		end

		if allowedTypes.Subcategories then
			for _, value in pairs(allowedTypes.Subcategories) do
				newUrl ..= "&Subcategory=" .. value
			end
		end
	end

	if creatorFilter then
		for k, v in pairs(creatorFilter) do
			newUrl ..= "&" .. k .. "=" .. tostring(v)
		end
	end

	local items

	if nextPageCursor then
		items, nextPageCursor = DownloadPage(player, newUrl .. "&Cursor=" .. nextPageCursor)
	else
		items, nextPageCursor = DownloadPage(player, newUrl)
	end

	if not items then
		return "No more pages"
	end

	local Page = {
		Items = items,
		NextPageCursor = nextPageCursor,
	}
	return Page
end

local function GetNormalPage(
	player: Player,
	keyword: string,
	pageNum: number,
	sortType: number,
	allowedTypes: ItemFilter?,
	creatorFilter: CreatorFilter?
)
	local cachedSearch = ActivePlayerSearches[player]

	local nextPageCursor
	if cachedSearch and cachedSearch.Keyword == keyword and pageNum > 1 then
		if not cachedSearch.Pages[pageNum] then
			nextPageCursor = cachedSearch.Pages[pageNum - 1] or false
		end
	else
		ActivePlayerSearches[player] = {
			Keyword = keyword,
			Pages = {},
		}
		cachedSearch = ActivePlayerSearches[player]
	end

	if nextPageCursor == false then
		return "No more pages"
	end

	local Page = RequestPage(player, keyword, sortType, nextPageCursor :: string, allowedTypes, creatorFilter)
	if not Page then
		return "No more pages"
	end

	cachedSearch.Pages[pageNum] = Page.NextPageCursor

	return Page.Items
end

function SearchModule.GetItems(
	player: Player,
	keyword: string,
	pageNum: number,
	sortType: number,
	allowedTypes: ItemFilter?,
	creatorFilter: CreatorFilter?
)
	if not sortType then
		sortType = 0
	end
	local page = GetNormalPage(player, keyword, pageNum, sortType, allowedTypes, creatorFilter)

	return page
end

function SearchModule.ResetPlayerCache(player: Player)
	ActivePlayerSearches[player] = nil
end

return SearchModule
