if SydneyHUD:IsOr(Global.game_settings.level_id, "Enemy_Spawner", "enemy_spawner2") then
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

function GroupAIStateBase:GetAssaultState()
    return self._task_data.assault.phase
end

--[[if Global.game_settings.level_id == "pbr2" and BAI.IsHost then
    BAI:Hook(GroupAIStateBesiege, "_upd_recon_tasks", function(self)
        if self._task_data.recon.tasks and self._task_data.recon.tasks[1] then
            managers.hud:UpdateAssaultState("control")
            BAI:SyncAssaultState("control", false, true, true)
            BAI:Unhook(nil, "_upd_recon_tasks")
        end
    end)
else
    BAI:Hook(GroupAIStateBase, "on_enemy_weapons_hot", function(self)
        managers.hud:UpdateAssaultState("control")
        BAI:SyncAssaultState("control", false, true, true)
    end)
end]]

SydneyHUD:Hook(GroupAIStateBase, "on_enemy_weapons_hot", function(self)
    managers.hud._hud_assault_corner:UpdateAssaultState("control")
    SydneyHUD:SyncAssaultState("control", false, true, true)
end)