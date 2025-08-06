-- DEPRECATED

local module = {}

function module:init_instance_dynamically(ad)
	local PublicAPI = require(script.Parent.PublicAPI)
	PublicAPI.dynamicLoadBillboardAd(ad)
end

function module:init_3d_instance_dynamically(ad)
	local PublicAPI = require(script.Parent.PublicAPI)
	PublicAPI.dynamicLoadBoxAd(ad)
end

return module