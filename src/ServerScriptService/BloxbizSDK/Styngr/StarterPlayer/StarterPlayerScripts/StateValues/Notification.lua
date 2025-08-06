local Fusion = require(game:GetService("ReplicatedStorage").BloxbizSDK.Utils.Fusion)

local DURATION_SECONDS = 6

local Notification = Fusion.Value(nil)

function Notification:notify(message: string, durationSeconds: number)
	if not message then
		return
	end

	if not durationSeconds then
		durationSeconds = DURATION_SECONDS
	end

	task.delay(durationSeconds, function()
		self:close()
	end)

	Notification:set(message)
end

function Notification:close()
	local notification = self:get()

	if not notification then
		return
	end

	self:set(nil)
end

return Notification
