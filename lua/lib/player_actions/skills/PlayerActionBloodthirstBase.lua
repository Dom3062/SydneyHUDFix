local bloodthirstbase_original = PlayerAction.BloodthirstBase.Function
function PlayerAction.BloodthirstBase.Function(player_manager, melee_multiplier, max_multiplier, ...)
    local multiplier = 1
    
    local function on_enemy_killed()
        if multiplier < max_multiplier then
            multiplier = math.min(multiplier + melee_multiplier, max_multiplier)
            managers.gameinfo:event("buff", "increment_stack_count", "bloodthirst_basic")
            managers.gameinfo:event("buff", "set_value", "bloodthirst_basic", { value = multiplier })
        end
    end
    
    managers.gameinfo:event("buff", "activate", "bloodthirst_basic")
    on_enemy_killed()
    player_manager:register_message(Message.OnEnemyKilled, "bloodthirst_basic_buff_listener", on_enemy_killed)
    
    bloodthirstbase_original(player_manager, melee_multiplier, max_multiplier, ...)
    
    player_manager:unregister_message(Message.OnEnemyKilled, "bloodthirst_basic_buff_listener")
    managers.gameinfo:event("buff", "deactivate", "bloodthirst_basic")
end