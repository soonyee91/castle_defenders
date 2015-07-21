-- This is the primary barebones gamemode script and should be used to assist in initializing your game mode


-- Set this to true if you want to see a complete debug output of all events/processes done by barebones
-- You can also change the cvar 'barebones_spew' at any time to 1 or 0 for output/no output
BAREBONES_DEBUG_SPEW = false 

if GameMode == nil then
    print ( '[BAREBONES] creating barebones game mode' )
    _G.GameMode = class({})
end

-- This library allow for easily delayed/timed actions
require('libraries/timers')
--[[
-- This library can be used for advancted physics/motion/collision of units.  See PhysicsReadme.txt for more information.
require('libraries/physics')
-- This library can be used for advanced 3D projectile systems.
require('libraries/projectiles')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')
]]
-- These internal libraries set up barebones's events and processes.  Feel free to inspect them/change them if you need to.
require('internal/gamemode')
require('internal/events')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')


--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function GameMode:PostLoadPrecache()
  print ("[BAREBONES] Performing Post-Load precache")    
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  --PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
  --PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
  print ("[BAREBONES] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
  print ("[BAREBONES] All Players have loaded into the game")
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame(hero)
  print ("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())

  -- This line for example will set the starting gold of every hero to 500 unreliable gold
  hero:SetGold(500, false)

  -- These lines will create an item and add it to the player, effectively ensuring they start with the item
  --local item = CreateItem("item_example_item", hero, hero)
  --hero:AddItem(item)

  --[[ --These lines if uncommented will replace the W ability of any hero that loads into the game
    --with the "example_ability" ability

  local abil = hero:GetAbilityByIndex(1)
  hero:RemoveAbility(abil:GetAbilityName())
  hero:AddAbility("example_ability")]]
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
  GameMode = self
  print ('[BAREBONES] Starting to load Barebones gamemode...')

  -- Call the internal function to set up the rules/behaviors specified in constants.lua
  -- This also sets up event hooks for all event handlers in events.lua
  -- Check out internals/gamemode to see/modify the exact code
  GameMode:_InitGameMode()

  print ('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this tSpawnPosition,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function GameMode:OnGameInProgress()
  print("[Castle_Defender] The game has officially begun")
  
  local iUpdateInterval = 1

  UpdatePreGame()
  Timers:CreateTimer(function()
    Update()
    return iUpdateInterval 
  end)

    --[[
    Timers:CreateTimer(start_after, function()
      CheckRoundEnd()
      return check_interval
    end)
  ]]

end

--[[ 
=============================================================================
  OUR CODES STARTS FROM HERE
=============================================================================

iVariable = int
tVariable = Tables
bVariable = boolean
vVariable = Vector

]]

-- Radiant hero count
iRadiantHeroCount = 0
-- Dire hero count
iDireHeroCount = 0
-- Spawn of wave is called
bCalledSpawn = false
-- Wave began
bWaveStarted = false
-- Wave ended
bWaveEnded = true
-- Game OFFICIALY Started
bGameStarted = false
-- Current Wave Number
iWaveNumber = 1
-- Number of enemies remaining
tEnemiesRemaining = {}
-- Spawn Positions
tSpawnPosition ={}
-- Pool position
vPoolPos = 0
-- Table for creep to hero value
tCreepSpawnValue = {
  [1] = 10,
  [2] = 15,
  [3] = 20,
  [4] = 20,
  [5] = 25,
  [6] = 30,
  [7] = 30,
  [8] = 40
}
-- Summoned Tower Position
tSummonedTowerPos = {}
-- Tower Summonings
tHeroesSummoned = {}
-- Creep Count
iCreepCountPerSpawn = 0

function UpdatePreGame()
  -- Handle radiant spawn tSpawnPositions
  iRadiantHeroCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
  iDireHeroCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)

  print('[sc] Radiant Players: ' .. iRadiantHeroCount .. ' Dire Players: ' .. iDireHeroCount)

  UpdateCreepCountToSpawn()
end

function Update()
  if bCalledSpawn == false and bWaveStarted == false and bWaveEnded == true then
    bCalledSpawn = true
    FireGameEvent('cgm_timer_display', { timerMsg = "Wave will start in", timerSeconds = 30, timerWarning = -1, timerEnd = false, timerPosition = 0})
    Timers:CreateTimer(30, function()
      ConvertToHeros()
      SpawnCreeps(iWaveNumber)
      bWaveStarted = true
    end)
  elseif IsRoundOver() == true and bWaveStarted == true then
    iWaveNumber = iWaveNumber + 1
    bWaveStarted = false
    bWaveEnded = true
    bCalledSpawn = false 
    RespawnBuildings()
  end
end

function SpawnCreeps(waveNumber)
  print('[SC] Spawn Them Creeps')
    local units_to_spawn = 10;
    local waypoint = Entities:FindByName(nil,"spawn11"):GetAbsOrigin()

    for i = 1, units_to_spawn do
      for _,v in pairs (tSpawnPosition) do
        Timers:CreateTimer(function()
          local unit = CreateUnitByName("creep_wave_" .. waveNumber, v, true, nil, nil, DOTA_TEAM_NEUTRALS)
          ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(),
                      OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                      Position = waypoint,Queue= true})
          table.insert(tEnemiesRemaining, unit)
        end)
      end
    end
end

function IsRoundOver()
  return (#tEnemiesRemaining <= 0)
end

function ConvertToHeros()
  for _,v in pairs (tSummonedTower) do
    -- TODO: Call first skill to change to unit
    local unit = CreateUnitByName("npc_dota_hero_antimage", v:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
    table.insert(tHeroesSummoned, unit)
    v:SetAbsOrigin(vPoolPos)
  end
end

function RespawnBuildings()
  for k,v in pairs (tSummonedTowerPos) do
    k:SetAbsOrigin(v)
  end

  for k,v in pairs (tHeroesSummoned) do
    v:Destroy()
    tHeroesSummoned[k] = nil
  end

  print('Heroes in table: ' .. #tHeroesSummoned)
end

function UpdateCreepCountToSpawn()
  local totalPlayers = iRadiantHeroCount + iDireHeroCount
  iCreepCountPerSpawn = tCreepSpawnValue[totalPlayers]
end