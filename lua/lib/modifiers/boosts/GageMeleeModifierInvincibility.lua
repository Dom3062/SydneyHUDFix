local OnPlayerManagerKillshot_original = GageModifierMeleeInvincibility.OnPlayerManagerKillshot
function GageModifierMeleeInvincibility:OnPlayerManagerKillshot(...)
    OnPlayerManagerKillshot_original(self, ...)
    
    if self._special_kill_t == TimerManager:game():time() then
        managers.gameinfo:event("buff", "activate", "some_invulnerability_debuff")
        managers.gameinfo:event("buff", "set_duration", "some_invulnerability_debuff", { duration = self:value() })
    end
end