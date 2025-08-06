local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("BLOXBIZ_EXPOSURE_STORAGE")

local Utils = require(script.Parent.Parent.Utils)

local WAIT_FOR_DATA_TIMEOUT = 10 --seconds

local FrequencyCapper = {}
FrequencyCapper.LocalExposureStorage = {}

--]] https://devforum.roblox.com/t/how-to-check-if-were-in-daylight-savings-time/
function FrequencyCapper:IsDaylightSavings()
	local weekdayNumber = tonumber(os.date("%w"))

	local isSunday = weekdayNumber == 7

	local month = tonumber(os.date("%m"))
	local monthDay = tonumber(os.date("%d"))

	local isDaylightSavingsTime

	local inSummerOrFall = month > 3 and month < 11

	local inMarch = month == 3
	local inMarchAndDayValid = (inMarch and monthDay >= 8) and (isSunday or monthDay >= 14)

	local inNovember = month == 11
	local inNovemberAndDayValid = (inNovember and monthDay < 7 and not isSunday)

	if inSummerOrFall or inMarchAndDayValid or inNovemberAndDayValid then
		isDaylightSavingsTime = true
	else
		isDaylightSavingsTime = false
	end

	return isDaylightSavingsTime
end

function FrequencyCapper:GetTimeDataEST()
	local currentSecondsUTC = os.time()
	local isDaylightSavings = FrequencyCapper:IsDaylightSavings()
	local hoursOffset = (isDaylightSavings and 4) or 5
	local currentSecondsEST = currentSecondsUTC - (hoursOffset * 60 * 60)

	local timeData = DateTime.fromUnixTimestamp(currentSecondsEST)
	timeData = timeData:ToUniversalTime()

	return timeData
end

function FrequencyCapper:IsSameDay(timeData)
	local currentTimeData = FrequencyCapper:GetTimeDataEST()

	local sameYear = currentTimeData.Year == timeData.Year
	local sameMonth = currentTimeData.Month == timeData.Month
	local sameDay = currentTimeData.Day == timeData.Day

	if sameYear and sameMonth and sameDay then
		return true
	else
		return false
	end
end

function FrequencyCapper:GetDataTemplate()
	return {
		TimeData = FrequencyCapper:GetTimeDataEST(),
		Exposures = {},
	}
end

function FrequencyCapper:FetchExposureData(playerId)
	local success, result = pcall(function()
		return DataStore:GetAsync(playerId)
	end)

	local isNewPlayer = success and result == nil

	if not success then
		Utils.pprint("[SuperBiz] Exposure DataStore fetch failure: " .. result)
		result = FrequencyCapper:GetDataTemplate()
	elseif isNewPlayer then
		result = FrequencyCapper:GetDataTemplate()
	end

	FrequencyCapper.LocalExposureStorage[playerId] = result
	FrequencyCapper:RefreshExposures(playerId)

	return success
end

function FrequencyCapper:SaveExposureData(playerId)
	local exposureData = FrequencyCapper.LocalExposureStorage[playerId]

	if not exposureData then
		return
	end

	FrequencyCapper:RefreshExposures(playerId)

	local success, result = pcall(function()
		return DataStore:SetAsync(playerId, exposureData)
	end)

	if not success then
		Utils.pprint("[SuperBiz] Exposure DataStore save failure: " .. result)
	end

	FrequencyCapper.LocalExposureStorage[playerId] = nil

	return success
end

function FrequencyCapper:getValidExposureTime(exposureData)
	local totalSeconds = 0

	local begunExposure = false
	local beginningOfExposure = -1

	for index, ray in ipairs(exposureData.rays) do
		local rayTimestamp = ray[1]
		local rayAngle = ray[2] or 90
		local adPercentageOfScreen = ray[3] or 0

		local angleGood = rayAngle <= 55
		local percentScreenGood = adPercentageOfScreen >= 1.5
		local isLastRay = index == #exposureData.rays

		if not begunExposure then
			if angleGood and percentScreenGood then
				beginningOfExposure = rayTimestamp
				begunExposure = true
			end
		else
			if not angleGood or not percentScreenGood or isLastRay then
				local endOfExposure = rayTimestamp
				begunExposure = false

				totalSeconds += endOfExposure - beginningOfExposure
			end
		end
	end

	return totalSeconds
end

function FrequencyCapper:RecordExposureFor10SecImpressions(exposureData)
	local totalSeconds = FrequencyCapper:getValidExposureTime(exposureData)

	local adIdString = tostring(exposureData.bloxbiz_ad_id)
	local playerId = exposureData.player_id

	local currentExposureCount = FrequencyCapper:GetAdExposureCount(playerId, adIdString)
	local exposureTable = FrequencyCapper.LocalExposureStorage[playerId].Exposures
	exposureTable[adIdString] = currentExposureCount + (totalSeconds / 10)
end

function FrequencyCapper:RecordExposureForXSecVideoPlays(playData, xSeconds)
	local adIdString = tostring(playData.bloxbiz_ad_id)
	local playerId = playData.player_id
	local secondsPlayed = playData.play_end_seconds or 0

	local currentExposureCount = FrequencyCapper:GetAdExposureCount(playerId, adIdString)
	local exposureTable = FrequencyCapper.LocalExposureStorage[playerId].Exposures

	if secondsPlayed >= xSeconds then
		exposureTable[adIdString] = currentExposureCount + 1
	end
end

function FrequencyCapper:RecordExposureForAudioAdPlayed(adData)
	local adIdString = tostring(adData.bloxbiz_ad_id)
	local playerId = adData.player_id

	local currentExposureCount = FrequencyCapper:GetAdExposureCount(playerId, adIdString)
	local exposureTable = FrequencyCapper.LocalExposureStorage[playerId].Exposures

	exposureTable[adIdString] = currentExposureCount + 1
end

function FrequencyCapper:WaitForDataReady(playerId)
	local start = tick()
	local hasData = FrequencyCapper.LocalExposureStorage[playerId]
	local hasTimedOut = false

	while not hasData and not hasTimedOut do
		hasData = FrequencyCapper.LocalExposureStorage[playerId]
		hasTimedOut = tick() - start > WAIT_FOR_DATA_TIMEOUT
		RunService.Stepped:Wait()
	end

	if hasTimedOut then
		local resetData = FrequencyCapper:GetDataTemplate()
		FrequencyCapper.LocalExposureStorage[playerId] = resetData
	end
end

function FrequencyCapper:RefreshExposures(playerId)
	local exposureData = FrequencyCapper.LocalExposureStorage[playerId]
	local timeData = exposureData.TimeData

	if not FrequencyCapper:IsSameDay(timeData) then
		local resetData = FrequencyCapper:GetDataTemplate()
		FrequencyCapper.LocalExposureStorage[playerId] = resetData
	end
end

function FrequencyCapper:GetAdExposureCount(playerId, adId)
	FrequencyCapper:WaitForDataReady(playerId)
	FrequencyCapper:RefreshExposures(playerId)

	local adIdString = tostring(adId)
	local exposureData = FrequencyCapper.LocalExposureStorage[playerId].Exposures
	local adExposureCount = exposureData[adIdString]

	if not adExposureCount then
		adExposureCount = 0
		exposureData[adIdString] = adExposureCount
	end

	return adExposureCount
end

Players.PlayerAdded:Connect(function(player)
	FrequencyCapper:FetchExposureData(player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	FrequencyCapper:SaveExposureData(player.UserId)
end)

for _, player in pairs(game.Players:GetPlayers()) do
	FrequencyCapper:FetchExposureData(player.UserId)
end

return FrequencyCapper
