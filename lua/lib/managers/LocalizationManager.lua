-- This hack allows us to reroute every call for texts.
local spacer = string.rep(" ", 10)
local sep = string.format("%s%s%s", spacer, managers.localization:text("hud_assault_end_line"), spacer)
local crimespree = managers.crime_spree:is_active()
local assault_extender = false
local tweak, gai_state, assault_data, get_value, get_mult
if Network:is_server() then
    tweak = tweak_data.group_ai.besiege.assault
    if managers.skirmish and managers.skirmish:is_skirmish() then
        tweak = tweak_data.group_ai.skirmish.assault
    end
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

function LocalizationManager:SetVariables(client)
    self.show_spawns_left = SydneyHUD:GetOption("enhanced_assault_spawns")
    self.show_time_left = SydneyHUD:GetOption("enhanced_assault_time")
    self.time_left_format = SydneyHUD:GetOption("time_format")
    self.show_wave_number = SydneyHUD:GetOption("enhanced_assault_count")
    self.is_client = client
end

function LocalizationManager:CSAE_Activate()
    assault_extender = true
end

function LocalizationManager:hud_assault_enhanced()
    if tweak and gai_state and assault_data and assault_data.active then
        local s = nil

        if self.show_spawns_left then
            local spawns = get_value(gai_state, tweak.force_pool) * get_mult(gai_state, tweak.force_pool_balance_mul)
            local spawns_left = self:text("hud_spawns_left") .. "  " .. math.round(math.max(spawns - assault_data.force_spawned, 0))
            s = string.format("%s", spawns_left)
        end

        if self.show_time_left then
            local add
            local time_left = assault_data.phase_end_t - gai_state._t -- Removing 350 here will make Time Left more accurate
            if crimespree or assault_extender then
                local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), math.random()) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
                add = managers.modifiers:modify_value("GroupAIStateBesiege:SustainEndTime", sustain_duration) - sustain_duration
                if add == 0 and gai_state._assault_number == 1 and assault_data.phase == "build" then
                    add = sustain_duration / 2 
                end
            end
            if assault_data.phase == "build" then
                local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), math.random()) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
                time_left = time_left + sustain_duration + tweak.fade_duration
                if add then
                    time_left = time_left + add
                end
            elseif assault_data.phase == "sustain" then
                time_left = time_left + tweak.fade_duration
                if add then
                    time_left = time_left + add
                end
            end

            if time_left < 0 then
                time_left = self:text("hud_time_left") .. " " .. self:text("hud_overdue")
            else
                if self.time_left_format == 1 or self.time_left_format == 2 then
                    time_left = self:text("hud_time_left") .. " " .. string.format("%.2f", time_left)
                    if self.time_left_format == 2 then
                        time_left = time_left .. " " .. self:text("hud_s")
                    end
                elseif self.time_left_format == 3 or self.time_left_format == 4 then
                    time_left = self:text("hud_time_left") .. " " .. string.format("%.0f", time_left)
                    if self.time_left_format == 4 then
                        time_left = time_left .. "  " .. self:text("hud_s")
                    end
                else
                    local min = math.floor(time_left / 60)
                    local s = math.floor(time_left % 60)
                    if s >= 60 then
                        s = s - 60
                        min = min + 1
                    end
                    if self.time_left_format == 5 then
                        time_left = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s%s%.0f%s%s", min, " ", self:text("hud_min"), "  ", s, " ", self:text("hud_s"))
                    else
                        time_left = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s", min, ":", (s <= 9 and "0" .. string.format("%.0f", s) or string.format("%.0f", s)))
                    end
                end
            end
            if s then
                s = string.format("%s%s%s", s, sep, time_left)
            else
                s = string.format("%s", time_left)
            end
        end

        if self.show_wave_number then
            if s then
                s = s .. sep .. self:text("hud_wave")
            else
                s = self:text("hud_wave")
            end
            s = s .. string.format("%d", gai_state._assault_number)
        end
        
        if s then
            return s
        end
        return self:text("hud_time_left") .. " " .. self:text("hud_overdue")
    end

    if self.is_client then
        local time
        if self.show_time_left then
            local client_time_left = managers.hud._hud_assault_corner:GetTimeLeft()
            if client_time_left < 0 then
                time = self:text("hud_time_left") .. " " .. self:text("hud_overdue")
            else
                if SydneyHUD:IsOr(self.time_format, 1, 2) then
                    time = self:text("hud_time_left") .. " " .. string.format("%.2f", client_time_left)
                    if self.time_format == 2 then
                        time = time .. " " .. self:text("hud_s")
                    end
                elseif SydneyHUD:IsOr(self.time_format, 3, 4) then
                    time = self:text("hud_time_left") .. " " .. string.format("%.0f", client_time_left)
                    if self.time_format == 4 then
                        time = time .. "  " .. self:text("hud_s")
                    end
                else
                    local min = math.floor(client_time_left / 60)
                    local s = math.floor(client_time_left % 60)
                    if s >= 60 then
                        s = s - 60
                        min = min + 1
                    end
                    if self.time_format == 5 then
                        time = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s%s%.0f%s%s", min, " ", self:text("hud_min"), "  ", s, " ", self:text("hud_s"))
                    else
                        time = self:text("hud_time_left") .. " " .. string.format("%.0f%s%s", min, ":", (s <= 9 and "0" .. string.format("%.0f", s) or string.format("%.0f", s)))
                    end
                end
            end
        end
        if self.show_wave_number then
            if not time then
                time = self:text("hud_wave") .. string.format("%d", managers.hud._hud_assault_corner._wave_number)
            else
                time = time .. sep .. self:text("hud_wave").. string.format("%d", managers.hud._hud_assault_corner._wave_number)
            end
        end
        return time or (self:text("hud_time_left") .. "" .. self:text("hud_overdue"))
    end
    return self:text("hud_time_left") .. " " .. self:text("hud_overdue")
end

function LocalizationManager:hud_phase()
    return self:text("hud_phase") .. " " .. self:text("hud_" .. managers.hud._hud_assault_corner.assault_state)
end