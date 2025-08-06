local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigReader = require(script.Parent.Parent.ConfigReader)
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local Net = require(script.Parent.Parent.Utils.Net)

local showVerifyModal = require(script.Parent.VerifyModal)



-- remotes

local CheckRewardFunction = BloxbizRemotes:WaitForChild("CheckReward")
local GetRewardsFunction = BloxbizRemotes:WaitForChild("GetRewards")

-- module

local RewardsClient = {}

function RewardsClient.init()
    Net:RemoteEvent("UnlockablesVerifyStart").OnClientEvent:Connect(function()
        showVerifyModal()
    end)
end

function RewardsClient.checkReward(rewardId: string, promptIfEarned: boolean?)
    return CheckRewardFunction:InvokeServer(rewardId, promptIfEarned)
end

function RewardsClient.getAllClaimedRewards()
    return GetRewardsFunction:InvokeServer()
end


return RewardsClient