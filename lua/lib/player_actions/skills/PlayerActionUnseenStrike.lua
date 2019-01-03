local unseenstrike_original = PlayerAction.UnseenStrike.Function
function PlayerAction.UnseenStrike.Function(player_manager, min_time, ...)
    local function on_player_damage()
        if not player_manager:has_activate_temporary_upgrade("temporary", "unseen_strike") then
            managers.gameinfo:event("buff", "activate", "unseen_strike_debuff")
            managers.gameinfo:event("buff", "set_duration", "unseen_strike_debuff", { duration = min_time })
        end
    end
    
    managers.player:register_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener", on_player_damage)
    unseenstrike_original(player_manager, min_time, ...)
    managers.player:unregister_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener")
end