function Change()
    if IsMusicChangeAllowed() then
        managers.music:check_music_switch()
    end
end

function IsMusicChangeAllowed()
    local level_name = Global.game_settings.level_id
    return level_name and not SydneyHUD:IsOr(level_name, "tag", "dark", "kosugi", "arena", "fish") or true
    --tag = Breakin' Feds; dark = Murky Station; kosugi = Shadow Raid; arena = The Alesso Heist; fish = The Yacht Heist
end

Change()