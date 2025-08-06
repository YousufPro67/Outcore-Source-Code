local Players = game:GetService("Players")

local ConfigReader = require(script.Parent.Parent.Parent.ConfigReader)

local CopyOutFitController = {}

local LocalPlayer = Players.LocalPlayer

local CatalogCopyOutfitsFromPlayersEnabled  = ConfigReader:read("CatalogCopyOutfitsFromPlayersEnabled")

local function onCharacterAdded(character, player)
    local root = character:WaitForChild("HumanoidRootPart")

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CopyOutfit"
    prompt.ObjectText = "Popmall"
    prompt.ActionText = "Wear Outfit"
    prompt.HoldDuration = 0.3
    prompt.MaxActivationDistance = 5
    prompt.RequiresLineOfSight = false

    prompt.Triggered:Connect(function()
        CopyOutFitController.Controllers.AvatarPreviewController:LoadCurrentOutfit(humanoid, true)
    end)

    prompt.Parent = root
end

local function onPlayerAdded(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)

    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

function CopyOutFitController.new(container, loadingFrame)
	return CopyOutFitController
end

function CopyOutFitController:Init(controllers)
    if not CatalogCopyOutfitsFromPlayersEnabled  then
        return
    end

    self.Controllers = controllers

    Players.PlayerAdded:Connect(onPlayerAdded)

    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end
end

return CopyOutFitController