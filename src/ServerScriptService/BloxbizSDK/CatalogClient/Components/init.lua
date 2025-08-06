return setmetatable({}, {
    __index = function(_, name)
        local module = script:FindFirstChild(name)
        if module and module:IsA("ModuleScript") then
            return require(module)
        end
    end
})