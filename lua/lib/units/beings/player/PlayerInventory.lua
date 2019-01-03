local equip_selection_original = PlayerInventory.equip_selection
function PlayerInventory:equip_selection(...)
    if equip_selection_original(self, ...) then
        local unit = self:equipped_unit()
        managers.gameinfo:event("player_weapon", "equip", tostring(unit:key()), { unit = unit })
        return true
    end
    return false
end