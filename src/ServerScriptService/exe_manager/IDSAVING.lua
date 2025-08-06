local DataStoreService = game:GetService("DataStoreService")
local UserIdDataStore = DataStoreService:GetDataStore("ID")
local UserIdListKey = "UserIdList"

local BATCH = 10
local INTERVAL = 60

local module = {}

function module.SAVE_USERID(USERID)
	local success, result = pcall(function()
		UserIdDataStore:SetAsync(tostring(USERID), true)

		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}

		if not table.find(userIds, tostring(USERID)) then
			table.insert(userIds, tostring(USERID))
			UserIdDataStore:SetAsync(UserIdListKey, userIds)
		end
	end)

	if not success then
		warn("Failed to save UserID:", result)
	end
end

function module.SAVE_EXPIRING_USERID(USERID, DURATION)
	local expireTime = os.time() + DURATION

	local success, result = pcall(function()
		local userIdWithTimestamp = tostring(USERID) .. ";" .. tostring(expireTime)

		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}

		-- Remove any existing entry for the same USERID to avoid duplicates
		for i, id in ipairs(userIds) do
			if id:split(";")[1] == tostring(USERID) then
				table.remove(userIds, i)
				break
			end
		end

		table.insert(userIds, userIdWithTimestamp)
		UserIdDataStore:SetAsync(UserIdListKey, userIds)
	end)

	if not success then
		warn("Failed to save UserID:", result)
	end
end

function module.REMOVE_USERID(USERID)
	local success, result = pcall(function()
		UserIdDataStore:RemoveAsync(tostring(USERID))

		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}

		for i, id in ipairs(userIds) do
			if id:split(";")[1] == tostring(USERID) then
				table.remove(userIds, i)
				break
			end
		end

		UserIdDataStore:SetAsync(UserIdListKey, userIds)
	end)

	if not success then
		warn("Failed to remove UserID:", result)
	end
end

function module.GET_USERIDS()
	local success, result = pcall(function()
		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}
		local permanentUserIds = {}

		for _, userId in ipairs(userIds) do
			if not userId:find(";") then
				table.insert(permanentUserIds, userId)
			end
		end

		return permanentUserIds
	end)

	if success then
		return result
	else
		warn("Failed to get UserIDs:", result)
		return {}
	end
end

function module.GET_EXPIRING_USERIDS()
	local success, result = pcall(function()
		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}
		local expiringUserIds = {}

		for _, userId in ipairs(userIds) do
			if userId:find(";") then
				table.insert(expiringUserIds, userId)
			end
		end

		return expiringUserIds
	end)

	if success then
		return result
	else
		warn("Failed to get expiring UserIDs:", result)
		return {}
	end
end

function module.SAVED(USERID)
	local success, result = pcall(function()
		return UserIdDataStore:GetAsync(tostring(USERID)) == true
	end)

	if success then
		return result
	else
		warn("Failed to check UserID:", result)
		return false
	end
end

function module.CLEAN_UP_EXPIRED_USERIDS()
	local success, result = pcall(function()
		local userIds = UserIdDataStore:GetAsync(UserIdListKey) or {}
		local currentTime = os.time()
		local validUserIds = {}
		local expiredUserIds = {}

		for i = 1, #userIds, BATCH do
			local batch = {unpack(userIds, i, math.min(i + BATCH - 1, #userIds))}

			for _, userId in ipairs(batch) do
				local parts = userId:split(";")

				if #parts == 2 then
					local id = parts[1]
					local expireTime = tonumber(parts[2])

					if expireTime and currentTime < expireTime then
						table.insert(validUserIds, userId)
					else
						table.insert(expiredUserIds, userId)
					end
				else
					table.insert(validUserIds, userId)  -- Treat as a permanent user ID
				end
			end
		end

		for _, userId in ipairs(expiredUserIds) do
			UserIdDataStore:RemoveAsync(userId:split(";")[1])
		end

		UserIdDataStore:SetAsync(UserIdListKey, validUserIds)
	end)

	if not success then
		warn("Failed to clean up expired UserIDs:", result)
	end
end

spawn(function()
	while true do
		module.CLEAN_UP_EXPIRED_USERIDS()

		task.wait(INTERVAL)
	end
end)

return module