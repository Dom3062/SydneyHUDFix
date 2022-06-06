if not SydneyHUD:GetOption("reduce_shotgun_spam") then
    return
end

local _f_init = WeaponTweakData.init
function WeaponTweakData:init(...)
    _f_init(self, ...)
    for key, value in pairs(self) do
        if key:find("_crew") and (value.is_shotgun or value.rays) then
            value.rays = 1
        end
    end
end