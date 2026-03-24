--[[
    EggData.lua
    Egg system definitions and hatching mechanics for V3
]]

local Config = require(script.Parent.Config)
local DragonData = require(script.Parent.DragonData)
local EggData = {}

--------------------------------------------------------------------------------
-- Egg Definitions
--------------------------------------------------------------------------------
EggData.EggTypes = {
    ["Stone Egg"] = {
        Price = 100,
        Currency = "Coins",
        HatchTime = 60, -- 1 minute
        AvailableIn = {"Enchanted Meadow"},
        PossibleElements = {"Fire", "Nature"},
        RarityWeights = {
            Common = 0.5,
            Uncommon = 0.3,
            Rare = 0.2,
            Epic = 0.0,
            Legendary = 0.0,
            Mythic = 0.0,
            Huge = 0.0
        }
    },
    
    ["Crystal Egg"] = {
        Price = 500,
        Currency = "Coins", 
        HatchTime = 5 * 60, -- 5 minutes
        AvailableIn = {"Crystal Caverns"},
        PossibleElements = {"Ice", "Storm"},
        RarityWeights = {
            Common = 0.3,
            Uncommon = 0.4,
            Rare = 0.25,
            Epic = 0.05,
            Legendary = 0.0,
            Mythic = 0.0,
            Huge = 0.0
        }
    },
    
    ["Shadow Egg"] = {
        Price = 2500,
        Currency = "Coins",
        HatchTime = 15 * 60, -- 15 minutes  
        AvailableIn = {"Shadow Realm"},
        PossibleElements = {"Shadow", "Light"},
        RarityWeights = {
            Common = 0.2,
            Uncommon = 0.3, 
            Rare = 0.35,
            Epic = 0.13,
            Legendary = 0.02,
            Mythic = 0.0,
            Huge = 0.0
        }
    },
    
    ["Golden Egg"] = {
        Price = 10000,
        Currency = "Coins",
        HatchTime = 30 * 60, -- 30 minutes
        AvailableIn = {"Sky Temple"},
        PossibleElements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
        RarityWeights = {
            Common = 0.1,
            Uncommon = 0.2,
            Rare = 0.4,
            Epic = 0.25,
            Legendary = 0.049,
            Mythic = 0.001,
            Huge = 0.0
        }
    },
    
    ["Mythic Egg"] = {
        Price = 50000,
        Currency = "Coins", 
        HatchTime = 60 * 60, -- 1 hour
        AvailableIn = {"Dragon's Peak"},
        PossibleElements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
        RarityWeights = {
            Common = 0.05,
            Uncommon = 0.1,
            Rare = 0.3,
            Epic = 0.4,
            Legendary = 0.139,
            Mythic = 0.01,
            Huge = 0.001
        }
    },
    
    ["Event Egg"] = {
        Price = 100,
        Currency = "Essence",
        HatchTime = 10 * 60, -- 10 minutes
        AvailableIn = {"Special"},
        PossibleElements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
        RarityWeights = {
            Common = 0.0,
            Uncommon = 0.0,
            Rare = 0.2,
            Epic = 0.5,
            Legendary = 0.25,
            Mythic = 0.049,
            Huge = 0.001
        }
    }
}

--------------------------------------------------------------------------------
-- Hatching System
--------------------------------------------------------------------------------
function EggData.CreateEgg(eggType, playerId)
    local eggTemplate = EggData.EggTypes[eggType]
    if not eggTemplate then
        return nil, "Invalid egg type"
    end
    
    local egg = {
        Type = eggType,
        PlayerId = playerId,
        StartTime = tick(),
        HatchTime = eggTemplate.HatchTime,
        IsHatching = false,
        Position = nil, -- Will be set when placed in incubator
        UniqueId = game:GetService("HttpService"):GenerateGUID(false)
    }
    
    return egg, "Egg created"
end

function EggData.StartHatching(egg)
    if egg.IsHatching then
        return false, "Egg is already hatching"
    end
    
    egg.IsHatching = true
    egg.StartTime = tick()
    return true, "Hatching started"
end

function EggData.GetHatchProgress(egg)
    if not egg.IsHatching then
        return 0
    end
    
    local elapsed = tick() - egg.StartTime
    local progress = math.min(elapsed / egg.HatchTime, 1.0)
    return progress
end

function EggData.IsReadyToHatch(egg)
    return egg.IsHatching and EggData.GetHatchProgress(egg) >= 1.0
end

function EggData.HatchEgg(egg, luckyBonus)
    luckyBonus = luckyBonus or false
    
    if not EggData.IsReadyToHatch(egg) then
        return nil, "Egg is not ready to hatch"
    end
    
    local eggTemplate = EggData.EggTypes[egg.Type]
    
    -- Roll for rarity
    local rarity = EggData.RollRarity(eggTemplate.RarityWeights, luckyBonus)
    
    -- Roll for element
    local element = eggTemplate.PossibleElements[math.random(#eggTemplate.PossibleElements)]
    
    -- Roll for shiny (1% base chance, 2% with lucky)
    local variant = "Normal"
    local shinyChance = luckyBonus and 0.02 or 0.01
    if math.random() <= shinyChance then
        variant = "Shiny"
    end
    
    -- Create the dragon
    local dragon = DragonData.CreateDragon(element, rarity, 1, variant)
    
    return dragon, "Dragon hatched successfully!"
end

function EggData.RollRarity(rarityWeights, luckyBonus)
    local roll = math.random()
    
    -- Lucky bonus shifts probabilities toward higher rarities
    if luckyBonus then
        roll = roll * 0.8 -- Bias toward better outcomes
    end
    
    local cumulative = 0
    for i, rarityData in ipairs(Config.Rarities) do
        local weight = rarityWeights[rarityData.Name] or 0
        cumulative = cumulative + weight
        
        if roll <= cumulative then
            return rarityData.Name
        end
    end
    
    -- Fallback
    return "Common"
end

--------------------------------------------------------------------------------
-- Incubator System
--------------------------------------------------------------------------------
function EggData.CanPlaceInIncubator(egg, incubator)
    if incubator.EggId then
        return false, "Incubator already has an egg"
    end
    
    if egg.Position then
        return false, "Egg is already in an incubator"
    end
    
    return true, "Can place egg"
end

function EggData.PlaceEggInIncubator(egg, incubator)
    local canPlace, reason = EggData.CanPlaceInIncubator(egg, incubator)
    if not canPlace then
        return false, reason
    end
    
    incubator.EggId = egg.UniqueId
    egg.Position = incubator.Position
    
    -- Start hatching automatically
    EggData.StartHatching(egg)
    
    return true, "Egg placed in incubator"
end

function EggData.RemoveEggFromIncubator(egg, incubator)
    if incubator.EggId ~= egg.UniqueId then
        return false, "Egg is not in this incubator"
    end
    
    incubator.EggId = nil
    egg.Position = nil
    
    return true, "Egg removed from incubator"
end

--------------------------------------------------------------------------------
-- Visual Effects Data
--------------------------------------------------------------------------------
EggData.HatchEffects = {
    Common = {
        ParticleColor = Color3.new(0.8, 0.8, 0.8),
        ShakeIntensity = 1,
        SoundEffect = "rbxassetid://1234567890", -- Placeholder
        CameraEffect = false
    },
    
    Uncommon = {
        ParticleColor = Color3.new(0.2, 1, 0.2),
        ShakeIntensity = 2,
        SoundEffect = "rbxassetid://1234567891", 
        CameraEffect = false
    },
    
    Rare = {
        ParticleColor = Color3.new(0.2, 0.5, 1),
        ShakeIntensity = 3,
        SoundEffect = "rbxassetid://1234567892",
        CameraEffect = false
    },
    
    Epic = {
        ParticleColor = Color3.new(0.7, 0.2, 1), 
        ShakeIntensity = 4,
        SoundEffect = "rbxassetid://1234567893",
        CameraEffect = true
    },
    
    Legendary = {
        ParticleColor = Color3.new(1, 0.8, 0.2),
        ShakeIntensity = 6,
        SoundEffect = "rbxassetid://1234567894",
        CameraEffect = true,
        ScreenShake = true
    },
    
    Mythic = {
        ParticleColor = Color3.new(1, 0.2, 0.2),
        ShakeIntensity = 8,
        SoundEffect = "rbxassetid://1234567895", 
        CameraEffect = true,
        ScreenShake = true,
        Confetti = true
    },
    
    Huge = {
        ParticleColor = Color3.new(1, 1, 1),
        ShakeIntensity = 10,
        SoundEffect = "rbxassetid://1234567896",
        CameraEffect = true,
        ScreenShake = true,
        Confetti = true,
        ServerAnnouncement = true
    }
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
function EggData.GetEggDisplayInfo(egg)
    local template = EggData.EggTypes[egg.Type]
    local progress = EggData.GetHatchProgress(egg)
    local timeRemaining = math.max(0, egg.HatchTime - (tick() - egg.StartTime))
    
    return {
        Type = egg.Type,
        Progress = progress,
        TimeRemaining = timeRemaining,
        IsReady = EggData.IsReadyToHatch(egg),
        VisualState = progress < 0.25 and "Whole" or
                     progress < 0.5 and "Cracking1" or  
                     progress < 0.75 and "Cracking2" or
                     progress < 1.0 and "AboutToHatch" or "ReadyToHatch"
    }
end

function EggData.GetEggPrice(eggType, currency)
    local template = EggData.EggTypes[eggType]
    if not template then return nil end
    
    if template.Currency == currency then
        return template.Price
    end
    
    return nil
end

function EggData.IsEggAvailableInArea(eggType, areaName)
    local template = EggData.EggTypes[eggType]
    if not template then return false end
    
    for _, availableArea in ipairs(template.AvailableIn) do
        if availableArea == areaName then
            return true
        end
    end
    
    return false
end

return EggData