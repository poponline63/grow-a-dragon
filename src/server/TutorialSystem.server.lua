--[[
    TutorialSystem.server.lua
    Tutorial and onboarding system for Grow a Dragon V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Wait for shared modules
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)
local DataStore = require(script.Parent.DataStore)

-- Create RemoteEvents for tutorial
local TutorialFolder = Instance.new("Folder")
TutorialFolder.Name = "Tutorial"
TutorialFolder.Parent = ReplicatedStorage:WaitForChild("RemoteEvents")

local StartTutorialRemote = Instance.new("RemoteEvent")
StartTutorialRemote.Name = "StartTutorial"
StartTutorialRemote.Parent = TutorialFolder

local AdvanceTutorialRemote = Instance.new("RemoteEvent")
AdvanceTutorialRemote.Name = "AdvanceTutorial"
AdvanceTutorialRemote.Parent = TutorialFolder

local SkipTutorialRemote = Instance.new("RemoteEvent")
SkipTutorialRemote.Name = "SkipTutorial"
SkipTutorialRemote.Parent = TutorialFolder

local TutorialActionRemote = Instance.new("RemoteEvent")
TutorialActionRemote.Name = "TutorialAction"
TutorialActionRemote.Parent = TutorialFolder

local TutorialSystem = {}
TutorialSystem.ActiveTutorials = {}

-- Tutorial step definitions
TutorialSystem.TutorialSteps = {
    {
        ID = "welcome",
        Title = "Welcome to Grow a Dragon! 🐉",
        Description = "You're about to start an amazing dragon adventure!",
        Type = "popup",
        Duration = 4,
        AutoAdvance = true
    },
    {
        ID = "egg_shop",
        Title = "Buy Your First Egg",
        Description = "Click the Shop button to browse available dragon eggs!",
        Type = "arrow",
        Target = "ShopButton",
        Action = "click",
        Highlight = true
    },
    {
        ID = "egg_purchase",
        Title = "Choose An Egg",
        Description = "Buy a Stone Egg to start your collection!",
        Type = "highlight",
        Target = "StoneEgg",
        Action = "purchase",
        Condition = "EggPurchased"
    },
    {
        ID = "place_egg",
        Title = "Place Your Egg",
        Description = "Take your egg to your plot and place it in the incubator!",
        Type = "arrow",
        Target = "Incubator",
        Action = "place_egg",
        Condition = "EggPlaced"
    },
    {
        ID = "wait_hatch",
        Title = "Wait for Hatching",
        Description = "Your egg is incubating! Wait for it to hatch or watch the magic happen!",
        Type = "popup",
        Duration = 3,
        Condition = "EggHatching"
    },
    {
        ID = "dragon_hatched",
        Title = "Congratulations! 🎉",
        Description = "You hatched a {DragonType}! Welcome to the family!",
        Type = "celebration",
        Duration = 5,
        Condition = "DragonHatched",
        Effect = "confetti"
    },
    {
        ID = "feed_dragon",
        Title = "Feed Your Dragon",
        Description = "Click the food bowl to feed your dragon and help it grow!",
        Type = "arrow",
        Target = "FoodBowl",
        Action = "feed",
        Condition = "DragonFed"
    },
    {
        ID = "tutorial_complete",
        Title = "Tutorial Complete! 🎉",
        Description = "Here's 500 bonus coins to help you on your journey!",
        Type = "popup",
        Duration = 4,
        Reward = {Coins = 500},
        Final = true
    }
}

-- Check if player needs tutorial
function TutorialSystem.ShouldStartTutorial(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false end
    
    -- Check if tutorial already completed
    if playerData.TutorialCompleted then
        return false
    end
    
    -- Check if player has any dragons (skip tutorial if they do)
    if #playerData.Dragons > 0 then
        -- Mark tutorial as completed
        playerData.TutorialCompleted = true
        DataStore.MarkDataDirty(player)
        return false
    end
    
    -- Check if tutorial is in progress
    if playerData.TutorialProgress then
        return true -- Continue existing tutorial
    end
    
    return true
end

-- Start tutorial for player
function TutorialSystem.StartTutorial(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Initialize tutorial progress
    playerData.TutorialProgress = {
        CurrentStep = 1,
        StepsCompleted = {},
        StartTime = tick(),
        LastStepTime = tick()
    }
    
    -- Mark as active
    TutorialSystem.ActiveTutorials[player] = {
        CurrentStep = 1,
        StepData = TutorialSystem.TutorialSteps[1],
        StartTime = tick()
    }
    
    DataStore.MarkDataDirty(player)
    
    -- Send initial step to client
    TutorialActionRemote:FireClient(player, "show_step", TutorialSystem.TutorialSteps[1])
    
    print("Started tutorial for", player.Name)
end

-- Advance to next tutorial step
function TutorialSystem.AdvanceStep(player, forceNext)
    local playerData = DataStore.GetPlayerData(player)
    local tutorialData = TutorialSystem.ActiveTutorials[player]
    
    if not playerData or not playerData.TutorialProgress or not tutorialData then
        return
    end
    
    local currentStepNum = playerData.TutorialProgress.CurrentStep
    local currentStep = TutorialSystem.TutorialSteps[currentStepNum]
    
    -- Check if step condition is met (unless forcing)
    if not forceNext and currentStep.Condition then
        if not TutorialSystem.CheckCondition(player, currentStep.Condition) then
            return false -- Condition not met
        end
    end
    
    -- Mark current step as completed
    table.insert(playerData.TutorialProgress.StepsCompleted, currentStepNum)
    playerData.TutorialProgress.LastStepTime = tick()
    
    -- Check if tutorial is complete
    if currentStep.Final then
        TutorialSystem.CompleteTutorial(player)
        return true
    end
    
    -- Advance to next step
    local nextStepNum = currentStepNum + 1
    local nextStep = TutorialSystem.TutorialSteps[nextStepNum]
    
    if nextStep then
        playerData.TutorialProgress.CurrentStep = nextStepNum
        tutorialData.CurrentStep = nextStepNum
        tutorialData.StepData = nextStep
        
        DataStore.MarkDataDirty(player)
        
        -- Send next step to client
        TutorialActionRemote:FireClient(player, "show_step", nextStep)
        
        print("Advanced", player.Name, "to tutorial step", nextStepNum, ":", nextStep.Title)
        return true
    else
        -- No more steps, complete tutorial
        TutorialSystem.CompleteTutorial(player)
        return true
    end
end

-- Complete tutorial
function TutorialSystem.CompleteTutorial(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Mark tutorial as completed
    playerData.TutorialCompleted = true
    playerData.TutorialProgress = nil -- Clean up progress data
    
    -- Give completion rewards
    local finalStep = TutorialSystem.TutorialSteps[#TutorialSystem.TutorialSteps]
    if finalStep.Reward then
        if finalStep.Reward.Coins then
            DataStore.AddCoins(player, finalStep.Reward.Coins)
        end
        if finalStep.Reward.Essence then
            DataStore.AddEssence(player, finalStep.Reward.Essence)
        end
    end
    
    -- Update stats
    playerData.Stats.TutorialCompleted = true
    playerData.Stats.TutorialCompletionTime = tick() - (playerData.TutorialProgress and playerData.TutorialProgress.StartTime or tick())
    
    DataStore.MarkDataDirty(player)
    
    -- Clean up active tutorial
    TutorialSystem.ActiveTutorials[player] = nil
    
    -- Notify client
    TutorialActionRemote:FireClient(player, "tutorial_complete", finalStep)
    
    print("Tutorial completed for", player.Name)
end

-- Skip tutorial
function TutorialSystem.SkipTutorial(player)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Mark as skipped and completed
    playerData.TutorialCompleted = true
    playerData.TutorialProgress = nil
    playerData.Stats.TutorialSkipped = true
    
    DataStore.MarkDataDirty(player)
    
    -- Clean up active tutorial
    TutorialSystem.ActiveTutorials[player] = nil
    
    -- Notify client
    TutorialActionRemote:FireClient(player, "tutorial_skipped")
    
    print("Tutorial skipped for", player.Name)
end

-- Check tutorial step conditions
function TutorialSystem.CheckCondition(player, condition)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false end
    
    if condition == "EggPurchased" then
        return #playerData.EggsInInventory > 0
    elseif condition == "EggPlaced" then
        return #playerData.EggsInIncubators > 0
    elseif condition == "EggHatching" then
        -- Check if any egg is currently hatching
        for _, egg in pairs(playerData.EggsInIncubators) do
            if egg.HatchTime and tick() >= egg.HatchTime then
                return true
            end
        end
        return false
    elseif condition == "DragonHatched" then
        return #playerData.Dragons > 0
    elseif condition == "DragonFed" then
        -- Check if any dragon has been fed
        for _, dragon in pairs(playerData.Dragons) do
            if dragon.FeedCount and dragon.FeedCount > 0 then
                return true
            end
        end
        return false
    end
    
    return true -- Default to true for unknown conditions
end

-- Check tutorial progress for players automatically
function TutorialSystem.CheckPlayerProgress(player)
    local tutorialData = TutorialSystem.ActiveTutorials[player]
    if not tutorialData then return end
    
    local currentStep = tutorialData.StepData
    if currentStep.Condition and TutorialSystem.CheckCondition(player, currentStep.Condition) then
        -- Condition met, advance automatically
        wait(0.5) -- Small delay for better UX
        TutorialSystem.AdvanceStep(player, false)
    end
end

-- Handle game events that affect tutorial
function TutorialSystem.OnEggPurchased(player)
    spawn(function()
        wait(1) -- Allow purchase to complete
        TutorialSystem.CheckPlayerProgress(player)
    end)
end

function TutorialSystem.OnEggPlaced(player)
    spawn(function()
        wait(1)
        TutorialSystem.CheckPlayerProgress(player)
    end)
end

function TutorialSystem.OnDragonHatched(player)
    spawn(function()
        wait(2) -- Allow hatch animation to complete
        TutorialSystem.CheckPlayerProgress(player)
    end)
end

function TutorialSystem.OnDragonFed(player)
    spawn(function()
        wait(1)
        TutorialSystem.CheckPlayerProgress(player)
    end)
end

-- Remote event handlers
StartTutorialRemote.OnServerEvent:Connect(function(player)
    TutorialSystem.StartTutorial(player)
end)

AdvanceTutorialRemote.OnServerEvent:Connect(function(player, forceNext)
    TutorialSystem.AdvanceStep(player, forceNext or false)
end)

SkipTutorialRemote.OnServerEvent:Connect(function(player)
    TutorialSystem.SkipTutorial(player)
end)

-- Player connection handling
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(3) -- Let character fully spawn
        
        if TutorialSystem.ShouldStartTutorial(player) then
            wait(2) -- Additional delay for UI to load
            TutorialSystem.StartTutorial(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    TutorialSystem.ActiveTutorials[player] = nil
end)

print("TutorialSystem loaded")

return TutorialSystem