--------------------------------------------------------------

-- || Server-Sided Script

--------------------------------------------------------------




-- // SERVICES
--------------------------------------------------------------

local _REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local _PLAYERS = game:GetService("Players")

-- // VARIABLE REFERENCE
--------------------------------------------------------------

local _ANIMATE = _REPLICATED_STORAGE:WaitForChild("Animate")

-- // FUNCTIONS
--------------------------------------------------------------

function _CHANGE_PLAYER_ANIMATION(CHAR : Model)
	if CHAR:FindFirstChild("Animate") then
		CHAR.Animate:Destroy()
	end
	_ANIMATE.Parent = CHAR
end	
function _PLAYER_ADDED(PLR : Player)
	if PLR.Character then
		_CHANGE_PLAYER_ANIMATION(PLR.Character)
	end
	PLR.CharacterAdded:Connect(function(CHAR : Model)
		_CHANGE_PLAYER_ANIMATION(CHAR)
	end)
end

-- // MAIN SCRIPT
--------------------------------------------------------------

_PLAYERS.PlayerAdded:Connect(_PLAYER_ADDED)

--[[

--------------------------------------------------------------
N O T E S
--------------------------------------------------------------

 - This script changes the default roblox animattions into
   custom Outcore Animations.

]]