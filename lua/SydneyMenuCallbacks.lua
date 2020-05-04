local function UpdateOneItem(self, menu, item_to_update, status)
    for _, item in pairs(menu.items) do
        if item.id == item_to_update then
            self:AnimateItemEnabled(item, status)
            break
        end
    end
end

-- Shared functions
function SydneyMenu:SetValue(value, id)
    SydneyHUD._data[id] = value
end

function SydneyMenu:SetSniperColor(color)
    SydneyHUD._data.laser_color_r_snipers = color.red
    SydneyHUD._data.laser_color_g_snipers = color.green
    SydneyHUD._data.laser_color_b_snipers = color.blue
end

function SydneyMenu:SetTurretColor(color)
    SydneyHUD._data.laser_color_r_turret = color.red
    SydneyHUD._data.laser_color_g_turret = color.green
    SydneyHUD._data.laser_color_b_turret = color.blue
end

function SydneyMenu:SetTurretrColor(color)
    SydneyHUD._data.laser_color_r_turretr = color.red
    SydneyHUD._data.laser_color_g_turretr = color.green
    SydneyHUD._data.laser_color_b_turretr = color.blue
end

function SydneyMenu:SetTurretmColor(color)
    SydneyHUD._data.laser_color_r_turretm = color.red
    SydneyHUD._data.laser_color_g_turretm = color.green
    SydneyHUD._data.laser_color_b_turretm = color.blue
end

function SydneyMenu:SetCivilianColor(color)
    SydneyHUD._data.civilian_color_r = color.red
    SydneyHUD._data.civilian_color_g = color.green
    SydneyHUD._data.civilian_color_b = color.blue
end

function SydneyMenu:SetEnemyColor(color)
    SydneyHUD._data.enemy_color_r = color.red
    SydneyHUD._data.enemy_color_g = color.green
    SydneyHUD._data.enemy_color_b = color.blue
end

function SydneyMenu:SetInteractColor(color)
    SydneyHUD._data.interact_color_r = color.red
    SydneyHUD._data.interact_color_g = color.green
    SydneyHUD._data.interact_color_b = color.blue
end

function SydneyMenu:SetWaypointColor(color)
    SydneyHUD._data.waypoint_color_r = color.red
    SydneyHUD._data.waypoint_color_g = color.green
    SydneyHUD._data.waypoint_color_b = color.blue
end

function SydneyMenu:HUDListOptionsRightCreated()
    UpdateOneItem(self, self:GetMenu("sydneyhud_hudlist_options_right"), "hudlist_separate_bagged_loot", SydneyHUD:GetOption("hudlist_show_loot") ~= 1)
end

function SydneyMenu:HUDListShowLootChanged(value)
    UpdateOneItem(self, self:GetMenu("sydneyhud_hudlist_options_right"), "hudlist_separate_bagged_loot", value ~= 1)
end

function SydneyMenu:SydneyHUDHUDTweaksAssaultMenuCreatedCallback()
    local menu = self:GetMenu("sydneyhud_hud_tweaks_assault")
    if BAI then
        UpdateOneItem(self, menu, "show_assault_states", false)
        UpdateOneItem(self, menu, "enable_enhanced_assault_banner", false)
        UpdateOneItem(self, menu, "enhanced_assault_spawns", false)
        UpdateOneItem(self, menu, "enhanced_assault_time", false)
        UpdateOneItem(self, menu, "time_format", false)
        UpdateOneItem(self, menu, "enhanced_assault_count", false)
    --else
        --menu.items[9].panel:set_alpha(0)
    end
end

function SydneyMenu:SydneyHUDReset()
    local menu_title = managers.localization:text("sydneyhud_reset")
    local menu_message = managers.localization:text("sydneyhud_reset_message")
    local menu_options = {
        [1] = {
            text = managers.localization:text("sydneyhud_reset_yes"),
            callback = function()
                SydneyHUD:LoadDefaults()
            end
        },
        [2] = {
            text = managers.localization:text("sydneyhud_reset_cancel"),
            is_cancel_button = true
        }
    }
    QuickMenu:new(menu_title, menu_message, menu_options, true)
end