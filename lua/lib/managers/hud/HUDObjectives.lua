-- Just animation stuff
function HUDList_set_offset(box, amount)
    local TOTAL_T = 0.18
    local OFFSET = box:y()
    local from_y = amount and 40 or 62 -- Rewrite this when more HUDList panels will use this animation
    local target_y = amount and 62 or 40
    local t = (1 - math.abs(box:y() - target_y) / OFFSET) * TOTAL_T
    while t < TOTAL_T do
        local dt = coroutine.yield()
        t = math.min(t + dt, TOTAL_T)
        local lerp = t / TOTAL_T
        box:set_y(math.lerp(from_y, target_y, lerp))
    end
end