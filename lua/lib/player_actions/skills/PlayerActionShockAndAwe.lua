local shockandawe_original = PlayerAction.ShockAndAwe.Function
function PlayerAction.ShockAndAwe.Function(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
    local weapon_unit = player_manager:equipped_weapon_unit()
    local min_threshold = min_bullets + (weapon_unit:base():is_category("smg", "assault_rifle", "lmg") and player_manager:upgrade_value("player", "automatic_mag_increase", 0) or 0)
    local max_threshold = math.floor(min_threshold + math.log(min_reload_increase/max_reload_increase) / math.log(penalty))				
    local ammo = weapon_unit:base():get_ammo_max_per_clip()
    local bonus = math.clamp(max_reload_increase * math.pow(penalty, ammo - min_threshold), min_reload_increase, max_reload_increase)
    
    managers.gameinfo:event("buff", "activate", "lock_n_load")
    managers.gameinfo:event("buff", "set_value", "lock_n_load", { value = bonus })
    
    shockandawe_original(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
    
    managers.gameinfo:event("buff", "deactivate", "lock_n_load")
end