local init_original = HUDAssaultCorner.init
function HUDAssaultCorner:init(hud, full_hud, tweak_hud)
    init_original(self, hud, full_hud, tweak_hud)
    if not BAI then -- Initialize these variables when BAI is not installed or not running
        self._assault_endless_color = Color.red
        self._state_control_color = Color.white
        self._state_anticipation_color = Color(255, 186, 204, 28) / 255
        self._state_build_color = self._assault_color
        self._state_sustain_color = Color(255, 237, 127, 127) / 255
        self._state_fade_color = self._state_anticipation_color
        self.heists_with_fake_endless_assaults = { "framing_frame_1", "gallery", "watchdogs_2", "bph" } -- Framing Frame Day 1, Art Gallery, Watch Dogs Day 2, Hell's Island
        self._no_endless_assault_override = table.contains(self.heists_with_fake_endless_assaults, Global.game_settings.level_id)
        self.endless_client = false
        self.is_host = Network:is_server()
        self.is_client = not self.is_host
        self.is_skirmish = managers.skirmish and managers.skirmish:is_skirmish() or false 
        self.is_crimespree = managers.crime_spree and managers.crime_spree:is_active() or false
        self.multiplayer_game = false
        if self.is_client then -- Safe House Nightmare, The Biker Heist Day 2, Cursed Kill Room, Escape: Garage, Escape: Cafe, Escape: Cafe (Day)
            self.heists_with_endless_assaults = { "haunted", "chew", "hvh", "escape_garage", "escape_cafe", "escape_cafe_day" }
            self.endless_client = table.contains(self.heists_with_endless_assaults, Global.game_settings.level_id)
            self.number_of_peers = LuaNetworking:GetNumberOfPeers()
            self.sustain_duration_min_max = {
                40,
                120,
                160
            }
            self.sustain_duration_balance_mul = {
                1,
                1.1,
                1.2,
                1.3
            }
        end
        self.assault_state = "nil"
        self.show_popup = true
        dofile(SydneyHUD._lua_path .. "LocalizationManager.lua")
        if self.is_client then
            managers.localization:SetClient()
        end
    end
    if self._hud_panel:child("hostages_panel") then
        self:_hide_hostages()
    end
    if SydneyHUD:GetOption("center_assault_banner") then
        self._hud_panel:child("assault_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_visible(false)
        self._hud_panel:child("casing_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("casing_panel"):child("icon_casingbox"):set_visible(false)
        self._hud_panel:child("point_of_no_return_panel"):set_right(self._hud_panel:w() / 2 + 150)
        self._hud_panel:child("point_of_no_return_panel"):child("icon_noreturnbox"):set_visible(false)
        self._hud_panel:child("buffs_panel"):set_x(self._hud_panel:child("assault_panel"):right())
        self._vip_bg_box:set_x(0) -- left align this "buff"
        self._last_assault_timer_size = 0
        self._assault_timer = HUDHeistTimer:new({
            panel = self._bg_box:panel({
                name = "assault_timer_panel",
                x = 4
            })
        }, tweak_hud)
        self._assault_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
        self._assault_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
        self._assault_timer._timer_text:set_align("left")
        self._assault_timer._timer_text:set_vertical("center")
        self._assault_timer._timer_text:set_color(Color.white:with_alpha(0.9))
        self._last_casing_timer_size = 0
        self._casing_timer = HUDHeistTimer:new({
            panel = self._casing_bg_box:panel({
                name = "casing_timer_panel",
                x = 4
            })
        }, tweak_hud)
        self._casing_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
        self._casing_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
        self._casing_timer._timer_text:set_align("left")
        self._casing_timer._timer_text:set_vertical("center")
        self._casing_timer._timer_text:set_color(Color.white:with_alpha(0.9))
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
    if Network:is_server() then
        if SydneyHUD:GetOption("assault_phase_chat_info") then
            SydneyHUD:SendChatMessage("Assault", phase .. " Wave: " .. self._wave_number, SydneyHUD:GetOption("assault_phase_chat_info_feed"))
        end
    end
end

function HUDAssaultCorner:HUDTimer(visibility)
    if SydneyHUD:GetOption("center_assault_banner") then
        managers.hud._hud_heist_timer._heist_timer_panel:set_visible(visibility)
    end
end

if BAI then -- Halt execution here, because the first four functions have nothing to do with BAI
    log(SydneyHUD.info .. "Execution of HUDAssaultCorner.lua halted because BAI is installed. Using BAI's version of HUDAssaultCorner file.")
    return
end

function HUDAssaultCorner:_show_hostages(...)
    return
end

function HUDAssaultCorner:SetTimer()
    if self.is_skirmish then
        self.client_time_left = TimerManager:game():time() + 140 -- Calculated from skirmishtweakdata.lua (2 minutes and 20 seconds); Build: 15s, Sustain: 120s, Fade: 5s
    else
        if self.is_crimespree then
            --local sustain_duration = (self.sustain_duration_min_max[math.clamp(self._wave_number, 1, 3)] * self.sustain_duration_balance_mul[math.clamp(self.number_of_peers, 1, 4)])
            --local difference = managers.modifiers:modify_value("GroupAIStateBesiege:SustainEndTime", sustain_duration) - sustain_duration
            self.client_time_left = TimerManager:game():time() + 240 -- 4 minutes
            if managers.crime_spree:server_spree_level() > 500 then
                self.client_time_left = self.client_time_left + 120
            end
        else
            -- Build: 35s; Sustain: Depends on number of players and wave intensity (or number); Fade: 5s
            self.client_time_left = TimerManager:game():time() + 35 + (self.sustain_duration_min_max[math.clamp(self._wave_number, 1, 3)] * self.sustain_duration_balance_mul[math.clamp(self.number_of_peers, 1, 4)]) + 5
        end
    end
end

function HUDAssaultCorner:SetTimeLeft(time)
    self.client_time_left = TimerManager:game():time() + time
end

function HUDAssaultCorner:GetTimeLeft()
	return self.client_time_left - TimerManager:game():time()
end

function HUDAssaultCorner:start_assault_callback()
    if self:GetEndlessAssault() then
        self:_start_endless_assault(self:_get_assault_endless_strings())
    else
        if self.is_client and SydneyHUD:GetOption("enable_enhanced_assault_banner") then
            self:SetTimer()
        end
        if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
            if SydneyHUD:GetOption("show_assault_states") then
                if self.is_host or (self.is_client and self.multiplayer_game) then
                    self:_start_assault(self:_get_assault_state_strings_info("build"))
                    self:_update_assault_hud_color(self:GetStateColor("build"))
                else
                    self:_start_assault(self:_get_assault_strings_info())
                end
            else
                self:_start_assault(self:_get_assault_strings_info())
            end    
        else
            if SydneyHUD:GetOption("show_assault_states") then
                if self.is_host or (self.is_client and self.multiplayer_game) then
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
        if Network:is_server() then
            if managers.groupai:state():get_hunt_mode() then
                LuaNetworking:SendToPeers("BAI_Message", "endless_triggered")
                return true
            end -- Returns false
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
    if SydneyHUD:GetOption("center_assault_banner") then
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
    local end_line = "hud_assault_" .. (SydneyHUD:GetOption("center_assault_banner") and "padlock" or "end_line")
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            "hud_assault_endless",
            end_line,
            ids_risk,
            end_line,
            "hud_assault_endless",
            end_line,
            ids_risk,
            end_line
        }
    else
        return {
            "hud_assault_endless",
            end_line,
            "hud_assault_endless",
            end_line,
            "hud_assault_endless",
            end_line
        }
    end
end

function HUDAssaultCorner:_get_assault_strings_info()
    if self.is_host and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_spawns") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_state_strings()
    elseif self.is_client and not SydneyHUD:GetOption("enhanced_assault_time") and not SydneyHUD:GetOption("enhanced_assault_count") then
        return self:_get_assault_state_strings()
    end
    if self.is_host and self.multiplayer_game and not self.is_skirmish then
        managers.localization:SetSynchronization(true)
    end
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line"
        }
    end
end

function HUDAssaultCorner:SetImage(image)
    if image then
        if SydneyHUD:IsOr(image, "assault", "padlock") then
            self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_image("guis/textures/pd2/hud_icon_" .. image .. "box")
        end
    end
end

function HUDAssaultCorner:SetEndlessClient(setter, dont_override)
    self.endless_client = setter
end

if Global.game_settings.level_id == "pbr" then
    function HUDAssaultCorner:SetNormalAssaultOverride() -- Beneath the Mountain only
        --[[if self.is_host and self.multiplayer_game then
            LuaNetworking:SendToPeers("BAI_Message", "NormalAssaultOverride")
        end]]
        self:SetImage("assault")
        self._assault_endless = false
        if SydneyHUD:GetOption("show_assault_states") then
            if self.is_host then
                self:UpdateAssaultStateOverride(managers.groupai:state():GetAssaultState())
            else
                if not self.multiplayer_game then
                    self:_update_assault_hud_color(self._assault_color)
                    self:_set_text_list(self:_get_assault_strings())
                end
            end
        else
            self:_update_assault_hud_color(self._assault_color)
            if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
                self:_set_text_list(self:_get_assault_strings_info())
            else
                self:_set_text_list(self:_get_assault_strings())
            end
        end
    end

    local _f_queue_dialog = DialogManager.queue_dialog -- Fix for Beneath the Mountain
    function DialogManager:queue_dialog(id, ...)
        if id == "Play_loc_jr1_23" then
            managers.hud._hud_assault_corner:SetNormalAssaultOverride()
        end
        return _f_queue_dialog(self, id, ...)
    end
end

function HUDAssaultCorner:UpdateAssaultState(state)
    if not self._assault_vip and not self._assault_endless and not self._point_of_no_return then
        if SydneyHUD:GetOption("show_assault_states") then
            if state and self.assault_state ~= state then
                self.assault_state = state
                if state == "build" then
                    self:SpamChat("Build")
                    self:_update_assault_hud_color(self:GetStateColor(state))
                    return
                end
                if state == "anticipation" and self.is_client and not self.multiplayer_game then
                    return
                end
                if not SydneyHUD:IsOr(state, "control", "anticipation") then
                    LuaNetworking:SendToPeers("BAI_AssaultState", state)
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
                    else
                        self:_set_text_list(self:_get_assault_state_strings(state))
                    end
                    if state == "sustain" then
                        self:SpamChat("Sustain")
                    else
                        self:SpamChat("Fade")
                    end
                end
                self:_update_assault_hud_color(self:GetStateColor(state))
            end
        else
            if state and self.assault_state ~= state then
                self.assault_state = state
                if self.is_host and not SydneyHUD:IsOr(state, "control", "anticipation", "build") then
                    LuaNetworking:SendToPeers("BAI_AssaultState", state)
                end
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
                    self:_update_assault_hud_color(self:GetStateColor(state))    
                else
                    self.assault_state = state
                    if SydneyHUD:GetOption("enable_enhanced_assault_banner") then
                        self:_set_text_list(self:_get_assault_state_strings_info(state))
                    else
                        self:_set_text_list(self:_get_assault_state_strings(state))
                    end
                    self:_update_assault_hud_color(self:GetStateColor(state))
                    if state == "build" then
                        self:SpamChat("Build")
                    elseif state == "sustain" then
                        self:SpamChat("Sustain")
                    else
                        self:SpamChat("Fade")
                    end
                    if self.is_host then
                        LuaNetworking:SendToPeers("BAI_AssaultStateOverride", state)
                    end
                end
            end
        end
    end
end

function HUDAssaultCorner:_set_hostages_offseted(is_offseted)
    if SydneyHUD:GetOption("center_assault_banner") then
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
	local OFFSET = self._bg_box:h() + 8
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
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line"
        }
    else
        return {
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_assault",
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
    if self.is_host and self.multiplayer_game and not self.is_skirmish then
        managers.localization:SetSynchronization(true)
    end
    if managers.job:current_difficulty_stars() > 0 then
        local ids_risk = Idstring("risk")
        return {
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            ids_risk,
            "hud_assault_end_line",
            "hud_assault_assault",
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
            "hud_assault_assault",
            "hud_assault_end_line",
            "hud_assault_phase",
            "hud_assault_end_line",
            "hud_assault_info",
            "hud_assault_end_line",
            "hud_assault_assault",
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
        if self.is_host or (self.is_client and self.multiplayer_game) then
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
    self:SetImage("assault")
end

function HUDAssaultCorner:SetMultiplayerGame(setter)
    self.multiplayer_game = setter
end

function HUDAssaultCorner:show_point_of_no_return_timer()
    local delay_time = self._assault and 1.2 or 0
    self:_close_assault_box()
    local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
    self:_hide_hostages()
    point_of_no_return_panel:stop()
    point_of_no_return_panel:animate(callback(self, self, "_animate_show_noreturn"), delay_time)
    self:_set_feedback_color(self._noreturn_color)
    self._point_of_no_return = true
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

Hooks:Add("NetworkReceivedData", "NetworkReceivedData_BAI", function(sender, id, data)
    if id == "BAI_Message" then
        if data == "endless_triggered" then -- Client
            managers.hud._hud_assault_corner:SetEndlessClient(true)
        end
        if data == "BAI?" then -- Host
            managers.hud._hud_assault_corner:SetMultiplayerGame(true)
            LuaNetworking:SendToPeer(sender, id, "BAI!")
        end
        if data == "BAI!" then -- Client
            managers.hud._hud_assault_corner:SetMultiplayerGame(true)
            LuaNetworking:SendToPeer(1, id, "IsEndlessAssault?")
            LuaNetworking:SendToPeer(1, id, "SendAssaultStates")
        end
        if data == "IsEndlessAssault?" then -- Host
            if managers.hud._hud_assault_corner:get_assault_mode() ~= "phalanx" and managers.groupai:state():get_hunt_mode() then -- Notifies drop-in client about Endless Assault in progress
                LuaNetworking:SendToPeer(sender, id, "endless_triggered")
            end
        end
        if data == "NormalAssaultOverride" then -- Client
            managers.hud._hud_assault_corner:SetNormalAssaultOverride()
        end
        if data == "SendAssaultStates" then -- Host; do nothing
        end
        if data == "RequestCurrentAssaultState" then -- Host
            LuaNetworking:SendToPeer(sender, "BAI_AssaultStateOverride", managers.groupai:state():GetAssaultState())
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
end)

Hooks:Add("BaseNetworkSessionOnLoadComplete", "BaseNetworkSessionOnLoadComplete_BAI", function(local_peer, id)
    if Network:is_client() then
        LuaNetworking:SendToPeer(1, "BAI_Message", "BAI?")
    end
end)

Hooks:Add("BaseNetworkSessionOnPeerRemoved", "BaseNetworkSessionOnPeerRemoved_BAI", function(peer, peer_id, reason)
    if Network:is_client() then
        managers.hud._hud_assault_corner.number_of_peers = managers.hud._hud_assault_corner.number_of_peers - 1
    end
end)

Hooks:Add("NetworkManagerOnPeerAdded", "NetworkManagerOnPeerAdded_BAI", function(peer, peer_id)
    if Network:is_client() then
        managers.hud._hud_assault_corner.number_of_peers = managers.hud._hud_assault_corner.number_of_peers + 1
    end
end)

--
-- Assault States
--
SydneyHUD:Hook(HUDManager, "sync_start_anticipation_music", function(self)
    self._hud_assault_corner:UpdateAssaultState("anticipation")
end)

SydneyHUD:AddDelayedCall("AssaultStatesHookDelay", 1, function()
    if Global.game_settings.level_id == "Enemy_Spawner" then
        return
    end
    
    SydneyHUD:Hook(GroupAIStateBesiege, "_upd_assault_task", function(self)
        if self._task_data.assault.phase ~= "anticipation" then
            managers.hud._hud_assault_corner:UpdateAssaultState(self._task_data.assault.phase)
        end
    end)
    
    if Network:is_server() then
        function GroupAIStateBase:GetAssaultState()
            return self._task_data.assault.phase
        end
    
        SydneyHUD:Hook(GroupAIStateBase, "on_enemy_weapons_hot", function(self)
            managers.hud._hud_assault_corner:UpdateAssaultState("control")
            LuaNetworking:SendToPeers("BAI_AssaultState", "control")
        end)
    end
end)