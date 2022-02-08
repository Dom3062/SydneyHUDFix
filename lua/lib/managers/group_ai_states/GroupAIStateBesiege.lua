if not BAI then
    SydneyHUD:PreHook(GroupAIStateBesiege, "set_wave_mode", function(self, flag)
        if managers.hud._hud_assault_corner:get_assault_mode() ~= "phalanx" and flag == "besiege" and self._hunt_mode then
            managers.hud:SetNormalAssaultOverride()
        end
    end)
end