--------------------------------------------------------------

-- || Client-Sided LocalScript

--------------------------------------------------------------




-- // SERVICES
--------------------------------------------------------------

local _REPLICATED_STORAGE = game.ReplicatedStorage

-- // VARIABLE REFERENCE
--------------------------------------------------------------

local _PLAYER = game.Players.LocalPlayer
local _CAMERA = game.Workspace.CurrentCamera
local _WINDSFX = _REPLICATED_STORAGE.SFX.WindSFX
local _PREVIOUS_POSITION = _CAMERA.CFrame.Position
local _MAX_VOLUME = 1
local _MAX_SPEED = 750
local _CURRENT_VOLUME = 0

-- // FUNCTIONS
--------------------------------------------------------------

local function updateWindSound()
	local _CURRENT_POSITION = _CAMERA.CFrame.Position
	local velocity = (_CURRENT_POSITION - _PREVIOUS_POSITION).Magnitude / game:GetService("RunService").PreRender:Wait()
	local volume = math.clamp(velocity / _MAX_SPEED, 0, _MAX_VOLUME)
	_CURRENT_VOLUME = _CURRENT_VOLUME + (volume - _CURRENT_VOLUME) * 0.2
	_WINDSFX.Volume = _CURRENT_VOLUME
	_PREVIOUS_POSITION = _CURRENT_POSITION
end

-- // STARTUP
--------------------------------------------------------------

_WINDSFX.Looped = true
_WINDSFX.Parent = _CAMERA
_WINDSFX:Play()

-- // MAIN SCRIPT
--------------------------------------------------------------

game:GetService("RunService").PreRender:Connect(updateWindSound)

--[[

--------------------------------------------------------------
N O T E S
--------------------------------------------------------------

 - A SCRIPT FOR WIND SFX

]]