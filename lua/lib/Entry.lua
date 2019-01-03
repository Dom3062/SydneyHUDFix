GameInfoManager = GameInfoManager or class()
GameInfoManager._PLUGINS_LOADED = {}
GameInfoManager._PLUGIN_SETTINGS = GameInfoManager._PLUGIN_SETTINGS or { PLACEHOLDER = true }	--BLT JSON decode doesn't like empty tables
function GameInfoManager:init()
    self._t = 0
    self._scheduled_callbacks = {}
    self._scheduled_callbacks_index = {}
    self._listeners = {}
end

function GameInfoManager:post_init()
    self:do_post_init_events()
end

function GameInfoManager:do_post_init_events()
    for _, clbk in ipairs(GameInfoManager.post_init_events or {}) do
        if type(clbk) == "string" then
            if self[clbk] then
                self[clbk](self)
            end
        else
            clbk()
        end
    end
    
    GameInfoManager.post_init_events = nil
end

function GameInfoManager:update(t, dt)
    self._t = t
    
    while self._scheduled_callbacks[1] and self._scheduled_callbacks[1].t <= t do
        local data = table.remove(self._scheduled_callbacks, 1)
        self._scheduled_callbacks_index[data.id] = nil
        data.clbk(unpack(data.args))
    end
end

function GameInfoManager:add_scheduled_callback(id, delay, clbk, ...)
    self:remove_scheduled_callback(id)

    local t = self._t + delay
    local pos = 1
    
    for i, data in ipairs(self._scheduled_callbacks) do
        if data.t >= t then break end
        pos = pos + 1
    end
    
    table.insert(self._scheduled_callbacks, pos, { id = id, t = t, clbk = clbk, args = { ... } })
    self._scheduled_callbacks_index[id] = true
end

function GameInfoManager:remove_scheduled_callback(id)
    if self._scheduled_callbacks_index[id] then
        for i, data in ipairs(self._scheduled_callbacks) do
            if data.id == id then
                self._scheduled_callbacks_index[id] = nil
                return table.remove(self._scheduled_callbacks, i)
            end
        end
    end
end

function GameInfoManager:event(source, ...)
    local target = "_" .. source .. "_event"
    
    if self[target] then
        self[target](self, ...)
    else
        printf("Error: No event handler for %s", target)
    end
end

function GameInfoManager:_interactive_unit_event(event, key, data)
    --Placeholder for callbacks
end

function GameInfoManager:_whisper_mode_event(event, key, status)
    self:_listener_callback("whisper_mode", "change", key, status)
end

function GameInfoManager:register_listener(listener_id, source_type, event, clbk, keys, data_only)
    local listener_keys = nil
    
    if keys then
        listener_keys = {}
        for _, key in ipairs(keys) do
            listener_keys[key] = true
        end
    end
    
    self._listeners[source_type] = self._listeners[source_type] or {}
    self._listeners[source_type][event] = self._listeners[source_type][event] or {}
    self._listeners[source_type][event][listener_id] = { clbk = clbk, keys = listener_keys, data_only = data_only }
end

function GameInfoManager:unregister_listener(listener_id, source_type, event)
    if self._listeners[source_type] then
        if self._listeners[source_type][event] then
            self._listeners[source_type][event][listener_id] = nil
        end
    end
end

function GameInfoManager:_listener_callback(source, event, key, ...)
    for listener_id, data in pairs(self._listeners[source] and self._listeners[source][event] or {}) do
        if not data.keys or data.keys[key] then
            if data.data_only then
                data.clbk(...)
            else
                data.clbk(event, key, ...)
            end
        end
    end
end

function GameInfoManager.add_post_init_event(clbk)
    GameInfoManager.post_init_events = GameInfoManager.post_init_events or {}
    table.insert(GameInfoManager.post_init_events, clbk)
    
    if managers and managers.gameinfo then
        managers.gameinfo:do_post_init_events()
    end
end

function GameInfoManager.add_plugin(name, data, init_clbk)
    GameInfoManager._PLUGINS_LOADED[name] = data
    if GameInfoManager._PLUGIN_SETTINGS[name] == nil then
        GameInfoManager._PLUGIN_SETTINGS[name] = true
    end
    
    if init_clbk then
        GameInfoManager.add_post_init_event(init_clbk)
    end
end

function GameInfoManager.has_plugin(name)
    return GameInfoManager._PLUGINS_LOADED[name] and true or false
end

function GameInfoManager.plugin_active(name)
    return GameInfoManager.has_plugin(name) and GameInfoManager._PLUGIN_SETTINGS[name] and true or false
end