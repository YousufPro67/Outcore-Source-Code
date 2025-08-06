--[[local aim = script.Parent.LocalScript.GrappleAim
script.Parent.RemoteEvent.OnServerEvent:Connect(function(plr,target)
	script.Parent.LocalScript.Target.Value = target or script.Parent.LocalScript
	aim.Parent = target or script.Parent.LocalScript
end)]]
wait()
local Player = game.Players:GetPlayerFromCharacter(script.Parent.Parent)
if not Player then
	Player = script.Parent.Parent.Parent
end
local HumanoidRootPart = Player.Character:WaitForChild("HumanoidRootPart")

local aim = script.Parent.LocalScript.GrappleAim
aim.Parent = workspace.VFX
aim.Name = Player.UserId.. aim.Name

local slashvfx1 = script.Parent.Handle.SlashVFX:WaitForChild("vfx1",5):Clone()
local slashvfx2 = script.Parent.Handle.SlashVFX:WaitForChild("vfx2",5):Clone()
local newvfxpart = Instance.new("Part")
newvfxpart.Parent = workspace.VFX
newvfxpart.CanCollide = false
newvfxpart.CanQuery = false
newvfxpart.CanTouch = false
newvfxpart.Name =  Player.UserId.."VFXGrapple"
newvfxpart.Size = HumanoidRootPart.Size
newvfxpart.Transparency = 1
newvfxpart.Massless = true

local vfxweld = Instance.new("Weld")
vfxweld.Parent = newvfxpart
vfxweld.Part0 = HumanoidRootPart
vfxweld.Part1 = newvfxpart
vfxweld.C1 = vfxweld.C1 * CFrame.Angles(0,0,35)

slashvfx1.Parent = newvfxpart
slashvfx2.Parent = newvfxpart

wait(0.1)
script.Parent.RemoteEvent:FireClient(Player)