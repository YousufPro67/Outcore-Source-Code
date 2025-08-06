--Made by Kleos303--

local knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
knit.Start({ServicePromises = false}):await()
local plrData = knit.GetService("PlayerDataManager")

local ViewAccessories = false
local ViewModels = false

Plr = game.Players.LocalPlayer
local Char:Model = Plr.Character or Plr.CharacterAdded:wait()
Human = Char:WaitForChild("Humanoid")

Cam = game.Workspace.CurrentCamera
Plr.CameraMaxZoomDistance = 400
Plr.CameraMinZoomDistance = 0.5
Human.CameraOffset = Vector3.new(0,-0.25,-1.5)

local data = plrData:Get()
local function Lock (part:BasePart)
	if not data.SHOW_BODY then return end
	if part and part:IsA("BasePart") and part.Name ~= "Head" and part.Name ~= "Speed Lines" and part.Name ~= "Torso" and part.Name~="UpperTorso" and part.Name~="LowerTorso" and not part:IsDescendantOf(Char:FindFirstChild("Head")) and not part:IsDescendantOf(Char:FindFirstChild("Torso")) then
		part.LocalTransparencyModifier = part.Transparency
		part.Changed:connect(function (property)
			part.LocalTransparencyModifier = part.Transparency
		end)
	end
end
for i, v in pairs (Char:GetDescendants()) do
	if v:IsA("BasePart") then
		Lock(v)
	elseif v:IsA("Accessory") and ViewAccessories then
		if v:FindFirstChild("Handle") then
			Lock(v.Handle)
		end
	elseif v:IsA("Model") and ViewModels then
		for index, descendant in pairs (v:GetDescendants()) do
			if descendant:IsA("BasePart") then
				Lock(descendant)
			end
		end
	end
end
Char.ChildAdded:connect(Lock)
Cam.Changed:connect(function (property)
	if property == "CameraSubject" then
		if Cam.CameraSubject and Cam.CameraSubject:IsA("VehicleSeat") and Human then
			-- Vehicle seats try to change the camera subject to the seat itself. This isn't what want.
			Cam.CameraSubject = Human; end
	end
end)