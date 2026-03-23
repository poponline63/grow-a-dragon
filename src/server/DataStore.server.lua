-- DataStore.server.lua - Player data persistence
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local playerDataStore = DataStoreService:GetDataStore("PlayerData_v2")
local playerData = {} -- Cache of all player data
local autoSaveConnections = {} -- Track auto-save connections

-- Default player data structure
local function getDefaultPlayerData()
    return {
        -- Currency
        Coins = Config.Currency.StartingCoins,
        Gems = Config.Currency.StartingGems,
        
        -- Dragons and Eggs
        Dragons = {},
        Eggs = {},
        ActiveCompanion = nil,
        
        -- Player Progress
        PlotId = nil,
        Level = 1,
        XP = 0,
        
        -- Quests and Achievements
        Quests = {
            Daily = {},
            Weekly = {},
            LastReset = {
                Daily = 0,
                Weekly = 0
            }
        },
        Achievements = {},
        
        -- Settings
        Settings = {
            Music = true,
            SFX = true,
            Notifications = true
        },
        
        -- Daily Rewards
        DailyReward = {
            LastClaim = 0,
            Streak = 0
        },
        
        -- Timestamps
        LastSave = Utils.GetTimestamp(),
        FirstJoin = Utils.GetTimestamp()
    }
end

-- Load player data with retry logic
local function loadPlayerData(player)
    local success, data
    local attempts = 0
    local maxAttempts = 3
    
    repeat
        attempts = attempts + 1
        success, data = pcall(function()
            return playerDataStore:GetAsync(tostring(player.UserId))
        end)
        
        if not success then
            warn("Failed to load data for " .. player.Name .. " (Attempt " .. attempts .. "): " .. tostring(data))
            wait(1) -- Wait before retry
        end
    until success or attempts >= maxAttempts
    
    if success and data then
        -- Merge with default data to ensure all fields exist
        local defaultData = getDefaultPlayerData()
        for key, value in pairs(data) do
            defaultData[key] = value
        end
        
        print("Loaded data for " .. player.Name)
        return defaultData
    else
        warn("Failed to load data for " .. player.Name .. " after " .. maxAttempts .. " attempts. Using default data.")
        return getDefaultPlayerData()
    end
end

-- Save player data with retry logic
local function savePlayerData(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    data.LastSave = Utils.GetTimestamp()
    
    local success, errorMessage
    local attempts = 0
    local maxAttempts = 3
    
    repeat
        attempts = attempts + 1
        success, errorMessage = pcall(function()
            playerDataStore:SetAsync(tostring(player.UserId), data)
        end)
        
        if not success then
            warn("Failed to save data for " .. player.Name .. " (Attempt " .. attempts .. "): " .. tostring(errorMessage))
            wait(1) -- Wait before retry
        end
    until success or attempts >= maxAttempts
    
    if success then
        print("Saved data for " .. player.Name)
    else
        warn("Failed to save data for " .. player.Name .. " after " .. maxAttempts .. " attempts!")
    end
end

-- Get player data (public API)
function getPlayerData(player)
    return playerData[player.UserId]
end

-- Update player data field
function updatePlayerData(player, field, value)
    local data = playerData[player.UserId]
    if data then
        data[field] = value
        return true
    end
    return false
end

-- Add to player currency
function addPlayerCurrency(player, coins, gems)
    local data = playerData[player.UserId]
    if data then
        data.Coins = data.Coins + (coins or 0)
        data.Gems = data.Gems + (gems or 0)
        
        -- Fire remote event to update client UI
        local updateCurrency = game.ReplicatedStorage.RemoteEvents:FindFirstChild("UpdateCurrency")
        if updateCurrency then
            updateCurrency:FireClient(player, data.Coins, data.Gems)
        end
        
        return true
    end
    return false
end

-- Spend player currency (returns true if successful)
function spendPlayerCurrency(player, coins, gems)
    local data = playerData[player.UserId]
    if not data then return false end
    
    coins = coins or 0
    gems = gems or 0
    
    if data.Coins >= coins and data.Gems >= gems then
        data.Coins = data.Coins - coins
        data.Gems = data.Gems - gems
        
        -- Update client UI
        local updateCurrency = game.ReplicatedStorage.RemoteEvents:FindFirstChild("UpdateCurrency")
        if updateCurrency then
            updateCurrency:FireClient(player, data.Coins, data.Gems)
        end
        
        return true
    end
    return false
end

-- Add XP and handle level up
function addPlayerXP(player, xp)
    local data = playerData[player.UserId]
    if not data then return false end
    
    data.XP = data.XP + xp
    local newLevel = Utils.GetLevelFromXP(data.XP)
    
    if newLevel > data.Level then
        data.Level = newLevel
        print(player.Name .. " leveled up to " .. newLevel .. "!")
        
        -- Fire level up event
        local levelUp = game.ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUp")
        if levelUp then
            levelUp:FireClient(player, newLevel)
        end
        
        -- Give level up reward
        local reward = newLevel * 50 -- 50 coins per level
        addPlayerCurrency(player, reward, 0)
    end
    
    -- Update client UI
    local updateXP = game.ReplicatedStorage.RemoteEvents:FindFirstChild("UpdateXP")
    if updateXP then
        updateXP:FireClient(player, data.XP, data.Level)
    end
    
    return true
end

-- Player joined
Players.PlayerAdded:Connect(function(player)
    print("Loading data for " .. player.Name .. "...")
    
    -- Load player data
    local data = loadPlayerData(player)
    playerData[player.UserId] = data
    
    -- Set up auto-save
    local connection = RunService.Heartbeat:Connect(function()
        -- Auto-save every 60 seconds
        if Utils.HasTimePassed(data.LastSave, Config.Game.AutoSaveInterval) then
            savePlayerData(player)
        end
    end)
    
    autoSaveConnections[player.UserId] = connection
    
    print(player.Name .. " data loaded successfully!")
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
    print("Saving data for " .. player.Name .. "...")
    
    -- Save data
    savePlayerData(player)
    
    -- Clean up auto-save connection
    local connection = autoSaveConnections[player.UserId]
    if connection then
        connection:Disconnect()
        autoSaveConnections[player.UserId] = nil
    end
    
    -- Clear cached data
    playerData[player.UserId] = nil
    
    print(player.Name .. " data saved and cleaned up!")
end)

-- Server shutdown - save all data
game:BindToClose(function()
    print("Server shutting down, saving all player data...")
    
    for _, player in pairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
    
    print("All player data saved!")
    wait(2) -- Give time for saves to complete
end)

-- Expose public functions
_G.PlayerDataAPI = {
    GetData = getPlayerData,
    UpdateData = updatePlayerData,
    AddCurrency = addPlayerCurrency,
    SpendCurrency = spendPlayerCurrency,
    AddXP = addPlayerXP,
    Save = savePlayerData
}