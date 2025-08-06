local module = {}

local function countTable(toCount)
	local count = 0

	for _, _ in pairs(toCount) do
		count = count + 1
	end

	return count
end

function module.combine(listOfModules)
	local returnVal = nil
	local returnType = type(require(listOfModules[1]))

	if returnType == "string" then
		returnVal = ""

		for _, modulePart in ipairs(listOfModules) do
			returnVal = returnVal .. require(modulePart)
		end
	elseif returnType == "table" then
		returnVal = {}

		for _, modulePart in ipairs(listOfModules) do
			local tablePart = require(modulePart)
			local count = countTable(tablePart)

			if #tablePart == count then
				for _, arrayMember in ipairs(tablePart) do
					table.insert(returnVal, arrayMember)
				end
			else
				for index, dictMember in pairs(tablePart) do
					returnVal[index] = dictMember
				end
			end
		end
	end

	return returnVal
end

return module
