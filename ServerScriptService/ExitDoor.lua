-- ExitDoor (Script)
-- Place INSIDE the "ExitDoor" Model in Workspace (not in ServerScriptService)
-- The ExitDoor model needs:
--   - A Part named "Door" (the physical door)
--   - A Part named "ExitTrigger" (invisible, CanCollide=false, this is the touch zone)
--   - A PointLight named "ExitLight" on the Door part

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local exitTrigger = script.Parent:WaitForChild("ExitTrigger")
local door        = script.Parent:WaitForChild("Door")

local PlayerEscapedEvent = ReplicatedStorage:WaitForChild("PlayerEscapedInternal", 10)
local AllObjectivesComplete = ReplicatedStorage:WaitForChild("AllObjectivesComplete", 10)

local isUnlocked = false

-- Listen for all objectives being complete
AllObjectivesComplete.Event:Connect(function()
    isUnlocked = true
    -- Visual: door fades and turns green
    door.Transparency = 0.8
    door.BrickColor   = BrickColor.new("Bright green")
    door.CanCollide   = false

    -- Turn exit light green
    local light = door:FindFirstChildOfClass("PointLight")
    if light then
        light.Color = Color3.fromRGB(0, 255, 80)
        light.Brightness = 3
    end

    print("[ExitDoor] Exit is now unlocked!")
end)

-- Detect player touching exit trigger
exitTrigger.Touched:Connect(function(hit)
    if not isUnlocked then return end

    local character = hit.Parent
    local player    = Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- Prevent double-firing
    if exitTrigger:GetAttribute("Escaping_" .. player.UserId) then return end
    exitTrigger:SetAttribute("Escaping_" .. player.UserId, true)

    PlayerEscapedEvent:Fire(player)

    -- Clean up flag after a moment
    task.delay(5, function()
        exitTrigger:SetAttribute("Escaping_" .. player.UserId, nil)
    end)
end)
