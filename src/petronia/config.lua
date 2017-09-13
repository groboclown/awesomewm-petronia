---------------------------------------------------------------------------
-- Configuration for the Petronia Layout
-- @module petronia
---------------------------------------------------------------------------

-- Global configuraiton.

-- Capture the globals here.
local ipairs = ipairs
local pairs = pairs


-- "setup" - how the screens and tags are split up.
_setup = {
  -- Array of roots
  roots = {}
  client_tile_assignment = {}
}

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


function Panel:_position(tile_index, parent_x, parent_y, parent_w, parent_h)

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


function RootPanel:_tile_position(tile_index)

end
