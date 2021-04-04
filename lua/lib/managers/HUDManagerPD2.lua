local init_original = HUDManager.init
function HUDManager:init(...)
    init_original(self, ...)
    SydneyHUD:Init()
    self._deferred_detections = {}
end

--[[
    Sets detection risk for all human players
]]
local set_slot_outfit_original = HUDManager.set_slot_outfit
function HUDManager:set_slot_outfit(peer_id, criminal_name, outfit, ...)
    self:set_slot_detection(peer_id, outfit, true)
    set_slot_outfit_original(self, peer_id, criminal_name, outfit, ...)
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

--[[
    mugshot_in_custody = Hides all info panels in your health bar when you went to custody
    mugshot_normal = Shows all info panels in your health bar when you are out of custody
]]
local set_player_condition_original = HUDManager.set_player_condition
function HUDManager:set_player_condition(icon_data, text)
    set_player_condition_original(self, icon_data, text)
    if icon_data == "mugshot_in_custody" then
        self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(true)
    elseif icon_data == "mugshot_normal" then
        self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(false)
    end
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
    feed_heist_time_original(self, t)
    self._hud_assault_corner:feed_heist_time(t)
    self._teammate_panels[self.PLAYER_PANEL]:change_health() -- force refresh hps meter atleast every second.
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
            self._teammate_panels[panel]:set_interact_text(label.panel:child("action"):text())
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
    set_mugshot_downed_original(self, id)
end

local set_mugshot_custody_original = HUDManager.set_mugshot_custody
function HUDManager:set_mugshot_custody(id)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    if panel_id then
        self._teammate_panels[panel_id]:reset_revives()
        self._teammate_panels[panel_id]:set_player_in_custody(true)
    end
    set_mugshot_custody_original(self, id)
end

local set_mugshot_normal_original = HUDManager.set_mugshot_normal
function HUDManager:set_mugshot_normal(id)
    local panel_id = self:_mugshot_id_to_panel_id(id)
    if panel_id then
        self._teammate_panels[panel_id]:set_player_in_custody(false)
    end
    set_mugshot_normal_original(self, id)
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

function HUDManager:press_substitute(text, new)
    return text:gsub(managers.localization:text("hud_hold"), new)
end

local show_interact_original = HUDManager.show_interact
function HUDManager:show_interact(data)
    if self._interact_visible and not data.force then
        return
    end

    if SydneyHUD:GetOption("push_to_interact") and SydneyHUD:GetOption("push_to_interact_delay") >= 0 then
        data.text = self:press_substitute(data.text, managers.localization:text("hud_press"))
    end

    self._interact_visible = true
    return show_interact_original(self, data)
end

function HUDManager:animate_interaction_bar(current, total, hide)
    if not total then
        total = current
        current = 0
    end
    self:show_interaction_bar(current, total)
    self._hud_interaction._animated = true

    local function feed_circle(o)
		local t = 0

		while t < total do
			t = t + coroutine.yield()

			self:set_interaction_bar_width(t, total)
        end

        if hide then
            self:hide_interaction_bar(true)
        end
    end

    if _G.IS_VR then
		return
	end

	self._hud_interaction._interact_circle._panel:stop()
	self._hud_interaction._interact_circle._panel:animate(feed_circle)
end

local remove_interact_original = HUDManager.remove_interact
function HUDManager:remove_interact()
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

local custom_radial_original = HUDManager.set_teammate_custom_radial
function HUDManager:set_teammate_custom_radial(i, data)
    if SydneyHUD:GetOption("swansong_effect") then
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
        if not hud.panel:child("swan_song_left") then
            local swan_song_left = hud.panel:bitmap({
                name = "swan_song_left",
                visible = false,
                texture = "guis/textures/pd2_mod_sydneyhud/alphawipe_test",
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
    custom_radial_original(self, i, data)
end

local _f_set_player_ability_radial = HUDManager.set_player_ability_radial
function HUDManager:set_player_ability_radial(data)
    if SydneyHUD:GetOption("kingpin_effect") then
        local hud = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
        if not hud.panel:child("chico_injector_left") then
            local chico_injector_left = hud.panel:bitmap({
                name = "chico_injector_left",
                visible = false,
                texture = "guis/textures/pd2_mod_sydneyhud/alphawipe_test",
                layer = 0,
                color = Color(1, 0.6, 0),
                blend_mode = "add",
                w = hud.panel:w(),
                h = hud.panel:h(),
                x = 0,
                y = 0
            })
        end
        local chico_injector_left = hud.panel:child("chico_injector_left")
        if data.current < data.total and data.current > 0 and chico_injector_left then
            chico_injector_left:set_visible(true)
            local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
            chico_injector_left:animate(hudinfo.flash_icon, 4000000000)
        elseif hud.panel:child("chico_injector_left") then
            chico_injector_left:stop()
            chico_injector_left:set_visible(false)
        end
        if chico_injector_left and data.current == 0 then
            chico_injector_left:set_visible(false)
        end
    end
	_f_set_player_ability_radial(self, data)
end

function HUDManager:SydneyHUDUpdate()
    for _, panel in pairs(self._teammate_panels or {}) do -- HUDTeammate
        if panel then
            panel:SydneyHUDUpdate()
        end
    end
    self._hud_interaction:SydneyHUDUpdate() -- HUDInteraction
    if self.UpdateHUDListSettings then
        --self:UpdateHUDListSettings()
    end
end

if not SydneyHUD:GetOption("hudlist_enabled") then
    return
end

function HUDManager:UpdateHUDListSettings()
    local options = HUDListManager.ListOptions
    local avoid = --not changeable by the player
    {
        ["right_list_y"] = true,
        ["left_list_y"] = true
    }
    local minus_one = --multichoice
    {
        ["show_ammo_bags"] = true,
        ["show_doc_bags"] = true,
        ["show_body_bags"] = true,
        ["show_grenade_crates"] = true,
        ["show_sentries"] = true,
        ["show_minions"] = true,
        ["show_enemies"] = true,
        ["show_hostages"] = true,
        ["show_loot"] = true
    }
    local k2
    for k, _ in pairs(options) do
        if type(options[k]) ~= "table" and not avoid[k] then
            if minus_one[k] then
                managers.hudlist:change_setting(k, SydneyHUD:GetModOption("hudlisk", k) - 1)
            else
                managers.hudlist:change_setting(k, SydneyHUD:GetModOption("hudlist", k))
            end
            log(SydneyHUD.dev .. "k: " .. k)
        else
            log(SydneyHUD.dev .. "k is table; skipping")
        end
    end
    for k, _ in pairs(options.ignore_special_pickups) do
        managers.hudlist:change_ignore_special_pickup_setting(k, SydneyHUD:GetHUDListItemOption(k))
    end
    local tbl =
    {
        ["aggressive_reload_aced"] = "aggressive_reload",
        ["armor_break_invulnerable"] = "armor_break_invulnerability",
        ["biker"] = "prospect",
        ["chico_injector"] = "injector",
        ["close_contact"] = "close_contact_no_talk",
        ["grinder"] = "histamine",
        ["maniac"] = "excitement",
        ["melee_stack_damage"] = "overdog_melee_damage",
        ["muscle_regen"] = "800_pound_gorilla",
        ["overdog"] = "overdog_damage_reduction",
        ["pain_killers"] = "painkillers",
        ["running_from_death"] = "running_from_death_basic",
        ["sicario_dodge"] = "twitch",

        -- Custom buff
        ["crew_inspire"] = "ai_inspire_cooldown"
    }
    for k, _ in pairs(options.ignore_buffs) do
        k2 = tbl[k] or k
        managers.hudlist:change_ignore_buff_setting(k, SydneyHUD:GetHUDListBuffOption(k2))
    end

    for k, _ in pairs(options.ignore_player_actions) do
        managers.hudlist:change_ignore_player_action_setting(k, SydneyHUD:GetHUDListPlayerActionOption(k))
    end
end

dofile(SydneyHUD.LuaPath .. "lib/managers/HUDList.lua")

local _setup_player_info_hud_pd2_original = HUDManager._setup_player_info_hud_pd2
function HUDManager:_setup_player_info_hud_pd2()
    _setup_player_info_hud_pd2_original(self)
    if not managers.hudlist then
        if not self:alive(PlayerBase.PLAYER_INFO_HUD_PD2) then
            return
        end
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
function HUDManager:update(t, dt)
    managers.hudlist:update(t, dt)
    update_original(self, t, dt)
end

--if not BAI then -- Preparing for BAI
    local _f_activate_objective = HUDManager.activate_objective
    function HUDManager:activate_objective(data)
        _f_activate_objective(self, data)
        managers.hudlist:list("left_list")._panel:animate(callback(nil, _G, "HUDList_set_offset"), data.amount or nil)
    end
--end