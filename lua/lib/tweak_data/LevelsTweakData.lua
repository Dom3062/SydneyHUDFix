local _f_get_music_event = LevelsTweakData.get_music_event
function LevelsTweakData:get_music_event(stage)
    local result = _f_get_music_event(self, stage)
    if result and stage == "control" and SydneyHUD:GetOption("shuffle_music") then
        if self.can_change_music then
            managers.music:check_music_switch()
        else
            self.can_change_music = true
        end
    end
    return result
end