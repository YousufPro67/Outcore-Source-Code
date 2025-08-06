-- Custom Mesh Part Rigs Script
local ViewAccessories = false
local ViewModels = false

local Plr = game.Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Human = Char:WaitForChild("Humanoid")
local Cam = game.Workspace.CurrentCamera

Plr.CameraMaxZoomDistance = 400
Plr.CameraMinZoomDistance = 0.5
Human.CameraOffset = Vector3.new(0, -0.25, -1.5)

local function Lock(part, isZoomedIn)
	if part and (part:IsA("BasePart") or part:IsA("MeshPart")) then
		if isZoomedIn and (part.Name == "Head" or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part:IsDescendantOf(Char.Head) or part:IsDescendantOf(Char.Torso)) then
			part.LocalTransparencyModifier = 1
		else
			part.LocalTransparencyModifier = part.Transparency
		end
		part.Changed:Connect(function(property)
			if isZoomedIn and (part.Name == "Head" or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part:IsDescendantOf(Char.Head) or part:IsDescendantOf(Char.Torso)) then
				part.LocalTransparencyModifier = 1
			else
				part.LocalTransparencyModifier = part.Transparency
			end
		end)
	end
end

local function UpdateTransparency()
	local zoomLevel = Cam.CFrame.Position - Cam.Focus.Position
	local zoomDistance = zoomLevel.Magnitude
	local isZoomedIn = zoomDistance <= Plr.CameraMinZoomDistance

	for _, v in pairs(Char:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") then
			Lock(v, isZoomedIn)
		end
	end
end

Cam.Changed:Connect(function(property)
	if property == "CFrame" then
		UpdateTransparency()
	elseif property == "CameraSubject" then
		if Cam.CameraSubject and Cam.CameraSubject:IsA("VehicleSeat") and Human then
			Cam.CameraSubject = Human
		end
	end
end)

Char.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") or child:IsA("MeshPart") then
		Lock(child, Cam.CFrame.Position - Cam.Focus.Position.Magnitude <= Plr.CameraMinZoomDistance)
	end
end)

UpdateTransparency()
