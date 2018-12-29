#!/usr/bin/env lua

require 'Rules_1'

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
