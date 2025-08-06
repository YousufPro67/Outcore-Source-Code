local RunService = game:GetService("RunService")

local FunctionQueue = {}
FunctionQueue.__index = FunctionQueue

function FunctionQueue.new(Interval, CallsPerInterval)
    local self = setmetatable({
        Interval = Interval,
        CallsLeft = CallsPerInterval,
        CallsPerInterval = CallsPerInterval,
        LastCallsRefresh = 0,

        Queue = {},
        QueueConnection = nil,
	}, FunctionQueue)

	return self
end

function FunctionQueue:Add(Function)
    local CalledEvent = Instance.new("BindableEvent")
    table.insert(self.Queue, {Function = Function, Called = CalledEvent})

    if not self.QueueConnection then
        self.QueueConnection = RunService.Heartbeat:Connect(function()
            if #self.Queue == 0 then return end

            if self.LastCallsRefresh + self.Interval < tick() then
                self.CallsLeft = self.CallsPerInterval
                self.LastCallsRefresh = tick()
            end

            local RemoveIndexes = {}

            if self.CallsLeft <= 0 then return end

            for Index, FunctionData in self.Queue do
                task.spawn(function()
                    FunctionData.Function()
                    FunctionData.Called:Fire()
                    FunctionData.Called:Destroy()
                    FunctionData.Called = nil
                end)
                table.insert(RemoveIndexes, Index)

                self.CallsLeft -= 1
                if self.CallsLeft <= 0 then break end
            end

            for _, Index in RemoveIndexes do
                table.remove(self.Queue, Index)
            end
        end)
    end

    return CalledEvent.Event
end

function FunctionQueue:Destroy()
    if self.QueueConnection then
        self.QueueConnection:Disconnect()
        self.QueueConnection = nil
    end
end

return FunctionQueue