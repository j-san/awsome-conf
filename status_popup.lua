
local capi = {
    timer = timer,
    screen = screen,
    mouse = mouse,
    client = client
}

local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local object = require("gears.object")
local surface = require("gears.surface")
local naughty = require("naughty")
local cairo = require("lgi").cairo
local setmetatable = setmetatable
local tonumber = tonumber
local string = string
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local print = print
local table = table
local type = type
local math = math
local vicious = require("vicious")


local status_popup = { mt = {} }

local table_update = function (t, set)
    for k, v in pairs(set) do
        t[k] = v
    end
    return t
end

local function set_coords(_status_popup)
    local s_geometry = capi.screen[1].workarea
    local screen_w = s_geometry.x + s_geometry.width
    local screen_h = s_geometry.y + s_geometry.height

    _status_popup.x = screen_w - 10 - _status_popup.width
    _status_popup.y = 30

    _status_popup.wibox.x = _status_popup.x
    _status_popup.wibox.y = _status_popup.y
end


local function set_size(_status_popup)
    _status_popup.wibox.height = _status_popup.height
    _status_popup.wibox.width = _status_popup.width

    _status_popup.width = _status_popup.wibox.width
    _status_popup.height = _status_popup.wibox.height

    return true
end

--- Show a status_popup.
function status_popup:show()
    set_size(self)
    set_coords(self)

    for k, widget in pairs(self.widgets) do
        vicious.activate(widget)
    end

    self.wibox.visible = true
end

--- Hide a status_popup popup.
function status_popup:hide()
    for k, widget in pairs(self.widgets) do
        vicious.unregister(widget, true)
    end

    self.wibox.visible = false
end

--- Toggle status_popup visibility.
function status_popup:toggle()
    if self.wibox.visible then
        self:hide()
    else
        self:show()
    end
end

function status_popup:add_vicious_widget(widget, wtype, format, timer, wargs)
    vicious.register(widget, wtype, format, timer, wargs)
    vicious.unregister(widget, true)
    table.insert(self.widgets, widget)
    self.layout:add(widget)
end

function status_popup:text(wtype, format, timer, wargs)
    local text = wibox.widget.textbox()

    if format == nil then
        text:set_text(wtype)
        self.layout:add(text)

        return text
    end

    self:add_vicious_widget(text, wtype, format, timer, wargs)

    return text
end

function status_popup:link(text, command)
    local link = wibox.widget.textbox(text)

    link:buttons(awful.button({ }, 1, function ()
        awful.util.spawn(command)
    end))

    return link
end

function status_popup:progress(wtype, format, timer, wargs)
    local progress = awful.widget.progressbar()
    progress:set_height(8)
    progress:set_vertical(false)
    progress:set_background_color(self.theme.bg_minimize)
    progress:set_border_color(self.theme.border_focus)
    progress:set_color(self.theme.bg_urgent)

    self:add_vicious_widget(progress, wtype, format, timer, wargs)

    return progress
end

function status_popup.init(_status_popup)
    _status_popup.layout = wibox.layout.fixed.vertical()

    date_long = _status_popup:text(vicious.widgets.date, "%d-%m-%y %T", 1)
    date_long:set_font('sans mono 12 bold')

    _status_popup:text(vicious.widgets.pkg, "$1 packages available for update", 600, "Arch")
    _status_popup:text(vicious.widgets.fs, "Root: ${/ avail_gb}GB free of ${/ size_gb}GB", 37)
    _status_popup:progress(vicious.widgets.fs, "${/ used_p}", 37)

    _status_popup:text(vicious.widgets.fs, "Home: ${/home avail_gb}GB  free of ${/home size_gb}GB", 37)
    _status_popup:progress(vicious.widgets.fs, "${/home used_p}", 37)

    _status_popup:text(vicious.widgets.mem, "Memory: $2Mb used of $3Mb", 3)
    _status_popup:progress(vicious.widgets.mem, "$1", 3)

    _status_popup:text(vicious.widgets.cpu, "CPU: $1%", 1)
    _status_popup:progress(vicious.widgets.cpu, "$1", 1)
    _status_popup:text("CPUs:")
    _status_popup:progress(vicious.widgets.cpu, "$2", 0.5)
    _status_popup:progress(vicious.widgets.cpu, "$3", 0.5)
    _status_popup:progress(vicious.widgets.cpu, "$4", 0.5)
    _status_popup:progress(vicious.widgets.cpu, "$5", 0.5)

    local links_layout = wibox.layout.fixed.horizontal()

    links_layout:add(_status_popup:link("top cpu", terminal .. " -e 'top -o %CPU'"))
    links_layout:add(wibox.widget.textbox(" | "))
    links_layout:add(_status_popup:link("top mem", terminal .. " -e 'top -o %MEM'"))
    links_layout:add(wibox.widget.textbox(" | "))
    links_layout:add(_status_popup:link("syslog", terminal .. " -e 'top -o %MEM'"))
    _status_popup.layout:add(links_layout)

    margin = wibox.layout.margin(_status_popup.layout, 8, 8, 4, 4)

    _status_popup.wibox:set_widget(margin)
end

function status_popup.new(args, parent)
    args = args or {}
    local _status_popup = table_update(object(), {
        height = 200,
        width = 300,
        toggle = status_popup.toggle,
        hide = status_popup.hide,
        show = status_popup.show,
        text = status_popup.text,
        link = status_popup.link,
        add_vicious_widget = status_popup.add_vicious_widget,
        progress = status_popup.progress,
        widgets = {}
    })
    _status_popup.theme = beautiful.get()

    if parent then
        _status_popup.auto_expand = parent.auto_expand
    elseif args.auto_expand ~= nil then
        _status_popup.auto_expand = args.auto_expand
    else
        _status_popup.auto_expand = true
    end

    _status_popup.wibox = wibox({
        ontop = true,
        fg = _status_popup.theme.fg_focus,
        bg = _status_popup.theme.bg_normal,
        border_color = _status_popup.theme.border_focus,
        border_width = _status_popup.theme.border_width,
        type = "popup_status_popup" })

    status_popup.init(_status_popup)

    _status_popup.wibox.visible = false
    set_size(_status_popup)
    _status_popup.x = _status_popup.wibox.x
    _status_popup.y = _status_popup.wibox.y

    return _status_popup
end

function status_popup.mt:__call(...)
    return status_popup.new(...)
end

return setmetatable(status_popup, status_popup.mt)
