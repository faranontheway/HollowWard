-- ObjectiveManager (Script)
-- Place in: ServerScriptService
-- Manages the 3 randomised objectives players must complete each round

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ObjectiveActivated  = ReplicatedStorage:WaitForChild("ObjectiveActivated", 10)
local ObjectiveCompleted  = ReplicatedStorage:WaitForChild("ObjectiveCompleted", 10)
local UpdateObjectives    = ReplicatedStorage:WaitForChild("UpdateObjectives", 10)
local CoinsUpdated        = ReplicatedStorage:WaitForChild("CoinsUpdated", 10)

local AllObjectivesComplete = ReplicatedStorage:WaitForChild("AllObjectivesComplete", 10)

-- Track state per round
local completedCount  = 0
local completedNames  = {}
local activeObjectives = {}   -- list of objective model names active this round

-- ─────────────────────────────────────────────
-- Objective setup — pick 3 random objectives
-- ─────────────────────────────────────────────

-- Objectives folder should exist in Workspace with child models named:
--   "FuseBox", "KeyLocker", "EvidenceBox", "PowerSwitch", "SecurityPanel"
-- Each model should have a Part named "InteractPart" with a ProximityPrompt inside

local OBJECTIVE_MODELS = {"FuseBox", "KeyLocker", "EvidenceBox", "PowerSwitch", "SecurityPanel"}

local function shuffleTable(t)
    local copy = {table.unpack(t)}
    for i = #copy, 2, -1 do
        local j = math.random(1, i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end

local function resetAllObjectives()
    local folder = workspace:FindFirstChild("Objectives")
    if not folder then
        warn("[ObjectiveManager] No 'Objectives' folder found in workspace.")
        return
    end
    for _, model in pairs(folder:GetChildren()) do
        model.Active = false  -- custom attribute, see below
        -- Reset visual state
        local interact = model:FindFirstChild("InteractPart")
        if interact then
            interact.BrickColor = BrickColor.new("Dark stone grey")
            local prompt = interact:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                prompt.Enabled = true
                prompt.ActionText = "Interact"
            end
            local light = interact:FindFirstChildOfClass("PointLight")
            if light then light.Color = Color3.fromRGB(255, 100, 0) end  -- orange = inactive
        end
    end
end

local function activateObjectives(count)
    completedCount  = 0
    completedNames  = {}
    activeObjectives = {}

    local folder = workspace:FindFirstChild("Objectives")
    if not folder then return end

    local shuffled = shuffleTable(OBJECTIVE_MODELS)
    local selected = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(selected, shuffled[i])
    end

    for _, name in pairs(selected) do
        local model = folder:FindFirstChild(name)
        if model then
            table.insert(activeObjectives, name)
            model:SetAttribute("Active", true)
            local interact = model:FindFirstChild("InteractPart")
            if interact then
                interact.BrickColor = BrickColor.new("Bright yellow")
                local light = interact:FindFirstChildOfClass("PointLight")
                if light then light.Color = Color3.fromRGB(255, 220, 0) end  -- yellow = active
            end
        end
    end

    UpdateObjectives:FireAllClients(0, count)
    print("[ObjectiveManager] Round objectives: " .. table.concat(selected, ", "))
end

-- ─────────────────────────────────────────────
-- Player interacts with an objective
-- ─────────────────────────────────────────────
ObjectiveActivated.OnServerEvent:Connect(function(player, objectiveName)
    -- Validate: is this objective actually active this round?
    local isActive = false
    for _, name in pairs(activeObjectives) do
        if name == objectiveName then isActive = true break end
    end
    if not isActive then return end

    -- Validate: not already completed
    for _, name in pairs(completedNames) do
        if name == objectiveName then return end  -- already done
    end

    -- Complete it
    table.insert(completedNames, objectiveName)
    completedCount += 1

    -- Visual feedback — mark objective as done
    local folder = workspace:FindFirstChild("Objectives")
    if folder then
        local model = folder:FindFirstChild(objectiveName)
        if model then
            local interact = model:FindFirstChild("InteractPart")
            if interact then
                interact.BrickColor = BrickColor.new("Bright green")
                local light = interact:FindFirstChildOfClass("PointLight")
                if light then light.Color = Color3.fromRGB(0, 255, 80) end  -- green = done
                local prompt = interact:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then prompt.Enabled = false end
            end
        end
    end

    -- Award coins to the player who completed it
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value += Config.COINS_PER_OBJECTIVE
            CoinsUpdated:FireClient(player, coins.Value)
        end
    end

    -- Broadcast objective completion
    ObjectiveCompleted:FireAllClients(objectiveName)
    UpdateObjectives:FireAllClients(completedCount, Config.OBJECTIVES_REQUIRED)
    print("[ObjectiveManager] " .. player.Name .. " completed: " .. objectiveName
        .. " (" .. completedCount .. "/" .. Config.OBJECTIVES_REQUIRED .. ")")

    -- Check if all done
    if completedCount >= Config.OBJECTIVES_REQUIRED then
        AllObjectivesComplete:Fire()
    end
end)

-- ─────────────────────────────────────────────
-- Listen for round start from GameManager
-- ─────────────────────────────────────────────
local setupEvent = Instance.new("BindableEvent")
setupEvent.Name  = "ObjectiveSetup"
setupEvent.Parent = ReplicatedStorage

setupEvent.Event:Connect(function(count)
    resetAllObjectives()
    task.wait(1)
    activateObjectives(count)
end)
