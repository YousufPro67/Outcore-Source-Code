local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local PromoCodes = {}

PromoCodes.ReceivedCode = BloxbizRemotes:WaitForChild("PlayerReceivedPromoCode").OnClientEvent;
PromoCodes.ReceivedReward = BloxbizRemotes:WaitForChild("PlayerReceivedReward").OnClientEvent;

return PromoCodes