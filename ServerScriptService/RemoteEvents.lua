-- RemoteEvents (Script)
-- Place in: ServerScriptService
-- Runs once at startup to create all RemoteEvents in ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function makeEvent(name)
    if not ReplicatedStorage:FindFirstChild(name) then
        local e = Instance.new("RemoteEvent")
        e.Name = name
        e.Parent = ReplicatedStorage
    end
end

local function makeFunction(name)
    if not ReplicatedStorage:FindFirstChild(name) then
        local f = Instance.new("RemoteFunction")
        f.Name = name
        f.Parent = ReplicatedStorage
    end
end

-- Game state events
makeEvent("GameStateChanged")   -- server -> client: ("Lobby"|"Playing"|"Win"|"Lose"), timeLeft
makeEvent("UpdateTimer")        -- server -> client: timeLeft (number)
makeEvent("UpdateObjectives")   -- server -> client: completed (number), required (number)

-- Player events
makeEvent("PlayerCaught")       -- server -> client: caught player name
makeEvent("PlayerEscaped")      -- server -> client: escaped player name
makeEvent("ShowJumpscare")      -- server -> client: triggers jumpscare screen

-- Objective events
makeEvent("ObjectiveActivated") -- client -> server: objectiveName
makeEvent("ObjectiveCompleted") -- server -> client: objectiveName

-- Monster events
makeEvent("MonsterAlert")       -- server -> client: monster heard/saw something nearby

-- Coin events
makeEvent("CoinsUpdated")       -- server -> client: total coins
makeEvent("PurchaseProduct")    -- client -> server: productId

print("[RemoteEvents] All remote events created.")
