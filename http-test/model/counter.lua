---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seet61.
--- DateTime: 16.09.19 21:06
---

-- Моель спейса
local counter = {}

function counter.model(config)
    local model = {}
    model.SPACE_NAME = 'counter'

    model.KEY = 1
    model.KEY_NAME = 'key'
    model.KEY_TYPE = 'string'
    model.VALUE = 2
    model.VALUE_NAME = 'value'
    model.VALUE_TYPE = 'unsigned'

    return model
end

return counter