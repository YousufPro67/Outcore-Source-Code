local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FocusChangedEvent = ReplicatedStorage.Styngr.FocusChangedEvent

local AppStates = require(script.Parent.Parent.AppStates)

local AppState = {}

function AppState:init()
	self._info = {}

	FocusChangedEvent.OnServerEvent:Connect(function(player, isVisible)
		self._info[player.UserId] = isVisible
	end)
end

function AppState:Get(player: Player): string
	if self._info[player.UserId] == nil then
		return AppStates.NONE_APP_STATE
	end

	return if self._info[player.UserId] == true then AppStates.OPEN else AppStates.BACKGROUND
end

function AppState:GetStart(player: Player): string
	return if self._info[player.UserId] == true then AppStates.ACTIVE else AppStates.BACK
end

AppState:init()

return AppState
