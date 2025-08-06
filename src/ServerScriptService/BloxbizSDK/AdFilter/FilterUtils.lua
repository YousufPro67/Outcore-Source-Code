--local HttpService = game:GetService('HttpService')

local Utils = require(script.Parent.Parent.Utils)

local FilterUtils = {}

function FilterUtils.CapIntegerValues(data)
	local integersToCap = {
		["lighting_fogend"] = 999999,
	}

	for item, maxInt in pairs(integersToCap) do
		data[item] = math.min(data[item], maxInt)
	end
end

function FilterUtils.CountDictionary(dict)
	local count = 0

	for _, _ in pairs(dict) do
		count += 1
	end

	return count
end

function FilterUtils.GetDeviceType(player)
	local vrEnabled = player["vr_enabled"]
	local isTenFootInterface = player["is_ten_foot_interface"]
	local accelerometerEnabled = player["accelerometer_enabled"]
	local gyroscopeEnabled = player["gyroscope_enabled"]
	local touchEnabled = player["touch_enabled"]
	local keyboardEnabled = player["keyboard_enabled"]
	local mouseEnabled = player["mouse_enabled"]

	if vrEnabled then
		return "vr"
	end

	if isTenFootInterface then
		return "console"
	end

	if touchEnabled and (accelerometerEnabled or gyroscopeEnabled) then
		return "mobile"
	end

	if touchEnabled and not keyboardEnabled and not mouseEnabled then
		return "mobile"
	end

	if keyboardEnabled and mouseEnabled then
		return "desktop"
	end

	return "unknown"
end

--[[
function FilterUtils.GetHexGUID()
    local hexGuid = ""
    local guid = HttpService:GenerateGUID()
    
    guid:gsub(".", function(char)
        hexGuid = hexGuid .. string.byte(char)
    end)

    hexGuid = string.format("%x", hexGuid)

    return hexGuid
end]]

function FilterUtils.GetPlayersGenderMultithreaded(playerIds)
	local playerGenders = {}

	for _, playerId in ipairs(playerIds) do
		playerGenders[playerId] = "Unknown"
	end

	--[[
    if #player_ids == 0 then
        return {}
    end

    local async_results = {}
    local player_genders = {}

    for _, player_id in ipairs(player_ids) do
        table.insert(async_results, pool.apply_async(get_player_gender, (player_id, )))
    end

    for player_id, async_result in pairs(zip(player_ids, async_results)) do
        player_genders[player_id] = async_result.get()
    end]]

	return playerGenders
end

--]] https://www.w3schools.com/python/ref_random_choices.asp
function FilterUtils.PythonChoices(list, weightsList, cumulativeWeights, k)
	local random = Random.new()

	local weightsListProcessed = cumulativeWeights

	if weightsList and not cumulativeWeights then
		weightsListProcessed = {}

		local cumulative = 0
		for _, weight in ipairs(weightsList) do
			cumulative += weight
			table.insert(weightsListProcessed, cumulative)
		end
	end

	local weightsSum = weightsListProcessed[#weightsListProcessed]
	local newList = {}

	local amount = k or 1
	for _ = 1, amount do
		local choice = random:NextNumber(0, weightsSum)
		local index = nil

		for possibleIndex, weight in ipairs(weightsListProcessed) do
			if choice <= weight then
				index = possibleIndex
				break
			end
		end

		local element = list[index]
		table.insert(newList, element)
	end

	return newList
end

--]] https://www.w3schools.com/python/ref_dictionary_update.asp
function FilterUtils.PythonUpdate(baseTable, updateTable)
	for key, value in pairs(updateTable) do
		if type(key) == "number" then
			table.insert(baseTable, key, value)
		else
			baseTable[key] = value
		end
	end
end

function FilterUtils.PythonInOperator(obj, objToSearch)
	local objFound = false

	if type(obj) == "string" and type(objToSearch) == "string" then
		objFound = string.find(obj, objToSearch)
	elseif type(objToSearch) == "table" then
		for _, value in pairs(objToSearch) do
			if value == obj then
				objFound = true
				break
			end
		end
	end

	return objFound
end

function FilterUtils.Round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)

	return math.floor(num * mult + 0.5) / mult
end

function FilterUtils.SafeDiv(x, y)
	if y == 0 then
		return 0
	end

	return x / y
end

function FilterUtils.ValidateParams(expectedParameters, data)
	local paramTypes = {
		["S"] = { ["string"] = true, ["nil"] = true },
		["N"] = { ["number"] = true },
		["BOOL"] = { ["boolean"] = true },
	}

	local numErrors = 0

	for paramName, paramType in pairs(expectedParameters) do
		if data[paramName] == nil then
			Utils.pprint("[SuperBiz] Parameter: '" .. paramName .. "' missing")
			numErrors += 1
		elseif not paramTypes[paramType][type(data[paramName])] then
			Utils.pprint(
				"[SuperBiz] Parameter: '"
					.. paramName
					.. "' is type '"
					.. type(data[paramName])
					.. "' but expecting '"
					.. paramTypes[paramType]
					.. "'"
			)
			numErrors += 1
		end
	end

	if numErrors > 0 then
		error(numErrors .. " errors in param validation")
	end

	return true
end

function FilterUtils.Within(array1, array2)
	if type(array1) == "table" then
		for _, array1Object in pairs(array1) do
			if FilterUtils.PythonInOperator(array1Object, array2) then
				return true
			end
		end
	else
		if FilterUtils.PythonInOperator(array1, array2) then
			return true
		end
	end

	return false
end

return FilterUtils
