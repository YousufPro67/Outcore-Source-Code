local UtilsStorage = script.Parent
local Symbol = require(UtilsStorage:WaitForChild("Symbol"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Value = Fusion.Value

local module = {}

module.Nil = Symbol.new("nil")
module.Required = Symbol.new("required")
module.Callback = Symbol.new("callback")

function module.GetValues(props, defaults)
    -- Takes a table of props that values that may be Fusion values, and returns a table with only Fusion values.
    -- Existing Fusion Values are kept, and raw values (strings, numbers, etc) are turned into Fusion values.
    -- This allows Fusion values or raw values to be passed in as props. If a Fusion value is passed in, updating the Fusion value will update the rendered component.

    props = props or {}

    for key, val in pairs(defaults) do
        if props[key] == nil then
            if val == module.Required then
                error(string.format("Prop %q is required", key))
            else
                props[key] = val
            end
        end
    end

    local newProps = {}
    local extras = {}
    for key, val in pairs(props) do
        if val == module.Nil then
            val = nil
        end
        -- elseif val == module.Callback then
        --     -- empty default callback does nothing
        --     val = defaultCallback
        -- end

        if type(val) == "table" and val.type == "State" then
            newProps[key] = val
        elseif val == module.Callback then
            newProps[key] = Value(function() end)
        else
            newProps[key] = Value(val)
            -- if type(val) == "function" then
            --     print(newProps[key]:get())
            -- end
        end
        
        if not defaults[key] then
            extras[key] = val
        end
    end

    return newProps, extras
end

return module