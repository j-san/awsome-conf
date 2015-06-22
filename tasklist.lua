
local wibox = require("wibox")
local common = require("awful.widget.common")


function tasklist(w, buttons, label, data, objects)
  -- update the widgets, creating them if needed
  w:reset()
  for i, o in ipairs(objects) do
    local cache = data[o]
    local ib, tb, bgb, m, l
    if cache then
        ib = cache.ib
        -- tb = cache.tb
        bgb = cache.bgb
        m   = cache.m
    else
        ib = wibox.widget.imagebox()
        -- tb = wibox.widget.textbox()
        bgb = wibox.widget.background()
        m = wibox.layout.margin(ib, 4, 4)
        l = wibox.layout.fixed.horizontal()

        -- All of this is added in a fixed widget
        l:fill_space(false)
        -- l:add(ib)
        l:add(m)

        -- And all of this gets a background
        bgb:set_widget(l)

        bgb:buttons(common.create_buttons(buttons, o))

        data[o] = {
            ib = ib,
            tb = tb,
            bgb = bgb,
            m   = m
        }
    end

    local text, bg, bg_image, icon = label(o)
    -- The text might be invalid, so use pcall
    -- if not pcall(tb.set_markup, tb, text) then
    --     tb:set_markup("<i>&lt;Invalid text&gt;</i>")
    -- end
    bgb:set_bg(bg)
    -- if type(bg_image) == "function" then
    --     bg_image = bg_image(tb,o,m,objects,i)
    -- end
    bgb:set_bgimage(bg_image)
    ib:set_image(icon)
    w:add(bgb)
  end
end

return tasklist