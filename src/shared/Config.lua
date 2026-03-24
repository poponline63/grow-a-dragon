--[[
    Config.lua
    Game configuration and constants for Grow a Dragon V3
]]

local Config = {}

--------------------------------------------------------------------------------
-- World Areas
--------------------------------------------------------------------------------
Config.Areas = {
    {
        Name = "Spawn Hub",
        UnlockCost = 0,
        Description = "The central hub where your journey begins",
        AvailableEggs = {},
        Position = {0, 0, 0}
    },
    {
        Name = "Enchanted Meadow", 
        UnlockCost = 10000,
        Description = "A peaceful meadow with Fire and Nature dragons",
        AvailableEggs = {"Common", "Uncommon", "Rare"},
        Elements = {"Fire", "Nature"},
        Position = {200, 0, 0}
    },
    {
        Name = "Crystal Caverns",
        UnlockCost = 100000,
        Description = "Glowing caverns home to Ice and Storm dragons",
        AvailableEggs = {"Uncommon", "Rare", "Epic"},
        Elements = {"Ice", "Storm"},
        Position = {0, 0, 200}
    },
    {
        Name = "Shadow Realm",
        UnlockCost = 500000,
        Description = "Dark floating islands with Shadow and Light dragons",
        AvailableEggs = {"Rare", "Epic"},
        Elements = {"Shadow", "Light"},
        Position = {-200, 50, 0}
    },
    {
        Name = "Sky Temple",
        UnlockCost = 2000000,
        Description = "Heavenly clouds where all elements converge",
        AvailableEggs = {"Epic", "Legendary"},
        Elements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
        Position = {0, 200, 0}
    },
    {
        Name = "Dragon's Peak",
        UnlockCost = 10000000,
        Description = "The ultimate dragon sanctuary",
        AvailableEggs = {"Legendary", "Mythic"},
        Elements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
        Position = {0, 400, 0}
    }
}

--------------------------------------------------------------------------------
-- Dragon Growth Stages
--------------------------------------------------------------------------------
Config.GrowthStages = {
    {
        Name = "Baby",
        SizeMultiplier = 1.0,
        TimeRequired = 0,
        FeedsRequired = 0,
        StatMultiplier = 1.0
    },
    {
        Name = "Juvenile", 
        SizeMultiplier = 1.5,
        TimeRequired = 10 * 60, -- 10 minutes
        FeedsRequired = 5,
        StatMultiplier = 1.5
    },
    {
        Name = "Teen",
        SizeMultiplier = 2.0,
        TimeRequired = 30 * 60, -- 30 minutes  
        FeedsRequired = 15,
        StatMultiplier = 2.0
    },
    {
        Name = "Adult",
        SizeMultiplier = 3.0,
        TimeRequired = 2 * 60 * 60, -- 2 hours
        FeedsRequired = 40,
        StatMultiplier = 3.0
    },
    {
        Name = "Elder",
        SizeMultiplier = 4.0,
        TimeRequired = 8 * 60 * 60, -- 8 hours
        FeedsRequired = 100,
        StatMultiplier = 4.0
    },
    {
        Name = "Legendary",
        SizeMultiplier = 5.0,
        TimeRequired = 24 * 60 * 60, -- 24 hours
        FeedsRequired = 250,
        StatMultiplier = 5.0
    }
}

--------------------------------------------------------------------------------
-- Rarity System
--------------------------------------------------------------------------------
Config.Rarities = {
    {Name = "Common", Color = Color3.new(0.5, 0.5, 0.5), StatBonus = 1.0, HatchChance = 0.5},
    {Name = "Uncommon", Color = Color3.new(0.2, 1, 0.2), StatBonus = 1.2, HatchChance = 0.25},
    {Name = "Rare", Color = Color3.new(0.2, 0.5, 1), StatBonus = 1.5, HatchChance = 0.15},
    {Name = "Epic", Color = Color3.new(0.7, 0.2, 1), StatBonus = 2.0, HatchChance = 0.08},
    {Name = "Legendary", Color = Color3.new(1, 0.8, 0.2), StatBonus = 3.0, HatchChance = 0.015},
    {Name = "Mythic", Color = Color3.new(1, 0.2, 0.2), StatBonus = 5.0, HatchChance = 0.004},
    {Name = "Huge", Color = Color3.new(1, 1, 1), StatBonus = 10.0, HatchChance = 0.0001}
}

--------------------------------------------------------------------------------
-- Element System  
--------------------------------------------------------------------------------
Config.BaseElements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"}

Config.FusionElements = {
    Steam = {"Fire", "Ice"},
    Magma = {"Fire", "Nature"},
    Plasma = {"Fire", "Storm"},
    FrostBloom = {"Ice", "Nature"},
    VoidIce = {"Ice", "Shadow"},
    Solar = {"Nature", "Light"},
    Eclipse = {"Shadow", "Light"},
    ThunderDark = {"Shadow", "Storm"},
    Prism = {"Storm", "Light"},
    Tempest = {"Nature", "Storm"}
}

Config.ElementColors = {
    Fire = Color3.new(1, 0.3, 0.1),
    Ice = Color3.new(0.4, 0.8, 1),
    Nature = Color3.new(0.2, 0.8, 0.2),
    Shadow = Color3.new(0.2, 0.1, 0.4),
    Light = Color3.new(1, 1, 0.8),
    Storm = Color3.new(0.7, 0.7, 1),
    Steam = Color3.new(0.8, 0.8, 0.9),
    Magma = Color3.new(1, 0.5, 0.1),
    Plasma = Color3.new(1, 0.2, 1),
    FrostBloom = Color3.new(0.8, 1, 0.9),
    VoidIce = Color3.new(0.1, 0.1, 0.3),
    Solar = Color3.new(1, 1, 0.4),
    Eclipse = Color3.new(0.4, 0.4, 0.6),
    ThunderDark = Color3.new(0.3, 0.2, 0.5),
    Prism = Color3.new(0.9, 0.9, 1),
    Tempest = Color3.new(0.5, 0.7, 0.4)
}

--------------------------------------------------------------------------------
-- Economy
--------------------------------------------------------------------------------
Config.Economy = {
    StartingCoins = 1000,
    StartingEssence = 10,
    
    -- Egg Prices
    EggPrices = {
        ["Stone Egg"] = {Coins = 100, Essence = 0, Area = "Enchanted Meadow"},
        ["Crystal Egg"] = {Coins = 500, Essence = 0, Area = "Crystal Caverns"}, 
        ["Shadow Egg"] = {Coins = 2500, Essence = 0, Area = "Shadow Realm"},
        ["Golden Egg"] = {Coins = 10000, Essence = 0, Area = "Sky Temple"},
        ["Mythic Egg"] = {Coins = 50000, Essence = 0, Area = "Dragon's Peak"},
        ["Event Egg"] = {Coins = 0, Essence = 100, Area = "Special"}
    },
    
    -- Upgrade Costs
    UpgradeCosts = {
        Incubator = {1000, 5000, 15000, 35000, 75000}, -- 1 to 6 total
        DragonPen = {2000, 10000, 50000}, -- 3 upgrades
        AutoFeeder = {25000},
        BreedingAltar = {100000}
    }
}

--------------------------------------------------------------------------------
-- Expedition System
--------------------------------------------------------------------------------
Config.Expeditions = {
    {
        Name = "Quick Scout",
        Duration = 15 * 60, -- 15 minutes
        MinLevel = 3, -- Adult+
        Rewards = {
            Coins = {50, 150},
            Essence = {1, 3},
            Items = {"Dragon Food"}
        }
    },
    {
        Name = "Treasure Hunt", 
        Duration = 60 * 60, -- 1 hour
        MinLevel = 3,
        Rewards = {
            Coins = {200, 500},
            Essence = {5, 10},
            Items = {"Dragon Food", "Egg Fragment"}
        }
    },
    {
        Name = "Ancient Ruins",
        Duration = 4 * 60 * 60, -- 4 hours
        MinLevel = 4, -- Elder+
        Rewards = {
            Coins = {1000, 2500},
            Essence = {20, 50},
            Items = {"Rare Food", "Enchant Stone"}
        }
    },
    {
        Name = "Dragon's Quest",
        Duration = 8 * 60 * 60, -- 8 hours
        MinLevel = 5, -- Legendary+
        Rewards = {
            Coins = {5000, 10000}, 
            Essence = {100, 200},
            Items = {"Epic Food", "Golden Scale"}
        }
    }
}

--------------------------------------------------------------------------------
-- Daily Systems
--------------------------------------------------------------------------------
Config.DailyRewards = {
    {Coins = 500, Essence = 0, Items = {}},
    {Coins = 1000, Essence = 0, Items = {}},
    {Coins = 0, Essence = 0, Items = {"Rare Egg"}},
    {Coins = 2500, Essence = 0, Items = {}},
    {Coins = 0, Essence = 50, Items = {}},
    {Coins = 0, Essence = 0, Items = {"Epic Egg"}},
    {Coins = 0, Essence = 100, Items = {"Legendary Egg"}}
}

Config.DailyQuests = {
    "Hatch {amount} eggs",
    "Feed dragons {amount} times",
    "Earn {amount} coins",
    "Send dragons on {amount} expeditions",
    "Upgrade a building",
    "Breed a dragon"
}

--------------------------------------------------------------------------------
-- UI Constants
--------------------------------------------------------------------------------
Config.UI = {
    BottomBarHeight = 80,
    SideHUDWidth = 200, 
    CardSize = {150, 200},
    TouchTargetSize = 60,
    AnimationSpeed = 0.5,
    Colors = {
        Primary = Color3.new(0.2, 0.3, 0.8),
        Secondary = Color3.new(0.8, 0.6, 0.2),
        Success = Color3.new(0.2, 0.8, 0.2),
        Warning = Color3.new(1, 0.7, 0.2),
        Error = Color3.new(0.8, 0.2, 0.2)
    }
}

return Config