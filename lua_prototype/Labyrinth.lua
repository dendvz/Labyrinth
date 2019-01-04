-- Labyrinth map

local Labyrinth = setmetatable(
{
  Objects = {},
  Players = {},
  Cells   = {},
  SizeX   = 0,
  SizeY   = 0,

  -- metatable for cell
  cell_mt = {
    __index = function (self, key)
      local parent = self.parent
      assert(string.len(key) == 1 and string.find('_news', key), 'invalid index \'' .. key .. '\' requested')
      if key == 'n' then return parent.Cells[self.x][self.y - 1].s end
      if key == 'w' then return parent.Cells[self.x - 1][self.y].e end
      return parent.Cells[self.x][self.y][key]
    end,
    __newindex = function (self, key, value)
      assert(string.len(key) == 1 and string.find('_news', key), 'invalid index \'' .. key .. '\' requested')
      local parent = self.parent
      if key == 'n' then
        parent.Cells[self.x][self.y - 1].s = value
      elseif key == 'w' then
        parent.Cells[self.x - 1][self.y].e = value
      else
        parent.Cells[self.x][self.y][key] = value
      end
    end,
    __tostring = function (self)
      local parent = self.parent
      local n = string.rep(parent.Cells[self.x][self.y - 1].s, 3)
      local w = parent.Cells[self.x - 1][self.y].e
      local e = parent.Cells[self.x][self.y].e
      local s = string.rep(parent.Cells[self.x][self.y].s, 3)
      local loc = parent.Cells[self.x][self.y]['_']
      if string.len(loc) == 1 then loc = loc .. ' ' end
      return string.format('+%s+\n%s%3s%s\n+%s+', n, w, loc, e, s)
    end
  },

  obj_mt = {
    __tostring = function (self)
      local result = {}
      for k, v in pairs(self) do
        table.insert(result, string.format('%s=%s', k, tostring(v)))
      end
      return '{ ' .. table.concat(result, ', ') .. ' }'
    end
  },

  loadMap = function (self, fileName)
    local map = {}
    local mapFound = false
    for str in io.lines(fileName) do
      if (mapFound) then
        if (str ~= ']]') then
          table.insert(map, str)
        else
          mapFound = false
        end
      elseif (str == '--[[' and #map == 0) then
        mapFound = true
      end
    end
    local y = 0
    for i = 1, #map do
      local x = 0
      -- pattern: 3 identical characters from set [- #], immediately followed by '+'
      for border in string.gmatch(map[i], '[# %-]([# %-<>v%^])[# %-]%+') do
        if not self.Cells[x] then
          self.Cells[x] = {}
        end
        self.Cells[x][y] = { x = x, y = y, parent = self }
        self.Cells[x][y].s = border
        -- extract location info and vertical borders from previous line, if it exists
        self.Cells[x][y].e = (i == 1) and '' or string.sub(map[i - 1], x * 4 + 4, x * 4 + 4)
        obj = (i == 1) and '' or string.sub(map[i - 1], x * 4 + 1, x * 4 + 3):gsub('%s+', '')
        self.Cells[x][y]._ = obj
        if obj ~= '' and string.find('<>^v', obj) == nil then
          self.Objects[obj] = { name = obj, x = x, y = y, parent = self }
        end
        x = x + 1
      end -- for border
      if x > 0 then
        y = y + 1
      end
    end -- for i
    self.SizeY = #self.Cells
    self.SizeX = #self.Cells[self.SizeY]
  end, -- LoadMap

  setPlayer = function (self, player, x, y)
    table.insert(self.Players, player)
    player.map = self
    player.x   = x
    player.y   = y
  end, -- setPlayer

  toString = function (self, obj)
    if type(obj) == 'table' then
      local mt = getmetatable(obj)
      if mt and mt.__tostring then
        return tostring(obj)
      end
      local result = {}
      for k, v in pairs(obj) do
        table.insert(result, string.format('%s=%s', k, self:toString(v)))
      end
      if #result == 0 then
        return '{}'
      end
      return '{ ' .. table.concat(result, ', ') .. ' }'
    end
    return tostring(obj)
  end
},
-- metatable for Labyrinth object
{
  __call = function (self, arg1, arg2)
    if type(arg1) == 'number' and type(arg2) == 'number' then
      local x, y = arg1, arg2
      assert( 1 <= x and x <= self.SizeX and 1 <= y and y <= self.SizeY,
              string.format('cell (%d,%d) is out of range', x , y))
      return setmetatable(self.Cells[x][y], self.cell_mt)
    elseif arg2 == nil and type(arg1) == 'string' then
      local objName = arg1
      return setmetatable(self.Objects[objName], self.obj_mt)
    end
  end,

  __tostring = function (self)
    local result = ''
    for y = 0, self.SizeY do
      for x = 0, self.SizeX do
        local loc = self.Cells[x][y]._
        if string.len(loc) == 1 then loc = loc .. ' ' end
        result = result .. string.format('%3s%1s', loc, self.Cells[x][y].e)
      end
      result = result .. '\n'
      for x = 0, self.SizeX do
        result = result .. string.rep(self.Cells[x][y].s, 3) .. '+'
      end
      result = result .. '\n'
    end
    return result
  end
})

Labyrinth:loadMap(debug.getinfo(3, 'S').short_src)

return Labyrinth
