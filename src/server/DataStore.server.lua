--[[
    DataStore.server.lua
    Player data persistence for Grow a Dragon V3
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonData = require(ReplicatedStorage.Shared.DragonData)

-- Create data stores
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_V3")
local BackupDataStore = DataStoreService:GetDataStore("PlayerDataBackup_V3")

local DataStore = {}
DataStore.PlayerData = {}
DataStore.SessionData = {}

-- Default player data structure
local function getDefaultPlayerData()
    return {
        -- Profile
        Level = 1,
        XP = 0,
        JoinTime = tick(),
        LastLogin = tick(),
        PlayTime = 0,
        
        -- Currency
        Coins = Config.Economy.StartingCoins,
        Essence = Config.Economy.StartingEssence,
        
        -- Dragons
        Dragons = {},
        EggsInInventory = {},
        EggsInIncubators = {},
        
        -- Plot upgrades
        Plot = {
            Incubators = 1,
            DragonPenSize = 1,
            HasAutoFeeder = false,
            HasBreedingAltar = false,
            Decorations = {}
        },
        
        -- Unlocked areas
        UnlockedAreas = {"Spawn Hub"},
        
        -- Quest progress
        Quests = {
            Daily = {},
            Weekly = {},
            DailyResetTime = 0,
            WeeklyResetTime = 0
        },
        
        -- Daily rewards
        LoginStreak = 0,
        LastDailyReward = 0,
        
        -- Statistics
        Stats = {
            DragonsHatched = 0,
            EggsBought = 0,
            CoinsEarned = 0,
            ExpeditionsCompleted = 0,
            DragonsBreed = 0,
            FusionsDiscovered = {},
            RarestDragon = "Common"
        },
        
        -- Settings
        Settings = {
            AutoHatch = false,
            TripleHatch = false,
            VIPAccess = false,
            NotificationsEnabled = true,
            SoundEnabled = true
        },
        
        -- Version tracking
        DataVersion = 3
    }
end

-- Data validation
local function validatePlayerData(data)
    if not data or type(data) ~= "table" then
        return false
    end
    
    -- Check required fields
    local required = {"Level", "Coins", "Dragons", "UnlockedAreas"}
    for _, field in ipairs(required) do
        if data[field] == nil then
            warn("Missing required field:", field)
            return false
        end
    end
    
    -- Validate dragons
    if type(data.Dragons) ~= "table" then
        warn("Dragons field is not a table")
        return false
    end
    
    for i, dragon in ipairs(data.Dragons) do
        if not dragon.UniqueId or not dragon.Element or not dragon.Rarity then
            warn("Invalid dragon at index", i)
            return false
        end
    end
    
    return true
end

-- Save player data with retry logic
function DataStore.SavePlayerData(player, data)
    if not data then
        warn("No data to save for", player.Name)
        return false
    end
    
    local success = false
    local attempts = 0
    local maxAttempts = 3
    
    while not success and attempts < maxAttempts do
        attempts = attempts + 1
        
        success = pcall(function()
            -- Save to primary store
            PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
            
            -- Save backup every 5 minutes
            local sessionData = DataStore.SessionData[player]
            if not sessionData.LastBackup or tick() - sessionData.LastBackup > 300 then
                BackupDataStore:SetAsync("Player_" .. player.UserId .. "_" .. tick(), data)
                sessionData.LastBackup = tick()
            end
        end)
        
        if not success and attempts < maxAttempts then
            wait(1) -- Wait before retry
        end
    end
    
    if success then
        print("Saved data for", player.Name)
        return true
    else
        warn("Failed to save data for", player.Name, "after", maxAttempts, "attempts")
        return false
    end
end

-- Load player data with backup fallback
function DataStore.LoadPlayerData(player)
    local data = nil
    local success = false
    
    -- Try primary store first
    success = pcall(function()
        data = PlayerDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if not success or not data then
        warn("Failed to load primary data for", player.Name, "- checking backups")
        
        -- Try to get list of backups
        success = pcall(function()
            local pages = BackupDataStore:ListKeysAsync("Player_" .. player.UserId)
            local keys = {}
            
            repeat
                local currentPage = pages:GetCurrentPage()
                for _, item in ipairs(currentPage) do
                    table.insert(keys, item.KeyName)
                end
                
                if not pages.IsFinished then
                    pages:AdvanceToNextPageAsync()
                end
            until pages.IsFinished
            
            -- Sort by timestamp (most recent first)
            table.sort(keys, function(a, b)
                local timeA = tonumber(string.match(a, "_(%d+)$"))
                local timeB = tonumber(string.match(b, "_(%d+)$"))
                return (timeA or 0) > (timeB or 0)
            end)
            
            -- Try most recent backup
            if #keys > 0 then
                data = BackupDataStore:GetAsync(keys[1])
                print("Loaded backup data for", player.Name)
            end
        end)
    end
    
    -- Validate loaded data
    if data and validatePlayerData(data) then
        -- Check for data migration
        if data.DataVersion and data.DataVersion < 3 then
            data = DataStore.MigratePlayerData(data)
        end
        
        DataStore.PlayerData[player] = data
        print("Loaded player data for", player.Name)
        return data
    else
        -- Create new player data
        warn("Creating new data for", player.Name)
        local newData = getDefaultPlayerData()
        DataStore.PlayerData[player] = newData
        return newData
    end
end

-- Migrate old data format to V3
function DataStore.MigratePlayerData(oldData)
    print("Migrating player data to V3")
    local newData = getDefaultPlayerData()
    
    -- Copy over what we can
    newData.Coins = oldData.Coins or newData.Coins
    newData.Level = oldData.Level or newData.Level
    newData.JoinTime = oldData.JoinTime or newData.JoinTime
    
    -- Migrate dragons if they exist
    if oldData.Dragons then
        for _, dragon in ipairs(oldData.Dragons) do
            if dragon.Element and dragon.Rarity then
                -- Recreate dragon with V3 structure
                local migratedDragon = DragonData.CreateDragon(
                    dragon.Element,
                    dragon.Rarity,
                    dragon.Stage or 1,
                    dragon.Variant or "Normal"
                )
                migratedDragon.UniqueId = dragon.UniqueId or migratedDragon.UniqueId
                migratedDragon.HatchTime = dragon.HatchTime or migratedDragon.HatchTime
                table.insert(newData.Dragons, migratedDragon)
            end
        end
    end
    
    newData.DataVersion = 3
    return newData
end

-- Player connection handling
function DataStore.OnPlayerAdded(player)
    print("Player joined:", player.Name)
    
    -- Initialize session data
    DataStore.SessionData[player] = {
        SessionStart = tick(),
        LastSave = tick(),
        LastBackup = 0,
        HasUnsavedChanges = false
    }
    
    -- Load player data
    local data = DataStore.LoadPlayerData(player)
    
    -- Update login info
    data.LastLogin = tick()
    
    -- Update login streak
    local daysSinceLastLogin = math.floor((tick() - data.LastDailyReward) / 86400)
    if daysSinceLastLogin == 1 then
        data.LoginStreak = data.LoginStreak + 1
    elseif daysSinceLastLogin > 1 then
        data.LoginStreak = 1
    end
    
    -- Check for daily quest reset
    local daysSinceQuestReset = math.floor((tick() - data.Quests.DailyResetTime) / 86400)
    if daysSinceQuestReset >= 1 then
        DataStore.ResetDailyQuests(player)
    end
    
    -- Auto-save setup
    spawn(function()
        while Players:FindFirstChild(player.Name) do
            wait(60) -- Auto-save every minute
            DataStore.AutoSave(player)
        end
    end)
end

function DataStore.OnPlayerRemoving(player)
    print("Player leaving:", player.Name)
    
    local data = DataStore.PlayerData[player]
    if data then
        -- Update play time
        local sessionData = DataStore.SessionData[player]
        if sessionData then
            data.PlayTime = data.PlayTime + (tick() - sessionData.SessionStart)
        end
        
        -- Final save
        DataStore.SavePlayerData(player, data)
    end
    
    -- Clean up
    DataStore.PlayerData[player] = nil
    DataStore.SessionData[player] = nil
end

-- Auto-save system
function DataStore.AutoSave(player)
    local data = DataStore.PlayerData[player]
    local sessionData = DataStore.SessionData[player]
    
    if data and sessionData and sessionData.HasUnsavedChanges then
        if DataStore.SavePlayerData(player, data) then
            sessionData.LastSave = tick()
            sessionData.HasUnsavedChanges = false
        end
    end
end

-- Mark player data as dirty (needs saving)
function DataStore.MarkDataDirty(player)
    local sessionData = DataStore.SessionData[player]
    if sessionData then
        sessionData.HasUnsavedChanges = true
    end
end

-- Reset daily quests
function DataStore.ResetDailyQuests(player)
    local data = DataStore.PlayerData[player]
    if not data then return end
    
    data.Quests.Daily = {}
    data.Quests.DailyResetTime = tick()
    
    -- Generate new daily quests
    local questTemplates = {
        "Hatch 3 eggs",
        "Feed dragons 10 times", 
        "Earn 500 coins",
        "Send dragons on 2 expeditions",
        "Upgrade a building"
    }
    
    -- Pick 3 random quests
    for i = 1, 3 do
        local questIndex = math.random(#questTemplates)
        local quest = {
            Description = questTemplates[questIndex],
            Progress = 0,
            Target = i == 1 and 3 or (i == 2 and 10 or (i == 3 and 500 or 2)),
            Completed = false,
            Reward = {Coins = 100 * i, Essence = 5 * i}
        }
        table.insert(data.Quests.Daily, quest)
        table.remove(questTemplates, questIndex)
    end
    
    DataStore.MarkDataDirty(player)
    print("Reset daily quests for", player.Name)
end

-- Public API
function DataStore.GetPlayerData(player)
    return DataStore.PlayerData[player]
end

function DataStore.AddCoins(player, amount)
    local data = DataStore.PlayerData[player]
    if data then
        data.Coins = data.Coins + amount
        DataStore.MarkDataDirty(player)
        return true
    end
    return false
end

function DataStore.SpendCoins(player, amount)
    local data = DataStore.PlayerData[player]
    if data and data.Coins >= amount then
        data.Coins = data.Coins - amount
        DataStore.MarkDataDirty(player)
        return true
    end
    return false
end

function DataStore.AddEssence(player, amount)
    local data = DataStore.PlayerData[player]
    if data then
        data.Essence = data.Essence + amount
        DataStore.MarkDataDirty(player)
        return true
    end
    return false
end

function DataStore.SpendEssence(player, amount)
    local data = DataStore.PlayerData[player]
    if data and data.Essence >= amount then
        data.Essence = data.Essence - amount
        DataStore.MarkDataDirty(player)
        return true
    end
    return false
end

-- Event connections
Players.PlayerAdded:Connect(DataStore.OnPlayerAdded)
Players.PlayerRemoving:Connect(DataStore.OnPlayerRemoving)

-- Shutdown save
game:BindToClose(function()
    print("Saving all player data before shutdown...")
    for player, data in pairs(DataStore.PlayerData) do
        DataStore.SavePlayerData(player, data)
    end
    wait(2) -- Give time for saves to complete
end)

return DataStore