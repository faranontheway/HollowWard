-- PlayerManager (Script)
-- Place in: ServerScriptService
-- Handles leaderstats, coin rewards, gamepasses, and DevProducts

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CoinsUpdated = ReplicatedStorage:WaitForChild("CoinsUpdated", 10)

-- DataStore for persistent coins
local CoinStore = DataStoreService:GetDataStore("HollowWard_Coins_v1")

-- Track active coin boosts per player
local coinBoosts = {}   -- { [userId] = expireTime }

-- ─────────────────────────────────────────────
-- Leaderstats
-- ─────────────────────────────────────────────
local function setupLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name  = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name  = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local escaped = Instance.new("IntValue")
    escaped.Name  = "Escapes"
    escaped.Value = 0
    escaped.Parent = leaderstats

    -- Load saved coins
    local success, saved = pcall(function()
        return CoinStore:GetAsync("coins_" .. player.UserId)
    end)
    if success and saved then
        coins.Value = saved
    end

    CoinsUpdated:FireClient(player, coins.Value)
end

-- ─────────────────────────────────────────────
-- Save coins on leave
-- ─────────────────────────────────────────────
local function saveCoins(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    if not coins then return end

    local success, err = pcall(function()
        CoinStore:SetAsync("coins_" .. player.UserId, coins.Value)
    end)
    if not success then
        warn("[PlayerManager] Failed to save coins for " .. player.Name .. ": " .. err)
    end
end

-- ─────────────────────────────────────────────
-- Award coins to a player
-- ─────────────────────────────────────────────
local function awardCoins(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    if not coins then return end

    -- Apply boost if active
    local boost = coinBoosts[player.UserId]
    if boost and boost > os.time() then
        amount = amount * 2
    end

    coins.Value += amount
    CoinsUpdated:FireClient(player, coins.Value)
end

-- ─────────────────────────────────────────────
-- End of round coin awards
-- ─────────────────────────────────────────────
local awardEvent = Instance.new("BindableEvent")
awardEvent.Name  = "AwardEndCoins"
awardEvent.Parent = ReplicatedStorage

awardEvent.Event:Connect(function(isWin, escapedNames)
    for _, player in pairs(Players:GetPlayers()) do
        local escaped = false
        for _, name in pairs(escapedNames or {}) do
            if name == player.Name then escaped = true break end
        end

        if escaped then
            awardCoins(player, Config.COINS_PER_ESCAPE)
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local e = leaderstats:FindFirstChild("Escapes")
                if e then e.Value += 1 end
            end
            print("[PlayerManager] Awarded " .. Config.COINS_PER_ESCAPE .. " coins to " .. player.Name)
        end
    end
end)

-- ─────────────────────────────────────────────
-- Developer Product purchases
-- ─────────────────────────────────────────────
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local productId = receiptInfo.ProductId

    if productId == Config.COIN_BOOST_PRODUCT_ID then
        -- Grant 1-hour coin boost
        coinBoosts[player.UserId] = os.time() + 3600
        print("[PlayerManager] Coin boost active for: " .. player.Name)

    elseif productId == Config.REVIVE_PRODUCT_ID then
        -- Instant revive
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end
        -- Remove from caught list via BindableEvent
        local reviveEvent = ReplicatedStorage:FindFirstChild("RevivePlayer")
        if reviveEvent then reviveEvent:Fire(player) end
        print("[PlayerManager] Revived: " .. player.Name)
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ─────────────────────────────────────────────
-- Check if player has VIP gamepass (on join)
-- ─────────────────────────────────────────────
local function checkGamepasses(player)
    -- VIP Survivor
    local hasVIP = false
    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.VIP_GAMEPASS_ID)
    end)
    if success then hasVIP = result end

    if hasVIP then
        -- Store VIP status as attribute for other scripts to read
        player:SetAttribute("IsVIP", true)
        print("[PlayerManager] " .. player.Name .. " has VIP pass.")
    end
end

-- ─────────────────────────────────────────────
-- Player connections
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    setupLeaderstats(player)
    checkGamepasses(player)

    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        hum.WalkSpeed = Config.PLAYER_WALK_SPEED
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveCoins(player)
end)

-- Handle server shutdowns
game:BindToClose(function()
    for _, player in pairs(Players:GetPlayers()) do
        saveCoins(player)
    end
end)
