local add_to_property_original = PropertyManager.add_to_property
local mul_to_property_original = PropertyManager.mul_to_property
local set_property_original = PropertyManager.set_property
local remove_property_original = PropertyManager.remove_property
function PropertyManager:add_to_property(prop, ...)
    local was_active = self:has_property(prop)
    
    add_to_property_original(self, prop, ...)
    
    if not was_active then
        managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
    end
    managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
    managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
end

function PropertyManager:mul_to_property(prop, ...)
    local was_active = self:has_property(prop)
    
    mul_to_property_original(self, prop, ...)
    
    if not was_active then
        managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
    end
    managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
    managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
end

function PropertyManager:set_property(prop, ...)
    local was_active = self:has_property(prop)
    
    set_property_original(self, prop, ...)
    
    if not was_active then
        managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
    end
    managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
end

function PropertyManager:remove_property(prop, ...)
    if self:has_property(prop) then
        managers.gameinfo:event("temporary_buff", "deactivate", "property", prop, 1)
    end
    
    return remove_property_original(self, prop, ...)
end