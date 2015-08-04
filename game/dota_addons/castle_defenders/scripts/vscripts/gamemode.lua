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
	hero:SetGold(9999999, false)

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
fVariable = float
eVariable = entity
]]

-- Radiant hero count
iRadiantHeroCount = 0
-- Current Wave Number
iWaveNumber = 1
-- Spawn Positions
tSpawnPosition ={}
-- Pool position
vBossSpawnPos = 0
-- Table for creep to hero value
tCreepSpawnValue = {
	[1] = 8,
	[2] = 8,
	[3] = 8,
	[4] = 12,
	[5] = 12,
	[6] = 15,
	[7] = 23,
	[8] = 23
}
-- Creep Count
iCreepCountPerSpawn = 0
-- Boss Number
iBossCounter = 1
-- Creep Spawn Time
fCreepSpawnTime = 0
-- Boss Spawn Time
fBossSpawnTime = 0
-- Current Game Time
fGameTime = 0
-- Creep Spawn Interval
fCreepSpawnInterval = 30
-- Boss Spawn Interval
fBossSpawnInterval = 180
-- Ally Base
eAllyBase = nil
-- Enemy Base
eEnemyBase = nil
-- How many times creep is spawned already
fDifficultyTimer = 0
-- Difficulty Interval
fDifficultyInterval = 180

function UpdatePreGame()
	iRadiantHeroCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)

	for i = 1, 3 do
		tSpawnPosition[i] = Entities:FindByName(nil, "spawn" .. i):GetAbsOrigin()
	end

	vBossSpawnPos = Entities:FindByName(nil, "boss_spawn"):GetAbsOrigin()

	UpdateCreepCountToSpawn()

	-- Cache both bases
	eAllyBase = Entities:FindByName(nil, "ally_base")
	eAllyBase:SetTeam(DOTA_TEAM_GOODGUYS)
	eEnemyBase = Entities:FindByName(nil, "enemy_base")

	fGameTime = GameRules:GetGameTime()
	fCreepSpawnTime = fGameTime + fCreepSpawnInterval
	fBossSpawnTime = fGameTime + fBossSpawnInterval
	fDifficultyTimer = fGameTime + fDifficultyInterval

	FireGameEvent('cgm_timer_display', { timerMsg = "Next Boss in ", timerSeconds = fBossSpawnInterval, timerWarning = -1, timerEnd = false, timerPosition = 0})

--[[
	Timers:CreateTimer(function()
		SpawnBoss(iBossCounter)
		return 180.0
		end
	)
]]
end

function Update()
	fGameTime = GameRules:GetGameTime() 

	if fCreepSpawnTime < fGameTime then
		fCreepSpawnTime = fGameTime + fCreepSpawnInterval
		SpawnCreeps(iWaveNumber)
	end

	if fBossSpawnTime < fGameTime then
		fBossSpawnTime = fGameTime + fBossSpawnInterval
		FireGameEvent('cgm_timer_display', { timerMsg = "Next Boss in ", timerSeconds = fBossSpawnInterval, timerWarning = -1, timerEnd = false, timerPosition = 0})
		SpawnBoss(iBossCounter)
	end

	if fDifficultyTimer < fGameTime then
		fDifficultyTimer = fGameTime + fDifficultyInterval
		iWaveNumber = iWaveNumber + 1
		-- Prevent over number of creep wave
		-- Addes 5 mroe creeps to each lane to spawn
		if iWaveNumber > 10 then
			iWaveNumber = 10
			iCreepCountPerSpawn = iCreepCountPerSpawn + 5
		end
	end

	if CheckGameEnd() then
		DeclareWinner()
	end
end

function SpawnCreeps(waveNumber)
	print('[SC] Spawn Them Creeps')
	local waypoint = eAllyBase:GetAbsOrigin()

	local leftPath = Entities:FindByName( nil, "left_lane_path_1")
	local midPath = Entities:FindByName( nil, "mid_lane_path_1")
	local rightPath = Entities:FindByName( nil, "right_lane_path_1")

	local counter = 0

	for _, v in pairs (tSpawnPosition) do
		for i = 1, iCreepCountPerSpawn do
			local unit = CreateUnitByName("creep_wave_" .. waveNumber, v, true, nil, nil, DOTA_TEAM_BADGUYS)

			if counter == 0 then
				unit:SetInitialGoalEntity(leftPath)
			elseif counter == 1 then
				unit:SetInitialGoalEntity(midPath)
			elseif counter == 2 then
				unit:SetInitialGoalEntity(rightPath)
			end
		end
		counter = counter + 1
	end
end

function SpawnBoss(bossNumber)
	print('[SC] SpawnBoss')
	local waypoint = eAllyBase:GetAbsOrigin()

	local unit = CreateUnitByName("boss_wave_" .. bossNumber, vBossSpawnPos, true, nil, nil, DOTA_TEAM_BADGUYS)
				ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(),
										OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
										Position = waypoint,Queue= true})
	iBossCounter = iBossCounter + 1
end

function UpdateCreepCountToSpawn()
	iCreepCountPerSpawn = tCreepSpawnValue[iRadiantHeroCount]
end

function CheckGameEnd()
	if not eAllyBase:IsAlive() or not eEnemyBase:IsAlive() then
		return true
	end
	return false
end

function DeclareWinner()
	if not eAllyBase:IsAlive() then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
	elseif not eEnemyBase:IsAlive() then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
	end
end