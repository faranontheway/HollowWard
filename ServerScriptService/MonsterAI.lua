-- MonsterAI (Script)
-- Place in: ServerScriptService
-- Controls The Orderly — a sound-based monster that hunts running players

local Players               = game:GetService("Players")
local PathfindingService    = game:GetService("PathfindingService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local RunService            = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ShowJumpscare     = ReplicatedStorage:WaitForChild("ShowJumpscare", 10)
local MonsterAlert      = ReplicatedStorage:WaitForChild("MonsterAlert", 10)
local PlayerCaughtEvent = ReplicatedStorage:WaitForChild("PlayerCaughtInternal", 10)

-- ─────────────────────────────────────────────
-- Setup — monster model must exist in Workspace
-- Name it "TheOrderly" with a Humanoid and HumanoidRootPart
-- ─────────────────────────────────────────────

local monster       = workspace:WaitForChild("TheOrderly")
local humanoid      = monster:WaitForChild("Humanoid")
local rootPart      = monster:WaitForChild("HumanoidRootPart")

-- Patrol waypoints: add Parts to workspace named "Waypoint1", "Waypoint2", etc.
-- inside a folder named "MonsterWaypoints"
local waypointFolder = workspace:WaitForChild("MonsterWaypoints")
local waypoints      = waypointFolder:GetChildren()
table.sort(waypoints, function(a, b) return a.Name < b.Name end)

-- State
local isActive      = false
local alertTarget   = nil       -- player the monster is currently chasing
local alertTimer    = 0         -- countdown for alert duration
local currentWaypoint = 1

-- ─────────────────────────────────────────────
-- Pathfinding helper
-- ─────────────────────────────────────────────
local function moveTo(targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius         = 2,
        AgentHeight         = 5,
        AgentCanJump        = false,
        AgentCanClimb       = false,
        WaypointSpacing     = 4,
    })

    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        -- Fallback: walk directly toward target
        humanoid:MoveTo(targetPosition)
        return
    end

    local waypoints = path:GetWaypoints()
    for _, wp in pairs(waypoints) do
        if wp.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        humanoid:MoveTo(wp.Position)
        -- Wait until we reach each waypoint or timeout
        local reached = humanoid.MoveToFinished:Wait(3)
        if not reached then break end

        -- If we get a new alert target mid-path, break early to recalculate
        if alertTarget then break end
    end
end

-- ─────────────────────────────────────────────
-- Catch a player
-- ─────────────────────────────────────────────
local caughtPlayers = {}  -- prevent double-catching

local function catchPlayer(player)
    if caughtPlayers[player.UserId] then return end
    caughtPlayers[player.UserId] = true

    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.Health = 0 end
    end

    ShowJumpscare:FireClient(player)
    PlayerCaughtEvent:Fire(player)

    -- Allow catching again after respawn
    task.delay(Config.CAUGHT_RESPAWN_TIME + 2, function()
        caughtPlayers[player.UserId] = nil
    end)

    -- Reset monster state
    alertTarget = nil
    alertTimer  = 0
    humanoid.WalkSpeed = Config.MONSTER_WALK_SPEED
    print("[MonsterAI] Caught: " .. player.Name)
end

-- ─────────────────────────────────────────────
-- Detect nearby running players (sound detection)
-- ─────────────────────────────────────────────
local function detectSound()
    local closestPlayer = nil
    local closestDist   = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local rootPart2 = char:FindFirstChild("HumanoidRootPart")
        local hum       = char:FindFirstChild("Humanoid")
        if not rootPart2 or not hum then continue end
        if hum.Health <= 0 then continue end

        -- Ghost players can't be detected
        local isGhost = false
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency >= 0.5 then
                isGhost = true break
            end
        end
        if isGhost then continue end

        local dist = (rootPart.Position - rootPart2.Position).Magnitude

        -- Player is running (audible)
        if hum.WalkSpeed >= Config.RUNNING_SPEED_THRESHOLD then
            if dist <= Config.MONSTER_HEAR_RADIUS and dist < closestDist then
                closestPlayer = player
                closestDist   = dist
            end
        end

        -- Player is very close (visible range, even if walking)
        if dist <= Config.MONSTER_CATCH_RADIUS * 3 and dist < closestDist then
            closestPlayer = player
            closestDist   = dist
        end
    end

    return closestPlayer, closestDist
end

-- ─────────────────────────────────────────────
-- Patrol between waypoints
-- ─────────────────────────────────────────────
local function patrol()
    if #waypoints == 0 then return end
    local wp = waypoints[currentWaypoint]
    humanoid.WalkSpeed = Config.MONSTER_WALK_SPEED
    moveTo(wp.Position)
    currentWaypoint = (currentWaypoint % #waypoints) + 1
    task.wait(Config.MONSTER_PATROL_WAIT)
end

-- ─────────────────────────────────────────────
-- Chase a target player
-- ─────────────────────────────────────────────
local function chasePlayer(player)
    humanoid.WalkSpeed = Config.MONSTER_CHASE_SPEED
    local char = player.Character
    if not char then return end
    local target = char:FindFirstChild("HumanoidRootPart")
    if not target then return end

    moveTo(target.Position)

    -- Check catch distance
    local dist = (rootPart.Position - target.Position).Magnitude
    if dist <= Config.MONSTER_CATCH_RADIUS then
        catchPlayer(player)
    end
end

-- ─────────────────────────────────────────────
-- Main AI loop
-- ─────────────────────────────────────────────
local function runAI()
    while isActive do
        -- Sound detection check
        local detected, dist = detectSound()

        if detected then
            if alertTarget ~= detected then
                -- New target found — alert all clients
                alertTarget = detected
                alertTimer  = Config.MONSTER_ALERT_DURATION
                MonsterAlert:FireAllClients(detected.Name)
                print("[MonsterAI] Alert! Chasing: " .. detected.Name)
            end
        end

        if alertTarget then
            -- Check target is still valid
            local char = alertTarget.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            if not char or not hum or hum.Health <= 0 then
                alertTarget = nil
                alertTimer  = 0
            else
                alertTimer -= 0.5
                if alertTimer <= 0 then
                    alertTarget = nil
                    humanoid.WalkSpeed = Config.MONSTER_WALK_SPEED
                    print("[MonsterAI] Lost the player. Returning to patrol.")
                else
                    chasePlayer(alertTarget)
                end
            end
        else
            patrol()
        end

        task.wait(0.5)
    end
end

-- ─────────────────────────────────────────────
-- Activate / Deactivate
-- ─────────────────────────────────────────────
local activateEvent = Instance.new("BindableEvent")
activateEvent.Name  = "ActivateMonster"
activateEvent.Parent = ReplicatedStorage

activateEvent.Event:Connect(function()
    isActive        = true
    alertTarget     = nil
    alertTimer      = 0
    caughtPlayers   = {}
    currentWaypoint = 1
    humanoid.WalkSpeed = Config.MONSTER_WALK_SPEED

    -- Move monster to its start position
    local startPos = workspace:FindFirstChild("MonsterSpawn")
    if startPos then
        monster:SetPrimaryPartCFrame(startPos.CFrame)
    end

    print("[MonsterAI] The Orderly is now active.")
    task.spawn(runAI)
end)

-- Deactivate at round end
local gameStateEvent = ReplicatedStorage:WaitForChild("GameStateChanged", 10)
gameStateEvent.OnServerEvent = nil  -- not a RemoteEvent listener, use GameManager BindableEvent

-- Listen for game end
local deactivateEvent = Instance.new("BindableEvent")
deactivateEvent.Name  = "DeactivateMonster"
deactivateEvent.Parent = ReplicatedStorage

deactivateEvent.Event:Connect(function()
    isActive    = false
    alertTarget = nil
    humanoid.WalkSpeed = 0
    print("[MonsterAI] The Orderly deactivated.")
end)
