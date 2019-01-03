local ammo_efficieny_original = PlayerAction.AmmoEfficiency.Function
function PlayerAction.AmmoEfficiency.Function(player_manager, target_headshots, bullet_refund, target_time, ...)
    local headshots = 0
    
    local function on_headshot_dealt()
        headshots = headshots + 1
        managers.gameinfo:event("buff", "set_stack_count", "ammo_efficiency", { stack_count = target_headshots - headshots })
    end
    
    managers.gameinfo:event("buff", "activate", "ammo_efficiency")
    managers.gameinfo:event("buff", "set_duration", "ammo_efficiency", { expire_t = target_time })
    on_headshot_dealt()
    player_manager:register_message(Message.OnHeadShot, "ammo_efficiency_buff_listener", on_headshot_dealt)
    
    ammo_efficieny_original(player_manager, target_headshots, bullet_refund, target_time, ...)
    
    player_manager:unregister_message(Message.OnHeadShot, "ammo_efficiency_buff_listener")
    managers.gameinfo:event("buff", "deactivate", "ammo_efficiency")
end