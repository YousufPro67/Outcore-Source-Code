local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
API = knit.CreateService({
	Name = "CounterService",
	Client = {},
	Counters = {},
	Timers = {}
})
--Counter--
function API:CreateCounter(name : string)
	local C = {
		Count = 0
	}
	API.Counters[name] = C
end
function API:GetCounter(name : string,name2)
	if typeof(name) ~= "Player" then
		return API.Counters[name]
	else
		return API.Counters[name2]
	end
end
function API:RemoveCounter(name : string)
	API.Counters[name] = nil
end
function API:UpdateCounter(name : string, Count : number)
	local C = API.Counters[name]
			API.Counters[name].Count += Count
end
function API:ResetCounter(name : string)
	local C = API.Counters[name]
	C.Count = 0
end
--Timers--
function API:CreateTimer(name : string)
	local C = {
		StartTime = 0,
		Running = false,
		Paused = false,
		PauseTime = 0,
		Minutes = 0,
		Seconds = 0,
		Milliseconds = 0
	}
	API.Timers[name] = C
end
function API:UpdateTimer(name : string)
	local C = API.Timers[name]
	if typeof(name) == "Instance" and name:IsA("Player") then
		C = API.Timers[name.UserId]
	end
		local elapsed
		if C.Paused then
			elapsed = C.PauseTime - C.StartTime
		else
			elapsed = tick() - C.StartTime
		end
		C.Minutes = math.floor(elapsed / 60)
		C.Seconds = math.floor(elapsed % 60)
		C.Milliseconds = math.floor((elapsed % 1) * 100)
end
function API:GetTimer(name,name2)
	if typeof(name) == "Instance" and name:IsA("Player") then
	    return API.Timers[name2]
	else
		return API.Timers[name]
	end
end
function API:RemoveTimer(name : string)
	if typeof(name) == "Instance" and name:IsA("Player") then
		API.Timers[name.UserId] = nil
	else
		API.Timers[name] = nil
	end
end
function API:ResetTimer(name : string)
	local C = API.Timers[name]
	if typeof(name) == "Instance" and name:IsA("Player") then
		C = API.Timers[name.UserId]
	end
	C.Minutes = 0
	C.Seconds = 0
	C.Milliseconds = 0
end
function API:PauseTimer(name)
	local C = API.Timers[name]
	if typeof(name) == "Instance" and name:IsA("Player") then
		C = API.Timers[name.UserId]
	end
	if C.Running and not C.Paused then
		C.PauseTime = tick()
		C.Paused = true
	end
end
function API:StartTimer(name)
	local C = API.Timers[name]
		if typeof(name) == "Instance" and name:IsA("Player") then
			C = API.Timers[name.UserId]
		end
		if not C.Running then
			C.StartTime = tick()
			C.Running = true
			C.Paused = false
		elseif C.Paused then
			local pauseDuration = tick() - C.PauseTime
			C.StartTime = C.StartTime + pauseDuration
			C.Paused = false
		end
end
function API:StopTimer(name:string)
	local C = API.Timers[name]
	if typeof(name) == "Instance" and name:IsA("Player") then
		C = API.Timers[name.UserId]
	end
	if C.Running then
		C.Running = false
		C.Paused = false
		C.PauseTime = 0
		C.StartTime = 0
		C.Minutes = 0
		C.Seconds = 0
		C.Milliseconds = 0
	end
end
for k,v in pairs(API) do
	API.Client[k] = v
end
return API