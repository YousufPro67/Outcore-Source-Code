local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TokenLostEvent = ReplicatedStorage.Styngr.TokenLostEvent

local function SendTokenLost(player: Player)
	TokenLostEvent:FireClient(player)
end

return SendTokenLost
