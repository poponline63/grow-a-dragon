-- QuestSystem.server.lua - Daily and weekly quest system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- Wait for DataStore API to be ready
repeat wait() until _G.PlayerDataAPI
local DataAPI = _G.PlayerDataAPI

-- Generate new quests for a player
local function generateDailyQuests(player)
    local data = DataAPI.GetData(player)
    if not data then return end
    
    -- Clear existing daily quests
    data.Quests.Daily = {}
    
    -- Generate new daily quests (pick 3 random quests)
    local availableQuests = Utils.DeepCopy(Config.Quests.Daily)
    local selectedQuests = {}
    
    for i = 1, 3 do
        if #availableQuests > 0 then
            local index = math.random(1, #availableQuests)
            local quest = availableQuests[index]
            
            -- Create quest with unique ID and progress tracking
            local questId = Utils.GenerateId()
            selectedQuests[questId] = {
                Id = questId,
                Type = quest.Type,
                Amount = quest.Amount,
                Progress = 0,
                Reward = quest.Reward,
                Completed = false,
                Claimed = false
            }
            
            -- Remove from available quests to avoid duplicates
            table.remove(availableQuests, index)
        end
    end
    
    data.Quests.Daily = selectedQuests
    data.Quests.LastReset.Daily = Utils.GetTimestamp()
    
    print("Generated daily quests for " .. player.Name)
end

local function generateWeeklyQuests(player)
    local data = DataAPI.GetData(player)
    if not data then return end
    
    -- Clear existing weekly quests
    data.Quests.Weekly = {}
    
    -- Generate new weekly quests (pick 2 random quests)
    local availableQuests = Utils.DeepCopy(Config.Quests.Weekly)
    local selectedQuests = {}
    
    for i = 1, 2 do
        if #availableQuests > 0 then
            local index = math.random(1, #availableQuests)
            local quest = availableQuests[index]
            
            -- Create quest with unique ID and progress tracking
            local questId = Utils.GenerateId()
            selectedQuests[questId] = {
                Id = questId,
                Type = quest.Type,
                Amount = quest.Amount,
                Progress = 0,
                Reward = quest.Reward,
                Completed = false,
                Claimed = false
            }
            
            -- Remove from available quests to avoid duplicates
            table.remove(availableQuests, index)
        end
    end
    
    data.Quests.Weekly = selectedQuests
    data.Quests.LastReset.Weekly = Utils.GetTimestamp()
    
    print("Generated weekly quests for " .. player.Name)
end

-- Update quest progress
local function updateQuestProgress(player, questType, amount)
    local data = DataAPI.GetData(player)
    if not data then return end
    
    amount = amount or 1
    local questsUpdated = {}
    
    -- Update daily quests
    for questId, quest in pairs(data.Quests.Daily) do
        if quest.Type == questType and not quest.Completed then
            quest.Progress = math.min(quest.Progress + amount, quest.Amount)
            
            if quest.Progress >= quest.Amount then
                quest.Completed = true
                table.insert(questsUpdated, {Type = "Daily", Quest = quest})
            end
        end
    end
    
    -- Update weekly quests
    for questId, quest in pairs(data.Quests.Weekly) do
        if quest.Type == questType and not quest.Completed then
            quest.Progress = math.min(quest.Progress + amount, quest.Amount)
            
            if quest.Progress >= quest.Amount then
                quest.Completed = true
                table.insert(questsUpdated, {Type = "Weekly", Quest = quest})
            end
        end
    end
    
    -- Notify client of quest completion
    if #questsUpdated > 0 then
        local questCompleted = ReplicatedStorage.RemoteEvents:FindFirstChild("QuestCompleted")
        if questCompleted then
            questCompleted:FireClient(player, questsUpdated)
        end
    end
end

-- Claim quest reward
local function claimQuestReward(player, questType, questId)
    local data = DataAPI.GetData(player)
    if not data then return false, "No player data" end
    
    local quest
    if questType == "Daily" then
        quest = data.Quests.Daily[questId]
    elseif questType == "Weekly" then
        quest = data.Quests.Weekly[questId]
    end
    
    if not quest then
        return false, "Quest not found"
    end
    
    if not quest.Completed then
        return false, "Quest not completed"
    end
    
    if quest.Claimed then
        return false, "Reward already claimed"
    end
    
    -- Give rewards
    local coins = quest.Reward.Coins or 0
    local gems = quest.Reward.Gems or 0
    
    DataAPI.AddCurrency(player, coins, gems)
    quest.Claimed = true
    
    return true, "Claimed: " .. coins .. " coins" .. (gems > 0 and ", " .. gems .. " gems" or "")
end

-- Get active quests for player
local function getActiveQuests(player)
    local data = DataAPI.GetData(player)
    if not data then return {} end
    
    local activeQuests = {
        Daily = {},
        Weekly = {}
    }
    
    -- Get daily quests
    for questId, quest in pairs(data.Quests.Daily) do
        activeQuests.Daily[questId] = quest
    end
    
    -- Get weekly quests
    for questId, quest in pairs(data.Quests.Weekly) do
        activeQuests.Weekly[questId] = quest
    end
    
    return activeQuests
end

-- Check if quests need to be reset
local function checkQuestResets(player)
    local data = DataAPI.GetData(player)
    if not data then return end
    
    local currentTime = Utils.GetTimestamp()
    local lastDailyReset = data.Quests.LastReset.Daily or 0
    local lastWeeklyReset = data.Quests.LastReset.Weekly or 0
    
    -- Check daily reset (24 hours)
    if currentTime - lastDailyReset >= 86400 then
        generateDailyQuests(player)
    end
    
    -- Check weekly reset (7 days)
    if currentTime - lastWeeklyReset >= 604800 then
        generateWeeklyQuests(player)
    end
end

-- Create remote functions
local getQuestsFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("GetQuests")
if not getQuestsFunction then
    getQuestsFunction = Instance.new("RemoteFunction")
    getQuestsFunction.Name = "GetQuests"
    getQuestsFunction.Parent = ReplicatedStorage.RemoteFunctions
end

getQuestsFunction.OnServerInvoke = function(player)
    checkQuestResets(player)
    return getActiveQuests(player)
end

local claimQuestFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("ClaimQuest")
if not claimQuestFunction then
    claimQuestFunction = Instance.new("RemoteFunction")
    claimQuestFunction.Name = "ClaimQuest"
    claimQuestFunction.Parent = ReplicatedStorage.RemoteFunctions
end

claimQuestFunction.OnServerInvoke = function(player, questType, questId)
    local success, message = claimQuestReward(player, questType, questId)
    return {success = success, message = message}
end

-- Listen for game events to update quest progress
local function setupQuestTracking()
    -- Track egg hatching
    local eggHatched = ReplicatedStorage.RemoteEvents:FindFirstChild("EggHatched")
    if eggHatched then
        eggHatched.OnServerEvent:Connect(function(player)
            updateQuestProgress(player, "HatchEggs", 1)
        end)
    end
    
    -- Track dragon hatching (for rarity-specific quests)
    local dragonHatched = ReplicatedStorage.RemoteEvents:FindFirstChild("DragonHatched")
    if dragonHatched then
        dragonHatched.OnServerEvent:Connect(function(player, dragon)
            -- Update collect dragons quest
            updateQuestProgress(player, "CollectDragons", 1)
            
            -- Update hatch rare quest (if dragon is rare+)
            local rarityIndex = 1
            for i, rarity in pairs(Config.Dragons.Rarities) do
                if rarity == dragon.Rarity then
                    rarityIndex = i
                    break
                end
            end
            
            if rarityIndex >= 3 then -- Rare or higher (index 3+)
                updateQuestProgress(player, "HatchRare", 1)
            end
        end)
    end
end

-- Track other quest types through custom events
local questProgressFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("QuestProgress")
if not questProgressFunction then
    questProgressFunction = Instance.new("RemoteFunction")
    questProgressFunction.Name = "QuestProgress"
    questProgressFunction.Parent = ReplicatedStorage.RemoteFunctions
end

questProgressFunction.OnServerInvoke = function(player, questType, amount)
    updateQuestProgress(player, questType, amount)
    return true
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Let data load
        
        local data = DataAPI.GetData(player)
        if data then
            -- Generate initial quests if none exist
            if Utils.DictLen(data.Quests.Daily) == 0 then
                generateDailyQuests(player)
            end
            
            if Utils.DictLen(data.Quests.Weekly) == 0 then
                generateWeeklyQuests(player)
            end
            
            -- Check for resets
            checkQuestResets(player)
        end
    end)
end)

-- Setup quest tracking after all remote events are created
spawn(function()
    wait(5) -- Wait for all systems to load
    setupQuestTracking()
end)

-- Periodic quest reset check (every 10 minutes)
spawn(function()
    while true do
        wait(600) -- 10 minutes
        
        for _, player in pairs(Players:GetPlayers()) do
            checkQuestResets(player)
        end
    end
end)

-- Track additional quest progress through game events
game.ReplicatedStorage.RemoteEvents.ChildAdded:Connect(function(child)
    if child.Name == "UpdateCurrency" then
        child.OnServerEvent:Connect(function(player, coins, gems)
            -- This is fired when currency is updated, we can track earning
            -- However, we need a better way to track specifically earned coins vs spent
        end)
    end
end)

-- Custom quest tracking functions that other systems can call
_G.QuestAPI = {
    UpdateProgress = updateQuestProgress,
    CheckResets = checkQuestResets,
    GetQuests = getActiveQuests
}

print("QuestSystem loaded successfully!")