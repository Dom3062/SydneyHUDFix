--[[
    Always show weapon mods in the Black Market
]]

local select_original = BlackMarketGuiSlotItem.select
function BlackMarketGuiSlotItem:select(instant, no_sound)
    self._data.hide_unselected_mini_icons = false
    return select_original(self, instant, no_sound)
end

local deselect_original = BlackMarketGuiSlotItem.deselect
function BlackMarketGuiSlotItem:deselect(instant)
    self._data.hide_unselected_mini_icons = false
    deselect_original(self, instant)
end