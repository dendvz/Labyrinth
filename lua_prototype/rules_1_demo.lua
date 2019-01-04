#!/usr/bin/env lua

--[[
     1   2   3   4   5   6   7   8
   +###+###+###+###+###+###+###+###+
 1 #                 v2            #
   +---+---+---+   +---+---+---+   +
 2 # w1    | e         |       |   #
   +---+   + ^ +   +---+---+   +   +
 3 # A |   | ^ < < < < < <         #
   +   +   +   +---+   + ^ +---+---+
 4 #   | w3    |       | ^   v1    #
   +   +---+---+---+   + ^ +   +---+
 5 #       |           | s     |
   +---+   +---+   +   +   +   +   +
 6 #   | w2|       |   |   |   |   #
   +   +   +   +   +   +---+   +   +
 7 # v3|       |           | w4|   #
   +   +   +   +   +---+---+   +   +
 8 #       |   |     T |           #
   +###+###+###+###+###+###+###+###+
]]

local L = require 'Labyrinth'
require 'Rules_1'

-- DEMO
--

-- print map
print(string.format("%dx%d", L.SizeX, L.SizeY))
print(L)

L.A = Building('Arsenal', function (self, player)
  while #{player:list('bomb')} < 3 do
    player:put(Bomb)
  end
end)

-- Connect wormholes
Wormhole { L('w1'), L('w2'), L('w3'), L('w4') }
Wormhole { L('v1'), L('v2'), L('v3') }

-- dummy bot: walk north, demolish walls until running out of bombs
function dummy(player)
  local done = false
  repeat
    if not player:move('N') then
      if player:list('bomb') then
        player:use(player:get('bomb'), 'N')
      else
        done = true
      end
    end
  until done
end

p1 = Player 'Alice'
L:setPlayer(p1, 1, 5)

-- enable debug printout
_G.DEBUG = true

-- Run bot
dummy(p1)
print(L)
