-- EggData.lua - Egg definitions with rarity weight tables
local Config = require(script.Parent.Config)

local EggData = {}

-- Egg tier definitions with rarity weight tables
EggData.Tiers = {
    Common = {
        Name = "Stone Egg",
        Price = 100,
        HatchTime = 300, -- 5 minutes
        Color = Color3.new(0.7, 0.7, 0.7),
        Description = "A rough stone egg. What could be inside?",
        RarityWeights = {
            Common = 70,
            Uncommon = 25,
            Rare = 5,
            Epic = 0,
            Legendary = 0,
            Mythic = 0
        }
    },
    
    Uncommon = {
        Name = "Clay Egg",
        Price = 250,
        HatchTime = 600, -- 10 minutes
        Color = Color3.new(0.8, 0.6, 0.4),
        Description = "A smooth clay egg with mysterious markings.",
        RarityWeights = {
            Common = 40,
            Uncommon = 45,
            Rare = 13,
            Epic = 2,
            Legendary = 0,
            Mythic = 0
        }
    },
    
    Rare = {
        Name = "Crystal Egg",
        Price = 500,
        HatchTime = 900, -- 15 minutes
        Color = Color3.new(0.4, 0.8, 1),
        Description = "A beautiful crystal egg that shimmers with inner light.",
        RarityWeights = {
            Common = 20,
            Uncommon = 35,
            Rare = 35,
            Epic = 9,
            Legendary = 1,
            Mythic = 0
        }
    },
    
    Epic = {
        Name = "Enchanted Egg",
        Price = 1000,
        HatchTime = 1800, -- 30 minutes
        Color = Color3.new(0.6, 0.2, 1),
        Description = "An egg pulsing with magical energy and ancient runes.",
        RarityWeights = {
            Common = 10,
            Uncommon = 20,
            Rare = 40,
            Epic = 25,
            Legendary = 4.5,
            Mythic = 0.5
        }
    },
    
    Legendary = {
        Name = "Golden Egg",
        Price = 2500,
        HatchTime = 3600, -- 1 hour
        Color = Color3.new(1, 0.8, 0),
        Description = "A magnificent golden egg that radiates power.",
        RarityWeights = {
            Common = 5,
            Uncommon = 10,
            Rare = 25,
            Epic = 40,
            Legendary = 18,
            Mythic = 2
        }
    },
    
    Mythic = {
        Name = "Celestial Egg",
        Price = 5000,
        HatchTime = 7200, -- 2 hours
        Color = Color3.new(1, 0.2, 0.2),
        Description = "A legendary egg said to contain the essence of gods.",
        RarityWeights = {
            Common = 0,
            Uncommon = 5,
            Rare = 15,
            Epic = 30,
            Legendary = 40,
            Mythic = 10
        }
    }
}

-- Helper function to get egg tier by name
function EggData:GetTier(tierName)
    return self.Tiers[tierName]
end

-- Helper function to get all available tiers
function EggData:GetAllTiers()
    local tiers = {}
    for tierName, tierData in pairs(self.Tiers) do
        tierData.TierName = tierName
        table.insert(tiers, tierData)
    end
    
    -- Sort by price
    table.sort(tiers, function(a, b)
        return a.Price < b.Price
    end)
    
    return tiers
end

-- Helper function to calculate rarity odds text for UI
function EggData:GetRarityOddsText(tierName)
    local tier = self:GetTier(tierName)
    if not tier then return "Unknown odds" end
    
    local weights = tier.RarityWeights
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local odds = {}
    for rarity, weight in pairs(weights) do
        if weight > 0 then
            local percentage = (weight / totalWeight) * 100
            if percentage >= 1 then
                table.insert(odds, string.format("%s: %.0f%%", rarity, percentage))
            else
                table.insert(odds, string.format("%s: %.1f%%", rarity, percentage))
            end
        end
    end
    
    return table.concat(odds, "\n")
end

-- Helper function to roll for dragon rarity based on egg tier
function EggData:RollRarity(tierName)
    local tier = self:GetTier(tierName)
    if not tier then return "Common" end
    
    local weights = tier.RarityWeights
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for rarity, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if roll <= currentWeight then
            return rarity
        end
    end
    
    return "Common" -- Fallback
end

-- Helper function to format hatch time for display
function EggData:FormatHatchTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm", math.floor(seconds / 60))
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        if minutes > 0 then
            return string.format("%dh %dm", hours, minutes)
        else
            return string.format("%dh", hours)
        end
    end
end

return EggData