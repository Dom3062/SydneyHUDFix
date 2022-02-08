local register_turret_original = GroupAIStateBase.register_turret
local unregister_turret_original = GroupAIStateBase.unregister_turret
local update_original = GroupAIStateBase.update
local on_hostage_state_original = GroupAIStateBase.on_hostage_state
local sync_hostage_headcount_original = GroupAIStateBase.sync_hostage_headcount
local convert_hostage_to_criminal_original = GroupAIStateBase.convert_hostage_to_criminal
local sync_converted_enemy_original = GroupAIStateBase.sync_converted_enemy
local _upd_criminal_suspicion_progress_original = GroupAIStateBase._upd_criminal_suspicion_progress
function GroupAIStateBase:update(t, ...)
    if self._client_hostage_count_expire_t and t < self._client_hostage_count_expire_t then
        self:_client_hostage_count_cbk()
    end

    return update_original(self, t, ...)
end

function GroupAIStateBase:on_hostage_state(...)
    on_hostage_state_original(self, ...)
    self:_update_hostage_count()
end

function GroupAIStateBase:sync_hostage_headcount(...)
    sync_hostage_headcount_original(self, ...)
    managers.player:update_hostage_skills()
    if Network:is_server() then
        self:_update_hostage_count()
    else
        self._client_hostage_count_expire_t = self._t + 10
    end
end

function GroupAIStateBase:convert_hostage_to_criminal(unit, peer_unit, ...)
    convert_hostage_to_criminal_original(self, unit, peer_unit, ...)
    
    if unit:brain()._logic_data.is_converted then
        local key = tostring(unit:key())
        local peer_id = peer_unit and managers.network:session():peer_by_unit(peer_unit):id() or managers.network:session():local_peer():id()
        local owner_base = peer_unit and peer_unit:base() or managers.player
        local damage_mult = (owner_base:upgrade_value("player", "convert_enemies_damage_multiplier", 1) or 1)
        
        managers.gameinfo:event("minion", "add", key, { unit = unit })
        managers.gameinfo:event("minion", "set_owner", key, { owner = peer_id })
        if damage_mult > 1 then
            managers.gameinfo:event("minion", "set_damage_multiplier", key, { damage_multiplier = damage_mult })
        end
    end
end

function GroupAIStateBase:sync_converted_enemy(converted_enemy, ...)
    managers.gameinfo:event("minion", "add", tostring(converted_enemy:key()), { unit = converted_enemy })
    return sync_converted_enemy_original(self, converted_enemy, ...)
end

function GroupAIStateBase:register_turret(unit, ...)
    managers.gameinfo:event("turret", "add", tostring(unit:key()), unit)
    return register_turret_original(self, unit, ...)
end

function GroupAIStateBase:unregister_turret(unit, ...)
    managers.gameinfo:event("turret", "remove", tostring(unit:key()), unit)
    return unregister_turret_original(self, unit, ...)
end

function GroupAIStateBase:_client_hostage_count_cbk()
    local police_hostages = 0
    local police_hostages_mk2 = 0
    local civilian_hostages = self._hostage_headcount

    for u_key, u_data in pairs(managers.enemy:all_enemies()) do
        if u_data and u_data.unit and u_data.unit.anim_data and u_data.unit:anim_data() then
            if u_data.unit:anim_data().surrender then
                police_hostages = police_hostages + 1
            end
        end
    end
    
    civilian_hostages = civilian_hostages - police_hostages
    managers.gameinfo:event("unit_count", "set", "civ_hostage", civilian_hostages)
    managers.gameinfo:event("unit_count", "set", "cop_hostage", police_hostages)
end

function GroupAIStateBase:_update_hostage_count()
    if Network:is_server() then
        managers.gameinfo:event("unit_count", "set", "civ_hostage", self._hostage_headcount - self._police_hostage_headcount)
        managers.gameinfo:event("unit_count", "set", "cop_hostage", self._police_hostage_headcount)
    else
        self:_client_hostage_count_cbk()
    end
end

local set_whisper_mode_original = GroupAIStateBase.set_whisper_mode
function GroupAIStateBase:set_whisper_mode(enabled, ...)
    set_whisper_mode_original(self, enabled, ...)
    managers.hud:set_hud_mode(enabled and "stealth" or "loud")
    managers.gameinfo:event("whisper_mode", "change", nil, enabled)
end

function GroupAIStateBase:_update_hostage_count()
    if Network:is_server() then
        managers.gameinfo:event("unit_count", "set", "civ_hostage", self._hostage_headcount - self._police_hostage_headcount)
        managers.gameinfo:event("unit_count", "set", "cop_hostage", self._police_hostage_headcount)
    else
        self:_client_hostage_count_cbk()
    end
end

function GroupAIStateBase:_upd_criminal_suspicion_progress(...)
    if self._ai_enabled then
        for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
            local unit = obs_susp_data.u_observer
            if managers.enemy:is_civilian(unit) then
                local waypoint = managers.hud._hud.waypoints["susp1" .. tostring(obs_key)]
                if waypoint then
                    local color, arrow_color
                    if SydneyHUD:GetOption("enable_pacified") and unit:anim_data().drop then
                        if not obs_susp_data._subdued_civ then
                            obs_susp_data._alerted_civ = nil
                            obs_susp_data._subdued_civ = true
                            color = Color(0.0, 1.0, 0.0)
                            arrow_color = Color(0.0, 0.3, 0.0)
                        end
                    elseif obs_susp_data.alerted then
                        if not obs_susp_data._alerted_civ then
                            obs_susp_data._subdued_civ = nil
                            obs_susp_data._alerted_civ = true
                            color = Color.white
                            arrow_color = tweak_data.hud.detected_color
                        end
                    end
                    if color then
                        waypoint.bitmap:set_color(color)
                        waypoint.arrow:set_color(arrow_color:with_alpha(0.75))
                    end
                end
            end
        end
    end
    return _upd_criminal_suspicion_progress_original(self, ...)
end

local register_ecm_jammer_original = GroupAIStateBase.register_ecm_jammer
function GroupAIStateBase:register_ecm_jammer(unit, jam_settings, ...)
    if alive(unit) and not (unit:base() and unit:base().battery_life_multiplier) then
        local key = tostring(unit:key())
        
        if jam_settings then
            local max_duration = tweak_data.upgrades.values.player.pocket_ecm_jammer_base[1].duration
            local t = Application:time()
            local expire_t = t + max_duration
            
            managers.gameinfo:event("ecm", "create", key, { is_pocket_ecm = true, unit = unit, t = t, expire_t = expire_t, max_duration = max_duration })
            managers.gameinfo:event("ecm", "set_jammer_active", key, { jammer_active = true })
        else
            managers.gameinfo:event("ecm", "set_jammer_active", key, { jammer_active = false })
            managers.gameinfo:event("ecm", "destroy", key)
        end
    end
    return register_ecm_jammer_original(self, unit, jam_settings, ...)
end

if not BAI then
    local load_original = GroupAIStateBase.load
    function GroupAIStateBase:load(load_data, ...)
        load_original(self, load_data, ...)
        local law1team = self._teams[tweak_data.levels:get_default_team_ID("combatant")]
        if law1team then
            if self._hunt_mode and not law1team.damage_reduction then
                managers.hud:SetEndlessClient()
            end
        elseif self._hunt_mode then
            managers.hud:SetEndlessClient()
        end
    end
end