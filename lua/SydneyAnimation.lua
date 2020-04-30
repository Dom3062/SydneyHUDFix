SydneyAnimation = SydneyAnimation or class()

function SydneyAnimation:ColorChange(o, new_color, color_function, old_color)
    new_color = new_color or Color.white
    color_function = color_function or o.set_color
    old_color = old_color or o:color()
    local t = 0

    while t < 1 do
        t = t + coroutine.yield()
        local r = old_color.r + (t * (new_color.r - old_color.r))
        local g = old_color.g + (t * (new_color.g - old_color.g))
        local b = old_color.b + (t * (new_color.b - old_color.b)) 
        color_function(Color(255, r, g, b), true)
    end
    color_function(new_color, true)
end