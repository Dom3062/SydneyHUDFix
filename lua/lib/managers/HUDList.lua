local function format_time_string(value)
    local frmt_string

    if value >= 60 then
        frmt_string = string.format("%d:%02d", math.floor(value / 60), math.ceil(value % 60))
    elseif value >= 9.9 then
        frmt_string = string.format("%d", math.ceil(value))
    elseif value >= 0 then
        frmt_string = string.format("%.1f", value)
    else
        frmt_string = string.format("%.1f", 0)
    end

    return frmt_string
end

local function log_error(fmt, ...)
	log(string.format("[ERROR] (HUDList.lua): " .. fmt, ...))
end

local function log_warning(fmt, ...)
	log(string.format("[WARNING] (HUDList.lua): " .. fmt, ...))
end

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

HUDListManager.ListOptions = HUDListManager.ListOptions or {
	--General settings
	right_list_y = SydneyHUD:GetOption("center_assault_banner") and 0 or 50, --Margin from top for the right list
	right_list_scale = SydneyHUD:GetModOption("hudlist", "right_list_scale"), --Size scale of right list
	left_list_y = 40, --Margin from top for the left list
	left_list_scale = SydneyHUD:GetModOption("hudlist", "left_list_scale"), --Size scale of left list
	buff_list_y = SydneyHUD:GetModOption("hudlist", "buff_list_y"), --Margin from bottom for the buff list
	buff_list_scale = SydneyHUD:GetModOption("hudlist", "buff_list_scale"), --Size scale of buff list

	--Left side list
	show_timers = SydneyHUD:GetModOption("hudlist", "show_timers"),	--Drills, time locks, hacking etc.
	show_ammo_bags = SydneyHUD:GetModOption("hudlist", "show_ammo_bags") - 1, --Show ammo bags/shelves and remaining amount
	show_doc_bags = SydneyHUD:GetModOption("hudlist", "show_doc_bags") - 1, --Show doc bags/cabinets and remaining charges
	show_body_bags = SydneyHUD:GetModOption("hudlist", "show_body_bags") - 1, --Show body bags and remaining amount. Auto-disabled if heist goes loud
	show_grenade_crates = SydneyHUD:GetModOption("hudlist", "show_grenade_crates") - 1,	--Show grenade crates with remaining amount
	show_sentries = SydneyHUD:GetModOption("hudlist", "show_sentries") - 1, --Deployable sentries, color-coded by owner
	show_ecms = SydneyHUD:GetModOption("hudlist", "show_ecms"), --Active ECMs with time remaining
	show_ecm_retrigger = SydneyHUD:GetModOption("hudlist", "show_ecm_retrigger"), --Countdown for player owned ECM feedback retrigger delay
	show_minions = SydneyHUD:GetModOption("hudlist", "show_minions") - 1, --Converted enemies, type and health
	show_pagers = SydneyHUD:GetModOption("hudlist", "show_pagers"), --Show currently active pagers
	show_tape_loop = SydneyHUD:GetModOption("hudlist", "show_tape_loop"), --Show active tape loop duration

	--Right side list
	show_enemies = SydneyHUD:GetModOption("hudlist", "show_enemies") - 1, --Currently spawned enemies
	show_turrets = SydneyHUD:GetModOption("hudlist", "show_turrets"), --Show active SWAT turrets
	show_civilians = SydneyHUD:GetModOption("hudlist", "show_civilians"), --Currently spawned, untied civs
	show_hostages = SydneyHUD:GetModOption("hudlist", "show_hostages") - 1, --Currently tied civilian and dominated cops
	show_minion_count = SydneyHUD:GetModOption("hudlist", "show_minion_count"), --Current number of jokered enemies
	show_pager_count = SydneyHUD:GetModOption("hudlist", "show_pager_count"), --Show number of triggered pagers (only counts pagers triggered while you were present). Auto-disabled if heist goes loud
	show_camera_count = SydneyHUD:GetModOption("hudlist", "show_camera_count"), --Show number of active cameras on the map. Auto-disabled if heist goes loud (experimental, has some issues)
	show_body_count = SydneyHUD:GetModOption("hudlist", "show_body_count"),	 --Show number of corpses/body bags on map. Auto-disabled if heist goes loud
	show_loot = SydneyHUD:GetModOption("hudlist", "show_loot") - 1,	--Show spawned and active loot bags/piles (may not be shown if certain mission parameters has not been met)
	separate_bagged_loot = SydneyHUD:GetModOption("hudlist", "separate_bagged_loot"),	 --Show bagged/unbagged loot as separate values
	show_special_pickups = SydneyHUD:GetModOption("hudlist", "show_special_pickups"),	--Show number of special equipment/items
    ignore_special_pickups = { --Exclude specific special pickups from showing
        crowbar = SydneyHUD:GetHUDListItemOption("crowbar"),
        keycard = SydneyHUD:GetHUDListItemOption("keycard"),
        courier = SydneyHUD:GetHUDListItemOption("courier"),
        planks = SydneyHUD:GetHUDListItemOption("planks"),
        meth_ingredients = SydneyHUD:GetHUDListItemOption("meth_ingredients"),
        secret_item = SydneyHUD:GetHUDListItemOption("secret_item"),	--Biker heist bottle / BoS rings
    },
	
	--Buff list
	show_buffs = SydneyHUD:GetModOption("hudlist", "show_buffs"),	--Show active effects (buffs/debuffs)
    ignore_buffs = {	--Exclude specific effects from showing
        aggressive_reload_aced = SydneyHUD:GetHUDListBuffOption("aggressive_reload"),
        ammo_efficiency = SydneyHUD:GetHUDListBuffOption("ammo_efficiency"),
        armor_break_invulnerable = SydneyHUD:GetHUDListBuffOption("armor_break_invulnerability"),
        berserker = SydneyHUD:GetHUDListBuffOption("berserker"),
        biker = SydneyHUD:GetHUDListBuffOption("prospect"),
        bloodthirst_aced = SydneyHUD:GetHUDListBuffOption("bloodthirst_aced"),
        bloodthirst_basic = SydneyHUD:GetHUDListBuffOption("bloodthirst_basic"),	--true,
        bullet_storm = SydneyHUD:GetHUDListBuffOption("bullet_storm"),
        chico_injector = SydneyHUD:GetHUDListBuffOption("injector"),
        close_contact = SydneyHUD:GetHUDListBuffOption("close_contact_no_talk"),
        combat_medic = SydneyHUD:GetHUDListBuffOption("combat_medic"),	--true,
        desperado = SydneyHUD:GetHUDListBuffOption("desperado"),
        die_hard = SydneyHUD:GetHUDListBuffOption("die_hard"),
        dire_need = SydneyHUD:GetHUDListBuffOption("dire_need"),
        grinder = SydneyHUD:GetHUDListBuffOption("histamine"),
        hostage_situation = SydneyHUD:GetHUDListBuffOption("hostage_situation"),	--true,
        hostage_taker = SydneyHUD:GetHUDListBuffOption("hostage_taker"),
        inspire = SydneyHUD:GetHUDListBuffOption("inspire"),
        lock_n_load = SydneyHUD:GetHUDListBuffOption("lock_n_load"),
        maniac = SydneyHUD:GetHUDListBuffOption("excitement"),	--true,
        melee_stack_damage = SydneyHUD:GetHUDListBuffOption("overdog_melee_damage"),
        messiah = SydneyHUD:GetHUDListBuffOption("messiah"),
        muscle_regen = SydneyHUD:GetHUDListBuffOption("800_pound_gorilla"),
        overdog = SydneyHUD:GetHUDListBuffOption("overdog_damage_reduction"),
        overkill = SydneyHUD:GetHUDListBuffOption("overkill"),
        pain_killer = SydneyHUD:GetHUDListBuffOption("painkillers"),	--true,
        partner_in_crime = SydneyHUD:GetHUDListBuffOption("partner_in_crime"),
        quick_fix = SydneyHUD:GetHUDListItemOption("quick_fix"),	--true,
        running_from_death = SydneyHUD:GetHUDListBuffOption("running_from_death_basic"),
        running_from_death_aced = SydneyHUD:GetHUDListBuffOption("running_from_death_aced"),
        second_wind = SydneyHUD:GetHUDListBuffOption("second_wind"),
        sicario_dodge = SydneyHUD:GetHUDListBuffOption("twitch"),
        sixth_sense = SydneyHUD:GetHUDListBuffOption("sixth_sense"),
        smoke_screen = SydneyHUD:GetHUDListBuffOption("smoke_screen"),
        swan_song = SydneyHUD:GetHUDListBuffOption("swan_song"),
        tooth_and_claw = SydneyHUD:GetHUDListBuffOption("tooth_and_claw"),	--Also integrated into armor regen
        trigger_happy = SydneyHUD:GetHUDListBuffOption("trigger_happy"),
        underdog = SydneyHUD:GetHUDListBuffOption("underdog"),
        unseen_strike = SydneyHUD:GetHUDListBuffOption("unseen_strike"),
        uppers = SydneyHUD:GetHUDListBuffOption("uppers"),
        up_you_go = SydneyHUD:GetHUDListBuffOption("up_you_go"),	--true,
        yakuza = SydneyHUD:GetHUDListBuffOption("yakuza"),
        
        ammo_give_out_debuff = SydneyHUD:GetHUDListBuffOption("ammo_give_out_cooldown"),
        anarchist_armor_recovery_debuff = SydneyHUD:GetHUDListBuffOption("lust_for_life_cooldown"),
        armor_break_invulnerable_debuff = SydneyHUD:GetHUDListBuffOption("armor_break_invulnerability_cooldown"),	--Composite
        bullseye_debuff = SydneyHUD:GetHUDListBuffOption("bullseye_cooldown"),
        chico_injector_debuff = SydneyHUD:GetHUDListBuffOption("injector_cooldown"),	--Composite
        grinder_debuff = SydneyHUD:GetHUDListBuffOption("histamine_cooldown"),	--Composite
        inspire_debuff = SydneyHUD:GetHUDListBuffOption("inspire_boost_cooldown"),
        inspire_revive_debuff = SydneyHUD:GetHUDListBuffOption("inspire_revive_cooldown"),
        life_drain_debuff = SydneyHUD:GetHUDListBuffOption("life_drain_cooldown"),
        medical_supplies_debuff = SydneyHUD:GetHUDListBuffOption("medical_supplies_cooldown"),
        self_healer_debuff = SydneyHUD:GetHUDListBuffOption("self_healer_cooldown"),
        sicario_dodge_debuff = SydneyHUD:GetHUDListBuffOption("twitch_cooldown"),	--Composite
        smoke_grenade = SydneyHUD:GetHUDListBuffOption("smoke_grenade"),
        sociopath_debuff = SydneyHUD:GetHUDListBuffOption("sociopath_cooldown"),
        some_invulnerability_debuff = SydneyHUD:GetHUDListBuffOption("some_invulnerability_cooldown"),
        unseen_strike_debuff = SydneyHUD:GetHUDListBuffOption("unseen_strike_cooldown"),	--Composite
        uppers_debuff = SydneyHUD:GetHUDListBuffOption("uppers_cooldown"),	--Composite
        
        armorer = SydneyHUD:GetHUDListBuffOption("liquid_armor"),
        crew_chief = SydneyHUD:GetHUDListBuffOption("crew_chief_level"),
        forced_friendship = SydneyHUD:GetHUDListBuffOption("forced_friendship"),
        shock_and_awe = SydneyHUD:GetHUDListBuffOption("shock_and_awe"),
    
        damage_increase = SydneyHUD:GetHUDListBuffOption("damage_bonus"),
        damage_reduction = SydneyHUD:GetHUDListBuffOption("received_damage_reduction"),
        melee_damage_increase = SydneyHUD:GetHUDListBuffOption("melee_damage_increase"),
        passive_health_regen = SydneyHUD:GetHUDListBuffOption("health_regeneration"),
        
        --Custom buffs
        crew_inspire = SydneyHUD:GetHUDListBuffOption("ai_inspire_cooldown")
    },
	show_player_actions = SydneyHUD:GetModOption("hudlist", "show_player_actions"),	--Show active player actions (armor regen, interactions, weapon charge, reload etc.)
    ignore_player_actions = {	--Exclude specific effects from showing
        anarchist_armor_regeneration = SydneyHUD:GetHUDListPlayerActionOption("anarchist_armor_regeneration"),
        standard_armor_regeneration = SydneyHUD:GetHUDListPlayerActionOption("standard_armor_regeneration"),
        melee_charge = SydneyHUD:GetHUDListPlayerActionOption("melee_charge"),
        weapon_charge = SydneyHUD:GetHUDListPlayerActionOption("weapon_charge"),
        reload = SydneyHUD:GetHUDListPlayerActionOption("reload"),
        interact = SydneyHUD:GetHUDListPlayerActionOption("interact"),
    }
}

HUDListManager.TIMER_SETTINGS = {
	[132864] = {	--Meltdown vault temperature
		class = "TemperatureGaugeItem",
		params = { start = 0, goal = 50, priority = -1 },
	},
	[135076] = { ignore = true },	--Lab rats cloaker safe 2
	[135246] = { ignore = true },	--Lab rats cloaker safe 3
	[135247] = { ignore = true },	--Lab rats cloaker safe 4
	[100007] = { ignore = true },	--Cursed kill room timer
	[100888] = { ignore = true },	--Cursed kill room timer
	[100889] = { ignore = true },	--Cursed kill room timer
	[100891] = { ignore = true },	--Cursed kill room timer
	[100892] = { ignore = true },	--Cursed kill room timer
	[100878] = { ignore = true },	--Cursed kill room timer
	[100176] = { ignore = true },	--Cursed kill room timer
	[100177] = { ignore = true },	--Cursed kill room timer
	[100029] = { ignore = true },	--Cursed kill room timer
	[141821] = { ignore = true },	--Cursed kill room safe 1 timer
	[141822] = { ignore = true },	--Cursed kill room safe 1 timer
	[140321] = { ignore = true },	--Cursed kill room safe 2 timer
	[140322] = { ignore = true },	--Cursed kill room safe 2 timer
	[139821] = { ignore = true },	--Cursed kill room safe 3 timer
	[139822] = { ignore = true },	--Cursed kill room safe 3 timer
	[141321] = { ignore = true },	--Cursed kill room safe 4 timer
	[141322] = { ignore = true },	--Cursed kill room safe 4 timer
	[140821] = { ignore = true },	--Cursed kill room safe 5 timer
	[140822] = { ignore = true },	--Cursed kill room safe 5 timer
}

HUDListManager.UNIT_TYPES = {
	cop = 						{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_scared = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_female = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	fbi = 						{ type_id = "cop",			category = "enemies",	long_name = "FBI" },
	swat = 						{ type_id = "cop",			category = "enemies",	long_name = "SWAT" },
	heavy_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "H. SWAT" },
	fbi_swat = 					{ type_id = "cop",			category = "enemies",	long_name = "FBI SWAT" },
	fbi_heavy_swat = 			{ type_id = "cop",			category = "enemies",	long_name = "H. FBI SWAT" },
	city_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "Elite" },
	heavy_swat_sniper =		{ type_id = "cop",			category = "enemies",	long_name = "H. Sniper" },
    bolivian_indoors =		{ type_id = "security",		category = "enemies",	long_name = "Sosa Security" },
    bolivian_indoors_mex =  { type_id = "security",         category = "enemies",   long_name = "Bolivian Guard" },
	security = 					{ type_id = "security",		category = "enemies",	long_name = "Sec. Guard" },
    security_undominatable ={ type_id = "security",		category = "enemies",	long_name = "Sec. Guard" },
    security_mex = { type_id = "security", category = "enemies", long_name = "Sp. Sec. G." },
	gensec = 					{ type_id = "security",		category = "enemies",	long_name = "GenSec" },
	bolivian =					{ type_id = "thug",			category = "enemies",	long_name = "Sosa Thug" },
	gangster = 					{ type_id = "thug",			category = "enemies",	long_name = "Gangster" },
	mobster = 					{ type_id = "thug",			category = "enemies",	long_name = "Mobster" },
	biker = 						{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	biker_escape = 			{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	tank = 						{ type_id = "tank",			category = "enemies",	long_name = "Bulldozer" },
	tank_hw = 					{ type_id = "tank",			category = "enemies",	long_name = "Headless dozer" },
	tank_medic =				{ type_id = "tank_med",		category = "enemies",	long_name = "Medic dozer" },
	tank_mini =					{ type_id = "tank_min",		category = "enemies",	long_name = "Minigun dozer" },
	spooc = 						{ type_id = "spooc",			category = "enemies",	long_name = "Cloaker" },
	taser = 						{ type_id = "taser",			category = "enemies",	long_name = "Taser" },
	shield = 					{ type_id = "shield",		category = "enemies",	long_name = "Shield" },
	sniper = 					{ type_id = "sniper",		category = "enemies",	long_name = "Sniper" },
	medic = 						{ type_id = "medic",			category = "enemies",	long_name = "Medic" },
	biker_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Biker Boss" },
	chavez_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Chavez" },
	drug_lord_boss =			{ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	drug_lord_boss_stealth ={ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	mobster_boss = 			{ type_id = "thug_boss",	category = "enemies",	long_name = "Commissar" },
	hector_boss = 				{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	hector_boss_no_armor = 	{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	phalanx_vip = 				{ type_id = "phalanx",		category = "enemies",	long_name = "Cpt. Winter" },
	phalanx_minion = 			{ type_id = "phalanx",		category = "enemies",	long_name = "Phalanx" },
	civilian = 					{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
    civilian_female = 		{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
    civilian_mariachi = { type_id = "civ", category = "civilians", long_name = "Mariachi Civ." },
	bank_manager = 			{ type_id = "civ",			category = "civilians",	long_name = "Bank mngr." },
	--captain = 					{ type_id = "unique",		category = "civilians",	long_name = "Captain" },	--Alaska
	--drunk_pilot = 				{ type_id = "unique",		category = "civilians",	long_name = "Pilot" },	--White X-mas
	--escort = 					{ type_id = "unique",		category = "civilians",	long_name = "Escort" },	--?
	--escort_cfo = 				{ type_id = "unique",		category = "civilians",	long_name = "CFO" },	--Diamond Heist CFO
	--escort_chinese_prisoner = 	{ type_id = "unique",		category = "civilians",	long_name = "Prisoner" },	--Green Bridge
	--escort_undercover = 		{ type_id = "unique",		category = "civilians",	long_name = "Taxman" },	--Undercover
	--old_hoxton_mission = 	{ type_id = "unique",		category = "civilians",	long_name = "Hoxton" },	--Hox Breakout/BtM (Locke)
	--inside_man = 				{ type_id = "unique",		category = "civilians",	long_name = "Insider" },	--FWB
	--boris = 						{ type_id = "unique",		category = "civilians",	long_name = "Boris" },	--Goat sim
	--spa_vip = 					{ type_id = "unique",			category = "civilians",	long_name = "Charon" },	--10-10
	--spa_vip_hurt = 			{ type_id = "unique",			category = "civilians",	long_name = "Charon" },	--10-10
	
	--Custom unit definitions
	turret = 					{ type_id = "turret",		category = "turrets",	long_name = "SWAT Turret" },
	minion =						{ type_id = "minion",		category = "minions",	long_name = "Joker" },
	cop_hostage =				{ type_id = "cop_hostage",	category = "hostages",	long_name = "Dominated" },
	civ_hostage =				{ type_id = "civ_hostage",	category = "hostages",	long_name = "Hostage" },
}

HUDListManager.SPECIAL_PICKUP_TYPES = {
	gen_pku_crowbar =					"crowbar",
	pickup_keycard =					"keycard",
	pickup_hotel_room_keycard =	"keycard",	--GGC keycard
	gage_assignment =					"courier",
	pickup_boards =					"planks",
	stash_planks_pickup =			"planks",
	muriatic_acid =					"meth_ingredients",
	hydrogen_chloride =				"meth_ingredients",
	caustic_soda =						"meth_ingredients",
	press_pick_up =					"secret_item",		--Biker heist bottle
	ring_band = 						"secret_item",		--BoS rings
}

HUDListManager.LOOT_TYPES = {
	ammo =						"shell",
	artifact_statue =			"artifact",
	circuit =					"server",
	cloaker_cocaine =			"coke",
	cloaker_gold =				"gold",
	cloaker_money =			"money",
	coke =						"coke",
	coke_pure =					"coke",
	counterfeit_money =		"money",
	cro_loot1 =					"bomb",
	cro_loot2 =					"bomb",
	diamond_necklace =		"jewelry",
	diamonds =					"jewelry",
	diamonds_dah =				"jewelry",
	din_pig =					"pig",
	drk_bomb_part =			"bomb",
	drone_control_helmet =	"drone_ctrl",
	evidence_bag =				"evidence",
	expensive_vine =			"wine",
	goat = 						"goat",
	gold =						"gold",
	hope_diamond =				"diamond",
	lost_artifact = 			"artifact",
	mad_master_server_value_1 =	"server",
	mad_master_server_value_2 =	"server",
	mad_master_server_value_3 =	"server",
	mad_master_server_value_4 =	"server",
	master_server = 			"server",
	masterpiece_painting =	"painting",
	meth =						"meth",
	meth_half =					"meth",
	money =						"money",
	mus_artifact =				"artifact",
	mus_artifact_paint =		"painting",
	old_wine =					"wine",
	ordinary_wine =			"wine",
	painting =					"painting",
	person =						"body",
	present = 					"present",
	prototype = 				"prototype",
	red_diamond =				"diamond",
	robot_toy =					"toy",
	safe_ovk =					"safe",
	safe_wpn =					"safe",
	samurai_suit =				"armor",
	sandwich =					"toast",
	special_person =			"body",
	toothbrush =				"toothbrush",
	turret =						"turret",
	unknown =					"dentist",
	vr_headset =				"headset",
	warhead =					"warhead",
	weapon =						"weapon",
	weapon_glock =				"weapon",
	weapon_scar =				"weapon",
	women_shoes =				"shoes",
    yayo =						"coke",
    faberge_egg = "faberge_egg",
    treasure = "romanov_treasure"
}

HUDListManager.POTENTIAL_LOOT_TYPES = {
    crate = 					"crate",
    xmas_present = 				"xmas_present",
    shopping_bag = 				"shopping_bag",
    showcase = 					"showcase",
}

HUDListManager.LOOT_CONDITIONS = {
	body = function(data) 
		return (managers.job:current_level_id() == "mad") and (data.bagged or data.unit:editor_id() ~= -1)
	end,
}

HUDListManager.BUFFS = {
	aggressive_reload_aced =				{ "aggressive_reload_aced" },
	ammo_efficiency =							{ "ammo_efficiency" },
	ammo_give_out_debuff =					{ "ammo_give_out_debuff", is_debuff = true },
	anarchist_armor_recovery_debuff =	{ "anarchist_armor_recovery_debuff", is_debuff = true },
	armor_break_invulnerable =				{ "armor_break_invulnerable" },
	armor_break_invulnerable_debuff =	{ "armor_break_invulnerable", "armor_break_invulnerable_debuff", is_debuff = true },
	armorer_armor_regen_multiplier =		{ "armorer" },
	berserker =									{ "berserker", "damage_increase", "melee_damage_increase" },
	berserker_aced =							{ "berserker", "damage_increase" },
	biker =										{ "biker" },
	bloodthirst_aced =						{ "bloodthirst_aced" },
	bloodthirst_basic =						{ "bloodthirst_basic", "melee_damage_increase" },
	bullet_storm =								{ "bullet_storm" },
	bullseye_debuff =							{ "bullseye_debuff", is_debuff = true },
	calm =										{ "calm" },
	cc_hostage_damage_reduction =			{ "crew_chief" },	--Damage reduction covered by hostage_situation
	cc_hostage_health_multiplier =		{ "crew_chief" },
	cc_hostage_stamina_multiplier =		{ "crew_chief" },
	cc_passive_armor_multiplier =			{ "crew_chief" },
	cc_passive_damage_reduction =			{ "crew_chief", "damage_reduction" },
	cc_passive_health_multiplier =		{ "crew_chief" },
	cc_passive_stamina_multiplier =		{ "crew_chief" },
	chico_injector =							{ "chico_injector" },
	chico_injector_use =						{ "chico_injector", "chico_injector_debuff", is_debuff = true },
	close_contact =							{ "close_contact", "damage_reduction" },
	combat_medic_interaction =				{ "combat_medic", "damage_reduction" },
	combat_medic_success =					{ "combat_medic", "damage_reduction" },
	damage_control_use =						{ "stoic_flask", is_debuff = true },
	desperado =									{ "desperado" },
	die_hard =									{ "die_hard", "damage_reduction" },
	dire_need =									{ "dire_need" },
	forced_friendship =						{ "forced_friendship" },
	grinder =									{ "grinder" },
	grinder_debuff = 							{ "grinder", "grinder_debuff", is_debuff = true },
	hostage_situation =						{ "hostage_situation", "damage_reduction" },
	hostage_taker =							{ "hostage_taker", "passive_health_regen" },
	inspire =									{ "inspire" },
	inspire_debuff =							{ "inspire_debuff", is_debuff = true },
	inspire_revive_debuff =					{ "inspire_revive_debuff", is_debuff = true },
	life_drain_debuff =						{ "life_drain_debuff", is_debuff = true },
	lock_n_load =								{ "lock_n_load" },
	maniac =										{ "maniac" },
	medical_supplies_debuff =				{ "medical_supplies_debuff", is_debuff = true },
	melee_stack_damage =						{ "melee_stack_damage", "melee_damage_increase" },
	messiah =									{ "messiah" },
	muscle_regen =								{ "muscle_regen", "passive_health_regen" },
	overdog =									{ "overdog", "damage_reduction" },
	overkill =									{ "overkill", "damage_increase" },
	overkill_aced =							{ "overkill", "damage_increase" },
	pain_killer =								{ "pain_killer", "damage_reduction" },
	partner_in_crime =						{ "partner_in_crime" },
	partner_in_crime_aced =					{ "partner_in_crime" },
	pocket_ecm_jammer_use =					{ "pocket_ecm_jammer_debuff", is_debuff = true },
	pocket_ecm_kill_dodge =					{ "pocket_ecm_kill_dodge" },
	quick_fix =									{ "quick_fix", "damage_reduction" },
	running_from_death_move_speed =		{ "running_from_death_aced" },
	running_from_death_reload_speed =	{ "running_from_death_basic" },
	running_from_death_swap_speed =		{ "running_from_death_basic" },
	second_wind =								{ "second_wind" },
	self_healer_debuff =						{ "self_healer_debuff", is_debuff = true },
	shock_and_awe =							{ "shock_and_awe" },
	sicario_dodge =							{ "sicario_dodge" },
	sicario_dodge_debuff =					{ "sicario_dodge", "sicario_dodge_debuff", is_debuff = true },
	sixth_sense =								{ "sixth_sense" },
	smoke_screen =								{ "smoke_screen" },
	smoke_screen_grenade_use =				{ "smoke_grenade", is_debuff = true },
	sociopath_debuff =						{ "sociopath_debuff", is_debuff = true },
	some_invulnerability_debuff =			{ "some_invulnerability_debuff", is_debuff = true },
	swan_song =									{ "swan_song" },
	swan_song_aced =							{ "swan_song" },
	tooth_and_claw =							{ "tooth_and_claw" },
	trigger_happy =							{ "trigger_happy", "damage_increase" },
	underdog =									{ "underdog", "damage_increase" },
	underdog_aced =							{ "underdog", "damage_reduction" },
	unseen_strike =							{ "unseen_strike" },
	unseen_strike_debuff =					{ "unseen_strike", "unseen_strike_debuff", is_debuff = true },
	up_you_go =									{ "up_you_go", "damage_reduction" },
	uppers =										{ "uppers" },
	uppers_debuff =							{ "uppers", "uppers_debuff", is_debuff = true },
	virtue_debuff =							{ "virtue_debuff", is_debuff = true },
	yakuza_recovery =							{ "yakuza" },
    yakuza_speed =								{ "yakuza" },
    
    --Custom buffs
    crew_inspire = { "crew_inspire", is_debuff = true }
}

HUDListManager.FORCE_AGGREGATE_EQUIPMENT = {
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
	born = {		--Biker heist
		[100776] = "bunker_grenade",
		[101226] = "bunker_grenade",
		[101469] = "bunker_grenade",
		[101472] = "bunker_ammo",
		[101473] = "bunker_ammo",
	},
	spa = {	--10-10
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
}

HUDListManager.EQUIPMENT_TABLE = {
	sentry =				{ skills = { 7, 5 },			class = "SentryEquipmentItem",	priority = 1 },
	grenade_crate =	{ preplanning = { 1, 0 },	class = "BagEquipmentItem",		priority = 2 },
	ammo_bag =			{ skills = { 1, 0 },			class = "AmmoBagItem",				priority = 3 },
	doc_bag =			{ skills = { 2, 7 },			class = "BagEquipmentItem",		priority = 4 },
	body_bag =			{ skills = { 5, 11 },		class = "BodyBagItem",				priority = 5 },
}

local function debug_print(...)
	local msg = "[HUDList]: " .. string.format(...)
	log(msg)
end

function HUDListManager:change_setting(setting, value)
    local clbk = "_set_" .. setting
    if HUDListManager[clbk] and HUDListManager.ListOptions[setting] ~= value then
        HUDListManager.ListOptions[setting] = value
        self[clbk](self, value)
        return true
    end
    return false
end

function HUDListManager:lists()
    return self._lists
end

function HUDListManager:list(id)
    return self._lists[id]
end

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
        list:update(t, dt)
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

function HUDListManager:register_list(name, class, params, ...)
    if not self._lists[name] then
        class = type(class) == "string" and _G.HUDList[class] or class
        self._lists[name] = class and class:new(nil, name, params, ...)
    end

    return self._lists[name]
end

function HUDListManager:unregister_list(name, instant)
    if self._lists[name] then
        self._lists[name]:delete(instant)
    end
    self._lists[name] = nil
end

function HUDListManager:setup()
	self:_setup_left_list()
	self:_setup_right_list()
	self:_setup_buff_list()
end

function HUDListManager:_setup_left_list()
	local scale = HUDListManager.ListOptions.left_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = self._hud_panel:h()
	local x = 0
	
	local list = self:add_list("left_list", HUDList.VerticalList, { 
		valign = "top", 
		halign = "left", 
		x = x, 
		w = list_w, 
		h = list_h, 
		item_margin = 5
	})
	self:_set_left_list_y()
	
	local function list_config_template(size, prio, ...)
		return {
			halign = "left", 
			valign = "center", 
			w = list_w, 
			h = size--[[ * scale]], 
			priority = prio,
			item_margin = 3, 
			static_item = {
				class = HUDList.StaticItem, 
				data = { 30--[[ * scale]], ... },
			}
		}
	end

	if GameInfoManager.plugin_active("deployables") then
		list:add_item("equipment", HUDList.RescalableHorizontalList, list_config_template(40, 8, 
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.ammo_bag.skills, valign = "top", halign = "right" },
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.doc_bag.skills, valign = "top", halign = "left" },
			{ h_scale = 0.55, w_scale = 0.55, preplanning = HUDListManager.EQUIPMENT_TABLE.grenade_crate.preplanning, valign = "bottom", halign = "right" },
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.body_bag.skills, valign = "bottom", halign = "left" })):rescale(scale)
		self:_set_show_ammo_bags()
		self:_set_show_doc_bags()
		self:_set_show_body_bags()
		self:_set_show_grenade_crates()
	end
	
	if GameInfoManager.plugin_active("sentries") then
		list:add_item("sentries", HUDList.RescalableHorizontalList, list_config_template(40, 7, { skills = HUDListManager.EQUIPMENT_TABLE.sentry.skills })):rescale(scale)
		self:_set_show_sentries()
	end
	
	if GameInfoManager.plugin_active("timers") then
		list:add_item("timers", HUDList.TimerList, list_config_template(60, 6, { skills = { 3, 6 } })):rescale(scale)
		self:_set_show_timers()
	end
	
	if GameInfoManager.plugin_active("units") then
		list:add_item("minions", HUDList.RescalableHorizontalList, list_config_template(45, 5, { skills = { 6, 8 } })):rescale(scale)
		self:_set_show_minions()
	end
	
	if GameInfoManager.plugin_active("ecms") then
		list:add_item("ecm_retrigger", HUDList.RescalableHorizontalList, list_config_template(40, 4, { skills = { 6, 2 } })):rescale(scale)
		list:add_item("ecms", HUDList.RescalableHorizontalList, list_config_template(40, 3, { skills = { 1, 4 } })):rescale(scale)
		self:_set_show_ecms()
		self:_set_show_ecm_retrigger()
	end
	
	if GameInfoManager.plugin_active("cameras") then
		list:add_item("tape_loop", HUDList.RescalableHorizontalList, list_config_template(40, 2, { skills = { 4, 2 } })):rescale(scale)
		self:_set_show_tape_loop()
	end
	
	if GameInfoManager.plugin_active("pagers") then
		list:add_item("pagers", HUDList.RescalableHorizontalList, list_config_template(40, 1, { perks = { 1, 4 } })):rescale(scale)
		self:_set_show_pagers()
	end
end

function HUDListManager:_setup_right_list()
	local scale = HUDListManager.ListOptions.right_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = self._hud_panel:h()
	local x = 0

	local list = self:add_list("right_list", HUDList.VerticalList, { 
		valign = "top", 
		halign = "right", 
		x = x, 
		w = list_w, 
		h = list_h, 
		item_margin = 5,
	})
	self:_set_right_list_y()
	
	local function list_config_template(prio)
		return {
			halign = "right", 
			valign = "center", 
			w = list_w, 
			h = 50--[[ * scale]], 
			item_margin = 3, 
			priority = prio,
		}
	end
	
	if GameInfoManager.plugin_active("units") then
		list:add_item("unit_count_list", HUDList.RescalableHorizontalList, list_config_template(4)):rescale(scale)
		self:_set_show_enemies()
		self:_set_show_turrets()
		self:_set_show_civilians()
		self:_set_show_hostages()
		self:_set_show_minion_count()
	end
	
	if GameInfoManager.plugin_active("loot") then
		list:add_item("loot_list", HUDList.RescalableHorizontalList, list_config_template(3)):rescale(scale)
		self:_set_show_loot()
	end
	
	if GameInfoManager.plugin_active("pickups") then
		list:add_item("special_pickup_list", HUDList.RescalableHorizontalList, list_config_template(2)):rescale(scale)
		self:_set_show_special_pickups()
	end
	
	if GameInfoManager.plugin_active("loot") or GameInfoManager.plugin_active("pagers") or GameInfoManager.plugin_active("cameras") then
		list:add_item("stealth_list", HUDList.StealthList, list_config_template(1)):rescale(scale)
		
		if GameInfoManager.plugin_active("loot") then
			self:_set_show_body_count()
		end
		if GameInfoManager.plugin_active("pagers") then
			self:_set_show_pager_count()
		end
		if GameInfoManager.plugin_active("cameras") then
			self:_set_show_camera_count()
		end
	end
end

function HUDListManager:_setup_buff_list()
	local scale = HUDListManager.ListOptions.buff_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = 70 * scale
	local x = 0
	
	self:add_list("buff_list", HUDList.HorizontalList, { 
		halign = "center", 
		valign = "center",
		x = x,
		w = list_w, 
		h = list_h, 
		item_margin = 0,
	})
	self:_set_buff_list_y()

	if GameInfoManager.plugin_active("buffs") then
		self:_set_show_buffs()
	end
	if GameInfoManager.plugin_active("player_actions") then
		self:_set_show_player_actions()
	end
end


--General config
function HUDListManager:_set_left_list_y()
	local list_panel = self:list("left_list"):panel()
	local y = HUDListManager.ListOptions.left_list_y or 40
	list_panel:set_y(y)
end

function HUDListManager:_set_right_list_y()
	local list_panel = self:list("right_list"):panel()
	local y = HUDListManager.ListOptions.right_list_y or 0
	list_panel:set_y(y)
end

function HUDListManager:_set_buff_list_y()
	local list_panel = self:list("buff_list"):panel()
	local list_h = list_panel:h()
	local y = self._hud_panel:bottom() - ((HUDListManager.ListOptions.buff_list_y or 80) + list_h)

	if HUDManager.CUSTOM_TEAMMATE_PANEL then
		local teammate_panel = managers.hud._teammate_panels_custom or managers.hud._teammate_panels 
		y = teammate_panel[HUDManager.PLAYER_PANEL]:panel():top() - (list_h + 5)
	end
	
	list_panel:set_y(y)
end

function HUDListManager:_set_left_list_scale()
	for lid, list in pairs(self:list("left_list"):items()) do
		list:rescale(HUDListManager.ListOptions.left_list_scale or 1)
	end
	self:list("left_list"):rearrange()
end

function HUDListManager:_set_right_list_scale()
	for lid, list in pairs(self:list("right_list"):items()) do
		list:rescale(HUDListManager.ListOptions.right_list_scale or 1)
	end
	self:list("right_list"):rearrange()
end

function HUDListManager:_set_buff_list_scale()
	
end

--Left list config
function HUDListManager:_set_show_timers()
	local list = self:list("left_list"):item("timers")
	local listener_id = "HUDListManager_timer_listener"
	local events = { "set_active" }
	local clbk = callback(self, self, "_timer_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_timers then
			managers.gameinfo:register_listener(listener_id, "timer", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "timer", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_timers()) do
		if HUDListManager.ListOptions.show_timers then
			clbk("set_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ammo_bags()
	self:_show_bag_deployable_by_type("ammo_bag", HUDListManager.ListOptions.show_ammo_bags)
end

function HUDListManager:_set_show_doc_bags()
	self:_show_bag_deployable_by_type("doc_bag", HUDListManager.ListOptions.show_doc_bags)
end

function HUDListManager:_set_show_body_bags()
	self:_show_bag_deployable_by_type("body_bag", HUDListManager.ListOptions.show_body_bags)
end

function HUDListManager:_set_show_grenade_crates()
	self:_show_bag_deployable_by_type("grenade_crate", HUDListManager.ListOptions.show_grenade_crates)
end

function HUDListManager:_set_show_sentries()
	local list = self:list("left_list"):item("sentries")
	local listener_id = "HUDListManager_sentry_listener"
	local events = { "set_active" }
	local clbk = callback(self, self, "_sentry_equipment_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_sentries > 0 then
			managers.gameinfo:register_listener(listener_id, "sentry", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "sentry", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_deployables("sentry")) do
		if HUDListManager.ListOptions.show_sentries > 0 then
			clbk("set_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_minions()
	local listener_id = "HUDListManager_minion_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_minion_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_minions > 0 then
			managers.gameinfo:register_listener(listener_id, "minion", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "minion", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_minions()) do
		clbk(HUDListManager.ListOptions.show_minions > 0 and "add" or "remove", key, data)
	end
end

function HUDListManager:_set_show_pagers()
	local list = self:list("left_list"):item("pagers")
	local listener_id = "HUDListManager_pager_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_pager_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_pagers then
			managers.gameinfo:register_listener(listener_id, "pager", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "pager", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_pagers()) do
		if HUDListManager.ListOptions.show_pagers then
			if data.active then
				clbk("add", key, data)
			end
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ecms()
	local list = self:list("left_list"):item("ecms")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_jammer_active" } 
	local clbk = callback(self, self, "_ecm_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecms then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecms then
			clbk("set_jammer_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ecm_retrigger()
	local list = self:list("left_list"):item("ecm_retrigger")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_retrigger_active" } 
	local clbk = callback(self, self, "_ecm_retrigger_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			clbk("set_retrigger_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_tape_loop()
	local list = self:list("left_list"):item("tape_loop")
	local listener_id = "HUDListManager_tape_loop_listener"
	local events = { "start_tape_loop", "stop_tape_loop" }
	local clbk = callback(self, self, "_tape_loop_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_tape_loop then
			managers.gameinfo:register_listener(listener_id, "camera", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "camera", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_cameras()) do
		if data.tape_loop_expire_t and HUDListManager.ListOptions.show_tape_loop then
			clbk("start_tape_loop", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_show_bag_deployable_by_type(deployable_type, option_value)
	local list = self:list("left_list"):item("equipment")
	local listener_id = string.format("HUDListManager_%s_listener", deployable_type)
	local events = { "set_active" }
	local clbk = callback(self, self, "_deployable_equipment_event")
	
	for _, event in pairs(events) do
		if option_value > 0 then
			managers.gameinfo:register_listener(listener_id, deployable_type, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, deployable_type, event)
		end
	end
	
	for id, item in pairs(list:items()) do
		if item:equipment_type() == deployable_type then
			item:delete(true)
		end
	end
	
	if option_value > 0 then
		for key, data in pairs(managers.gameinfo:get_deployables(deployable_type)) do
			clbk("set_active", key, data)
		end
	end
end

--Right list config
function HUDListManager:_set_show_enemies()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("enemies")
	
	for unit_type, unit_ids in pairs(all_types) do
		list:remove_item(unit_type, true)
	end
	list:remove_item("enemies", true)
	
	if HUDListManager.ListOptions.show_enemies == 1 then
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, true)
		end
	elseif HUDListManager.ListOptions.show_enemies == 2 then
		self:_update_unit_count_list_items(list, "enemies", all_ids, true)
	end
end

function HUDListManager:_set_show_civilians()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("civilians")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_civilians)
	end
end

function HUDListManager:_set_show_hostages()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("hostages")
	
	for unit_type, unit_ids in pairs(all_types) do
		list:remove_item(unit_type, true)
	end
	list:remove_item("hostages", true)
	
	if HUDListManager.ListOptions.show_hostages == 1 then
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, true)
		end
	elseif HUDListManager.ListOptions.show_hostages == 2 then
		self:_update_unit_count_list_items(list, "hostages", all_ids, true)
	end
end

function HUDListManager:_set_show_minion_count()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("minions")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_minion_count)
	end
end

function HUDListManager:_set_show_turrets()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("turrets")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_turrets)
	end
end	

function HUDListManager:_set_show_pager_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_pager_count then
		list:add_item("PagerCount", HUDList.UsedPagersItem)
	else
		list:remove_item("PagerCount", true)
	end
end

function HUDListManager:_set_show_camera_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_camera_count then
		list:add_item("CameraCount", HUDList.CameraCountItem)
	else
		list:remove_item("CameraCount", true)
	end
end

function HUDListManager:_set_show_special_pickups()
	local list = self:list("right_list"):item("special_pickup_list")
	local all_ids = {}
	local all_types = {}
	
	for pickup_id, pickup_type in pairs(HUDListManager.SPECIAL_PICKUP_TYPES) do
		all_types[pickup_type] = all_types[pickup_type] or {}
		table.insert(all_types[pickup_type], pickup_id)
		table.insert(all_ids, pickup_id)
	end
	
	for pickup_type, members in pairs(all_types) do
		if HUDListManager.ListOptions.show_special_pickups and not HUDListManager.ListOptions.ignore_special_pickups[pickup_type] then
			list:add_item(pickup_type, HUDList.SpecialPickupItem, members)
		else
			list:remove_item(pickup_type, true)
		end
	end
end

function HUDListManager:_set_ignored_special_pickup(pickup, value)
	self:_set_show_special_pickups()
end

function HUDListManager:_set_show_loot()
	local list = self:list("right_list"):item("loot_list")
	local all_ids = {}
	local all_types = {}
	
	for loot_id, loot_type in pairs(HUDListManager.LOOT_TYPES) do
		all_types[loot_type] = all_types[loot_type] or {}
		table.insert(all_types[loot_type], loot_id)
		table.insert(all_ids, loot_id)
	end
	
	for loot_type, loot_ids in pairs(all_types) do
		list:remove_item(loot_type, true)
	end
	list:remove_item("aggregate", true)
	
	if HUDListManager.ListOptions.show_loot == 1 then
		for loot_type, loot_ids in pairs(all_types) do
			list:add_item(loot_type, HUDList.LootItem, loot_ids)
		end
	elseif HUDListManager.ListOptions.show_loot == 2 then
		list:add_item("aggregate", HUDList.LootItem, all_ids)
	end
end

function HUDListManager:_set_separate_bagged_loot()
	for _, item in pairs(self:list("right_list"):item("loot_list"):items()) do
		item:update_value()
	end
end

function HUDListManager:_get_units_by_category(category)
	local all_types = {}
	local all_ids = {}
	
	for unit_id, data in pairs(HUDListManager.UNIT_TYPES) do
		if data.category == category then
			all_types[data.type_id] = all_types[data.type_id] or {}
			table.insert(all_types[data.type_id], unit_id)
			table.insert(all_ids, unit_id)
		end
	end
	
	return all_types, all_ids
end

function HUDListManager:_update_unit_count_list_items(list, id, members, show)
	if show then
		local data = HUDList.UnitCountItem.MAP[id]
		local item = list:add_item(id, data.class or HUDList.UnitCountItem, members)
	else
		list:remove_item(id, true)
	end
end

function HUDListManager:_set_show_body_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_body_count then
		list:add_item("body_stealth", HUDList.BodyCountItem)
	else
		list:remove_item("body_stealth", true)
	end
end

--Buff list config
function HUDListManager:_set_show_buffs()
	local listener_id = "HUDListManager_buff_listener"
	local src = "buff"
	local events = { "activate", "deactivate" }
	local clbk = callback(self, self, "_buff_event")
	local list = self:list("buff_list")
	
	for _, event in ipairs(events) do
		if HUDListManager.ListOptions.show_buffs then
			managers.gameinfo:register_listener(listener_id, src, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, src, event)
		end
	end
	
	for buff_id, data in pairs(managers.gameinfo:get_buffs()) do
		if HUDListManager.ListOptions.show_buffs then
			clbk("activate", buff_id, data)
		else
			list:remove_item(buff_id, true)
		end
	end
end

function HUDListManager:_set_ignored_buff(item_id, value)
	local list = self:list("buff_list")
	
	if HUDListManager.ListOptions.show_buffs then
		if not value then
			local members = {}
			for id, data in pairs(HUDListManager.BUFFS) do
				if table.contains(data, item_id) then
					table.insert(members, id)
				end
			end
			
			local item_data = HUDList.BuffItemBase.MAP[item_id]
			local item = item_data and list:add_item(item_id, item_data.class or "BuffItemBase", members, item_data)
			
			for _, member_id in ipairs(members) do
				local buff_data = managers.gameinfo:get_buffs(member_id)
				
				if item and buff_data then
					local is_debuff = HUDListManager.BUFFS[member_id].is_debuff
					item:set_buff_active(member_id, true, buff_data, is_debuff)
					item:apply_current_values(member_id, buff_data)
				end
			end
		else
			list:remove_item(item_id, true)
		end
	end
end

function HUDListManager:_get_buff_items(id)
	local buff_list = self:list("buff_list")
	local items = {}
	local is_debuff = false
	
	local function create_item(item_id)
		if HUDListManager.ListOptions.ignore_buffs[item_id] then return end
		
		local item_data = HUDList.BuffItemBase.MAP[item_id]
		
		if item_data then
			local members = {}
		
			for buff_id, data in pairs(HUDListManager.BUFFS) do
				if table.contains(data, item_id) and not table.contains(members, buff_id) then
					table.insert(members, buff_id)
				end
			end
			
			return buff_list:add_item(item_id, item_data.class or "BuffItemBase", members, item_data)
		end
		
		printf("(%.2f) HUDListManager:_get_buff_items(%s): No map entry for item", Application:time(), tostring(item_id))
	end
	
	if HUDListManager.BUFFS[id] then
		for _, item_id in ipairs(HUDListManager.BUFFS[id]) do
			local item = buff_list:item(item_id) or create_item(item_id)
			if item then
				table.insert(items, item)
			end
		end
		is_debuff = HUDListManager.BUFFS[id].is_debuff
	else
		printf("(%.2f) HUDListManager:_get_buff_items(%s): No definition for buff", Application:time(), tostring(id))
	end
	
	return items, is_debuff
end

function HUDListManager:_set_show_player_actions()
	local listener_id = "HUDListManager_player_action_listener"
	local src = "player_action"
	local events = { "activate", "deactivate" }
	local clbk = callback(self, self, "_player_action_event")
	local list = self:list("buff_list")
	
	for _, event in ipairs(events) do
		if HUDListManager.ListOptions.show_player_actions then
			managers.gameinfo:register_listener(listener_id, src, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, src, event)
		end
	end
	
	for action_id, data in pairs(managers.gameinfo:get_player_actions()) do
		if HUDListManager.ListOptions.show_player_actions then
			clbk("activate", action_id, data)
		else
			list:remove_item(action_id, true)
		end
	end
end

function HUDListManager:_set_ignored_player_action(id, value)
	local list = self:list("buff_list")
	
	if HUDListManager.ListOptions.show_player_actions then
		if not value then
			local action_data = managers.gameinfo:get_player_actions(id)
			
			if action_data then
				self:_player_action_event("activate", id, action_data)
			end
		else
			list:remove_item(id, true)
		end
	end
end

--Event handlers
function HUDListManager:_timer_event(event, key, data)
	local settings = HUDListManager.TIMER_SETTINGS[data.id] or {}
	
	if not settings.ignore then
		local timer_list = self:list("left_list"):item("timers")
		
		if event == "set_active" then
			if data.active then
				local class = settings.class or (HUDList.TimerItem.DEVICE_TYPES[data.device_type] or HUDList.TimerItem.DEVICE_TYPES.default).class
				timer_list:add_item(key, class, data, settings.params):activate()
			else
				timer_list:remove_item(key)
			end
		end
	end
end

function HUDListManager:_deployable_equipment_event(event, key, data)
	if event == "set_active" then
		local equipment_list = self:list("left_list"):item("equipment")
		local level_id = managers.job:current_level_id()
		local editor_id = data.unit:editor_id()
		local item_id = key
		local type_to_option = {
			doc_bag = HUDListManager.ListOptions.show_doc_bags,
			ammo_bag = HUDListManager.ListOptions.show_ammo_bags,
			body_bag = HUDListManager.ListOptions.show_body_bags,
			grenade_crate = HUDListManager.ListOptions.show_grenade_crates,
		}
		
		if type_to_option[data.type] == 2 then
			item_id = data.type
		elseif HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id] and HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id][editor_id] then
			item_id = HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id][editor_id]
		end
	
		if data.active then
			local class = HUDListManager.EQUIPMENT_TABLE[data.type].class
			local item = equipment_list:add_item(item_id, class, data.type)
			item:add_bag_unit(key, data)
		else
			local item = equipment_list:item(item_id)
			if item then
				item:remove_bag_unit(key, data)
			end
		end
	end
end

function HUDListManager:_sentry_equipment_event(event, key, data)
	local sentry_list = self:list("left_list"):item("sentries")
	
	if event == "set_active" then
		if data.active then
			local class = HUDListManager.EQUIPMENT_TABLE[data.type].class
			local item = sentry_list:add_item(key, class, data)
			item:set_active(HUDListManager.ListOptions.show_sentries < 2 or item:is_player_owner())
		else
			sentry_list:remove_item(key)
		end
	end
end

function HUDListManager:_minion_event(event, key, data)
	local minion_list = self:list("left_list"):item("minions")
	
	if event == "add" then
		local item = minion_list:add_item(key, HUDList.MinionItem, data)
		item:set_active(HUDListManager.ListOptions.show_minions < 2 or item:is_player_owner())
	elseif event == "remove" then
		minion_list:remove_item(key)
	end
end

function HUDListManager:_pager_event(event, key, data)
	local pager_list = self:list("left_list"):item("pagers")
	
	if event == "add" then
		pager_list:add_item(key, HUDList.PagerItem, data):activate()
	elseif event == "remove" then
		pager_list:remove_item(key)
	end
end

function HUDListManager:_ecm_event(event, key, data)
	local list = self:list("left_list"):item("ecms")
	
	if event == "set_jammer_active" then
		if data.jammer_active then
			list:add_item(key, data.is_pocket_ecm and HUDList.PocketECMItem or HUDList.ECMItem, data):activate()
		else
			list:remove_item(key)
		end
	end
end

function HUDListManager:_ecm_retrigger_event(event, key, data)
	local list = self:list("left_list"):item("ecm_retrigger")
	
	if event == "set_retrigger_active" then
		if data.retrigger_active then
			list:add_item(key, HUDList.ECMRetriggerItem, data):activate()
		else
			list:remove_item(key)
		end
	end
end

function HUDListManager:_tape_loop_event(event, key, data)
	local list = self:list("left_list"):item("tape_loop")
	
	if event == "start_tape_loop" then
		list:add_item(key, HUDList.TapeLoopItem, data):activate()
	elseif event == "stop_tape_loop" then
		list:remove_item(key)
	end
end

function HUDListManager:_buff_event(event, id, data)
	local items, is_debuff = self:_get_buff_items(id)
	local active = event == "activate" and true or false
	
	for _, item in ipairs(items) do
		item:set_buff_active(id, active, data, is_debuff)
		if active then
			item:apply_current_values(id, data)
		end
	end
end

function HUDListManager:_player_action_event(event, id, data)
	if not HUDListManager.ListOptions.ignore_player_actions[id] then
		local item_data = HUDList.PlayerActionItemBase.MAP[id]
		local activate = event == "activate" and true or false
	
		if item_data then
			local item = self:list("buff_list"):add_item(id, item_data.class or "PlayerActionItemBase", data, item_data)
			if item_data.delay then
				item:disable("delayed_enable")
			end
			if item_data.min_duration then
				item:disable("insufficient_duration")
			end
			item:set_active(activate)
		else
			printf("(%.2f) HUDListManager:_player_action_event(%s, %s): No map entry for item", Application:time(), event, id)
		end
	end
end

function HUDListManager:change_ignore_buff_setting(buff, value)
	if HUDListManager.ListOptions.ignore_buffs[buff] ~= value then
		HUDListManager.ListOptions.ignore_buffs[buff] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_buff(buff, value)
		end
	end
end

function HUDListManager:change_ignore_player_action_setting(action, value)
	if HUDListManager.ListOptions.ignore_player_actions[action] ~= value then
		HUDListManager.ListOptions.ignore_player_actions[action] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_player_action(action, value)
		end
	end
end

function HUDListManager:change_ignore_special_pickup_setting(pickup, value)
	if HUDListManager.ListOptions.ignore_special_pickups[pickup] ~= value then
		HUDListManager.ListOptions.ignore_special_pickups[pickup] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_special_pickup(pickup, value)
		end
	end
end

local function get_icon_data(icon)
    local texture = icon.texture
    local texture_rect = icon.texture_rect

    if icon.skills then
        texture = "guis/textures/pd2/skilltree/icons_atlas"
        local x, y = unpack(icon.skills)
        texture_rect = { x * 64, y * 64, 64, 64 }
    elseif icon.skills_new then
        texture = "guis/textures/pd2/skilltree_2/icons_atlas_2"
        local x, y = unpack(icon.skills_new)
        texture_rect = { x * 80, y * 80, 80, 80 }
    elseif icon.perks then
        texture = "guis/" .. (icon.bundle_folder and ("dlcs/" .. tostring(icon.bundle_folder) .. "/") or "") .. "textures/pd2/specialization/icons_atlas"
        local x, y = unpack(icon.perks)
        texture_rect = { x * 64, y * 64, 64, 64 }
    elseif icon.hud_icons then
        texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon.hud_icons)
    elseif icon.hudtabs then
        texture = "guis/textures/pd2/hud_tabs"
        texture_rect = icon.hudtabs
    elseif icon.preplanning then
        texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/preplan_icon_types"
        local x, y = unpack(icon.preplanning)
        texture_rect = { x * 48, y * 48, 48, 48 }
    end
    
    return texture, texture_rect
end

local function format_time_string(t)
    t = math.floor(t * 10) / 10
    
    if t < 0 then
        return string.format("%.1f", 0)
    elseif t < 10 then
        return string.format("%.1f", t)
    elseif t < 60 then
        return string.format("%d", t)
    else
        return string.format("%d:%02d", t/60, t%60)
    end
end

local DEFAULT_COLOR_TABLE = {
    { ratio = 0.0, color = Color(1, 0.9, 0.1, 0.1) }, --Red
    { ratio = 0.5, color = Color(1, 0.9, 0.9, 0.1) }, --Yellow
    { ratio = 1.0, color = Color(1, 0.1, 0.9, 0.1) } --Green
}
local function get_color_from_table(value, max_value, color_table, default_color)
    local color_table = color_table or DEFAULT_COLOR_TABLE
    local ratio = math.clamp(value / max_value, 0 , 1)
    local tmp_color = color_table[#color_table].color
    local color = default_color or Color(tmp_color.alpha, tmp_color.red, tmp_color.green, tmp_color.blue)
    
    for i, data in ipairs(color_table) do
        if ratio < data.ratio then
            local nxt = color_table[math.clamp(i-1, 1, #color_table)]
            local scale = (ratio - data.ratio) / (nxt.ratio - data.ratio)
            color = Color(
                (data.color.alpha or 1) * (1-scale) + (nxt.color.alpha or 1) * scale, 
                (data.color.red or 0) * (1-scale) + (nxt.color.red or 0) * scale, 
                (data.color.green or 0) * (1-scale) + (nxt.color.green or 0) * scale, 
                (data.color.blue or 0) * (1-scale) + (nxt.color.blue or 0) * scale)
            break
        end
    end
    
    return color
end

local function make_circle_gui(panel, size, add_bg, add_bg_circle, x, y)
    local cricle, bg, bg_circle

    circle = CircleBitmapGuiObject:new(panel, {
        use_bg = true,
        radius = size / 2,
        color = Color.white:with_alpha(1),
        layer = 0,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
    })
    circle._alpha = 1
    if x and y then
        circle:set_position(x, y)
    end
    
    if add_bg then
        local texture, texture_rect = get_icon_data({ hudtabs = { 84, 34, 19, 19 } })
        bg = panel:bitmap({
            texture = texture,
            texture_rect = texture_rect,
            align = "center",
            vertical = "center",
            valign = "scale",
            halign = "scale",
            w = size * 1.3,
            h = size * 1.3,
            layer = -20,
            alpha = 0.25,
            color = Color.black,
        })
        local diff = size * 0.3 / 2
        local cx, cy = circle:position()
        bg:set_position(cx - diff, cy - diff)
    end
    
    if add_bg_circle then
        bg_circle = panel:bitmap({
            texture = "guis/textures/pd2/hud_progress_active",
            w = size,
            h = size,
            align = "center",
            vertical = "center",
            valign = "scale",
            halign = "scale",
            layer = -10,
        })
        bg_circle:set_position(circle:position())
    end
    
    return circle, bg, bg_circle
end

local dir = Vector3()
local fwd = Vector3()
local function get_distance_and_rotation(camera, unit)
    mvector3.set(fwd, camera:rotation():y())
    mvector3.set(dir, unit:position())
    mvector3.subtract(dir, camera:position())
    local distance = mvector3.normalize(dir)
    local rotation = math.atan2(fwd.x*dir.y - fwd.y*dir.x, fwd.x*dir.x + fwd.y*dir.y)
    
    return distance, rotation
end

local function HUDBGBox_create_rescalable(...)
    local box_panel = HUDBGBox_create(...)
    for _, vertical in ipairs({ "top", "bottom" }) do
        for _, horizontal in ipairs({ "left", "right" }) do
            local corner_icon = box_panel:child(string.format("%s_%s", horizontal, vertical))
            corner_icon:set_halign("scale")
            corner_icon:set_valign("scale")
        end
    end
    return box_panel
end

local function tostring_trimmed(number, max_decimals)
    return string.format("%." .. (max_decimals or 10) .. "f", number):gsub("%.?0+$", "")
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

HUDList.StaticItem = HUDList.StaticItem or class(HUDList.Base)
function HUDList.StaticItem:init(id, ppanel, size, ...)
    HUDList.StaticItem.super.init(self, id, ppanel, { w = size, h = size })
    
    self._base_size = size
    
    for i, icon in ipairs({ ... }) do
        local texture, texture_rect = get_icon_data(icon)
        
        local bitmap = self._panel:bitmap({
            texture = texture,
            texture_rect = texture_rect,
            h = self._panel:w() * (icon.h_scale or 1),
            w = self._panel:w() * (icon.w_scale or 1),
            align = "center",
            vertical = "center",
            valign = "scale",
            halign = "scale",
        })
        
        bitmap:set_center(self._panel:center())
        
        if icon.valign == "top" then 
            bitmap:set_top(self._panel:top())
        elseif icon.valign == "bottom" then 
            bitmap:set_bottom(self._panel:bottom())
        end
        
        if icon.halign == "left" then
            bitmap:set_left(self._panel:left())
        elseif icon.halign == "right" then
            bitmap:set_right(self._panel:right())
        end
    end
end

function HUDList.StaticItem:rescale(scale)
    self._panel:set_size(self._base_size * scale, self._base_size * scale)
end


HUDList.RescalableHorizontalList = HUDList.RescalableHorizontalList or class(HUDList.HorizontalList)
function HUDList.RescalableHorizontalList:init(...)
    HUDList.RescalableHorizontalList.super.init(self, ...)
    
    self._current_scale = 1
    self._base_h = self._panel:h()
end

function HUDList.RescalableHorizontalList:rescale(scale)
    if self._current_scale ~= scale then
        local h = self._base_h * scale
        self._current_scale = scale
        
        self._panel:set_h(h)
        for id, item in pairs(self:items()) do
            item:rescale(scale)
        end
        
        if self._static_item then
            self._static_item:rescale(scale)
        end
        
        if self._expansion_indicator then
            self._expansion_indicator:rescale(scale)
        end
        
        self:rearrange()
    end
end


HUDList.EventItemBase = HUDList.EventItemBase or class(HUDList.Base)
function HUDList.EventItemBase:init(...)
    HUDList.EventItemBase.super.init(self, ...)
    self._listener_clbks = {}
end

function HUDList.EventItemBase:post_init(...)
    HUDList.EventItemBase.super.post_init(self, ...)
    self:_register_listeners()
end

function HUDList.EventItemBase:destroy()
    HUDList.EventItemBase.super.destroy(self)
    self:_unregister_listeners()
end

function HUDList.EventItemBase:rescale(scale)
    self._panel:set_size(self._internal.parent_panel:h(), self._internal.parent_panel:h())
end

function HUDList.EventItemBase:_register_listeners()
    for i, data in ipairs(self._listener_clbks) do
        for _, event in pairs(data.event) do
            managers.gameinfo:register_listener(data.name, data.source, event, data.clbk, data.keys, data.data_only)
        end
    end
end

function HUDList.EventItemBase:_unregister_listeners()
    for i, data in ipairs(self._listener_clbks) do
        for _, event in pairs(data.event) do
            managers.gameinfo:unregister_listener(data.name, data.source, event)
        end
    end
end


HUDList.TimerList = HUDList.TimerList or class(HUDList.RescalableHorizontalList)
HUDList.TimerList.RECHECK_INTERVAL = 1
function HUDList.TimerList:update(t, dt, ...)
    self._recheck_order_t = (self._recheck_order_t or 0) - dt
    
    if self._recheck_order_t < 0 then
        for i = 2, #self._item_order, 1 do
            local prev = self:item(self._item_order[i-1])
            local cur = self:item(self._item_order[i])
            
            if prev and cur and prev:priority() < cur:priority() then
                self:rearrange()
                break
            end
        end
        
        self._recheck_order_t = self.RECHECK_INTERVAL
    end
    
    return HUDList.TimerList.super.update(self, t, dt, ...)
end


HUDList.TimerItem = HUDList.TimerItem or class(HUDList.EventItemBase)
HUDList.TimerItem.COLORS = {
    standard = Color(1, 1, 1, 1),
    upgradable = Color(1, 0.0, 0.8, 1.0),
    disabled = Color(1, 1, 0, 0),
}
HUDList.TimerItem.FLASH_SPEED = 2
HUDList.TimerItem.DEVICE_TYPES = {
    default =		{ class = "TimerItem",					title = "Timer" },
    digital =		{ class = "TimerItem",					title = "Timer" }, 
    timer =			{ class = "TimerItem",					title = "Timer" },
    hack =			{ class = "TimerItem",					title = "Hack" },
    securitylock =	{ class = "TimerItem",					title = "Hack" },
    saw =				{ class = "UpgradeableTimerItem",	title = "Saw" },
    drill =			{ class = "UpgradeableTimerItem",	title = "Drill" },
}
function HUDList.TimerItem:init(id, ppanel, timer_data)
    local diameter = ppanel:h() * 2/3

    HUDList.TimerItem.super.init(self, id, ppanel, { w = diameter, h = ppanel:h() })
    
    self._unit = timer_data.unit
    self._remaining = math.huge
    
    self._type_text = self._panel:text({
        name = "type_text",
        text = self.DEVICE_TYPES[timer_data.device_type].title or self.DEVICE_TYPES.default.title,
        align = "center",
        vertical = "top",
        valign = "scale",
        halign = "scale",
        w = diameter,
        h = (self._panel:h() - diameter) * 0.6,
        font_size = (self._panel:h() - diameter) * 0.6,
        font = tweak_data.hud_corner.assault_font,
    })	
    
    self._circle, self._bg, self._circle_bg = make_circle_gui(self._panel, diameter, true, true, 0, self._type_text:h())
    self._circle_bg:set_visible(false)
    self._circle_bg:set_color(Color.red)
    
    local arrow_w = diameter * 0.25
    self._arrow = self._panel:bitmap({
        name = "arrow",
        texture = "guis/textures/hud_icons",
        texture_rect = { 434, 46, 30, 19 },
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = arrow_w,
        h = arrow_w * 2/3,
    })
    self._arrow:set_center(self._circle_bg:center())

    self._main_text = self._panel:text({
        name = "time_text",
        align = "center",
        vertical = "top",
        valign = "scale",
        halign = "scale",
        w = diameter,
        h = diameter * 0.35,
        font = tweak_data.hud_corner.assault_font,
        font_size = diameter * 0.35,
    })
    self._main_text:set_bottom(self._arrow:top() - 1)

    self._secondary_text = self._panel:text({
        name = "distance_text",
        align = "center",
        vertical = "bottom",
        valign = "scale",
        halign = "scale",
        w = diameter,
        h = diameter * 0.3,
        font = tweak_data.hud_corner.assault_font,
        font_size = diameter * 0.3,
    })
    self._secondary_text:set_top(self._arrow:bottom() + 1)
    
    self._flash_color_table = {
        { ratio = 0.0, color = self.COLORS.disabled },
        { ratio = 1.0, color = self.COLORS.standard }
    }
    
    local key = tostring(self._unit:key())
    local listener_id = string.format("HUDList_timer_listener_%s", key)
    local events = {
        update = callback(self, self, "_update_timer"),
        set_jammed = callback(self, self, "_set_jammed"),
        set_unpowered = callback(self, self, "_set_unpowered"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "timer", event = { event }, clbk = clbk, keys = { key }, data_only = true })
    end
end

function HUDList.TimerItem:post_init(timer_data, ...)
    HUDList.TimerItem.super.post_init(self, timer_data, ...)
    
    self:_set_jammed(timer_data)
    self:_set_unpowered(timer_data)
    self:_update_timer(timer_data)
end

function HUDList.TimerItem:priority(...)
    return -self._remaining
end

function HUDList.TimerItem:update(t, dt)
    if self:visible() then
        if self._jammed or self._unpowered then
            self._circle_bg:set_alpha(math.sin(t*360 * self.FLASH_SPEED) * 0.5 + 0.5)
            local new_color = get_color_from_table(math.sin(t*360 * self.FLASH_SPEED) * 0.5 + 0.5, 1, self._flash_color_table, self.COLORS.standard)
            self:_set_colors(new_color)
        end
        
        self:_update_distance(t, dt)
    end
    
    return HUDList.TimerItem.super.update(self, t, dt)
end

function HUDList.TimerItem:rescale(scale)
    self._panel:set_size(self._internal.parent_panel:h() * 2/3, self._internal.parent_panel:h())
    self._type_text:set_font_size((self._panel:h() - self._panel:w()) * 0.6)
    self._main_text:set_font_size(self._panel:w() * 0.35)
    self._secondary_text:set_font_size(self._panel:w() * 0.3)
end

function HUDList.TimerItem:_update_timer(data)
    if data.timer_value then
        self._remaining = data.timer_value
        self._main_text:set_text(format_time_string(self._remaining))
        
        if data.progress_ratio then
            self._circle:set_current(1 - data.progress_ratio)
        elseif data.duration then
            self._circle:set_current(self._remaining/data.duration)
        end
    end
end

function HUDList.TimerItem:_set_jammed(data)
    self._jammed = data.jammed
    self:_check_is_running()
end

function HUDList.TimerItem:_set_unpowered(data)
    self._unpowered = data.unpowered
    self:_check_is_running()
end

function HUDList.TimerItem:_check_is_running()
    if not (self._jammed or self._unpowered) then
        self:_set_colors(self._flash_color_table[2].color)
        self._circle_bg:set_visible(false)
    else
        self._circle_bg:set_visible(true)
    end
end

function HUDList.TimerItem:_update_distance(t, dt)
    local camera = managers.viewport:get_current_camera()
    if camera and alive(self._unit) then
        local distance, rotation = get_distance_and_rotation(camera, self._unit)
        self._secondary_text:set_text(string.format("%.0fm", distance / 100))
        self._arrow:set_rotation(270 - rotation)
    end
end

function HUDList.TimerItem:_set_colors(color)
    self._secondary_text:set_color(color)
    self._main_text:set_color(color)
    self._type_text:set_color(color)
    self._arrow:set_color(color)
end

HUDList.UpgradeableTimerItem = HUDList.UpgradeableTimerItem or class(HUDList.TimerItem)
function HUDList.UpgradeableTimerItem:init(id, ppanel, timer_data)
    HUDList.UpgradeableTimerItem.super.init(self, id, ppanel, timer_data)
    
    self._upgrades = {"faster", "silent", "restarter"}
    self._upgrade_icons = {}
    
    local icon_size = self._panel:h() - self._type_text:h() - self._circle_bg:h()
    for _, upgrade in ipairs(self._upgrades) do
        self._upgrade_icons[upgrade] = self._panel:bitmap{
            texture = "guis/textures/pd2/skilltree/drillgui_icon_" .. upgrade,
            w = icon_size,
            h = icon_size,
            align = "center",
            vertical = "center",
            valign = "scale",
            halign = "scale",
            y = self._panel:h() - icon_size,
            visible = false,
        }
    end
    
    local key = tostring(timer_data.unit:key())
    local listener_id = string.format("HUDList_timer_listener_%s", key)
    local events = {
        set_upgradable = callback(self, self, "_set_upgradable"),
        set_acquired_upgrades = callback(self, self, "_set_acquired_upgrades"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "timer", event = { event }, clbk = clbk, keys = { key }, data_only = true })
    end
end

function HUDList.UpgradeableTimerItem:post_init(timer_data, ...)
    HUDList.UpgradeableTimerItem.super.post_init(self, timer_data, ...)
    
    self:_set_upgradable(timer_data)
    self:_set_acquired_upgrades(timer_data)
    self._upgradable_timer_data = nil
end

function HUDList.UpgradeableTimerItem:_set_upgradable(data)
    self._upgradable = data.upgradable
    local current_color = self._upgradable and self.COLORS.upgradable or self.COLORS.standard
    self._flash_color_table[2].color = current_color
    self:_set_colors(current_color)
end

function HUDList.UpgradeableTimerItem:_set_acquired_upgrades(data)
    local x = 0
    
    for _, upgrade in ipairs(self._upgrades) do
        local icon = self._upgrade_icons[upgrade]
        local level =  data.acquired_upgrades and data.acquired_upgrades[upgrade] or 0
        
        icon:set_visible(level > 0)
        if level > 0 then
            icon:set_color(TimerGui.upgrade_colors["upgrade_color_" .. level] or Color.white)
            icon:set_x(x)
            x = x + icon:w()
        end
    end
end

HUDList.TemperatureGaugeItem = HUDList.TemperatureGaugeItem or class(HUDList.TimerItem)
function HUDList.TemperatureGaugeItem:init(id, ppanel, timer_data, timer_params)
    self._start = timer_params.start
    self._goal = timer_params.goal
    self._last_value = self._start
    
    HUDList.TemperatureGaugeItem.super.init(self, id, ppanel, timer_data)
    
    self._type_text:set_text("Temp")
end

function HUDList.TemperatureGaugeItem:update(t, dt)
    if self._estimated_t then
        self._estimated_t = self._estimated_t - dt
        
        if self:visible() then
            self._main_text:set_text(format_time_string(self._estimated_t))
        end
    end
    
    return HUDList.TemperatureGaugeItem.super.update(self, t, dt)
end

function HUDList.TemperatureGaugeItem:priority(...)
    return 1
end

function HUDList.TemperatureGaugeItem:_update_timer(data)
    if data.timer_value then
        local dv = math.abs(self._last_value - data.timer_value)
        local remaining = math.abs(self._goal - data.timer_value)
        
        if dv > 0 then
            self._estimated_t = remaining / dv
            self._circle:set_current(remaining / math.abs(self._goal - self._start))
        end
        
        self._last_value = data.timer_value
    end
end


HUDList.SentryEquipmentItem = HUDList.SentryEquipmentItem or class(HUDList.EventItemBase)
function HUDList.SentryEquipmentItem:init(id, ppanel, sentry_data)
    local equipment_settings = HUDListManager.EQUIPMENT_TABLE.sentry
    
    HUDList.SentryEquipmentItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h(), priority = equipment_settings.priority })
    
    self._unit = sentry_data.unit
    self._type = sentry_data.type
    
    self._ammo_bar = self._panel:bitmap({
        name = "radial_ammo",
        texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
        render_template = "VertexColorTexturedRadial",
        color = Color.red,
        w = self._panel:w(),
        h = self._panel:w(),
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
    })
    
    self._ammo_bar_bg = self._panel:bitmap({
        name = "radial_ammo_bg",
        texture = "guis/textures/pd2/endscreen/exp_ring",
        color = Color.red,
        w = self._panel:w() * 1.15,
        h = self._panel:w() * 1.15,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        visible = false,
        alpha = 0,
        layer = -1,
    })
    self._ammo_bar_bg:set_center(self._panel:w() / 2, self._panel:h() / 2)
    
    self._health_bar = self._panel:bitmap({
        name = "radial_health",
        texture = "guis/textures/pd2/hud_health",
        render_template = "VertexColorTexturedRadial",
        color = Color.red,
        w = self._panel:w(),
        h = self._panel:w(),
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
    })
    
    local texture, texture_rect = get_icon_data({ hudtabs = { 84, 34, 19, 19 } })
    self._owner_icon = self._panel:bitmap({
        name = "owner_icon",
        texture = texture,
        texture_rect = texture_rect,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        h = self._panel:w() * 0.5,
        w = self._panel:w() * 0.5,
        color = Color.black,
        alpha = 0.25,
    })
    self._owner_icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
    
    self._kills = self._panel:text({
        name = "kills",
        text = "0",
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h(),
        layer = 10,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:h() * 0.5,
    })
    
    local listener_id = string.format("HUDList_sentry_listener_%s", id)
    local events = {
        set_ammo_ratio = callback(self, self, "_set_ammo_ratio"),
        set_health_ratio = callback(self, self, "_set_health_ratio"),
        increment_kills = callback(self, self, "_set_kills"),
        set_owner = callback(self, self, "_set_owner"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "sentry", event = { event }, clbk = clbk, keys = { id }, data_only = true })
    end
end

function HUDList.SentryEquipmentItem:post_init(sentry_data, ...)
    HUDList.SentryEquipmentItem.super.post_init(self, sentry_data, ...)

    self:_set_owner(sentry_data)
    self:_set_kills(sentry_data)
    self:_set_ammo_ratio(sentry_data)
    self:_set_health_ratio(sentry_data)
end

function HUDList.SentryEquipmentItem:rescale(scale)
    HUDList.SentryEquipmentItem.super.rescale(self, scale)
    self._kills:set_font_size(self._panel:h() * 0.5)
end

function HUDList.SentryEquipmentItem:is_player_owner()
    return self._owner == managers.network:session():local_peer():id()
end

function HUDList.SentryEquipmentItem:_set_owner(data)
    if data.owner then
        self._owner = data.owner
        self._owner_icon:set_alpha(0.75)
        self._owner_icon:set_color(self._owner and self._owner > 0 and tweak_data.chat_colors[self._owner]:with_alpha(1) or Color.white)
    end
    
    self:set_active(HUDListManager.ListOptions.show_sentries < 2 or self:is_player_owner())
end

function HUDList.SentryEquipmentItem:_set_ammo_ratio(data)
    if data.ammo_ratio then
        self._ammo_bar:set_color(Color(data.ammo_ratio, 1, 1))
        
        
        if data.ammo_ratio <= 0 then
            self:set_active(self:is_player_owner())
            
            self._ammo_bar_bg:animate(function(o)
                local bc = o:color()
                local t = 0
                
                o:set_visible(true)
                
                while true do
                    local r = math.sin(t*720) * 0.25 + 0.25
                    o:set_alpha(r)
                    t = t + coroutine.yield()
                end
            end)
        end
        
    end
end

function HUDList.SentryEquipmentItem:_set_health_ratio(data)
    if data.health_ratio then
        self._health_bar:set_color(Color(data.health_ratio, 1, 1))
    end
end

function HUDList.SentryEquipmentItem:_set_kills(data)
    self._kills:set_text(tostring(data.kills))
end


HUDList.BagEquipmentItem = HUDList.BagEquipmentItem or class(HUDList.EventItemBase)
function HUDList.BagEquipmentItem:init(id, ppanel, equipment_type)
    local equipment_settings = HUDListManager.EQUIPMENT_TABLE[equipment_type]
    
    HUDList.BagEquipmentItem.super.init(self, id, ppanel, { w = ppanel:h() * 0.8, h = ppanel:h(), priority = equipment_settings.priority })
    
    self._units = {}
    self._type = equipment_type
    self._max_amount = 0
    self._amount = 0
    self._amount_offset = 0
    
    self._box = HUDBGBox_create_rescalable(self._panel, {
            w = self._panel:w(),
            h = self._panel:h(),
            halign = "scale",
            valign = "scale",
        }, {})
    
    local texture, texture_rect = get_icon_data(equipment_settings)
    self._icon = self._panel:bitmap({
        name = "icon",
        texture = texture,
        texture_rect = texture_rect,
        h = self._panel:w() * 0.8,
        w = self._panel:w() * 0.8,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        layer = 1,
    })
    self._icon:set_center_x(self._panel:center_x())
    
    self._info_text = self._panel:text({
        name = "info",
        align = "center",
        vertical = "bottom",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h(),
        layer = 1,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:h() * 0.4,
    })
end

function HUDList.BagEquipmentItem:rescale(scale)
    self._panel:set_size(self._internal.parent_panel:h() * 0.8, self._internal.parent_panel:h())
    self._info_text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.BagEquipmentItem:equipment_type()
    return self._type
end

function HUDList.BagEquipmentItem:add_bag_unit(key, data)
    self._units[key] = data
    self:_rebuild_listeners()
    self:_update_info()
    self:set_active(next(self._units) and true or false)
end

function HUDList.BagEquipmentItem:remove_bag_unit(key, data)
    self._units[key] = nil
    self:_rebuild_listeners()
    self:_update_info()
    self:set_active(next(self._units) and true or false)
end

function HUDList.BagEquipmentItem:_rebuild_listeners()
    self:_unregister_listeners()
    self._listener_clbks = {}
    self:_generate_listeners_table()
    self:_register_listeners()
end

function HUDList.BagEquipmentItem:_generate_listeners_table()
    local keys = {}
    for key, data in pairs(self._units) do
        table.insert(keys, key)
    end
    
    local listener_id = string.format("HUDList_bag_listener_%s", self:id())
    local events = {
        set_max_amount = callback(self, self, "_update_info"),
        set_amount = callback(self, self, "_update_info"),
        set_amount_offset = callback(self, self, "_update_info"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = self._type, event = { event }, clbk = clbk, keys = keys, data_only = true })
    end
end

function HUDList.BagEquipmentItem:_update_info(...)
    local max_amount = 0
    local amount = 0
    local amount_offset = 0
    
    for key, data in pairs(self._units) do
        max_amount = max_amount + (data.max_amount or 0)
        amount = amount + (data.amount or 0)
        amount_offset = amount_offset + (data.amount_offset or 0)
    end
    
    self._max_amount = max_amount
    self._amount = amount
    self._amount_offset = amount_offset
    self:_update_text()
    self._info_text:set_color(get_color_from_table(self._amount + self._amount_offset, self._max_amount + self._amount_offset))
end

function HUDList.BagEquipmentItem:_update_text()
    self._info_text:set_text(string.format("%.0f", self._amount + self._amount_offset))
end

HUDList.AmmoBagItem = HUDList.AmmoBagItem or class(HUDList.BagEquipmentItem)	
function HUDList.AmmoBagItem:_update_text()
    self._info_text:set_text(string.format("%.0f%%", (self._amount + self._amount_offset) * 100))
end

HUDList.BodyBagItem = HUDList.BodyBagItem or class(HUDList.BagEquipmentItem)
function HUDList.BodyBagItem:_generate_listeners_table()
    HUDList.BodyBagItem.super._generate_listeners_table(self)
    
    table.insert(self._listener_clbks, {
        name = string.format("HUDList_bag_listener_%s", self:id()),
        source = "whisper_mode",
        event = { "change" },
        clbk = callback(self, self, "_whisper_mode_change"),
        data_only = true,
    })
end

function HUDList.BodyBagItem:set_active(state)
    return HUDList.BodyBagItem.super.set_active(self, state and managers.groupai:state():whisper_mode())
end

function HUDList.BodyBagItem:_whisper_mode_change(state)
    self:set_active(self:active())
end


HUDList.MinionItem = HUDList.MinionItem or class(HUDList.EventItemBase)
function HUDList.MinionItem:init(id, ppanel, minion_data)
    HUDList.MinionItem.super.init(self, id, ppanel, { w = ppanel:h() * 0.8, h = ppanel:h() })
    
    self._unit = minion_data.unit
    local type_string = HUDListManager.UNIT_TYPES[minion_data.type] and HUDListManager.UNIT_TYPES[minion_data.type].long_name or "UNDEF"

    self._health_bar = self._panel:bitmap({
        name = "radial_health",
        texture = "guis/textures/pd2/hud_health",
        texture_rect = { 128, 0, -128, 128 },
        render_template = "VertexColorTexturedRadial",
        blend_mode = "add",
        layer = 2,
        color = Color(1, 1, 0, 0),
        w = self._panel:w(),
        h = self._panel:w(),
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
    })
    self._health_bar:set_bottom(self._panel:bottom())
    
    self._hit_indicator = self._panel:bitmap({
        name = "radial_health",
        texture = "guis/textures/pd2/hud_radial_rim",
        blend_mode = "add",
        layer = 1,
        color = Color.red,
        alpha = 0,
        w = self._panel:w(),
        h = self._panel:w(),
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
    })
    self._hit_indicator:set_center(self._health_bar:center())

    self._outline = self._panel:bitmap({
        name = "outline",
        texture = "guis/textures/pd2/hud_shield",
        texture_rect = { 128, 0, -128, 128 },
        blend_mode = "add",
        w = self._panel:w() * 0.95,
        h = self._panel:w() * 0.95,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        layer = 1,
        alpha = 0,
        color = Color(0.8, 0.8, 1.0),
    })
    self._outline:set_center(self._health_bar:center())
    
    self._damage_upgrade_text = self._panel:text({
        name = "type",
        text = "W",
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:w(),
        layer = 3,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:w() * 0.4,
        alpha  = 0.5
    })
    self._damage_upgrade_text:set_bottom(self._panel:bottom())
    
    self._unit_type = self._panel:text({
        name = "type",
        text = type_string,
        align = "center",
        vertical = "top",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:w() * 0.3,
        layer = 3,
        font = tweak_data.hud_corner.assault_font,
        font_size = math.min(8 / string.len(type_string), 1) * 0.25 * self._panel:h(),
    })
    
    self._kills = self._panel:text({
        name = "kills",
        text = "0",
        align = "right",
        vertical = "bottom",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:w(),
        layer = 10,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:w() * 0.4,
    })
    self._kills:set_center(self._health_bar:center())
    
    local key = tostring(self._unit:key())
    local listener_id = string.format("HUDList_minion_listener_%s", key)
    local events = {
        set_health_ratio = callback(self, self, "_set_health_ratio"),
        set_owner = callback(self, self, "_set_owner"),
        increment_kills = callback(self, self, "_set_kills"),
        set_damage_resistance = callback(self, self, "_set_damage_resistance"),
        set_damage_multiplier = callback(self, self, "_set_damage_multiplier"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "minion", event = { event }, clbk = clbk, keys = { key }, data_only = true })
    end
end

function HUDList.MinionItem:post_init(minion_data, ...)
    HUDList.MinionItem.super.post_init(self, minion_data, ...)

    self:_set_health_ratio(minion_data, true)
    self:_set_damage_resistance(minion_data)
    self:_set_damage_multiplier(minion_data)
    self:_set_owner(minion_data)
end

function HUDList.MinionItem:rescale(scale)
    self._panel:set_size(self._internal.parent_panel:h() * 0.8, self._internal.parent_panel:h())
    self._damage_upgrade_text:set_font_size(self._panel:w() * 0.4)
    self._unit_type:set_font_size(math.min(8 / string.len(self._unit_type:text()), 1) * 0.25 * self._panel:h())
    self._kills:set_font_size(self._panel:w() * 0.4)
end

function HUDList.MinionItem:is_player_owner()
    return self._owner == managers.network:session():local_peer():id()
end

function HUDList.MinionItem:_set_health_ratio(data, skip_animate)
    if data.health_ratio then
        self._health_bar:set_color(Color(1, data.health_ratio, 1, 1))
        if not skip_animate then
            self._hit_indicator:stop()
            self._hit_indicator:animate(function(o)
                over(1, function(r)
                    o:set_alpha(1-r)
                end)
            end)
        end
    end
end

function HUDList.MinionItem:_set_owner(data)
    if data.owner then
        self._owner = data.owner
        self._unit_type:set_color(tweak_data.chat_colors[data.owner]:with_alpha(1) or Color(1, 1, 1, 1))
    end
    
    self:set_active(HUDListManager.ListOptions.show_minions < 2 or self:is_player_owner())
end

function HUDList.MinionItem:_set_kills(data)
    self._kills:set_text(data.kills)
end

function HUDList.MinionItem:_set_damage_resistance(data)
    local max_mult = tweak_data.upgrades.values.player.convert_enemies_health_multiplier[1] * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[2]
    local alpha = math.clamp(1 - ((data.damage_resistance or 1) - max_mult) / (1 - max_mult), 0, 1) * 0.8 + 0.2
    self._outline:set_alpha(alpha)
end

function HUDList.MinionItem:_set_damage_multiplier(data)
    self._damage_upgrade_text:set_alpha((data.damage_multiplier or 1) > 1 and 1 or 0.5)
end


HUDList.PagerItem = HUDList.PagerItem or class(HUDList.EventItemBase)
HUDList.PagerItem.FLASH_SPEED = 2
function HUDList.PagerItem:init(id, ppanel, pager_data)
    HUDList.PagerItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
    
    self._unit = pager_data.unit
    self._start_t = pager_data.start_t
    self._expire_t = pager_data.expire_t
    self._duration = pager_data.expire_t - pager_data.start_t
    self._remaining = pager_data.expire_t - Application:time()
    
    self._circle, self._bg, self._circle_bg = make_circle_gui(self._panel, self._panel:h(), true, true)
    
    local arrow_w = self._panel:w() * 0.25
    self._arrow = self._panel:bitmap({
        name = "arrow",
        texture = "guis/textures/hud_icons",
        texture_rect = { 434, 46, 30, 19 },
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = arrow_w,
        h = arrow_w * 2/3,
    })
    self._arrow:set_center(self._panel:w() / 2, self._panel:h() / 2)

    self._time_text = self._panel:text({
        name = "time_text",
        align = "center",
        vertical = "top",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h() * 0.35,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:h() * 0.35,
    })
    self._time_text:set_bottom(self._arrow:top() - 1)

    self._distance_text = self._panel:text({
        name = "distance_text",
        align = "center",
        vertical = "bottom",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h() * 0.3,
        font = tweak_data.hud_corner.assault_font,
        font_size = self._panel:h() * 0.3,
    })
    self._distance_text:set_top(self._arrow:bottom() + 1)
    
    local key = tostring(self._unit:key())
    table.insert(self._listener_clbks, { 
        name = string.format("HUDList_pager_listener_%s", key), 
        source = "pager", 
        event = { "set_answered" }, 
        clbk = callback(self, self, "_set_answered"), 
        keys = { key }, 
        data_only = true
    })
end

function HUDList.PagerItem:rescale(scale)
    HUDList.PagerItem.super.rescale(self, scale)
    self._time_text:set_font_size(self._panel:h() * 0.35)
    self._distance_text:set_font_size(self._panel:h() * 0.3)
end

function HUDList.PagerItem:_set_answered()
    self._answered = true
    self._time_text:set_color(Color(1, 0.1, 0.9, 0.1))
    
    self._circle_bg:set_color(Color.green)
    self._circle_bg:set_alpha(0.8)
    self._circle_bg:set_visible(true)
end

function HUDList.PagerItem:update(t, dt)
    if not self._answered then
        self._remaining = math.max(self._remaining - dt, 0)
        
        if self:visible() then
            self._ratio = self._remaining / self._duration
            
            local color = get_color_from_table(self._remaining, self._duration)
            self._time_text:set_text(format_time_string(self._remaining))
            self._time_text:set_color(color)
            self._circle_bg:set_color(color)
            self._circle:set_current(self._ratio)
            
            if self._ratio <= 0.25 then
                self._circle_bg:set_alpha(math.sin(t*360 * self.FLASH_SPEED) * 0.3 + 0.5)
            end
        end
    end
    
    if self:visible() then
        local camera = managers.viewport:get_current_camera()
        if camera and alive(self._unit) then
            local distance, rotation = get_distance_and_rotation(camera, self._unit)
            self._distance_text:set_text(string.format("%.0fm", distance / 100))
            self._arrow:set_rotation(270 - rotation)
        end
    end
    
    return HUDList.PagerItem.super.update(self, t, dt)
end	


HUDList.ECMItem = HUDList.ECMItem or class(HUDList.EventItemBase)
function HUDList.ECMItem:init(id, ppanel, ecm_data)
    HUDList.ECMItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
    
    self._unit = ecm_data.unit
    self._max_duration = ecm_data.max_duration or tweak_data.upgrades.ecm_jammer_base_battery_life
    
    self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
    
    self._text = self._panel:text({
        name = "text",
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h(),
        font = tweak_data.hud_corner.assault_font,
        layer = 10,
        font_size = self._panel:h() * 0.4,
    })
    
    local texture, texture_rect = get_icon_data({ skills_new = { 3, 4 } })
    self._pager_block_icon = self._panel:bitmap({
        name = "pager_block_icon",
        texture = texture,
        texture_rect = texture_rect,
        w = self._panel:w() * 0.7,
        h = self._panel:h() * 0.7,
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        alpha = 0.85,
    })
    self._pager_block_icon:set_bottom(self._panel:h() * 1.1)
    self._pager_block_icon:set_right(self._panel:w() * 1.1)
    
    local key = tostring(self._unit:key())
    local listener_id = string.format("HUDList_ecm_jammer_listener_%s", key)
    local events = {
        set_upgrade_level = callback(self, self, "_set_upgrade_level"),
        set_jammer_battery = callback(self, self, "_set_jammer_battery"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "ecm", event = { event }, clbk = clbk, keys = { key }, data_only = true })
    end
end

function HUDList.ECMItem:post_init(ecm_data, ...)
    HUDList.ECMItem.super.post_init(self, ecm_data, ...)

    self:_set_jammer_battery(ecm_data)
    self:_set_upgrade_level(ecm_data)
end

function HUDList.ECMItem:rescale(scale)
    HUDList.ECMItem.super.rescale(self, scale)
    self._text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.ECMItem:_set_upgrade_level(data)
    if data.upgrade_level then
        self._blocks_pager = data.upgrade_level == 3
        self._max_duration = tweak_data.upgrades.ecm_jammer_base_battery_life * ECMJammerBase.battery_life_multiplier[data.upgrade_level]
        self._pager_block_icon:set_visible(self._blocks_pager)
    end
end

function HUDList.ECMItem:_set_jammer_battery(data)
    if data.jammer_battery then
        self._text:set_text(format_time_string(data.jammer_battery))
        self._text:set_color(get_color_from_table(data.jammer_battery, self._max_duration))
        self._circle:set_current(data.jammer_battery / self._max_duration)
    end
end

HUDList.PocketECMItem = HUDList.PocketECMItem or class(HUDList.ECMItem)
function HUDList.PocketECMItem:init(id, ppanel, ecm_data)
    HUDList.PocketECMItem.super.init(self, id, ppanel, ecm_data)
    
    self._start_t = ecm_data.t
    self._expire_t = ecm_data.expire_t
end

function HUDList.PocketECMItem:update(...)
    HUDList.PocketECMItem.super.update(self, ...)
    
    local t = Application:time()
    local remaining = self._expire_t - t
    self:_set_jammer_battery({ jammer_battery = remaining })
end


HUDList.ECMRetriggerItem = HUDList.ECMRetriggerItem or class(HUDList.EventItemBase)
function HUDList.ECMRetriggerItem:init(id, ppanel, ecm_data)
    HUDList.ECMRetriggerItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
    
    self._unit = ecm_data.unit
    self._max_duration = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
    
    self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
    
    self._text = self._panel:text({
        name = "text",
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h(),
        font = tweak_data.hud_corner.assault_font,
        layer = 10,
        font_size = self._panel:h() * 0.4,
    })
    
    local key = tostring(self._unit:key())
    table.insert(self._listener_clbks, { 
        name = string.format("HUDList_ecm_retrigger_listener_%s", key), 
        source = "ecm", 
        event = { "set_retrigger_delay" }, 
        clbk = callback(self, self, "_set_retrigger_delay"), 
        keys = { key }, 
        data_only = true
    })
end

function HUDList.ECMRetriggerItem:post_init(ecm_data, ...)
    HUDList.ECMRetriggerItem.super.post_init(self, ecm_data, ...)

    self:_set_retrigger_delay(ecm_data)
end

function HUDList.ECMRetriggerItem:rescale(scale)
    HUDList.ECMRetriggerItem.super.rescale(self, scale)
    self._text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.ECMRetriggerItem:_set_retrigger_delay(data)
    if data.retrigger_delay then
        local remaining = self._max_duration - data.retrigger_delay
        self._text:set_text(format_time_string(data.retrigger_delay))
        self._text:set_color(get_color_from_table(remaining, self._max_duration))
        self._circle:set_current(1 - remaining / self._max_duration)
    end
end


HUDList.TapeLoopItem = HUDList.TapeLoopItem or class(HUDList.EventItemBase)
function HUDList.TapeLoopItem:init(id, ppanel, tape_loop_data)
    HUDList.TapeLoopItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
    
    self._unit = tape_loop_data.unit
    self._start_t = tape_loop_data.tape_loop_start_t
    self._expire_t = tape_loop_data.tape_loop_expire_t
    self._duration = self._expire_t - self._start_t
    
    self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
    
    self._text = self._panel:text({
        name = "text",
        align = "center",
        vertical = "center",
        valign = "scale",
        halign = "scale",
        w = self._panel:w(),
        h = self._panel:h(),
        font = tweak_data.hud_corner.assault_font,
        layer = 10,
        font_size = self._panel:h() * 0.4,
    })
end

function HUDList.TapeLoopItem:update(t, dt)
    if self:visible() then
        local remaining = self._expire_t - t
        self._text:set_text(format_time_string(remaining))
        self._circle:set_current(remaining / self._duration)
    end
    
    return HUDList.TapeLoopItem.super.update(self, t, dt)
end

function HUDList.TapeLoopItem:rescale(scale)
    HUDList.TapeLoopItem.super.rescale(self, scale)
    self._text:set_font_size(self._panel:h() * 0.4)
end


HUDList.StealthList = HUDList.StealthList or class(HUDList.RescalableHorizontalList)
function HUDList.StealthList:post_init(...)
    HUDList.StealthList.super.post_init(self, ...)
    managers.gameinfo:register_listener("HUDList_stealth_list_listener", "whisper_mode", "change", callback(self, self, "_whisper_mode_change"), nil, true)
end

function HUDList.StealthList:_whisper_mode_change(state)
    if not state then
        self:clear_items()
    end
end


HUDList.CounterItem = HUDList.CounterItem or class(HUDList.EventItemBase)
function HUDList.CounterItem:init(id, ppanel, data)
    HUDList.CounterItem.super.init(self, id, ppanel, { w = ppanel:h() / 2, h = ppanel:h(), priority = data.priority })

    local texture, texture_rect = get_icon_data(data.icon or {})
    self._icon = self._panel:bitmap({
        name = "icon",
        texture = texture,
        texture_rect = texture_rect,
        color = (data.icon and data.icon.color or Color.white):with_alpha(1),
        blend_mode = data.icon and data.icon.blend_mode or "normal",
        h = self._panel:w(),
        w = self._panel:w(),
        halign = "scale",
        valign = "scale",
    })
    
    self._box = HUDBGBox_create_rescalable(self._panel, {
            w = self._panel:w(),
            h = self._panel:w(),
            halign = "scale",
            valign = "scale",
        }, {})
    self._box:set_bottom(self._panel:bottom())
    
    self._text = self._box:text({
        name = "text",
        align = "center",
        vertical = "center",
        halign = "scale",
        valign = "scale",
        w = self._box:w(),
        h = self._box:h(),
        font = tweak_data.hud_corner.assault_font,
        font_size = self._box:h() * 0.6
    })
    
    self._count = 0
end

function HUDList.CounterItem:rescale(scale)
    self._panel:set_size(self._internal.parent_panel:h() / 2, self._internal.parent_panel:h())
    self._text:set_font_size(self._box:h() * 0.6)
end

function HUDList.CounterItem:change_count(diff)
    self:set_count(self._count + diff)
end

function HUDList.CounterItem:set_count(num)
    self._count = num
    self._text:set_text(tostring(self._count))
    self:set_active(self._count > 0)
end


HUDList.UsedPagersItem = HUDList.UsedPagersItem or class(HUDList.CounterItem)
function HUDList.UsedPagersItem:init(id, ppanel)
    HUDList.UsedPagersItem.super.init(self, id, ppanel, { icon = { perks = {1, 4} } })
    
    self._listener_clbks = {
        {
            name = "HUDList_pager_count_listener",
            source = "pager",
            event = { "add" },
            clbk = callback(self, self, "_add_pager"),
            data_only = true,
        }
    }
end

function HUDList.UsedPagersItem:post_init(...)
    HUDList.UsedPagersItem.super.post_init(self, ...)
    self:set_count(table.size(managers.gameinfo:get_pagers()))
end

function HUDList.UsedPagersItem:_add_pager(...)
    self:change_count(1)
end

function HUDList.UsedPagersItem:set_count(num)
    HUDList.UsedPagersItem.super.set_count(self, num)
    
    if self._count >= #tweak_data.player.alarm_pager.bluff_success_chance - 1 then
        self._text:set_color(Color.red)
    end
end


HUDList.CameraCountItem = HUDList.CameraCountIteM or class(HUDList.CounterItem)
function HUDList.CameraCountItem:init(id, ppanel)
    HUDList.CameraCountItem.super.init(self, id, ppanel, { icon = { skills = {4, 2} } })
    
    self._listener_clbks = {
        {
            name = "HUDList_camera_count_listener",
            source = "camera_count",
            event = { "change_count" },
            clbk = callback(self, self, "_recount_cameras"),
            data_only = true,
        },
        {
            name = "HUDList_camera_count_listener",
            source = "camera",
            event = { "set_active", "start_tape_loop", "stop_tape_loop" },
            clbk = callback(self, self, "_recount_cameras"),
            data_only = true,
        },
    }
end

function HUDList.CameraCountItem:post_init(...)
    HUDList.CameraCountItem.super.post_init(self, ...)
    self:_recount_cameras()
end

function HUDList.CameraCountItem:_recount_cameras(...)
    if managers.groupai:state():whisper_mode() then
        local count = 0
        for key, data in pairs(managers.gameinfo:get_cameras()) do
            if data.active or data.tape_loop_expire_t then
                count = count + 1
            end
        end
        self:set_count(count)
    end
end

HUDList.LootItem = HUDList.LootItem or class(HUDList.CounterItem)
HUDList.LootItem.MAP = {
    armor =			{ text = "Armor" },
    artifact =		{ text = "Artifact" },
    body =			{ text = "Body" },
    bomb =			{ text = "Bomb" },
    coke =			{ text = "Coke" },
    dentist =		{ text = "Unknown" },
    diamond =		{ text = "Diamond" },
    drone_ctrl =	{ text = "BCI" },
    evidence =		{ text = "Evidence" },
    goat =			{ text = "Goat" },
    gold =			{ text = "Gold" },
    headset =		{ text = "Headset" },
    jewelry =		{ text = "Jewelry" },
    meth =			{ text = "Meth" },
    money =			{ text = "Money" },
    painting =		{ text = "Painting" },
    pig =				{ text = "Pig" },
    present =		{ text = "Present" },
    prototype =		{ text = "Prototype" },     
    safe =			{ text = "Safe" },
    server =			{ text = "Server" },
    shell =			{ text = "Shell" },
    shoes =			{ text = "Shoes" },
    toast =			{ text = "Toast" },
    toothbrush =	{ text = "Toothbrush" },
    toy =				{ text = "Toy" },
    turret =			{ text = "Turret" },
    warhead =		{ text = "Warhead" },
    weapon =			{ text = "Weapon" },
    wine =			{ text = "Wine" },
    faberge_egg = { text = "Fabergé Egg"},
    romanov_treasure = { text = "Romanov Tre."},

    aggregate =		{ text = "" },	--Aggregated loot
    body_stealth =	{ icon = { skills_new = {7, 2} } },	--Bodies for stealth
}
function HUDList.LootItem:init(id, ppanel, members)
    local data = HUDList.LootItem.MAP[id]
    HUDList.LootItem.super.init(self, id, ppanel, data)

    if not data.icon then
        local texture, texture_rect = get_icon_data({ hudtabs = { 32, 33, 32, 32 } })
        self._icon:set_image(texture, unpack(texture_rect))
        self._icon:set_alpha(0.75)
        self._icon:set_w(self._panel:w() * 1.2)
        self._icon:set_center_x(self._panel:w() / 2)
        self._default_icon = true
    end

    self._loot_types = {}
    self._bagged_count = 0
    self._unbagged_count = 0

    if data.text then
        self._name_text = self._panel:text({
            name = "text",
            text = string.sub(data.text, 1, 5) or "",
            align = "center",
            vertical = "center",
            halign = "scale",
            valign = "scale",
            w = self._panel:w(),
            h = self._panel:w(),
            color = Color(0.0, 0.5, 0.0),
            font = tweak_data.hud_corner.assault_font,
            font_size = self._panel:w() * 0.4,
            layer = 10
        })
        self._name_text:set_center_x(self._icon:center_x())
        self._name_text:set_y(self._name_text:y() + self._icon:h() * 0.1)
    end

    for _, loot_id in pairs(members) do
        self._loot_types[loot_id] = true
    end

    self._listener_clbks = {
        {
            name = string.format("HUDList_%s_loot_count_listener", id),
            source = "loot_count",
            event = { "change" },
            clbk = callback(self, self, "_change_loot_count"),
            keys = members,
            data_only = true,
        }
    }
end

function HUDList.LootItem:rescale(scale)
    HUDList.LootItem.super.rescale(self, scale)
    if self._name_text then
        self._name_text:set_font_size(self._panel:w() * 0.4)
    end
    if self._default_icon then
        self._icon:set_w(self._panel:w() * 1.2)
    end
end

function HUDList.LootItem:post_init(...)
    HUDList.LootItem.super.post_init(self, ...)
    self:update_value()
end

function HUDList.LootItem:update_value()
    local total_unbagged = 0
    local total_bagged = 0

    for _, data in pairs(managers.gameinfo:get_loot()) do
        if self._loot_types[data.carry_id] and self:_check_loot_condition(data) then
            if data.bagged then
                total_bagged = total_bagged + data.count
            else
                total_unbagged = total_unbagged + data.count
            end
        end
    end

    self:set_count(total_unbagged, total_bagged)
end

function HUDList.LootItem:set_count(unbagged, bagged)
    self._unbagged_count = unbagged
    self._bagged_count = bagged

    local total = self._unbagged_count + self._bagged_count
    self._text:set_text(HUDListManager.ListOptions.separate_bagged_loot and (self._unbagged_count .. "/" .. self._bagged_count) or total)
    self:set_active(total > 0)
end

function HUDList.LootItem:_change_loot_count(data, value)
    if not self:_check_loot_condition(data) then return end

    self:set_count(
        self._unbagged_count + (data.bagged and 0 or value), 
        self._bagged_count + (data.bagged and value or 0)
    )
end

function HUDList.LootItem:_check_loot_condition(data)
    local loot_type = HUDListManager.LOOT_TYPES[data.carry_id]
    local condition_clbk = HUDListManager.LOOT_CONDITIONS[loot_type]
    return not condition_clbk or condition_clbk(data)
end

HUDList.BodyCountItem = HUDList.BodyCountItem or class(HUDList.LootItem)
function HUDList.BodyCountItem:init(id, ppanel)
    HUDList.BodyCountItem.super.init(self, id, ppanel, { "person", "special_person" })
end

function HUDList.BodyCountItem:_check_loot_condition()
    return managers.groupai:state():whisper_mode()
end

function HUDList.BodyCountItem:set_count(...)
    if self:_check_loot_condition() then
        HUDList.BodyCountItem.super.set_count(self, ...)
    end
end

local enemy_color = SydneyHUD:GetColor("enemy_color")
local guard_color = enemy_color
local special_color = enemy_color
local turret_color = enemy_color
local thug_color = enemy_color
local civilian_color = SydneyHUD:GetColor("civilian_color")
local minion_color = SydneyHUD:GetColor("minion_color")
local hostage_color = civilian_color

HUDList.UnitCountItem = HUDList.UnitCountItem or class(HUDList.CounterItem)
HUDList.UnitCountItem.MAP = {
    --TODO: Security and cop are both able to be dominate/jokered. Specials could cause issues if made compatible. Straight subtraction won't work. Should be fine for aggregated enemy counter
    enemies =	{ priority = 0,	class = "DominatableCountItem",	icon = { skills = {0, 5}, color = enemy_color } },	--Aggregated enemies
    hostages =	{ priority = 6,	class = "UnitCountItem",			icon = { skills = {4, 7}, color = hostage_color } },	--Aggregated hostages

    cop =		{ priority = 2,	class = "DominatableCountItem",	icon = { skills = {0, 5}, color = enemy_color } },
    security =	{ priority = 3,	class = "DominatableCountItem",	icon = { perks = {1, 4}, color = guard_color } },
    thug =		{ priority = 3,	class = "UnitCountItem",			icon = { skills = {4, 12}, color = thug_color } },
    thug_boss =	{ priority = 3,	class = "UnitCountItem",			icon = { skills = {1, 1}, color = thug_color } },
    tank =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {3, 1}, color = special_color } },
    tank_med =	{ priority = 1,	class = "UnitCountItem",			icon = { hud_icons = "crime_spree_dozer_medic", color = special_color } },
    tank_min =	{ priority = 1,	class = "UnitCountItem",			icon = { hud_icons = "crime_spree_dozer_minigun", color = special_color } },
    spooc =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {1, 3}, color = special_color } },
    taser =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {3, 5}, color = special_color } },
    shield =	{ priority = 1,	class = "ShieldCountItem",			icon = { texture = "guis/textures/pd2/hud_buff_shield", color = special_color } },
    sniper =	{ priority = 1,	class = "UnitCountItem",			icon = { skills = {6, 5}, color = special_color } },
    medic =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {5, 7}, color = special_color } },
    phalanx =	{ priority = 0,	class = "UnitCountItem",			icon = { texture = "guis/textures/pd2/hud_buff_shield", color = special_color } },

    turret =		{ priority = 3,	class = "UnitCountItem",		icon = { skills = {7, 5}, color = turret_color } },
    unique =		{ priority = 4,	class = "UnitCountItem",		icon = { skills = {3, 8}, color = civilian_color } },
    civ =			{ priority = 4,	class = "CivilianCountItem",	icon = { skills = {6, 7}, color = civilian_color } },
    cop_hostage =	{ priority = 5,	class = "UnitCountItem",		icon = { skills = {2, 8}, color = hostage_color } },
    civ_hostage =	{ priority = 6,	class = "UnitCountItem",		icon = { skills = {4, 7}, color = hostage_color } },
    minion =		{ priority = 7,	class = "UnitCountItem",		icon = { skills = {6, 8}, color = minion_color } }
}
function HUDList.UnitCountItem:init(id, ppanel, members)
    local data = HUDList.UnitCountItem.MAP[id]
    HUDList.UnitCountItem.super.init(self, id, ppanel, data)

    self._unit_types = {}

    for _, unit_id in pairs(members) do
        self._unit_types[unit_id] = true
        self._count = self._count + managers.gameinfo:get_unit_count(unit_id)
    end

    self._listener_clbks = {
        {
            name = string.format("HUDList_%s_unit_count_listener", id),
            source = "unit_count",
            event = { "change" },
            clbk = callback(self, self, "_change_count"),
            keys = members,
        }
    }
end

function HUDList.UnitCountItem:post_init(...)
    HUDList.UnitCountItem.super.post_init(self, ...)	
    self:set_count(self._count)
end

function HUDList.UnitCountItem:_change_count(event, unit_type, value)
    self:change_count(value)
end

HUDList.ShieldCountItem = HUDList.ShieldCountItem or class(HUDList.UnitCountItem)
function HUDList.ShieldCountItem:init(...)
    HUDList.ShieldCountItem.super.init(self, ...)

    self._shield_filler = self._panel:rect({
        name = "shield_filler",
        w = self._icon:w() * 0.4,
        h = self._icon:h() * 0.4,
        align = "center",
        vertical = "center",
        halign = "scale",
        valign = "scale",
        color = self._icon:color():with_alpha(1),
        layer = self._icon:layer() - 1,
    })
    self._shield_filler:set_center(self._icon:center())
end

HUDList.CivilianCountItem = HUDList.CivilianCountItem or class(HUDList.UnitCountItem)
function HUDList.CivilianCountItem:init(...)
    HUDList.CivilianCountItem.super.init(self, ...)

    table.insert(self._listener_clbks, {
        name = string.format("HUDList_%s_civ_count_listener", self:id()),
        source = "unit_count",
        event = { "change" },
        clbk = callback(self, self, "_change_count"),
        keys = { "civ_hostage" }
    })
end

function HUDList.CivilianCountItem:post_init(...)
    HUDList.CivilianCountItem.super.post_init(self, ...)
    self:change_count(-managers.gameinfo:get_unit_count("civ_hostage"))
end

function HUDList.CivilianCountItem:_change_count(event, unit_type, value)
    self:change_count(unit_type == "civ_hostage" and -value or value)
end

HUDList.DominatableCountItem = HUDList.DominatableCountItem or class(HUDList.UnitCountItem)
function HUDList.DominatableCountItem:init(id, ppanel, members)
    HUDList.DominatableCountItem.super.init(self, id, ppanel, members)

    self._hostage_offset = 0
    self._joker_offset = 0

    table.insert(self._listener_clbks, {
        name = string.format("HUDList_%s_dominatable_count_listener", id),
        source = "unit_count",
        event = { "change" },
        clbk = callback(self, self, "_change_dominatable_count"),
        keys = { "cop_hostage" }
    })
    table.insert(self._listener_clbks, {
        name = string.format("HUDList_%s_dominatable_minion_count_listener", id),
        source = "minion",
        event = { "add", "remove" },
        clbk = callback(self, self, "_change_joker_count"),
    })
end

function HUDList.DominatableCountItem:post_init(...)
    HUDList.DominatableCountItem.super.post_init(self, ...)
    self:_change_dominatable_count()
end

function HUDList.DominatableCountItem:set_count(num)
    self._count = num
    local actual = self._count - self._hostage_offset - self._joker_offset
    self._text:set_text(tostring(actual))
    self:set_active(actual > 0)
end

function HUDList.DominatableCountItem:_change_dominatable_count(...)
    local offset = 0

    for u_key, u_data in pairs(managers.enemy:all_enemies()) do
        local unit = u_data.unit
        if alive(unit) and self._unit_types[unit:base()._tweak_table] then
            if Network:is_server() then
                if unit:brain():surrendered() then
                    offset = offset + 1
                end
            else
                if unit:anim_data().surrender then
                    offset = offset + 1
                end
            end
        end
    end

    if self._hostage_offset ~= offset then
        self._hostage_offset = offset
        self:set_count(self._count)
    end
end

function HUDList.DominatableCountItem:_change_joker_count(event, key, data)
    if self._unit_types[data.type] then
        self._joker_offset = self._joker_offset + (event == "add" and 1 or -1)
        self:_change_dominatable_count()
        self:set_count(self._count)
    end
end


HUDList.SpecialPickupItem = HUDList.SpecialPickupItem or class(HUDList.CounterItem)
HUDList.SpecialPickupItem.MAP = {
    courier = 					{ icon = { texture = "guis/dlcs/trk/textures/pd2/achievements_atlas7", texture_rect = { 435, 435, 85, 85 }}},
    --courier = 					{ icon = { skills = { 6, 0 } } },
    crowbar =					{ icon = { hud_icons = "equipment_crowbar" } },
    keycard =					{ icon = { hud_icons = "equipment_bank_manager_key" } },
    planks =						{ icon = { hud_icons = "equipment_planks" } },
    meth_ingredients =		{ icon = { hud_icons = "pd2_methlab" } },
    secret_item =				{ icon = { hud_icons = "pd2_question" } },
}

function HUDList.SpecialPickupItem:init(id, ppanel, members)
    HUDList.SpecialPickupItem.super.init(self, id, ppanel, HUDList.SpecialPickupItem.MAP[id])

    self._pickup_types = {}

    for _, pickup_id in pairs(members) do
        self._pickup_types[pickup_id] = true
    end

    for _, data in pairs(managers.gameinfo:get_special_equipment()) do
        if self._pickup_types[data.interact_id] then
            self._count = self._count + 1
        end
    end

    self._listener_clbks = {
        {
            name = string.format("HUDList_%s_special_pickup_count_listener", id),
            source = "special_equipment_count",
            event = { "change" },
            clbk = callback(self, self, "_change_special_equipment_count_clbk"),
            keys = members,
        }
    }
end

function HUDList.SpecialPickupItem:post_init(...)
    HUDList.SpecialPickupItem.super.post_init(self, ...)
    self:set_count(self._count)
end

function HUDList.SpecialPickupItem:_change_special_equipment_count_clbk(event, interact_id, value, data)
    self:change_count(value)
end

local PanelFrame = class()
function PanelFrame:init(parent, settings)
    settings = settings or {}

    local h = settings.h or parent:h()
    local w = settings.w or parent:w()
    local total = 2*w + 2*h

    self._panel = parent:panel({
        w = w,
        h = h,
        alpha = settings.alpha or 1,
        visible = settings.visible,
    })

    self._invert_progress = settings.invert_progress
    self._stages = { 0, w/total, (w+h)/total, (2*w+h)/total, 1 }
    self._top = self._panel:rect({})
    self._bottom = self._panel:rect({})
    self._left = self._panel:rect({})
    self._right = self._panel:rect({})

    self:set_width(settings.bar_w or 2)
    self:set_color(settings.color or Color.white)
    self:reset()
end

function PanelFrame:panel()
    return self._panel
end

function PanelFrame:set_width(w)
    self._top:set_h(w)
    self._top:set_top(0)
    self._bottom:set_h(w)
    self._bottom:set_bottom(self._panel:h())
    self._left:set_w(w)
    self._left:set_left(0)
    self._right:set_w(w)
    self._right:set_right(self._panel:w())
end

function PanelFrame:set_color(c)
    self._top:set_color(c)
    self._bottom:set_color(c)
    self._left:set_color(c)
    self._right:set_color(c)
end

function PanelFrame:reset()
    self._current_stage = 1
    self._top:set_w(self._panel:w())
    self._right:set_h(self._panel:h())
    self._right:set_bottom(self._panel:h())
    self._bottom:set_w(self._panel:w())
    self._bottom:set_right(self._panel:w())
    self._left:set_h(self._panel:h())
end

function PanelFrame:set_ratio(r)
    r = math.clamp(r, 0, 1)
    if self._invert_progress then
        r = 1-r
    end

    if r < self._stages[self._current_stage] then
        self:reset()
    end

    while r > self._stages[self._current_stage + 1] do
        if self._current_stage == 1 then
            self._top:set_w(0)
        elseif self._current_stage == 2 then
            self._right:set_h(0)
        elseif self._current_stage == 3 then
            self._bottom:set_w(0)
        elseif self._current_stage == 4 then
            self._left:set_h(0)
        end
        self._current_stage = self._current_stage + 1
    end

    local low = self._stages[self._current_stage]
    local high = self._stages[self._current_stage + 1]
    local stage_progress = (r - low) / (high - low)

    if self._current_stage == 1 then
        self._top:set_w(self._panel:w() * (1-stage_progress))
        self._top:set_right(self._panel:w())
    elseif self._current_stage == 2 then
        self._right:set_h(self._panel:h() * (1-stage_progress))
        self._right:set_bottom(self._panel:h())
    elseif self._current_stage == 3 then
        self._bottom:set_w(self._panel:w() * (1-stage_progress))
    elseif self._current_stage == 4 then
        self._left:set_h(self._panel:h() * (1-stage_progress))
    end
end

local function buff_value_standard(item, buffs)
    local value = 0
    for buff, data in pairs(buffs) do
        value = value + (data.active and data.value or 0)
    end
    return value
end

local function buff_stack_count_standard(item, buffs)
    local value = 0
    for buff, data in pairs(buffs) do
        value = value + (data.active and data.stack_count or 0)
    end
    return value
end

HUDList.BuffItemBase = HUDList.BuffItemBase or class(HUDList.EventItemBase)
HUDList.BuffItemBase.MAP = {
    --Buffs
    aggressive_reload_aced = {
        skills_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    ammo_efficiency = {
        skills_new = tweak_data.skilltree.skills.spotter_teamwork.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    armor_break_invulnerable = {
        perks = {6, 1},
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks" } },
    },
    berserker = {
        skills_new = tweak_data.skilltree.skills.wolverine.icon_xy,
        class = "BerserkerBuffItem",
        priority = 3,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    biker = {
        perks = {0, 0}, bundle_folder = "wild",
        class = "BikerBuffItem",
        priority = 8,
        menu_data = { grouping = { "perks", "biker" }, sort_key = "prospect" },
    },
    bloodthirst_aced = {
        skills_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
        class = "TimedBuffItem",
        priority = 3,
        ace_icon = true,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    bloodthirst_basic = {
        skills_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    bullet_storm = {
        skills_new = tweak_data.skilltree.skills.ammo_reservoir.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "enforcer" } },
    },
    calm = {
        perks = {2, 0}, bundle_folder = "myh",
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "stoic" } },
    },
    chico_injector = {
        perks = {0, 0}, bundle_folder = "chico",
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "scarface" }, sort_key = "injector" },
    },
    close_contact = {
        perks = {5, 4},
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks" }, sort_key = "close_combat_no_talk" },
    },
    combat_medic = {
        skills_new = tweak_data.skilltree.skills.combat_medic.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    desperado = {
        skills_new = tweak_data.skilltree.skills.expert_handling.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    die_hard = {
        skills_new = tweak_data.skilltree.skills.show_of_force.icon_xy,
        class = "BuffItemBase",
        priority = 7,
        menu_data = { grouping = { "skills", "enforcer" } },
    },
    dire_need = {
        skills_new = tweak_data.skilltree.skills.dire_need.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        menu_data = { grouping = { "skills", "ghost" } },
    },
    grinder = {
        perks = {4, 6},
        class = "TimedStackBuffItem",
        priority = 8,
        menu_data = { grouping = { "perks", "grinder" }, sort_key = "histamine" },
    },
    hostage_situation = {
        perks = {0, 1},
        class = "BuffItemBase",
        priority = 3,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "perks", "crew_chief" } },
    },
    hostage_taker = {
        skills_new = tweak_data.skilltree.skills.black_marketeer.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    inspire = {
        skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    lock_n_load = {
        skills_new = tweak_data.skilltree.skills.shock_and_awe.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        show_value = buff_value_standard,
        menu_data = { grouping = { "skills", "technician" } },
    },
    maniac = {
        perks = {0, 0}, bundle_folder = "coco",
        class = "TimedBuffItem",
        priority = 7,
        show_value = buff_value_standard,
        menu_data = { grouping = { "perks", "maniac" }, sort_key = "excitement" },
    },
    melee_stack_damage = {
        perks = {5, 4},
        class = "TimedBuffItem",
        priority = 7,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "perks", "infiltrator" }, sort_key = "overdog_melee_damage" },
    },
    messiah = {
        skills_new = tweak_data.skilltree.skills.messiah.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    muscle_regen = {
        perks = {4, 1},
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "muscle" }, sort_key = "800_pound_gorilla" },
    },
    overdog = {
        perks = {6, 4},
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "infiltrator" }, sort_key = "overdog_damage_reduction" },
    },
    overkill = {
        skills_new = tweak_data.skilltree.skills.overkill.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "enforcer" } },
    },
    pain_killer = {
        skills_new = tweak_data.skilltree.skills.fast_learner.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    partner_in_crime = {
        skills_new = tweak_data.skilltree.skills.control_freak.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    pocket_ecm_kill_dodge = {
        perks = {3, 0}, bundle_folder = "joy",
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "hacker" } },
    },
    quick_fix = {
        skills_new = tweak_data.skilltree.skills.tea_time.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    running_from_death_aced = {
        skills_new = tweak_data.skilltree.skills.running_from_death.icon_xy,
        class = "BuffItemBase",
        priority = 3,
        ace_icon = true,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    running_from_death_basic = {
        skills_new = tweak_data.skilltree.skills.running_from_death.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    second_wind = {
        skills_new = tweak_data.skilltree.skills.scavenger.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "ghost" } },
    },
    sicario_dodge = {
        perks = {1, 0}, bundle_folder = "max",
        class = "TimedBuffItem",
        priority = 7,
        show_value = buff_value_standard,
        menu_data = { grouping = { "perks", "sicario" }, sort_key = "twitch" },
    },
    sixth_sense = {
        skills_new = tweak_data.skilltree.skills.chameleon.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "ghost" } },
    },
    smoke_screen = {
        perks = {0, 1}, bundle_folder = "max",
        class = "BuffItemBase",
        priority = 7,
        menu_data = { grouping = { "perks", "sicario" } },
    },
    swan_song = {
        skills_new = tweak_data.skilltree.skills.perseverance.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    tooth_and_claw = {
        perks = {0, 3},
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "hitman" } },
    },
    trigger_happy = {
        skills_new = tweak_data.skilltree.skills.trigger_happy.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        show_stack_count = buff_stack_count_standard,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    underdog = {
        skills_new = tweak_data.skilltree.skills.underdog.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "enforcer" } },
    },
    unseen_strike = {
        skills_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "ghost" } },
    },
    uppers = {
        skills_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    up_you_go = {
        skills_new = tweak_data.skilltree.skills.up_you_go.icon_xy,
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "skills", "fugitive" } },
    },
    yakuza = {
        perks = {2, 7},
        class = "BerserkerBuffItem",
        priority = 3,
        menu_data = { grouping = { "perks", "yakuza" } },
    },

    --Debuffs
    ammo_give_out_debuff = {
        perks = {5, 5},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "gambler" } },
    },
    anarchist_armor_recovery_debuff = {
        perks = {0, 1}, bundle_folder = "opera",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "anarchist" }, sort_key = "lust_for_life" },
    },
    armor_break_invulnerable_debuff = {
        perks = {6, 1},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks" } },
    },
    bullseye_debuff = {
        skills_new = tweak_data.skilltree.skills.prison_wife.icon_xy,
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "skills", "enforcer" } },
    },
    chico_injector_debuff = {
        perks = {0, 0}, bundle_folder = "chico",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "scarface" }, sort_key = "injector_debuff" },
    },
    grinder_debuff = {
        perks = {4, 6},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "grinder" }, sort_key = "histamine_debuff" },
    },
    inspire_debuff = {
        skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
        class = "TimedBuffItem",
        priority = 10,
        title = "Boost",
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    inspire_revive_debuff = {
        skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
        class = "TimedBuffItem",
        priority = 10,
        title = "Revive",
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    life_drain_debuff = {
        perks = {7, 4},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "infiltrator" } },
    },
    medical_supplies_debuff = {
        perks = {4, 5},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "gambler" } },
    },
    pocket_ecm_jammer_debuff = {
        perks = {0, 0}, bundle_folder = "joy",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "hacker" } },
    },
    self_healer_debuff = {
        hud_icons = "csb_lifesteal",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "boosts" }, sort_key = "gage_boost_lifesteal" },
    },
    sicario_dodge_debuff = {
        perks = {1, 0}, bundle_folder = "max",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "sicario" }, sort_key = "twitch_debuff" },
    },
    smoke_grenade = {
        perks = {0, 0}, bundle_folder = "max",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "sicario" } },
    },
    sociopath_debuff = {
        perks = {3, 5},
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "perks", "sociopath" } },
    },
    some_invulnerability_debuff = {
        hud_icons = "csb_melee",
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "boosts" }, sort_key = "gage_boost_invulnerability" },
    },
    stoic_flask = {
        perks = {0, 1}, bundle_folder = "myh",
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "stoic" } },
    },
    unseen_strike_debuff = {
        skills_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "skills", "ghost" } },
    },
    uppers_debuff = {
        skills_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
        class = "TimedBuffItem",
        priority = 10,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    virtue_debuff = {
        perks = {3, 0}, bundle_folder = "myh",
        class = "TimedBuffItem",
        priority = 7,
        menu_data = { grouping = { "perks", "stoic" } },
        show_value = buff_value_standard,
    },

    --Team buffs
    armorer = {
        perks = {6, 0},
        class = "TeamBuffItem",
        priority = 1,
        title = "Armorer",
        menu_data = { grouping = { "perks", "armorer" }, sort_key = "liquid_armor" },
    },
    crew_chief = {
        perks = {2, 0},
        class = "TeamBuffItem",
        priority = 1,
        title = "Crew Chief",
        menu_data = { grouping = { "perks", "crew_chief" } },
    },
    forced_friendship = {
        skills = tweak_data.skilltree.skills.triathlete.icon_xy,
        class = "TeamBuffItem",
        priority = 1,
        menu_data = { grouping = { "skills", "mastermind" } },
    },
    shock_and_awe = {
        perks = {6, 2},
        class = "TeamBuffItem",
        priority = 1,
        menu_data = { grouping = { "skills", "enforcer" } },
    },

    --Composite buffs
    damage_increase = {
        perks = {7, 0},
        class = "DamageIncreaseBuffItem",
        priority = 5,
        title = "+Dmg",
        menu_data = { grouping = { "composite" } },
    },
    damage_reduction = {
        skills = {6, 4},
        class = "DamageReductionBuffItem",
        priority = 5,
        title = "-Dmg",
        menu_data = { grouping = { "composite" } },
    },
    melee_damage_increase = {
        skills = {4, 10},
        class = "MeleeDamageIncreaseBuffItem",
        priority = 5,
        title = "+M.Dmg",
        menu_data = { grouping = { "composite" } },
    },
    passive_health_regen = {
        perks = {4, 1},
        class = "HealthRegenBuffItemBase",
        priority = 5,
        show_value = buff_value_standard,
        title = "Regen",
        menu_data = { grouping = { "composite" } },
    },

    --Custom buffs
    crew_inspire = {
        skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
        class = "AITimedBuffItem",
        priority = 10,
        title = "AI"
    }
}

HUDList.BuffItemBase.BUFF_COLORS = {
    standard = Color.white,
    debuff = Color.red,
    team = Color.green,
}
HUDList.BuffItemBase.PROGRESS_BAR_WIDTH = 2
function HUDList.BuffItemBase:init(id, ppanel, members, item_data)
    HUDList.BuffItemBase.super.init(self, id, ppanel, { h = ppanel:h(), w = ppanel:h() * 0.6, priority = -item_data.priority })

    self:set_fade_rate(100)
    self:set_move_rate(nil)

    self._member_data = {}
    self._active_buffs = {}
    self._active_debuffs = {}
    self._standard_color = self._standard_color or item_data.color or self.BUFF_COLORS.standard
    self._debuff_color = self._debuff_color or item_data.debuff_color or self.BUFF_COLORS.debuff
    self._show_stack_count = self._show_stack_count or item_data.show_stack_count
    self._show_value = self._show_value or item_data.show_value
    self._timed = self._timed or item_data.timed

    for _, buff in ipairs(members) do
        self._member_data[buff] = {}
    end

    local icon_size = self._panel:w() - HUDList.BuffItemBase.PROGRESS_BAR_WIDTH * 3 - 5
    local texture, texture_rect = get_icon_data(item_data)

    self._icon = self._panel:bitmap({
        texture = texture,
        texture_rect = texture_rect,
        h = icon_size,
        w = icon_size,
        color = self._standard_color,
        rotation = item_data.icon_rotation or 0,
    })
    self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)

    self._bg = self._panel:rect({
        h = self._icon:h(),
        w = self._icon:w(),
        layer = -10,
        color = Color.black,
        alpha = 0.2,
    })
    self._bg:set_center(self._icon:center())

    if item_data.ace_icon then
        self._ace_icon = self._panel:bitmap({
            texture = "guis/textures/pd2/skilltree_2/ace_symbol",
            h = icon_size * 1.5,
            w = icon_size * 1.5,
            color = self._standard_color,
            layer = self._icon:layer() - 1,
        })
        self._ace_icon:set_center(self._icon:center())
    end

    if self._show_stack_count then
        self._stack_panel = self._panel:panel({
            w = self._icon:w() * 0.4,
            h = self._icon:h() * 0.4,
            layer = self._icon:layer() + 1,
            visible = false,
        })
        self._stack_panel:set_right(self._icon:right())
        self._stack_panel:set_bottom(self._icon:bottom())

        self._stack_panel:bitmap({
            w = self._stack_panel:w(),
            h = self._stack_panel:h(),
            texture = "guis/textures/pd2/equip_count",
            texture_rect = { 5, 5, 22, 22 },
            alpha = 0.8,
        })

        self._stack_text = self._stack_panel:text({
            valign = "center",
            align = "center",
            vertical = "center",
            w = self._stack_panel:w(),
            h = self._stack_panel:h(),
            layer = 1,
            color = Color.black,
            font = tweak_data.hud.small_font,
            font_size = self._stack_panel:h() * 0.85,
        })
    end

    if self._timed then
        self._expire_data = {}
        self._progress_bars = {}

        for i = 1, 3, 1 do
            local progress_bar = PanelFrame:new(self._panel, { 
                bar_w = self.PROGRESS_BAR_WIDTH, 
                w = self._icon:w() + self.PROGRESS_BAR_WIDTH * (i-1) * 2,
                h = self._icon:h() + self.PROGRESS_BAR_WIDTH * (i-1) * 2,
                visible = false,
            })
            progress_bar:panel():set_center(self._icon:center())

            table.insert(self._progress_bars, progress_bar)
        end
    end

    if self._timed or self._show_value then
        local h = (self._panel:h() - self._icon:h()) / 2

        self._value_text = self._panel:text({
            align = "center",
            vertical = "bottom",
            w = self._panel:w(),
            h = h,
            font = tweak_data.hud_corner.assault_font,
            font_size = 0.7 * h,
        })
        self._value_text:set_bottom(self._panel:h())
    end

    if item_data.title then
        local h = (self._panel:h() - self._icon:h()) / 2

        self._title_text = self._panel:text({
            text = item_data.title,
            align = "center",
            vertical = "top",
            w = self._panel:w(),
            h = h,
            font = tweak_data.hud_corner.assault_font,
            font_size = 0.7 * h,
        })
    end

    local listener_id = string.format("HUDList_buff_listener_%s", id)
    local events = {
        set_value = self._show_value and callback(self, self, "_set_value_clbk") or nil,
        set_stack_count = self._show_stack_count and callback(self, self, "_set_stack_count_clbk") or nil,
    }

    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = members })
    end
end

function HUDList.BuffItemBase:apply_current_values(id, data)
    if data then
        if self._timed and data.t and data.expire_t then
            self:_set_duration_clbk("set_duration", id, data)
        end
        if self._show_value and data.value then
            self:_set_value_clbk("set_value", id, data)
        end
        if self._show_stack_count and data.stack_count then
            self:_set_stack_count_clbk("set_stack_count", id, data)
        end
    end
end

function HUDList.BuffItemBase:set_buff_active(id, status, data, is_debuff)
    local active_table = is_debuff and self._active_debuffs or self._active_buffs

    if status then
        self._member_data[id].active = status and true or false
        table.insert(active_table, id)
    elseif table.contains(active_table, id) then
        self._member_data[id].active = status and true or false
        table.delete(active_table, id)

        if self._timed then
            self:_update_expire_data()
        end
    end

    self:set_active(#self._active_debuffs + #self._active_buffs > 0)
end

function HUDList.BuffItemBase:update(t, dt)
    if self:visible() then
        if self._timed then
            local text = ""
            local debuff_start_index

            for i, data in ipairs(self._expire_data) do
                local total = data.expire_t - data.t
                local current = t - data.t
                local remaining = total - current

                self._progress_bars[i]:set_ratio(current/total)

                debuff_start_index = data.is_debuff and string.len(text) or debuff_start_index
                text = text .. format_time_string(remaining)
                if i < #self._expire_data then
                    text = text .. "/"
                end
            end

            if not self._show_value then
                self._value_text:set_text(text)
                if debuff_start_index then
                    self._value_text:set_range_color(debuff_start_index, string.len(text), self.BUFF_COLORS.debuff)
                end
            end
        end
    end

    return HUDList.BuffItemBase.super.update(self, t, dt)
end

function HUDList.BuffItemBase:_set_duration_clbk(event, id, data)
    self._member_data[id].t = data.t
    self._member_data[id].expire_t = data.expire_t
    self:_update_expire_data()
end

function HUDList.BuffItemBase:_set_value_clbk(event, id, data)
    self._member_data[id].value = data.value
    self:_update_value_text()
end

function HUDList.BuffItemBase:_set_stack_count_clbk(event, id, data)
    self._member_data[id].stack_count = data.stack_count
    self:_update_stack_count()
end

function HUDList.BuffItemBase:_update_expire_data()
    self._expire_data = {}

    local min_t, min_expire_t, max_t, max_expire_t
    local debuff_t, debuff_expire_t

    if #self._active_buffs > 0 then
        for _, id in ipairs(self._active_buffs) do
            local data = self._member_data[id]

            if data.expire_t then
                if not max_expire_t or data.expire_t > max_expire_t then
                    max_t = data.t
                    max_expire_t = data.expire_t
                end
                if not min_expire_t or data.expire_t < min_expire_t then
                    min_t = data.t
                    min_expire_t = data.expire_t
                end
            end
        end

        if min_expire_t then
            table.insert(self._expire_data, { t = min_t, expire_t = min_expire_t })
            if math.abs(max_expire_t - min_expire_t) > 0.01 then
                table.insert(self._expire_data, { t = max_t, expire_t = max_expire_t })
            end
        end
    end

    if #self._active_debuffs > 0 then
        for _, id in ipairs(self._active_debuffs) do
            local data = self._member_data[id]

            if data.expire_t and data.t then
                if not debuff_expire_t or data.expire_t > debuff_expire_t then
                    debuff_t = data.t
                    debuff_expire_t = data.expire_t
                end
            end
        end

        if debuff_expire_t then
            table.insert(self._expire_data, { t = debuff_t, expire_t = debuff_expire_t, is_debuff = true })
        end
    end

    for i, progress_bar in ipairs(self._progress_bars) do
        local expire_data = self._expire_data[i]
        progress_bar:panel():set_visible(expire_data and true or false)
        progress_bar:set_color(expire_data and expire_data.is_debuff and self.BUFF_COLORS.debuff or self._standard_color)
    end

    self:_set_icon_color((debuff_expire_t and (not min_expire_t or min_expire_t > debuff_expire_t)) and self._debuff_color or self._standard_color)
end

function HUDList.BuffItemBase:_update_value_text()
    local value = self._show_value(self, self._member_data)
    self._value_text:set_text(tostring_trimmed(value, 2))
end

function HUDList.BuffItemBase:_update_stack_count()
    local stacks = self._show_stack_count(self, self._member_data)
    self._stack_panel:set_visible(stacks > 0)
    self._stack_text:set_text(string.format("%d", stacks))
end

function HUDList.BuffItemBase:_set_icon_color(color)
    self._icon:set_color(color)
    if self._ace_icon then
        self._ace_icon:set_color(color)
    end
end

HUDList.BerserkerBuffItem = HUDList.BerserkerBuffItem or class(HUDList.BuffItemBase)
function HUDList.BerserkerBuffItem:init(...)
    self._show_value = self._show_value_function
    HUDList.BerserkerBuffItem.super.init(self, ...)
end

function HUDList.BerserkerBuffItem._show_value_function(item, buffs)
    local values = {}

    for buff, data in pairs(buffs) do
        if data.active and data.value then
            table.insert(values, data.value)
        end
    end

    return values
end

function HUDList.BerserkerBuffItem:_update_value_text()
    local values = self._show_value(self, self._member_data)
    local text = ""

    for i, value in ipairs(values) do
        text = text .. tostring_trimmed(value, 2)
        if i < #values then
            text = text .. " / "
        end
    end

    self._value_text:set_text(text)
end

HUDList.TeamBuffItem = HUDList.TeamBuffItem or class(HUDList.BuffItemBase)
HUDList.TeamBuffItem.BUFF_LEVELS = {
    cc_passive_damage_reduction =	1,
    cc_passive_stamina_multiplier = 3,
    cc_passive_health_multiplier = 5,
    cc_passive_armor_multiplier = 7,
    cc_hostage_damage_reduction = 9,
    cc_hostage_health_multiplier = 9,
    cc_hostage_stamina_multiplier = 9,
}
function HUDList.TeamBuffItem:init(...)
    self._show_value = self._show_value_function
    HUDList.TeamBuffItem.super.init(self, ...)
    self._standard_color = self.BUFF_COLORS.team
    self:_set_icon_color(self._standard_color)
end

function HUDList.TeamBuffItem._show_value_function(item, buffs)
    local level = 0

    --printf("Updating team buff level: %s", tostring(item:id()))
    for id, data in pairs(buffs) do
        level = math.max(level, data.active and HUDList.TeamBuffItem.BUFF_LEVELS[id] or 0)

        --if data.active then
        --	printf("\tActive buff: %s / %s", id, tostring(HUDList.TeamBuffItem.BUFF_LEVELS[id]))
        --end
    end
    return level
end

function HUDList.TeamBuffItem:set_buff_active(...)
    HUDList.TeamBuffItem.super.set_buff_active(self, ...)
    self:_update_value_text()
end

function HUDList.TeamBuffItem:_update_value_text()
    local value = self._show_value(self, self._member_data)
    self._value_text:set_text(value > 0 and tostring_trimmed(value) or "")
end


HUDList.TimedBuffItem = HUDList.TimedBuffItem or class(HUDList.BuffItemBase)
function HUDList.TimedBuffItem:init(id, ppanel, members, item_data)
    self._timed = true
    HUDList.TimedBuffItem.super.init(self, id, ppanel, members, item_data)

    table.insert(self._listener_clbks, {
        name = string.format("HUDList_buff_listener_%s", id),
        source = "buff",
        event = { "set_duration" },
        clbk = callback(self, self, "_set_duration_clbk"),
        keys = members,
    })
end


HUDList.TimedStackBuffItem = HUDList.TimedStackBuffItem or class(HUDList.TimedBuffItem)
function HUDList.TimedStackBuffItem:init(id, ppanel, members, item_data)
    self._show_stack_count = self._show_stack_count_function
    self._stack_count = 0
    HUDList.TimedStackBuffItem.super.init(self, id, ppanel, members, item_data)

    local listener_id = string.format("HUDList_buff_listener_%s", id)
    local events = {
        add_timed_stack = callback(self, self, "_stack_changed_clbk"),
        remove_timed_stack = callback(self, self, "_stack_changed_clbk"),
    }

    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = members })
    end
end

function HUDList.TimedStackBuffItem:apply_current_values(id, data)
    HUDList.TimedStackBuffItem.super.apply_current_values(self, id, data)

    if data then
        if data.stacks then
            self:_stack_changed_clbk("add_timed_stack", id, data)
        end
    end
end

function HUDList.TimedStackBuffItem._show_stack_count_function(item, buffs)
    return item._stack_count or 0
end

function HUDList.TimedStackBuffItem:_stack_changed_clbk(event, id, data)
    --This is a simplification which assumes only one buff is present with timed stacks, which is the case currently for grinder/biker
    self._stacks = data.stacks
    self._stack_count = table.size(self._stacks)

    self._member_data[id].stacks = data.stacks
    self:_update_expire_data()
    self:_update_stack_count()
end

function HUDList.TimedStackBuffItem:_update_expire_data()
    self._expire_data = {}

    local min_t, min_expire_t, max_t, max_expire_t
    local debuff_t, debuff_expire_t

    if self._stack_count > 0 then
        for _, data in pairs(self._stacks) do
            if data.expire_t then
                if not max_expire_t or data.expire_t > max_expire_t then
                    max_t = data.t
                    max_expire_t = data.expire_t
                end
                if not min_expire_t or data.expire_t < min_expire_t then
                    min_t = data.t
                    min_expire_t = data.expire_t
                end
            end
        end

        if min_expire_t then
            table.insert(self._expire_data, { t = min_t, expire_t = min_expire_t })
            if max_expire_t ~= min_expire_t then
                table.insert(self._expire_data, { t = max_t, expire_t = max_expire_t })
            end
        end
    end

    if #self._active_debuffs > 0 then
        for _, id in ipairs(self._active_debuffs) do
            local data = self._member_data[id]

            if data.expire_t and data.t then
                if not debuff_expire_t or data.expire_t > debuff_expire_t then
                    debuff_t = data.t
                    debuff_expire_t = data.expire_t
                end
            end
        end

        if debuff_expire_t then
            table.insert(self._expire_data, { t = debuff_t, expire_t = debuff_expire_t, is_debuff = true })
        end
    end

    for i, progress_bar in ipairs(self._progress_bars) do
        local expire_data = self._expire_data[i]
        progress_bar:panel():set_visible(expire_data and true or false)
        progress_bar:set_color(expire_data and expire_data.is_debuff and self.BUFF_COLORS.debuff or self._standard_color)
    end

    self:_set_icon_color((debuff_expire_t and (not min_expire_t or min_expire_t > debuff_expire_t)) and self._debuff_color or self._standard_color)
end

HUDList.BikerBuffItem = HUDList.BikerBuffItem or class(HUDList.TimedStackBuffItem)
function HUDList.BikerBuffItem:_stack_changed_clbk(...)
    HUDList.BikerBuffItem.super._stack_changed_clbk(self, ...)
    self:_set_icon_color((self._stack_count >= tweak_data.upgrades.wild_max_triggers_per_time) and self._debuff_color or self._standard_color)
end

HUDList.CompositeBuffItemBase = HUDList.CompositeBuffItemBase or class(HUDList.TimedBuffItem)
function HUDList.CompositeBuffItemBase:init(...)
    self._show_value = self._show_value_function
    HUDList.CompositeBuffItemBase.super.init(self, ...)
end

function HUDList.CompositeBuffItemBase:set_buff_active(...)
    HUDList.CompositeBuffItemBase.super.set_buff_active(self, ...)
    self:_update_value_text()
end

HUDList.DamageReductionBuffItem = HUDList.DamageReductionBuffItem or class(HUDList.CompositeBuffItemBase)
HUDList.DamageReductionBuffItem.EXCLUSIVE_BUFFS = {
    combat_medic_success = "combat_medic_interaction"
}
function HUDList.DamageReductionBuffItem._show_value_function(item, buffs)
    local v = 1
    for id, data in pairs(buffs) do
        local exclusive_buff = item.EXCLUSIVE_BUFFS[id]
        if not (exclusive_buff and buffs[exclusive_buff].active) then
            v = v * (data.active and data.value or 1)
        end
    end
    return v
end

function HUDList.DamageReductionBuffItem:_update_value_text()
    local str = tostring_trimmed(self._show_value(self, self._member_data), 2)
    self._value_text:set_text(string.format("x%s", str))
end

HUDList.DamageIncreaseBuffItem = HUDList.DamageIncreaseBuffItem or class(HUDList.CompositeBuffItemBase)
HUDList.DamageIncreaseBuffItem.WEAPON_REQUIREMENT = {
    include = {
        overkill = { shotgun = true, saw = true },
        berserker = { saw = true },
    },
    exclude = {
        overkill_aced = { shotgun = true, saw = true },
        berserker_aced = { saw = true },
    },
}
function HUDList.DamageIncreaseBuffItem:init(...)
    HUDList.DamageIncreaseBuffItem.super.init(self, ...)

    table.insert(self._listener_clbks, {
        name = "HUDList_DamageIncreaseBuffItem_weapon_equipped_listener",
        source = "player_weapon",
        event = { "equip" },
        clbk = callback(self, self, "_update_value_text"),
        data_only = true,
    })
end

function HUDList.DamageIncreaseBuffItem._show_value_function(item, buffs)
    local weapon = managers.player:equipped_weapon_unit()

    if alive(weapon) then
        local categories = weapon:base():weapon_tweak_data().categories
        local value = 1

        for buff, data in pairs(buffs) do
            local include_data = item.WEAPON_REQUIREMENT.include[buff]
            local exclude_data = item.WEAPON_REQUIREMENT.exclude[buff]
            local include = not include_data
            local exclude = false

            if include_data then
                for _, category in ipairs(categories) do
                    include = include or include_data[category]
                end
            end

            if exclude_data then
                for _, category in ipairs(categories) do
                    exclude = exclude or exclude_data[category]
                end
            end

            if include and not exclude then
                value = value * (data.active and data.value or 1)
            end
        end

        return value, tweak and tweak.ignore_damage_upgrades
    end

    return 1
end

function HUDList.DamageIncreaseBuffItem:_update_value_text()
    local value, ignores_upgrades = self._show_value(self, self._member_data)
    local str = tostring_trimmed(value, 2)

    local text = string.format("x%s", str)
    if ignores_upgrades then
        text = string.format("(%s)", text)
    end

    self._value_text:set_text(text)
end

HUDList.MeleeDamageIncreaseBuffItem = HUDList.MeleeDamageIncreaseBuffItem or class(HUDList.CompositeBuffItemBase)
function HUDList.MeleeDamageIncreaseBuffItem._show_value_function(item, buffs)
    local v = 1
    for id, data in pairs(buffs) do
        v = v * (data.active and data.value or 1)
    end
    return v
end

function HUDList.MeleeDamageIncreaseBuffItem:_update_value_text()
    local str = tostring_trimmed(self._show_value(self, self._member_data), 2)
    self._value_text:set_text(string.format("x%s", str))
end

HUDList.HealthRegenBuffItemBase = HUDList.HealthRegenBuffItemBase or class(HUDList.CompositeBuffItemBase)
function HUDList.HealthRegenBuffItemBase:_update_value_text()
    local str = tostring_trimmed(self._show_value(self, self._member_data) * 100, 5)
    self._value_text:set_text(string.format("+%s%%", str))
end


HUDList.PlayerActionItemBase = HUDList.PlayerActionItemBase or class(HUDList.EventItemBase)
HUDList.PlayerActionItemBase.MAP = {
    anarchist_armor_regeneration = {
        perks = {0, 0}, bundle_folder = "opera",
        priority = 15,
    },
    standard_armor_regeneration = {
        perks = {6, 0},
        class = "ArmorRegenActionItem",
        priority = 15,
    },
    melee_charge = {
        skills = { 4, 10 },
        priority = 15,
        title = "M.Charge",
        delay = 0.5,
        invert = true,
    },
    weapon_charge = {
        texture = "guis/dlcs/west/textures/pd2/blackmarket/icons/weapons/plainsrider",
        icon_rotation = 90,
        icon_ratio = 0.75,
        priority = 15,
        title = "W.Charge",
        delay = 0.5,
        invert = true,
    },
    reload = {
        skills_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
        priority = 15,
        title = "Reload",
        min_duration = 0.25,
    },
    interact = {
        skills_new = tweak_data.skilltree.skills.second_chances.icon_xy,
        priority = 15,
        title = "Interact",
        min_duration = 0.5,
    },
}	
function HUDList.PlayerActionItemBase:init(id, ppanel, action_data, item_data)
    HUDList.PlayerActionItemBase.super.init(self, id, ppanel, { h = ppanel:h(), w = ppanel:h() * 0.6, priority = -item_data.priority })
    
    self:set_fade_rate(100)
    self:set_move_rate(nil)
    
    self._min_duration = item_data.min_duration
    self._delay = item_data.delay
    self._standard_color = Color.white
    
    local icon_size = self._panel:w() - HUDList.BuffItemBase.PROGRESS_BAR_WIDTH * 3 - 5
    local texture, texture_rect = get_icon_data(item_data)
    
    self._icon = self._panel:bitmap({
        texture = texture,
        texture_rect = texture_rect,
        h = icon_size * 1/(item_data.icon_ratio or 1),
        w = icon_size * (item_data.icon_ratio or 1),
        color = self._standard_color,
        rotation = item_data.icon_rotation or 0,
    })
    self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
    
    self._bg = self._panel:rect({
        h = icon_size,
        w = icon_size,
        layer = -10,
        color = Color.black,
        alpha = 0.2,
    })
    self._bg:set_center(self._icon:center())
    
    self._progress_bar = PanelFrame:new(self._panel, { 
        bar_w = self.PROGRESS_BAR_WIDTH, 
        w = icon_size,
        h = icon_size,
        visible = true,
        invert_progress = item_data.invert,
    })
    self._progress_bar:panel():set_center(self._icon:center())
    
    local text_h = (self._panel:h() - icon_size) / 2
    self._value_text = self._panel:text({
        align = "center",
        vertical = "bottom",
        w = self._panel:w(),
        h = text_h,
        font = tweak_data.hud_corner.assault_font,
        font_size = 0.7 * text_h,
    })
    self._value_text:set_bottom(self._panel:h())
    
    if item_data.title then
        local h = (self._panel:h() - icon_size) / 2
        
        self._title_text = self._panel:text({
            text = item_data.title,
            align = "center",
            vertical = "top",
            w = self._panel:w(),
            h = h,
            font = tweak_data.hud_corner.assault_font,
            font_size = 0.7 * h,
        })
    end
    
    self:_set_duration_clbk(action_data)
    
    local listener_id = string.format("HUDList_buff_listener_%s", id)
    local events = {
        set_duration = callback(self, self, "_set_duration_clbk")
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "player_action", event = { event }, clbk = clbk, keys = { id }, data_only = true })
    end
end

function HUDList.PlayerActionItemBase:update(t, dt)
    if self._delayed_activation_t and t > self._delayed_activation_t then
        self._delayed_activation_t = nil
        self:enable("delayed_enable")
    end

    if self:visible() then
        if self._t and self._expire_t then
            local total = self._expire_t - self._t
            local current = t - self._t
            local remaining = total - current
            
            self._progress_bar:set_ratio(current/total)
            
            if remaining <= 0 then
                self._t = nil
                self._expire_t = nil
                self._value_text:set_text("")
            else
                self._value_text:set_text(format_time_string(remaining))
            end
        end
    end
    
    return HUDList.PlayerActionItemBase.super.update(self, t, dt)
end

function HUDList.PlayerActionItemBase:_set_duration_clbk(data)
    self._t = data.t
    self._expire_t = data.expire_t
    
    if self._t and self._expire_t then
        if self._delay then
            self._delayed_activation_t = self._t + self._delay
        end
        
        if self._min_duration and self._min_duration < (self._expire_t - self._t) then
            self:enable("insufficient_duration")
        end
    end
end

HUDList.ArmorRegenActionItem = HUDList.ArmorRegenActionItem or class(HUDList.PlayerActionItemBase)
function HUDList.ArmorRegenActionItem:init(...)
    HUDList.ArmorRegenActionItem.super.init(self, ...)
    
    local listener_id = "HUDList_armor_regen_tooth_and_claw_listener"
    local events = {
        --activate = callback(self, self, "_tooth_and_claw_event"),
        deactivate = callback(self, self, "_tooth_and_claw_event"),
        set_duration = callback(self, self, "_tooth_and_claw_event"),
    }
    
    for event, clbk in pairs(events) do
        table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = { "tooth_and_claw" } })
    end
end

function HUDList.ArmorRegenActionItem:_set_duration_clbk(...)
    HUDList.ArmorRegenActionItem.super._set_duration_clbk(self, ...)
    self._standard_expire_t = self._expire_t
    self._standard_t = self._t
    self:_check_max_expire_t()
end

function HUDList.ArmorRegenActionItem:_tooth_and_claw_event(event, id, data)
    self._forced_t = (event ~= "deactivate") and data.t or nil
    self._forced_expire_t = (event ~= "deactivate") and data.expire_t or nil
    self:_check_max_expire_t()
end

function HUDList.ArmorRegenActionItem:_check_max_expire_t()
    if self._expire_t and self._forced_expire_t then
        if self._forced_expire_t < self._standard_expire_t then
            self._expire_t = self._forced_expire_t
            self._t = self._forced_t
        end
    end
end

--Custom buffs
HUDList.AITimedBuffItem = HUDList.AITimedBuffItem or class(HUDList.BuffItemBase)
function HUDList.AITimedBuffItem:init(id, ppanel, members, item_data)
    self._timed = true
    HUDList.AITimedBuffItem.super.init(self, id, ppanel, members, item_data)

    if item_data.title then
        local icon_size = self._panel:w() - HUDList.BuffItemBase.PROGRESS_BAR_WIDTH * 3 - 5
        local h = (self._panel:h() - icon_size) / 2
        
        self._title_text = self._panel:text({
            text = item_data.title,
            align = "center",
            vertical = "top",
            w = self._panel:w(),
            h = h,
            font = tweak_data.hud_corner.assault_font,
            font_size = 0.7 * h,
        })
    end
    
    table.insert(self._listener_clbks, {
        name = string.format("HUDList_buff_listener_%s", id),
        source = "buff",
        event = { "set_duration" },
        clbk = callback(self, self, "_set_duration_clbk"),
        keys = members,
    })
end