local HttpService = game:GetService("HttpService")

local apiKey = require(script.Parent.Parent.BatchHTTP.ApiKey)
local utils = require(script.Parent.Parent.Utils)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)

local http = {}

function http.getUrl(query)
	return BatchHTTP.getNewUrl("promocodes/" .. query)
end

function http.getHeaders()
    return {
       ["API-KEY"] = apiKey.getApiKey(),
       ["Content-Type"] = "application/json"
   }
end

function http.post(url, data)
    local baseData = {
        game_id = game.GameId
    }
    data = utils.merge(baseData, data or {})
    local json = HttpService:JSONEncode(data)
    url = http.getUrl(url)

    local response = HttpService:RequestAsync({
        Url = url,
        Body = json,
        Method = "POST",
        Headers = http.getHeaders(),
    })

    local decodeSuccess, respData = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeSuccess then
        error(response.StatusMessage)
    end

    if not response.Success then
        error(respData.message or response.StatusMessage)
    end

    return respData
end

return http