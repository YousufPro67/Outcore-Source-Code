local function GetNameRichText(userName: string, postedTime: string): string
	return userName .. '  <font color="rgb(121,121,121)">' .. postedTime .. "</font>"
end

local function IsoDateToNumber(date: string): number
	local t = DateTime.fromIsoDate(date)
	return t.UnixTimestamp
end

local function GetTime(isoDate: string): (string, number)
	local now = os.time()
	local date_obj = os.time({
		year = tonumber(isoDate:sub(1, 4)) :: number,
		month = tonumber(isoDate:sub(6, 7)) :: number,
		day = tonumber(isoDate:sub(9, 10)) :: number,
		hour = tonumber(isoDate:sub(12, 13)) :: number,
		min = tonumber(isoDate:sub(15, 16)) :: number,
		sec = tonumber(isoDate:sub(18, 19)) :: number,
	})

	local time_diff = now - date_obj
	local seconds = math.abs(time_diff)

	local minute = 60
	local hour = 60 * minute
	local day = 24 * hour
	local week = 7 * day
	local month = 30 * day
	local year = 365 * day

	local date = ""
	local level = 0
	if seconds < minute then
		level = 1
		date = string.format("%d seconds ago", seconds)
	elseif seconds < hour then
		level = 2
		date = string.format("%d minutes ago", seconds / minute)
	elseif seconds < day then
		level = 3
		date = string.format("%d hours ago", seconds / hour)
	elseif seconds < week then
		level = 4 
		date = string.format("%d days ago", seconds / day)
	elseif seconds < month then
		level = 5
		date = string.format("%d weeks ago", seconds / week)
	elseif seconds < year then
		level = 6
		date = string.format("%d months ago", seconds / month)
	else
		level = 7
		date = string.format("%d years ago", seconds / year)
	end

	return date, level
end

local MONTHS_ABBR = {
	"Jan", "Feb", "March", "Apr", "May", "June", "July", "Aug", "Sep", "Oct", "Nov", "Dec"
}

local function FormatIsoDate(isoDate: string, formatKey: string?, localeKey: string?): string
	local myDate = DateTime.fromIsoDate(isoDate)

	-- lua date formatting doesn't support month abbreviations so I did it myself
	local month = tonumber(myDate:FormatLocalTime("MM", "en-us")) :: number
	local month_abbr = MONTHS_ABBR[month]

	return month_abbr .. " " .. myDate:FormatLocalTime("DD, YYYY", "en-us")
end

return {
    GetNameRichText = GetNameRichText,
    IsoDateToNumber = IsoDateToNumber,
	FormatIsoDate = FormatIsoDate,
    GetTime = GetTime,
}