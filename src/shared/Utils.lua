-- Utils.lua - Utility functions
local Config = require(script.Parent.Config)

local Utils = {}

-- Format large numbers with commas (1000 -> 1,000)
function Utils.FormatNumber(number)
    if type(number) ~= "number" then
        return tostring(number)
    end
    
    local formatted = tostring(math.floor(number))
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end
    
    return formatted
end

-- Format time in seconds to readable string (120 -> "2m 0s")
function Utils.FormatTime(seconds)
    if type(seconds) ~= "number" then
        return "0s"
    end
    
    seconds = math.floor(seconds)
    
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        if remainingSeconds > 0 then
            return string.format("%dm %ds", minutes, remainingSeconds)
        else
            return string.format("%dm", minutes)
        end
    else
        local hours = math.floor(seconds / 3600)
        local remainingMinutes = math.floor((seconds % 3600) / 60)
        local remainingSeconds = seconds % 60
        
        local result = string.format("%dh", hours)
        if remainingMinutes > 0 then
            result = result .. string.format(" %dm", remainingMinutes)
        end
        if remainingSeconds > 0 then
            result = result .. string.format(" %ds", remainingSeconds)
        end
        
        return result
    end
end

-- Get dictionary length (since # doesn't work on dictionaries)
function Utils.DictLen(dict)
    local count = 0
    for _ in pairs(dict) do
        count = count + 1
    end
    return count
end

-- Deep copy a table
function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Get growth stage from level
function Utils.GetGrowthStage(level)
    if level < 5 then
        return "Baby"
    elseif level < 15 then
        return "Juvenile"
    elseif level < 25 then
        return "Teen"
    elseif level < 35 then
        return "Adult"
    elseif level < 45 then
        return "Elder"
    else
        return "Legendary"
    end
end

-- Calculate dragon stats based on base stats and level
function Utils.CalculateStats(baseStats, level)
    local multiplier = 1 + (level * 0.1) -- 10% increase per level
    
    return {
        Strength = math.floor(baseStats.Strength * multiplier),
        Speed = math.floor(baseStats.Speed * multiplier),
        Magic = math.floor(baseStats.Magic * multiplier)
    }
end

-- Linear interpolation for smooth animations
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp a value between min and max
function Utils.Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

-- Generate a unique ID string
function Utils.GenerateId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    
    for i = 1, 8 do
        local index = math.random(1, #chars)
        id = id .. string.sub(chars, index, index)
    end
    
    return id
end

-- Get current timestamp
function Utils.GetTimestamp()
    return os.time()
end

-- Check if enough time has passed since a timestamp
function Utils.HasTimePassed(timestamp, seconds)
    return (Utils.GetTimestamp() - timestamp) >= seconds
end

-- Calculate XP required for next level
function Utils.GetXPForNextLevel(currentLevel)
    if currentLevel >= Config.Levels.MaxLevel then
        return 0
    end
    
    return Config.Levels.XPRequired[currentLevel + 1] or 0
end

-- Get level from total XP
function Utils.GetLevelFromXP(totalXP)
    for level = 1, Config.Levels.MaxLevel do
        local required = Config.Levels.XPRequired[level] or 0
        if totalXP < required then
            return level - 1
        end
    end
    return Config.Levels.MaxLevel
end

-- Calculate progress to next level (0-1)
function Utils.GetLevelProgress(totalXP, currentLevel)
    if currentLevel >= Config.Levels.MaxLevel then
        return 1
    end
    
    local currentLevelXP = Config.Levels.XPRequired[currentLevel] or 0
    local nextLevelXP = Config.Levels.XPRequired[currentLevel + 1] or 0
    
    if nextLevelXP <= currentLevelXP then
        return 1
    end
    
    local progress = (totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
    return Utils.Clamp(progress, 0, 1)
end

-- Shuffle array randomly
function Utils.ShuffleArray(array)
    local shuffled = Utils.DeepCopy(array)
    
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    return shuffled
end

-- Convert CFrame to readable string
function Utils.CFrameToString(cf)
    local pos = cf.Position
    return string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
end

-- Check if player is within range of a position
function Utils.IsPlayerInRange(player, position, range)
    if not player.Character or not player.Character.PrimaryPart then
        return false
    end
    
    local distance = (player.Character.PrimaryPart.Position - position).Magnitude
    return distance <= range
end

return Utils