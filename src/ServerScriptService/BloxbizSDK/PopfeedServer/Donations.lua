local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local BatchHTTP = require(script.Parent.Parent.BatchHTTP)

local module = {}
module.fetchedDonations = {
    --[playerId] = cache
    --cache: [donation_item_id] = donationData
}

local function isPopfeedDonation(playerCacheToCheck, donationId)
    local cacheDict = module.fetchedDonations[playerCacheToCheck.UserId]
    if not cacheDict then
        return false
    end

    if not cacheDict[donationId] then
        return false
    end

    return true
end

local function sendDonationConfirmation(player, donationId)
    local url = BatchHTTP.getNewUrl('popfeed/donations/verify')

    local success, result = pcall(function()
        return HttpService:PostAsync(url, HttpService:JSONEncode({
            donor = player.UserId,
            recipient = module.fetchedDonations[player.UserId][donationId].sellerId,
            item_id = donationId,
            donation_type = module.fetchedDonations[player.UserId][donationId].itemType,
            game_id = game.GameId
        }), nil, nil, BatchHTTP.getGeneralRequestHeaders())
    end)

    if not success then
        warn("Donation confirmation failed", result)
        return
    end

    result = HttpService:JSONDecode(result)

    return result
end

local function onGamePassPurchase(player, gamePassId, wasPurchased)
    if not wasPurchased then
        return
    end

    if isPopfeedDonation(player, gamePassId) then
        sendDonationConfirmation(player, gamePassId)
    end
end

local function onClothesPurchase(player, assetId, wasPurchased)
    if not wasPurchased then
        return
    end

    if isPopfeedDonation(player, assetId) then
        sendDonationConfirmation(player, assetId)
    end
end

local function onPlayerRemoving(player)
    if module.fetchedDonations[player] then
       module.fetchedDonations[player] = nil
    end
end

function module.cacheDonations(player, sellerId, recipientDonationList)
    local cacheDict = module.fetchedDonations[player.UserId]
    if not cacheDict then
        module.fetchedDonations[player.UserId] = {}
        cacheDict = module.fetchedDonations[player.UserId]
    end

    for _, donation in recipientDonationList do
        cacheDict[donation.item_id] = {
            sellerId = sellerId,
            itemType = donation.item_type,
            price = donation.robux
        }
    end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassPurchase)
MarketplaceService.PromptPurchaseFinished:Connect(onClothesPurchase)
Players.PlayerRemoving:Connect(onPlayerRemoving)

return module