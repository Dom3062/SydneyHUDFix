local OnPlayerManagerKillshot_original = GageModifierLifeSteal.OnPlayerManagerKillshot
function GageModifierLifeSteal:OnPlayerManagerKillshot(...)
    OnPlayerManagerKillshot_original(self, ...)

    if self._last_killshot_t == TimerManager:game():time() then
        managers.gameinfo:event("buff", "activate", "self_healer_debuff")
        managers.gameinfo:event("buff", "set_duration", "self_healer_debuff", { duration = self:value("cooldown") })
    end
end