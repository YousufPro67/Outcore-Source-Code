local RunService = game:GetService("RunService")
local ConfigReader = require(script.Parent.Parent.ConfigReader)

local billboardAdUnits = ConfigReader:read("Ads")
local _3dAdUnits = ConfigReader:read("Ads3D")
local portalAdUnits = ConfigReader:read("AdsPortals")

local function assertAdUnitNames(adUnits)
	local nameDictionary = {}

	for _, unit in pairs(adUnits) do
		local unitName = unit:GetFullName()

		if nameDictionary[unitName] then
			if RunService:IsServer() then
				error("[Superbiz] There is a duplicate ad unit named: \"" .. unitName .. "\"")
			end

			return true
		else
			nameDictionary[unitName] = true
		end
	end

	return false
end

local function assertBadStreamingEnabledSetup()
	local totalAdUnits = #ConfigReader:read("Ads") + #ConfigReader:read("Ads3D") + #ConfigReader:read("AdsPortals")

	if totalAdUnits > 0 and workspace.StreamingEnabled then
		if RunService:IsServer() then
			error("[SuperBiz] You can't load ads through the config while having StreamingEnabled")
		end

		return true
	end

	return false
end

return function()
	if assertBadStreamingEnabledSetup() then
		return true
	end

	local badNames = assertAdUnitNames(billboardAdUnits) or assertAdUnitNames(_3dAdUnits) or assertAdUnitNames(portalAdUnits)
	if badNames then
		return true
	end

	return false
end