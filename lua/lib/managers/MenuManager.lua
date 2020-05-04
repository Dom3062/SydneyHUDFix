dofile(SydneyHUD._lua_path .. "SydneyMenu.lua")

local is_dlc_latest_locked_original = MenuCallbackHandler.is_dlc_latest_locked
function MenuCallbackHandler:is_dlc_latest_locked(...)
    return SydneyHUD:GetOption("remove_ads") and false or is_dlc_latest_locked_original(self, ...)
end

local old_resume = MenuCallbackHandler.resume_game
function MenuCallbackHandler:resume_game()
    old_resume(self)
    if SydneyHUD.Update then
        SydneyHUD.Update = false
        managers.hud:SydneyHUDUpdate()
    end
end

--[[
    Load our localization keys for our menu, and menu items.
]]
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_sydneyhud", function(loc)
    if SydneyHUD:GetOption("language") == 1 then
        local language_filename = nil
        for _, filename in pairs(file.GetFiles(SydneyHUD._path .. "lang/")) do
            local str = filename:match('^(.*).json$')
            if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
                language_filename = str
                break
            end
        end
        if language_filename then
            loc:load_localization_file(SydneyHUD._path .. "lang/" .. language_filename .. ".json")
        end
    else
        local langid = SydneyHUD:GetOption("language") - 1
        for _, filename in pairs(file.GetFiles(SydneyHUD._path .. "lang/")) do
            local str = filename:match('^(.*).json$')
            -- if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
            -- log(SydneyHUD.dev..langid)
            if str == SydneyHUD._language[langid] then
                loc:load_localization_file(SydneyHUD._path .. "lang/" .. filename)
                log(SydneyHUD.info .. "language: " .. filename)
                break
            end
        end
    end
    loc:load_localization_file(SydneyHUD._path .. "lang/english.json", false)
    loc:load_localization_file(SydneyHUD._path .. "lang/languages.json")
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_SydneyHUD", function(menu_manager, nodes)
    if nodes.main then
        MenuHelper:AddMenuItem(nodes.main, "crimenet_contract_special", "menu_cn_premium_buy", "menu_cn_premium_buy_desc", "crimenet", "after")
    end
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_SydneyHUD", function(menu_manager, nodes)
    --[[
        Setup our callbacks as defined in our item callback keys, and perform our logic on the data retrieved.
    ]]
    MenuCallbackHandler.OpenSydneyHUDModOptions = function(self, item)
        SydneyHUD.Menu = SydneyHUD.Menu or SydneyMenu:new()
		SydneyHUD.Menu:Open()
	end
	
	local node = nodes["blt_options"]

	local item_params = {
		name = "SydneyHUD_OpenMenu",
		text_id = "sydneyhud_menu",
		help_id = "sydneyhud_menu_desc",
		callback = "OpenSydneyHUDModOptions",
		localize = true,
	}
    node:add_item(node:create_item({type = "CoreMenuItem.Item"}, item_params))
end)

Hooks:PostHook(MenuManager, "update", "update_menu_SydneyHUD", function(self, t, dt)
	if SydneyHUD.Menu and SydneyHUD.Menu.update and SydneyHUD.Menu._enabled then
		SydneyHUD.Menu:update(t, dt)
	end
end)