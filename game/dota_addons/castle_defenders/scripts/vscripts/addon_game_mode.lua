-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  print ("[BAREBONES] Performing pre-load precache")

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  PrecacheUnitByNameSync("creep_wave_1", context)
  PrecacheUnitByNameSync("creep_wave_2", context)
  PrecacheUnitByNameSync("creep_wave_3", context)
  PrecacheUnitByNameSync("creep_wave_4", context)
  PrecacheUnitByNameSync("creep_wave_5", context)
  PrecacheUnitByNameSync("creep_wave_6", context)
  PrecacheUnitByNameSync("creep_wave_7", context)
  PrecacheUnitByNameSync("creep_wave_8", context)
  PrecacheUnitByNameSync("creep_wave_9", context)
  PrecacheUnitByNameSync("creep_wave_10", context)

end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
end