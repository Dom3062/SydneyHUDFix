local init_original = HUDInteraction.init
function HUDInteraction:init(hud, child_name)
    init_original(self, hud, child_name)
    self._interact_timer_text = self._hud_panel:text({
        name = "interact_timer_text",
        visible = false,
        text = "",
        valign = "center",
        align = "center",
        layer = 2,
        color = Color.white,
        font = tweak_data.menu.pd2_large_font,
        font_size = tweak_data.hud_present.text_size + 8,
        h = 64
    })
    self._interact_timer_text:set_y(self._hud_panel:h() / 2)
    for i = 1, 4 do
        self["_bgtext" .. i] = self._hud_panel:text({
            name = "bgtext" .. i,
            visible = false,
            text = "",
            valign = "center",
            align = "center",
            layer = 1,
            color = Color.black,
            font = tweak_data.menu.pd2_large_font,
            font_size = tweak_data.hud_present.text_size + 8,
            h = 64
        })
    end
    self._bgtext1:set_y(self._hud_panel:h() / 2 - 1)
    self._bgtext1:set_x(self._bgtext1:x() - 1)
    self._bgtext2:set_y(self._hud_panel:h() / 2 + 1)
    self._bgtext2:set_x(self._bgtext2:x() + 1)
    self._bgtext3:set_y(self._hud_panel:h() / 2 + 1)
    self._bgtext3:set_x(self._bgtext3:x() - 1)
    self._bgtext4:set_y(self._hud_panel:h() / 2 - 1)
    self._bgtext4:set_x(self._bgtext4:x() + 1)
    self.show_interaction_circle = SydneyHUD:GetOption("show_interaction_circle")
    self.show_interaction_text = SydneyHUD:GetOption("show_interaction_text")
    self.show_text_borders = SydneyHUD:GetOption("show_text_borders")
end

local show_interaction_bar_original = HUDInteraction.show_interaction_bar
function HUDInteraction:show_interaction_bar(current, total)
    show_interaction_bar_original(self, current, total)
    self._interact_circle:set_visible(self.show_interaction_circle)
    self._interact_timer_text:set_visible(self.show_interaction_text)
    for i = 1, 4 do
        self["_bgtext" .. i]:set_visible(self.show_interaction_text and self.show_text_borders)
    end
end

local set_interaction_bar_width_original = HUDInteraction.set_interaction_bar_width
function HUDInteraction:set_interaction_bar_width(current, total)
    set_interaction_bar_width_original(self, current, total)
    if not self._interact_timer_text then
        return
    end
    local text = string.format("%.1f", total - current >= 0 and total - current or 0) .. "s"
    local color = SydneyHUD:GetColor("interaction_color")
    self._interact_timer_text:set_text(text)
    self._interact_timer_text:set_color(Color(
        color.a + (current / total),
        color.r + (current / total),
        color.g + (current / total),
        color.b + (current / total)
    ))
    for i = 1, 4 do
        self["_bgtext" .. i]:set_text(text)
    end
end

local hide_interaction_bar_original = HUDInteraction.hide_interaction_bar
function HUDInteraction:hide_interaction_bar(complete)
    if not complete and self._animated and self._interact_circle then
        self._animated = nil
        self._interact_circle._panel:stop()
    end
    hide_interaction_bar_original(self, complete and self.show_interaction_circle)
    self._interact_timer_text:set_visible(false)
    for i = 1, 4 do
        self["_bgtext" .. i]:set_visible(false)
    end
end

local destroy_original = HUDInteraction.destroy
function HUDInteraction:destroy()
    self._hud_panel:remove(self._hud_panel:child("interact_timer_text"))
    self._hud_panel:remove(self._hud_panel:child("bgtext1"))
    self._hud_panel:remove(self._hud_panel:child("bgtext2"))
    self._hud_panel:remove(self._hud_panel:child("bgtext3"))
    self._hud_panel:remove(self._hud_panel:child("bgtext4"))
    destroy_original(self)
end

function HUDInteraction:set_locked(status)
    if status then
        if self._interact_circle_locked then
            self._interact_circle_locked._circle:set_color(status and Color.green or Color.red)
            self._interact_circle_locked._circle:set_alpha(0.25)
        end

        if SydneyHUD:GetOption("equipment_interrupt") then
            self._hud_panel:child(self._child_name_text):set_text(utf8.to_upper(managers.localization:text("equipment_interrupt_press")))
        end
    end
end