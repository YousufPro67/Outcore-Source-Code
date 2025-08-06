local ReplicatedStorage = game:GetService("ReplicatedStorage")

local http = require(script.Parent.Http)
local utils = require(script.Parent.Parent.Utils)
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local distributors = {}
distributors._playerReceivedCode = BloxbizRemotes.PlayerReceivedPromoCode

function distributors.getCurrentBatch(campaignId, options)
    options = options or {}

    local url = "campaign/" .. campaignId .. "/distributors/current"
    local success, result = pcall(function()
        return http.post(url, {
            metadata = options.metadata,
            metadata_exclude = options.metadata_exclude
        })
    end)

    if not success then
        warn("[SuperBiz] Error fetching current distributor batch: " .. tostring(result))
		utils.pprint(debug.traceback())
        return
    end

    return result.data
end

function distributors.distributeCode(player, campaignId, options)
    options = options or {}

    local url = "campaign/" .. campaignId .. "/distribute"
    local data = {
        player_id = player.UserId,
        metadata = options.metadata,
        metadata_exclude = options.metadata_exclude
    }

    local success, result = pcall(function()
        return http.post(url, data)
    end)

    if not success then
        warn("[SuperBiz] Error distributing code to player: " .. tostring(result))
		utils.pprint(debug.traceback())
        return
    end

    if result.status ~= "ok" then
        warn("[SuperBiz] Error distributing code to player: " .. tostring(result.message))
		utils.pprint(debug.traceback())
        return
    end

    distributors._playerReceivedCode:FireClient(player, result.code.plaintext_code, result.code.metadata)

    return result.code.plaintext_code, result.code.metadata
end

return distributors