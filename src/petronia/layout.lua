-------------------------------------
-- Petronia layouts module for awful
-- 
-- @module petronia
-------------------------------------


local tag = require("awful.tag")
local ipairs = ipairs
local client = require("awful.client")
local capi = {
  mouse = mouse,
  screen = screen,
  mousegrabber = mousegrabber
}

-- The Petronia layout layoutbox icon
-- @beautiful petronia.layout_petronia
-- @param surface
-- @see gears.surface

local tile = {}

-- Jump mouse cursor to the client's corner when resizing it
tile.resize_jump_to_corner = true

-- Petronia allows for resizing a window however you want.
tile.mouse_resize_handler = require("awful.layout.suit.floating").mouse_resize_handler

-- The setup configuration for the layout
tile.tiles = {}


-- The petronia layout
-- @clientlayout petronia.layout.

function tile.arrange(p)
  local wa = p.workarea
  local cls = p.clients
  local g = p:geometry()
  local screen = p.screen
end

tile.name = "petronia"

return tile

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
