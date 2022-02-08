if BAI then
    return
end

local SydneyHUD = SydneyHUD
if SydneyHUD._cache.ElementAiGlobalEvent then
    return
else
    SydneyHUD._cache.ElementAiGlobalEvent = true
end

local _f_client_on_executed = ElementAiGlobalEvent.client_on_executed
function ElementAiGlobalEvent:client_on_executed(...)
    _f_client_on_executed(self, ...)
    local wave_mode = self._wave_modes[self._values.wave_mode]
    if wave_mode then
        if wave_mode == "hunt" then
            managers.hud:StartEndlessAssault()
        elseif wave_mode == "besiege" then
            managers.hud:SetNormalAssaultOverride()
        end
    end
end