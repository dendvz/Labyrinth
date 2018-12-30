Player = setmetatable(
{
  -- prototype
  proto = {
    -- data members
    name   = '',
    x      = 0,
    y      = 0,
    ammo   = { bombs = 0, rounds = 0 },
    -- actions
    move = function(self, direction)
      local d = string.lower(direction)
      local msg = 'OK'
      local action = {
        n = function(p) if self.map(p.x, p.y).n == ' ' then p.y = p.y - 1 else error() end end,
        s = function(p) if self.map(p.x, p.y).s == ' ' then p.y = p.y + 1 else error() end end,
        w = function(p) if self.map(p.x, p.y).w == ' ' then p.x = p.x - 1 else error() end end,
        e = function(p) if self.map(p.x, p.y).e == ' ' then p.x = p.x + 1 else error() end end
      }
      local result = pcall(action[d], self)
      if result then
        local cell = self.map(self.x, self.y)._
        if cell ~= '' and self.map[cell] then
          self.map[cell](self)
          msg = msg .. ' ' .. self.map[cell].name
        end
      else
        msg = 'WALL(' .. self.map(self.x, self.y)[d] .. ')'
      end
      print(self.name .. ' move ' .. string.upper(direction) .. ' : ' .. msg)
      return result
    end,

    use  = function(self, what, where)
      if what == 'bomb' then
        local result = false
        local msg = 'OK'
        local action = {
          n = function(p) if self.map(p.x, p.y).n == '-' then self.map(p.x, p.y).n = ' ' end end,
          s = function(p) if self.map(p.x, p.y).s == '-' then self.map(p.x, p.y).s = ' ' end end,
          w = function(p) if self.map(p.x, p.y).w == '|' then self.map(p.x, p.y).w = ' ' end end,
          e = function(p) if self.map(p.x, p.y).e == '|' then self.map(p.x, p.y).e = ' ' end end
        }
        if self.ammo and self.ammo.bombs > 0 then
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
      local result = {}
      for _, k in ipairs({ 'name', 'x', 'y', 'ammo' }) do
        table.insert(result, string.format('%s=%s', k, self.map:toString(self[k])))
      end
      return '{ ' .. table.concat(result, ', ') .. ' }'
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

Object = setmetatable(
{},
{
  __call = function (self, name, func)
    return setmetatable({ name = name }, { __call = func })
  end
})
