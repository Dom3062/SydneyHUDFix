-- This hack allows us to reroute every call for texts.
local spacer = string.rep(" ", 10)
local sep = string.format("%s%s%s", spacer, managers.localization:text("hud_assault_end_line"), spacer)
local crimespree = managers.crime_spree:is_active()
local skirmish = managers.skirmish:is_skirmish()
local tweak, gai_state, assault_data, get_value, get_mult
if Network:is_server() then
    tweak = tweak_data.group_ai.besiege.assault
    gai_state = managers.groupai:state()
    assault_data = gai_state and gai_state._task_data.assault
    get_value = gai_state._get_difficulty_dependent_value or function() return 0 end
    get_mult = gai_state._get_balancing_multiplier or function() return 0 end
end
local text_original = LocalizationManager.text
function LocalizationManager:text(string_id, macros)
    if string_id == "hud_assault_info" then
        return self:hud_assault_enhanced()
    end
    if string_id == "hud_assault_phase" then
        return self:hud_phase()
    end
    return text_original(self, string_id, macros)
end

function LocalizationManager:SetClient()
    self.is_client = true
end

function LocalizationManager:SetSynchronization(setter)
    self.synchronize_time = setter
end

function LocalizationManager:hud_assault_enhanced()
    if self.is_client then
        local time
        if SydneyHUD:GetOption("enhanced_assault_time") then
            local client_time_left = managers.hud._hud_assault_corner:GetTimeLeft()
            if client_time_left < 0 then
                time = self:text("hud_time_left") .. self:text("hud_overdue")
            else
                if SydneyHUD:IsOr(SydneyHUD:GetOption("time_format"), 1, 2) then
                    time = self:text("hud_time_left") .. " " .. string.format("%.2f", client_time_left)
                    if SydneyHUD:GetOption("time_format") == 2 then
                        time = time .. " " .. self:text("hud_s")
                    end
                elseif SydneyHUD:IsOr(SydneyHUD:GetOption("time_format"), 3, 4) then
                    time = self:text("hud_time_left") .. " " .. string.format("%.0f", client_time_left)
                    if SydneyHUD:GetOption("time_format") == 4 then
                        time = time .. "  " .. self:text("hud_s")
                    end
                else
                    local min = math.floor(client_time_left / 60)
                    local s = math.floor(client_time_left % 60)
                    if s >= 60 then
                        s = s - 60
                        min = min + 1
                    end
                    if SydneyHUD:GetOption("time_format") == 5 then
                        time = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s%s%.0f%s%s", min, " ", self:text("hud_min"), "  ", s, " ", self:text("hud_s"))
                    else
                        time = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s", min, ":", (s <= 9 and "0" .. string.format("%.0f", s) or string.format("%.0f", s)))
                    end
                end
            end
        end
        if SydneyHUD:GetOption("enhanced_assault_count") then
            if not time then
                time = self:text("hud_wave") .. string.format("%d", managers.hud._hud_assault_corner._wave_number)
            else
                time = time .. sep .. self:text("hud_wave").. string.format("%d", managers.hud._hud_assault_corner._wave_number)
            end
        end
        return time
    end
    
    local groupaistate = managers.groupai:state()
    local finaltext
    local spawns = groupaistate:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.force_pool) * groupaistate:_get_balancing_multiplier(tweak_data.group_ai.besiege.assault.force_pool_balance_mul)
    if SydneyHUD:GetOption("enhanced_assault_spawns") then
        finaltext = self:text("hud_spawns_left") .. string.format("%d", spawns - groupaistate._task_data.assault.force_spawned)
    end
    if SydneyHUD:GetOption("enhanced_assault_time") then
        if not finaltext then
            finaltext = self:text("hud_time_left")
        else
            finaltext = finaltext .. sep .. self:text("hud_time_left")
        end
        local add
        local atime = groupaistate._task_data.assault.phase_end_t - groupaistate._t
        if crimespree then
            local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), 0.5) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
            add = managers.modifiers:modify_value("GroupAIStateBesiege:SustainEndTime", sustain_duration) - sustain_duration
        end
        if assault_data.phase == "build" then
            local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), 0.5) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
            atime = atime + sustain_duration + tweak.fade_duration
            if add then
                atime = atime + add
            end
            if skirmish then
                atime = 140 - (assault_data.phase_end_t - groupaistate._t) -- 140 is precalculated from SkirmishTweakData.lua
            end
        elseif assault_data.phase == "sustain" then
            atime = atime + tweak.fade_duration
            if add then
                atime = atime + add
            end
        end

        if self.synchronize_time then
            LuaNetworking:SendToPeers("BAI_AdvancedAssaultInfo_TimeLeft", time_left)
            self.synchronize_time = false
        end

        if atime < 0 then
            finaltext = finaltext .. self:text("hud_overdue")
        else
            if SydneyHUD:IsOr(SydneyHUD:GetOption("time_format"), 1, 2) then
                finaltext = finaltext .. string.format("%.2f", atime)
                if SydneyHUD:GetOption("time_format") == 2 then
                    finaltext = finaltext .. " " .. self:text("hud_s")
                end
            elseif SydneyHUD:IsOr(SydneyHUD:GetOption("time_format"), 3, 4) then
                finaltext = finaltext .. string.format("%.0f", atime)
                if SydneyHUD:GetOption("time_format") == 4 then
                    finaltext = finaltext .. " " .. self:text("hud_s")
                end
            else
                local min = math.floor(atime / 60)
                local s = math.floor(atime % 60)
                if s >= 60 then
                    s = s - 60
                    min = min + 1
                end
                if SydneyHUD:GetOption("time_format") == 5 then
                    finaltext = finaltext .. " " .. string.format("%.0f%s%s%s%.0f%s%s", min, " ", self:text("hud_min"), "  ", s, " ", self:text("hud_s"))
                else
                    finaltext = finaltext .. " " .. string.format("%.0f%s%s", min, ":", (s <= 9 and "0" .. string.format("%.0f", s) or string.format("%.0f", s)))
                end
            end
        end
    end
    if SydneyHUD:GetOption("enhanced_assault_count") then
        if not finaltext then
            finaltext = self:text("hud_wave")
        else
            finaltext = finaltext .. sep .. self:text("hud_wave")
        end
        finaltext = finaltext .. string.format("%d", managers.hud._hud_assault_corner._wave_number)
    end
    return finaltext
end

function LocalizationManager:hud_phase()
    return self:text("hud_phase") .. " " .. self:text("hud_" .. managers.hud._hud_assault_corner.assault_state)
end