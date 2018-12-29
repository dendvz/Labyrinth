Utils = {
  toString = function (obj)
    local result = {}
    for k, v in pairs(obj) do
      table.insert(result, string.format('%s=%s', k, type(v) == 'table' and Utils.toString(v) or tostring(v)))
    end
    return '{ ' .. table.concat(result, ', ') .. ' }'
  end
}

Player = setmetatable(
{
  -- prototype
  proto = {
    -- data members
    name   = '',
    x      = 0,
    y      = 0,
    ammo   = {},
    -- actions
    move = function(self, direction)
      local d = string.lower(direction)
      local msg = 'OK'
      local action = {
        n = function(p) if Map(p.x, p.y).n == ' ' then p.y = p.y - 1 else error() end end,
        s = function(p) if Map(p.x, p.y).s == ' ' then p.y = p.y + 1 else error() end end,
        w = function(p) if Map(p.x, p.y).w == ' ' then p.x = p.x - 1 else error() end end,
        e = function(p) if Map(p.x, p.y).e == ' ' then p.x = p.x + 1 else error() end end
      }
      local result = pcall(action[d], self)
      if result then
        local cell = Map(self.x, self.y)._
        if cell ~= '' and Map[cell] then
          Map[cell](self)
          msg = msg .. ' ' .. Map[cell].name
        end
      else
        msg = 'WALL(' .. Map(self.x, self.y)[d] .. ')'
      end
      print(self.name .. ' move ' .. string.upper(direction) .. ' : ' .. msg)
      return result
    end,
    use  = function(self, what, where)
      if what == 'bomb' then
        local result = false
        local msg = 'OK'
        local action = {
          n = function(p) if Map(p.x, p.y).n == '-' then Map(p.x, p.y).n = ' ' end end,
          s = function(p) if Map(p.x, p.y).s == '-' then Map(p.x, p.y).s = ' ' end end,
          w = function(p) if Map(p.x, p.y).w == '|' then Map(p.x, p.y).w = ' ' end end,
          e = function(p) if Map(p.x, p.y).e == '|' then Map(p.x, p.y).e = ' ' end end
        }
        if self.ammo.bombs > 0 then
          result = pcall(action[string.lower(where)], self)
          self.ammo.bombs = self.ammo.bombs - 1
        else
          msg = 'out of bombs'
        end
        print(self.name .. ' use bomb ' .. string.upper(where) .. ' : ' .. msg)
        return result
      end
    end
  },
  -- metatable for Player instance
  instance_mt = {
    __tostring = function (self)
      return Utils.toString(self)
    end,
    __index = function (self, key)
      return Player.proto[key]
    end
  }
},
-- metatable for Player class
{
  __call = function (self, obj)
    local ret = {}
    if type(obj) == 'string' then
      ret.name = obj
    elseif type(obj) == 'table' then
      ret = obj
    end
    if ret.name and #ret.name then
      return setmetatable(ret, Player.instance_mt)
    end
    error('Player must have name')
  end
})

Map = setmetatable(
{
  SizeX   = 0,
  SizeY   = 0,
  Objects = {},
  Cells   = {},

  -- metatable for cell
  cell_mt = {
    __index = function (self, key)
      assert(string.len(key) == 1 and string.find('news_', key), 'invalid index \'' .. key .. '\' requested')
      if key == 'n' then return Map.Cells[self.x][self.y - 1].s end
      if key == 'w' then return Map.Cells[self.x - 1][self.y].e end
      return Map.Cells[self.x][self.y][key]
    end,
    __newindex = function (self, key, value)
      assert(string.len(key) == 1 and string.find('news_', key), 'invalid index \'' .. key .. '\' requested')
      if key == 'n' then
        Map.Cells[self.x][self.y - 1].s = value
      elseif key == 'w' then
        Map.Cells[self.x - 1][self.y].e = value
      else
        Map.Cells[self.x][self.y][key] = value
      end
      return Map(self.x, self.y)
    end,
    __tostring = function (self)
      local n = string.rep(Map.Cells[self.x][self.y - 1].s, 3)
      local w = Map.Cells[self.x - 1][self.y].e
      local e = Map.Cells[self.x][self.y].e
      local s = string.rep(Map.Cells[self.x][self.y].s, 3)
      local loc = Map.Cells[self.x][self.y]['_']
      if string.len(loc) == 1 then loc = loc .. ' ' end
      return string.format('+%s+\n%s%3s%s\n+%s+', n, w, loc, e, s)
    end
  },

  init = function(self, sizeX, sizeY)
    self.SizeX = sizeX
    self.SizeY = sizeY

    for x = 0, sizeX do
      self.Cells[x] = {}
      for y = 0, sizeY do
        -- set up walls
        self.Cells[x][y] = {
          x = x,
          y = y,
          e = ((x == 0 or x == SizeX) and '#' or ' '),
          s = ((y == 0 or y == SizeY) and '#' or ' ')
        }
        self.Cells[x][y]['_'] = ''
      end
    end
  end
},
{
  __call = function(self, x, y)
    assert( 1 <= x and x <= self.SizeX and 1 <= y and y <= self.SizeY,
            string.format('cell Map(%d,%d) is out of range', x , y))
    return setmetatable({ x = x, y = y }, Map.cell_mt)
  end
})

Object = setmetatable(
{},
{
  __call = function (self, name, func)
    return setmetatable({ name = name }, { __call = func })
  end
})

-- DEMO
--
--
--
-- initialize map 10x10
Map:init(10, 10)
-- build wall
Map(5, 2).s = '-'
-- set up Arsenal
Map(5, 3)._ = 'A'

Map.A = Object('Arsenal', function (self, player)
  player.ammo = {
    bombs = 3,
    rounds = 3
  } 
end)

-- dummy bot: walk north, demolish walls until running out of bombs
function dummy(player)
  repeat
    if not player:move('N') then
      player:use('bomb', 'N')
    end
  until player.ammo.bombs == 0
end

p1 = Player { name = 'Alice', x = 5, y = 5 }
print(p1)

-- initialize with defaults
p2 = Player 'Bob'
print(p2)

-- Run bot
dummy(p1)
