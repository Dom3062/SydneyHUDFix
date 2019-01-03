local activate_property_original = TemporaryPropertyManager.activate_property
local add_to_property_original = TemporaryPropertyManager.add_to_property
local mul_to_property_original = TemporaryPropertyManager.mul_to_property
local set_time_original = TemporaryPropertyManager.set_time
local remove_property_original = TemporaryPropertyManager.remove_property

function TemporaryPropertyManager:activate_property(prop, ...)
    activate_property_original(self, prop, ...)
    
    local data = self._properties[prop]
    managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
    managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
    managers.gameinfo:event("temporary_buff", "set_duration", "property", prop, 1, { expire_t = data[2] })
    managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
end

function TemporaryPropertyManager:add_to_property(prop, ...)
    local was_active = self:has_active_property(prop)
    
    add_to_property_original(self, prop, ...)
    
    local data = self._properties[prop]
    if was_active then
        managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
        managers.gameinfo:event("temporary_buff", "set_expire", "property", prop, 1, { expire_t = data[2] })
        managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
    end
end

function TemporaryPropertyManager:mul_to_property(prop, ...)
    local was_active = self:has_active_property(prop)
    
    mul_to_property_original(self, prop, ...)
    
    local data = self._properties[prop]
    if was_active then
        managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
        managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
    end
end

function TemporaryPropertyManager:set_time(prop, ...)
    set_time_original(self, prop, ...)
    
    local data = self._properties[prop]
    if data and self:has_active_property(prop) then
        managers.gameinfo:event("temporary_buff", "set_expire", "property", prop, 1, { expire_t = data[2] })
    end
end

function TemporaryPropertyManager:remove_property(prop, ...)
    if self:has_active_property(prop) then
        managers.gameinfo:event("temporary_buff", "deactivate", "property", prop, 1)
    end
    
    return remove_property_original(self, prop, ...)
end