--[[
   _____           __                 __  ____  ______
  / ___/__  ______/ /___  ___  __  __/ / / / / / / __ \        ____
  \__ \/ / / / __  / __ \/ _ \/ / / / /_/ / / / / / / /	 _  __/ / /
 ___/ / /_/ / /_/ / / / /  __/ /_/ / __  / /_/ / /_/ /	| |/ /_  _/
/____/\__, /\__,_/_/ /_/\___/\__, /_/ /_/\____/_____/	|___/ /_/
     /____/                 /____/

        All-In-One mod for PAYDAY2      Developed by SydneyMOD Team
]]


if not Steam then
    return
end

--[[
    We setup the global table for our mod, along with some path variables, and a data table.
    We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
        different mod.
]]
SydneyHUD = SydneyHUD or {}
if not SydneyHUD.setup then

    --[[
        Alias for EZ to write log

        Info: Information Log. Something succeeded.
        Warn: Warning Log. Something Errored, but can keep working.
        Error: Error Log. Something Errored. Can not keep working.
        Dev: Develop Log. Printing var, Breakpoint.
    ]]
    SydneyHUD.info = "[SydneyHUD Info] "
    SydneyHUD.warn = "[SydneyHUD Warn] "
    SydneyHUD.error = "[SydneyHUD Error] "
    SydneyHUD.dev = "[SydneyHUD Dev] "

    -- var for script
    SydneyHUD._last_removed_time = 0

    SydneyHUD._down_count = {}

    SydneyHUD._language =
    {
        [1] = "english",
        [2] = "japanese",
        [3] = "french",
        [4] = "russian",
        [5] = "portuguese"
    }

    -- var for util
    SydneyHUD.assets_path = "./assets/mod_overrides/"
    SydneyHUD._path = ModPath
    SydneyHUD._lua_path = ModPath .. "lua/"
    SydneyHUD._data_path = SavePath .. "SydneyHUD.json"
    SydneyHUD._poco_path = SavePath .. "hud3_config.json"
    SydneyHUD._data = {}
    SydneyHUD._menus = {
        "sydneyhud_options",
        "sydneyhud_core",

        "sydneyhud_gadget_options",
        "sydneyhud_gadget_options_sniper",
        "sydneyhud_gadget_options_turret",

        "sydneyhud_hudlist_options",
        "sydneyhud_hudlist_options_left",
        "sydneyhud_hudlist_options_right",
        "sydneyhud_hudlist_options_right_not_ignore",
        "sydneyhud_hudlist_options_buff",
        "sydneyhud_hudlist_options_buff_options",
        "sydneyhud_hudlist_options_buff_options_buff",
        "sydneyhud_hudlist_options_buff_options_skills",
        "sydneyhud_hudlist_options_buff_options_skills_mastermind",
        "sydneyhud_hudlist_options_buff_options_skills_enforcer",
        "sydneyhud_hudlist_options_buff_options_skills_technician",
        "sydneyhud_hudlist_options_buff_options_skills_ghost",
        "sydneyhud_hudlist_options_buff_options_skills_fugitive",
        "sydneyhud_hudlist_options_buff_options_composite",
        "sydneyhud_hudlist_options_buff_options_perks",
        "sydneyhud_hudlist_options_buff_options_perks_crew_chief",
        "sydneyhud_hudlist_options_buff_options_perks_muscle",
        "sydneyhud_hudlist_options_buff_options_perks_armorer",
        "sydneyhud_hudlist_options_buff_options_perks_hitman",
        "sydneyhud_hudlist_options_buff_options_perks_infiltrator",
        "sydneyhud_hudlist_options_buff_options_perks_sociopath",
        "sydneyhud_hudlist_options_buff_options_perks_gambler",
        "sydneyhud_hudlist_options_buff_options_perks_grinder",
        "sydneyhud_hudlist_options_buff_options_perks_yakuza",
        "sydneyhud_hudlist_options_buff_options_perks_maniac",
        "sydneyhud_hudlist_options_buff_options_perks_anarchist",
        "sydneyhud_hudlist_options_buff_options_perks_biker",
        "sydneyhud_hudlist_options_buff_options_perks_kingpin",
        "sydneyhud_hudlist_options_buff_options_perks_sicario",
        "sydneyhud_hudlist_options_buff_options_perks_stoic",
        "sydneyhud_hudlist_options_buff_options_perks_hacker",
        "sydneyhud_hudlist_options_buff_options_boosts",
        "sydneyhud_hudlist_options_buff_player_actions",
        "sydneyhud_hudlist_options_civilian_color",
        "sydneyhud_hudlist_options_enemy_color",

        "sydneyhud_chat_info",
        "sydneyhud_experimental",
        "sydneyhud_gameplay_tweaks",
        "sydneyhud_hps_meter",
        "sydneyhud_interact_tweaks",
        "sydneyhud_kill_counter_options",
        "sydneyhud_menu_tweaks",

        "sydneyhud_hud_tweaks",
        "sydneyhud_hud_tweaks_assault",
        "sydneyhud_hud_tweaks_interact",
        "sydneyhud_hud_tweaks_name",
        "sydneyhud_hud_tweaks_panel",
        "sydneyhud_hud_tweaks_waypoint"
    }
    SydneyHUD._hook_files = {
        ["lib/entry"] = "lib/Entry.lua",
        ["lib/managers/chatmanager"] = "lib/managers/ChatManager.lua",
        ["lib/managers/enemymanager"] = "lib/managers/EnemyManager.lua",
        ["lib/managers/group_ai_states/groupaistatebase"] = "lib/managers/group_ai_states/GroupAIStateBase.lua",
        ["lib/managers/hud/hudassaultcorner"] = "lib/managers/hud/HUDAssaultCorner.lua",
        ["lib/managers/hud/hudinteraction"] = "lib/managers/hud/HUDInteraction.lua",
        ["lib/managers/hud/hudstatsscreen"] = "lib/managers/hud/HUDStatsScreen.lua",
        ["lib/managers/hud/hudsuspicion"] = "lib/managers/hud/HUDSuspicion.lua",
        ["lib/managers/hud/hudteammate"] = "lib/managers/hud/HUDTeammate.lua",
        ["lib/managers/hudmanager"] = "lib/managers/HUDManager.lua",
        ["lib/managers/hudmanagerpd2"] = "lib/managers/HUDManagerPD2.lua",
        ["lib/managers/menu/blackmarketgui"] = "lib/managers/menu/BlackMarketGUI.lua",
        ["lib/managers/menu/contractboxgui"] = "lib/managers/menu/ContractBoxGui.lua",
        ["lib/managers/menu/lootdropscreengui"] = "lib/managers/menu/LootDropScreenGui.lua",
        ["lib/managers/menu/menubackdropgui"] = "lib/managers/menu/MenuBackDropGUI.lua",
        ["lib/managers/menu/menucomponentmanager"] = "lib/managers/menu/MenuComponentManager.lua",
        ["lib/managers/menu/menunodegui"] = "lib/managers/menu/MenuNodeGui.lua",
        ["lib/managers/menu/menuscenemanager"] = "lib/managers/menu/MenuSceneManager.lua",
        ["lib/managers/menu/missionbriefinggui"] = "lib/managers/menu/MissionBriefingGui.lua",
        ["lib/managers/menu/stageendscreengui"] = "lib/managers/menu/StageEndScreenGui.lua",
        ["lib/managers/menumanager"] = "lib/managers/MenuManager.lua",
        ["lib/managers/missionassetsmanager"] = "lib/managers/MissionAssetsManager.lua",
        ["lib/managers/moneymanager"] = "lib/managers/MoneyManager.lua",
        ["lib/managers/objectinteractionmanager"] = "lib/managers/ObjectInteractionManager.lua",
        ["lib/managers/playermanager"] = "lib/managers/PlayerManager.lua",
        ["lib/managers/trademanager"] = "lib/managers/TradeManager.lua",
        ["lib/modifiers/boosts/gagemodifierlifesteal"] = "lib/modifiers/boosts/GageModifierLifeSteal.lua",
        ["lib/modifiers/boosts/gagemodifiermeleeinvincibility"] = "lib/modifiers/boosts/GageMeleeModifierInvincibility.lua",
        ["lib/network/base/handlers/connectionnetworkhandler"] = "lib/network/base/handlers/ConnectionNetworkHandler.lua",
        ["lib/network/base/networkpeer"] = "lib/network/base/NetworkPeer.lua",
        ["lib/network/handlers/unitnetworkhandler"] = "lib/network/handlers/UnitNetworkHandler.lua",
        ["lib/player_actions/skills/playeractionammoefficiency"] = "lib/player_actions/skills/PlayerActionAmmoEfficiency.lua",
        ["lib/player_actions/skills/playeractionbloodthirstbase"] = "lib/player_actions/skills/PlayerActionBloodthirstBase.lua",
        ["lib/player_actions/skills/playeractiondireneed"] = "lib/player_actions/skills/PlayerActionDireNeed.lua",
        ["lib/player_actions/skills/playeractionexperthandling"] = "lib/player_actions/skills/PlayerActionExpertHandling.lua",
        ["lib/player_actions/skills/playeractionshockandawe"] = "lib/player_actions/skills/PlayerActionShockAndAwe.lua",
        ["lib/player_actions/skills/playeractiontriggerhappy"] = "lib/player_actions/skills/PlayerActionTriggerHappy.lua",
        ["lib/player_actions/skills/playeractionunseenstrike"] = "lib/player_actions/skills/PlayerActionUnseenStrike.lua",
        ["lib/setups/setup"] = "lib/setups/Setup.lua",
        ["lib/states/ingamewaitingforplayers"] = "lib/states/IngameWaitingForPlayersState.lua",
        ["lib/tweak_data/charactertweakdata"] = "lib/tweak_data/CharacterTweakData.lua",
        ["lib/tweak_data/playertweakdata"] = "lib/tweak_data/PlayerTweakData.lua",
        ["lib/units/beings/player/huskplayermovement"] = "lib/units/beings/player/HuskPlayerMovement.lua",
        ["lib/units/beings/player/playerdamage"] = "lib/units/beings/player/PlayerDamage.lua",
        ["lib/units/beings/player/playerinventory"] = "lib/units/beings/player/PlayerInventory.lua",
        ["lib/units/beings/player/playermovement"] = "lib/units/beings/player/PlayerMovement.lua",
        ["lib/units/beings/player/states/playerbleedout"] = "lib/units/beings/player/states/PlayerBleedOut.lua",
        ["lib/units/beings/player/states/playercarry"] = "lib/units/beings/player/states/PlayerCarry.lua",
        ["lib/units/beings/player/states/playercivilian"] = "lib/units/beings/player/states/PlayerCivilian.lua",
        ["lib/units/beings/player/states/playerdriving"] = "lib/units/beings/player/states/PlayerDriving.lua",
        ["lib/units/beings/player/states/playermaskoff"] = "lib/units/beings/player/states/PlayerMaskOff.lua",
        ["lib/units/beings/player/states/playerstandard"] = "lib/units/beings/player/states/PlayerStandard.lua",
        ["lib/units/enemies/cop/copdamage"] = "lib/units/enemies/cop/CopDamage.lua",
        ["lib/units/equipment/ammo_bag/ammobagbase"] = "lib/units/equipment/ammo_bag/AmmoBagBase.lua",
        ["lib/units/equipment/bodybags_bag/bodybagsbagbase"] = "lib/units/equipment/bodybags_bag/BodyBagBase.lua",
        ["lib/units/equipment/doctor_bag/doctorbagbase"] = "lib/units/equipment/doctor_bag/DoctorBagBase.lua",
        ["lib/units/equipment/ecm_jammer/ecmjammerbase"] = "lib/units/equipment/ecm_jammer/ECMJammerBase.lua",
        ["lib/units/equipment/grenade_crate/grenadecratebase"] = "lib/units/equipment/grenade_crate/GrenadeCrateBase.lua",
        ["lib/units/equipment/sentry_gun/sentrygunbase"] = "lib/units/equipment/sentry_gun/SentryGunBase.lua",
        ["lib/units/equipment/sentry_gun/sentrygundamage"] = "lib/units/equipment/sentry_gun/SentryGunDamage.lua",
        ["lib/units/interactions/interactionext"] = "lib/units/interactions/InteractionExt.lua",
        ["lib/units/props/digitalgui"] = "lib/units/props/DigitalGui.lua",
        ["lib/units/props/securitycamera"] = "lib/units/props/SecurityCamera.lua",
        ["lib/units/props/securitylockgui"] = "lib/units/props/SecurityLockGui.lua",
        ["lib/units/props/timergui"] = "lib/units/props/TimerGui.lua",
        ["lib/units/weapons/newraycastweaponbase"] = "lib/units/weapons/NewRayCastWeaponBase.lua",
        ["lib/units/weapons/sentrygunweapon"] = "lib/units/weapons/SentryGunWeapon.lua",
        ["lib/units/weapons/weaponflashlight"] = "lib/units/weapons/WeaponFlashlight.lua",
        ["lib/units/weapons/weaponlaser"] = "lib/units/weapons/WeaponLaser.lua",
        ["lib/utils/propertymanager"] = "lib/utils/PropertyManager.lua",
        ["lib/utils/temporarypropertymanager"] = "lib/utils/TemporaryPropertyManager.lua"
    }
    SydneyHUD._poco_conflicting_defaults = {
        buff = {
            mirrorDirection = true,
            showBoost = true,
            showCharge = true,
            showECM = true,
            showInteraction = true,
            showReload = true,
            showShield = true,
            showStamina = true,
            showSwanSong = true,
            showTapeLoop = true,
            simpleBusyIndicator = true
        },
        game = {
            interactionClickStick = true
        },
        playerBottom = {
            showRank = true,
            uppercaseNames = true
        }
    }

    --[[
        A simple save function that json encodes our _data table and saves it to a file.
    ]]
    function SydneyHUD:Save()
        local file = io.open(self._data_path, "w+")
        if file then
            file:write(json.encode(self._data))
            file:close()
        end
    end

    --[[
        A simple load function that decodes the saved json _data table if it exists.
    ]]
    function SydneyHUD:Load()
        self:LoadDefaults()
        local file = io.open(self._data_path, "r")
        if file then
            for k, v in pairs(json.decode(file:read("*all"))) do
                if self._data[k] ~= nil then
                    self._data[k] = v
                end
            end
            file:close()
        end
        self:CheckPoco()
    end

    function SydneyHUD:GetOption(id)
        return self._data[id]
    end

    function SydneyHUD:GetModOption(mod_name, id)
        return self:GetOption(mod_name .. "_" .. id)
    end

    function SydneyHUD:GetHUDListItemOption(item_name)
        return not self:GetOption("hudlist_not_ignore_item_" .. item_name)
    end

    function SydneyHUD:GetHUDListBuffOption(buff_name)
        return not self:GetOption("hudlist_not_ignore_buff_" .. buff_name)
    end

    function SydneyHUD:GetHUDListPlayerActionOption(action_name)
        return not self:GetOption("hudlist_not_ignore_player_action_" .. action_name)
    end

    function SydneyHUD:LoadDefaults()
        local default_file = io.open(self._path .."menu/default_values.json")
        self._data = json.decode(default_file:read("*all"))
        default_file:close()
    end

    function SydneyHUD:InitAllMenus()
        for _, menu in pairs(self._menus) do
            MenuHelper:LoadFromJsonFile(self._path .. "menu/" .. menu .. ".json", self, self._data)
        end
    end

    function SydneyHUD:ForceReloadAllMenus()
        for _,menu in pairs(self._menus) do
            for _,_item in pairs(MenuHelper:GetMenu(menu)._items_list) do
                if _item._type == "toggle" then
                    _item.selected = self._data[_item._parameters.name] and 1 or 2
                elseif _item._type == "multi_choice" then
                    _item._current_index = self._data[_item._parameters.name]
                elseif _item._type == "slider" then
                    _item._value = self._data[_item._parameters.name]
                end
            end
        end
    end

    function SydneyHUD:CheckPoco()
        local file = io.open(self._poco_path)
        if file then
            self._poco_conf = json.decode(file:read("*all"))
            file:close()
        end
    end

    function SydneyHUD:ApplyFixedPocoSettings()
        local file = io.open(self._poco_path, "w+")
        if file and self._fixed_poco_conf then
            file:write(json.encode(self._fixed_poco_conf))
            file:close()
            local menu_title = managers.localization:text("sydneyhud_pocohud_config_fixed")
            local menu_message = managers.localization:text("sydneyhud_pocohud_confix_fixed_desc")
            local menu_options = {
                [1] = {
                    text = managers.localization:text("sydneyhud_pocohud_i_understand"),
                    is_cancel_button = true,
                }
            }
            QuickMenu:new(menu_title, menu_message, menu_options, true)
        end
    end

    function SydneyHUD:SafeDoFile(fileName)
        local success, errorMsg = pcall(function()
            if io.file_is_readable(fileName) then
                dofile(fileName)
            else
                log(SydneyHUD.error .. "Can't open file '" .. fileName .. "'!")
            end
        end)
        if not success then
            log(SydneyHUD.error .. "File: " .. fileName .. "\n" .. errorMsg)
        end
    end

    function SydneyHUD:MakeOutlineText(panel, bg, txt)
        bg.name = nil
        local bgs = {}
        for i = 1, 4 do
            table.insert(bgs, panel:text(bg))
        end
        bgs[1]:set_x(txt:x() - 1)
        bgs[1]:set_y(txt:y() - 1)
        bgs[2]:set_x(txt:x() + 1)
        bgs[2]:set_y(txt:y() - 1)
        bgs[3]:set_x(txt:x() - 1)
        bgs[3]:set_y(txt:y() + 1)
        bgs[4]:set_x(txt:x() + 1)
        bgs[4]:set_y(txt:y() + 1)
        return bgs
    end

    function SydneyHUD:GetVersion()
        for _, mod in ipairs(BLT.Mods:Mods()) do
            if mod:GetName() == "SydneyHUD" then -- I don't understand, why BLT is checking every mod it's identifier (mod folder name) and not mod name defined in mod.txt
                return tostring(mod:GetVersion() or "(n/a)")
            end
        end
        return "(n/a)"
    end

    function SydneyHUD:SendChatMessage(name, message, isfeed, color)
        if not message then
            message = name
            name = ""
        end
        if not isfeed then
            isfeed = false
        end
        isfeed = isfeed or false
        --[[
        if not tostring(color):find('Color') then
            color = nil
        end
        --]]
        if color and #color == 6 then
            color = Color(color)
        end

        message = tostring(message)
        --if managers and managers.chat and managers.chat._receives and managers.chat._receivers[1] then
            for __, rcvr in pairs(managers.chat._receivers[1]) do
                rcvr:receive_message(name or "*", message, color or tweak_data.chat_colors[5])
            end
        --end
        if Network:is_server() and isfeed then
            local num_player_slots = BigLobbyGlobals and BigLobbyGlobals:num_player_slots() or 4
            for i=2,num_player_slots do
                local peer = managers.network:session():peer(i)
                if peer then
                    peer:send("send_chat_message", ChatManager.GAME, name .. ": " .. message)
                end
            end
        end
    end

    function SydneyHUD:Replenish(peer_id)
        local peer = managers.network:session():peer(peer_id)
        if peer then
            local down = "down"
            -- NOTE: Add existence check of _down_count (can be nil when not downed)
            if self._down_count[peer_id] and self._down_count[peer_id] > 1 then
                down = "downs"
            end
            -- NOTE: Display 0 instead of nil
            local message = peer:name() .. " +" .. tostring(self._down_count[peer_id] or 0) .. " " .. down
            local is_feed = SydneyHUD:GetOption("replenished_chat_info_feed")
            if SydneyHUD:GetOption("replenished_chat_info") then
                self:SendChatMessage("Replenished", message, is_feed, "00ff04")
            end
            self._down_count[peer_id] = 0
        end
    end

    function SydneyHUD:Down(peer_id, local_peer)
        local peer = managers.network:session():peer(peer_id)
        if peer then
            local warn_down = 3

            if Global.game_settings.one_down then
                warn_down = 1
            end

            if local_peer then
                local nine_lives = managers.player:upgrade_value('player', 'additional_lives', 0) or 0
                warn_down = warn_down + nine_lives
            end

            if not SydneyHUD._down_count[peer_id] then
                SydneyHUD._down_count[peer_id] = 1
            else
                SydneyHUD._down_count[peer_id] = SydneyHUD._down_count[peer_id] + 1
            end

            if SydneyHUD._down_count[peer_id] == warn_down and SydneyHUD:GetOption("critical_down_warning_chat_info") then
                local message = peer:name() .. " was downed " .. tostring(SydneyHUD._down_count[peer_id]) .. " times"
                local is_feed = SydneyHUD:GetOption("critical_down_warning_chat_info_feed")
                self:SendChatMessage("Warning!", message, is_feed, "ff0000")
            elseif SydneyHUD:GetOption("down_warning_chat_info") then
                local message = peer:name() .. " was downed (" .. tostring(SydneyHUD._down_count[peer_id]) .. "/" .. warn_down .. ")"
                local is_feed = SydneyHUD:GetOption("down_warning_chat_info_feed")
                self:SendChatMessage("Warning", message, is_feed, "ff0000")
            end
        end
    end

    function SydneyHUD:Custody(criminal_name, local_peer)
        local peer_id = criminal_name
        if not local_peer then
            for __, data in pairs(managers.criminals._characters) do
                if data.token and criminal_name == data.name then
                    peer_id = data.peer_id
                    break
                end
            end
        end
        local peer = managers.network:session():peer(peer_id)
        if peer then
            SydneyHUD._down_count[peer_id] = 0
        end
    end

    function SydneyHUD:Peer_id_To_Peer(peer_id)
        local session = managers.network:session()
        return session and session:peer(peer_id) or nil
    end

    function SydneyHUD:Peer(input)
        local t = type(input)
        if t == 'userdata' then
            return alive(input) and input:network():peer()
        elseif t == 'number' then
            return self:Peer_id_To_Peer(input)
        elseif t == 'string' then
            return self:Peer(managers.criminals:character_peer_id_by_name(input))
        end
    end

    function SydneyHUD:Peer_Info(input)
        local peer = self:Peer(input)
        return peer and peer:id() or 0
    end

    function SydneyHUD:CreatePanel()
        if self._panel or not managers.menu_component then
            return
        end
        self._panel = managers.menu_component._ws:panel():panel()
    end

    function SydneyHUD:DestroyPanel()
        if not alive(self._panel) then
            return
        end
        self._panel:clear()
        self.color_box = nil
        self.color_box_2 = nil
        self.color_box_3 = nil
        self.text_box = nil
        self.text_box_2 = nil
        self.text_box_3 = nil
        self._panel:parent():remove(self._panel)
        self._panel = nil
    end

    function SydneyHUD:CreateBitmaps()
        if alive(self._panel) and not self.color_box then
            self.color_box = self:CreateBitmap(Color.white, 0.10)
            self.color_box_2 = self:CreateBitmap(Color.white, 0.20)
            self.color_box_3 = self:CreateBitmap(Color.white, 0.30)
        end
    end

    function SydneyHUD:CreateTexts()
        if alive(self._panel) and not self.text_box then
            self.text_box = self:CreateText(self:GetText("enable_laser_options_turret"), 0.12, 0.25)
            self.text_box_2 = self:CreateText(self:GetText("enable_laser_options_turretr"), 0.22, 0.25)
            self.text_box_3 = self:CreateText(self:GetText("enable_laser_options_turretm"), 0.32, 0.25)
        end
    end

    function SydneyHUD:GetText(text)
        return managers.localization:text(text) .. ":"
    end

    function SydneyHUD:MakeFineText(text)
        local x, y, w, h = text:text_rect()
    
        text:set_size(w, h)
        text:set_position(math.round(text:x()), math.round(text:y()))
    end

    function SydneyHUD:CreateText(text, x, y)
        local txt = self._panel:text({
            h = 0, -- This value changes during text resize
            w = 0, -- This one also
            valign = 'center',
            halign = 'center',
            font = tweak_data.menu.pd2_large_font,
            font_size = tweak_data.menu.pd2_small_font_size,
            text = text,
            visible = false,
            color = Color.white,
            layer = 350, --tweak_data.gui.MENU_LAYER - 50,
            blend_mode = 'add'
        })
        self:SetRight(y or 0.02, txt)
        self:SetTop(x, txt)
        self:MakeFineText(txt) -- Resizes text to fit the text in the panel
        return txt
    end

    function SydneyHUD:CreateBitmap(color, x, y)
        local bmp = self._panel:bitmap({
            h = 48,
            w = 48,
            valign = 'center',
            halign = 'center',
            visible = false,
            color = color,
            layer = 350, --tweak_data.gui.MENU_LAYER - 50,
            blend_mode = 'normal'
        })
        self:SetRight(y or 0.02, bmp)
        self:SetTop(x, bmp)
        return bmp
    end

    function SydneyHUD:SetTop(x, object)
        object = object or self.color_box
        if alive(self._panel) and object then
            object:set_top(self._panel:h() * x)
        end
    end
    
    function SydneyHUD:SetRight(x, object)
        object = object or self.color_box
        if alive(self._panel) and object then
            object:set_right(self._panel:right() - self._panel:w() * (0.35 + x))
        end
    end

    function SydneyHUD:SetVisibility(visibility, object)
        object = object or self.color_box
        if object then
            object:set_visible(visibility)
        end
    end

    function SydneyHUD:SetBoxColor(color, extension, object)
        object = object or self.color_box
        object:set_color(self:GetColor(color, extension))
    end

    function SydneyHUD:GetColor(color, extension)
        if not color then
            return Color.white
        end
        extension = extension or ""
        return Color(1, SydneyHUD._data[color .. "_r" .. extension], SydneyHUD._data[color .. "_g" .. extension], SydneyHUD._data[color .. "_b" .. extension]) -- Already converted from 255 format
    end

    function SydneyHUD:IsOr(string, ...)
        for i = 1, select("#", ...) do
            if string == select(i, ...) then
                return true
            end
        end
        return false
    end

    function SydneyHUD:Hook(object, func, post_call)
        Hooks:PostHook(object, func, "SydneyHUD_" .. func, post_call)
    end
    
--[[     function SydneyHUD:Unhook(mod, id)
        Hooks:RemovePostHook((mod and (mod .. "_") or "BAI_") .. id)
    end ]]

    SydneyHUD:Load()
    SydneyHUD.setup = true
    if CustomWaypoint then
        CustomWaypoint:ChangeVariables() -- Hack
    end
    log(SydneyHUD.info .. "SydneyHUD loaded.")
end

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if SydneyHUD._hook_files[requiredScript] then
        SydneyHUD:SafeDoFile(SydneyHUD._lua_path .. SydneyHUD._hook_files[requiredScript])
    else
        log(SydneyHUD.warn .. "unlinked script called: " .. requiredScript)
    end
end