local ConfigReader = require(script.Parent.Parent.ConfigReader)
local Distributors = require(script.Parent.Distributors)
local Validators = require(script.Parent.Validators)

local PromoCodes = {}

function PromoCodes.init()
    if ConfigReader:read("AutoValidatePromoCodesClaims") then
        Validators.validateOnJoin()
        -- print("Promo Claims will be automatically validated")
    end
end

function PromoCodes.getCampaignId()
    return ConfigReader:read("PromoCodesCampaignID")
end

-- Distributors --

function PromoCodes.distributeCode(player, options)
    options = options or {}

    return Distributors.distributeCode(
        player, options.campaign or PromoCodes.getCampaignId(), options
    )
end

function PromoCodes.currentBatch(options)
    options = options or {}

    return Distributors.getCurrentBatch(options.campaign or PromoCodes.getCampaignId(), options)
end

-- Validators --

function PromoCodes.validateClaim(player, claimId)
    return Validators.validateClaim(player, claimId)
end

PromoCodes.PlayerReceivedReward = Validators._playerReceivedRewardServer.Event


return PromoCodes