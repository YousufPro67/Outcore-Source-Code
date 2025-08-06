local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local players = game.Players
local utils = knit.GetService("UtilityService")
local cs = game:GetService("CollectionService")

for _,pad in cs:GetTagged("BouncePad") do
	utils.Bouncepad.new(pad,0.9,"Realistic")
	local emitter = script.ParticleEmitter:Clone()
	emitter.Parent = pad
end

