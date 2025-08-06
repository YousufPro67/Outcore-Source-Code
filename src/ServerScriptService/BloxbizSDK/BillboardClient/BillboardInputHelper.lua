local UserInputService = game:GetService("UserInputService")

local ConfigReader = require(script.Parent.Parent.ConfigReader)
local RaycastModule = require(script.Parent.Raycast)
local Raycaster = nil

local RAYCAST_MAX_DISTANCE = 5_000

local LocalPlayer = game.Players.LocalPlayer
local playerMouse = LocalPlayer:GetMouse()

local activeBillboards = {}
local loopRunning = false
local lastBillboard = nil

local BillboardInputHelper = {}

function BillboardInputHelper:addBillboard(part)
	if activeBillboards[part] then
		return
	end

	activeBillboards[part] = true
end

function BillboardInputHelper:removeBillboard(part)
	if activeBillboards[part] then
		activeBillboards[part] = nil
	end
end

function BillboardInputHelper:updateRaycasting()
	local raycastParams = RaycastParams.new()
	local raycastFilterList = ConfigReader:read("RaycastFilterList")()
	raycastParams.FilterType = ConfigReader:read("RaycastFilterType")
	raycastParams.FilterDescendantsInstances = raycastFilterList

	Raycaster = RaycastModule.new(raycastParams, 0, false, false, 0, 1)
end

function BillboardInputHelper:isMouseOnBillboard()
	local billboard = nil

	self:updateRaycasting()

	for part, _ in pairs(activeBillboards) do
		local camera = workspace.CurrentCamera
		local _, onScreen = camera:WorldToViewportPoint(part.Position)

		if onScreen then
			local ray = camera:ScreenPointToRay(playerMouse.X, playerMouse.Y, 0)
			local result = Raycaster:Raycast(ray.Origin, ray.Direction * RAYCAST_MAX_DISTANCE)

			if result and activeBillboards[result.Instance] then
				billboard = result.Instance
				break
			end
		end
	end

	return billboard
end

function BillboardInputHelper:detectMouseClicks()
	UserInputService.InputBegan:Connect(function(input)
		local clicked = input.UserInputType == Enum.UserInputType.MouseButton1
		local touched = input.UserInputType == Enum.UserInputType.Touch

		if clicked or touched then
			local currentBillboard = self:isMouseOnBillboard()

			if currentBillboard then
				self.mouseClick:Fire(currentBillboard)
			end
		end
	end)
end

function BillboardInputHelper:runDetectionLoop()
	if loopRunning then
		return
	end

	loopRunning = true

	while true do
		--only minor lag spikes with 400 billboards
		task.wait(0.1)

		if playerMouse.Target == nil then
			continue
		end

		local currentBillboard = self:isMouseOnBillboard()

		if lastBillboard ~= currentBillboard then
			if lastBillboard ~= nil then
				self.mouseLeft:Fire(lastBillboard)
			end

			if currentBillboard ~= nil then
				self.mouseEntered:Fire(currentBillboard)
			end

			lastBillboard = currentBillboard
		end
	end
end

function BillboardInputHelper:init()
	self.mouseClick = Instance.new("BindableEvent")
	self.mouseEntered = Instance.new("BindableEvent")
	self.mouseLeft = Instance.new("BindableEvent")

	self:detectMouseClicks()

	task.spawn(self.runDetectionLoop, self)
end

BillboardInputHelper:init()

return BillboardInputHelper
