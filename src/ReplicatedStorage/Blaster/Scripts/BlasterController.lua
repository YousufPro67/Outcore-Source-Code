local Players = game:GetService("Players")
local knit = require(game.ReplicatedStorage.Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Blaster.Constants)
local TouchInputController = require(script.Parent.TouchInputController)
local CameraRecoiler = require(script.Parent.CameraRecoiler)
local ViewModelController = require(script.Parent.ViewModelController)
local CharacterAnimationController = require(script.Parent.CharacterAnimationController)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local getRayDirections = require(script.Parent.Parent.Utility.getRayDirections)
local drawRayResults = require(script.Parent.Parent.Utility.drawRayResults)
local castRays = require(script.Parent.Parent.Utility.castRays)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage.Blaster.Remotes
local shootRemote = remotes.Shoot

local random = Random.new()

local BlasterController = {}
BlasterController.__index = BlasterController

function BlasterController.new(blaster: Tool)
	local viewModelController = ViewModelController.new(blaster)
	local touchInputController = TouchInputController.new(blaster)
	local characterAnimationController = CharacterAnimationController.new(blaster)

	local self = {
		blaster = blaster,
		viewModelController = viewModelController,
		touchInputController = touchInputController,
		characterAnimationController = characterAnimationController,
		activated = false,
		equipped = false,
		shooting = false,
		connections = {},
	}
	setmetatable(self, BlasterController)

	self:initialize()

	return self
end

function BlasterController:isHumanoidAlive(): boolean
	return self.humanoid and self.humanoid.Health > 0
end

function BlasterController:canShoot(): boolean
	return self:isHumanoidAlive() and self.equipped 
end



function BlasterController:recoil()
	local recoilMin = self.blaster:GetAttribute(Constants.RECOIL_MIN_ATTRIBUTE)
	local recoilMax = self.blaster:GetAttribute(Constants.RECOIL_MAX_ATTRIBUTE)

	local xDif = recoilMax.X - recoilMin.X
	local yDif = recoilMax.Y - recoilMin.Y
	local x = recoilMin.X + random:NextNumber() * xDif
	local y = recoilMin.Y + random:NextNumber() * yDif

	local recoil = Vector2.new(math.rad(-x), math.rad(y))

	CameraRecoiler.recoil(recoil)
end

function BlasterController:shoot()
	local spread = self.blaster:GetAttribute(Constants.SPREAD_ATTRIBUTE)
	local raysPerShot = self.blaster:GetAttribute(Constants.RAYS_PER_SHOT_ATTRIBUTE)
	local range = self.blaster:GetAttribute(Constants.RANGE_ATTRIBUTE)
	local rayRadius = self.blaster:GetAttribute(Constants.RAY_RADIUS_ATTRIBUTE)

	self.viewModelController:playShootAnimation()
	self.characterAnimationController:playShootAnimation()
	self:recoil()




	local now = Workspace:GetServerTimeNow()
	local origin = camera.CFrame

	local rayDirections = getRayDirections(origin, raysPerShot, math.rad(spread), now)
	for index, direction in rayDirections do
		rayDirections[index] = direction * range
	end

	local rayResults = castRays(player, origin.Position, rayDirections, rayRadius)

	-- Rather than passing the entire table of rayResults to the server, we'll pass the shot origin and a list of tagged humanoids.
	-- The server will then recalculate the ray directions from the origin and validate the tagged humanoids.
	-- Strings are used for the indices since non-contiguous arrays do not get passed over the network correctly.
	-- (This may be non-contiguous in the case of firing a shotgun, where not all of the rays hit a target)
	local tagged = {}
	local didTag = false
	for index, rayResult in rayResults do
		if rayResult.taggedHumanoid then
			tagged[tostring(index)] = rayResult.taggedHumanoid
			didTag = true
		end
	end

	

	shootRemote:FireServer(now, self.blaster, origin, tagged)

	local muzzlePosition = self.viewModelController:getMuzzlePosition()
	drawRayResults(muzzlePosition, rayResults)
end

function BlasterController:startShooting()

	

	if not self:canShoot() then
		return
	end

	if self.shooting then
		return
	end

	local fireMode = self.blaster:GetAttribute(Constants.FIRE_MODE_ATTRIBUTE)
	local rateOfFire = self.blaster:GetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE)

	if fireMode == Constants.FIRE_MODE.SEMI then
		self.shooting = true
		self:shoot()
		task.delay(60 / rateOfFire, function()
			self.shooting = false

			
		end)
	elseif fireMode == Constants.FIRE_MODE.AUTO then
		task.spawn(function()
			self.shooting = true
			while self.activated and self:canShoot() do
				self:shoot()
				task.wait(60 / rateOfFire)
			end
			self.shooting = false

			
		end)
	end
end



function BlasterController:activate()
	if self.activated then
		return
	end
	self.activated = true

	self:startShooting()
end

function BlasterController:deactivate()
	if not self.activated then
		return
	end
	self.activated = false
end

function BlasterController:equip()
	if self.equipped then
		return
	end
	self.equipped = true

	



	-- Enable view model
	self.viewModelController:enable()

	-- Enable GUI



	-- Enable touch input controller
	self.touchInputController:enable()

	-- Enable character animations
	self.characterAnimationController:enable()

	-- Keep track of the humanoid in the character currently equipping the blaster.
	-- We need this to make sure the player can't shoot while dead.
	self.humanoid = self.blaster.Parent:FindFirstChildOfClass("Humanoid")
	
	if self.blaster.Name == "Blaster" then
		ReplicatedStorage.Blaster:SetAttribute("ActiveBlaster", "Blaster")
	elseif self.blaster.Name == "AutoBlaster" then
		ReplicatedStorage.Blaster:SetAttribute("ActiveBlaster", "AutoBlaster")
	end
end

function BlasterController:unequip()
	if not self.equipped then
		return
	end
	self.equipped = false

	-- Force deactivate the blaster when unequipping it
	self:deactivate()

	
	if self.reloadTask then
		task.cancel(self.reloadTask)
		self.reloadTask = nil
	end

	-- Disable view model
	self.viewModelController:disable()

	-- Disable GUI


	-- Disable touch input controller
	self.touchInputController:disable()

	-- Disable character animations
	self.characterAnimationController:disable()
end

function BlasterController:initialize()
	local blasterdebounce = false
	table.insert(
		self.connections,
		self.blaster.Equipped:Connect(function()
			self:equip()
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Unequipped:Connect(function()
			self:unequip()
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Activated:Connect(function()
			if self.blaster.Name == "Blaster" then if blasterdebounce then return end end
			self:activate()
			local hrp:BasePart = player.Character.HumanoidRootPart
			local mouse = player:GetMouse()
			local target = mouse.Target
			local hit = mouse.Hit
			local module = knit.GetService("ExplosionService")
			if target == nil then return end
			local distance = (hit.Position - hrp.CFrame.Position).magnitude
			local direction = (hit.Position - Workspace.CurrentCamera.CFrame.Position).Unit
			local explosives = workspace:FindFirstChild("OutcoreStorage"):FindFirstChild("Explosives")
			local function checker()
				if not target:IsDescendantOf(player.Character) then
					if self.blaster.Name == "Blaster" then
						if not blasterdebounce then
							local exp = Instance.new("Explosion")
							blasterdebounce = true
							exp.Parent = Workspace
							exp.BlastRadius = 10
							exp.Position = mouse.Hit.Position
							exp.DestroyJointRadiusPercent = 0
							exp.BlastPressure = 500000
							exp.ExplosionType = Enum.ExplosionType.Craters
							exp.Visible = false
							exp.Hit:Connect(function(hit)
								local o = hit:FindFirstAncestorOfClass("Model")
								if o then
									if o:FindFirstChildOfClass("Humanoid") then
										if o ~= player.Character then
											o:FindFirstChildOfClass("Humanoid"):TakeDamage(100)
										end
									end
								end
							end)
							task.wait(0.1)
							exp:Destroy()
							wait(1)
							blasterdebounce = false
						end
					end
				end
			end
			if explosives then
				if target:IsDescendantOf(explosives) then
					module:explode(target:FindFirstAncestorOfClass("Model"))
				else
					checker()
				end
			else
				checker()
			end
			
			
		   
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Deactivated:Connect(function()
			self:deactivate()
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputBegan:Connect(function(inputObject: InputObject, processed: boolean)
			if processed then
				return
			end
		end)
	)


end

function BlasterController:destroy()
	self:unequip()
	disconnectAndClear(self.connections)
	self.viewModelController:destroy()
	self.touchInputController:destroy()
	self.characterAnimationController:destroy()
end

return BlasterController
