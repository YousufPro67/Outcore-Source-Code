local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local ConfigReader = require(script.Parent.Parent.ConfigReader)
local Promise = require(script.Parent.Parent.Utils.Promise)
local Utils = require(script.Parent.Parent.Utils)
local Net = require(script.Parent.Parent.Utils.Net)
local http = require(script.Parent.Parent.BatchHTTP)


local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

-- remotes

local CheckRewardFunction
local GetRewardsFunction

local playerRewardsCache = {}

-- module

local RewardsServer = {}

function RewardsServer.init()
    CheckRewardFunction = Instance.new("RemoteFunction")
    CheckRewardFunction.Name = "CheckReward"
    CheckRewardFunction.Parent = BloxbizRemotes
    CheckRewardFunction.OnServerInvoke = RewardsServer.checkReward

    GetRewardsFunction = Instance.new("RemoteFunction")
    GetRewardsFunction.Name = "GetRewards"
    GetRewardsFunction.Parent = BloxbizRemotes
    GetRewardsFunction.OnServerInvoke = RewardsServer.getAllClaimedRewards

    if ConfigReader:read("RewardsAutoPromptUGC") then
        local onJoin = function(player)
            local joinData = player:GetJoinData()
            local launchData = joinData.LaunchData
    
            if launchData and #launchData == 36 then
                if not player:HasAppearanceLoaded() then
                    player.CharacterAppearanceLoaded:Wait()
                end

                Promise.delay(5)
                    :andThen(function()
                        Utils.pprint("Checking reward for " .. player.Name)
                        RewardsServer.checkReward(player, launchData, true)
                    end)
            end
        end

        Players.PlayerAdded:Connect(onJoin)
        for _, player in Players:GetChildren() do
            task.spawn(function()
                onJoin(player)
            end)
        end
    end

    -- Unlockables verification

    Net:RemoteEvent("UnlockablesVerifyStart")
    Net:RemoteEvent("UnlockablesVerifyComplete")
    
    if ConfigReader:read("UnlockablesAutoVerifyUsers") then
        local onJoin = function(player)
            local joinData = player:GetJoinData()
            local launchData = joinData.LaunchData or ""
    
            if Utils.startsWith(launchData, "verify:") then
                local token = string.sub(launchData, 8)
                Utils.pprint(token)

                local success, err = http.request("post", "/rewards/sdk/connect/" .. token)

                if success then
                    if not player:HasAppearanceLoaded() then
                        player.CharacterAppearanceLoaded:Wait()
                    end
                    
                    Net:RemoteEvent("UnlockablesVerifyStart"):FireClient(player)
                else
                    warn(err)
                end
            end
        end

        Players.PlayerAdded:Connect(onJoin)
        for _, player in Players:GetChildren() do
            task.spawn(function()
                onJoin(player)
            end)
        end

        Net:RemoteEvent("UnlockablesVerifyComplete").OnServerEvent:Connect(function(player)
            local joinData = player:GetJoinData()
            local launchData = joinData.LaunchData or ""
            
            if Utils.startsWith(launchData, "verify:") then
                local token = string.sub(launchData, 8)
                Utils.pprint(token)

                local success, err = http.request("post", "/rewards/sdk/connect/" .. token .. "/use", {
                    player_id = player.UserId,
                    username = player.Name,
                    display_name = player.DisplayName,
                })

                if not success then
                    warn(err)
                end
            end
        end)
    end

    MarketplaceService.PromptPurchaseFinished:Connect(function(plr, assetId, isPurchased)
        if isPurchased then
            local playerId = plr.UserId
            if playerRewardsCache[playerId] and playerRewardsCache[playerId][assetId] then
                local rewardId = playerRewardsCache[playerId][assetId]
                RewardsServer.markRewardRedeemed(plr, rewardId)
            end
        end
    end)
end

function RewardsServer.checkReward(player: Player, rewardId: string, promptIfEarned: boolean?)
    local success, resp = BatchHTTP.request("post", "/rewards/sdk/check-user-reward", {
        reward_id = rewardId,
        player_id = player.UserId
    })

    if promptIfEarned and success and resp.reward.reward_type == "avatar_item" then
        Utils.pprint("Prompting purchase for " .. player.Name)

        local assetId = resp.reward.reward_info.reward_data
        
        playerRewardsCache[player.UserId] = playerRewardsCache[player.UserId] or {}
        playerRewardsCache[player.UserId][assetId] = rewardId

        MarketplaceService:PromptPurchase(player, assetId)
    end

    return success, success and resp.reward or resp
end

function RewardsServer.getAllClaimedRewards(player: Player)
    local success, resp = BatchHTTP.request("post", "/rewards/sdk/get-user-rewards", {
        player_id = player.UserId
    })

    return success, success and resp.rewards or resp
end

function RewardsServer.markChallengeComplete(player: Player, challengeId: string)
    local success, _ = BatchHTTP.request("post", "/rewards/sdk/mark-challenge-complete", {
        player_id = player.UserId,
        challenge_id = challengeId
    })

    return success
end

function RewardsServer.markRewardRedeemed(player: Player, rewardId: string)
    local success, _ = BatchHTTP.request("post", "/rewards/sdk/mark-reward-redeemed", {
        player_id = player.UserId,
        reward_id = rewardId
    })

    return success
end

function RewardsServer.setPlayerScore(contestId: string, player: Player, score: number)
    return BatchHTTP.request("post", "/rewards/sdk/record-contest-score", {
        roblox_id = player.UserId,
        contest_id = contestId,
        score = score,
        increment = false,
    })
end

function RewardsServer.addPlayerScore(contestId: string, player: Player, score: number)
    return BatchHTTP.request("post", "/rewards/sdk/record-contest-score", {
        roblox_id = player.UserId,
        contest_id = contestId,
        score = score,
        increment = true,
    })
end


return RewardsServer