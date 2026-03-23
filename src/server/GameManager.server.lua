-- GameManager.server.lua - Core game loop and remote events
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local EggData = require(ReplicatedStorage.Shared.EggData)

-- Wait for DataStore API to be ready
repeat wait() until _G.PlayerDataAPI

local DataAPI = _G.PlayerDataAPI
local playerPlots = {} -- Track which plot each player has

-- Create RemoteEvents and RemoteFunctions folders if they don't exist
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctionsFolder then
    remoteFunctionsFolder = Instance.new("Folder")
    remoteFunctionsFolder.Name = "RemoteFunctions"
    remoteFunctionsFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local remoteEvents = {
    "UpdateCurrency",
    "UpdateXP", 
    "LevelUp",
    "EggPurchased",
    "EggHatched",
    "DragonHatched",
    "QuestCompleted",
    "DailyRewardClaimed"
}

for _, eventName in pairs(remoteEvents) do
    local event = remoteEventsFolder:FindFirstChild(eventName)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = remoteEventsFolder
    end
end

-- Create RemoteFunctions
local remoteFunctions = {
    "ClickForCoins",
    "BuyEgg",
    "SpeedUpEgg",
    "FeedDragon",
    "SetActiveCompanion",
    "ClaimDailyReward",
    "GetShopData",
    "GetPlayerStats"
}

for _, functionName in pairs(remoteFunctions) do
    local func = remoteFunctionsFolder:FindFirstChild(functionName)
    if not func then
        func = Instance.new("RemoteFunction")
        func.Name = functionName
        func.Parent = remoteFunctionsFolder
    end
end

-- Plot management
local function getNextAvailablePlot()
    for plotId = 1, Config.Game.PlotCount do
        local isUsed = false
        for _, usedPlotId in pairs(playerPlots) do
            if usedPlotId == plotId then
                isUsed = true
                break
            end
        end
        
        if not isUsed then
            return plotId
        end
    end
    return nil -- All plots taken
end

local function assignPlotToPlayer(player)
    local data = DataAPI.GetData(player)
    if not data then return end
    
    -- Check if player already has a plot
    if data.PlotId then
        playerPlots[player.UserId] = data.PlotId
        return data.PlotId
    end
    
    -- Assign new plot
    local plotId = getNextAvailablePlot()
    if plotId then
        data.PlotId = plotId
        playerPlots[player.UserId] = plotId
        print(player.Name .. " assigned to plot " .. plotId)
        return plotId
    end
    
    warn("No available plots for " .. player.Name)
    return nil
end

-- Click for coins system
local clickCooldowns = {} -- Prevent spam clicking
remoteFunctionsFolder.ClickForCoins.OnServerInvoke = function(player)
    local currentTime = tick()
    local lastClick = clickCooldowns[player.UserId] or 0
    
    -- 0.1 second cooldown
    if currentTime - lastClick < 0.1 then
        return {success = false, reason = "Too fast!"}
    end
    
    clickCooldowns[player.UserId] = currentTime
    
    local reward = Config.Currency.ClickReward
    local success = DataAPI.AddCurrency(player, reward, 0)
    
    if success then
        -- Add a tiny bit of XP for clicking
        DataAPI.AddXP(player, 1)
        
        return {
            success = true,
            coins = reward,
            message = "+" .. reward .. " coins!"
        }
    else
        return {success = false, reason = "Data error"}
    end
end

-- Buy egg system
remoteFunctionsFolder.BuyEgg.OnServerInvoke = function(player, tierName)
    local data = DataAPI.GetData(player)
    if not data then
        return {success = false, reason = "No player data"}
    end
    
    -- Check if player has space for more eggs
    local eggCount = Utils.DictLen(data.Eggs)
    if eggCount >= Config.Game.MaxEggsPerPlot then
        return {success = false, reason = "Plot is full! Hatch some eggs first."}
    end
    
    local tierData = EggData:GetTier(tierName)
    if not tierData then
        return {success = false, reason = "Invalid egg tier"}
    end
    
    -- Check if player can afford it
    if data.Coins < tierData.Price then
        local needed = tierData.Price - data.Coins
        return {success = false, reason = "Need " .. Utils.FormatNumber(needed) .. " more coins!"}
    end
    
    -- Purchase the egg
    local success = DataAPI.SpendCurrency(player, tierData.Price, 0)
    if success then
        -- Create new egg
        local eggId = Utils.GenerateId()
        local newEgg = {
            Id = eggId,
            Tier = tierName,
            HatchTime = tierData.HatchTime,
            StartTime = Utils.GetTimestamp(),
            Position = Vector3.new(0, 0, 0) -- Will be set by client
        }
        
        data.Eggs[eggId] = newEgg
        
        -- Fire event to clients
        remoteEventsFolder.EggPurchased:FireClient(player, newEgg)
        
        return {
            success = true,
            egg = newEgg,
            message = "Purchased " .. tierData.Name .. "!"
        }
    else
        return {success = false, reason = "Purchase failed"}
    end
end

-- Speed up egg hatching with gems
remoteFunctionsFolder.SpeedUpEgg.OnServerInvoke = function(player, eggId)
    local data = DataAPI.GetData(player)
    if not data then
        return {success = false, reason = "No player data"}
    end
    
    local egg = data.Eggs[eggId]
    if not egg then
        return {success = false, reason = "Egg not found"}
    end
    
    -- Check if player has enough gems
    local cost = Config.Eggs.GemSpeedUpCost
    if data.Gems < cost then
        return {success = false, reason = "Need " .. cost .. " gems!"}
    end
    
    -- Spend gems and instantly hatch
    local success = DataAPI.SpendCurrency(player, 0, cost)
    if success then
        -- Set egg to ready to hatch
        egg.StartTime = Utils.GetTimestamp() - egg.HatchTime
        
        return {
            success = true,
            message = "Egg ready to hatch!"
        }
    else
        return {success = false, reason = "Not enough gems"}
    end
end

-- Get shop data
remoteFunctionsFolder.GetShopData.OnServerInvoke = function(player)
    local tiers = EggData:GetAllTiers()
    local shopData = {}
    
    for _, tier in pairs(tiers) do
        table.insert(shopData, {
            Name = tier.Name,
            TierName = tier.TierName,
            Price = tier.Price,
            HatchTime = tier.HatchTime,
            Color = tier.Color,
            Description = tier.Description,
            RarityOdds = EggData:GetRarityOddsText(tier.TierName)
        })
    end
    
    return shopData
end

-- Get player stats for UI
remoteFunctionsFolder.GetPlayerStats.OnServerInvoke = function(player)
    local data = DataAPI.GetData(player)
    if not data then return nil end
    
    return {
        Coins = data.Coins,
        Gems = data.Gems,
        Level = data.Level,
        XP = data.XP,
        NextLevelXP = Utils.GetXPForNextLevel(data.Level),
        Progress = Utils.GetLevelProgress(data.XP, data.Level),
        DragonCount = Utils.DictLen(data.Dragons),
        EggCount = Utils.DictLen(data.Eggs)
    }
end

-- Daily reward system
remoteFunctionsFolder.ClaimDailyReward.OnServerInvoke = function(player)
    local data = DataAPI.GetData(player)
    if not data then
        return {success = false, reason = "No player data"}
    end
    
    local currentTime = Utils.GetTimestamp()
    local lastClaim = data.DailyReward.LastClaim
    local timeSinceClaim = currentTime - lastClaim
    
    -- Check if 24 hours have passed
    if timeSinceClaim < 86400 then -- 24 hours = 86400 seconds
        local timeLeft = 86400 - timeSinceClaim
        return {
            success = false, 
            reason = "Next reward in " .. Utils.FormatTime(timeLeft)
        }
    end
    
    -- Determine streak
    local streak = data.DailyReward.Streak
    if timeSinceClaim > 172800 then -- 48 hours - streak broken
        streak = 1
    else
        streak = math.min(streak + 1, #Config.Currency.DailyRewardCoins)
    end
    
    -- Get rewards
    local coins = Config.Currency.DailyRewardCoins[streak] or Config.Currency.DailyRewardCoins[#Config.Currency.DailyRewardCoins]
    local gems = Config.Currency.DailyRewardGems[streak] or Config.Currency.DailyRewardGems[#Config.Currency.DailyRewardGems]
    
    -- Give rewards
    DataAPI.AddCurrency(player, coins, gems)
    
    -- Update streak and timestamp
    data.DailyReward.LastClaim = currentTime
    data.DailyReward.Streak = streak
    
    -- Fire event
    remoteEventsFolder.DailyRewardClaimed:FireClient(player, {
        coins = coins,
        gems = gems,
        streak = streak
    })
    
    return {
        success = true,
        coins = coins,
        gems = gems,
        streak = streak,
        message = "Day " .. streak .. " reward claimed!"
    }
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    -- Wait for character to spawn
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Let character fully load
        
        -- Assign plot
        assignPlotToPlayer(player)
        
        -- Send initial data to client
        local stats = remoteFunctionsFolder.GetPlayerStats:InvokeClient(player)
        
        print(player.Name .. " joined the game!")
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Free up the plot
    if playerPlots[player.UserId] then
        playerPlots[player.UserId] = nil
    end
    
    -- Clear cooldowns
    if clickCooldowns[player.UserId] then
        clickCooldowns[player.UserId] = nil
    end
end)

print("GameManager loaded successfully!")