local TimeFormat = {}

local MINUTE = 60
local HOUR = MINUTE * 60
local DAY = HOUR * 24

function TimeFormat.GetDate(timestamp)
    local now = os.time()
    local passedTime = now - timestamp

    return DateTime.fromUnixTimestamp(timestamp):FormatUniversalTime("ll", "en-us")
end

function TimeFormat.GetTime(timestamp)
    local now = os.time()
    local passedTime = now - timestamp

    return DateTime.fromUnixTimestamp(timestamp):FormatUniversalTime("LT", "en-us")
end

function TimeFormat.Format(timestamp)
    local now = os.time()
    local passedTime = now - timestamp

    if passedTime >= DAY then
        return DateTime.fromUnixTimestamp(timestamp):FormatUniversalTime("ll", "en-us")
    elseif passedTime >= HOUR then
        return math.floor(passedTime / HOUR) .. "h"
    elseif passedTime >= MINUTE then
        return math.floor(passedTime / MINUTE) .. "m"
    else
        return "Now"
    end
end

return TimeFormat