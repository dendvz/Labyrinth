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
      local map = self.map
      assert(string.len(key) == 1 and string.find('_news', key), 'invalid index \'' .. key .. '\' requested')
      if key == 'n' then return map.Cells[self.x][self.y - 1].s end
      if key == 'w' then return map.Cells[self.x - 1][self.y].e end
      return map.Cells[self.x][self.y][key]
    end,
    __newindex = function (self, key, value)
      assert(string.len(key) == 1 and string.find('_news', key), 'invalid index \'' .. key .. '\' requested')
      local map = self.map
      if key == 'n' then
        map.Cells[self.x][self.y - 1].s = value
      elseif key == 'w' then
        map.Cells[self.x - 1][self.y].e = value
      else
        map.Cells[self.x][self.y][key] = value
      end
    end,
    __tostring = function (self)
      local n = string.rep(self.map.Cells[self.x][self.y - 1].s, 3)
      local w = self.map.Cells[self.x - 1][self.y].e
      local e = self.map.Cells[self.x][self.y].e
      local s = string.rep(self.map.Cells[self.x][self.y].s, 3)
      local loc = self.map.Cells[self.x][self.y]['_']
      if string.len(loc) == 1 then loc = loc .. ' ' end
      return string.format('+%s+\n%s%3s%s\n+%s+', n, w, loc, e, s)
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
        self.Cells[x][y] = { x = x, y = y, map = self }
        self.Cells[x][y].s = border
        -- extract location info and vertical borders from previous line, if it exists
        self.Cells[x][y].e = (i == 1) and '' or string.sub(map[i - 1], x * 4 + 4, x * 4 + 4)
        self.Cells[x][y]._ = (i == 1) and '' or string.sub(map[i - 1], x * 4 + 1, x * 4 + 3):gsub('%s+', '')
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
      local result = {}
      for k, v in pairs(obj) do
        table.insert(result, string.format('%s=%s', k, type(v) == 'table' and self.toString(v) or tostring(v)))
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
  __call = function (self, x, y)
    assert( 1 <= x and x <= self.SizeX and 1 <= y and y <= self.SizeY,
            string.format('cell (%d,%d) is out of range', x , y))
    return setmetatable(self.Cells[x][y], self.cell_mt)
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
