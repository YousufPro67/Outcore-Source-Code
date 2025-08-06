local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = {}

local ConfigReader = require(script.Parent.ConfigReader)
local InternalConfig = require(script.Parent.InternalConfig)

local Promise = require(script.Promise)

local PRINT_DEBUG_STATEMENTS = InternalConfig.PRINT_DEBUG_STATEMENTS
local REMOTES_FOLDER = "BloxbizRemotes"

local function getRemotesFolder()
	return ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
end

local DEBUG_CUSTOM_EVENTS = ConfigReader:read("DebugModeCustomEvents")

function Utils.custom_event_print(...)
	if DEBUG_CUSTOM_EVENTS or PRINT_DEBUG_STATEMENTS then
		print(...)
	end
end

function Utils.pprint(...)
	if PRINT_DEBUG_STATEMENTS then
		print(...)
	end
end

function Utils.debug_warn(...)
	if PRINT_DEBUG_STATEMENTS then
		warn(...)
	end
end

function Utils.startsWith(str, substr)
	return str:sub(1, #substr) == substr
end

function Utils.endsWith(str, substr)
	return str:sub(#str - #substr + 1) == substr
end

-- @param num: number
-- @return string
function Utils.toLocaleNumber(num: number): string
    return string.format("%0.0f", num)
		:gsub("(%d)(%d%d%d)$", function(digit: string, otherDigits: string)
			return digit .. "," .. otherDigits
		end)
end

local SUFFIXES = {
    "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud",
    "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Od", "Nd", "V", "Uv", "Dv",
    "Tv", "Qav", "Qiv", "Sxv", "Spv", "Ov", "Nv", "Tt",
}

function Utils.toSuffixNumber(number)
    local suffixIndex
    if number >= 10000 then
        local digitCount = math.max(math.floor(math.log10(number)), 0)
        suffixIndex = math.floor(digitCount / 3)

        number = number / 1000 ^ suffixIndex
    end
    number = math.round(number * 100) / 100

	return suffixIndex and number .. SUFFIXES[suffixIndex] or number
end

function Utils.reverse(arr: table)
	local rev = {}
	for i=#arr, 1, -1 do
		rev[#rev+1] = arr[i]
	end

	return rev
end

function Utils.search(arr, predicate)
	for _, v in ipairs(arr) do
		if predicate(v) then
			return v
		end
	end

	return nil
end

function Utils.values<T>(tbl: {T}, filterFunc: ((T, string) -> boolean)?)
	local result = {}
	for k, v in pairs(tbl) do
		if filterFunc then
			if filterFunc(v, k) then
				table.insert(result, v)
			end
		else
			table.insert(result, v)
		end
	end

	return result
end

function Utils.find(arr, predicate)
	for i, v in ipairs(arr) do
		if predicate(v) then
			return i
		end
	end

	return nil
end

function Utils.tableFilter(tbl, predicate)
	local newTbl = {}

	for k, v in pairs(tbl) do
		if predicate(v) then
			newTbl[k] = v
		end
	end

	return newTbl
end

function Utils.sortByKey<T>(arr: {T}, keyOrKeyFunc: string | (() -> number)): {T}
	local keyFunc
	if type(keyOrKeyFunc) == "string" then
		keyFunc = function (item)
			return item[keyOrKeyFunc]
		end
	else
		keyFunc = keyOrKeyFunc
	end

	table.sort(arr, function (a, b)
		local aKey = keyFunc(a)
		local bKey = keyFunc(b)

		return aKey < bKey
	end)

	return arr
end

Utils.sort = Utils.sortByKey

function Utils.filter(arr, predicate)
	local newArr = {}

	for _, v in ipairs(arr) do
		if predicate(v) then
			table.insert(newArr, v)
		end
	end

	return newArr
end

function Utils.findFirstAncestorOfClass(instance, classname)
	local current = instance.Parent

	while not current:IsA(classname) do
		current = current.Parent
		if current == game then
			return nil
		end
	end

	return current
end

-- Returns a white or black text color based on background color luminance
function Utils.getTextColor(bgColor: Color3 | string)
	if type(bgColor) == "string" then
		bgColor = Color3.fromHex(bgColor)
	end

	local r, g, b = bgColor.R, bgColor.G, bgColor.B

	if r <= 0.04045 then r = r / 12.92 else r = ((r + 0.055) / 1.055) ^ 2.4 end
	if g <= 0.04045 then g = g / 12.92 else g = ((g + 0.055) / 1.055) ^ 2.4 end
	if b <= 0.04045 then b = b / 12.92 else b = ((b + 0.055) / 1.055) ^ 2.4 end

	local luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

	if luminance > 0.25 then
		return Color3.new(0, 0, 0)
	else
		return Color3.new(1, 1, 1)
	end
end

-- Returns a Promise that filters array values asynchronously using a predicate callback that may yield.
function Utils.asyncFilter<T>(arr: {T}, predicate: (T) -> boolean)
	return Promise.new(function (resolve, reject)
		local predicatePromises = {}

		for _, item in ipairs(arr) do
			table.insert(predicatePromises, Promise.try(function()
				return predicate(item)
			end))
		end

		Promise.all(predicatePromises)
			:andThen(function (results)
				local filteredValues = {}

				for idx, item in ipairs(arr) do
					if results[idx] then
						table.insert(filteredValues, item)
					end
				end

				resolve(filteredValues)
			end)
			:catch(reject)
	end)
end

function Utils.strip(str, suffix)
	if Utils.endsWith(str, suffix) then
		return string.sub(str, 1, #str - #suffix)
	end

	return str
end

function Utils.count(arr, predicate)
	if not arr then
		return 0
	end
	
	local count = 0

	for _, v in pairs(arr) do
		if predicate(v) then
			count += 1
		end
	end

	return count
end

function Utils.sum(arr, callback)
	if not arr then
		return 0
	end

	local count = 0

	for _, v in pairs(arr) do
		count += callback(v)
	end

	return count
end

function Utils.map(tb, transformer)
	local result = {}

	-- works on arrays and dictionaries
	for k, v in pairs(tb) do
		result[k] = transformer(v, k, tb)
	end

	return result
end

function Utils.callWithRetry(func: () -> any, max_tries: number): any
	local success = false
	local result = nil
	local tries = 1

	while not success and tries < max_tries do
		success, result = pcall(func)

		if not success then
			print("[SuperBiz] Retrying failed function call: " .. tostring(result))
			Utils.pprint(debug.traceback())

			task.wait(tries * 2)
			tries += 1
		end
	end

	return result, success
end

function Utils.merge(table1: { [any]: any }, table2: { [any]: any }): { [any]: any }
	local result = {}

	for k, v in pairs(table1 or {}) do
		result[k] = v
	end

	for k, v in pairs(table2 or {}) do
		result[k] = v
	end

	return result
end

function Utils.copyTable(original)
	local copy = {}
	for k, v in original do
		copy[k] = v
	end
	return copy
end

function Utils.deepCopy(original: { [any]: any })
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = Utils.deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function Utils.hasSameKeys(tbl1, tbl2)
	for k, _ in pairs(tbl1) do
		if not tbl2[k] then
			return false
		end
	end

	for k, _ in pairs(tbl2) do
		if not tbl1[k] then
			return false
		end
	end

	return true
end

function Utils.getTableType(t: { [any]: any }): string?
	if next(t) == nil then
		return
	end
	for k, _ in pairs(t) do
		if typeof(k) ~= "number" or (typeof(k) == "number" and (k % 1 ~= 0 or k < 0)) then
			return "Dictionary"
		end
	end

	return "Array"
end

function Utils.getArraySize(array: { [any]: any }): number
	local tableType = Utils.getTableType(array)
	if tableType == "Array" then
		return #array
	elseif tableType == "Dictionary" then
		local count = 0
		for _ in pairs(array) do
			count += 1
		end
		return count
	else
		return 0
	end
end

function Utils.concat(...)
	local args = {...}

	local result = {}
	for _, array in ipairs(args) do
		for _, value in ipairs(array) do
			table.insert(result, value)
		end
	end

	return result
end

function Utils.defaultdict(callable, initial)
    local T = {}
    setmetatable(T, {
        __index = function(T, key)
            local val = rawget(T, key)
            if not val then
                rawset(T, key, callable())
            end
            return rawget(T, key)
        end
    })

	if initial then
		for k, v in pairs(initial) do
			T[k] = v
		end
	end

    return T
end

function Utils.chunk(array, size)
	local result = {}

	for i, item in ipairs(array) do
		local arrIdx = math.ceil(i / size)

		if not result[arrIdx] then
			table.insert(result, {})
		end

		table.insert(result[arrIdx], item)
	end

	return result
end

function Utils.isVisible(container, item)
	local containerTop, containerBottom = container.AbsolutePosition.Y, container.AbsolutePosition.Y + container.AbsoluteSize.Y
	local itemTop, itemBottom = item.AbsolutePosition.Y, item.AbsolutePosition.Y + item.AbsoluteSize.Y

	local isVisibleY = itemBottom > containerTop and itemTop < containerBottom

	return isVisibleY
end

function Utils.getAncestor(inst, depth)
	if depth == 1 then
		return inst and inst.Parent or nil
	else
		return inst.Parent and Utils.getAncestor(inst.Parent, depth-1) or nil
	end
end

local runtimeFilterList = {}
local hardcodedFilterList = ConfigReader:read("RaycastFilterList")()
function Utils.appendToRaycastFilterList(obj)
	local BloxbizConfig = require(game.ReplicatedStorage.BloxbizConfig)
	table.insert(runtimeFilterList, obj)

	BloxbizConfig.RaycastFilterList = function()
		local newFilterList = {}

		for _, v in pairs(hardcodedFilterList) do
			table.insert(newFilterList, v)
		end

		for _, v in pairs(runtimeFilterList) do
			table.insert(newFilterList, v)
		end

		return newFilterList
	end
end

function Utils.getAdUsingBloxbizAdId(bloxbizAdId)
	local numId = tonumber(bloxbizAdId)
	local inputValid = numId ~= nil and numId > 0

	if not inputValid then
		return
	end

	local adsList
	if RunService:IsClient() then
		local RemotesFolder = getRemotesFolder()
		adsList = RemotesFolder.getAdStorage:InvokeServer()
	else
		local AdFilter = require(script.Parent.AdFilter)
		adsList = AdFilter:GetAllEnabledAds()
	end

	for _, ad in pairs(adsList) do
		if tonumber(bloxbizAdId) == tonumber(ad.bloxbiz_ad_id) then
			return ad
		end
	end
end

function Utils.isHovering(guiObject, mouse)
	local player = Players.LocalPlayer
	local mouse = mouse or player:GetMouse()
	local guiObjects = player.PlayerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

	for _, obj in ipairs(guiObjects) do
		if obj == guiObject then
			return true
		end
	end

	return false
end

function Utils.benchmarkFn(label, fn)
	local st = tick()
	local results = { fn() }
	local timePassed = tick() - st

	local formattedTime = string.format("%.1f s", timePassed)
	if timePassed < 1 then
		formattedTime = string.format("%s ms", math.round(timePassed * 1000))
	end

	Utils.pprint(string.format("%q took %s", label, formattedTime))

	return table.unpack(results)
end

return Utils
