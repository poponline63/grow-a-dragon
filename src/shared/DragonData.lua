-- DragonData.lua - Dragon definitions (36 dragons: 6 elements × 6 rarities)
local Config = require(script.Parent.Config)

local DragonData = {}

-- Base stats that scale with rarity
local BaseStats = {
    Common = {Strength = 10, Speed = 10, Magic = 10},
    Uncommon = {Strength = 15, Speed = 15, Magic = 15},
    Rare = {Strength = 25, Speed = 25, Magic = 25},
    Epic = {Strength = 40, Speed = 40, Magic = 40},
    Legendary = {Strength = 60, Speed = 60, Magic = 60},
    Mythic = {Strength = 100, Speed = 100, Magic = 100}
}

-- Dragon names by element and rarity
local DragonNames = {
    Fire = {
        Common = "Ember Hatchling",
        Uncommon = "Flame Wyrm",
        Rare = "Blaze Dragon",
        Epic = "Inferno Drake",
        Legendary = "Phoenix Lord",
        Mythic = "Solar Emperor"
    },
    Ice = {
        Common = "Frost Pup",
        Uncommon = "Ice Glider",
        Rare = "Crystal Dragon",
        Epic = "Glacier Behemoth",
        Legendary = "Arctic Sovereign",
        Mythic = "Winter's Avatar"
    },
    Nature = {
        Common = "Vine Sprout",
        Uncommon = "Forest Walker",
        Rare = "Grove Guardian",
        Epic = "Ancient Treant",
        Legendary = "World Tree",
        Mythic = "Nature's Heart"
    },
    Shadow = {
        Common = "Shade Wisp",
        Uncommon = "Dark Serpent",
        Rare = "Shadow Stalker",
        Epic = "Void Reaper",
        Legendary = "Eclipse Dragon",
        Mythic = "Nightmare King"
    },
    Light = {
        Common = "Glow Sprite",
        Uncommon = "Radiant Drake",
        Rare = "Celestial Wyrm",
        Epic = "Divine Seraph",
        Legendary = "Archangel",
        Mythic = "Light Incarnate"
    },
    Storm = {
        Common = "Thunder Pip",
        Uncommon = "Lightning Bolt",
        Rare = "Storm Rider",
        Epic = "Tempest Lord",
        Legendary = "Hurricane Master",
        Mythic = "Sky God"
    }
}

-- Dragon descriptions
local DragonDescriptions = {
    Fire = {
        Common = "A small dragon with tiny sparks dancing around its scales.",
        Uncommon = "This fiery dragon's breath can melt ice in seconds.",
        Rare = "Blazing flames surround this majestic creature at all times.",
        Epic = "An infernal beast that leaves scorched earth in its wake.",
        Legendary = "Reborn from ashes, this mythical phoenix commands respect.",
        Mythic = "The embodiment of the sun's power, radiant and unstoppable."
    },
    Ice = {
        Common = "A playful dragon that leaves frost trails wherever it goes.",
        Uncommon = "This icy drake can freeze water with just a touch.",
        Rare = "Crystal formations grow naturally on this dragon's hide.",
        Epic = "A massive ice dragon that brings eternal winter.",
        Legendary = "Ruler of the frozen wastelands, ancient and wise.",
        Mythic = "The very spirit of winter made manifest in dragon form."
    },
    Nature = {
        Common = "A tiny dragon with leaves growing from its back.",
        Uncommon = "This earth dragon nurtures plant life wherever it treads.",
        Rare = "A guardian of the forest with bark-like scales.",
        Epic = "An ancient tree-dragon, older than the oldest oaks.",
        Legendary = "The living embodiment of the world's forests.",
        Mythic = "Nature's chosen avatar, protector of all living things."
    },
    Shadow = {
        Common = "A mysterious dragon that seems to flicker in and out of sight.",
        Uncommon = "This dark serpent moves through shadows like water.",
        Rare = "A shadowy predator that hunts from the darkness.",
        Epic = "A reaper of souls wrapped in living darkness.",
        Legendary = "Master of shadows and eclipses, feared by all.",
        Mythic = "The king of nightmares, darkness given form and purpose."
    },
    Light = {
        Common = "A bright little dragon that glows softly in the dark.",
        Uncommon = "This radiant dragon brings hope wherever it flies.",
        Rare = "A celestial wyrm blessed by the stars themselves.",
        Epic = "An angelic dragon with six shimmering wings.",
        Legendary = "A divine messenger with power over light itself.",
        Mythic = "Pure light incarnate, the opposite of all darkness."
    },
    Storm = {
        Common = "A hyperactive dragon that crackles with tiny lightning bolts.",
        Uncommon = "This electric dragon can generate small thunderstorms.",
        Rare = "A storm-riding dragon that dances with lightning.",
        Epic = "Master of tempests, this dragon commands wind and rain.",
        Legendary = "Ancient lord of hurricanes and tornadoes.",
        Mythic = "The sky god incarnate, wielding the power of infinite storms."
    }
}

-- Build the complete dragon data structure
DragonData.Dragons = {}

for _, element in pairs(Config.Dragons.Elements) do
    DragonData.Dragons[element] = {}
    
    for _, rarity in pairs(Config.Dragons.Rarities) do
        DragonData.Dragons[element][rarity] = {
            Name = DragonNames[element][rarity],
            Element = element,
            Rarity = rarity,
            Description = DragonDescriptions[element][rarity],
            BaseStats = BaseStats[rarity],
            Color = Config.UI.ElementColors[element],
            RarityColor = Config.UI.RarityColors[rarity]
        }
    end
end

-- Helper function to get a dragon by element and rarity
function DragonData:GetDragon(element, rarity)
    if self.Dragons[element] and self.Dragons[element][rarity] then
        return self.Dragons[element][rarity]
    end
    return nil
end

-- Helper function to get all dragons of a specific element
function DragonData:GetDragonsByElement(element)
    return self.Dragons[element] or {}
end

-- Helper function to get all dragons of a specific rarity
function DragonData:GetDragonsByRarity(rarity)
    local dragons = {}
    for element, elementDragons in pairs(self.Dragons) do
        if elementDragons[rarity] then
            table.insert(dragons, elementDragons[rarity])
        end
    end
    return dragons
end

-- Helper function to get a random dragon based on rarity weights
function DragonData:GetRandomDragon(rarityWeights)
    -- Default weights if not provided
    rarityWeights = rarityWeights or {
        Common = 50,
        Uncommon = 25,
        Rare = 15,
        Epic = 7,
        Legendary = 2.5,
        Mythic = 0.5
    }
    
    -- Calculate total weight
    local totalWeight = 0
    for _, weight in pairs(rarityWeights) do
        totalWeight = totalWeight + weight
    end
    
    -- Roll for rarity
    local roll = math.random() * totalWeight
    local currentWeight = 0
    local selectedRarity = "Common"
    
    for rarity, weight in pairs(rarityWeights) do
        currentWeight = currentWeight + weight
        if roll <= currentWeight then
            selectedRarity = rarity
            break
        end
    end
    
    -- Pick random element
    local elements = Config.Dragons.Elements
    local selectedElement = elements[math.random(#elements)]
    
    return self:GetDragon(selectedElement, selectedRarity)
end

return DragonData