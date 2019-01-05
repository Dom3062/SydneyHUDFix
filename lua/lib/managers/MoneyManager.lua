local function GetTimeText(time)
    time = math.max(math.floor(time), 0)
    local minutes = math.floor(time / 60)
    time = time - minutes * 60
    local seconds = math.round(time)
    local text = ""

    return text .. (minutes < 10 and "0" .. minutes or minutes) .. ":" .. (seconds < 10 and "0" .. seconds or seconds)
end

function MoneyManager:civilian_killed()
    local deduct_amount = self:get_civilian_deduction()

    if deduct_amount == 0 then
        return
    end
    
    self.civilians_killed = (self.civilians_killed or 0) + 1

    local text = managers.localization:text("hud_civilian_killed_message", {AMOUNT = managers.experience:cash_string(deduct_amount)})
    local title = managers.localization:text("hud_civilian_killed_title")
    
    if SydneyHUD:GetOption("show_trade_delay") then
        title = title .. " " .. utf8.to_upper(managers.localization:text("hud_trade_delay", {TIME = tostring(GetTimeText(5 + (self.civilians_killed * 30)))}))
    end

    managers.hud:present_mid_text({
        time = 4,
        text = text,
        title = title
    })
    self:_deduct_from_total(deduct_amount)
end

function MoneyManager:ResetCivilianKills()
    self.civilians_killed = 0
end