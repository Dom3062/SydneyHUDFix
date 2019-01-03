local check_skills_original = PlayerManager.check_skills
local activate_temporary_upgrade_original = PlayerManager.activate_temporary_upgrade
local activate_temporary_upgrade_by_level_original = PlayerManager.activate_temporary_upgrade_by_level
local deactivate_temporary_upgrade_original = PlayerManager.deactivate_temporary_upgrade
local disable_cooldown_upgrade_original = PlayerManager.disable_cooldown_upgrade
local replenish_grenades_original = PlayerManager.replenish_grenades
local _on_grenade_cooldown_end_original = PlayerManager._on_grenade_cooldown_end
local speed_up_grenade_cooldown_original = PlayerManager.speed_up_grenade_cooldown
local aquire_team_upgrade_original = PlayerManager.aquire_team_upgrade
local unaquire_team_upgrade_original = PlayerManager.unaquire_team_upgrade
local add_synced_team_upgrade_original = PlayerManager.add_synced_team_upgrade
local peer_dropped_out_original = PlayerManager.peer_dropped_out
local _dodge_shot_gain_original = PlayerManager._dodge_shot_gain
local on_killshot_original = PlayerManager.on_killshot
local on_headshot_dealt_original = PlayerManager.on_headshot_dealt
local _on_messiah_recharge_event_original = PlayerManager._on_messiah_recharge_event
local use_messiah_charge_original = PlayerManager.use_messiah_charge
local count_up_player_minions_original = PlayerManager.count_up_player_minions
local count_down_player_minions_original = PlayerManager.count_down_player_minions
local set_synced_cocaine_stacks_original = PlayerManager.set_synced_cocaine_stacks
local chk_wild_kill_counter_original = PlayerManager.chk_wild_kill_counter

local IS_SOCIOPATH = false

function PlayerManager:check_skills(...)
    check_skills_original(self, ...)
    
    managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
    managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
    
    IS_SOCIOPATH = self:has_category_upgrade("player", "killshot_regen_armor_bonus") or
        self:has_category_upgrade("player", "killshot_close_regen_armor_bonus") or
        self:has_category_upgrade("player", "killshot_close_panic_chance") or
        self:has_category_upgrade("player", "melee_kill_life_leech")
end

function PlayerManager:activate_temporary_upgrade(category, upgrade, ...)
    activate_temporary_upgrade_original(self, category, upgrade, ...)
    
    local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
    if data then
        local level = self:upgrade_level(category, upgrade, 0)
        managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
        managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.expire_time })
        managers.gameinfo:event("temporary_buff", "set_value", category, upgrade, level, { value = self:temporary_upgrade_value(category, upgrade) })
    end
end

function PlayerManager:activate_temporary_upgrade_by_level(category, upgrade, level, ...)
    activate_temporary_upgrade_by_level_original(self, category, upgrade, level, ...)
    
    local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
    if data then
        local level = self:upgrade_level(category, upgrade, 0)
        managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
        managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.expire_time })
        managers.gameinfo:event("temporary_buff", "set_value", category, upgrade, level, { value = data.upgrade_value })
    end
end

function PlayerManager:deactivate_temporary_upgrade(category, upgrade, ...)
    local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
    if data then
        local level = self:upgrade_level(category, upgrade, 0)
        managers.gameinfo:event("temporary_buff", "deactivate", category, upgrade, level)
    end
    
    return deactivate_temporary_upgrade_original(self, category, upgrade, ...)
end

function PlayerManager:disable_cooldown_upgrade(category, upgrade, ...)
    disable_cooldown_upgrade_original(self, category, upgrade, ...)
    
    local data = self._global.cooldown_upgrades[category] and self._global.cooldown_upgrades[category][upgrade]
    if data then
        local level = self:upgrade_level(category, upgrade, 0)
        managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
        managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.cooldown_time })
    end
end

function PlayerManager:replenish_grenades(cooldown, ...)
    if not self:has_active_timer("replenish_grenades") then
        local id = managers.blackmarket:equipped_grenade()
        
        if id then
            managers.gameinfo:event("buff", "activate", id .. "_use")
            managers.gameinfo:event("buff", "set_duration", id .. "_use", { duration = cooldown })
        end
    end
    
    return replenish_grenades_original(self, cooldown, ...)
end

function PlayerManager:_on_grenade_cooldown_end(...)
    local id = managers.blackmarket:equipped_grenade()
    
    if id then
        managers.gameinfo:event("buff", "deactivate", id .. "_use")
    end
    
    return _on_grenade_cooldown_end_original(self, ...)
end

function PlayerManager:speed_up_grenade_cooldown(t, ...)
    if self:has_active_timer("replenish_grenades") then
        local id = managers.blackmarket:equipped_grenade()
        
        if id then
            managers.gameinfo:event("buff", "change_expire", id .. "_use", { difference = -t })
        end
    end
    
    return speed_up_grenade_cooldown_original(self, t, ...)
end

function PlayerManager:aquire_team_upgrade(upgrade, ...)
    aquire_team_upgrade_original(self, upgrade, ...)
    managers.gameinfo:event("team_buff", "activate", 0, upgrade.category, upgrade.upgrade, 1)
end

function PlayerManager:unaquire_team_upgrade(upgrade, ...)
    unaquire_team_upgrade_original(self, upgrade, ...)
    managers.gameinfo:event("team_buff", "deactivate", 0, upgrade.category, upgrade.upgrade, 1)
end

function PlayerManager:add_synced_team_upgrade(peer_id, category, upgrade, ...)
    add_synced_team_upgrade_original(self, peer_id, category, upgrade, ...)
    managers.gameinfo:event("team_buff", "activate", peer_id, category, upgrade, 1)
end

function PlayerManager:peer_dropped_out(peer, ...)
    local peer_id = peer:id()
    for category, data in pairs(self._global.synced_team_upgrades[peer_id] or {}) do
        for upgrade, value in pairs(data) do
            managers.gameinfo:event("team_buff", "deactivate", peer_id, category, upgrade, 1)
        end
    end
    
    return peer_dropped_out_original(self, peer, ...)
end

function PlayerManager:_dodge_shot_gain(gain_value, ...)
    if gain_value then
        if gain_value > 0 then
            managers.gameinfo:event("buff", "activate", "sicario_dodge")
            managers.gameinfo:event("buff", "set_value", "sicario_dodge", { value = gain_value * self:upgrade_value("player", "sicario_multiplier", 1) })
            managers.gameinfo:event("buff", "activate", "sicario_dodge_debuff")
            managers.gameinfo:event("buff", "set_duration", "sicario_dodge_debuff", { duration = tweak_data.upgrades.values.player.dodge_shot_gain[1][2] })
        else
            managers.gameinfo:event("buff", "set_value", "sicario_dodge", { value = 0 })
            managers.gameinfo:event("buff", "deactivate", "sicario_dodge")
        end
    end
    
    return _dodge_shot_gain_original(self, gain_value, ...)
end

function PlayerManager:on_killshot(...)
    local last_killshot = self._on_killshot_t
    local result = on_killshot_original(self, ...)
    
    if IS_SOCIOPATH and self._on_killshot_t ~= last_killshot then
        managers.gameinfo:event("buff", "activate", "sociopath_debuff")
        managers.gameinfo:event("buff", "set_duration", "sociopath_debuff", { expire_t = self._on_killshot_t })
    end
    
    return result
end

function PlayerManager:on_headshot_dealt(...)
    local t = Application:time()
    if (self._on_headshot_dealt_t or 0) <= t and self:has_category_upgrade("player", "headshot_regen_armor_bonus") then
        managers.gameinfo:event("buff", "activate", "bullseye_debuff")
        managers.gameinfo:event("buff", "set_duration", "bullseye_debuff", { duration = tweak_data.upgrades.on_headshot_dealt_cooldown or 0 })
    end
    
    return on_headshot_dealt_original(self, ...)
end

function PlayerManager:_on_messiah_recharge_event(...)
    _on_messiah_recharge_event_original(self, ...)

    managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
    managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
end

function PlayerManager:use_messiah_charge(...)
    use_messiah_charge_original(self, ...)
    
    managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
    managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
end

function PlayerManager:count_up_player_minions(...)
    local result = count_up_player_minions_original(self, ...)
    if self._local_player_minions > 0 then
        if self:has_category_upgrade("player", "minion_master_speed_multiplier") then
            managers.gameinfo:event("buff", "activate", "partner_in_crime")
        end
        if self:has_category_upgrade("player", "minion_master_health_multiplier") then
            managers.gameinfo:event("buff", "activate", "partner_in_crime_aced")
        end
    end
    return result
end

function PlayerManager:count_down_player_minions(...)
    local result = count_down_player_minions_original(self, ...)
    if self._local_player_minions <= 0 then
        managers.gameinfo:event("buff", "deactivate", "partner_in_crime")
        managers.gameinfo:event("buff", "deactivate", "partner_in_crime_aced")
    end
    return result
end

function PlayerManager:set_synced_cocaine_stacks(...)
    set_synced_cocaine_stacks_original(self, ...)
    
    local max_stack = 0
    for peer_id, data in pairs(self._global.synced_cocaine_stacks) do
        if data.in_use and data.amount > max_stack then
            max_stack = data.amount
        end
    end
    
    local ratio = max_stack / tweak_data.upgrades.max_total_cocaine_stacks
    managers.gameinfo:event("buff", ratio > 0 and "activate" or "deactivate", "maniac")
    managers.gameinfo:event("buff", "set_value", "maniac", { value = max_stack } )
end

function PlayerManager:chk_wild_kill_counter(...)
    local t = Application:time()
    local player = self:player_unit()
    local expire_t
    local old_stacks = 0
    local do_check = alive(player) and (managers.player:has_category_upgrade("player", "wild_health_amount") or managers.player:has_category_upgrade("player", "wild_armor_amount"))
    
    if do_check then
        local dmg = player:character_damage()
        local missing_health_ratio = math.clamp(1 - dmg:health_ratio(), 0, 1)
        local missing_armor_ratio = math.clamp(1 - dmg:armor_ratio(), 0, 1)
        local less_armor_wild_cooldown = managers.player:upgrade_value("player", "less_armor_wild_cooldown", 0)
        local less_health_wild_cooldown = managers.player:upgrade_value("player", "less_health_wild_cooldown", 0)
        local trigger_cooldown = tweak_data.upgrades.wild_trigger_time or 30

        if less_health_wild_cooldown ~= 0 and less_health_wild_cooldown[1] ~= 0 then
            local missing_health_stacks = math.floor(missing_health_ratio / less_health_wild_cooldown[1])
            trigger_cooldown = trigger_cooldown - less_health_wild_cooldown[2] * missing_health_stacks
        end
        if less_armor_wild_cooldown ~= 0 and less_armor_wild_cooldown[1] ~= 0 then
            local missing_armor_stacks = math.floor(missing_armor_ratio / less_armor_wild_cooldown[1])
            trigger_cooldown = trigger_cooldown - less_armor_wild_cooldown[2] * missing_armor_stacks
        end
        
        expire_t = t + math.max(trigger_cooldown, 0)
    
        if self._wild_kill_triggers then
            old_stacks = #self._wild_kill_triggers
            for i = 1, #self._wild_kill_triggers, 1 do
                if self._wild_kill_triggers[i] > t then
                    break
                end
                old_stacks = old_stacks - 1
            end
        end
    end
    
    chk_wild_kill_counter_original(self, ...)
    
    if do_check and self._wild_kill_triggers and #self._wild_kill_triggers > old_stacks then
        managers.gameinfo:event("timed_stack_buff", "add_timed_stack", "biker", { t = t, expire_t = expire_t })
    end
end

function PlayerManager:update_hostage_skills()
    local stack_count = (managers.groupai:state():hostage_count() or 0) + (self:num_local_minions() or 0)
    local has_hostage = stack_count > 0
    
    if self:has_team_category_upgrade("health", "hostage_multiplier") or self:has_team_category_upgrade("stamina", "hostage_multiplier") or self:has_team_category_upgrade("damage_dampener", "hostage_multiplier") then
        managers.gameinfo:event("buff", has_hostage and "activate" or "deactivate", "hostage_situation")
        
        if has_hostage then
            local value = self:team_upgrade_value("damage_dampener", "hostage_multiplier", 0)
            managers.gameinfo:event("buff", "set_stack_count", "hostage_situation", { stack_count = stack_count })
            managers.gameinfo:event("buff", "set_value", "hostage_situation", { value = value })
        end
    end
    
    if PlayerManager.HAS_HOSTAGE ~= has_hostage then
        PlayerManager.HAS_HOSTAGE = has_hostage
        
        if alive(self:player_unit()) then
            self:player_unit():character_damage():check_passive_regen_buffs("hostage_taker")
        end
    end
end

if SydneyHUD:GetOption("inspire_ace_chat_info") then
    local has_enabled_cooldown_upgrade_original = PlayerManager.has_enabled_cooldown_upgrade
    function PlayerManager:has_enabled_cooldown_upgrade(category, upgrade)
        if category == "cooldown" and upgrade == "long_dis_revive" then
            if self._global.cooldown_upgrades[category][upgrade] then
                local remaining = self._global.cooldown_upgrades[category][upgrade].cooldown_time - Application:time()
                if remaining > 0 then
                    local text = string.format("%.1f sec", remaining)
                    SydneyHUD:SendChatMessage(managers.localization:text("inspire_ace_chat_info"), text, false, "FF9800")
                end
            end
        end
        return has_enabled_cooldown_upgrade_original(self, category, upgrade)
    end
end