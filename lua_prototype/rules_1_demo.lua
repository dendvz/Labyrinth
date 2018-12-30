#!/usr/bin/env lua

--[[
     1   2   3   4   5   6   7   8
   +###+###+###+###+###+###+###+###+
 1 #                _v2            #
   +---+---+---+   +---+---+---+   +
 2 #       | e         |    _w2|   #
   +   +   + ^ +   +---+---+   +   +
 3 # A |   | ^ < < < < < <         #
   +   +   +   +---+   + ^ +---+---+
 4 #   |       |       | ^  _v3    #
   +   +   +---+---+   + ^ +   +---+
 5 #       |        _w3| s     |
   +   +   +---+   +   +   +   +   +
 6 #   |   |       |   |   |   |   #
   +   +   +   +   +   +---+   +   +
 7 #_v1|       |        _w4|   |   #
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

L.A = Object('Arsenal', function (self, player)
  player.ammo = {
    bombs = 3,
    rounds = 3
  }
end)

-- dummy bot: walk north, demolish walls until running out of bombs
function dummy(player)
  local done = false
  repeat
    if not player:move('N') then
      if player.ammo.bombs > 0 then
        player:use('bomb', 'N')
      else
        done = true
      end
    end
  until done
end

p1 = Player 'Alice'
L:setPlayer(p1, 1, 5)
print(p1)

-- Run bot
dummy(p1)
print(L)
