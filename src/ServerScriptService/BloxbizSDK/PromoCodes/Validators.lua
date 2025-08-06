local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local http = require(script.Parent.Http)
local utils = require(script.Parent.Parent.Utils)
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local validators = {}
validators._setupOnJoin = false
validators._playerReceivedRewardClient = BloxbizRemotes:WaitForChild("PlayerReceivedReward")
validators._playerReceivedRewardServer = Instance.new("BindableEvent")

function validators.validateClaim(player, claimId)
    local url = "claim/use"
    local data = {
        player_id = player.UserId,
        claim_id = claimId
    }

    local success, result = pcall(function()
        return http.post(url, data)
    end)

    if not success then
        warn("[SuperBiz] Error validating claim for player: " .. tostring(result))
		utils.pprint(debug.traceback())
        return
    end

    if result.status ~= "ok" then
        warn("[SuperBiz] Error validating claim for player: " .. tostring(result.message))
		utils.pprint(debug.traceback())
        return
    end

    validators._playerReceivedRewardClient:FireClient(player, result.claim.reward_id)
    validators._playerReceivedRewardServer:Fire(player, result.claim.reward_id)

    return result.claim.reward_id
end

function validators.validateOnJoin()
    if validators._setupOnJoin then
        warn("PromoCodes.validateOnJoin() is being called more than once.")
        return
    end

    Players.PlayerAdded:Connect(function (player)
        local joinData = player:GetJoinData()
        if (not joinData.LaunchData) or #joinData.LaunchData == 0 then
            return
        end

        validators.validateClaim(player, joinData.LaunchData)
    end)

    validators._setupOnJoin = true
end

return validators