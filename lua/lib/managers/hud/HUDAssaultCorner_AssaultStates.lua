if Global.game_settings.level_id == "Enemy_Spawner" then
    return
end

SydneyHUD:Hook(GroupAIStateBesiege, "_upd_assault_task", function(self)
    if self._task_data.assault.phase ~= "anticipation" then
        managers.hud._hud_assault_corner:UpdateAssaultState(self._task_data.assault.phase)
    end
end)

SydneyHUD:Hook(HUDManager, "sync_start_anticipation_music", function(self)
    self._hud_assault_corner:UpdateAssaultState("anticipation")
end)

if Network:is_server() then
    function GroupAIStateBase:GetAssaultState()
        return self._task_data.assault.phase
    end

    SydneyHUD:Hook(GroupAIStateBase, "on_enemy_weapons_hot", function(self)
        managers.hud._hud_assault_corner:UpdateAssaultState("control")
        LuaNetworking:SendToPeers("BAI_AssaultState", "control")
    end)
end