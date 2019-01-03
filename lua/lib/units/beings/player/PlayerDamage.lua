local init_original = PlayerDamage.init
local set_health_original = PlayerDamage.set_health
local _upd_health_regen_original = PlayerDamage._upd_health_regen
local _check_bleed_out_original = PlayerDamage._check_bleed_out
local _start_regen_on_the_side_original = PlayerDamage._start_regen_on_the_side
local add_damage_to_hot_original = PlayerDamage.add_damage_to_hot
local _update_delayed_damage_original = PlayerDamage._update_delayed_damage
local delay_damage_original = PlayerDamage.delay_damage
local clear_delayed_damage_original = PlayerDamage.clear_delayed_damage

local CALM_COOLDOWN = false
local CALM_HEALING = false
local DELAYED_DAMAGE_BUFFER_SIZE = 16

function PlayerDamage:init(...)
    init_original(self, ...)
    
    CALM_COOLDOWN = managers.player:has_category_upgrade("player", "damage_control_auto_shrug") and managers.player:upgrade_value("player", "damage_control_auto_shrug") or false
    CALM_HEALING = managers.player:has_category_upgrade("player", "damage_control_healing") and (managers.player:upgrade_value("player", "damage_control_healing") * 0.01) or false
    DELAYED_DAMAGE_BUFFER_SIZE = math.round(1 / (tweak_data.upgrades.values.player.damage_control_passive[1][2] * 0.01))
    
    if managers.player:has_category_upgrade("player", "damage_to_armor") then
        CopDamage.register_listener("anarchist_debuff_listener", {"on_damage"}, function(dmg_info)
            local attacker = dmg_info and dmg_info.attacker_unit
            if alive(attacker) and attacker:base() and attacker:base().thrower_unit then
                attacker = attacker:base():thrower_unit()
            end
        
            if self._unit == attacker then
                local t = Application:time()
                local data = self._damage_to_armor
                if (data.elapsed == t) or (t - data.elapsed > data.target_tick) then
                    managers.gameinfo:event("buff", "activate", "anarchist_armor_recovery_debuff")
                    managers.gameinfo:event("buff", "set_duration", "anarchist_armor_recovery_debuff", { t = t, duration = data.target_tick })
                end
            end
        end)
    end
end

local HEALTH_RATIO_BONUSES = {
    melee_damage_health_ratio_multiplier = { category = "melee", buff_id = "berserker", offset = 1 },
    damage_health_ratio_multiplier = { category = "damage", buff_id = "berserker_aced", offset = 1 },
    armor_regen_damage_health_ratio_multiplier = { category = "armor_regen", buff_id = "yakuza_recovery" },
    movement_speed_damage_health_ratio_multiplier = { category = "movement_speed", buff_id = "yakuza_speed" },
}
local LAST_HEALTH_RATIO = 0
function PlayerDamage:set_health(...)
    local was_hurt = self:_max_health() > (self:get_real_health() + 0.001)

    set_health_original(self, ...)
    
    local health_ratio = self:health_ratio()
    
    if health_ratio ~= LAST_HEALTH_RATIO then
        local is_hurt = self:_max_health() > (self:get_real_health() + 0.001)
        LAST_HEALTH_RATIO = health_ratio
    
        for upgrade, data in pairs(HEALTH_RATIO_BONUSES) do
            if managers.player:has_category_upgrade("player", upgrade) then
                local bonus_ratio = managers.player:get_damage_health_ratio(health_ratio, data.category)
                local value = (data.offset or 0) + managers.player:upgrade_value("player", upgrade, 0) * bonus_ratio
                managers.gameinfo:event("buff", bonus_ratio > 0 and "activate" or "deactivate", data.buff_id)
                managers.gameinfo:event("buff", "set_value", data.buff_id, { value = value })
            end
        end
        
        if managers.player:has_category_upgrade("player", "passive_damage_reduction") then
            local threshold = managers.player:upgrade_value("player", "passive_damage_reduction")
            local value = managers.player:team_upgrade_value("damage_dampener", "team_damage_reduction")
            if health_ratio < threshold then
                value = 2 * value - 1
            end
            managers.gameinfo:event("buff", "set_value", "cc_passive_damage_reduction", { value = value })
        end
        
        if was_hurt ~= is_hurt then
            self:check_passive_regen_buffs()
        end
    end
end

function PlayerDamage:_upd_health_regen(...)
    _upd_health_regen_original(self, ...)
    
    if self._health_regen_update_timer and self._health_regen_update_timer >= 5 then
        self:check_passive_regen_buffs()
    end
end

function PlayerDamage:_check_bleed_out(...)
    local last_uppers = self._uppers_elapsed or 0
    
    local result = _check_bleed_out_original(self, ...)
    
    if (self._uppers_elapsed or 0) > last_uppers then
        managers.gameinfo:event("buff", "activate", "uppers_debuff")
        managers.gameinfo:event("buff", "set_duration", "uppers_debuff", { duration = self._UPPERS_COOLDOWN })
    end
end

function PlayerDamage:_start_regen_on_the_side(time, ...)
    if self._regen_on_the_side_timer <= 0 and time > 0 then
        managers.gameinfo:event("buff", "activate", "tooth_and_claw")
        managers.gameinfo:event("buff", "set_duration", "tooth_and_claw", { duration = time })
    end
    
    return _start_regen_on_the_side_original(self, time, ...)
end

function PlayerDamage:add_damage_to_hot(...)
    if not (self:got_max_doh_stacks() or self:need_revive() or self:dead() or self._check_berserker_done) then
        local stack_duration = ((self._doh_data.total_ticks or 1) + managers.player:upgrade_value("player", "damage_to_hot_extra_ticks", 0)) * (self._doh_data.tick_time or 1)
        managers.gameinfo:event("buff", "activate", "grinder_debuff")
        managers.gameinfo:event("buff", "set_duration", "grinder_debuff", { duration = tweak_data.upgrades.damage_to_hot_data.stacking_cooldown })
        managers.gameinfo:event("timed_stack_buff", "add_timed_stack", "grinder", { duration = stack_duration })
    end
    
    return add_damage_to_hot_original(self, ...)
end

local DELAYED_DAMAGE_BUFFER = {}
local DELAYED_DAMAGE_TOTAL = 0
local DELAYED_DAMAGE_BUFFER_INDEX = 0
function PlayerDamage:_update_delayed_damage(t, ...)
    if self._delayed_damage.next_tick and t >= self._delayed_damage.next_tick then
        --managers.gameinfo:event("buff", "set_duration", "virtue_debuff", { duration = 1, no_expire = true })
        
        if DELAYED_DAMAGE_TOTAL > 0 then
            DELAYED_DAMAGE_TOTAL = DELAYED_DAMAGE_TOTAL - DELAYED_DAMAGE_BUFFER[DELAYED_DAMAGE_BUFFER_INDEX + 1]
            DELAYED_DAMAGE_BUFFER[DELAYED_DAMAGE_BUFFER_INDEX + 1] = 0
            DELAYED_DAMAGE_BUFFER_INDEX = (DELAYED_DAMAGE_BUFFER_INDEX + 1) % DELAYED_DAMAGE_BUFFER_SIZE
            managers.gameinfo:event("buff", "set_value", "virtue_debuff", { value = math.round(DELAYED_DAMAGE_TOTAL * 10) })
        else
            DELAYED_DAMAGE_TOTAL = 0
        end
    end
    
    return _update_delayed_damage_original(self, t, ...)
end

function PlayerDamage:delay_damage(damage, seconds, ...)
    if not self._delayed_damage.next_tick then
        managers.gameinfo:event("buff", "activate", "virtue_debuff")
        
        if CALM_COOLDOWN then
            managers.gameinfo:event("buff", "activate", "calm")
        end
    end
    
    if CALM_COOLDOWN then
        managers.gameinfo:event("buff", "set_duration", "calm", { duration = CALM_COOLDOWN })
    end

    local tick_dmg = damage / seconds
    for i = 1, DELAYED_DAMAGE_BUFFER_SIZE, 1 do
        DELAYED_DAMAGE_BUFFER[i] = (DELAYED_DAMAGE_BUFFER[i] or 0) + tick_dmg
    end
    DELAYED_DAMAGE_TOTAL = DELAYED_DAMAGE_TOTAL + damage
    
    local t = self._delayed_damage.next_tick and (self._delayed_damage.next_tick - 1) or TimerManager:game():time()
    local expire_t = t + DELAYED_DAMAGE_BUFFER_SIZE
    
    managers.gameinfo:event("buff", "set_duration", "virtue_debuff", { t = t, expire_t = expire_t })
    managers.gameinfo:event("buff", "set_value", "virtue_debuff", { value = math.round(DELAYED_DAMAGE_TOTAL * 10) })
    
    return delay_damage_original(self, damage, seconds, ...)
end

function PlayerDamage:clear_delayed_damage(...)
    DELAYED_DAMAGE_BUFFER = {}
    DELAYED_DAMAGE_TOTAL = 0

    managers.gameinfo:event("buff", "deactivate", "virtue_debuff")
    managers.gameinfo:event("buff", "deactivate", "calm")

    return clear_delayed_damage_original(self, ...)
end


local MUSCLE_REGEN_ACTIVE = false
local HOSTAGE_REGEN_ACTIVE = false
local PASSIVE_REGEN_BUFFS = {
    hostage_taker = { 
        category = "player", 
        upgrade = "hostage_health_regen_addend", 
        check = function() return PlayerManager.HAS_HOSTAGE end,
    },
    muscle_regen = { 
        category = "player",
        upgrade = "passive_health_regen",
    },
}
function PlayerDamage:check_passive_regen_buffs(buff)
    local is_hurt = self:_max_health() > (self:get_real_health() + 0.001)
    
    for buff_id, data in pairs(PASSIVE_REGEN_BUFFS) do
        if not buff or buff == buff_id then
            local value = managers.player:upgrade_value(data.category, data.upgrade, 0)
            local can_use = value > 0 and (not data.check or data.check())
            
            if is_hurt and can_use then
                local t = Application:time()
                local start_t = t - (5 - (self._health_regen_update_timer or 5))
                local expire_t = start_t + 5
                managers.gameinfo:event("buff", "activate", buff_id)
                managers.gameinfo:event("buff", "set_value", buff_id, { value = value })
                managers.gameinfo:event("buff", "set_duration", buff_id, { t = start_t, expire_t = expire_t })
            else
                managers.gameinfo:event("buff", "deactivate", buff_id)
            end
        end
    end
end