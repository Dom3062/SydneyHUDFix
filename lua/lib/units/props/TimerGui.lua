local init_original = TimerGui.init
local set_background_icons_original = TimerGui.set_background_icons
local set_visible_original = TimerGui.set_visible
local update_original = TimerGui.update
local _start_original = TimerGui._start
local _set_done_original = TimerGui._set_done
local _set_jammed_original = TimerGui._set_jammed
local _set_powered = TimerGui._set_powered
local destroy_original = TimerGui.destroy

function TimerGui:init(unit, ...)
    self._info_key = tostring(unit:key())
    local device_type = unit:base().is_drill and "drill" or unit:base().is_hacking_device and "hack" or unit:base().is_saw and "saw" or "timer"
    managers.gameinfo:event("timer", "create", self._info_key, unit, self, device_type)
    init_original(self, unit, ...)
end

function TimerGui:set_background_icons(...)
    local skills = self._unit:base().get_skill_upgrades and self._unit:base():get_skill_upgrades()

    if skills then
        local can_upgrade = false
        local interact_ext = self._unit:interaction()
        local pinfo = interact_ext and interact_ext.get_player_info_id and interact_ext:get_player_info_id()

        if skills and pinfo then
            for i, _ in pairs(interact_ext:split_info_id(pinfo)) do
                if not skills[i] then
                    can_upgrade = true
                    break
                end
            end
        end

        local upgrade_table = {
            restarter = (skills.auto_repair_level_1 or 0) + (skills.auto_repair_level_2 or 0),
            faster = (skills.speed_upgrade_level or 0),
            silent = (skills.reduced_alert and 1 or 0) + (skills.silent_drill and 1 or 0),
        }

        managers.gameinfo:event("timer", "set_upgradable", self._info_key, can_upgrade)
        managers.gameinfo:event("timer", "set_acquired_upgrades", self._info_key, upgrade_table)
    end

    return set_background_icons_original(self, ...)
end

function TimerGui:set_visible(visible, ...)
    if not visible and self._unit:base().is_drill then
        managers.gameinfo:event("timer", "set_active", self._info_key, false)
    end
    return set_visible_original(self, visible, ...)
end

function TimerGui:update(unit, t, dt, ...)
    update_original(self, unit, t, dt, ...)
    managers.gameinfo:event("timer", "update", self._info_key, t, self._time_left, 1 - self._current_timer / self._timer)
end

function TimerGui:_start(...)
    _start_original(self, ...)
    managers.gameinfo:event("timer", "set_active", self._info_key, true)
end

function TimerGui:_set_done(...)
    managers.gameinfo:event("timer", "set_active", self._info_key, false)
    return _set_done_original(self, ...)
end

function TimerGui:_set_jammed(jammed, ...)
    managers.gameinfo:event("timer", "set_jammed", self._info_key, jammed and true or false)
    return _set_jammed_original(self, jammed, ...)
end

function TimerGui:_set_powered(powered, ...)
    managers.gameinfo:event("timer", "set_powered", self._info_key, powered and true or false)
    return _set_powered(self, powered, ...)
end

function TimerGui:destroy(...)
    managers.gameinfo:event("timer", "destroy", self._info_key)
    return destroy_original(self, ...)
end