local _f_init = EnemyManager.init
function EnemyManager:init()
    _f_init(self)
    if SydneyHUD:GetOption("block_corpses") then
        self._MAX_NR_CORPSES = 0
        self._corpse_disposal_upd_interval = 0
    end
    if SydneyHUD:GetOption("block_shields") then
        self._shield_disposal_upd_interval = 0
        self._shield_disposal_lifetime = 0
        self._MAX_NR_SHIELDS = 0
    end
    if SydneyHUD:GetOption("block_magazines") then
        self.MAX_MAGAZINES = 0
    end
end

local on_enemy_registered_original = EnemyManager.on_enemy_registered
function EnemyManager:on_enemy_registered(unit, ...)
    managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
    return on_enemy_registered_original(self, unit, ...)
end

local on_enemy_unregistered_original = EnemyManager.on_enemy_unregistered
function EnemyManager:on_enemy_unregistered(unit, ...)
    managers.gameinfo:event("unit", "remove", tostring(unit:key()))
    return on_enemy_unregistered_original(self, unit, ...)
end

local register_civilian_original = EnemyManager.register_civilian
function EnemyManager:register_civilian(unit, ...)
    managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
    return register_civilian_original(self, unit, ...)
end

local on_civilian_died_original = EnemyManager.on_civilian_died
function EnemyManager:on_civilian_died(unit, ...)
    managers.gameinfo:event("unit", "remove", tostring(unit:key()))
    return on_civilian_died_original(self, unit, ...)
end

local on_civilian_destroyed_original = EnemyManager.on_civilian_destroyed
function EnemyManager:on_civilian_destroyed(unit, ...)
    managers.gameinfo:event("unit", "remove", tostring(unit:key()))
    return on_civilian_destroyed_original(self, unit, ...)
end

function EnemyManager:get_delayed_clbk_expire_t(clbk_id)
    for _, clbk in ipairs(self._delayed_clbks) do
        if clbk[1] == clbk_id then
            return clbk[2]
        end
    end
end

if SydneyHUD:GetOption("block_corpses") then
    function EnemyManager:corpse_limit()
        return 0
    end
end