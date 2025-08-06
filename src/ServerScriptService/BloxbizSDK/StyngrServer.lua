local StyngrServer = {}

function StyngrServer.Init()
    local Styngr = game.ServerScriptService:WaitForChild("Styngr")

    local Configuration = require(Styngr.Configuration)

    local StyngrService = require(Styngr.StyngrService)
    StyngrService:init(Configuration)
end

return StyngrServer