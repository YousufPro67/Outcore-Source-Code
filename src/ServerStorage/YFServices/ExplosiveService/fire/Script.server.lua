on = true
local t = math.random(5,10)
spawn(function()
	while on do
		wait(0.5)
		if script.Parent.Parent.Parent:findFirstChild("Humanoid")~= nil then
			script.Parent.Parent.Parent:findFirstChild("Humanoid"):TakeDamage((math.random(1,10)/math.random(3,7)))
		end
		
	end
end)
spawn(function()
while on do
	wait(1)
local b=script.Parent.Parent:GetTouchingParts()
local c=script.Parent.Parent:GetConnectedParts()

for i = 1 ,#b do
	if b[i]:findFirstChild("fire") == nil and b[i].Anchored==false then
	if math.random(1,5) == 1 then
	local	boi = script.Parent:Clone()
	if b[i]:GetMass()>10 then
		boi.Rate = (b[i]:GetMass())^0.7
		else
		boi.Rate = (b[i]:GetMass())*10
		end
	boi.Size = NumberSequence.new((b[i]:GetMass()^0.3)+1.75,0)
	boi.Acceleration = Vector3.new(0,(b[i]:GetMass()/15)+25,0)
		boi.Enabled=true
		boi.Parent = b[i]
		boi.Script.Disabled=false
	end
	end
end
for i = 1 ,#c do
	if c[i]:findFirstChild("fire") == nil and c[i].Anchored==false then
	if math.random(1,5) == 1 then
	local	boi = script.Parent:Clone()
		if c[i]:GetMass()>10 then
		boi.Rate = (c[i]:GetMass())^0.7
		else
		boi.Rate = (c[i]:GetMass())*10
		end
		boi.Rate = (c[i]:GetMass())^0.9
		boi.Size = NumberSequence.new((c[i]:GetMass()^0.3)+1.75,0)
		boi.Acceleration = Vector3.new(0,(c[i]:GetMass()/15)+25,0)
		boi.Enabled=true
		boi.Parent = c[i]
		boi.Script.Disabled=false
	end
	end
end
end
end)
function feet(hit)--gettouchingparts is bad at detecting feet :(
	local hum = hit.Parent:findFirstChild("Humanoid")
	local foire = hit:findFirstChild("fire")
	if math.random(1,3) == 1 and hum~= nil and foire == nil and on == true then
		local	boi = script.Parent:Clone()
		boi.Rate = (hit:GetMass())*10
		boi.Size = NumberSequence.new((hit:GetMass()/90)+1.75,0)
		boi.Enabled=true
		boi.Parent = hit
		boi.Script.Disabled=false
	end
end
script.Parent.Parent.Touched:connect(feet)
spawn(function()
	for i = 1,t*2 do
		local r = script.Parent.Parent.Color.r*0.93
		local g = script.Parent.Parent.Color.g*0.93
		local b = script.Parent.Parent.Color.b*0.93
		script.Parent.Parent.Color = Color3.new(r,g,b)
		wait(0.5)
	end
end)

spawn(function()
	while true do
		wait(0.5)
		if math.random(1,50) == 1 and script.Parent.Parent.Parent:findFirstChild("Humanoid")== nil then
			script.Parent.Parent:BreakJoints()
		end
	end
end)
wait(t)

on = false
script.Parent.Enabled=false
local hum = script.Parent.Parent.Parent:findFirstChild("Humanoid")
if hum ~= nil then
	wait(6)
	script.Parent:Remove()--remove tag early for players
end


wait(60)
--keep the fire tag for a while so parts that were recently set on fire dont get set on fire repeatedly,
--making an endless flame loop
script.Parent:remove()