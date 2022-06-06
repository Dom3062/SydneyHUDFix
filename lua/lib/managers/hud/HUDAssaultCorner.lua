local function HideHostages(self)
    self:_hide_hostages()
    self._hide_hostages = function() end
    self._show_hostages = function() end
end

local init_original = HUDAssaultCorner.init
function HUDAssaultCorner:init(hud, full_hud, tweak_hud)
    init_original(self, hud, full_hud, tweak_hud)
    self.center_assault_banner = SydneyHUD:GetOption("center_assault_banner")
    self.hudlist_enemy = SydneyHUD:GetModOption("hudlist", "show_enemies")
    self.hudlist_enabled = SydneyHUD:GetModOption("hudlist", "enabled")
    if SydneyHUD:GetOption("hide_hostage_panel") then
        HideHostages(self)
    end
    if not BAI then -- Initialize these variables when BAI is not installed or running
        self._assault_endless_color = Color.red
        self._state_control_color = Color.white
        self._state_anticipation_color = Color(255, 186, 204, 28) / 255
        self._state_build_color = Color(255, 255, 255, 0) / 255
        self._state_sustain_color = Color(255, 237, 127, 127) / 255
        self._state_fade_color = Color(255, 0, 255, 255) / 255
        local level_id = Global.game_settings.level_id
        -- Framing Frame Day 1, Art Gallery, Watch Dogs Day 2, Hell's Island
        self._no_endless_assault_override = table.contains({ "framing_frame_1", "gallery", "watchdogs_2", "bph" }, level_id)
        self.endless_client = false
        self.is_host = Network:is_server()
        self.is_client = not self.is_host
        self.is_skirmish = managers.skirmish and managers.skirmish:is_skirmish() or false
        self.is_crimespree = managers.crime_spree and managers.crime_spree:is_active() or false
        self.CompatibleHost = false
        self.BAIHost = false
        dofile(SydneyHUD.LuaPath .. "lib/managers/LocalizationManager.lua")
        dofile(SydneyHUD.LuaPath .. "lib/managers/hud/HUDAssaultCorner_AssaultStates.lua")
        dofile(SydneyHUD.LuaPath .. "lib/managers/hud/HUDAssaultCorner_AssaultTime.lua")
        dofile(SydneyHUD.LuaPath .. "lib/managers/group_ai_states/GroupAIStateBesiege.lua")
        dofile(SydneyHUD.LuaPath .. "SydneyAnimation.lua")
        if self.is_client then
            self.diff = self:GetCorrectDiff(level_id)
        end
        self.assault_state = "nil"
        self.show_popup = true
        if (managers.mutators and managers.mutators:are_mutators_active() and Global.mutators.active_on_load["MutatorAssaultExtender"]) or (self.is_crimespree and managers.crime_spree:DoesServerHasAssaultExtenderModifier()) then
            self.assault_extender_modifier = true
        end
        SydneyHUD:EasterEggInit()
        if self.is_host and self.assault_extender_modifier then
            managers.localization:CSAE_Activate()
        end
        managers.localization:SetVariables(self.is_client)
        self.spam =
        {
            ["build"] = "Build",
            ["sustain"] = "Sustain",
            ["fade"] = "Fade"
        }
    end
    if self._hud_panel:child("hostages_panel") and self.hudlist_enabled then
        HideHostages(self)
    end
    if self.center_assault_banner then
        self._hud_panel:child("assault_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_visible(false)
        self._hud_panel:child("casing_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("casing_panel"):child("icon_casingbox"):set_visible(false)
        self._hud_panel:child("point_of_no_return_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("point_of_no_return_panel"):child("icon_noreturnbox"):set_visible(false)
        self._hud_panel:child("buffs_panel"):set_x(self._hud_panel:child("assault_panel"):right() - 20)
        self._vip_bg_box:set_x(0) -- left align this "buff"
        self._last_assault_timer_size = 0
        self._assault_timer = HUDHeistTimer:new({
            panel = self._bg_box:panel({
                name = "assault_timer_panel",
                x = 4
            })
        }, tweak_hud)
        if self._assault_timer and self._assault_timer._timer_text then
            self._assault_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
            self._assault_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
            self._assault_timer._timer_text:set_align("left")
            self._assault_timer._timer_text:set_vertical("center")
            self._assault_timer._timer_text:set_color(Color.white:with_alpha(0.9))
        else
            -- Other mod probably overrode "HUDHeistTimer" class, set this to "nil" to disable this timer
            self._assault_timer = nil
        end
        self._last_casing_timer_size = 0
        self._casing_timer = HUDHeistTimer:new({
            panel = self._casing_bg_box:panel({
                name = "casing_timer_panel",
                x = 4
            })
        }, tweak_hud)
        if self._casing_timer and self._casing_timer._timer_text then
            self._casing_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
            self._casing_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
            self._casing_timer._timer_text:set_align("left")
            self._casing_timer._timer_text:set_vertical("center")
            self._casing_timer._timer_text:set_color(Color.white:with_alpha(0.9))
        else
            -- Other mod probably overrode "HUDHeistTimer" class, set this to "nil" to disable this timer
            self._casing_timer = nil
        end
        if managers.skirmish and managers.skirmish:is_skirmish() and self.hudlist_enemy == 1 and self.center_assault_banner then
            if self._hud_panel:child("wave_panel") then
                self._hud_panel:remove(self._hud_panel:child("wave_panel"))
            end
            local wave_w = 38
            local wave_h = 38
            local wave_panel = self._hud_panel:panel({
                name = "wave_panel",
                w = 145,
                h = 38
            })

            wave_panel:set_top(0)
            wave_panel:set_right(self._hud_panel:child("hostages_panel"):left() + 75)

            local waves_icon = wave_panel:bitmap({
                texture = "guis/textures/pd2/specialization/icons_atlas",
                name = "waves_icon",
                layer = 1,
                valign = "top",
                y = 0,
                x = 0,
                texture_rect = {
                    192,
                    64,
                    64,
                    64
                },
                w = wave_w,
                h = wave_h
            })
            self._wave_bg_box = HUDBGBox_create(wave_panel, {
                w = 100,
                x = 0,
                y = 0,
                h = wave_h
            }, {blend_mode = "add"})

            waves_icon:set_right(wave_panel:w())
            waves_icon:set_center_y(self._wave_bg_box:h() * 0.5)
            self._wave_bg_box:set_right(waves_icon:left())

            local num_waves = self._wave_bg_box:text({
                vertical = "center",
                name = "num_waves",
                layer = 1,
                align = "center",
                y = 0,
                halign = "right",
                x = 0,
                valign = "center",
                text = self:get_completed_waves_string(),
                w = self._wave_bg_box:w(),
                h = self._wave_bg_box:h(),
                color = Color.white,
                font = tweak_data.hud_corner.assault_font,
                font_size = tweak_data.hud_corner.numhostages_size
            })
        end
    end
end

function HUDAssaultCorner:feed_heist_time(t)
    if self._assault_timer then
        self._assault_timer:set_time(t)
        local _, _, w, _ = self._assault_timer._timer_text:text_rect()
        if self._bg_box:child("text_panel") and self._bg_box:w() >= 242 and w ~= self._last_assault_timer_size then
            self._last_assault_timer_size = w
            self._bg_box:child("text_panel"):set_w(self._bg_box:w() - (w + 8))
            self._bg_box:child("text_panel"):set_x(w + 8)
        end
    end
    if self._casing_timer then
        self._casing_timer:set_time(t)
        local _, _, w, _ = self._casing_timer._timer_text:text_rect()
        if self._casing_bg_box:child("text_panel") and self._casing_bg_box:w() >= 242 and w ~= self._last_casing_timer_size then
            self._last_casing_timer_size = w
            self._casing_bg_box:child("text_panel"):set_w(self._casing_bg_box:w() - (w + 8))
            self._casing_bg_box:child("text_panel"):set_x(w + 8)
        end
    end
end

function HUDAssaultCorner:SpamChat(phase)
    if Network:is_server() and SydneyHUD:GetOption("assault_phase_chat_info") then
        SydneyHUD:SendChatMessage("Assault", phase .. " Wave: " .. self._wave_number, SydneyHUD:GetOption("assault_phase_chat_info_feed"))
    end
end

function HUDAssaultCorner:HUDTimer(visibility)
    if self.center_assault_banner then
        managers.hud._hud_heist_timer._heist_timer_panel:set_visible(visibility)
    end
end

if SydneyHUD:GetModOption("hudlist", "enabled") then
    function HUDAssaultCorner:_show_hostages()
    end
end

if BAI then -- Halt execution here, because the first four functions have nothing to do with BAI
    log(SydneyHUD.info .. "Execution of HUDAssaultCorner.lua halted because BAI is installed. Using BAI's version of HUDAssaultCorner file.")
    return
end

function HUDAssaultCorner:StartEndlessAssaultClient()
    if self._assault_vip or self._point_of_no_return then
        return
    end
    self:SetEndlessClient(true)
    self:_start_endless_assault(self:_get_assault_endless_strings())
end

local old_sync_set_assault_mode = HUDAssaultCorner.sync_set_assault_mode
function HUDAssaultCorner:sync_set_assault_mode(mode)
    old_sync_set_assault_mode(self, mode)
    self._assault_vip = mode == "phalanx"
    if SydneyHUD:GetOption("show_assault_states") and mode ~= "phalanx" and self.is_host then
        self:UpdateAssaultState("fade") -- When Captain is defeated, automatically set Assault state to Fade state
    end
    self:SetTimeLeft(5)
end

function HUDAssaultCorner:SetTimer()
    if self.is_host then
        return
    end
    if self.is_skirmish then
        self.client_time_left = TimerManager:game():time() + 140 -- Calculated from skirmishtweakdata.lua (2 minutes and 20 seconds = 140 seconds); Build: 15s, Sustain: 120s, Fade: 5s
    else
        -- Build: 35s; Sustain: Depends on number of players and wave diff; Fade: 5s
        local sustain = self:CalculateSustainDurationFromDiff()
        self.client_time_left = TimerManager:game():time() + 35 + sustain + 5
        if self.assault_extender_modifier then
            self.client_time_left = self.client_time_left + (sustain / 2)
        end
    end
    SydneyHUD:DelayCall("SydneyHUD_RequestCurrentAssaultTimeLeft", 40, function()
        LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
    end)
end

function HUDAssaultCorner:SetTimeLeft(time)
    if self.is_host then
        return
    end
    self.client_time_left = TimerManager:game():time() + time
end

function HUDAssaultCorner:GetAssaultTime(sender)
    if self.is_host and self._assault and not self._assault_endless and not self._assault_vip and sender then
        local tweak = tweak_data.group_ai.besiege.assault
        if self.is_skirmish then
            tweak = tweak_data.group_ai.skirmish.assault
        end
        local gai_state = managers.groupai:state()
        local assault_data = gai_state and gai_state._task_data.assault
        local get_value = gai_state._get_difficulty_dependent_value or function() return 0 end
        local get_mult = gai_state._get_balancing_multiplier or function() return 0 end

        if not (tweak and gai_state and assault_data and assault_data.active) then
            return
        end
        
        local time_left = assault_data.phase_end_t - gai_state._t
        local add
        if self.is_crimespree or self.assault_extender_modifier then
            local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), 0.5) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
            add = managers.modifiers:modify_value("GroupAIStateBesiege:SustainEndTime", sustain_duration) - sustain_duration
            if add == 0 and self._wave_number == 1 and self.assault_state == "build" then
                add = sustain_duration / 2 
            end
        end
        if assault_data.phase == "build" then
            local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), 0.5) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
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
        LuaNetworking:SendToPeer(sender, "BAI_AdvancedAssaultInfo_TimeLeft", time_left)
    end
end

function HUDAssaultCorner:GetTimeLeft()
	return self.client_time_left - TimerManager:game():time()
end

function HUDAssaultCorner:start_assault_callback()
    if self:GetEndlessAssault() then
        self:_start_endless_assault(self:_get_assault_endless_strings())
    else
        self:SetTimer()
        if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
            if SydneyHUD:GetOption("show_assault_states") then
                if self.is_host or (self.is_client and self.CompatibleHost) then
                    self:_start_assault(self:_get_assault_state_strings_info("build"))
                    self:_update_assault_hud_color(self:GetStateColor("build"))
                else
                    self:_start_assault(self:_get_assault_strings_info())
                    LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
                end
            else
                self:_start_assault(self:_get_assault_strings_info())
                if self.is_client then
                    LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
                end
            end
        else
            if SydneyHUD:GetOption("show_assault_states") then
                if self.is_host or (self.is_client and self.CompatibleHost) then
                    self:_start_assault(self:_get_assault_state_strings("build"))
                    self:_update_assault_hud_color(self:GetStateColor("build"))
                else
                    self:_start_assault(self:_get_assault_strings())
                end
            else
                self:_start_assault(self:_get_assault_strings())
            end
        end
    end
end

function HUDAssaultCorner:GetEndlessAssault()
    if not self._no_endless_assault_override then
        if Network:is_server() and managers.groupai:state():get_hunt_mode() then
            return true
        end
        return self.endless_client
    end
    return false
end

function HUDAssaultCorner:_start_endless_assault(text_list)
    self._assault_endless = true
    self:_start_assault(text_list)
    self:SetImage("padlock")
    self:_update_assault_hud_color(self._assault_endless_color)
    self:SpamChat("Endless")
end

local _f_start_assault = HUDAssaultCorner._start_assault
function HUDAssaultCorner:_start_assault(text_list)
    _f_start_assault(self, text_list)
    if self.center_assault_banner then
        self:HUDTimer(false)
    end
    if SydneyHUD:GetOption("show_assault_states") then
        if self.is_skirmish and self.show_popup then
            self.show_popup = false
            self:_popup_wave_started()
        end
    end
end

function HUDAssaultCorner:_get_assault_endless_strings()
    local text = "hud_assault_endless" .. self:GetFactionAssaultText()
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            text,
            "hud_assault_padlock",
            ids_risk,
            "hud_assault_padlock",
            text,
            "hud_assault_padlock",
            ids_risk,
            "hud_assault_padlock"
        }
    else
        return {
            text,
            "hud_assault_padlock",
            text,
            "hud_assault_padlock",
            text,
            "hud_assault_padlock"
        }
    end
end

function HUDAssaultCorner:_get_assault_strings_info()
    if self.is_host and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_spawns") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_strings()
    elseif self.is_client and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_strings()
    end
    local text = "hud_assault_assault" .. self:GetFactionAssaultText()
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line"
        }
    end
end

function HUDAssaultCorner:SetImage(image)
    if image and SydneyHUD:IsOr(image, "assault", "padlock") then
        self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_image("guis/textures/pd2/hud_icon_" .. image .. "box")
    end
end

function HUDAssaultCorner:SetEndlessClient(setter, dont_override)
    self.endless_client = setter
end

function HUDAssaultCorner:SetNormalAssaultOverride()
    if self._assault_vip or not self._assault_endless then
        return
    end
    self:SetImage("assault")
    self._assault_endless = false
    if SydneyHUD:GetOption("show_assault_states") then
        if self.is_host then
            self:UpdateAssaultStateOverride(managers.groupai:state():GetAssaultState())
        else
            if not self.BAIHost then
                self:_animate_update_assault_hud_color(self._assault_color)
                self:_set_text_list(self:_get_assault_strings())
            end
        end
    else
        self:_animate_update_assault_hud_color(self._assault_color)
        if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
            self:_set_text_list(self:_get_assault_strings_info())
            if self.is_client then
                LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
            end
        else
            self:_set_text_list(self:_get_assault_strings())
        end
    end
end

function HUDAssaultCorner:UpdateAssaultState(state)
    if not self._assault_vip and not self._assault_endless and not self._point_of_no_return then
        if SydneyHUD:GetOption("show_assault_states") then
            if state and self.assault_state ~= state then
                self.assault_state = state
                SydneyHUD:SyncAssaultState(state)
                if state == "build" then
                    self:SpamChat("Build")
                    self:_update_assault_hud_color(self:GetStateColor(state))
                    if self.is_client then
                        LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
                    end
                    return
                end
                if state == "anticipation" and self.is_client and not self.CompatibleHost then
                    return
                end
                if SydneyHUD:IsOr(state, "control", "anticipation") then
                    if not self._assault then
                        self.show_popup = false
                        self:_start_assault(self:_get_state_strings(state))
                        self:_set_hostages_offseted(true)
                        self.show_popup = true
                    else
                        if state == "anticipation" then
                            self:_set_text_list(self:_get_state_strings(state))
                        end
                    end
                else
                    if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
                        self:_set_text_list(self:_get_assault_state_strings_info(state))
                        if self.is_client then
                            LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
                        end
                    else
                        self:_set_text_list(self:_get_assault_state_strings(state))
                    end
                    self:SpamChat(self.spam[state])
                end
                if state == "control" then
                    self:_update_assault_hud_color(self:GetStateColor(state))
                else
                    self:_animate_update_assault_hud_color(self:GetStateColor(state))
                end
            end
        else
            if state and self.assault_state ~= state then
                self.assault_state = state
                SydneyHUD:SyncAssaultState(state)
            end
        end
    end
end

function HUDAssaultCorner:UpdateAssaultStateOverride(state)
    if not self._assault_vip and not self._assault_endless and not self._point_of_no_return then
        if SydneyHUD:GetOption("show_assault_states") then
            if state then
                if SydneyHUD:IsOr(state, "control", "anticipation") then
                    self.assault_state = state
                    self._assault = true
                    self:_set_text_list(self:_get_state_strings(state))
                    self:_animate_update_assault_hud_color(self:GetStateColor(state))    
                else
                    self.assault_state = state
                    if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
                        self:_set_text_list(self:_get_assault_state_strings_info(state))
                        if self.is_client then
                            LuaNetworking:SendToPeer(1, "BAI_Message", "RequestCurrentAssaultTimeLeft")
                        end
                    else
                        self:_set_text_list(self:_get_assault_state_strings(state))
                    end
                    self:_animate_update_assault_hud_color(self:GetStateColor(state))
                    self:SpamChat(self.spam[state])
                end
                SydneyHUD:SyncAssaultState(state, true)
            end
        end
    end
end

function HUDAssaultCorner:_set_hostages_offseted(is_offseted)
    if self.center_assault_banner and (self.hudlist_enemy ~= 1 or not self.hudlist_enabled) then -- 1 = All enemies
        return
    end

	local hostage_panel = self._hud_panel:child("hostages_panel")
	self._remove_hostage_offset = nil

	hostage_panel:stop()
	hostage_panel:animate(callback(self, self, "_offset_hostages", is_offseted))

	local wave_panel = self._hud_panel:child("wave_panel")

	if wave_panel then
		wave_panel:stop()
		wave_panel:animate(callback(self, self, "_offset_hostages", is_offseted))
	end
end

function HUDAssaultCorner:_offset_hostages(is_offseted, hostage_panel) -- Just offseting panels, nothing more!
	local TOTAL_T = 0.18
	local OFFSET = self._bg_box:h() + ((self.is_skirmish and self.center_assault_banner) and 16 or 8)
	local from_y = is_offseted and 0 or OFFSET
	local target_y = is_offseted and OFFSET or 0
	local t = (1 - math.abs(hostage_panel:y() - target_y) / OFFSET) * TOTAL_T
	while t < TOTAL_T do
		local dt = coroutine.yield()
		t = math.min(t + dt, TOTAL_T)
		local lerp = t / TOTAL_T
		hostage_panel:set_y(math.lerp(from_y, target_y, lerp))
	end
end

function HUDAssaultCorner:GetStateColor(color)
    return self["_state_" .. color .. "_color"]
end

function HUDAssaultCorner:_get_state_strings(state)
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            "hud_" .. state,
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            "hud_" .. state,
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            "hud_" .. state,
            "hud_assault_end_line",
            "hud_" .. state,
            "hud_assault_end_line",
            "hud_" .. state,
            "hud_assault_end_line",
            "hud_" .. state,
            "hud_assault_end_line"
        }
    end
end
    
function HUDAssaultCorner:_get_assault_state_strings()
    local text = "hud_assault_assault" .. self:GetFactionAssaultText()
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line"
        }
    end
end
    
function HUDAssaultCorner:_get_assault_state_strings_info()
    if self.is_host and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_spawns") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_state_strings()
    elseif self.is_client and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_state_strings()
    end
    local text = "hud_assault_assault" .. self:GetFactionAssaultText()
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            text,
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line"
        }
    end
end

local _f_end_assault = HUDAssaultCorner._end_assault
function HUDAssaultCorner:_end_assault()
	if not self._assault then
		self._start_assault_after_hostage_offset = nil
		return
	end
    if SydneyHUD:GetOption("show_assault_states") then
        if self.is_host or (self.is_client and self.CompatibleHost) then
            self.show_popup = false
            self:_start_assault(self:_get_state_strings("control"))
            self:_update_assault_hud_color(self:GetStateColor("control"))
            self.show_popup = true
        else
            _f_end_assault(self)
            self:HUDTimer(true)
        end
    else
        _f_end_assault(self)
        self:HUDTimer(true)
    end
    self.endless_client = false
    self._assault_endless = false
    self.send_time_left = true
    self:SetImage("assault")
end

function HUDAssaultCorner:SetCompatibleHost(BAIHost)
    self.CompatibleHost = true
    if BAIHost then
        self.BAIHost = true
    end
end

function HUDAssaultCorner:show_point_of_no_return_timer(id)
    self._point_of_no_return = true
    local delay_time = self._assault and 1.2 or 0
    self:_close_assault_box()
    self:_update_noreturn(id)
    local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
    self:_hide_hostages()
    point_of_no_return_panel:stop()
    point_of_no_return_panel:animate(callback(self, self, "_animate_show_noreturn"), delay_time)
    self:_set_feedback_color(self._noreturn_color)
    self:HUDTimer(false)
end

if SydneyHUD:GetOption("center_assault_banner") then
    local _f_show_casing = HUDAssaultCorner.show_casing
    function HUDAssaultCorner:show_casing(mode)
        self._casing = true
        _f_show_casing(self, mode)
    end

    function HUDAssaultCorner:_set_hostage_offseted(is_offseted)
        if self._casing or not is_offseted then
            return
        end
        self:start_assault_callback()
    end
end

function HUDAssaultCorner:GetFactionAssaultText()
    if SydneyHUD.EasterEgg.FSS.AIReactionTimeTooHigh and math.random(0, 100) % 10 == 0 then
        return "_fss_mod_" .. math.random(1, 3)
    end
    return ""
end

function HUDAssaultCorner:_animate_update_assault_hud_color(color)
    self._bg_box:animate(callback(SydneyAnimation, SydneyAnimation, "ColorChange"), color, callback(self, self, "_update_assault_hud_color"), self._current_assault_color)
end

Hooks:Add("NetworkReceivedData", "NetworkReceivedData_BAI", function(sender, id, data)
    if not managers.hud then
        return
    end
    if id == "BAI_Message" then
        if data == "BAI?" then -- Host
            LuaNetworking:SendToPeer(sender, id, "BAI!")
        end
        if data == "BAI!" then -- Client
            managers.hud._hud_assault_corner:SetCompatibleHost(true)
            LuaNetworking:SendToPeer(1, "BAI_EasterEgg", "AIReactionTimeTooHigh?")
            --LuaNetworking:SendToPeer(1, id, BAI.data.ResendAS)
        end
        if data == "NormalAssaultOverride" then -- Client
            managers.hud._hud_assault_corner:SetNormalAssaultOverride()
        end
        if data == "RequestCurrentAssaultState" then -- Host
            LuaNetworking:SendToPeer(sender, "BAI_AssaultStateOverride", managers.groupai:state():GetAssaultState())
        end
        if data == "RequestCurrentAssaultTimeLeft" then -- Host
            managers.hud._hud_assault_corner:GetAssaultTime(sender)
        end
    end
    if id == "BAI_AssaultState" then -- Client
        if SydneyHUD:GetOption("show_assault_states") then
            managers.hud._hud_assault_corner:UpdateAssaultState(data)
        end
    end
    if id == "BAI_AssaultStateOverride" then -- Client
        if SydneyHUD:GetOption("show_assault_states") then
            managers.hud._hud_assault_corner:UpdateAssaultStateOverride(data)
        end
    end
    if id == "BAI_AdvancedAssaultInfo_TimeLeft" then -- Client
        managers.hud._hud_assault_corner:SetTimeLeft(data)
    end
    if id == "BAI_EasterEgg" then
        if data == "AIReactionTimeTooHigh?" then -- Host
            if SydneyHUD.EasterEgg.FSS.AIReactionTimeTooHigh then
                LuaNetworking:SendToPeer(sender, id, "AIReactionTimeTooHigh")
            end
        end
        if data == "AIReactionTimeTooHigh" then -- Client
            SydneyHUD.EasterEgg.FSS.AIReactionTimeTooHigh = true
        end
    end
    if id == "BAI_EasterEgg_Reset" then
        SydneyHUD.EasterEgg.FSS.AIReactionTimeTooHigh = false
        LuaNetworking:SendToPeer(1, "BAI_EasterEgg", "AIReactionTimeTooHigh?")
    end

    -- KineticHUD
    if id == "DownCounterStandalone" then
        managers.hud._hud_assault_corner:SetCompatibleHost()
    end
    if id == "SyncAssaultPhase" then
        if SydneyHUD:GetOption("show_assault_states") then
            data = utf8.to_lower(data)
            if data == "control" and managers.hud._hud_assault_corner._assault then
                return
            end
            if SydneyHUD:IsOr(data, "anticipation", "build", "regroup") then
                return
            end
            managers.hud._hud_assault_corner:UpdateAssaultState(data)
        end
    end
    -- KineticHUD
end)

Hooks:Add("BaseNetworkSessionOnLoadComplete", "BaseNetworkSessionOnLoadComplete_BAI", function(local_peer, id)
    if Network:is_client() then
        LuaNetworking:SendToPeer(1, "BAI_Message", "BAI?")
    end
end)