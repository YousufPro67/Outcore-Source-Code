local Utils = require(script.Parent)

local QUOTES = "[\"']"

local CreatorType = {
    User = 1,
    Group = 2
}

local Filters = {}

function Filters.getCreatorFilter(query)
    if not query then
        return query, nil
    end

    local filters = {}

    local newQuery = ""
    local function advance(n, include)
        local removed = query:sub(1, n)

        if include then
            newQuery ..= removed
        end

        query = query:sub(n + 1)
        return removed
    end

    while #query > 0 do
        if Utils.startsWith(query, "user:") then
            advance(5)

            if query:sub(1, 1) == "@" then
                advance(1)
            end

            local userIdOrName = string.match(query, "^%S+")
            if userIdOrName then
                advance(#userIdOrName)

                local userId = tonumber(userIdOrName)
                if userId then
                    filters.CreatorType = CreatorType.User
                    filters.CreatorTargetId = userId
                else
                    filters.CreatorType = CreatorType.User
                    filters.CreatorName = userIdOrName
                end
            end
        elseif Utils.startsWith(query, "group:") then
            advance(6)
            local groupId = string.match(query, "^%d+")
            if groupId then
                filters.CreatorType = CreatorType.Group
                filters.CreatorTargetId = tonumber(groupId)
                advance(#groupId)
            end
        else
            advance(1, true)
        end
    end

    if Utils.getArraySize(filters) == 0 then
        return newQuery, nil
    end

    return newQuery, filters
end

return Filters