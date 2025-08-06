local anim = script.Animation
local track = script.Parent.Humanoid:LoadAnimation(anim)
track.Looped = true
track:Play()
script.Parent.HumanoidRootPart.Anchored = true

