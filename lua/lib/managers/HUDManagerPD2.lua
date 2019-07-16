if SydneyHUD:GetOption("hudlist_enable") then
    dofile(SydneyHUD._lua_path .. "lib/managers/HUDList.lua")
end

local last_removed_time = 0

local init_original = HUDManager.init
function HUDManager:init(...)
    init_original(self, ...)
    self._deferred_detections = {}
end

function HUDManager:Update()
    for _, panel in pairs(self._teammate_panels) do -- HUDTeammate
        if panel then
            panel:Update()
        end
    end
end

local set_slot_outfit_original = HUDManager.set_slot_outfit
function HUDManager:set_slot_outfit(peer_id, criminal_name, outfit, ...)
    self:set_slot_detection(peer_id, outfit, true)
    return set_slot_outfit_original(self, peer_id, criminal_name, outfit, ...)
end

local add_teammate_panel_original = HUDManager.add_teammate_panel
function HUDManager:add_teammate_panel(character_name, player_name, ai, peer_id, ...)
    local result = add_teammate_panel_original(self, character_name, player_name, ai, peer_id, ...)
    for pid, risk in pairs(self._deferred_detections) do
        for panel_id, _ in ipairs(self._hud.teammate_panels_data) do
            if self._teammate_panels[panel_id]:peer_id() == pid then
                self._teammate_panels[panel_id]:set_detection_risk(risk)
                self._deferred_detections[pid] = nil
            end
        end
    end
    return result
end

function HUDManager:set_slot_detection(peer_id, outfit, unpacked)
    if not unpacked or not outfit then
        outfit = managers.blackmarket:unpack_outfit_from_string(outfit)
    end
    local risk = managers.blackmarket:get_suspicion_offset_of_outfit_string(outfit, tweak_data.player.SUSPICION_OFFSET_LERP or 0.75)
    for panel_id, _ in ipairs(self._hud.teammate_panels_data) do
        if self._teammate_panels[panel_id].set_detection_risk and peer_id == managers.network:session():local_peer():id() and self._teammate_panels[panel_id]._main_player or self._teammate_panels[panel_id]:peer_id() == peer_id then
            self._teammate_panels[panel_id]:set_detection_risk(risk)
            return
        end
    end
    self._deferred_detections[peer_id] = risk
end

local set_player_condition_original = HUDManager.set_player_condition
function HUDManager:set_player_condition(icon_data, text)
    set_player_condition_original(self, icon_data, text)
    if icon_data == "mugshot_in_custody" then
        self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(true)
    elseif icon_data == "mugshot_normal" then
        self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(false)
    end
end

function HUDManager:change_health(...)
    self._teammate_panels[self.PLAYER_PANEL]:change_health(...)
end

local _create_downed_hud_original = HUDManager._create_downed_hud
function HUDManager:_create_downed_hud(...)
    _create_downed_hud_original(self, ...)
    if SydneyHUD:GetOption("center_assault_banner") then
        local timer_msg = self._hud_player_downed._hud_panel:child("downed_panel"):child("timer_msg")
        timer_msg:set_y(50)
        self._hud_player_downed._hud.timer:set_y(math.round(timer_msg:bottom() - 6))
    end
end

local show_casing_original = HUDManager.show_casing
function HUDManager:show_casing(...)
    self._hud_heist_timer._heist_timer_panel:set_visible(not SydneyHUD:GetOption("center_assault_banner"))
    if self:alive("guis/mask_off_hud") and SydneyHUD:GetOption("center_assault_banner") then
        self:script("guis/mask_off_hud").mask_on_text:set_y(50)
    end
    show_casing_original(self, ...)
end

local hide_casing_original = HUDManager.hide_casing
function HUDManager:hide_casing(...)
    hide_casing_original(self, ...)
    self._hud_heist_timer._heist_timer_panel:set_visible(true)
end

local show_point_of_no_return_timer_original = HUDManager.show_point_of_no_return_timer
function HUDManager:show_point_of_no_return_timer(...)
    self._hud_heist_timer._heist_timer_panel:set_visible(not SydneyHUD:GetOption("center_assault_banner"))
    show_point_of_no_return_timer_original(self, ...)
end

local hide_point_of_no_return_timer_original = HUDManager.hide_point_of_no_return_timer
function HUDManager:hide_point_of_no_return_timer(...)
    hide_point_of_no_return_timer_original(self, ...)
    self._hud_heist_timer._heist_timer_panel:set_visible(true)
end

local _f_create_custody_hud = HUDManager._create_custody_hud
function HUDManager:_create_custody_hud(hud)
    _f_create_custody_hud(self, hud)
    if SydneyHUD:GetOption("center_assault_banner") then
        local timer_msg = self._hud_player_custody._hud_panel:child("custody_panel"):child("timer_msg")
        timer_msg:set_y(50)
        self._hud_player_custody._hud_panel:child("custody_panel"):child("timer"):set_y(math.round(timer_msg:bottom() - 6))
    end
end

local feed_heist_time_original = HUDManager.feed_heist_time
function HUDManager:feed_heist_time(t)
    if SydneyHUD:GetOption("enable_corpse_remover_plus") then
        if t - last_removed_time >= SydneyHUD:GetOption("remove_interval") then
            if SydneyHUD:GetOption("remove_shield") then
                if managers.enemy then
                    local enemy_data = managers.enemy._enemy_data
                    local corpses = enemy_data.corpses
                    for u_key, u_data in pairs(corpses) do
                        if u_data.unit:inventory() ~= nil then
                            u_data.unit:inventory():destroy_all_items()
                        end
                    end
                end
            end
            if SydneyHUD:GetOption("remove_body") then
                if managers.enemy and not managers.groupai:state():whisper_mode() then
                    managers.enemy:dispose_all_corpses()
                end
            end
            last_removed_time = t
        end
    end
    feed_heist_time_original(self, t)
    self._hud_assault_corner:feed_heist_time(t)
    self._teammate_panels[self.PLAYER_PANEL]:change_health(0) -- force refresh hps meter atleast every second.
end

function HUDManager:update_armor_timer(...)
    self._teammate_panels[self.PLAYER_PANEL]:update_armor_timer(...)
end

function HUDManager:update_inspire_timer(...)
    self._teammate_panels[self.PLAYER_PANEL]:update_inspire_timer(...)
end

local teammate_progress_original = HUDManager.teammate_progress
function HUDManager:teammate_progress(peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
    teammate_progress_original(self, peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
    local label = self:_name_label_by_peer_id(peer_id)
    local panel = self:teammate_panel_from_peer_id(peer_id)
    if panel then
        if label then
            self._teammate_panels[panel]:set_interact_text((label.panel:child("action"):text()))
        end
        self._teammate_panels[panel]:set_interact_visibility(enabled)
    end
end

function HUDManager:_mugshot_id_to_panel_id(id)
    for _, data in pairs(managers.criminals:characters()) do
        if data and data.data and data.data.mugshot_id == id then
            return data.data.panel_id
        end
    end
end

function HUDManager:_mugshot_id_to_unit(id)
    for _, data in pairs(managers.criminals:characters()) do
        if data and data.data and data.data.mugshot_id == id then
            return data.unit
        end
    end
end

local set_mugshot_downed_original = HUDManager.set_mugshot_downed
function HUDManager:set_mugshot_downed(id)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    local unit = self:_mugshot_id_to_unit(id)
    if panel_id and unit and unit:movement().current_state_name and unit:movement():current_state_name() == "bleed_out" then
        self._teammate_panels[panel_id]:increment_revives()
    end
    return set_mugshot_downed_original(self, id)
end

local set_mugshot_custody_original = HUDManager.set_mugshot_custody
function HUDManager:set_mugshot_custody(id)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    if panel_id then
        self._teammate_panels[panel_id]:reset_revives()
        self._teammate_panels[panel_id]:set_player_in_custody(true)
    end
    return set_mugshot_custody_original(self, id)
end

local set_mugshot_normal_original = HUDManager.set_mugshot_normal
function HUDManager:set_mugshot_normal(id)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    if panel_id then
        self._teammate_panels[panel_id]:set_player_in_custody(false)
    end
    return set_mugshot_normal_original(self, id)
end

function HUDManager:reset_teammate_revives(panel_id)
    if self._teammate_panels[panel_id] then
        self._teammate_panels[panel_id]:reset_revives()
    end
end

function HUDManager:set_mugshot_voice(id, active)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
        self._teammate_panels[panel_id]:set_voice_com(active)
    end
end

function HUDManager:set_hud_mode(mode)
    for _, panel in pairs(self._teammate_panels or {}) do
        panel:set_hud_mode(mode)
    end
end

function HUDManager:teammate_panel_from_peer_id(id)
    for panel_id, panel in pairs(self._teammate_panels or {}) do
        if panel._peer_id == id then
            return panel_id
        end
    end
end

local set_stamina_value_original = HUDManager.set_stamina_value
function HUDManager:set_stamina_value(value, ...)
    self._teammate_panels[HUDManager.PLAYER_PANEL]:set_current_stamina(value)
    return set_stamina_value_original(self, value, ...)
end

local set_max_stamina_original = HUDManager.set_max_stamina
function HUDManager:set_max_stamina(value, ...)
    self._teammate_panels[HUDManager.PLAYER_PANEL]:set_max_stamina(value)
    return set_max_stamina_original(self, value, ...)
end

function HUDManager:increment_kill_count(teammate_panel_id, is_special, headshot)
    self._teammate_panels[teammate_panel_id]:increment_kill_count(is_special, headshot)
end

function HUDManager:reset_kill_count(teammate_panel_id)
    self._teammate_panels[teammate_panel_id]:reset_kill_count()
end

function HUDManager:press_substitute(text, new)
    return text:gsub(managers.localization:text("hud_hold"), new)
end

local show_interact_original = HUDManager.show_interact
function HUDManager.show_interact(self, data)
    if self._interact_visible and not data.force then
        return
    end

    if SydneyHUD:GetOption("push_to_interact") and SydneyHUD:GetOption("push_to_interact_delay") >= 0 then
        data.text = HUDManager:press_substitute(data.text, managers.localization:text("hud_press"))
    end

    self._interact_visible = true
    return show_interact_original(self, data)
end

local remove_interact_original = HUDManager.remove_interact
function HUDManager.remove_interact(self)
    self._interact_visible = nil
    return remove_interact_original(self)
end

function HUDManager:show_underdog()
    if not SydneyHUD:GetOption("show_underdog_aced") then
        self:hide_underdog()
        return
    end
    self._teammate_panels[ HUDManager.PLAYER_PANEL ]:show_underdog()
end

function HUDManager:hide_underdog()
    self._teammate_panels[ HUDManager.PLAYER_PANEL ]:hide_underdog()
end

if not SydneyHUD:GetOption("hudlist_enable") then
    return
end

local _setup_player_info_hud_pd2_original = HUDManager._setup_player_info_hud_pd2
function HUDManager:_setup_player_info_hud_pd2(...)
    _setup_player_info_hud_pd2_original(self, ...)
    if not managers.hudlist then
        managers.hudlist = HUDListManager:new(managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel)
        managers.hudlist:post_init()
        HUDListManager.add_post_init_event(function()
            if not GameInfoManager then
                return log_error("Script requires GameInfoManager to function, aborting setup")
            else
                managers.gameinfo:add_scheduled_callback("HUDList_setup_clbk", 1, function()
                    managers.hudlist:setup()
                end)
            end
        end)
    end
end

local update_original = HUDManager.update
function HUDManager:update(t, dt, ...)
    managers.hudlist:update(t, dt)
    return update_original(self, t, dt, ...)
end

local custom_radial_original = HUDManager.set_teammate_custom_radial
function HUDManager:set_teammate_custom_radial(i, data)
    if SydneyHUD:GetOption("swansong_effect") then
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
        if not hud.panel:child("swan_song_left") then
            local swan_song_left = hud.panel:bitmap({
                name = "swan_song_left",
                visible = false,
                texture = "guis/textures/alphawipe_test",
                layer = 0,
                color = Color(0, 0.7, 1),
                blend_mode = "add",
                w = hud.panel:w(),
                h = hud.panel:h(),
                x = 0,
                y = 0
            })
        end
        local swan_song_left = hud.panel:child("swan_song_left")
        if i == 4 and data.current < data.total and data.current > 0 and swan_song_left then
            swan_song_left:set_visible(true)
            local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
            swan_song_left:animate(hudinfo.flash_icon, 4000000000)
        elseif hud.panel:child("swan_song_left") then
            swan_song_left:stop()
            swan_song_left:set_visible(false)
        end
        if swan_song_left and data.current == 0 then
            swan_song_left:set_visible(false)
        end
    end
    return custom_radial_original(self, i, data)
end

local _f_activate_objective = HUDManager.activate_objective
function HUDManager:activate_objective(data)
    _f_activate_objective(self, data)
    managers.hudlist:change_setting("left_list_y", data.amount and 62 or 40)
end