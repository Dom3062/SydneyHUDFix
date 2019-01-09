local create_assets_original = AssetsItem.create_assets
local unlock_asset_by_id_original = AssetsItem.unlock_asset_by_id
local move_up_original = AssetsItem.move_up
local move_down_original = AssetsItem.move_down
local move_left_original = AssetsItem.move_left
local move_right_original = AssetsItem.move_right
local confirm_pressed_original = AssetsItem.confirm_pressed
local mouse_moved_original = AssetsItem.mouse_moved
local mouse_pressed_original = AssetsItem.mouse_pressed

function AssetsItem:create_assets(...)
    create_assets_original(self, ...)

    self._buy_all_btn = self._panel:text({
        name = "buy_all_btn",
        text = "",
        h = tweak_data.menu.pd2_medium_font_size * 0.95,
        font_size = tweak_data.menu.pd2_medium_font_size * 0.9,
        font = tweak_data.menu.pd2_medium_font,
        color = tweak_data.screen_colors.button_stage_3,
        align = "right",
        blend_mode = "add",
        visible = managers.assets:has_locked_assets(),
    })

    self:update_buy_all_btn()
end

function AssetsItem:unlock_asset_by_id(...)
    unlock_asset_by_id_original(self, ...)

    self:update_buy_all_btn()
end

function AssetsItem:move_up(...)
    if self._asset_selected and (self._asset_selected % 2 > 0) and managers.assets:has_buyable_assets() and self:can_afford_all_assets() then
        self._buy_all_highlighted = true
        self._last_selected_asset = self._asset_selected
        self:check_deselect_item()
        self:update_buy_all_btn(true)
        managers.menu_component:post_event("highlight")
    else
        move_up_original(self, ...)
    end
end

function AssetsItem:move_down(...)
    if self._buy_all_highlighted then
        self._buy_all_highlighted = nil
        self:select_asset(self._last_selected_asset)
        self:update_buy_all_btn(true)
        self._last_selected_asset = nil
    else
        move_down_original(self, ...)
    end
end

function AssetsItem:move_left(...)
    if not self._buy_all_highlighted then
        move_left_original(self, ...)
    end
end

function AssetsItem:move_right(...)
    if not self._buy_all_highlighted then
        move_right_original(self, ...)
    end
end

function AssetsItem:confirm_pressed(...)
    if self._buy_all_highlighted then
        if self:can_afford_all_assets() then
            managers.assets:unlock_all_buyable_assets()
            self:update_buy_all_btn()
            self:move_down()
        end
    else
        return confirm_pressed_original(self, ...)
    end
end

function AssetsItem:mouse_moved(x, y, ...)
    if alive(self._buy_all_btn) and managers.assets:has_buyable_assets() then
        if self._buy_all_btn:inside(x, y) then
            if not self._buy_all_highlighted then
                self._buy_all_highlighted = true
                self:update_buy_all_btn(true)
                self:check_deselect_item()
                if self:can_afford_all_assets() then
                    managers.menu_component:post_event("highlight")
                end
            end
            return true, "link"
        elseif self._buy_all_highlighted then
            self._buy_all_highlighted = nil
            self:update_buy_all_btn(true)
        end
    end

    return mouse_moved_original(self, x, y, ...)
end

function AssetsItem:mouse_pressed(button, x, y, ...)
    if alive(self._buy_all_btn) and self:can_afford_all_assets() and button == Idstring("0") and self._buy_all_btn:inside(x, y) then
        managers.assets:unlock_all_buyable_assets()
        self:update_buy_all_btn()
    end

    return mouse_pressed_original(self, button, x, y, ...)
end

function AssetsItem:update_buy_all_btn(colors_only)
    if alive(self._buy_all_btn) then
        local asset_costs = managers.assets:get_total_assets_costs()
        if managers.assets:has_buyable_assets() then
            if self:can_afford_all_assets() then
                self._buy_all_btn:set_color(self._buy_all_highlighted and tweak_data.screen_colors.button_stage_2 or tweak_data.screen_colors.button_stage_3)
            else
                self._buy_all_btn:set_color(tweak_data.screen_colors.pro_color)
            end
        else
            self._buy_all_btn:set_color(tweak_data.screen_color_grey)
        end
        if not colors_only then
            local text = string.format("%s (%s)", managers.localization:to_upper_text("buy_all_assets"), managers.experience:cash_string(asset_costs))
            self._buy_all_btn:set_text(text)
            local _, _, w, _ = self._buy_all_btn:text_rect()
            self._buy_all_btn:set_w(math.ceil(w))
            self._buy_all_btn:set_top(15)
            if managers.menu:is_pc_controller() then
                self._buy_all_btn:set_right(self._panel:w() - 5)
            else
                self._buy_all_btn:set_left(5)
            end
        end
    end
end

function AssetsItem:can_afford_all_assets()
    return (managers.assets:get_total_assets_costs() <= managers.money:total())
end

-- TODO: This does nothing useful for now. I *may* re-implement the pre-U143 melee icons (i.e. mini primary + secondary weapon
-- icons) at a later point if I have time (or if I'm actually bored enough to do this)
local preU143melee = false

-- Do not allow the returned table to prevent the referenced panels from being garbage collected
local function CreateWeakValuedTable()
    return setmetatable({}, {__mode = "v"})
end

-- Standard IEEE rounding to nearest integer (round half away from zero)
local function RoundToNearest(real)
    return real >= 0 and math.floor(real + 0.5) or math.ceil(real - 0.5)
end

-- Be advised, this function is really, /really/ longwinded... Composition: 98% panel identification logic + 1% panel
-- re-alignment logic + 1% code for actually creating the new throwable icon. But why go through all this trouble? Why not simply
-- mirror the game's code in this function hook, make a few alignment tweaks and be done with it all? Because game updates may
-- (read: will) cause problems in future, if OVK decides to change this function. But the resulting problem(s) won't show up here,
-- no sir. It'll show up somewhere completely unexpected instead (in which case, have fun debugging that)
local set_slot_outfit_actual = TeamLoadoutItem.set_slot_outfit
function TeamLoadoutItem:set_slot_outfit(slot, criminal_name, outfit, ...)
    local player_slot = self._player_slots[slot]
    if not player_slot or not outfit or not outfit.grenade then
        return set_slot_outfit_actual(self, slot, criminal_name, outfit, ...)
    end

    set_slot_outfit_actual(self, slot, criminal_name, outfit, ...)

    -- Figure out which bitmaps correspond to which loadout item (e.g. primary, secondary, etc.). Thanks for - once again - not
    -- naming your panels, OVK  >.>
    local childpanels = player_slot.panel:children()
    if childpanels == nil or #childpanels == 0 then
        log(SydneyHUD.error .. "TeamLoadoutItem:set_slot_outfit() | Error: No child panels were found for slot " .. tostring(slot) .. ", aborting")
        return
    end

    -- Because Bitmap panels store their assigned textures as Idstring-encoded hashes, go the long way and look up and hash each
    -- of the texture names currently being used in the five bitmaps. This will form a list of identifiers, from which the
    -- corresponding bitmap can be, well, identified. Note that this still does not identify *all* bitmaps because there are
    -- 'subcomponents' in certain cases, such as weapon skins and mod icons. Fortunately, OVK's code creates them sequentially
    -- For instance, all bitmaps related to the primary weapon will always be created before the secondary weapon's bitmap is
    -- added

    -- Given a texture hash, provides its corresponding item index, or nil if not found
    local texture_hashes = {}
    -- These are named indexes for conveniently indexing the panels table below
    local item_index = {
        primary = 1,
        primary_perks = 2,
        secondary = 3,
        secondary_perks = 4,
        melee_weapon = 5,
        armor = 6,
        deployable = 7,
        secondary_deployable = 8,
        -- These are special signal values, not indexes. Always use the melee_weapon index instead of these values directly
        -- (melee_primary corresponds to the first entry in the melee_weapon subtable, while melee_secondary corresponds to the
        -- second entry)
        melee_primary = -1,
        melee_secondary = -2,
        -- This signals that both the primary and secondary weapons share the same skin rarity background (i.e. both are rare,
        -- epic, etc.)
        shared_skin_background = -3,
        -- This signals that both the primary and secondary weapons share the same image (e.g. double saws)
        shared_weapon = -4,
        -- This signals that the primary, secondary, and melee weapons all share the same image (e.g. double saws + weapon butt
        -- melee)
        shared_weapon_and_melee = -5,
        -- Abort immediately if this is found
        throwable = -90
    }
    -- This table holds references to weak-valued subtables, each of which holds one or more panels. Use item_index to facilitate
    -- indexing the subtables more easily
    local panels = {
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable(),
        CreateWeakValuedTable()
    }
    -- Example panels table structure:
    -- {
    --		[1] = {primary weapon icon, primary weapon skin background}
    --		[2] = {primary weapon perk icon 1, ...}
    --		[3] = {secondary weapon icon, secondary weapon skin background}
    --		[4] = {secondary weapon perk icon 1, ...}
    --		[5] = {melee weapon icon, melee secondary weapon icon (if weapon butt melee is equipped, otherwise nil)}
    --		[6] = {armor icon}
    --		[7] = {deployable icon, amount text}
    --		[8] = {secondary deployable icon, amount text}
    -- }

    -- Avoid incurring repeated global table lookups by caching the references as locals (for performance reasons)
    local managers = _G.managers
    local blackmarket_manager = managers.blackmarket
    local weaponfactorymanager = managers.weapon_factory
    local tweakdata = _G.tweak_data
    local blackmarkettweakdata = tweakdata.blackmarket

    -- Figure out which throwable texture is being used. Do this here so the code can bail out early if the throwable icon
    -- already exists (e.g. if OVK adds it in a future update) instead of wasting CPU cycles to add an unnecessary icon. The
    -- validity check for outfit.grenade is omitted since it has already been performed at the very beginning of this function
    local throwable_texture = nil
    do
        local guis_catalog = "guis/"
        local bundle_folder = blackmarkettweakdata.projectiles[outfit.grenade] and blackmarkettweakdata.projectiles[outfit.grenade].texture_bundle_folder
        if bundle_folder then
            guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        throwable_texture = guis_catalog .. "textures/pd2/blackmarket/icons/grenades/" .. outfit.grenade
    end
    if throwable_texture ~= nil then
        texture_hashes[Idstring(throwable_texture):key()] = item_index.throwable
    else
        log(SydneyHUD.error .. "TeamLoadoutItem:set_slot_outfit() | Error: Failed to determine throwable texture for slot " .. tostring(slot) .. ", aborting")
        return
    end

    -- Prepare the texture_hashes table for use by determining the exact texture name hashes used by the existing game code and
    -- assigning indexes to them that correspond to entries within the panels table
    local has_primary_skin = false
    local has_secondary_skin = false
    local primary_texture = nil
    local secondary_texture = nil
    if outfit.primary.factory_id then
        local primary_id = weaponfactorymanager:get_weapon_id_by_factory_id(outfit.primary.factory_id)
        local rarity = nil
        primary_texture, rarity = blackmarket_manager:get_weapon_icon_path(primary_id, outfit.primary.cosmetics)
        texture_hashes[Idstring(primary_texture):key()] = item_index.primary
        if rarity then
            texture_hashes[Idstring(rarity):key()] = item_index.primary
            has_primary_skin = true
        end
    end
    if outfit.secondary.factory_id then
        local secondary_id = weaponfactorymanager:get_weapon_id_by_factory_id(outfit.secondary.factory_id)
        local rarity = nil
        secondary_texture, rarity = blackmarket_manager:get_weapon_icon_path(secondary_id, outfit.secondary.cosmetics)
        local secondarytexturehash = Idstring(secondary_texture):key()
        if texture_hashes[secondarytexturehash] == item_index.primary then
            texture_hashes[secondarytexturehash] = item_index.shared_weapon
        else
            texture_hashes[secondarytexturehash] = item_index.secondary
        end
        if rarity then
            -- Does this weapon's skin share the same rarity background as the primary weapon's skin?
            local rarityhash = Idstring(rarity):key()
            if texture_hashes[rarityhash] == nil then
                texture_hashes[rarityhash] = item_index.secondary
            else
                texture_hashes[rarityhash] = item_index.shared_skin_background
            end
            has_secondary_skin = true
        end
    end
    if outfit.melee_weapon then
        local guis_catalog = "guis/"
        local bundle_folder = blackmarkettweakdata.melee_weapons[outfit.melee_weapon] and blackmarkettweakdata.melee_weapons[outfit.melee_weapon].texture_bundle_folder
        if bundle_folder then
            guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        if preU143melee and outfit.melee_weapon == "weapon" then
            -- Weapon butt
            if primary_texture and secondary_texture then
                if primary_texture ~= secondary_texture then
                    -- Note that this clobbers the indexes for the primary and secondary weapons previously set above, but weapon
                    -- skins are unaffected by this and will continue to use the correct indexes
                    texture_hashes[Idstring(primary_texture):key()] = item_index.melee_primary
                    texture_hashes[Idstring(secondary_texture):key()] = item_index.melee_secondary
                else
                    -- E.g. double saws + weapon butt melee
                    texture_hashes[Idstring(primary_texture):key()] = item_index.shared_weapon_and_melee
                end
            end
        else
            texture_hashes[Idstring(guis_catalog .. "textures/pd2/blackmarket/icons/melee_weapons/" .. outfit.melee_weapon):key()] = item_index.melee_weapon
        end
    end
    if outfit.armor then
        local guis_catalog = "guis/"
        local bundle_folder = blackmarkettweakdata.armors[outfit.armor] and blackmarkettweakdata.armors[outfit.armor].texture_bundle_folder
        if bundle_folder then
            guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        texture_hashes[Idstring(guis_catalog .. "textures/pd2/blackmarket/icons/armors/" .. outfit.armor):key()] = item_index.armor
    end
    local forceprimarydeployablevisible = false
    if outfit.deployable and outfit.deployable ~= "nil" then
        local guis_catalog = "guis/"
        local bundle_folder = blackmarkettweakdata.deployables[outfit.deployable] and blackmarkettweakdata.deployables[outfit.deployable].texture_bundle_folder
        if bundle_folder then
            guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        texture_hashes[Idstring(guis_catalog .. "textures/pd2/blackmarket/icons/deployables/" .. outfit.deployable):key()] = item_index.deployable
    else
        forceprimarydeployablevisible = true
        texture_hashes[Idstring("guis/textures/pd2/none_icon"):key()] = item_index.deployable
    end
    -- Ditto for the secondary deployable (networked by OVK in U118)
    local secondary_deployable_texture = nil
    if outfit.secondary_deployable and outfit.secondary_deployable ~= "nil" then
        -- This check is necessary because of OVK's incredibly broken deployable selection GUI implementation with regard to the
        -- Jack of All Trades skill (please sanitize your tables instead of leaving stale junk in them FFS)
        if outfit.secondary_deployable ~= outfit.deployable then
            local guis_catalog = "guis/"
            local bundle_folder = blackmarkettweakdata.deployables[outfit.secondary_deployable] and blackmarkettweakdata.deployables[outfit.secondary_deployable].texture_bundle_folder
            if bundle_folder then
                guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
            end
            secondary_deployable_texture = guis_catalog .. "textures/pd2/blackmarket/icons/deployables/" .. outfit.secondary_deployable
            texture_hashes[Idstring(secondary_deployable_texture):key()] = item_index.secondary_deployable
        end
    end

    -- Given an example childpanels table containing the following panels:
    -- {
    --		<text>							<- Not of type 'Bitmap'; ignored
    --		<primary>						<- Recognized
    --		<primary skin background>		<- Recognized
    --		<primary mod icon 1>			<- Unrecognized
    --		<primary mod icon 2>			<- Unrecognized
    --		<secondary>						<- Recognized
    --		<secondary skin background>		<- Recognized
    --		<secondary mod icon 1>			<- Unrecognized
    --		<secondary mod icon 2>			<- Unrecognized
    --		<melee>							<- Recognized
    --		...
    -- }
    -- The following loop attempts to identify the recognized panels and group the subsequent unrecognized panels together with
    -- the most recently recognized panel

    local previousitemindex = 1
    for index, panel in ipairs(childpanels) do
        if panel.type_name == "Bitmap" then
            -- Attempt to identify it by its texture name hash
            local itemindex = texture_hashes[panel:texture_name():key()]
            -- Substitute signal values with their actual indexes
            if itemindex == item_index.melee_primary then
                -- melee_primary is a shared index that is used for both the primary weapon and the melee weapon icons, so this
                -- code needs to ensure that both slots get populated, rather than just one of them
                itemindex = item_index.primary
                if #panels[itemindex] > 0 then
                    itemindex = item_index.melee_weapon
                end
            end
            if itemindex == item_index.melee_secondary then
                -- melee_secondary is a shared index that is used for both the secondary weapon and the melee weapon icons, so
                -- this code needs to ensure that both slots get populated, rather than just one of them
                itemindex = item_index.secondary
                if #panels[itemindex] > 0 then
                    itemindex = item_index.melee_weapon
                end
            end
            if itemindex == item_index.shared_skin_background then
                -- shared_skin_background is a shared index that is used for both the primary and secondary weapon icons, so this
                -- code needs to ensure that both slots get populated, rather than just one of them
                itemindex = item_index.primary
                if #panels[itemindex] > 1 then
                    itemindex = item_index.secondary
                end
            end
            if itemindex == item_index.shared_weapon then
                -- shared_weapon is a shared index that is used for both the primary and secondary weapon icons, so this code
                -- needs to ensure that both slots get populated, rather than just one of them
                itemindex = item_index.primary
                if #panels[itemindex] > 0 then
                    itemindex = item_index.secondary
                end
            end
            if itemindex == item_index.shared_weapon_and_melee then
                -- shared_weapon_and_melee is a shared index that is used for the primary, secondary, and melee weapon icons, so
                -- this code needs to ensure that all slots get populated, rather than just one of them
                -- TODO: This is ugly, rewrite it
                itemindex = item_index.primary
                if #panels[itemindex] > 0 then
                    itemindex = item_index.secondary
                    if #panels[itemindex] > 0 then
                        itemindex = item_index.melee_weapon
                    end
                end
            end
            if itemindex == item_index.throwable then
                log(SydneyHUD.warn .. "TeamLoadoutItem:set_slot_outfit() | Warning: Throwable icon already exists, aborting")
                return
            end
            if itemindex ~= nil and itemindex > previousitemindex then
                previousitemindex = itemindex
            end
            if itemindex == nil then
                -- This is very likely to be a weapon perk icon since weapon skins (if any) are always recognized
                if previousitemindex == item_index.primary then
                    itemindex = item_index.primary_perks
                elseif previousitemindex == item_index.secondary then
                    itemindex = item_index.secondary_perks
                end
            end
            itemindex = itemindex or previousitemindex
            table.insert(panels[itemindex], panel)
        elseif panel.type_name == "Text" then
            -- Also grab references to the deployable count text panels, if present
            if previousitemindex == item_index.deployable or previousitemindex == item_index.secondary_deployable and tostring(panel:text()):sub(1, 1) == "x" then
                table.insert(panels[previousitemindex], panel)
            end
        end
    end

    -- See the comment block near the declaration of the panels table above for an example of the table's contents at this point

    -- Compute new positions and offsets
    local slot_h = player_slot.panel:h()
    local aspect
    local x = player_slot.panel:w() / 2
    local y = player_slot.panel:h() / 20
    local w = slot_h / 6 * 0.9
    local h = w

    -- Resize and reposition the panels
    if outfit.primary.factory_id then
        local primary_bitmap = panels[item_index.primary][1]
        if alive(primary_bitmap) then
            primary_bitmap:set_h(h)
            aspect = primary_bitmap:texture_width() / math.max(1, primary_bitmap:texture_height())
            primary_bitmap:set_w(primary_bitmap:h(h) * aspect)
            primary_bitmap:set_center_x(x)
            primary_bitmap:set_center_y(y * 3)
            local rarity_bitmap = panels[item_index.primary][2]
            if alive(rarity_bitmap) then
                local tw = rarity_bitmap:texture_width()
                local th = rarity_bitmap:texture_height()
                local pw = primary_bitmap:w()
                local ph = primary_bitmap:h()
                local sw = math.min(pw, ph * (tw / th))
                local sh = math.min(ph, pw / (tw / th))
                rarity_bitmap:set_size(math.round(sw), math.round(sh))
                rarity_bitmap:set_center(primary_bitmap:center())
            end
        end
        -- Primary weapon perk icons
        for index, perk_object in ipairs(panels[item_index.primary_perks]) do
            if alive(perk_object) then
                -- As you can probably tell, this deviates from the standard layout. This is done to prevent the weapon perk
                -- icons from obscuring the weapon icon, which has now been shrunk
                local perk_index = index - 3
                perk_object:set_rightbottom(math.round(primary_bitmap:right() - perk_index * 16), math.round(primary_bitmap:bottom() - 5))
            end
        end
    end
    if outfit.secondary.factory_id then
        local secondary_bitmap = panels[item_index.secondary][1]
        if alive(secondary_bitmap) then
            secondary_bitmap:set_h(h)
            aspect = secondary_bitmap:texture_width() / math.max(1, secondary_bitmap:texture_height())
            secondary_bitmap:set_w(secondary_bitmap:h() * aspect)
            secondary_bitmap:set_center_x(x)
            secondary_bitmap:set_center_y(y * 6)
            local rarity_bitmap = panels[item_index.secondary][2]
            if alive(rarity_bitmap) then
                local tw = rarity_bitmap:texture_width()
                local th = rarity_bitmap:texture_height()
                local pw = secondary_bitmap:w()
                local ph = secondary_bitmap:h()
                local sw = math.min(pw, ph * (tw / th))
                local sh = math.min(ph, pw / (tw / th))
                rarity_bitmap:set_size(math.round(sw), math.round(sh))
                rarity_bitmap:set_center(secondary_bitmap:center())
            end
        end
        -- Secondary weapon perk icons
        for index, perk_object in ipairs(panels[item_index.secondary_perks]) do
            if alive(perk_object) then
                -- As you can probably tell, this deviates from the standard layout. This is done to prevent the weapon perk
                -- icons from obscuring the weapon icon, which has now been shrunk
                local perk_index = index - 3
                perk_object:set_rightbottom(math.round(secondary_bitmap:right() - perk_index * 16), math.round(secondary_bitmap:bottom() - 5))
            end
        end
    end
    if outfit.melee_weapon then
        if preU143melee and outfit.melee_weapon == "weapon" then
            if primary_texture and secondary_texture then
                local primary = panels[item_index.melee_weapon][1]
                if alive(primary) then
                    primary:set_h(h * 0.75)
                    aspect = primary:texture_width() / math.max(1, primary:texture_height())
                    primary:set_w(primary:h() * aspect)
                    primary:set_center_x(x - primary:w() * 0.25)
                    primary:set_center_y(y * 9)
                end
                local secondary = panels[item_index.melee_weapon][2]
                if alive(secondary) then
                    secondary:set_h(h * 0.75)
                    aspect = secondary:texture_width() / math.max(1, secondary:texture_height())
                    secondary:set_w(secondary:h() * aspect)
                    secondary:set_center_x(x + secondary:w() * 0.25)
                    secondary:set_center_y(y * 9)
                end
            end
        else
            local melee_weapon_bitmap = panels[item_index.melee_weapon][1]
            if alive(melee_weapon_bitmap) then
                melee_weapon_bitmap:set_h(h)
                aspect = melee_weapon_bitmap:texture_width() / math.max(1, melee_weapon_bitmap:texture_height())
                melee_weapon_bitmap:set_w(melee_weapon_bitmap:h() * aspect)
                melee_weapon_bitmap:set_center_x(x)
                melee_weapon_bitmap:set_center_y(y * 9)
            end
        end
    end
    if outfit.armor then
        local armor_bitmap = panels[item_index.armor][1]
        if alive(armor_bitmap) then
            armor_bitmap:set_h(h)
            aspect = armor_bitmap:texture_width() / math.max(1, armor_bitmap:texture_height())
            armor_bitmap:set_w(armor_bitmap:h() * aspect)
            armor_bitmap:set_center_x(x)
            armor_bitmap:set_center_y(y * 15)
        end
    end
    -- Does the player actually qualify for the Jack of All Trades skill? The detection heuristic is somewhat crappy since it is
    -- entirely possible to progress up to tier 4 without spending even a single point on that skill, but oh well...
    local secondary_deployable_amount = tonumber(outfit.secondary_deployable_amount) or 0
    if secondary_deployable_amount < 1 or outfit.skills == nil or outfit.skills.skills == nil or (tonumber(outfit.skills.skills[7]) or 0) < 12 then
        -- This is an ugly way to skip the following code, but eh, whatever
        secondary_deployable_texture = nil
    end

    if outfit.deployable and outfit.deployable ~= "nil" or forceprimarydeployablevisible then
        local deployable_bitmap = panels[item_index.deployable][1]
        if alive(deployable_bitmap) then
            deployable_bitmap:set_h(h)
            aspect = deployable_bitmap:texture_width() / math.max(1, deployable_bitmap:texture_height())
            deployable_bitmap:set_w(deployable_bitmap:h() * aspect)
            deployable_bitmap:set_center_x(RoundToNearest(secondary_deployable_texture == nil and x or x * 0.5))
            deployable_bitmap:set_center_y(y * 18)
            local deployable_text = panels[item_index.deployable][2]
            if secondary_deployable_texture ~= nil and alive(deployable_text) then
                deployable_text:set_x(RoundToNearest(deployable_text:x() - x * 0.85))
            end
        end
    end
    if secondary_deployable_texture ~= nil and outfit.secondary_deployable and outfit.secondary_deployable ~= "nil" then
        local secondary_deployable_bitmap = panels[item_index.secondary_deployable][1]
        if not alive(secondary_deployable_bitmap) then
            secondary_deployable_bitmap = player_slot.panel:bitmap({
                texture = secondary_deployable_texture,
                w = w,
                h = h,
                rotation = math.random(2) - 1.5,
                alpha = 0.8
            })
        else
            secondary_deployable_bitmap:set_h(h)
        end
        aspect = secondary_deployable_bitmap:texture_width() / math.max(1, secondary_deployable_bitmap:texture_height())
        secondary_deployable_bitmap:set_w(secondary_deployable_bitmap:h() * aspect)
        secondary_deployable_bitmap:set_center_x(RoundToNearest(x + x * 0.3))
        secondary_deployable_bitmap:set_center_y(y * 18)
        -- Apparently OVK networks the amount before the halving penalty for the Jack of All Trades skill is applied, compensate
        local secondary_deployable_amount_compensated = math.ceil(secondary_deployable_amount / 2)
        if secondary_deployable_amount_compensated > 1 then
            local secondary_deployable_text = panels[item_index.secondary_deployable][2]
            if not alive(secondary_deployable_text) then
                secondary_deployable_text = player_slot.panel:text({
                    text = "x" .. tostring(secondary_deployable_amount_compensated),
                    font_size = tweak_data.menu.pd2_small_font_size,
                    font = tweak_data.menu.pd2_small_font,
                    rotation = secondary_deployable_bitmap:rotation(),
                    color = tweak_data.screen_colors.text
                })
                local _, _, w, h = secondary_deployable_text:text_rect()
                secondary_deployable_text:set_size(w, h)
                secondary_deployable_text:set_rightbottom(player_slot.panel:w(), player_slot.panel:h())
                secondary_deployable_text:set_position(math.round(secondary_deployable_text:x()) - 16, math.round(secondary_deployable_text:y()) - 5)
            end
            secondary_deployable_text:set_x(RoundToNearest(secondary_deployable_text:x() - x * 0.05))
        end
    end
    -- Using a do-end block to constrain local variable scope... Not that it even matters anyway since this is already at the end
    -- of the function block
    do
        -- Add the throwable icon. The validity check for outfit.grenade is omitted since it has already been performed at the
        -- very beginning of this function
        local grenade_bitmap = player_slot.panel:bitmap({
            texture = throwable_texture,
            w = w,
            h = h,
            rotation = math.random(2) - 1.5,
            alpha = 0.8
        })
        aspect = grenade_bitmap:texture_width() / math.max(1, grenade_bitmap:texture_height())
        grenade_bitmap:set_w(grenade_bitmap:h() * aspect)
        grenade_bitmap:set_center_x(x)
        grenade_bitmap:set_center_y(y * 12)
    end

    -- There is no point holding references to the panels as they will be cleared (deleted) each time this function is called
    -- (the game code calls player_slot.panel:clear())
end    