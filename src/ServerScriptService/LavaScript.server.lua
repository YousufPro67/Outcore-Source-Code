--------------------------------------------------------------

-- || Server-Sided Script

--------------------------------------------------------------




-- // SERVICES
--------------------------------------------------------------
local _CS = game.CollectionService


-- // VARIABLE REFERENCE
--------------------------------------------------------------

local _DAMAGE = 100

-- // FUNCTIONS
--------------------------------------------------------------

local function TakeDamage(plr:Player,damage)
	local chr = plr.Character
	local hum = chr:FindFirstChildOfClass("Humanoid")
	hum:ChangeState(Enum.HumanoidStateType.Dead)
end

-- // STARTUP
--------------------------------------------------------------



-- // MAIN SCRIPT
--------------------------------------------------------------

for _,obj in _CS:GetTagged("Lava") do
	obj.Touched:Connect(function(otherPart: BasePart) 
		local partParent = otherPart.Parent
		local humanoid = partParent:FindFirstChild("Humanoid")
		if humanoid then
			TakeDamage(game.Players:GetPlayerFromCharacter(partParent),_DAMAGE)
		end
	end)
end

--[[

--------------------------------------------------------------
N O T E S
--------------------------------------------------------------

 - 

]]