-- Game Rules v.1

Player = setmetatable(
{
  MAX_ITEMS = 20,

  -- prototype
  proto = {
    -- data members
    name   = '',
    x      = 0,
    y      = 0,
    items  = {},

    -- inventory management
    get = function (self, selector)
      if type(selector) == 'number' and self.items[selector] then
        return table.remove(self.items, selector)
      else
        local index = self:list(selector)
        if index and self.items[index] then
          return table.remove(self.items, index)
        end
      end
      return nil
    end,

    put = function (self, item)
      if #self.items < Player.MAX_ITEMS then
        table.insert(self.items, item)
      else
        error('No free space')
      end
    end,

    list = function (self, selector)
      local result = {}
      for k, v in pairs(self.items) do
        if type(selector) == 'function' and selector(v) then
          table.insert(result, k)
        elseif type(selector) == 'string' and tostring(v) == selector then
          table.insert(result, k)
        elseif type(selector) == 'table' then
          local match, count = 0, 0
          for ks, vs in pairs(selector) do
            count = count + 1
            if v[ks] == vs then
              match = match + 1
            end
          end
          if count > 0 and match == count then
            table.insert(result, k)
          end
        end
      end
      return table.unpack(result)
    end,

    -- actions
    move = function(self, direction)
      local d = string.lower(direction)
      local prefix = _G.DEBUG and tostring(self) or self.name
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
        -- if target cell contains Building, Artifact or Path (River / Wormhole), trigger an event
        if cell ~= '' and self.map[cell] then
          self.map[cell](self)
          msg = msg .. ' ' .. self.map[cell].name .. (_G.DEBUG and ' (' .. cell .. ')' or '')
        end
      else
        msg = 'WALL(' .. self.map(self.x, self.y)[d] .. ')'
      end
      print(prefix .. ' move ' .. string.upper(direction) .. ' : ' .. msg)
      return result
    end,

    use  = function(self, what, where)
      local result = false
      local prefix = _G.DEBUG and tostring(self) or self.name
      if type(what) == 'table' then
        result = pcall(what, self.map(self.x, self.y), string.lower(where))
        local msg = result and 'OK' or 'FAILURE'
        print(prefix .. ' use ' .. tostring(what) .. ' ' .. where .. ' : ' .. msg)
      else
        print(prefix .. ' don\'t know how to use ' .. tostring(what))
      end
      return result
    end
  },
  -- metatable for Player instance
  instance_mt = {
    __tostring = function (self)
      local result = {}
      for _, k in ipairs({ 'name', 'x', 'y', 'items' }) do
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

Building = setmetatable({
  toString = function (self)
    return self.name
  end
},
{
  __call = function (self, name, func)
    return setmetatable({
      name = name,
      portable = false
    },
    {
      __call = func,
      __tostring = self.toString
    })
  end
})

Artifact = setmetatable({
  toString = function (self)
    return self.name
  end
},
{
  __call = function (self, name, func)
    return setmetatable({
      name = name,
      portable = true
    },
    {
      __call = func,
      __tostring = self.toString
    })
  end
})

Bomb = Artifact('bomb', function (self, cell, direction)
  if string.find('|-', cell[direction]) ~= nil then
    cell[direction] = ' '
  end
end)

Wormhole = setmetatable({
  fall = function (self, player)
    local pos = (self.index + 1)
    if pos > #self.chain then
      pos = 1
    end
    local dst = self.chain[pos]
    player.x = dst.x
    player.y = dst.y
  end
},
{
  __call = function (self, ...)
    self.chain = {}
    for i, v in ipairs(...) do
      v.parent[v.name] = setmetatable({
        name  = 'Wormhole',
        chain = self.chain,
        index = i
      },
      {
        __call = self.fall
      })
      table.insert(self.chain, v)
    end
  end
})
