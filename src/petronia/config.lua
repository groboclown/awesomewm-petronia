---------------------------------------------------------------------------
-- Configuration for the Petronia Layout
-- @module petronia
---------------------------------------------------------------------------

-- Global configuraiton.

-- Capture the globals here.
local ipairs = ipairs
local pairs = pairs

DIRECTION_VERTICAL = "vertical"
DIRECTION_HORIZONTAL = "horizontal"


-- "setup" - how the screens and tags are split up.
_setup = {
  -- Array of roots
  roots = {}
  client_tile_assignment = {}
}

function _get_position_for_client(client)
  local best_match_factor = 0
  local best_match_root = nil
  for i,v in pairs(_setup.roots) do
    local factor = v:_match_factor(client)
	if best_match_root == nil or factor > best_match_factor then
	  best_match_root = v
	  best_match_factor = factor
	end
  end
  if best_match_root == nil then
	error("no root window registered")
  end
  local tile_index = client_tile_assignment[ _mk_client_id(client) ] or 0
  return best_match_root:_tile_position(client, tile_index)
end

function _mk_client_id(client)
  return "" .. client.pid .. ":" .. client.instance
end

local Panel = {}
function Panel:new(o, parent)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o._type = nil
  o._direction = nil
  o._size_factor = nil
  o._parent = parent or nil
  o._children = {}
  o._index = -1
  o._snap = "nw"

  return o
end

local RootPanel = Panel:new()


-- Create a root window.  This defines how it can be used.
-- The options defines how the system matches the screen
-- and tag to the root display.
function root(options)
  local rp = RootPanel:new()
  if type(options.name) ~= "string" then
	error("no `name` option")
  end
  rp.name = options.name
  rp._screens = {}
  rp._tags = {}
  rp._sizes = {}
  rp._child_count = 0
  if type(options.screens) == "table" then
	for k, v in pairs(options.screens) do
	  if type(v) == "number" then
		rp._screens[#rp._screens + 1] = v
	  end
	end
  elseif type(options.screen) == "number" then
	rp._screens[0] = options.screen
  end
  if type(options.tags) == "table" then
	for k, v in pairs(options.tags) do
	  if type(v) == "string" or type(v) == "number" then
		rp._tags[#rp._tags + 1] = v
	  end
	end
  elseif type(options.tag) == "string" or type(options.tag) == "number" then
    rp._tags[0] = options.tag
  end
  if type(options.sizes) == "table" then
	for k, v in pairs(options.sizes) do
	  if type(v) == "table" and type(v.x) == "number" and type(v.y) == "number" then
		rp._sizes[0] = { x=v.x; y=v.y }
	  elseif type(v) == "table" and type(v.w) == "number" and type(v.h) == "number" then
		rp._sizes[0] = { x=v.w; y=v.h }
	  elseif type(v) == "table" and type(v.width) == "number" and type(v.height) == "number" then
		rp._sizes[0] = { x=v.width; y=v.height }
	  end
	end
  elseif type(options.size) == "table" then
	if type(options.size.x) == "number" and type(options.size.y) == "number" then
	  rp._sizes[0] = { x=options.size.x; y=options.size.y }
	elseif type(options.size.w) == "number" and type(options.size.h) == "number" then
	  rp._sizes[0] = { x=options.size.w; y=options.size.h }
	elseif type(options.size.width) == "number" and type(options.size.height) == "number" then
	  rp._sizes[0] = { x=options.size.width; y=options.size.height }
	end
  end

  _setup.roots[#_setup.roots + 1] = rp
  return rp
end



-- Define this Panel as a tile, where a client window can live.
function Panel:as_tile(split_size_factor)
  if self._type ~= nil then
	error("already set type")
  end
  self._type = "tile"
  self._size_factor = split_size_factor
  local r = self:_root()
  self._index = r._child_count
  r._child_count = r._child_count + 1
  return self
end


function Panel:as_container(split_direction)
  if self._type ~= nil then
	error("already set type")
  end
  if split_direction ~= DIRECTION_VERTICAL and split_direction ~= DIRECTION_HORIZONTAL then
	error("split_direction can only be `" .. DIRECTION_VERTICAL .. "` or `" .. DIRECTION_HORIZONTAL .. "`")
  end
  self._type = "container"
  self._direction = split_direction
  return self
end


function Panel:with_child(f)
  local child = Panel:new({}, self)
  self._children[#self._children + 1] = child
  if type(f) == "function" then
	f(child)
	return self
  end
  return child
end


function Panel:_root()
  if self._parent == nil then
	return self
  end
  return self._parent:_root()
end


function Panel:_has_tile_index(index)
  for i,v in ipairs(self._children) do
	if v:_has_tile_index(index) then
	  return true
	end
  end
  return self._index == index
end


-- @param panel_? - coordinates of this panel, as calculated by
--   the parent panel.
-- return a table with { x, y, width, height, snap }
-- `snap` is one of "ne", "nw", "se", "sw"
function Panel:_position(args)
  local tile_index = args.tile_index
  local panel_x = args.panel_x
  local panel_y = args.panel_y
  local panel_w = args.panel_w
  local panel_h = args.panel_h

  if self._index == tile_index then
	return { x=panel_x, y=panel_y, width=panel_w, height=panel_h, snap=self._snap }
  end
  -- figure out the total size factors of the children
  local size_total = 0
  for i,v in ipairs(self._children) do
	if v._index == tile_index and v._size_factor == 0 then
	  -- full split
      return { x=panel_x, y=panel_y, width=panel_w, height=panel_h, snap=self._snap }
	end
    size_total = size_total + v._size_factor
  end
  local const_pos_index = "panel_x"
  local const_pos = panel_x
  local split_pos_index = "panel_y"
  local split_start_pos = panel_y
  local split_pos = panel_y
  local const_size_index = "panel_w"
  local const_size = panel_w
  local split_size_index = "panel_h"
  local total_split_size = panel_h
  if self._direction == DIRECTION_HORIZONTAL then
	const_pos_index = "panel_y"
	const_pos = panel_y
	split_pos_index = "panel_x"
	split_start_pos = panel_x
	split_pos = panel_x
	const_size_index = "panel_h"
	const_size = panel_h
	split_size_index = "panel_w"
	total_split_size = panel_w
  end
  local ret = {}
  ret[const_pos_index] = const_pos
  ret[const_size_index] = const_size
  local split_inc_pos = 0
  for i,v in ipairs(self._children) do
	local split_size = ((total_pos * v._size_factor) / size_total)
    local split_endpos = split_inc_pos + ((total_pos * v._size_factor) / size_total)

	-- avoid rounding errors
	if i == #self._children then
	  split_size = total_split_size - split_inc_pos
	end

	-- don't need to worry about `0` size factor here.
	if v:_has_tile_window(tile_index) then
	  ret[split_pos_index] = split_start_pos + split_inc_pos
	  ret[split_size_index] = split_size
	  return v:_position(ret)
	end
  end
  error("No tile index contained in this panel")
end


-- return 0 == no match, 100 = full match
function RootPanel:_match_factor(client)
  local s = client.screen
  local g = s.geometry
  local tag = s.selected_tag

  local factor = 0
  local screen_match = false

  for i,v in pairs(self._screens) do
	if v == s.index then
	  factor += 50
	  screen_match = true
	  break
	end
  end
  if ! screen_match then
	local max_screen_match = 0
    for i,v in pairs(self._sizes) do
      local mx = (100 - math.abs(v.x - g.width)) / 4
	  local my = (100 - math.abs(v.y - g.height)) / 4
	  if mx >= 0 and my >= 0 and mx + my > max_screen_match then
		max_screen_match = mx + my
	  end
	end
	factor += max_screen_match
  end

  for i,v in pairs(self._tags) do
	if v == tag.index or v == tag.name then
      factor += 50
	  break
	end
  end

  return factor
end


function RootPanel:_tile_position(client, tile_index)
  local g = client.screen.workarea

  return self:_position{
	tile_index = tile_index;
	panel_x = g.x;
	panel_y = g.y;
	panel_w = g.width;
	panel_h = g.height;
  }
end
