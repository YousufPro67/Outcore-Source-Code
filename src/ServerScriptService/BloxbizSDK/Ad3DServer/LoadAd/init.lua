return function(ad3DServerInstance, adToLoad)
	if adToLoad.ad_type == "Character" then
		local loader = require(script.LoadCharacterAd)
		loader(adToLoad)

		return true
	elseif adToLoad.ad_type == "BoxInventorySizing" then
		return true
	end
end
