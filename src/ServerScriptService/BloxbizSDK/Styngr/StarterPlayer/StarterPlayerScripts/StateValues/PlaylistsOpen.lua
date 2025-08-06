local Fusion = require(game:GetService("ReplicatedStorage").BloxbizSDK.Utils.Fusion)

local PlaylistsOpen = Fusion.Value(false)

function PlaylistsOpen:toggle()
	self:set(not self:get())
end

return PlaylistsOpen
