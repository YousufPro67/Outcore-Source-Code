--------------------------------------------------------------

-- ||  ModuleScript

--------------------------------------------------------------




-- // SERVICES
--------------------------------------------------------------

local _REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local _KNIT = require(_REPLICATED_STORAGE.Packages.Knit)
local Module = _KNIT.CreateService({
	Name = "ClientData",
	Client = {}
})
--_KNIT.Start():await()

-- // VARIABLE REFERENCE
--------------------------------------------------------------

local _MANAGER = require(script.Parent.PlayerDataManager)
local _SETTINGS_EXCLUDED = {
	"LEVELS"
}

-- // FUNCTIONS
--------------------------------------------------------------

function Module.Client:SET(PLR,NAME,VAL)
	if _SETTINGS_EXCLUDED[NAME] == nil then
		_MANAGER:Set(PLR,NAME,VAL)
	end
end

-- // STARTUP
--------------------------------------------------------------



-- // MAIN SCRIPT
--------------------------------------------------------------





return Module



--[[

--------------------------------------------------------------
N O T E S
--------------------------------------------------------------

 - Script to prevent exploiters

]]