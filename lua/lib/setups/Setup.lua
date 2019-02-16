printf = printf or function(...) end
if RequiredScript == "lib/setups/setup" and Setup then

    local init_managers_original = Setup.init_managers
    local update_original = Setup.update

    function Setup:init_managers(managers, ...)
        managers.gameinfo = managers.gameinfo or GameInfoManager:new()
        managers.gameinfo:post_init()
        return init_managers_original(self, managers, ...)
    end

    function Setup:update(t, dt, ...)
        managers.gameinfo:update(t, dt)
        return update_original(self, t, dt, ...)
    end

else

    GameInfoManager = GameInfoManager or class()
    local plugin = 
    {
        "timers",
        "deployables",
        "sentries",
        "loot",
        "units",
        "pickups",
        "pagers",
        "ecms",
        "cameras",
        "buffs",
        "player_actions"
    }

    local plugin_title =
    {
        "Timers",
        "Deployables",
        "Sentries",
        "Loot",
        "Units",
        "Pickups",
        "Pagers",
        "ECMs",
        "Cameras",
        "Buffs",
        "Player Actions"
    }

    local plugin_desc =
    {
        "Handles drills, hacks and misc. mission timers",
        "Handles mission assets and deployable bags/crates",
        "Tracks deployable sentries",
        "Handles loot-related events, e.g. counting and loot unit tracking",
        "Handles various unit tracking tasks, e.g. for counters",
        "Handles special equipment/pickups",
        "Handles pager events for timers and counters",
        "Handles ECM jammer and feedback timers",
        "Handles tracking of camera units and tape loop timers",
        "Handles tracking of player buff/debuffs and status effects",
        "Handles tracking of player action timers/charges"
    }

    local plugin_init =
    {
        "init_timers_plugin",
        "init_deployables_plugin",
        "init_sentry_plugin",
        "init_loot_plugin",
        "init_unit_plugin",
        "init_pickups_plugin",
        "init_pagers_plugin",
        "init_ecms_plugin",
        "init_cameras_plugin",
        "init_buffs_plugin",
        "init_player_actions_plugin"
    }

    local function InitPlugins()
        for k, _ in pairs(plugin) do
            if not GameInfoManager.has_plugin(plugin[k]) then
                GameInfoManager.add_plugin(plugin[k], { title = plugin_title[k], desc = plugin_desc[k] }, plugin_init[k])
            end
        end
    end
    InitPlugins()

	GameInfoManager._TIMER_CALLBACKS = {
		default = {
			--Digital specific functions
			set = function(timers, key, timer)
				if timers[key] and timers[key].active and not timers[key].duration then
					GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timer)
				end
				GameInfoManager._TIMER_CALLBACKS.default.update(timers, key, Application:time(), timer)
			end,
			start_count_up = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					if not timers[key].duration then
						GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timers[key].timer_value)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			start_count_down = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					if not timers[key].duration then
						GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timers[key].timer_value)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			pause = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, true)
			end,
			resume = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
			end,
			stop = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
			end,
			
			--General functions
			update = function(timers, key, t, timer, progress_ratio)
				if timers[key] then
					timers[key].timer_value = timer
					timers[key].progress_ratio = progress_ratio
					managers.gameinfo:_listener_callback("timer", "update", key, timers[key])
				end
			end,
			set_duration = function(timers, key, duration)
				if timers[key] then
					timers[key].duration = duration
					managers.gameinfo:_listener_callback("timer", "set_duration", key, timers[key])
				end
			end,
			set_active = function(timers, key, status)
				if timers[key] and timers[key].active ~= status then
					timers[key].active = status
					managers.gameinfo:_listener_callback("timer", "set_active", key, timers[key])
				end
			end,
			set_jammed = function(timers, key, status)
				if timers[key] and timers[key].jammed ~= status then
					timers[key].jammed = status
					managers.gameinfo:_listener_callback("timer", "set_jammed", key, timers[key])
				end
			end,
			set_powered = function(timers, key, status)
				local unpowered = not status
				if timers[key] and timers[key].unpowered ~= unpowered then
					timers[key].unpowered = unpowered
					managers.gameinfo:_listener_callback("timer", "set_unpowered", key, timers[key])
				end
			end,
			set_upgradable = function(timers, key, status)
				if timers[key] and timers[key].upgradable ~= status then
					timers[key].upgradable = status
					managers.gameinfo:_listener_callback("timer", "set_upgradable", key, timers[key])
				end
			end,
			set_acquired_upgrades = function(timers, key, acquired_upgrades)
				if timers[key] then
					timers[key].acquired_upgrades = acquired_upgrades
					managers.gameinfo:_listener_callback("timer", "set_acquired_upgrades", key, timers[key])
				end
			end,
		},
		overrides = {
			--Common functions
			stop_on_loud_pause = function(...)
				if not managers.groupai:state():whisper_mode() then
					GameInfoManager._TIMER_CALLBACKS.default.stop(...)
				else
					GameInfoManager._TIMER_CALLBACKS.default.pause(...)
				end
			end,
			stop_on_pause = function(...)
				GameInfoManager._TIMER_CALLBACKS.default.stop(...)
			end,
		
			[132864] = {	--Meltdown vault temperature
				set = function(timers, key, timer)
					if timer > 0 then
						GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set(timers, key, timer)
				end,
				start_count_down = function(timers, key)
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
				end,
				pause = function(...) end,
			},
			[101936] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--GO Bank time lock
			[139706] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Hoxton Revenge alarm	(UNTESTED)
			[132675] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Hoxton Revenge panic room time lock	(UNTESTED)
			[133922] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--The Diamond pressure plates timer
			[130022] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130122] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130222] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130422] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130522] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			--[130320] = { },	--The Diamond outer time lock
			--[130395] = { },	--The Diamond inner time lock
			--[101457] = { },	--Big Bank time lock door #1
			--[104671] = { },	--Big Bank time lock door #2
			--[167575] = { },	--Golden Grin BFD timer
			--[135034] = { },	--Lab rats cloaker safe 1
			--[135076] = { },	--Lab rats cloaker safe 2
			--[135246] = { },	--Lab rats cloaker safe 3
			--[135247] = { },	--Lab rats cloaker safe 4
			[141821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[140321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[139821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[141321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[140821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
		}
	}
    
    function GameInfoManager:init_timers_plugin()
		self._timers = self._timers or {}
	end
	
	function GameInfoManager:get_timers(key)
		if key then
			return self._timers[key]
		else
			return self._timers
		end
	end

	function GameInfoManager:_timer_event(event, key, ...)
		if event == "create" then
			if not self._timers[key] then	
				local unit, ext, device_type = ...
				local id = unit:editor_id()		
				self._timers[key] = { unit = unit, ext = ext, device_type = device_type, id = id, jammed = false, powered = true, upgradable = false }
				self:_listener_callback("timer", "create", key, self._timers[key])
			end
		elseif event == "destroy" then
			if self._timers[key] then
				GameInfoManager._TIMER_CALLBACKS.default.set_active(self._timers, key, false)
				self:_listener_callback("timer", "destroy", key, self._timers[key])
				self._timers[key] = nil
			end
		elseif self._timers[key] then
			local timer_id = self._timers[key].id
			local timer_override = GameInfoManager._TIMER_CALLBACKS.overrides[timer_id]
			
			if timer_override and timer_override[event] then
				timer_override[event](self._timers, key, ...)
			else
				GameInfoManager._TIMER_CALLBACKS.default[event](self._timers, key, ...)
			end
		end
    end
    
    GameInfoManager._DEPLOYABLES = {
		interaction_ids = {
			firstaid_box =		"doc_bag",
			ammo_bag =			"ammo_bag",
			doctor_bag =		"doc_bag",
			bodybags_bag =		"body_bag",
			grenade_crate =	"grenade_crate",
		},
		amount_offsets = {
			[tostring(Idstring("units/payday2/equipment/gen_equipment_ammobag/gen_equipment_ammobag"))] = 0,	--AmmoBagBase / bag
			[tostring(Idstring("units/payday2/props/stn_prop_armory_shelf_ammo/stn_prop_armory_shelf_ammo"))] = -1,	--CustomAmmoBagBase / shelf 1
			[tostring(Idstring("units/pd2_dlc_spa/props/spa_prop_armory_shelf_ammo/spa_prop_armory_shelf_ammo"))] = -1,	--CustomAmmoBagBase / shelf 2
			[tostring(Idstring("units/payday2/equipment/gen_equipment_medicbag/gen_equipment_medicbag"))] = 0,	--DoctorBagBase / bag
			[tostring(Idstring("units/payday2/props/stn_prop_medic_firstaid_box/stn_prop_medic_firstaid_box"))] = -1,	--CustomDoctorBagBase / cabinet 1
			[tostring(Idstring("units/pd2_dlc_casino/props/cas_prop_medic_firstaid_box/cas_prop_medic_firstaid_box"))] = -1,	--CustomDoctorBagBase / cabinet 2
			[tostring(Idstring("units/pd2_dlc_old_hoxton/equipment/gen_equipment_first_aid_kit/gen_equipment_first_aid_kit"))] = 0,	--FirstAidKitBase / FAK
			[tostring(Idstring("units/payday2/equipment/gen_equipment_grenade_crate/gen_equipment_explosives_case"))] = 0,	--GrenadeCrateBase / grenate crate
			[tostring(Idstring("units/payday2/equipment/gen_equipment_grenade_crate/gen_equipment_explosives_case_single"))] = 0,	--CustomGrenadeCrateBase / single grenade box
		},
		ignore_ids = {
			chill_combat = {	--Safehouse Raid (2x ammo shelves)
				[100751] = true,
				[101242] = true,
			},
			sah = { --Shacklethorne Auction (1x3 grenade crate)
				[400178] = true,
			}
		},
    }
    
    function GameInfoManager:init_deployables_plugin()
		self._deployables = self._deployables or {}
		self._deployables.ammo_bag = self._deployables.ammo_bag or {}
		self._deployables.doc_bag = self._deployables.doc_bag or {}
		self._deployables.body_bag = self._deployables.body_bag or {}
		self._deployables.grenade_crate = self._deployables.grenade_crate or {}
	end
	
	function GameInfoManager:get_deployables(type, key)
		if type and key then
			return self._deployables[type][key]
		elseif type then
			return self._deployables[type]
		else
			return self._deployables
		end
	end
	
	function GameInfoManager:_deployable_interaction_handler(event, key, data)
		local type = GameInfoManager._DEPLOYABLES.interaction_ids[data.interact_id]
		
		if self._deployables[type][key] then
			local active = event == "add"
			
			if active then
				local offset = GameInfoManager._DEPLOYABLES.amount_offsets[tostring(data.unit:name())] or 0
				if offset ~= 0 then
					self:_bag_deployable_event("set_amount_offset", key, { amount_offset = offset }, type)
				end
			end
			
			self:_bag_deployable_event("set_active", key, { active = active }, type)
		end
	end
	
	function GameInfoManager:_doc_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "doc_bag")
	end
	
	function GameInfoManager:_ammo_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "ammo_bag")
	end
	
	function GameInfoManager:_body_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "body_bag")
	end
	
	function GameInfoManager:_grenade_crate_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "grenade_crate")
	end
	
	function GameInfoManager:_bag_deployable_event(event, key, data, type)
		if event == "create" then
			if self._deployables[type][key] then return end
			self._deployables[type][key] = { unit = data.unit, type = type }
			self:_listener_callback(type, event, key, self._deployables[type][key])
		elseif self._deployables[type][key] then
			if event == "set_active" then
				if self._deployables[type][key].active == data.active then return end
				self._deployables[type][key].active = data.active
			elseif event == "set_owner" then
				self._deployables[type][key].owner = data.owner
			elseif event == "set_max_amount" then
				self._deployables[type][key].max_amount = data.max_amount
			elseif event == "set_amount_offset" then
				self._deployables[type][key].amount_offset = data.amount_offset
			elseif event == "set_amount" then
				self._deployables[type][key].amount = data.amount
			elseif event == "set_upgrades" then
				self._deployables[type][key].upgrades = data.upgrades
			end
			
			self:_listener_callback(type, event, key, self._deployables[type][key])
			
			if event == "destroy" then
				self._deployables[type][key] = nil
			end
		end
	end
	
	local _interactive_unit_event_original = GameInfoManager._interactive_unit_event
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if GameInfoManager._DEPLOYABLES.interaction_ids[data.interact_id] then
			local ignore_lookup = GameInfoManager._DEPLOYABLES.ignore_ids
			local level_id = managers.job:current_level_id()
			
			if not (ignore_lookup[level] and ignore_lookup[level][data.editor_id]) then
				self:_deployable_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original(self, event, key, data)
    end
    
    function GameInfoManager:init_sentry_plugin()
		self._deployables = self._deployables or {}
		self._deployables.sentry = self._deployables.sentry or {}
	end
	
	function GameInfoManager:get_deployables(type, key)
		if type and key then
			return self._deployables[type][key]
		elseif type then
			return self._deployables[type]
		else
			return self._deployables
		end
	end

	function GameInfoManager:_sentry_event(event, key, data)
		if event == "create" then
			local sentry_type = data.unit:base() and data.unit:base():get_type()
			
			if not self._deployables.sentry[key] and (sentry_type == "sentry_gun" or sentry_type == "sentry_gun_silent") then
				self._deployables.sentry[key] = { unit = data.unit, kills = 0, type = "sentry" }
				self:_listener_callback("sentry", event, key, self._deployables.sentry[key])
			end
		elseif self._deployables.sentry[key] then
			if event == "set_active" then
				if self._deployables.sentry[key].active == data.active then return end
				self._deployables.sentry[key].active = data.active
			elseif event == "set_ammo_ratio" then
				self._deployables.sentry[key].ammo_ratio = data.ammo_ratio
			elseif event == "increment_kills" then
				self._deployables.sentry[key].kills = self._deployables.sentry[key].kills + 1
			elseif event == "set_health_ratio" then
				self._deployables.sentry[key].health_ratio = data.health_ratio
			elseif event == "set_owner" then
				self._deployables.sentry[key].owner = data.owner
			end
			
			self:_listener_callback("sentry", event, key, self._deployables.sentry[key])
			
			if event == "destroy" then
				self._deployables.sentry[key] = nil
			end
		end
    end
    
    GameInfoManager._LOOT = {
		interaction_to_carry = {
			weapon_case =				"weapon",
			weapon_case_axis_z =		"weapon",
			samurai_armor =			"samurai_suit",
			gen_pku_warhead_box =	"warhead",
			corpse_dispose =			"person",
			hold_open_case =			"drone_control_helmet",	--May be reused in future heists for other loot
		},
		bagged_ids = {
			painting_carry_drop = true,
			carry_drop = true,
			safe_carry_drop = true,
			goat_carry_drop = true,
		},
		composite_loot_units = {
			gen_pku_warhead_box = 2,	--[132925] = 2, [132926] = 2, [132927] = 2,	--Meltdown warhead cases
			--hold_open_bomb_case = 4,	--The Bomb heists cases, extra cases on docks screws with counter...
			[103428] = 4, [103429] = 3, [103430] = 2, [103431] = 1,	--Shadow Raid armor
			--[102913] = 1, [102915] = 1, [102916] = 1,	--Train Heist turret (unit fixed, need workaround)
			[105025] = 10, [105026] = 9, [104515] = 8, [104518] = 7, [104517] = 6, [104522] = 5, [104521] = 4, [104520] = 3, [104519] = 2, [104523] = 1, --Slaughterhouse alt 1.
			[105027] = 10, [105028] = 9, [104525] = 8, [104524] = 7, [104490] = 6, [100779] = 5, [100778] = 4, [100777] = 3, [100773] = 2, [100771] = 1, --Slaughterhouse alt 2.
		},
		conditional_ignore_ids = {
			ff3_vault = function(wall_id)
				if managers.job:current_level_id() == "framing_frame_3" then
					for _, unit in pairs(World:find_units_quick("all", 1)) do
						if unit:editor_id() == wall_id then
							return true
						end
					end
				end
			end,

			--FF3 lounge vault
			[100548] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100549] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100550] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100551] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100552] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100553] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100554] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100555] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			--FF3 bedroom vault
			[100556] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100557] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100558] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100559] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100560] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100561] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100562] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100563] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			--FF3 upstairs vault
			[100564] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100566] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100567] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100568] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100569] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100570] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100571] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100572] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
		},
		ignore_ids = {
			watchdogs_2 = {	--Watchdogs day 2 (8x coke)
				[100054] = true, [100058] = true, [100426] = true, [100427] = true, [100428] = true, [100429] = true, [100491] = true, [100492] = true, [100494] = true, [100495] = true,
			},
			family = {	--Diamond store (1x money)
				[100899] = true,
			},	--Hotline Miami day 1 (1x money)
			mia_1 = {	--Hotline Miami day 1 (1x money)
				[104526] = true,
			},
			welcome_to_the_jungle_1 = {	--Big Oil day 1 (1x money, 1x gold)
				[100886] = true, [100872] = true,
			},
			mus = {	--The Diamond (RNG)
				[300047] = true, [300686] = true, [300457] = true, [300458] = true, [301343] = true, [301346] = true,
			},
			arm_und = {	--Transport: Underpass (8x money)
				[101237] = true, [101238] = true, [101239] = true, [103835] = true, [103836] = true, [103837] = true, [103838] = true, [101240] = true,
			},
			ukrainian_job = {	--Ukrainian Job (3x money)
				[101514] = true, [102052] = true, [102402] = true,
			},
			jewelry_store = {	--Jewelry Store (2x money)
				[102052] = true, [102402] = true,
			},
			fish = {	--Yacht (1x artifact painting)
				[500533] = true,
			},
			chill_combat = {	--Safe House Raid (1x artifact painting, 1x toothbrush)
				[150416] = true, [102691] = true,
			},
			tag = {	--Breakin' Feds (1x evidence)
				[134563] = true,
			},
			sah = { --Shacklethorne Auction (2x artifact)
				[400791] = true, [400792] = true,
			}
		},
	}
	GameInfoManager._LOOT.ignore_ids.watchdogs_2_day = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.watchdogs_2)
	GameInfoManager._LOOT.ignore_ids.welcome_to_the_jungle_1_night = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.welcome_to_the_jungle_1)
	GameInfoManager._LOOT.ignore_ids.chill = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.chill_combat)
	
	function GameInfoManager:init_loot_plugin()
		self._loot = self._loot or {}
	end
	
	function GameInfoManager:get_loot(key)
		if key then
			return self._loot[key]
		else
			return self._loot
		end
	end
	
	function GameInfoManager:_loot_interaction_handler(event, key, data)
		if event == "add" then
			if not self._loot[key] then
				local composite_lookup = GameInfoManager._LOOT.composite_loot_units
				local count = composite_lookup[data.editor_id] or composite_lookup[data.interact_id] or 1
				local bagged = GameInfoManager._LOOT.bagged_ids[data.interact_id] and true or false
			
				self._loot[key] = { unit = data.unit, carry_id = data.carry_id, count = count, bagged = bagged }
				self:_listener_callback("loot", "add", key, self._loot[key])
				self:_loot_count_event("change", key, self._loot[key].count)
			end
		elseif event == "remove" then
			if self._loot[key] then
				self:_listener_callback("loot", "remove", key, self._loot[key])
				self:_loot_count_event("change", key, -self._loot[key].count)
				self._loot[key] = nil
			end
		end
	end
	
	function GameInfoManager:_loot_count_event(event, key, value)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("loot_count", "change", self._loot[key].carry_id, self._loot[key], value)
			end
		end
	end
	
	local _interactive_unit_event_original_two = GameInfoManager._interactive_unit_event
	function GameInfoManager:_interactive_unit_event(event, key, data)
		local lookup = GameInfoManager._LOOT
		local carry_id = data.unit:carry_data() and data.unit:carry_data():carry_id() or 
			lookup.interaction_to_carry[data.interact_id] or 
			(self._loot[key] and self._loot[key].carry_id)
		
		if carry_id then
			local level_id = managers.job:current_level_id()
			
			if not (lookup.ignore_ids[level_id] and lookup.ignore_ids[level_id][data.editor_id]) and not (lookup.conditional_ignore_ids[data.editor_id] and lookup.conditional_ignore_ids[data.editor_id]()) then
				data.carry_id = carry_id
				self:_loot_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original_two(self, event, key, data)
	end

    GameInfoManager._INTERACTIONS = {
        INTERACTION_TO_CALLBACK = {
            corpse_alarm_pager =				"_pager_event",
            gen_pku_crowbar =					"_special_equipment_interaction_handler",
            pickup_keycard =					"_special_equipment_interaction_handler",
            pickup_hotel_room_keycard =			"_special_equipment_interaction_handler",
            gage_assignment =					"_special_equipment_interaction_handler",
            pickup_boards =						"_special_equipment_interaction_handler",
            stash_planks_pickup =				"_special_equipment_interaction_handler",
            muriatic_acid =						"_special_equipment_interaction_handler",
            hydrogen_chloride =					"_special_equipment_interaction_handler",
            caustic_soda =						"_special_equipment_interaction_handler",
            press_pick_up =						"_special_equipment_interaction_handler",
            ring_band = 						"_special_equipment_interaction_handler",
            firstaid_box =						"_deployable_interaction_handler",
            ammo_bag =							"_deployable_interaction_handler",
            doctor_bag =						"_deployable_interaction_handler",
            bodybags_bag =						"_deployable_interaction_handler",
            grenade_crate =						"_deployable_interaction_handler",
        },
        INTERACTION_TO_CARRY = {
            weapon_case =					"weapon",
            weapon_case_axis_z =			"weapon",
            samurai_armor =					"samurai_suit",
            gen_pku_warhead_box =			"warhead",
            corpse_dispose =				"person",
            hold_open_case =				"drone_control_helmet",	--May be reused in future heists for other loot
            cut_glass = 					"showcase",
            diamonds_pickup = 				"diamonds_dah",
            red_diamond_pickup = 			"red_diamond",
            red_diamond_pickup_no_axis = 	"red_diamond",

            hold_open_shopping_bag = 		"shopping_bag",
            hold_take_toy = 				"robot_toy",
            hold_take_wine = 				"ordinary_wine",
            hold_take_expensive_wine = 		"expensive_vine",
            hold_take_diamond_necklace =	"diamond_necklace",
            hold_take_vr_headset = 			"vr_headset",
            hold_take_shoes = 				"women_shoes",
            hold_take_old_wine = 			"old_wine",
        },
        BAGGED_IDS = {
            painting_carry_drop = true,
            carry_drop = true,
            safe_carry_drop = true,
            goat_carry_drop = true,
        },
        COMPOSITE_LOOT_UNITS = {
            gen_pku_warhead_box = 2,	--[132925] = 2, [132926] = 2, [132927] = 2,	--Meltdown warhead cases
            --hold_open_bomb_case = 4,	--The Bomb heists cases, extra cases on docks screws with counter...
            [103428] = 4, [103429] = 3, [103430] = 2, [103431] = 1,	--Shadow Raid armor
            --[102913] = 1, [102915] = 1, [102916] = 1,	--Train Heist turret (unit fixed, need workaround)
            [105025] = 10, [105026] = 9, [104515] = 8, [104518] = 7, [104517] = 6, [104522] = 5, [104521] = 4, [104520] = 3, [104519] = 2, [104523] = 1, --Slaughterhouse alt 1.
            [105027] = 10, [105028] = 9, [104525] = 8, [104524] = 7, [104490] = 6, [100779] = 5, [100778] = 4, [100777] = 3, [100773] = 2, [100771] = 1, --Slaughterhouse alt 2.
        },
        CONDITIONAL_IGNORE_IDS = {
            ff3_vault = function(wall_id)
                if managers.job:current_level_id() == "framing_frame_3" then
                    for _, unit in pairs(World:find_units_quick("all", 1)) do
                        if unit:editor_id() == wall_id then
                            return true
                        end
                    end
                end
            end,

            --FF3 lounge vault
            [100548] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100549] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100550] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100551] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100552] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100553] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100554] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            [100555] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
            --FF3 bedroom vault
            [100556] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100557] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100558] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100559] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100560] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100561] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100562] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            [100563] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
            --FF3 upstairs vault
            [100564] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100566] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100567] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100568] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100569] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100570] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100571] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
            [100572] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
        },
        IGNORE_IDS = {
            watchdogs_2 = {	--Watchdogs day 2 (8x coke)
                [100054] = true, [100058] = true, [100426] = true, [100427] = true, [100428] = true, [100429] = true, [100491] = true, [100492] = true, [100494] = true, [100495] = true,
            },
            family = {	--Diamond store (1x money)
                [100899] = true,
            },	--Hotline Miami day 1 (1x money)
            mia_1 = {	--Hotline Miami day 1 (1x money)
                [104526] = true,
            },
            welcome_to_the_jungle_1 = {	--Big Oil day 1 (1x money, 1x gold)
                [100886] = true, [100872] = true,
            },
            mus = {	--The Diamond (RNG)
                [300047] = true, [300686] = true, [300457] = true, [300458] = true, [301343] = true, [301346] = true,
            },
            arm_und = {	--Transport: Underpass (8x money)
                [101237] = true, [101238] = true, [101239] = true, [103835] = true, [103836] = true, [103837] = true, [103838] = true, [101240] = true,
            },
            ukrainian_job = {	--Ukrainian Job (3x money)
                [101514] = true,
                [102052] = true,
                [102402] = true,
            },
            firestarter_2 = {	--Firestarter day 2 (1x keycard)
                [107208] = true,
            },
            big = {	--Big Bank (1x keycard)
                [101499] = true,
            },
            roberts = {	--GO Bank (1x keycard)
                [106104] = true,
            },
            jewelry_store = {	--Jewelry Store (2x money)
                [102052] = true,
                [102402] = true,
            },
            fish = {	--Yacht (1x artifact painting)
                [500533] = true,
            },
            dah = {	-- The Diamond Heist (1x Red Diamond Showcase)
                [100952] = true,
            }
        },
    }
    GameInfoManager._INTERACTIONS.IGNORE_IDS.watchdogs_2_day = table.deep_map_copy(GameInfoManager._INTERACTIONS.IGNORE_IDS.watchdogs_2)
    GameInfoManager._INTERACTIONS.IGNORE_IDS.welcome_to_the_jungle_1_night = table.deep_map_copy(GameInfoManager._INTERACTIONS.IGNORE_IDS.welcome_to_the_jungle_1)

    GameInfoManager.CAMERAS = {
        ["6c5d032fe7e08d01"] = "standard",	--units/payday2/equipment/gen_equipment_security_camera/gen_equipment_security_camera
        ["0c721a9fa6d2fe0a"] = "standard",	--units/world/props/security_camera/security_camera
        ["c64ffaefb39415bc"] = "standard",	--units/world/props/security_camera/security_camera_white
        ["490a9313f945cccf"] = "drone",		--units/pd2_dlc_dark/equipment/gen_drone_camera/gen_drone_camera
    }

    GameInfoManager._EQUIPMENT = {
        SENTRY_KEYS = {
            --unit:name():key() for friendly sentries
            ["07bd083cc5f2d3ba"] = true,	--Standard U100+
            ["c71d763cd8d33588"] = true,	--Suppressed U100+
            ["b1f544e379409e6c"] = true,	--GGC BFD sentries
        },
        INTERACTION_ID_TO_TYPE = {
            firstaid_box =						"doc_bag",
            ammo_bag =							"ammo_bag",
            doctor_bag =						"doc_bag",
            bodybags_bag =						"body_bag",
            grenade_crate =						"grenade_crate",
        },
        AMOUNT_OFFSETS = {
            --interaction_id or editor_id
            firstaid_box = -1,	--GGC drill asset, HB infirmary
        },
        AGGREAGATE_ITEMS = {
            ["first_aid_kit"] = "first_aid_kits",	-- Aggregate all FAKs
            hox_2 = {	--Hoxton breakout
                [136859] = "armory_grenade",
                [136870] = "armory_grenade",
                [136869] = "armory_grenade",
                [136864] = "armory_grenade",
                [136866] = "armory_grenade",
                [136860] = "armory_grenade",
                [136867] = "armory_grenade",
                [136865] = "armory_grenade",
                [136868] = "armory_grenade",
                [136846] = "armory_ammo",
                [136844] = "armory_ammo",
                [136845] = "armory_ammo",
                [136847] = "armory_ammo",
                [101470] = "infirmary_cabinet",
                [101472] = "infirmary_cabinet",
                [101473] = "infirmary_cabinet",
            },
            kenaz = {	--GGC
                [151596] = "armory_grenade",
                [151597] = "armory_grenade",
                [151598] = "armory_grenade",
                [151611] = "armory_ammo",
                [151612] = "armory_ammo",
            },
            born = {	--Biker heist
                [100776] = "bunker_grenade",
                [101226] = "bunker_grenade",
                [101469] = "bunker_grenade",
                [101472] = "bunker_ammo",
                [101473] = "bunker_ammo",
            },
            spa = {		--10-10
                [132935] = "armory_ammo",
                [132938] = "armory_ammo",
                [133085] = "armory_ammo",
                [133088] = "armory_ammo",
                [133835] = "armory_ammo",
                [133838] = "armory_ammo",
                [134135] = "armory_ammo",
                [134138] = "armory_ammo",
                [137885] = "armory_ammo",
                [137888] = "armory_ammo",
            },
        },
    }

    function GameInfoManager:init_unit_plugin()
		self._units = self._units or {}
		self._unit_count = self._unit_count or {}
		self._minions = self._minions or {}
		self._turrets = self._turrets or {}
	end
	
	function GameInfoManager:get_units(key)
		if key then
			return self._units[key]
		else
			return self._units
		end
	end
	
	function GameInfoManager:get_unit_count(id)
		if id then
			return self._unit_count[id] or 0
		else
			return self._unit_count
		end
	end
	
	function GameInfoManager:get_minions(key)
		if key then
			return self._minions[key]
		else
			return self._minions
		end
	end
	
	function GameInfoManager:get_turrets(key)
		if key then
			return self._turrets[key]
		else
			return self._turrets
		end
	end
	
	function GameInfoManager:_unit_event(event, key, data)
		if event == "add" then
			if not self._units[key] then
				local unit_type = data.unit:base()._tweak_table
				self._units[key] = { unit = data.unit, type = unit_type }
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", unit_type, 1)
			end
		elseif event == "remove" then
			if self._units[key] then
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", self._units[key].type, -1)
				self._units[key] = nil
				
				if self._minions[key] then
					self:_minion_event("remove", key)
				end
			end
		end
	end
	
	function GameInfoManager:_unit_count_event(event, unit_type, value)
		if event == "change" then
			if value ~= 0 then
				self._unit_count[unit_type] = (self._unit_count[unit_type] or 0) + value
				self:_listener_callback("unit_count", "change", unit_type, value)
			end
		elseif event == "set" then
			self:_unit_count_event("change", unit_type, value - (self._unit_count[unit_type] or 0))
		end
	end
	
	function GameInfoManager:_minion_event(event, key, data)
		if event == "add" then
			if not self._minions[key] then
				self._minions[key] = { unit = data.unit, kills = 0, type = data.unit:base()._tweak_table }
				self:_listener_callback("minion", "add", key, self._minions[key])
				self:_unit_count_event("change", "minion", 1)
			end
		elseif self._minions[key] then
			if event == "set_health_ratio" then
				self._minions[key].health_ratio = data.health_ratio
			elseif event == "increment_kills" then
				self._minions[key].kills = self._minions[key].kills + 1
			elseif event == "set_owner" then
				self._minions[key].owner = data.owner
			elseif event == "set_damage_resistance" then
				self._minions[key].damage_resistance = data.damage_resistance
			elseif event == "set_damage_multiplier" then
				self._minions[key].damage_multiplier = data.damage_multiplier
			end
			
			self:_listener_callback("minion", event, key, self._minions[key])
			
			if event == "remove" then
				self:_unit_count_event("change", "minion", -1)
				self._minions[key] = nil
			end
		end
	end
	
	function GameInfoManager:_turret_event(event, key, unit)
		if event == "add" then
			if not self._turrets[key] then
				self._turrets[key] = unit
				self:_unit_count_event("change", "turret", 1)
			end
		elseif event == "remove" then
			if self._turrets[key] then
				self:_unit_count_event("change", "turret", -1)
				self._turrets[key] = nil
			end
		end
    end

    GameInfoManager._PICKUPS = {
		interaction_ids = {
			gen_pku_crowbar = true,
			pickup_keycard = true,
			pickup_hotel_room_keycard = true,
			gage_assignment = true,
			pickup_boards = true,
			stash_planks_pickup = true,
			muriatic_acid = true,
			hydrogen_chloride = true,
			caustic_soda = true,
			press_pick_up = true,
			ring_band = true,
		},
		ignore_ids = {
			firestarter_2 = {	--Firestarter day 2 (1x keycard)
				[107208] = true,
			},
			big = {	--Big Bank (1x keycard)
				[101499] = true,
			},
			roberts = {	--GO Bank (1x keycard)
				[106104] = true,
			},
		},
    }
    
    function GameInfoManager:init_pickups_plugin()
		self._special_equipment = self._special_equipment or {}
	end
	
	function GameInfoManager:get_special_equipment(key)
		if key then
			return self._special_equipment[key]
		else
			return self._special_equipment
		end
	end
	
	function GameInfoManager:_special_equipment_interaction_handler(event, key, data)
		if event == "add" then
			if not self._special_equipment[key] then
				self._special_equipment[key] = { unit = data.unit, interact_id = data.interact_id }
				self:_listener_callback("special_equipment", "add", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, 1, self._special_equipment[key])
			end
		elseif event == "remove" then
			if self._special_equipment[key] then
				self:_listener_callback("special_equipment", "remove", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, -1, self._special_equipment[key])
				self._special_equipment[key] = nil
			end
		end
	end
	
	function GameInfoManager:_special_equipment_count_event(event, interact_id, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("special_equipment_count", "change", interact_id, value, data)
			end
		end
	end
	
	local _interactive_unit_event_original_three = GameInfoManager._interactive_unit_event
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if GameInfoManager._PICKUPS.interaction_ids[data.interact_id] then
			local level_id = managers.job:current_level_id()
			
			if not (GameInfoManager._PICKUPS.ignore_ids[level_id] and GameInfoManager._PICKUPS.ignore_ids[level_id][data.editor_id]) then
				self:_special_equipment_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original_three(self, event, key, data)
    end
    
    function GameInfoManager:init_pagers_plugin()
		self._pagers = self._pagers or {}
	end
	
	function GameInfoManager:get_pagers(key)
		if key then
			return self._pagers[key]
		else
			return self._pagers
		end
	end
	
	function GameInfoManager:_pager_event(event, key, data)
		if event == "add" then
			if not self._pagers[key] then
				local t = Application:time()
				
				self._pagers[key] = { 
					unit = data.unit, 
					active = true, 
					answered = false,
					start_t = t,
					expire_t = t + 12,
				}
				self:_listener_callback("pager", "add", key, self._pagers[key])
			end
		elseif self._pagers[key] then
			if event == "remove" then
				if self._pagers[key].active then
					self:_listener_callback("pager", "remove", key, self._pagers[key])
					self._pagers[key].active = nil
				end
			elseif event == "set_answered" then
				if not self._pagers[key].answered then
					self._pagers[key].answered = true
					self:_listener_callback("pager", "set_answered", key, self._pagers[key])
				end
			end
		end
	end
	
	local _interactive_unit_event_original_four = GameInfoManager._interactive_unit_event
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if data.interact_id == "corpse_alarm_pager" then
			self:_pager_event(event, key, data)
		end
		
		return _interactive_unit_event_original_four(self, event, key, data)
    end
    
    function GameInfoManager:init_ecms_plugin()
		self._ecms = self._ecms or {}
	end
	
	function GameInfoManager:get_ecms(key)
		if key then
			return self._ecms[key]
		else
			return self._ecms
		end
	end
	
	function GameInfoManager:_ecm_event(event, key, data)
		if event == "create" then
			if self._ecms[key] then return end
			self._ecms[key] = { unit = data.unit, is_pocket_ecm = data.is_pocket_ecm, max_duration = data.max_duration, t = data.t, expire_t = data.expire_t }
			self:_listener_callback("ecm", event, key, self._ecms[key])
		elseif self._ecms[key] then
			if event == "set_jammer_battery" then
				if not self._ecms[key].jammer_active then return end
				self._ecms[key].jammer_battery = data.jammer_battery
			elseif event == "set_retrigger_delay" then
				if not self._ecms[key].retrigger_active then return end
				self._ecms[key].retrigger_delay = data.retrigger_delay
			elseif event == "set_jammer_active" then
				if self._ecms[key].jammer_active == data.jammer_active then return end
				self._ecms[key].jammer_active = data.jammer_active
			elseif event == "set_retrigger_active" then
				if self._ecms[key].retrigger_active == data.retrigger_active then return end
				self._ecms[key].retrigger_active = data.retrigger_active
			elseif event == "set_owner" then
				self._ecms[key].owner = data.owner
			elseif event == "set_upgrade_level" then
				self._ecms[key].upgrade_level = data.upgrade_level
			end
			
			self:_listener_callback("ecm", event, key, self._ecms[key])
			
			if event == "destroy" then
				self._ecms[key] = nil
			end
		end
    end
    
    function GameInfoManager:init_cameras_plugin()
		self._cameras = self._cameras or {}
	end
	
	function GameInfoManager:get_cameras(key)
		if key then
			return self._cameras[key]
		else
			return self._cameras
		end
	end
	
	function GameInfoManager:_camera_event(event, key, data)
		if event == "create" then
			if not self._cameras[key] then
				self._cameras[key] = { unit = data.unit }
				self:_listener_callback("camera", event, key, self._cameras[key])
			end
		elseif self._cameras[key] then
			if event == "set_active" then
				if self._cameras[key].active == data.active then return end
				self._cameras[key].active = data.active
			elseif event == "start_tape_loop" then
				self._cameras[key].tape_loop_expire_t = data.tape_loop_expire_t
				self._cameras[key].tape_loop_start_t = Application:time()
			elseif event == "stop_tape_loop" then
				self._cameras[key].tape_loop_expire_t = nil
				self._cameras[key].tape_loop_start_t = nil
			end
			
			self:_listener_callback("camera", event, key, self._cameras[key])
			
			if event == "destroy" then
				self._cameras[key] = nil
			end
		end
	end

	GameInfoManager._BUFFS = {
		definitions = {
			temporary = {
				chico_injector =									{ "chico_injector", },
				damage_speed_multiplier =						{ "second_wind" },
				team_damage_speed_multiplier_received =	{ "second_wind" },
				dmg_multiplier_outnumbered =					{ "underdog" },
				dmg_dampener_outnumbered =						{ "underdog_aced" },
				dmg_dampener_outnumbered_strong =			{ "overdog" },
				dmg_dampener_close_contact =					{ "close_contact", "close_contact", "close_contact" },
				overkill_damage_multiplier =					{ "overkill" },
				berserker_damage_multiplier =					{ "swan_song", "swan_song_aced" },
				first_aid_damage_reduction =					{ "quick_fix" },
				increased_movement_speed =						{ "running_from_death_move_speed" },
				reload_weapon_faster =							{ "running_from_death_reload_speed" },
				revived_damage_resist =							{ "up_you_go" },
				swap_weapon_faster =								{ "running_from_death_swap_speed" },
				single_shot_fast_reload =						{ "aggressive_reload_aced" },
				armor_break_invulnerable =						{ "armor_break_invulnerable_debuff" },
				loose_ammo_restore_health =					{ "medical_supplies_debuff" },
				melee_life_leech =								{ "life_drain_debuff" },
				loose_ammo_give_team =							{ "ammo_give_out_debuff" },
				revive_damage_reduction =						{ "combat_medic_success" },
				unseen_strike =									{ "unseen_strike", "unseen_strike" },
                pocket_ecm_kill_dodge =							{ "pocket_ecm_kill_dodge" },
			},
			property = {
				bloodthirst_reload_speed =						{ "bloodthirst_aced" },
				revived_damage_reduction =						{ "pain_killer" },
				revive_damage_reduction =						{ "combat_medic_interaction" },
				bullet_storm =										{ "bullet_storm" },
				shock_and_awe_reload_multiplier =			{ "lock_n_load" },
				trigger_happy =									{ "trigger_happy" },
				desperado =											{ "desperado" },
				bipod_deploy_multiplier =						false,
			},
			cooldown = {
                long_dis_revive =									{ "inspire_revive_debuff" },
                crew_inspire = { "ai_inspire_cooldown" }
			},
			team = {
				damage_dampener = {
					team_damage_reduction =						{ "cc_passive_damage_reduction" },
					hostage_multiplier =							{ "cc_hostage_damage_reduction" },
				},
				stamina = {
					passive_multiplier = 						{ "cc_passive_stamina_multiplier" },
					hostage_multiplier =							{ "cc_hostage_stamina_multiplier" },
				},
				health = {
					passive_multiplier =							{ "cc_passive_health_multiplier" },
					hostage_multiplier =							{ "cc_hostage_health_multiplier" },
				},
				armor = {
					multiplier =									{ "cc_passive_armor_multiplier" },
					passive_regen_time_multiplier =			{ "armorer_armor_regen_multiplier" },
					regen_time_multiplier =						{ "shock_and_awe" },
				},
				damage = {
					hostage_absorption =							{ "forced_friendship" },
				},
			},
		},
		event_clbks = {
			activate = {
				armor_break_invulnerable_debuff = function()
					local duration = managers.player:upgrade_value("temporary", "armor_break_invulnerable")[1]
					managers.gameinfo:event("buff", "activate", "armor_break_invulnerable")
					managers.gameinfo:event("buff", "set_duration", "armor_break_invulnerable", { duration = duration })
				end,
			},
			set_duration = {
				overkill = function(id, data)
					if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
						local duration = managers.player:upgrade_value("temporary", "overkill_damage_multiplier")[2]
						managers.gameinfo:event("buff", "activate", "overkill_aced")
						managers.gameinfo:event("buff", "set_duration", "overkill_aced", { duration = duration })
					end
				end,
			},
			set_value = {
				overkill = function(id, data)
					if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
						local value = managers.player:upgrade_value("temporary", "overkill_damage_multiplier")[1]
						managers.gameinfo:event("buff", "set_value", "overkill_aced", { value = value })
					end
				end,
			},
		},
    }
    
    function GameInfoManager:init_buffs_plugin()
		self._buffs = self._buffs or {}
		self._team_buffs = self._team_buffs or {}
		
		self:add_scheduled_callback("init_local_team_buffs", 0, function()
			for category, data in pairs(Global.player_manager.team_upgrades or {}) do
				for upgrade, value in pairs(data) do
					managers.gameinfo:event("team_buff", "activate", 0, category, upgrade, 1)
				end
			end
		end)
    end
    
    function GameInfoManager:init_player_actions_plugin()
		self._player_actions = self._player_actions or {}
	end
	
	function GameInfoManager:get_buffs(id)
		if id then
			return self._buffs[id]
		else
			return self._buffs
		end
	end
	
	function GameInfoManager:get_player_actions(id)
		if id then
			return self._player_actions[id]
		else
			return self._player_actions
		end
	end
	
	
	function GameInfoManager:_buff_event(event, id, data)
		if event == "activate" then
			if self._buffs[id] then return end
            self._buffs[id] = {}
		elseif self._buffs[id] then
			if event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or (data.duration + t)
				
				if self._buffs[id].t == t and 
					self._buffs[id].expire_t == expire_t and 
					self._buffs[id].no_expire == data.no_expire then 
                        return
				end
				
				self._buffs[id].t = t
				self._buffs[id].expire_t = expire_t
                self._buffs[id].no_expire = data.no_expire
				
				if not self._buffs[id].no_expire then
                    self:add_scheduled_callback(id .. "_expire", expire_t - Application:time(), callback(self, self, "_buff_event"), "deactivate", id)
				end
			elseif event == "set_value" then
				if self._buffs[id].value == data.value then return end
				self._buffs[id].value = data.value
			elseif event == "set_stack_count" then
				if self._buffs[id].stack_count == data.stack_count then return end
				self._buffs[id].stack_count = data.stack_count
			elseif event == "set_expire" then
				local expire_t = data.duration and (data.duration + Application:time()) or data.expire_t
				return self:_buff_event("set_duration", id, { t = self._buffs[id].t, expire_t = expire_t, no_expire = self._buffs[id].no_expire })
			elseif event == "change_expire" then
				local expire_t = data.difference and (self._buffs[id].expire_t + data.difference) or data.expire_t
				return self:_buff_event("set_duration", id, { t = self._buffs[id].t, expire_t = expire_t, no_expire = self._buffs[id].no_expire })
			elseif event == "increment_stack_count" then
				return self:_buff_event("set_stack_count", id, { stack_count = (self._buffs[id].stack_count or 0) + 1 })
			elseif event == "decrement_stack_count" then
				return self:_buff_event("set_stack_count", id, { stack_count = (self._buffs[id].stack_count or 0) - 1 })
			end
		else
			return
		end
		
		--printf("(%.2f) GameInfoManager:_buff_event(%s, %s)", Application:time(), event, id)
		--[[
		for k, v in pairs(self._buffs[id]) do
			printf("\t%s: %s", tostring(k), tostring(v))
		end
		]]
		self:_listener_callback("buff", event, id, self._buffs[id])
		
		local event_clbk = GameInfoManager._BUFFS.event_clbks[event] and GameInfoManager._BUFFS.event_clbks[event][id]
		if event_clbk then
			event_clbk(id, self._buffs[id])
		end
		
		if event == "deactivate" then
			if not self._buffs[id].no_expire then
				self:remove_scheduled_callback(id .. "_expire")
			end
			self._buffs[id] = nil
		end
	end
	
	function GameInfoManager:_temporary_buff_event(event, category, upgrade, level, data)		
		local defs = GameInfoManager._BUFFS.definitions
		local buff_data = defs[category] and defs[category][upgrade]
		
		if buff_data then
			local id = buff_data[level or 1]
			
			if id and not buff_data.ignore then
				self:_buff_event(event, id, data)
			end
		elseif buff_data == nil then
			printf("(%.2f) GameInfoManager:_temporary_buff_event(%s): Unrecognized buff %s %s %s", Application:time(), event, tostring(category), tostring(upgrade), tostring(level))
		end
	end
	
	function GameInfoManager:_team_buff_event(event, peer_id, category, upgrade, level, data)
		local defs = GameInfoManager._BUFFS.definitions.team
		local id = defs[category] and defs[category][upgrade] and defs[category][upgrade][level]
		
		if id then
			self._team_buffs[id] = self._team_buffs[id] or {}
			local was_active = next(self._team_buffs[id])
			
			if event == "activate" then
				self._team_buffs[id][peer_id] = true
				
				if not was_active then
					self:_buff_event(event, id)
				end
			elseif event == "deactivate" then
				self._team_buffs[id][peer_id] = nil
				
				if was_active and not next(self._team_buffs[id]) then
					self:_buff_event(event, id)
				end
			elseif event == "set_value" then
				self:_buff_event(event, id, data)
			end
		else
			printf("(%.2f) GameInfoManager:_team_buff_event(%s, %s): Unrecognized buff %s %s %s", Application:time(), event, tostring(peer_id), tostring(category), tostring(upgrade), tostring(level))
		end
	end
	
	local STACK_ID = 0
	function GameInfoManager:_timed_stack_buff_event(event, id, data)
		if event == "add_timed_stack" then
			if not self._buffs[id] then
				self:_buff_event("activate", id, data)
				self._buffs[id].stacks = {}
			end
			
			local ct = Application:time()
			local t = data.t or ct
			local expire_t = data.expire_t or (data.duration + t)
			local value = data.value
			self._buffs[id].stacks[STACK_ID] = { t = t, expire_t = expire_t, value = value }
			self:add_scheduled_callback(string.format("%s_%s", id, STACK_ID), expire_t - ct, callback(self, self, "_timed_stack_buff_event"), "remove_timed_stack", id, { stack_id = STACK_ID })
			
			STACK_ID = (STACK_ID + 1) % 10000
			
			self:_listener_callback("buff", event, id, self._buffs[id])
			--self:_buff_event("increment_stack_count", id)
		elseif self._buffs[id] and self._buffs[id].stacks then
			if event == "remove_timed_stack" then
				if self._buffs[id].stacks[data.stack_id] then
					self._buffs[id].stacks[data.stack_id] = nil
					self:remove_scheduled_callback(id .. "_" .. data.stack_id)
					self:_listener_callback("buff", event, id, self._buffs[id])
					--self:_buff_event("decrement_stack_count", id)
					
					if not next(self._buffs[id].stacks) then
						self:_buff_event("deactivate", id, data)
					end
				end
			end
		end
	end
	
	function GameInfoManager:_player_weapon_event(event, key, data)
		self:_listener_callback("player_weapon", event, key, data)
	end

    function GameInfoManager:get_sentries(key)
        if key then
            return self._sentries[key]
        else
            return self._sentries
        end
    end

    function GameInfoManager:_player_action_event(event, id, data)
		if event == "activate" then
			if self._player_actions[id] then return end
			self._player_actions[id] = {}
		elseif self._player_actions[id] then
			if event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or (data.duration + t)
				self._player_actions[id].t = t
				self._player_actions[id].expire_t = expire_t
			elseif event == "set_value" then
				self._player_actions[id].value = data.value
			elseif event == "set_expire" then
				local expire_t = data.duration and (data.duration + Application:time()) or data.expire_t
				return self:_player_action_event("set_duration", id, { t = self._player_actions[id].t, expire_t = expire_t })
			elseif event == "change_expire" then
				local expire_t = data.difference and (self._player_actions[id].expire_t + data.difference) or data.expire_t
				return self:_player_action_event("set_duration", id, { t = self._player_actions[id].t, expire_t = expire_t })
			end
		else
			return
		end
		
		--printf("(%.2f) GameInfoManager:_player_action_event(%s, %s)", Application:time(), event, id)
		--for k, v in pairs(self._player_actions[id]) do
		--	printf("\t%s: %s", tostring(k), tostring(v))
		--end
		
		self:_listener_callback("player_action", event, id, self._player_actions[id])
		
		if event == "deactivate" then
			self._player_actions[id] = nil
		end
    end

    HUDListManager = HUDListManager or class()
    function HUDListManager:init(hud_panel)
        self._hud_panel = hud_panel
        self._lists = {}
    end

    function HUDListManager:post_init()
        for _, clbk in ipairs(HUDListManager.post_init_events or {}) do
            clbk()
        end
        
        HUDListManager.post_init_events = nil
    end

    function HUDListManager:lists() return self._lists end
    function HUDListManager:list(id) return self._lists[id] end

    function HUDListManager:add_list(id, class, ...)
        if not self._lists[id] then
            local class = HUDListManager.get_class(class)
            self._lists[id] = class:new(id, self._hud_panel, ...)
            self._lists[id]:post_init(...)
        end
        
        return self._lists[id]
    end

    function HUDListManager:remove_list(id)
        if self._lists[id] then
            self._lists[id] = nil
        end
    end

    function HUDListManager:update(t, dt)
        for _, list in pairs(self._lists) do
            if list and list:active() then
                list:update(t, dt)
            end
        end
    end

    function HUDListManager.get_class(class)
        return type(class) == "string" and _G.HUDList[class] or class
    end

    function HUDListManager.add_post_init_event(clbk)
        if managers and managers.hudlist then
            clbk()
        else
            HUDListManager.post_init_events = HUDListManager.post_init_events or {}
            table.insert(HUDListManager.post_init_events, clbk)
        end
    end

    
    HUDList = HUDList or {}
    HUDList.Base = HUDList.Base or class()
    HUDList.Base._item_number = 0	--Unique ID for all items created, incremented in HUDList.Base:init()
    function HUDList.Base:init(id, ppanel, data)
        local data = data or {}

        self._internal = {
            id = id,
            parent_panel = ppanel,
            priority = data.priority or 0,
            item_number = HUDList.Base._item_number,
            visible = false,
            active = false,
            inactive_reasons = { default = true },
            enabled = true,
            disabled_reasons = {},
            fade_rate = data.fade_rate or 4,
            move_rate = data.fade_rate or 100,
            temp_instant_positioning = true,
        }
        
        self._panel = self._internal.parent_panel:panel({
            name = id,
            visible = false,
            alpha = 0,
            w = data.w or 0,
            h = data.h or 0,
            x = data.x or 0,
            y = data.y or 0,
        })
        
        if data.bg then
            self._panel:rect({
                name = "bg",
                halign = "grow",
                valign = "grow",
                alpha = data.bg.alpha or 0.25,
                color = data.bg.color or Color.black,
                layer = -100,
            })
        end
        
        HUDList.Base._item_number = HUDList.Base._item_number + 1
    end

    function HUDList.Base:set_parent_list(plist)
        self._internal.parent_list = plist
    end

    function HUDList.Base:post_init(...)

    end

    function HUDList.Base:destroy()
        if alive(self._panel) and alive(self._internal.parent_panel) then
            self._internal.parent_panel:remove(self._panel)
        end
    end

    function HUDList.Base:delete(instant)
        self._internal.deleted = true
        
        if instant or not self._internal.fade_rate or not self:visible() then
            self:_visibility_state_changed(false)
        else
            self:set_active(false)
        end
    end

    function HUDList.Base:set_target_position(x, y, instant)
        if not alive(self._panel) then
            debug_print("Dead panel for item: %s", tostring(self:id()))
            return
        end

        if self._move_thread_x then
            self._panel:stop(self._move_thread_x)
            self._move_thread_x = nil
        end
        if self._move_thread_y then
            self._panel:stop(self._move_thread_y)
            self._move_thread_y = nil
        end

        if instant or self._internal.temp_instant_positioning or not self._internal.move_rate then
            self._panel:set_position(x, y)
        else
            local do_move = function(o, init, target, rate, move_func)
                over(math.abs(init - target) / rate, function(r)
                    move_func(o, math.lerp(init, target, r))
                end)
                
                move_func(o, target)
            end
            
            self._move_thread_x = self._panel:animate(do_move, self._panel:x(), x, self._internal.move_rate, function(o, v) o:set_x(v) end)
            self._move_thread_y = self._panel:animate(do_move, self._panel:y(), y, self._internal.move_rate, function(o, v) o:set_y(v) end)
        end
        
        self._internal.temp_instant_positioning = nil
    end

    function HUDList.Base:set_target_alpha(alpha, instant)
        if not alive(self._panel) then
            debug_print("Dead panel for item: %s", tostring(self:id()))
            return
        end

        if self._fade_thread then
            self._panel:stop(self._fade_thread)
            self._fade_thread = nil
        end
        
        self:_set_visible(alpha > 0 or self._panel:alpha() > 0)
        
        if instant or not self._internal.fade_rate then
            self._panel:set_alpha(alpha)
            self:_set_visible(alpha > 0)
        else
            local do_fade = function(o, init, target, rate)
                over(math.abs(init - target) / rate, function(r)
                    local a = math.lerp(init, target, r)
                    o:set_alpha(a)
                end)
                
                o:set_alpha(target)
                self:_set_visible(target > 0)
            end
            
            self._fade_thread = self._panel:animate(do_fade, self._panel:alpha(), alpha, self._internal.fade_rate)
        end
    end

    function HUDList.Base:set_priority(priority)
        local priority = priority or 0
        
        if self._internal.priority ~= priority then
            self._internal.priority = priority
            
            if self._internal.parent_list then
                self._internal.parent_list:rearrange()
            end
        end
    end

    function HUDList.Base:set_active(state, reason)
        local state = not (state and true or false)
        local reason = reason or "default"
        
        self._internal.inactive_reasons[reason] = state and true or nil
        local active = not next(self._internal.inactive_reasons)
        
        if self._internal.active ~= active then
            self._internal.active = active
            self:set_target_alpha(active and 1 or 0)
        end
    end

    function HUDList.Base:set_enabled(state, reason)
        local state = not (state and true or false)
        local reason = reason or "default"
        
        self._internal.disabled_reasons[reason] = state and true or nil
        local enabled = not next(self._internal.disabled_reasons)
        
        if self._internal.enabled ~= enabled then
            self._internal.enabled = enabled
            self:_set_visible(self._panel:alpha() > 0)
        end
    end

    function HUDList.Base:update(t, dt)

    end

    function HUDList.Base:id() return self._internal.id end
    function HUDList.Base:active() return self._internal.active end
    function HUDList.Base:enabled() return self._internal.enabled end
    function HUDList.Base:visible() return self._internal.visible end
    function HUDList.Base:priority() return self._internal.priority end
    function HUDList.Base:item_number() return self._internal.item_number end
    function HUDList.Base:panel() return self._panel end

    function HUDList.Base:set_fade_rate(rate) self._internal.fade_rate = rate end
    function HUDList.Base:set_move_rate(rate) self._internal.move_rate = rate end
    function HUDList.Base:activate(reason) self:set_active(true, reason) end
    function HUDList.Base:deactivate(reason) self:set_active(false, reason) end
    function HUDList.Base:enable(reason) self:set_enabled(true, reason) end
    function HUDList.Base:disable(reason) self:set_enabled(false, reason) end

    function HUDList.Base:_delete()
        if self._internal.parent_list then
            self._internal.parent_list:_delete_item(self._internal.id)
        else
            managers.hudlist:remove_list(self._internal.id)
        end
        
        self:destroy()
    end

    function HUDList.Base:_set_visible(state)
        local state = state and self:enabled() and true or false
        
        if self._internal.visible ~= state then
            self._internal.visible = state
            self._panel:set_visible(state)
            self:_visibility_state_changed(state)
        end
    end

    function HUDList.Base:_visibility_state_changed(state)
        if not state and self._internal.deleted then
            self:_delete()
        end
        
        if self._internal.parent_list then
            self._internal.parent_list:item_visibility_state_changed(self._internal.id, state)
        end
    end


    HUDList.ListBase = HUDList.ListBase or class(HUDList.Base)
    function HUDList.ListBase:init(id, ppanel, data)
        HUDList.ListBase.super.init(self, id, ppanel, data)
        
        self:set_fade_rate(nil)
        
        self._item_margin = data and data.item_margin or 0
        self._max_items = data and data.max_items
        self._valign = data and data.valign
        self._halign = data and data.halign
        
        self._items = {}
        self._item_index = {}	--Read using self:_get_item_index() to ensure it updates if necessary before reading
        self._item_order = {}
        
        if data.static_item then
            local class = HUDListManager.get_class(data.static_item.class)
            self._static_item = class:new(
                "static",
                self._panel,
                unpack(data.static_item.data or {}))
        end
        
        if data.expansion_indicator then
            --TODO
            --self._expansion_indicator = HUDList.ExpansionIndicator:new("expansion_indicator", self._panel)
            --self._expansion_indicator:post_init()
        end
    end

    function HUDList.ListBase:post_init(...)
        HUDList.ListBase.super.post_init(self)
        
        if self._static_item then
            self._static_item:activate()
            self:_update_item_order()
        end
    end

    function HUDList.ListBase:destroy()
        self:clear_items(true)
        HUDList.ListBase.super.destroy(self)
    end

    function HUDList.ListBase:items() return self._items end
    function HUDList.ListBase:item(id) return self._items[id] end
    function HUDList.ListBase:static_item() return self._static_item end
    function HUDList.ListBase:expansion_indicator() return self._expansion_indicator end

    function HUDList.ListBase:update(t, dt)
        HUDList.ListBase.super.update(self, t, dt)
        
        for _, id in ipairs(self:_get_item_index()) do
            local item = self._items[id]
            
            if item and item:active() then
                item:update(t, dt)
            end
        end
        
        if self._internal.rearrange_needed then
            self:_update_item_order()
            self:_rearrange()
            self._internal.rearrange_needed = false
        end
    end

    function HUDList.ListBase:add_item(id, class, ...)
        if not self._items[id] then
            self._items[id] = HUDListManager.get_class(class):new(id, self._panel, ...)
            self._items[id]:set_parent_list(self)
            self._items[id]:post_init(...)
            self._index_update_needed = true
        else
            self._items[id]._internal.deleted = nil
        end
        
        return self._items[id]
    end

    function HUDList.ListBase:clear_items(instant)
        for _, id in ipairs(self:_get_item_index()) do
            self._items[id]:delete(instant)
        end
    end

    function HUDList.ListBase:remove_item(id, instant)
        if self._items[id] then
            self._items[id]:delete(instant)
        end
    end

    function HUDList.ListBase:_delete_item(id)
        self._items[id] = nil
        self._index_update_needed = true
    end

    function HUDList.ListBase:item_visibility_state_changed(id, state)
        self:rearrange()
        
        if state then
            self:set_active(true)
        else
            for id, item in pairs(self._items) do
                if item:visible() then
                    return
                end
            end
            self:set_active(false)
        end
    end

    function HUDList.ListBase:rearrange()
        self._internal.rearrange_needed = true
    end

    function HUDList.ListBase:_get_item_index()
        if self._index_update_needed then
            self._item_index = {}
            self._index_update_needed = nil
            
            for id, item in pairs(self._items) do
                table.insert(self._item_index, id)
            end
        end
        
        return self._item_index
    end

    function HUDList.ListBase:_update_item_order()
        local new_order = {}
        
        for id, item in pairs(self._items) do
            local insert_at = #new_order + 1
            local new_data = { id = id, prio = item:priority(), no = item:item_number() }
            
            for i, data in ipairs(new_order) do
                if (data.prio < new_data.prio) or ((data.prio == new_data.prio) and (data.no > new_data.no)) then
                    insert_at = i
                    break
                end
            end
            
            table.insert(new_order, insert_at, new_data)
        end
        
        local total_items = #new_order
        local list_maxed = self._max_items and (total_items > self._max_items) or false
        
        self._item_order = {}
        for i, data in ipairs(new_order) do
            table.insert(self._item_order, data.id)
            self._items[data.id]:set_active(not list_maxed or i <= self._max_items, "list_full")
        end
        
        if self._expansion_indicator then
            self._expansion_indicator:set_active(list_maxed)
            if list_maxed then
                self._expansion_indicator:set_extra_count(total_items - self._max_items)
                table.insert(self._item_order, self._max_items + 1, self._expansion_indicator:id())
            end
        end
        
        if self._static_item and self._static_item:visible() then
            table.insert(self._item_order, 1, self._static_item:id())
        end
        
        return self._item_order
    end


    HUDList.HorizontalList = HUDList.HorizontalList or class(HUDList.ListBase)
    function HUDList.HorizontalList:init(...)
        HUDList.HorizontalList.super.init(self, ...)
    end

    function HUDList.HorizontalList:_rearrange()
        local w = 0
        
        if self._halign == "center"  then
            local total_w = 0
            
            for _, id in ipairs(self._item_order) do
                local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
                
                if item:visible() then
                    total_w = total_w + self._item_margin + item:panel():w()
                end
            end
            
            w = (self._panel:w() - total_w + self._item_margin) / 2
        end
        
        for _, id in ipairs(self._item_order) do
            local x, y
            local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
            local p = item:panel()
            
            if self._halign == "right" then
                x = self._panel:w() - w - p:w()
            else
                x = w
            end
            
            if self._valign == "top" then
                y = 0
            elseif self._valign == "bottom" then
                y = self._panel:h() - p:h()
            else
                y = (self._panel:h() - p:h()) / 2
            end
            
            item:set_target_position(x, y)
            
            if item:visible() then
                w = w + p:w() + self._item_margin
            end
        end
    end


    HUDList.VerticalList = HUDList.VerticalList or class(HUDList.ListBase)
    function HUDList.VerticalList:init(...)
        HUDList.VerticalList.super.init(self, ...)
    end

    function HUDList.VerticalList:_rearrange()
        local h = 0

        if self._valign == "center"  then
            local total_h = 0
            
            for _, id in ipairs(self._item_order) do
                local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
                
                if item:visible() then
                    total_h = total_h + self._item_margin + item:panel():h()
                end
            end
            
            h = (self._panel:h() - total_h + self._item_margin) / 2
        end
        
        for _, id in ipairs(self._item_order) do
            local x, y
            local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
            local p = item:panel()
            
            if self._valign == "bottom" then
                y = self._panel:h() - h - p:h()
            else
                y = h
            end
            
            if self._halign == "left" then
                x = 0
            elseif self._halign == "right" then
                x = self._panel:w() - p:w()
            else
                x = (self._panel:w() - p:w()) / 2
            end
            
            item:set_target_position(x, y)
            
            if item:visible() then
                h = h + p:h() + self._item_margin
            end
        end
    end

end