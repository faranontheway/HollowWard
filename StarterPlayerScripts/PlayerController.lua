-- PlayerController (LocalScript)
-- Place in: StarterPlayerScripts
-- Handles: walk/run toggle, hiding in lockers, objective interaction prompt

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ObjectiveActivated = ReplicatedStorage:WaitForChild("ObjectiveActivated", 10)

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- Re-grab references on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid  = char:WaitForChild("Humanoid")
    rootPart  = char:WaitForChild("HumanoidRootPart")
    isHiding  = false
    humanoid.WalkSpeed = Config.PLAYER_WALK_SPEED
end)

-- ─────────────────────────────────────────────
-- Walk / Run Toggle (Shift to run)
-- ─────────────────────────────────────────────
local isRunning = false

local function setRunning(state)
    isRunning = state
    if humanoid then
        humanoid.WalkSpeed = state and Config.PLAYER_RUN_SPEED or Config.PLAYER_WALK_SPEED
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setRunning(true)
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setRunning(false)
    end
end)

-- Mobile run button (BoolValue set by GameUI)
local mobileRunning = ReplicatedStorage:FindFirstChild("MobileRunning_" .. player.UserId)
if mobileRunning then
    mobileRunning.Changed:Connect(function(val)
        setRunning(val)
    end)
end

-- ─────────────────────────────────────────────
-- Hiding in Lockers
-- ─────────────────────────────────────────────
local isHiding    = false
local hideTime    = 0
local HIDE_COOLDOWN = Config.HIDE_COOLDOWN

-- Lockers are Models in workspace with a ProximityPrompt named "HidePrompt"
-- and a BoolValue named "Occupied"
local function setupLockerPrompts()
    local lockerFolder = workspace:FindFirstChild("Lockers")
    if not lockerFolder then return end

    for _, locker in pairs(lockerFolder:GetChildren()) do
        local prompt = locker:FindFirstChild("HidePrompt")
        if not prompt then
            -- Create the prompt if it doesn't exist
            local interactPart = locker:FindFirstChildWhichIsA("BasePart")
            if interactPart then
                prompt = Instance.new("ProximityPrompt")
                prompt.Name        = "HidePrompt"
                prompt.ActionText  = "Hide"
                prompt.ObjectText  = "Locker"
                prompt.HoldDuration = 0.5
                prompt.MaxActivationDistance = 6
                prompt.Parent      = interactPart
            end
        end

        if prompt then
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer ~= player then return end
                if isHiding then return end
                if (os.clock() - hideTime) < HIDE_COOLDOWN then return end

                local occupied = locker:FindFirstChild("Occupied")
                if occupied and occupied.Value then return end  -- locker taken

                -- Enter locker
                isHiding = true
                hideTime = os.clock()

                if occupied then occupied.Value = true end
                humanoid.WalkSpeed = 0
                prompt.ActionText  = "Exit"

                -- Tween camera to first-person (handled in CameraController)
                local hideEvent = ReplicatedStorage:FindFirstChild("PlayerHiding")
                if hideEvent then hideEvent:FireServer(true, locker) end

                -- Wait for player to press again
                local conn
                conn = prompt.Triggered:Connect(function(p2)
                    if p2 ~= player then return end
                    -- Exit locker
                    isHiding = false
                    if occupied then occupied.Value = false end
                    humanoid.WalkSpeed = Config.PLAYER_WALK_SPEED
                    prompt.ActionText  = "Hide"
                    if hideEvent then hideEvent:FireServer(false, locker) end
                    conn:Disconnect()
                end)
            end)
        end
    end
end

-- Delay to let the map load
task.delay(3, setupLockerPrompts)

-- ─────────────────────────────────────────────
-- Objective interaction (ProximityPrompt on each objective)
-- ─────────────────────────────────────────────
local function setupObjectivePrompts()
    local folder = workspace:FindFirstChild("Objectives")
    if not folder then return end

    for _, model in pairs(folder:GetChildren()) do
        local interact = model:FindFirstChild("InteractPart")
        if not interact then continue end

        local prompt = interact:FindFirstChildWhichIsA("ProximityPrompt")
        if not prompt then
            prompt = Instance.new("ProximityPrompt")
            prompt.ActionText  = "Interact"
            prompt.HoldDuration = 1.5
            prompt.MaxActivationDistance = 8
            prompt.Parent = interact
        end

        prompt.Triggered:Connect(function(triggerPlayer)
            if triggerPlayer ~= player then return end
            if not model:GetAttribute("Active") then return end
            -- Fire to server
            ObjectiveActivated:FireServer(model.Name)
        end)
    end
end

task.delay(3, setupObjectivePrompts)

-- ─────────────────────────────────────────────
-- Footstep sounds (louder when running)
-- ─────────────────────────────────────────────
local footstepSound = Instance.new("Sound")
footstepSound.SoundId  = "rbxassetid://6042053626"  -- footstep sound
footstepSound.Volume   = 0.3
footstepSound.Parent   = rootPart

local stepTimer = 0

RunService.Heartbeat:Connect(function(dt)
    if not humanoid or not rootPart then return end
    if humanoid.MoveDirection.Magnitude > 0 then
        stepTimer += dt
        local stepRate = isRunning and 0.3 or 0.5
        if stepTimer >= stepRate then
            stepTimer = 0
            footstepSound.Volume = isRunning and 1.0 or 0.3
            footstepSound:Play()
        end
    else
        stepTimer = 0
    end
end)
