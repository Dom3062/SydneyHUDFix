local set_tweak_data_original = BaseInteractionExt.set_tweak_data
local interact_start_original = BaseInteractionExt.interact_start
local interact_interupt_original = BaseInteractionExt.interact_interupt

function BaseInteractionExt:set_tweak_data(...)
    local old_tweak = self.tweak_data
    local was_active = self:active()
    set_tweak_data_original(self, ...)
    if was_active and self:active() and self.tweak_data ~= old_tweak then
        managers.interaction:remove_unit_clbk(self._unit, old_tweak)
        managers.interaction:add_unit_clbk(self._unit)
    end
end

local SecurityCameraInteractionExt_set_active_original = SecurityCameraInteractionExt.set_active
function SecurityCameraInteractionExt:set_active(active, ...)
    managers.gameinfo:event("camera", "set_active", tostring(self._unit:key()), { active = active and true or false } )
    return SecurityCameraInteractionExt_set_active_original(self, active, ...)
end

function BaseInteractionExt:interact_start(player, data)
	    if SydneyHUD:GetOption("push_to_interact") and self:can_interact(player) and tonumber(self:check_interact_time()) >= SydneyHUD:GetOption("push_to_interact_delay") and not self:_interact_blocked(player) then
			local btn_cancel = SydneyHUD:GetOption("equipment_interrupt") and (managers.localization:btn_macro("use_item", true) or managers.localization:get_default_macro("BTN_USE_ITEM")) or (managers.localization:btn_macro("interact", true) or managers.localization:get_default_macro("BTN_INTERACT"))
			managers.hud:show_interact({
				text = managers.localization:text(self.tweak_data == "corpse_alarm_pager" and "sydneyhud_int_locked_pager" or "sydneyhud_int_locked", {BTN_CANCEL = btn_cancel}),
				icon = self._tweak_data.icon,
				force = true
			})
		end
    return interact_start_original(self, player, data)
end

function BaseInteractionExt:interact_interupt(player, complete)
	local string_macros = {}

	self:_add_string_macros(string_macros)
	if SydneyHUD:GetOption("push_to_interact") and self:can_interact(player) and tonumber(self:check_interact_time()) >= SydneyHUD:GetOption("push_to_interact_delay") then
		if self.tweak_data == "corpse_alarm_pager" then return interact_interupt_original(self, player, complete) end
		local text_id = self._tweak_data.text_id or alive(self._unit) and self._unit:base().interaction_text_id and self._unit:base():interaction_text_id()
		local text = managers.localization:text(text_id, string_macros)
		local icon = self._tweak_data.icon
		managers.hud:show_interact({
			text = text,
			icon = icon,
			force = true
		})
		return true
	end
	return interact_interupt_original(self, player, complete)
end

function BaseInteractionExt:check_interact_time()
    local interact_timer = 0
    if self:_timer_value() then
        interact_timer = self:_get_timer()
    end
    if interact_timer < 10 then
        if string.len(interact_timer) > 3 then
            interact_timer = string.sub(math.round(interact_timer * 10) / 10, 1, 3)
        elseif string.len(interact_timer) == 1 then
            interact_timer = interact_timer .. ".0"
        end
    else
        if string.len(interact_timer) > 4 then
            interact_timer = string.sub(math.round(interact_timer * 10) / 10, 1, 4)
        elseif string.len(interact_timer) == 2 then
            interact_timer = interact_timer .. ".0"
        end
    end
    return interact_timer
end
