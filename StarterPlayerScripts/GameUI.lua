-- GameUI (LocalScript)
-- Place in: StarterPlayerScripts
-- Draws all HUD elements: timer, objectives, coins, monster alert, phase screens

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local GameStateChanged  = ReplicatedStorage:WaitForChild("GameStateChanged", 10)
local UpdateTimer       = ReplicatedStorage:WaitForChild("UpdateTimer", 10)
local UpdateObjectives  = ReplicatedStorage:WaitForChild("UpdateObjectives", 10)
local CoinsUpdated      = ReplicatedStorage:WaitForChild("CoinsUpdated", 10)
local MonsterAlert      = ReplicatedStorage:WaitForChild("MonsterAlert", 10)
local ShowJumpscare     = ReplicatedStorage:WaitForChild("ShowJumpscare", 10)
local ObjectiveCompleted = ReplicatedStorage:WaitForChild("ObjectiveCompleted", 10)
local PlayerCaught      = ReplicatedStorage:WaitForChild("PlayerCaught", 10)
local PlayerEscaped     = ReplicatedStorage:WaitForChild("PlayerEscaped", 10)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- Build the ScreenGui
-- ─────────────────────────────────────────────
local screenGui         = Instance.new("ScreenGui")
screenGui.Name          = "HollowWardUI"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = playerGui

-- ─────────────────────────────────────────────
-- HUD Frame (shown during gameplay)
-- ─────────────────────────────────────────────
local hudFrame          = Instance.new("Frame")
hudFrame.Name           = "HUD"
hudFrame.Size           = UDim2.new(1, 0, 1, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Visible        = false
hudFrame.Parent         = screenGui

-- Timer (top centre)
local timerLabel        = Instance.new("TextLabel")
timerLabel.Name         = "Timer"
timerLabel.Size         = UDim2.new(0, 180, 0, 50)
timerLabel.Position     = UDim2.new(0.5, -90, 0, 16)
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
timerLabel.BackgroundTransparency = 0.4
timerLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled   = true
timerLabel.Font         = Enum.Font.GothamBold
timerLabel.Text         = "5:00"
Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0, 8)
timerLabel.Parent       = hudFrame

-- Objectives counter (top left)
local objFrame          = Instance.new("Frame")
objFrame.Size           = UDim2.new(0, 220, 0, 60)
objFrame.Position       = UDim2.new(0, 16, 0, 16)
objFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
objFrame.BackgroundTransparency = 0.4
Instance.new("UICorner", objFrame).CornerRadius = UDim.new(0, 8)
objFrame.Parent         = hudFrame

local objIcon           = Instance.new("TextLabel")
objIcon.Size            = UDim2.new(0, 40, 1, 0)
objIcon.Position        = UDim2.new(0, 0, 0, 0)
objIcon.BackgroundTransparency = 1
objIcon.TextColor3      = Color3.fromRGB(255, 200, 0)
objIcon.Text            = "⚡"
objIcon.TextScaled      = true
objIcon.Parent          = objFrame

local objLabel          = Instance.new("TextLabel")
objLabel.Name           = "ObjLabel"
objLabel.Size           = UDim2.new(1, -48, 1, 0)
objLabel.Position       = UDim2.new(0, 48, 0, 0)
objLabel.BackgroundTransparency = 1
objLabel.TextColor3     = Color3.fromRGB(255, 255, 255)
objLabel.TextScaled     = true
objLabel.Font           = Enum.Font.Gotham
objLabel.TextXAlignment = Enum.TextXAlignment.Left
objLabel.Text           = "Objectives: 0 / 3"
objLabel.Parent         = objFrame

-- Coins (top right)
local coinsLabel        = Instance.new("TextLabel")
coinsLabel.Name         = "Coins"
coinsLabel.Size         = UDim2.new(0, 150, 0, 44)
coinsLabel.Position     = UDim2.new(1, -166, 0, 20)
coinsLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
coinsLabel.BackgroundTransparency = 0.4
coinsLabel.TextColor3   = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled   = true
coinsLabel.Font         = Enum.Font.GothamBold
coinsLabel.Text         = "⭐ 0"
Instance.new("UICorner", coinsLabel).CornerRadius = UDim.new(0, 8)
coinsLabel.Parent       = hudFrame

-- Run indicator (bottom left)
local runLabel          = Instance.new("TextLabel")
runLabel.Size           = UDim2.new(0, 200, 0, 36)
runLabel.Position       = UDim2.new(0, 16, 1, -56)
runLabel.BackgroundTransparency = 1
runLabel.TextColor3     = Color3.fromRGB(180, 180, 180)
runLabel.TextScaled     = true
runLabel.Font           = Enum.Font.Gotham
runLabel.Text           = "[ SHIFT ] to run"
runLabel.Parent         = hudFrame

-- Notification (centre bottom — for objective complete, player caught etc.)
local notifLabel        = Instance.new("TextLabel")
notifLabel.Name         = "Notif"
notifLabel.Size         = UDim2.new(0, 400, 0, 50)
notifLabel.Position     = UDim2.new(0.5, -200, 1, -120)
notifLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notifLabel.BackgroundTransparency = 0.5
notifLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
notifLabel.TextScaled   = true
notifLabel.Font         = Enum.Font.GothamBold
notifLabel.Text         = ""
notifLabel.Visible      = false
Instance.new("UICorner", notifLabel).CornerRadius = UDim.new(0, 8)
notifLabel.Parent       = hudFrame

-- ─────────────────────────────────────────────
-- Monster Alert bar (centre, flashes red)
-- ─────────────────────────────────────────────
local alertFrame        = Instance.new("Frame")
alertFrame.Name         = "AlertFrame"
alertFrame.Size         = UDim2.new(1, 0, 0, 60)
alertFrame.Position     = UDim2.new(0, 0, 0, 0)
alertFrame.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
alertFrame.BackgroundTransparency = 1
alertFrame.Visible      = false
alertFrame.ZIndex       = 10
alertFrame.Parent       = screenGui

local alertLabel        = Instance.new("TextLabel")
alertLabel.Size         = UDim2.new(1, 0, 1, 0)
alertLabel.BackgroundTransparency = 1
alertLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
alertLabel.TextScaled   = true
alertLabel.Font         = Enum.Font.GothamBold
alertLabel.Text         = "⚠ IT HEARS YOU ⚠"
alertLabel.ZIndex       = 11
alertLabel.Parent       = alertFrame

-- ─────────────────────────────────────────────
-- Jumpscare overlay
-- ─────────────────────────────────────────────
local jumpscareFrame    = Instance.new("Frame")
jumpscareFrame.Name     = "Jumpscare"
jumpscareFrame.Size     = UDim2.new(1, 0, 1, 0)
jumpscareFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
jumpscareFrame.BackgroundTransparency = 1
jumpscareFrame.Visible  = false
jumpscareFrame.ZIndex   = 20
jumpscareFrame.Parent   = screenGui

local jumpscareText     = Instance.new("TextLabel")
jumpscareText.Size      = UDim2.new(1, 0, 1, 0)
jumpscareText.BackgroundTransparency = 1
jumpscareText.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpscareText.TextScaled = true
jumpscareText.Font      = Enum.Font.GothamBold
jumpscareText.Text      = "CAUGHT"
jumpscareText.ZIndex    = 21
jumpscareText.Parent    = jumpscareFrame

-- ─────────────────────────────────────────────
-- Phase screens (Lobby / Win / Lose)
-- ─────────────────────────────────────────────
local phaseFrame        = Instance.new("Frame")
phaseFrame.Name         = "PhaseScreen"
phaseFrame.Size         = UDim2.new(1, 0, 1, 0)
phaseFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
phaseFrame.BackgroundTransparency = 0.1
phaseFrame.Visible      = true
phaseFrame.ZIndex       = 15
phaseFrame.Parent       = screenGui

local phaseTitleLabel   = Instance.new("TextLabel")
phaseTitleLabel.Size    = UDim2.new(0.7, 0, 0, 80)
phaseTitleLabel.Position = UDim2.new(0.15, 0, 0.35, 0)
phaseTitleLabel.BackgroundTransparency = 1
phaseTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
phaseTitleLabel.TextScaled = true
phaseTitleLabel.Font    = Enum.Font.GothamBold
phaseTitleLabel.Text    = "HOLLOW WARD"
phaseTitleLabel.ZIndex  = 16
phaseTitleLabel.Parent  = phaseFrame

local phaseSubLabel     = Instance.new("TextLabel")
phaseSubLabel.Size      = UDim2.new(0.7, 0, 0, 50)
phaseSubLabel.Position  = UDim2.new(0.15, 0, 0.5, 0)
phaseSubLabel.BackgroundTransparency = 1
phaseSubLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
phaseSubLabel.TextScaled = true
phaseSubLabel.Font      = Enum.Font.Gotham
phaseSubLabel.Text      = "Waiting for players..."
phaseSubLabel.ZIndex    = 16
phaseSubLabel.Parent    = phaseFrame

local countdownLabel    = Instance.new("TextLabel")
countdownLabel.Size     = UDim2.new(0.3, 0, 0, 60)
countdownLabel.Position = UDim2.new(0.35, 0, 0.62, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
countdownLabel.TextScaled = true
countdownLabel.Font     = Enum.Font.GothamBold
countdownLabel.Text     = ""
countdownLabel.ZIndex   = 16
countdownLabel.Parent   = phaseFrame

-- ─────────────────────────────────────────────
-- Utility functions
-- ─────────────────────────────────────────────
local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

local function showNotif(text, color, duration)
    notifLabel.Text = text
    notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    notifLabel.Visible = true
    task.delay(duration or 3, function()
        notifLabel.Visible = false
    end)
end

-- ─────────────────────────────────────────────
-- Remote event listeners
-- ─────────────────────────────────────────────

GameStateChanged.OnClientEvent:Connect(function(phase, timeLeft)
    if phase == "Lobby" then
        hudFrame.Visible    = false
        phaseFrame.Visible  = true
        phaseTitleLabel.Text = "HOLLOW WARD"
        phaseSubLabel.Text  = "Waiting to start..."
        countdownLabel.Text = "Starting in " .. timeLeft .. "s"

    elseif phase == "Playing" then
        phaseFrame.Visible  = false
        hudFrame.Visible    = true

    elseif phase == "Win" then
        hudFrame.Visible    = false
        phaseFrame.Visible  = true
        phaseTitleLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        phaseTitleLabel.Text = "YOU ESCAPED"
        phaseSubLabel.Text  = "The ward couldn't hold you."
        countdownLabel.Text = ""

    elseif phase == "Lose" then
        hudFrame.Visible    = false
        phaseFrame.Visible  = true
        phaseTitleLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
        phaseTitleLabel.Text = "NO ESCAPE"
        phaseSubLabel.Text  = "The Orderly claims another soul."
        countdownLabel.Text = ""
    end
end)

UpdateTimer.OnClientEvent:Connect(function(timeLeft)
    timerLabel.Text = formatTime(timeLeft)
    -- Flash red when under 60 seconds
    if timeLeft <= 60 then
        timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    else
        timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    -- Lobby countdown
    if phaseFrame.Visible then
        countdownLabel.Text = "Starting in " .. timeLeft .. "s"
    end
end)

UpdateObjectives.OnClientEvent:Connect(function(done, required)
    objLabel.Text = "Objectives: " .. done .. " / " .. required
    if done >= required then
        objLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        objLabel.Text = "EXIT UNLOCKED ✓"
    end
end)

CoinsUpdated.OnClientEvent:Connect(function(total)
    coinsLabel.Text = "⭐ " .. total
end)

ObjectiveCompleted.OnClientEvent:Connect(function(name)
    showNotif("✓ " .. name .. " complete!", Color3.fromRGB(0, 255, 120), 3)
end)

PlayerCaught.OnClientEvent:Connect(function(name)
    if name == player.Name then return end  -- own jumpscare handled separately
    showNotif("💀 " .. name .. " was caught!", Color3.fromRGB(255, 80, 80), 4)
end)

PlayerEscaped.OnClientEvent:Connect(function(name)
    showNotif("🚪 " .. name .. " escaped!", Color3.fromRGB(0, 200, 255), 4)
end)

-- Monster alert flash
MonsterAlert.OnClientEvent:Connect(function()
    alertFrame.Visible = true
    alertFrame.BackgroundTransparency = 0.3

    -- Flash 3 times then fade
    for i = 1, 3 do
        TweenService:Create(alertFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        task.wait(0.2)
        TweenService:Create(alertFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
        task.wait(0.2)
    end
    task.wait(1)
    TweenService:Create(alertFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    alertFrame.Visible = false
end)

-- Jumpscare
ShowJumpscare.OnClientEvent:Connect(function()
    jumpscareFrame.Visible = true
    jumpscareFrame.BackgroundTransparency = 0
    -- Flash the screen
    for i = 1, 4 do
        TweenService:Create(jumpscareFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0}):Play()
        task.wait(0.05)
        TweenService:Create(jumpscareFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0.5}):Play()
        task.wait(0.05)
    end
    task.wait(0.8)
    TweenService:Create(jumpscareFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    jumpscareFrame.Visible = false
end)
