local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FocusChangedEvent = ReplicatedStorage.Styngr:WaitForChild("FocusChangedEvent")

local AppStateService = {}

function AppStateService:Init()
	self._appStateInfo = {}
	self._currentAppStateInfo = nil

	UserInputService.WindowFocusReleased:Connect(function()
		self:_onGameFocusChanged(false)
	end)

	UserInputService.WindowFocused:Connect(function()
		self:_onGameFocusChanged(true)
	end)

	return self
end

function AppStateService:_onGameFocusChanged(isVisible)
	assert(isVisible ~= nil, "isVisible cannot be nil!")

	FocusChangedEvent:FireServer(isVisible)
end

return AppStateService
