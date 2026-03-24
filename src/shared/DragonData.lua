--[[
    DragonData.lua
    Dragon species definitions and stat calculations for V3
]]

local Config = require(script.Parent.Config)
local DragonData = {}

--------------------------------------------------------------------------------
-- Base Dragon Templates
--------------------------------------------------------------------------------
DragonData.BaseStats = {
    Fire = {Power = 100, Speed = 80, Luck = 60},
    Ice = {Power = 80, Speed = 90, Luck = 80},
    Nature = {Power = 70, Speed = 70, Luck = 110},
    Shadow = {Power = 120, Speed = 100, Luck = 40},
    Light = {Power = 90, Speed = 85, Luck = 85},
    Storm = {Power = 110, Speed = 110, Luck = 50}
}

DragonData.FusionStats = {
    Steam = {Power = 90, Speed = 85, Luck = 70}, -- Fire + Ice
    Magma = {Power = 130, Speed = 60, Luck = 70}, -- Fire + Nature
    Plasma = {Power = 140, Speed = 95, Luck = 45}, -- Fire + Storm
    FrostBloom = {Power = 60, Speed = 80, Luck = 120}, -- Ice + Nature
    VoidIce = {Power = 100, Speed = 95, Luck = 60}, -- Ice + Shadow
    Solar = {Power = 110, Speed = 70, Luck = 100}, -- Nature + Light
    Eclipse = {Power = 105, Speed = 92, Luck = 62}, -- Shadow + Light
    ThunderDark = {Power = 115, Speed = 105, Luck = 45}, -- Shadow + Storm
    Prism = {Power = 100, Speed = 97, Luck = 67}, -- Storm + Light
    Tempest = {Power = 90, Speed = 90, Luck = 80} -- Nature + Storm
}

--------------------------------------------------------------------------------
-- Dragon Creation and Stats
--------------------------------------------------------------------------------
function DragonData.CreateDragon(element, rarity, stage, variant)
    variant = variant or "Normal"
    stage = stage or 1
    
    local dragon = {
        Element = element,
        Rarity = rarity or "Common",
        Stage = stage,
        Variant = variant, -- Normal, Shiny, Golden, Rainbow
        Level = 1,
        XP = 0,
        FeedCount = 0,
        IsBreeding = false,
        OnExpedition = false,
        
        -- Generated stats
        Power = 0,
        Speed = 0, 
        Luck = 0,
        
        -- Timestamps
        HatchTime = tick(),
        LastFed = 0,
        
        -- Visual
        Size = 3, -- Starting baby size
        UniqueId = game:GetService("HttpService"):GenerateGUID(false)
    }
    
    -- Calculate base stats
    local baseStats = DragonData.BaseStats[element] or DragonData.FusionStats[element]
    if not baseStats then
        baseStats = DragonData.BaseStats.Fire -- Fallback
    end
    
    -- Apply rarity bonus
    local rarityData = Config.Rarities[rarity] or Config.Rarities[1]
    local rarityMultiplier = rarityData.StatBonus or 1.0
    
    -- Apply stage bonus  
    local stageData = Config.GrowthStages[stage] or Config.GrowthStages[1]
    local stageMultiplier = stageData.StatMultiplier or 1.0
    
    -- Apply variant bonus
    local variantMultiplier = 1.0
    if variant == "Shiny" then
        variantMultiplier = 2.0
    elseif variant == "Golden" then 
        variantMultiplier = 3.0
    elseif variant == "Rainbow" then
        variantMultiplier = 5.0
    end
    
    -- Calculate final stats
    local totalMultiplier = rarityMultiplier * stageMultiplier * variantMultiplier
    dragon.Power = math.floor(baseStats.Power * totalMultiplier)
    dragon.Speed = math.floor(baseStats.Speed * totalMultiplier)
    dragon.Luck = math.floor(baseStats.Luck * totalMultiplier)
    
    -- Set size based on stage
    dragon.Size = 3 * (stageData.SizeMultiplier or 1.0)
    
    return dragon
end

--------------------------------------------------------------------------------
-- Growth System
--------------------------------------------------------------------------------
function DragonData.CanGrowToNextStage(dragon)
    if dragon.Stage >= #Config.GrowthStages then
        return false -- Already at max stage
    end
    
    local nextStageData = Config.GrowthStages[dragon.Stage + 1]
    local timeSinceHatch = tick() - dragon.HatchTime
    
    return dragon.FeedCount >= nextStageData.FeedsRequired and 
           timeSinceHatch >= nextStageData.TimeRequired
end

function DragonData.GrowDragon(dragon)
    if not DragonData.CanGrowToNextStage(dragon) then
        return false
    end
    
    dragon.Stage = dragon.Stage + 1
    
    -- Recalculate stats for new stage
    local updatedDragon = DragonData.CreateDragon(
        dragon.Element, 
        dragon.Rarity, 
        dragon.Stage, 
        dragon.Variant
    )
    
    -- Preserve unique data
    updatedDragon.UniqueId = dragon.UniqueId
    updatedDragon.HatchTime = dragon.HatchTime
    updatedDragon.FeedCount = dragon.FeedCount
    updatedDragon.LastFed = dragon.LastFed
    updatedDragon.Level = dragon.Level
    updatedDragon.XP = dragon.XP
    
    return updatedDragon
end

--------------------------------------------------------------------------------
-- Feeding System  
--------------------------------------------------------------------------------
function DragonData.FeedDragon(dragon, foodType)
    foodType = foodType or "Basic"
    
    local now = tick()
    if now - dragon.LastFed < 5 then -- 5 second cooldown
        return false, "Too soon to feed again"
    end
    
    dragon.LastFed = now
    dragon.FeedCount = dragon.FeedCount + 1
    
    -- Award XP based on food type
    local xpGain = 10
    if foodType == "Rare" then xpGain = 25
    elseif foodType == "Epic" then xpGain = 50
    elseif foodType == "Legendary" then xpGain = 100 end
    
    dragon.XP = dragon.XP + xpGain
    
    -- Level up check (every 100 XP)
    if dragon.XP >= dragon.Level * 100 then
        dragon.Level = dragon.Level + 1
        dragon.XP = 0
        return true, "Dragon leveled up!"
    end
    
    return true, "Dragon fed successfully"
end

--------------------------------------------------------------------------------
-- Breeding System
--------------------------------------------------------------------------------
function DragonData.CanBreed(dragon1, dragon2)
    -- Must be adult+ stage
    if dragon1.Stage < 4 or dragon2.Stage < 4 then
        return false, "Dragons must be Adult or higher to breed"
    end
    
    -- Cannot breed with self
    if dragon1.UniqueId == dragon2.UniqueId then
        return false, "Cannot breed dragon with itself"
    end
    
    -- Check if already breeding
    if dragon1.IsBreeding or dragon2.IsBreeding then
        return false, "One or both dragons are already breeding"
    end
    
    return true, "Ready to breed"
end

function DragonData.BreedDragons(dragon1, dragon2)
    local canBreed, reason = DragonData.CanBreed(dragon1, dragon2)
    if not canBreed then
        return nil, reason
    end
    
    -- Determine result element
    local element1, element2 = dragon1.Element, dragon2.Element
    local resultElement = element1 -- Default to parent 1
    
    -- Check for fusion possibilities
    for fusionName, parents in pairs(Config.FusionElements) do
        if (parents[1] == element1 and parents[2] == element2) or 
           (parents[1] == element2 and parents[2] == element1) then
            resultElement = fusionName
            break
        end
    end
    
    -- Determine rarity (small chance to upgrade)
    local parentRarities = {dragon1.Rarity, dragon2.Rarity}
    local bestRarity = 1
    for _, rarity in ipairs(parentRarities) do
        for i, rarityData in ipairs(Config.Rarities) do
            if rarityData.Name == rarity then
                bestRarity = math.max(bestRarity, i)
            end
        end
    end
    
    -- 10% chance to upgrade rarity
    if math.random() < 0.1 and bestRarity < #Config.Rarities then
        bestRarity = bestRarity + 1
    end
    
    local resultRarity = Config.Rarities[bestRarity].Name
    
    -- Create baby dragon
    local babyDragon = DragonData.CreateDragon(resultElement, resultRarity, 1, "Normal")
    
    -- Set breeding status
    dragon1.IsBreeding = true
    dragon2.IsBreeding = true
    
    return babyDragon, "Breeding successful!"
end

--------------------------------------------------------------------------------
-- Variant System
--------------------------------------------------------------------------------
function DragonData.RollForShiny()
    return math.random() <= 0.01 -- 1% chance
end

function DragonData.CreateGoldenVariant(dragon)
    if dragon.Variant == "Normal" then
        local goldenDragon = DragonData.CreateDragon(
            dragon.Element, dragon.Rarity, dragon.Stage, "Golden"
        )
        goldenDragon.UniqueId = dragon.UniqueId
        goldenDragon.HatchTime = dragon.HatchTime
        goldenDragon.FeedCount = dragon.FeedCount
        goldenDragon.Level = dragon.Level
        goldenDragon.XP = dragon.XP
        return goldenDragon
    end
    return dragon
end

function DragonData.CreateRainbowVariant(shinyDragon1, shinyDragon2)
    if shinyDragon1.Variant == "Shiny" and shinyDragon2.Variant == "Shiny" then
        local rainbow = DragonData.BreedDragons(shinyDragon1, shinyDragon2)
        if rainbow then
            rainbow.Variant = "Rainbow"
            -- Recalculate stats with rainbow bonus
            local recalced = DragonData.CreateDragon(
                rainbow.Element, rainbow.Rarity, rainbow.Stage, "Rainbow"
            )
            recalced.UniqueId = rainbow.UniqueId
            return recalced
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
function DragonData.GetDisplayName(dragon)
    local variantPrefix = ""
    if dragon.Variant ~= "Normal" then
        variantPrefix = dragon.Variant .. " "
    end
    
    local stageName = Config.GrowthStages[dragon.Stage].Name
    
    return string.format("%s%s %s Dragon", variantPrefix, dragon.Element, stageName)
end

function DragonData.GetPowerRating(dragon)
    return dragon.Power + dragon.Speed + dragon.Luck
end

return DragonData