local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes = ReplicatedStorage.BloxbizRemotes

local RankManager = require(script.RankManager)

local Config = require(script.Parent.Config)
local Commands = require(script.Parent.Commands)

local OnRunCommand = Instance.new("RemoteEvent")
OnRunCommand.Name = "OnRunCommand"
OnRunCommand.Parent = Remotes

local CommandToolServer = {}

local PREFIX = Config:Read("CommandPrefix")

local ARG_VALIDATORS = {
    Player = function(name, player)
        if not name then
            return player
        end

        for _, target in Players:GetPlayers() do
            if target.Name:lower() == name then
                return target
            end
        end
    end,

    Text = function(text)
        return text or ""
    end,

    Number = function(number)
        if tonumber(number) then
            return number
        end
    end,
}

local function getCommand(text)
    local hasPrefix = text:sub(1, 1) == PREFIX
    if not hasPrefix then
        return
    end

    local loweredText = text:sub(2):lower()
    local inputtedArgs = loweredText:split(" ")

    local commandId = inputtedArgs[1]
    table.remove(inputtedArgs, 1)

    return commandId, Commands[commandId], inputtedArgs
end

local function validateArgs(inputtedArgs, args, player)
    if args == "None" then
        return "None"
    end

    local validatedArgs = {}

    for index, arg in args do
        local inputtedArg = inputtedArgs[index]
        local validateCallback = ARG_VALIDATORS[arg]

        local validArg = validateCallback(inputtedArg, player)
        if not validArg then
            return
        end

        table.insert(validatedArgs, validArg)
    end

    return validatedArgs
end

local function hasPermission(player, commandId)
    local ranks = RankManager.GetRanks(player)
    if not ranks then
        return
    end

    for _, rank in ranks do
        if Config:CanUseCommand(rank, commandId) then
            return true
        end
    end

    return false
end

local function onPlayerChatted(player, text)
    local commandId, command, inputtedArgs = getCommand(text)
    if not command then
        return
    end

    if not hasPermission(player, commandId) then
        return
    end

    local args = validateArgs(inputtedArgs, command.Args, player)
    if not args then
        return
    end

    local callback = command.Callback
    if not callback then
        return
    end

    callback(player, args)
end

local function onRunCommand(player, target, commandId)
    if type(target) ~= "string" or type(commandId) ~= "string" then
        return
    end

    local text = string.format("%s%s %s", PREFIX, commandId, target)
    onPlayerChatted(player, text)
end

function CommandToolServer.Init()
    OnRunCommand.OnServerEvent:Connect(onRunCommand)

    RankManager.Init()
    CommandToolServer.RankManager = RankManager

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
        if not wasPurchased then
            return
        end

        local rank = Config:IsRankGamepass(gamepassId)
        if not rank then
            return
        end

        RankManager.AddRank(player, rank)
        RankManager.SaveGamepass(player, gamepassId)
    end)

    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(text)
            onPlayerChatted(player, text)
        end)
    end)

    for _, player in Players:GetPlayers() do
        player.Chatted:Connect(function(text)
            onPlayerChatted(player, text)
        end)
    end
end

return CommandToolServer