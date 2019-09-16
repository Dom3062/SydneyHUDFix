local GetTime = function()
    return managers.hud and managers.hud._hud_heist_timer and managers.hud._hud_heist_timer._timer_text and managers.hud._hud_heist_timer._timer_text:text() or
    (SydneyHUD:GetOption("_24h_format") and
    (SydneyHUD:GetOption("chat_time_format") == 1 and os.date('%X') or os.date('%H:%M')) or
    (SydneyHUD:GetOption("chat_time_format") == 1 and os.date('%I:%M:%S%p') or os.date('%I:%M%p')))
end

local text
local visible = false -- Hack, don't try to fix it
local _f_receive_message = ChatGui.receive_message
function ChatGui:receive_message(name, message, color, icon)
    if SydneyHUD:GetOption("show_heist_time") then
        name = GetTime() .. " " .. name
    end
    if alive(self._panel) then
        self:AnimateInfoText(text, visible)
    end
    _f_receive_message(self, name, message, color, icon)
end

local typing = {
    [1] = "",
    [2] = "",
    [3] = "",
    [4] = ""
}
local init_original = ChatGui.init
function ChatGui:init(ws)
    init_original(self, ws)
    self:_create_info_panel()
    self:_layout_info_panel()
end

function ChatGui:set_leftbottom(left, bottom)
    self._panel:set_left(left)
    self._panel:set_bottom(self._panel:parent():h() - bottom + 24)
end

function ChatGui:_create_info_panel()
    self._panel:text({
        name = "info_text",
        text = "Sydney is typing...",
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        x = 0,
        y = 0,
        w = self._panel:w(),
        h = 24,
        color = Color.white,
        alpha = 1,
        visible = false,
        layer = 1
    })
end

local _layout_input_panel_original = ChatGui._layout_input_panel
function ChatGui:_layout_input_panel()
    _layout_input_panel_original(self)
    self._input_panel:set_y(self._input_panel:parent():h() - self._input_panel:h() - 24)
end

function ChatGui:_layout_info_panel()
    local text = self._panel:child("info_text")
    text:set_left(self._panel:left() + self._input_panel:left() + self._input_panel:child("input_text"):left())
    text:set_y(text:parent():h() - text:h())
end

local _f_on_focus = ChatGui._on_focus
function ChatGui:_on_focus()
    _f_on_focus(self)
	if not self._enabled then
		return
	end
	if not self._focus then
		return
    end
    LuaNetworking:SendToPeers("ChatInfo", "typing")
end

local _f_loose_focus = ChatGui._loose_focus
function ChatGui:_loose_focus()
    _f_loose_focus(self)
    if self._focus then
        return
    end
    LuaNetworking:SendToPeers("ChatInfo", "typing_ended")
end

function ChatGui:AnimateInfoText(text, visible) -- Don't call it during "NetworkReceivedDataChatInfo" hook, otherwise be prepared for a nice suprise
    if self._panel:child("info_text"):visible() ~= visible then
        --[[local function func(o)
            over(0.6, function(p)
                o:set_alpha(math.lerp(visible and 0 or 1, visible and 1 or 0, p))
            end)
        end]]
        self._panel:child("info_text"):set_visible(visible)
    end
end

function ChatGui:UpdateInfoText(action, peer, peer_name)
    typing[peer] = action == "add" and peer_name or "Someone"
    local amount = self:GetAmountOfPeopleWriting()
    text = ""
    if amount > 0 then
        local loaded = 0
        for _, v in pairs(typing) do
            if v ~= "" then
                if text ~= "" then
                    if loaded + 1 == amount then
                        text = text .. managers.localization:text("chat_and") .. " "
                    else
                        text = text .. ", "
                    end
                end
                text = text .. v
                loaded = loaded + 1
            end
        end
        text = text .. " " .. managers.localization:text("chat_" .. (amount > 1 and "are" or "is") .. "_typing")
    end
    visible = self:IsAnybodyTyping()
end

function ChatGui:IsAnybodyTyping()
    for _, v in pairs(typing) do
        if v ~= "" then
            return true
        end
    end
    return false;
end

function ChatGui:GetAmountOfPeopleWriting()
    local amount = 0
    for _, v in pairs(typing) do
        if v ~= "" then
            amount = amount + 1
        end
    end
    return amount
end

Hooks:Add("NetworkReceivedData", "NetworkReceivedDataChatInfo", function(sender, id, data)
    if id == "ChatInfo" then
        if id == "typing" then
            ChatGui:UpdateInfoText("add", sender, SydneyHUD:Peer(sender)._name or "Someone")
        else
            ChatGui:UpdateInfoText("remove", sender) -- When removing player from the table, I don't need to know his name, because it is not used
        end
    end
end)