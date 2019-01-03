local update_original = PlayerMovement.update
local on_morale_boost_original = PlayerMovement.on_morale_boost

function PlayerMovement:update(unit, t, ...)
    self:_update_radius_buffs(t)
    return update_original(self, unit, t, ...)
end

function PlayerMovement:on_morale_boost(...)
    managers.gameinfo:event("buff", "activate", "inspire")
    managers.gameinfo:event("buff", "set_duration", "inspire", { duration = tweak_data.upgrades.morale_boost_time })
    return on_morale_boost_original(self, ...)
end

local recheck_t = 0
local recheck_interval = 0.5
local FAK_in_range = false
local player_in_smoke = false
function PlayerMovement:_update_radius_buffs(t)
    if t > recheck_t and alive(self._unit) then
        recheck_t = t + recheck_interval
        
        local fak_in_range = FirstAidKitBase.GetFirstAidKit(self._unit:position())
        if fak_in_range ~= FAK_in_range then
            FAK_in_range = fak_in_range
            managers.gameinfo:event("buff", fak_in_range and "activate" or "deactivate", "uppers")
        end
        
        local in_smoke = false
        for _, smoke_screen in ipairs(managers.player:smoke_screens()) do
            if smoke_screen:is_in_smoke(self._unit) then
                in_smoke = true
                break
            end
        end
        
        if in_smoke ~= player_in_smoke then
            player_in_smoke = in_smoke
            managers.gameinfo:event("buff", in_smoke and "activate" or "deactivate", "smoke_screen")
        end
    end
end

Hooks:PostHook( PlayerMovement , "_upd_underdog_skill" , "uHUDPostPlayerMovementUpdUnderdogSkill" , function( self , t )
    if not self._underdog_skill_data.has_dmg_dampener then
        return
    end

    if not self._attackers or self:downed() then
        managers.hud:hide_underdog()
        return
    end

    local my_pos = self._m_pos
    local nr_guys = 0
    local activated
    for u_key, attacker_unit in pairs(self._attackers) do
        if not alive(attacker_unit) then
            self._attackers[u_key] = nil
            managers.hud:hide_underdog()
            return
        end
        local attacker_pos = attacker_unit:movement():m_pos()
        local dis_sq = mvector3.distance_sq(attacker_pos, my_pos)
        if dis_sq < self._underdog_skill_data.max_dis_sq and math.abs(attacker_pos.z - my_pos.z) < 250 then
            nr_guys = nr_guys + 1
            if nr_guys >= self._underdog_skill_data.nr_enemies then
                activated = true
                managers.hud:show_underdog()
            end
        else
        return
        end
    end
end )