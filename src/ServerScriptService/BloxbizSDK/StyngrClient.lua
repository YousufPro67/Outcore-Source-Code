local StyngrClient = {}

function StyngrClient.Init()
    local StyngrFolder = game.StarterPlayer.StarterPlayerScripts:WaitForChild("Styngr")

    local BoomboxTopbarManager = require(StyngrFolder.BoomboxTopbarManager)

    local Configuration = {}
    local config = StyngrFolder:FindFirstChild("Configuration")
    if config then
        Configuration = require(config)
    end

    require(StyngrFolder.AppStateService):Init()

    local Styngr = require(StyngrFolder.StyngrClient)

    Styngr:Init()
    BoomboxTopbarManager:Init(Configuration)
end

return StyngrClient