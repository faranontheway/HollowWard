-- GameConfig (ModuleScript)
-- Place in: ReplicatedStorage
-- This is the single place to tune all game values

local GameConfig = {}

-- Round settings
GameConfig.ROUND_DURATION       = 300   -- 5 minutes per round (seconds)
GameConfig.LOBBY_WAIT_TIME      = 15    -- seconds before round starts
GameConfig.END_SCREEN_DURATION  = 8     -- seconds on win/lose screen
GameConfig.MIN_PLAYERS          = 1     -- minimum players to start a round

-- Objectives
GameConfig.OBJECTIVES_REQUIRED  = 3     -- how many must be completed to unlock exit
GameConfig.OBJECTIVE_NAMES      = {
    "Restore Power",
    "Find the Key",
    "Collect Evidence",
    "Fix the Fuse Box",
    "Unlock the Locker"
}

-- Monster (The Orderly)
GameConfig.MONSTER_WALK_SPEED       = 14    -- normal patrol speed
GameConfig.MONSTER_CHASE_SPEED      = 20    -- speed when chasing
GameConfig.MONSTER_HEAR_RADIUS      = 40    -- studs — hears running players
GameConfig.MONSTER_CATCH_RADIUS     = 5     -- studs — catches player
GameConfig.MONSTER_PATROL_WAIT      = 2     -- seconds between patrol waypoints
GameConfig.MONSTER_ALERT_DURATION   = 8     -- seconds monster stays alerted
GameConfig.RUNNING_SPEED_THRESHOLD  = 10    -- walkspeed above this = running (audible)

-- Player
GameConfig.PLAYER_WALK_SPEED    = 8     -- quiet walk
GameConfig.PLAYER_RUN_SPEED     = 16    -- fast but audible
GameConfig.HIDE_COOLDOWN        = 3     -- seconds before you can hide again
GameConfig.CAUGHT_RESPAWN_TIME  = 10    -- seconds until caught player respawns as ghost

-- Coins
GameConfig.COINS_PER_ESCAPE     = 50
GameConfig.COINS_PER_OBJECTIVE  = 10
GameConfig.COINS_PER_SURVIVAL   = 5     -- per minute survived

-- DevProduct IDs (replace with your real IDs from Creator Hub)
GameConfig.COIN_BOOST_PRODUCT_ID    = 0000000001  -- 2x coins for 1 hour
GameConfig.REVIVE_PRODUCT_ID        = 0000000002  -- instant revive when caught

-- GamePass IDs (replace with your real IDs from Creator Hub)
GameConfig.VIP_GAMEPASS_ID          = 0000000003  -- VIP Survivor pass
GameConfig.MONSTER_MODE_GAMEPASS_ID = 0000000004  -- Play as monster pass

return GameConfig
