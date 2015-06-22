
local capi = {
    awesome = awesome,
    screen = screen,
    client = client,
    drawin = drawin,

}
local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local object = require("gears.object")
local naughty = require("naughty")
local beautiful = require("beautiful")

local status_popup = require("status_popup")

require("obvious.clock")
require("obvious.loadavg")
require("obvious.battery")


function init()
    spacer = wibox.widget.textbox(' | ')

    volume_text = wibox.widget.textbox()
    volume_reg = vicious.register(volume_text, vicious.widgets.volume, "Vol: $2 $1%", 20, "Master")

    root.keys(awful.util.table.join(
        root.keys(),
        awful.key({ }, "XF86AudioRaiseVolume", function ()
            awful.util.spawn(volume_up,   false)
            vicious.force({volume_text})

        end),
        awful.key({ }, "XF86AudioLowerVolume", function ()
            awful.util.spawn(volume_down, false)
            vicious.force({volume_text})
        end),
        awful.key({ }, "XF86AudioMute",        function ()
            awful.util.spawn(volume_mute, false)
            vicious.force({volume_text})
        end)
    ))
    --Battery
    bat_text = wibox.widget.textbox()
    vicious.register(bat_text, vicious.widgets.bat, "Bat: $1 $2%", 30, "BAT0")

    date_short = wibox.widget.textbox()
    vicious.register(date_short, vicious.widgets.date, "%d %b %R", 60)

    local status_layout = wibox.layout.fixed.horizontal()
    status_layout:add(bat_text)
    status_layout:add(spacer)
    status_layout:add(volume_text)
    status_layout:add(spacer)
    status_layout:add(date_short)


    local popup = status_popup()

    status_layout:buttons(awful.button({ }, 1, function ()
        popup:toggle()
    end))
    popup.wibox:buttons(awful.button({ }, 1, function ()
        popup:toggle()
        -- popup:refresh()
    end))

    return status_layout
end

return init

