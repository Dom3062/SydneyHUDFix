local _do_action_intimidate_original = PlayerStandard._do_action_intimidate
function PlayerStandard:_do_action_intimidate(t, interact_type, ...)
    if interact_type == "cmd_gogo" or interact_type == "cmd_get_up" then
        local duration = (tweak_data.upgrades.morale_boost_base_cooldown * managers.player:upgrade_value("player", "morale_boost_cooldown_multiplier", 1)) or 3.5
        managers.gameinfo:event("buff", "activate", "inspire_debuff")
        managers.gameinfo:event("buff", "set_duration", "inspire_debuff", { duration = duration })
    end

    return _do_action_intimidate_original(self, t, interact_type, ...)
end

local _do_melee_damage_original = PlayerStandard._do_melee_damage
function PlayerStandard:_do_melee_damage(t, ...)
    if self._state_data.melee_start_t then
        managers.gameinfo:event("player_action", "deactivate", "melee_charge")
    end
    if self._state_data.charging_melee then
        managers.hud:hide_interaction_bar()
        self._state_data.charging_melee = false
    end
    local result = _do_melee_damage_original(self, t, ...)

    local stack = self._state_data.stacking_dmg_mul and self._state_data.stacking_dmg_mul.melee
    if stack then
        managers.gameinfo:event("buff", stack[2] > 0 and "activate" or "deactivate", "melee_stack_damage")

        if stack[2] > 0 then
            local value = managers.player:upgrade_value("melee", "stacking_hit_damage_multiplier", 0)
            managers.gameinfo:event("buff", "set_duration", "melee_stack_damage", { expire_t = stack[1] })
            managers.gameinfo:event("buff", "set_stack_count", "melee_stack_damage", { stack_count = stack[2] })
            managers.gameinfo:event("buff", "set_value", "melee_stack_damage", { value = 1 + stack[2] * value })
        end
    end

    return result
end

local _start_action_melee_original = PlayerStandard._start_action_melee
function PlayerStandard:_start_action_melee(t, input, instant)
    if not instant then
        local duration = tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time
        managers.gameinfo:event("player_action", "activate", "melee_charge")
        managers.gameinfo:event("player_action", "set_duration", "melee_charge", { duration = duration })
        if SydneyHUD:GetOption("show_melee_interaction") then
            managers.hud:animate_interaction_bar(duration)
            self._state_data.charging_melee = true
        end
    end
    return _start_action_melee_original(self, t, input, instant)
end

local _start_action_interact_original = PlayerStandard._start_action_interact
function PlayerStandard:_start_action_interact(...)
    if managers.player:has_category_upgrade("player", "interacting_damage_multiplier") then
        local value = managers.player:upgrade_value("player", "interacting_damage_multiplier", 0)
        managers.gameinfo:event("buff", "activate", "die_hard")
        managers.gameinfo:event("buff", "set_value", "die_hard", { value = value })
    end

    return _start_action_interact_original(self, ...)
end

local _interupt_action_interact_original = PlayerStandard._interupt_action_interact
function PlayerStandard:_interupt_action_interact(...)
    if self._interact_expire_t and managers.player:has_category_upgrade("player", "interacting_damage_multiplier") then
        managers.gameinfo:event("buff", "deactivate", "die_hard")
    end

    return _interupt_action_interact_original(self, ...)
end

local _start_action_charging_weapon_original = PlayerStandard._start_action_charging_weapon
function PlayerStandard:_start_action_charging_weapon(t, ...)
    managers.gameinfo:event("player_action", "activate", "weapon_charge")
    managers.gameinfo:event("player_action", "set_duration", "weapon_charge", { duration = self._equipped_unit:base():charge_max_t() })
    return _start_action_charging_weapon_original(self, t, ...)
end

local _end_action_charging_weapon_original = PlayerStandard._end_action_charging_weapon
function PlayerStandard:_end_action_charging_weapon(...)
    if self._state_data.charging_weapon then
        managers.gameinfo:event("player_action", "deactivate", "weapon_charge")
    end
    return _end_action_charging_weapon_original(self, ...)
end

--OVERRIDE
function PlayerStandard:_update_omniscience(t, dt)
    local action_forbidden =
        not managers.player:has_category_upgrade("player", "standstill_omniscience") or
        managers.player:current_state() == "civilian" or
        self:_interacting() or
        self._ext_movement:has_carry_restriction() or
        self:is_deploying() or
        self:_changing_weapon() or
        self:_is_throwing_projectile() or
        self:_is_meleeing() or
        self:_on_zipline() or
        self._moving or
        self:running() or
        self:_is_reloading() or
        self:in_air() or
        self:in_steelsight() or
        self:is_equipping() or
        self:shooting() or
        not managers.groupai:state():whisper_mode() or
        not tweak_data.player.omniscience

    if action_forbidden then
        if self._state_data.omniscience_t then
            managers.gameinfo:event("buff", "deactivate", "sixth_sense")
            self._state_data.omniscience_t = nil
        end
        return
    end

    if not self._state_data.omniscience_t then
        managers.gameinfo:event("buff", "activate", "sixth_sense")
        managers.gameinfo:event("buff", "set_duration", "sixth_sense", { duration = tweak_data.player.omniscience.start_t, no_expire = true })
        managers.gameinfo:event("buff", "set_stack_count", "sixth_sense", { stack_count = nil })
    end

    self._state_data.omniscience_t = self._state_data.omniscience_t or t + tweak_data.player.omniscience.start_t
    if t >= self._state_data.omniscience_t then
        local sensed_targets = World:find_units_quick("sphere", self._unit:movement():m_pos(), tweak_data.player.omniscience.sense_radius, managers.slot:get_mask("trip_mine_targets"))
        managers.gameinfo:event("buff", "set_stack_count", "sixth_sense", { stack_count = #sensed_targets })

        for _, unit in ipairs(sensed_targets) do
            if alive(unit) and not unit:base():char_tweak().is_escort then
                self._state_data.omniscience_units_detected = self._state_data.omniscience_units_detected or {}
                if not self._state_data.omniscience_units_detected[unit:key()] or t >= self._state_data.omniscience_units_detected[unit:key()] then
                    self._state_data.omniscience_units_detected[unit:key()] = t + tweak_data.player.omniscience.target_resense_t
                    managers.game_play_central:auto_highlight_enemy(unit, true)
                end
            else
            end
        end
        self._state_data.omniscience_t = t + tweak_data.player.omniscience.interval_t
        managers.gameinfo:event("buff", "set_duration", "sixth_sense", { duration = tweak_data.player.omniscience.interval_t, no_expire = true })
    end
end

--local PREV_DMG_STACK = {}	--Prevent event flooding
function PlayerStandard:_check_damage_stack_skill(t, category)
    local stack = self._state_data.stacking_dmg_mul[category]

    if stack then
        local buff_id = category .. "_stack_damage"

        --if not PREV_DMG_STACK[category] or (PREV_DMG_STACK[category][1] ~= stack[1] or PREV_DMG_STACK[category][2] ~= stack[2]) then
        --	PREV_DMG_STACK[category] = { stack[1], stack[2] }

        if stack[2] > 0 then
            local value = managers.player:upgrade_value(category, "stacking_hit_damage_multiplier", 0)
            managers.gameinfo:event("timed_buff", "activate", buff_id, { expire_t = stack[1] })
            managers.gameinfo:event("buff", "set_stack_count", buff_id, { stack_count = stack[2] })
            managers.gameinfo:event("buff", "set_value", buff_id, { value = 1 + stack[2] * value })
        else
            managers.gameinfo:event("buff", "deactivate", buff_id)
        end
        --end
    end
end

local update_original = PlayerStandard.update
function PlayerStandard:update(t, ...)
    managers.hud:update_inspire_timer(self._ext_movement:morale_boost() and managers.enemy:get_delayed_clbk_expire_t(self._ext_movement:morale_boost().expire_clbk_id) - t or -1)
    return update_original(self, t, ...)
end

local _start_action_reload_original = PlayerStandard._start_action_reload
function PlayerStandard:_start_action_reload(t, ...)
    _start_action_reload_original(self, t, ...)
    if self._equipped_unit:base():can_reload() then
        if managers.player:current_state() ~= "bleed_out" and SydneyHUD:GetOption("show_reload_interaction") then
            self._state_data._isReloading = true
            managers.hud:animate_interaction_bar(self._state_data.reload_expire_t - t, nil, true)
        end
        managers.gameinfo:event("player_action", "activate", "reload", { duration = self._state_data.reload_expire_t - t })
    end
end

local _update_reload_timers_original = PlayerStandard._update_reload_timers
function PlayerStandard:_update_reload_timers(t, dt, input)
    local interupt = self._queue_reload_interupt
    local reload = self._state_data.reload_expire_t
    _update_reload_timers_original(self, t, dt, input)
    if reload and not self._state_data.reload_expire_t then
        managers.gameinfo:event("player_action", "deactivate", "reload")
    end
    if interupt then
        managers.hud:hide_interaction_bar()
        self._state_data._isReloading = false
    end
end

local _interupt_action_reload_original = PlayerStandard._interupt_action_reload
function PlayerStandard:_interupt_action_reload(t)
    if self._state_data.reload_expire_t then
        managers.gameinfo:event("player_action", "deactivate", "reload")
    end
    if self._state_data._isReloading and managers.player:current_state() ~= "bleed_out" then
        managers.hud:hide_interaction_bar()
        self._state_data._isReloading = false
    end
    return _interupt_action_reload_original(self, t)
end

local _interupt_action_melee_original = PlayerStandard._interupt_action_melee
function PlayerStandard:_interupt_action_melee(...)
    if self._state_data.melee_start_t then
        managers.gameinfo:event("player_action", "deactivate", "melee_charge")
    end
    if self._state_data.charging_melee then
        managers.hud:hide_interaction_bar()
        self._state_data.charging_melee = false
    end
    _interupt_action_melee_original(self, ...)
end

local TIMEOUT = 0.25
local _check_action_throw_grenade_original = PlayerStandard._check_action_throw_grenade
function PlayerStandard:_check_action_throw_grenade(t, input, ...)
    if input.btn_throw_grenade_press then
        if SydneyHUD:GetOption("anti_stealth_grenades") and managers.groupai:state():whisper_mode() and (t - (self._last_grenade_t or 0) >= TIMEOUT) then
            self._last_grenade_t = t
            return
        end
    end
    return _check_action_throw_grenade_original(self, t, input, ...)
end

local _check_action_interact_original = PlayerStandard._check_action_interact
function PlayerStandard:_check_action_interact(t, input, ...)
    local check_interact = {} and (self._interact_params or 0)
    if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact") and check_interact.timer >= SydneyHUD:GetOption("push_to_interact_delay")) then
        return _check_action_interact_original(self, t, input, ...)
    end
end

function PlayerStandard:_check_interact_toggle(t, input)
    local interrupt_key_press = input.btn_interact_press
    if SydneyHUD:GetOption("equipment_interrupt") then
        interrupt_key_press = input.btn_use_item_press
    end
    if interrupt_key_press and self:_interacting() then
        self:_interupt_action_interact()
        return true
    elseif input.btn_interact_release and self._interact_params then
        return true
    end
end

Hooks:PostHook(PlayerStandard, "_update_fwd_ray", "uHUDPostPlayerStandardUpdateFwdRay", function(self)
    if self._last_unit then
        local iAngle = 360
        local cAngle = 360
        iAngle = self:getUnitRotation(self._last_unit)
        if iAngle then
            cAngle = cAngle + (iAngle - cAngle)
            if cAngle == 0 then cAngle = 360 end
            managers.hud:set_unit_health_rotation(cAngle)
        end
    end

    if self._fwd_ray and self._fwd_ray.unit then
        local unit = self._fwd_ray.unit
        local turret
        if unit:in_slot(8) and alive(unit:parent()) then
            unit = unit:parent()
        end
        if managers.groupai:state():turrets() then
            for _, t_unit in pairs(managers.groupai:state():turrets()) do
                if alive(t_unit) and t_unit:movement():team().foes[managers.player:player_unit():movement():team().id] and unit == t_unit then
                    unit = t_unit
                    turret = true
                    break
                end
            end
        end
        if alive(unit) and unit:character_damage() and not unit:character_damage()._dead and not managers.enemy:is_civilian(unit) and (managers.enemy:is_enemy(unit) or turret) and ((unit:base() and unit:base()._tweak_table) or turret) then
            self._last_unit = unit
            managers.hud:set_unit_health_visible(true)
            managers.hud:set_unit_health(unit:character_damage()._health or 0, unit:character_damage()._HEALTH_INIT or 0, unit:base()._tweak_table or "swat_turret")
        else
            if self._last_unit and alive(self._last_unit) then
                managers.hud:set_unit_health(self._last_unit:character_damage()._health or 0, self._last_unit:character_damage()._HEALTH_INIT or 0, self._last_unit:base()._tweak_table or "swat_turret")
                managers.hud:set_unit_health_visible(false)
            end
        end
    else
        if self._last_unit and alive(self._last_unit) then
            managers.hud:set_unit_health(self._last_unit:character_damage()._health or 0, self._last_unit:character_damage()._HEALTH_INIT or 0, self._last_unit:base()._tweak_table or "swat_turret")
            managers.hud:set_unit_health_visible(false)
        end
    end
end)

function PlayerStandard:getUnitRotation(unit)
    if not unit or not alive(unit) then return 360 end
    local unit_position = unit:position()
    local vector = self._camera_unit:position() - unit_position
    local forward = self._camera_unit:rotation():y()
    local rotation = math.floor(vector:to_polar_with_reference(forward, math.UP).spin)
    return -(rotation + 180)
end