local nrwb_old = NewRaycastWeaponBase.on_enabled
function NewRaycastWeaponBase:on_enabled(...)
    nrwb_old(self, ...)
    if SydneyHUD:GetOption("auto_laser") then
        if SydneyHUD:GetOption("set_gadget_id_on") == 0 then
            self:set_gadget_on(1 or 2 or 0, false)
        else
            self:set_gadget_on(SydneyHUD:GetOption("set_gadget_id_on"), false)
        end
    end
end