local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local New = Fusion.New

local BOOMBOX_MESH_ID = "rbxassetid://13894568565"

local BoomboxModel = {}

BoomboxModel.__index = BoomboxModel

function BoomboxModel.new(textureId: string, owner: Player)
	local self = setmetatable({}, BoomboxModel)

	self._owner = owner
	self._asset = self:_makeAsset(textureId)
	self._connections = {}

	self._visible = false

	table.insert(
		self._connections,
		owner.CharacterAdded:Connect(function()
			if not self._visible then
				return
			end
			task.wait(0.5)

			self:Show()
		end)
	)

	table.insert(
		self._connections,
		owner.CharacterRemoving:Connect(function()
			self:Hide(true)
		end)
	)

	return self
end

function BoomboxModel:Show()
	if self._visible then
		return
	end

	self._visible = true

	local character = self._owner.Character

	local gripAttachment = character:FindFirstChild("RightGripAttachment", true)
	self._asset.CFrame = gripAttachment.WorldCFrame
	self._asset.RigidConstraint.Attachment1 = gripAttachment

	self._asset.Parent = character
end

function BoomboxModel:Hide(dontSetFlag: boolean)
	if not self._visible then
		return
	end

	if not dontSetFlag then
		self._visible = false
	end

	self._asset.Parent = nil
end

function BoomboxModel:Destroy()
	if self._asset then
		self._asset:Destroy()
	end

	for _, connection in self._connections do
		connection:Disconnect()
	end
end

function BoomboxModel:_makeAsset(textureId: string)
	local boombox = New("Part")({
		Name = "BoomboxModel",
		Size = Vector3.new(2.2, 1.2, 0.5),
		CanCollide = false,
		Massless = true,
	})

	local attachment = New("Attachment")({
		CFrame = CFrame.new(0, boombox.Size.Y / 2, 0) * CFrame.Angles(math.rad(90), math.rad(180), math.rad(-90)),
		Parent = boombox,
	})

	New("RigidConstraint")({
		Attachment0 = attachment,
		Parent = boombox,
	})

	New("SpecialMesh")({
		MeshId = BOOMBOX_MESH_ID,
		TextureId = textureId,
		Scale = Vector3.new(0.05, 0.05, 0.05),
		Parent = boombox,
	})

	return boombox
end

return BoomboxModel
