local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TokenReceivedEvent = ReplicatedStorage.Styngr.TokenReceivedEvent

local function SendTokenReceived(player: Player)
	TokenReceivedEvent:FireClient(player)
end

return SendTokenReceived
