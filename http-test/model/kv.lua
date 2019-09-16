---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seet61.
--- DateTime: 15.09.19 10:56
---

local log = require('log')
local json = require('json')
local configm = require('http-test.config.main')
-- Моель спейса
local kv = {}

function kv.model(config)
    local model = {}

    -- Название спейса и индексa
    model.SPACE_NAME = 'kv'
    model.PRIMARY_INDEX = 'primary'

    -- Номера полей в хранимом кортеже (tuple)
    model.KEY = 1
    model.KEY_NAME = 'key'
    model.KEY_TYPE = 'string'
    model.VALUE = 2
    model.VALUE_NAME = 'value'
    model.VALUE_TYPE = 'map'

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    --check rps
    function model.before(req)
        log.debug('box.stat.net(): ' .. json.encode(box.stat.net()))
        local counter = box.space.counter:get('count')[2]
        if counter == 0 then
            local resp = req:render({json = { message = 'Too many requests' }})
            resp.status = 429
            return resp
        end
        counter = counter - 1
        box.space.counter:update('count', {{'=', 2, counter}})
    end

    function model.create(req)
        local res = model.before(req)
        if res ~= nil then
            return res
        end
        log.debug("create req: " .. tostring(req))
        if not req:json() then
            local resp = req:render({json = { message = 'Bad request' }})
            resp.status = 400
            return resp
        end
        local body = req:json()
        local key = body.key
        local value = body.value
        if key ~= nil and key ~= '' then
            local res = model.get_space():get(key)
            if res ~= nil then
                local resp = req:render({json = { message = 'key already exist' }})
                resp.status = 409
                return resp
            end
            res = model.get_space():insert{
                key,
                value
            }
            log.debug("create res from space: " .. tostring(res))
            if res == nil then
                local resp = req:render({json = { message = 'Error' }})
                resp.status = 500
                return resp
            end
            return req:render({
                json = {
                    message = 'Saved'
                }
            })
        end
    end

    function model.put_by_key(req)
        local res = model.before(req)
        if res ~= nil then
            return res
        end
        log.debug("put by key: " .. tostring(req))
        if pcall(req:json()) then
            local resp = req:render({json = { message = 'Bad request' }})
            resp.status = 400
            return resp
        end
        local body = req:json()
        local key = req:stash('id')
        if key ~= nil and key ~= ''  then
            local res = model.get_space():update({key}, {{'=', 2, body.value }})
            log.debug("put res from space: " .. tostring(res))
            if res == nil then
                local resp = req:render({json = { message = 'Not Found' }})
                resp.status = 404
                return resp
            end
            return req:render({
                json = { message = 'Updated' }
            })
        else
            log.error('Bad key')
            local resp = req:render({json = { message = 'Bad key' }})
            resp.status = 400
            return resp
        end
    end

    function model.get_by_key(req)
        local res = model.before(req)
        if res ~= nil then
            return res
        end
        log.debug("get by key: " .. tostring(req))
        local key = req:stash('id')
        if key ~= nil and key ~= nil  then
            local res = model.get_space().index[model.PRIMARY_INDEX]:get(key)
            log.debug("get res from space: " .. tostring(res))
            if res == nil then
                local resp = req:render({json = { message = 'Not found' }})
                resp.status = 404
                return resp
            end
            return req:render({
                json = res:tomap({names_only=true})
            })
        else
            log.error('Bad key')
            local resp = req:render({json = { message = 'Bad key' }})
            resp.status = 400
            return resp
        end
    end



    function model.delete_by_key(req)
        local res = model.before(req)
        if res ~= nil then
            return res
        end
        log.debug("delete by key: " .. tostring(req))
        local key = req:stash('id')
        if key ~= nil and key ~= nil  then
            local res = model.get_space().index[model.PRIMARY_INDEX]:delete(key)
            log.debug("delete res from space: " .. tostring(res))
            if res == nil then
                local resp = req:render({json = { message = 'Not found' }})
                resp.status = 404
                return resp
            end
            return req:render({
                json = { message = 'Deleted' }
            })
        else
            log.error('Bad key')
            local resp = req:render({json = { message = 'Bad key' }})
            resp.status = 400
            return resp
        end
    end

    return model
end

return kv