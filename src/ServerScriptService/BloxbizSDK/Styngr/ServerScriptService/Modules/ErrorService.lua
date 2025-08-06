local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.BloxbizSDK.Utils.Promise)

local Endpoints = require(script.Parent.Endpoints)

local MAX_RETRIES = 10
local TIME_BETWEEN_RETRIES = 120 -- in seconds

local ErrorService = {}

function ErrorService:Init(cloudService)
	self._cloudService = cloudService
end

function ErrorService:Send(message, data)
	local traceback = debug.traceback()
	local toSend = HttpService:JSONEncode({ message = message, data = data, traceback = traceback })
	Promise.retryWithDelay(function()
		return self._cloudService:Call(nil, Endpoints.Error, { message = toSend })
	end, MAX_RETRIES, TIME_BETWEEN_RETRIES):catch(function(error)
		warn("Can't send error report: ", error)
	end)
end

return ErrorService
