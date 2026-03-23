-- Config.lua - All game constants
local Config = {}

-- General Game Settings
Config.Game = {
    AutoSaveInterval = 60,           -- Auto save every 60 seconds
    MaxEggsPerPlot = 4,              -- Max eggs on a player plot
    PlotRadius = 250,                -- Radius for player plots
    PlotSize = 80,                   -- 80x80 plot size
    SpawnPosition = Vector3.new(0, 5, 0),
    PlotCount = 20                   -- Number of player plots
}

-- Currency
Config.Currency = {
    StartingCoins = 100,             -- Starting coins for new players
    StartingGems = 10,               -- Starting gems for new players
    ClickReward = 5,                 -- Coins per click
    DailyRewardCoins = {50, 75, 100, 150, 200, 300, 500}, -- Daily rewards (increasing)
    DailyRewardGems = {1, 2, 3, 5, 8, 12, 20}             -- Daily gem rewards
}

-- Egg System
Config.Eggs = {
    Tiers = {
        Common = { Price = 100, HatchTime = 300, Color = Color3.new(0.7, 0.7, 0.7) },
        Uncommon = { Price = 250, HatchTime = 600, Color = Color3.new(0.2, 0.8, 0.2) },
        Rare = { Price = 500, HatchTime = 900, Color = Color3.new(0.2, 0.5, 1) },
        Epic = { Price = 1000, HatchTime = 1800, Color = Color3.new(0.6, 0.2, 1) },
        Legendary = { Price = 2500, HatchTime = 3600, Color = Color3.new(1, 0.8, 0) },
        Mythic = { Price = 5000, HatchTime = 7200, Color = Color3.new(1, 0.2, 0.2) }
    },
    GemSpeedUpCost = 5               -- Gems to instantly hatch an egg
}

-- Dragon System
Config.Dragons = {
    Elements = {"Fire", "Ice", "Nature", "Shadow", "Light", "Storm"},
    Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"},
    GrowthStages = {"Baby", "Juvenile", "Teen", "Adult", "Elder", "Legendary"},
    XPRequired = {100, 300, 600, 1200, 2400, 5000}, -- XP needed for each growth stage
    FeedingXP = 25,                  -- XP gained from feeding
    FeedingCost = 50,                -- Cost to feed a dragon
    MaxLevel = 50                    -- Max dragon level
}

-- Level System  
Config.Levels = {
    XPRequired = {}, -- Will be calculated
    MaxLevel = 100,
    XPMultiplier = 1.2 -- Each level requires 20% more XP
}

-- Calculate XP requirements dynamically
local baseXP = 1000
for i = 1, Config.Levels.MaxLevel do
    Config.Levels.XPRequired[i] = math.floor(baseXP * (Config.Levels.XPMultiplier ^ (i - 1)))
end

-- Quest System
Config.Quests = {
    Daily = {
        {Type = "HatchEggs", Amount = 1, Reward = {Coins = 100}},
        {Type = "EarnCoins", Amount = 500, Reward = {Coins = 150}},
        {Type = "FeedDragons", Amount = 3, Reward = {Coins = 75, Gems = 1}},
        {Type = "ClickCollect", Amount = 50, Reward = {Coins = 125}}
    },
    Weekly = {
        {Type = "HatchRare", Amount = 1, Reward = {Coins = 1000, Gems = 5}},
        {Type = "ReachLevel", Amount = 5, Reward = {Coins = 2000, Gems = 10}},
        {Type = "CollectDragons", Amount = 10, Reward = {Coins = 1500, Gems = 7}}
    }
}

-- UI Colors
Config.UI = {
    RarityColors = {
        Common = Color3.new(0.7, 0.7, 0.7),      -- Gray
        Uncommon = Color3.new(0.2, 0.8, 0.2),    -- Green
        Rare = Color3.new(0.2, 0.5, 1),          -- Blue
        Epic = Color3.new(0.6, 0.2, 1),          -- Purple
        Legendary = Color3.new(1, 0.8, 0),       -- Gold
        Mythic = Color3.new(1, 0.2, 0.2)         -- Red
    },
    ElementColors = {
        Fire = Color3.new(1, 0.4, 0.1),
        Ice = Color3.new(0.5, 0.8, 1),
        Nature = Color3.new(0.2, 0.8, 0.3),
        Shadow = Color3.new(0.3, 0.2, 0.5),
        Light = Color3.new(1, 1, 0.7),
        Storm = Color3.new(0.6, 0.4, 1)
    },
    MainTheme = {
        Primary = Color3.new(0.2, 0.6, 1),
        Secondary = Color3.new(0.8, 0.4, 1),
        Background = Color3.new(0.1, 0.1, 0.2),
        Text = Color3.new(1, 1, 1)
    }
}

-- Sound Effects (Roblox asset IDs)
Config.Sounds = {
    ButtonClick = "rbxasset://sounds/button_click.mp3",
    EggHatch = "rbxasset://sounds/victory.mp3",
    DragonFeed = "rbxasset://sounds/powerup.mp3",
    Coins = "rbxasset://sounds/coin.mp3",
    QuestComplete = "rbxasset://sounds/chime.mp3",
    Error = "rbxasset://sounds/error.mp3"
}

return Config