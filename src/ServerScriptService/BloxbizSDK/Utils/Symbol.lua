local _cache = {}

local Symbol = {}
Symbol.__index = Symbol

function Symbol.new(name, opts)
    if _cache[name] then
        return _cache[name]
    end

    local self = setmetatable({}, Symbol)
    self._name = name

    for k, v in pairs(opts or {}) do
        self[k] = v
    end

    _cache[name] = self
    return self
end

function Symbol:__tostring()
    return string.format("Symbol(%q)", self._name)
end

return Symbol