---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seet61.
--- DateTime: 15.09.19 11:27
---

local log = require('log')
local fio = require('fio')
local config = require('http-test.config.main')
local db = require('http-test.db')
local kv = require('http-test.model.kv').model()
local fiber = require('fiber')

log.debug('package.path: ' .. package.path)
--create folder
fio.mkdir(config.path .. config.instance)

--box configuration
box.cfg {
    pid_file  = config.path .. config.instance .. ".pid",
    log       = "/var/log/tarantool/" .. config.instance .. ".log",
    log_level = config.log_level,
    listen = config.listen_port,
    memtx_memory = config.memtx_memory,
    memtx_max_tuple_size = config.memtx_max_tuple_size,
    memtx_dir = config.path .. config.instance,
    work_dir = config.path .. config.instance,
}

-- Создаем space
db.create_database()

box.schema.user.grant('guest', 'read,write,execute', 'universe', '', { if_not_exists = true })
box.schema.user.create('root', { password = 'secret', if_not_exists = true})
box.schema.user.grant('root', 'read,write,execute, drop', 'universe', nil, {if_not_exists=true})

log.debug('box configured: %s', config.version)

local function reload_counter()
    while true do
        local counter = box.space.counter:get('count')
        if box.space.counter:get('count') == nil then
            box.space.counter:insert({'count', config.rps})
            log.debug('init counter')
        else
            log.debug('count: ' .. tostring(counter[2]))
            box.space.counter:update('count', {{'=', 2, config.rps}})
        end
        fiber.sleep(1)
    end
end
fiber.create(reload_counter)
log.debug("fiber reload_counter was started")

-- Api routes
require('http.server').new(config.http_host, config.http_port, {
    charset = 'utf-8',
    display_errors = true,
    log_requests = true,
})
:route({ path = '/kv', method = 'POST' }, kv.create)
:route({ path = '/kv/:id', method = 'PUT' }, kv.put_by_key)
:route({ path = '/kv/:id', method = 'GET' }, kv.get_by_key)
:route({ path = '/kv/:id', method = 'DELETE' }, kv.delete_by_key)
:start()