--[[
    QuestSystem.server.lua
    Daily and weekly quest management for V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataStore = require(script.Parent.DataStore)

local QuestSystem = {}
QuestSystem.ActiveQuests = {} -- Player -> {Daily = {}, Weekly = {}}

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local QuestProgressEvent = RemoteEvents:FindFirstChild("QuestProgress") or Instance.new("RemoteEvent")
QuestProgressEvent.Name = "QuestProgress"
QuestProgressEvent.Parent = RemoteEvents

local QuestCompletedEvent = RemoteEvents:FindFirstChild("QuestCompleted") or Instance.new("RemoteEvent")
QuestCompletedEvent.Name = "QuestCompleted" 
QuestCompletedEvent.Parent = RemoteEvents

local DailyRewardClaimedEvent = RemoteEvents:FindFirstChild("DailyRewardClaimed") or Instance.new("RemoteEvent")
DailyRewardClaimedEvent.Name = "DailyRewardClaimed"
DailyRewardClaimedEvent.Parent = RemoteEvents

-- Remote functions
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local ClaimQuestRewardFunction = RemoteFunctions:FindFirstChild("ClaimQuestReward") or Instance.new("RemoteFunction")
ClaimQuestRewardFunction.Name = "ClaimQuestReward"
ClaimQuestRewardFunction.Parent = RemoteFunctions

local ClaimDailyRewardFunction = RemoteFunctions:FindFirstChild("ClaimDailyReward") or Instance.new("RemoteFunction")
ClaimDailyRewardFunction.Name = "ClaimDailyReward"
ClaimDailyRewardFunction.Parent = RemoteFunctions

-- Quest templates
local DailyQuestTemplates = {
    {
        ID = "hatch_eggs",
        Description = "Hatch {target} eggs",
        Type = "hatch",
        BaseTarget = 3,
        BaseReward = {Coins = 200, Essence = 10}
    },
    {
        ID = "feed_dragons", 
        Description = "Feed dragons {target} times",
        Type = "feed",
        BaseTarget = 15,
        BaseReward = {Coins = 150, Essence = 8}
    },
    {
        ID = "earn_coins",
        Description = "Earn {target} coins",
        Type = "coins",
        BaseTarget = 1000,
        BaseReward = {Coins = 300, Essence = 15}
    },
    {
        ID = "send_expeditions",
        Description = "Send dragons on {target} expeditions",
        Type = "expedition",
        BaseTarget = 3,
        BaseReward = {Coins = 250, Essence = 12}
    },
    {
        ID = "upgrade_building",
        Description = "Upgrade a building",
        Type = "upgrade", 
        BaseTarget = 1,
        BaseReward = {Coins = 500, Essence = 25}
    },
    {
        ID = "visit_areas",
        Description = "Visit {target} different areas",
        Type = "visit",
        BaseTarget = 2,
        BaseReward = {Coins = 180, Essence = 9}
    }
}

local WeeklyQuestTemplates = {
    {
        ID = "breed_fusion",
        Description = "Breed a fusion dragon",
        Type = "breed_fusion",
        BaseTarget = 1,
        BaseReward = {Coins = 2000, Essence = 100}
    },
    {
        ID = "collect_rarity",
        Description = "Hatch an Epic+ dragon",
        Type = "hatch_rarity",
        BaseTarget = 1,
        RequiredRarity = "Epic",
        BaseReward = {Coins = 1500, Essence = 75}
    },
    {
        ID = "complete_dailies",
        Description = "Complete {target} daily quests", 
        Type = "complete_daily",
        BaseTarget = 10,
        BaseReward = {Coins = 3000, Essence = 150}
    },
    {
        ID = "earn_weekly_coins",
        Description = "Earn {target} coins this week",
        Type = "coins_weekly",
        BaseTarget = 25000,
        BaseReward = {Coins = 5000, Essence = 200}
    },
    {
        ID = "unlock_area",
        Description = "Unlock a new area",
        Type = "unlock_area",
        BaseTarget = 1,
        BaseReward = {Coins = 10000, Essence = 500}
    }
}

-- Generate daily quests
function QuestSystem.GenerateDailyQuests(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Clear existing quests
    playerData.Quests.Daily = {}
    
    -- Shuffle templates
    local availableTemplates = {}
    for _, template in ipairs(DailyQuestTemplates) do
        table.insert(availableTemplates, template)
    end
    
    -- Generate 3 daily quests
    for i = 1, 3 do
        if #availableTemplates > 0 then
            local templateIndex = math.random(#availableTemplates)
            local template = availableTemplates[templateIndex]
            
            -- Create quest from template
            local quest = QuestSystem.CreateQuestFromTemplate(template, "Daily", i)
            table.insert(playerData.Quests.Daily, quest)
            
            -- Remove template to avoid duplicates
            table.remove(availableTemplates, templateIndex)
        end
    end
    
    playerData.Quests.DailyResetTime = tick()
    DataStore.MarkDataDirty(player)
    
    print("Generated daily quests for", player.Name)
end

-- Generate weekly quest
function QuestSystem.GenerateWeeklyQuest(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Pick random weekly quest template
    local template = WeeklyQuestTemplates[math.random(#WeeklyQuestTemplates)]
    local quest = QuestSystem.CreateQuestFromTemplate(template, "Weekly", 1)
    
    playerData.Quests.Weekly = {quest}
    playerData.Quests.WeeklyResetTime = tick()
    DataStore.MarkDataDirty(player)
    
    print("Generated weekly quest for", player.Name)
end

-- Create quest from template
function QuestSystem.CreateQuestFromTemplate(template, questType, difficulty)
    local difficultyMultiplier = questType == "Daily" and difficulty or 1
    local target = math.ceil(template.BaseTarget * difficultyMultiplier)
    
    local quest = {
        ID = template.ID,
        Type = template.Type,
        Description = string.gsub(template.Description, "{target}", tostring(target)),
        Target = target,
        Progress = 0,
        Completed = false,
        Claimed = false,
        RequiredRarity = template.RequiredRarity,
        Reward = {
            Coins = math.ceil(template.BaseReward.Coins * difficultyMultiplier),
            Essence = math.ceil(template.BaseReward.Essence * difficultyMultiplier)
        },
        CreatedTime = tick()
    }
    
    return quest
end

-- Update quest progress
function QuestSystem.UpdateQuestProgress(player, questType, progressType, amount, extraData)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    amount = amount or 1
    local questList = questType == "Daily" and playerData.Quests.Daily or playerData.Quests.Weekly
    local updated = false
    
    for _, quest in ipairs(questList) do
        if not quest.Completed and quest.Type == progressType then
            
            -- Special handling for different quest types
            local shouldUpdate = true
            
            if progressType == "hatch_rarity" and extraData then
                -- Check if hatched dragon meets rarity requirement
                local rarityIndex = 1
                local requiredIndex = 1
                
                for i, rarity in ipairs(Config.Rarities) do
                    if rarity.Name == extraData.rarity then rarityIndex = i end
                    if rarity.Name == quest.RequiredRarity then requiredIndex = i end
                end
                
                shouldUpdate = rarityIndex >= requiredIndex
            elseif progressType == "breed_fusion" and extraData then
                -- Check if bred dragon is a fusion
                local isFusion = Config.FusionElements[extraData.element] ~= nil
                shouldUpdate = isFusion
            end
            
            if shouldUpdate then
                quest.Progress = math.min(quest.Progress + amount, quest.Target)
                updated = true
                
                -- Check for completion
                if quest.Progress >= quest.Target and not quest.Completed then
                    quest.Completed = true
                    QuestCompletedEvent:FireClient(player, quest, questType)
                    print(player.Name .. " completed " .. questType .. " quest: " .. quest.Description)
                end
                
                -- Send progress update
                QuestProgressEvent:FireClient(player, quest, questType)
            end
        end
    end
    
    if updated then
        DataStore.MarkDataDirty(player)
    end
end

-- Claim quest reward
function QuestSystem.ClaimQuestReward(player, questType, questIndex)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false, "Player data not found" end
    
    local questList = questType == "Daily" and playerData.Quests.Daily or playerData.Quests.Weekly
    local quest = questList[questIndex]
    
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
    DataStore.AddCoins(player, quest.Reward.Coins)
    DataStore.AddEssence(player, quest.Reward.Essence)
    
    quest.Claimed = true
    DataStore.MarkDataDirty(player)
    
    print(player.Name .. " claimed " .. questType .. " quest reward: " .. quest.Reward.Coins .. " coins, " .. quest.Reward.Essence .. " essence")
    
    -- Update weekly quest progress if this was a daily
    if questType == "Daily" then
        QuestSystem.UpdateQuestProgress(player, "Weekly", "complete_daily", 1)
    end
    
    return true, "Reward claimed successfully"
end

-- Daily login reward system
function QuestSystem.ClaimDailyReward(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false, "Player data not found" end
    
    -- Check if daily reward can be claimed
    local daysSinceLastReward = math.floor((tick() - playerData.LastDailyReward) / 86400)
    if daysSinceLastReward < 1 then
        return false, "Daily reward already claimed today"
    end
    
    -- Update streak
    if daysSinceLastReward == 1 then
        playerData.LoginStreak = math.min(playerData.LoginStreak + 1, 7)
    else
        playerData.LoginStreak = 1
    end
    
    -- Get reward for current streak day
    local rewardDay = playerData.LoginStreak
    local reward = Config.DailyRewards[rewardDay]
    
    if not reward then
        return false, "Invalid reward day"
    end
    
    -- Give rewards
    if reward.Coins > 0 then
        DataStore.AddCoins(player, reward.Coins)
    end
    
    if reward.Essence > 0 then
        DataStore.AddEssence(player, reward.Essence)
    end
    
    -- Give items
    for _, item in ipairs(reward.Items) do
        if item == "Rare Egg" then
            local egg, _ = require(ReplicatedStorage.Shared.EggData).CreateEgg("Crystal Egg", player.UserId)
            if egg then
                table.insert(playerData.EggsInInventory, egg)
            end
        elseif item == "Epic Egg" then
            local egg, _ = require(ReplicatedStorage.Shared.EggData).CreateEgg("Shadow Egg", player.UserId)
            if egg then
                table.insert(playerData.EggsInInventory, egg)
            end
        elseif item == "Legendary Egg" then
            local egg, _ = require(ReplicatedStorage.Shared.EggData).CreateEgg("Golden Egg", player.UserId)
            if egg then
                table.insert(playerData.EggsInInventory, egg)
            end
        end
    end
    
    playerData.LastDailyReward = tick()
    DataStore.MarkDataDirty(player)
    
    DailyRewardClaimedEvent:FireClient(player, reward, rewardDay)
    print(player.Name .. " claimed daily reward day " .. rewardDay)
    
    return true, "Daily reward claimed"
end

-- Check for quest resets
function QuestSystem.CheckQuestResets(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Check daily reset
    local daysSinceDailyReset = math.floor((tick() - playerData.Quests.DailyResetTime) / 86400)
    if daysSinceDailyReset >= 1 then
        QuestSystem.GenerateDailyQuests(player)
    end
    
    -- Check weekly reset (7 days)
    local daysSinceWeeklyReset = math.floor((tick() - playerData.Quests.WeeklyResetTime) / (86400 * 7))
    if daysSinceWeeklyReset >= 1 then
        QuestSystem.GenerateWeeklyQuest(player)
    end
end

-- Initialize quests for new player
function QuestSystem.InitializePlayerQuests(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Generate initial quests if none exist
    if #playerData.Quests.Daily == 0 then
        QuestSystem.GenerateDailyQuests(player)
    end
    
    if #playerData.Quests.Weekly == 0 then
        QuestSystem.GenerateWeeklyQuest(player)
    end
    
    QuestSystem.ActiveQuests[player] = {
        Daily = playerData.Quests.Daily,
        Weekly = playerData.Quests.Weekly
    }
end

-- Player cleanup
function QuestSystem.OnPlayerRemoving(player)
    QuestSystem.ActiveQuests[player] = nil
end

-- Remote function handlers
ClaimQuestRewardFunction.OnServerInvoke = function(player, questType, questIndex)
    return QuestSystem.ClaimQuestReward(player, questType, questIndex)
end

ClaimDailyRewardFunction.OnServerInvoke = function(player)
    return QuestSystem.ClaimDailyReward(player)
end

-- Event listeners for quest progress
game.ReplicatedStorage.RemoteEvents.DragonHatched.Event:Connect(function(player, dragon)
    QuestSystem.UpdateQuestProgress(player, "Daily", "hatch", 1)
    QuestSystem.UpdateQuestProgress(player, "Weekly", "hatch_rarity", 1, {rarity = dragon.Rarity})
end)

game.ReplicatedStorage.RemoteEvents.DragonFed.Event:Connect(function(player)
    QuestSystem.UpdateQuestProgress(player, "Daily", "feed", 1)
end)

game.ReplicatedStorage.RemoteEvents.BreedingStarted.Event:Connect(function(player, dragon1, dragon2, element)
    QuestSystem.UpdateQuestProgress(player, "Weekly", "breed_fusion", 1, {element = element})
end)

-- Quest reset checker
spawn(function()
    while true do
        wait(300) -- Check every 5 minutes
        for _, player in ipairs(Players:GetPlayers()) do
            QuestSystem.CheckQuestResets(player)
        end
    end
end)

-- Event connections
Players.PlayerAdded:Connect(function(player)
    -- Wait for data to load
    wait(2)
    QuestSystem.InitializePlayerQuests(player)
end)

Players.PlayerRemoving:Connect(QuestSystem.OnPlayerRemoving)

return QuestSystem