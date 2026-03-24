--[[
    CodesSystem.server.lua
    Redeem codes for free rewards - Grow a Dragon V3
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Wait for shared modules
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)
local DataStore = require(script.Parent.DataStore)

-- Create RemoteEvents
local CodesFolder = Instance.new("Folder")
CodesFolder.Name = "Codes"
CodesFolder.Parent = ReplicatedStorage:WaitForChild("RemoteEvents")

local RedeemCodeRemote = Instance.new("RemoteFunction")
RedeemCodeRemote.Name = "RedeemCode"
RedeemCodeRemote.Parent = CodesFolder

-- Code redemption DataStore  
local CodesDataStore = DataStoreService:GetDataStore("v3_CodesRedemption")

local CodesSystem = {}

-- Define available codes with rewards and optional expiry
CodesSystem.AvailableCodes = {
    ["RELEASE"] = {
        Rewards = {
            Coins = 1000
        },
        Description = "Release celebration reward!",
        ExpiryTime = nil, -- Never expires
        OneTimeUse = true
    },
    ["DRAGON"] = {
        Rewards = {
            Coins = 500,
            Essence = 25
        },
        Description = "Dragon essence boost!",
        ExpiryTime = nil,
        OneTimeUse = true
    },
    ["LUCKY"] = {
        Rewards = {
            Items = {
                {Type = "LuckyEgg", Amount = 1}
            }
        },
        Description = "Lucky egg for better hatches!",
        ExpiryTime = nil,
        OneTimeUse = true
    },
    ["FIRE"] = {
        Rewards = {
            Items = {
                {Type = "FireEgg", Amount = 1}
            }
        },
        Description = "Free Fire element egg!",
        ExpiryTime = nil,
        OneTimeUse = true
    },
    ["WELCOME"] = {
        Rewards = {
            Coins = 2000
        },
        Description = "Welcome to Grow a Dragon!",
        ExpiryTime = nil,
        OneTimeUse = true
    }
}

-- Check if code is valid and not expired
function CodesSystem.IsCodeValid(codeText)
    local code = CodesSystem.AvailableCodes[string.upper(codeText)]
    if not code then
        return false, "Invalid code"
    end
    
    -- Check expiry
    if code.ExpiryTime and tick() > code.ExpiryTime then
        return false, "Code has expired"
    end
    
    return true, "Valid code"
end

-- Check if player has already redeemed this code
function CodesSystem.HasPlayerRedeemed(player, codeText)
    local success, result = pcall(function()
        local key = "Player_" .. player.UserId .. "_" .. string.upper(codeText)
        return CodesDataStore:GetAsync(key)
    end)
    
    if success and result then
        return true
    end
    return false
end

-- Mark code as redeemed for player
function CodesSystem.MarkCodeRedeemed(player, codeText)
    local success = pcall(function()
        local key = "Player_" .. player.UserId .. "_" .. string.upper(codeText)
        CodesDataStore:SetAsync(key, {
            RedeemedTime = tick(),
            PlayerId = player.UserId,
            PlayerName = player.Name
        })
    end)
    
    return success
end

-- Give rewards to player
function CodesSystem.GiveRewards(player, rewards)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Give coins
    if rewards.Coins then
        DataStore.AddCoins(player, rewards.Coins)
    end
    
    -- Give essence
    if rewards.Essence then
        DataStore.AddEssence(player, rewards.Essence)
    end
    
    -- Give items
    if rewards.Items then
        for _, item in ipairs(rewards.Items) do
            if item.Type == "LuckyEgg" then
                -- Add lucky egg effect to player data
                playerData.LuckyEggs = (playerData.LuckyEggs or 0) + item.Amount
                
            elseif item.Type == "FireEgg" then
                -- Add fire egg to inventory
                local fireEgg = {
                    EggType = "Fire Egg",
                    Element = "Fire",
                    Rarity = "Common",
                    ReceivedTime = tick()
                }
                table.insert(playerData.EggsInInventory, fireEgg)
            end
        end
    end
    
    DataStore.MarkDataDirty(player)
    return true, "Rewards given successfully"
end

-- Main redemption function
function CodesSystem.RedeemCode(player, codeText)
    -- Validate input
    if not codeText or type(codeText) ~= "string" then
        return {
            Success = false,
            Message = "Invalid code format"
        }
    end
    
    local upperCode = string.upper(string.gsub(codeText, "%s+", "")) -- Remove spaces and uppercase
    
    -- Check if code exists and is valid
    local isValid, validationMsg = CodesSystem.IsCodeValid(upperCode)
    if not isValid then
        return {
            Success = false,
            Message = validationMsg
        }
    end
    
    -- Check if player already redeemed this code
    if CodesSystem.HasPlayerRedeemed(player, upperCode) then
        return {
            Success = false,
            Message = "You have already redeemed this code!"
        }
    end
    
    -- Get code data
    local codeData = CodesSystem.AvailableCodes[upperCode]
    
    -- Give rewards
    local rewardSuccess, rewardMsg = CodesSystem.GiveRewards(player, codeData.Rewards)
    if not rewardSuccess then
        return {
            Success = false,
            Message = "Failed to give rewards: " .. rewardMsg
        }
    end
    
    -- Mark as redeemed
    if not CodesSystem.MarkCodeRedeemed(player, upperCode) then
        warn("Failed to mark code as redeemed for", player.Name, upperCode)
    end
    
    -- Build success message
    local rewardText = {}
    if codeData.Rewards.Coins then
        table.insert(rewardText, codeData.Rewards.Coins .. " coins")
    end
    if codeData.Rewards.Essence then  
        table.insert(rewardText, codeData.Rewards.Essence .. " essence")
    end
    if codeData.Rewards.Items then
        for _, item in ipairs(codeData.Rewards.Items) do
            table.insert(rewardText, item.Amount .. "x " .. item.Type)
        end
    end
    
    local rewardsString = table.concat(rewardText, ", ")
    
    -- Update stats
    local playerData = DataStore.GetPlayerData(player)
    if playerData then
        playerData.Stats.CodesRedeemed = (playerData.Stats.CodesRedeemed or 0) + 1
        DataStore.MarkDataDirty(player)
    end
    
    print(player.Name .. " redeemed code: " .. upperCode .. " - Rewards: " .. rewardsString)
    
    return {
        Success = true,
        Message = "Code redeemed! You received: " .. rewardsString,
        Rewards = codeData.Rewards,
        Description = codeData.Description
    }
end

-- Remote function handler
RedeemCodeRemote.OnServerInvoke = function(player, codeText)
    return CodesSystem.RedeemCode(player, codeText)
end

-- Admin function to add new codes (for future use)
function CodesSystem.AddCode(codeText, rewards, description, expiryTime)
    CodesSystem.AvailableCodes[string.upper(codeText)] = {
        Rewards = rewards,
        Description = description or "Special reward!",
        ExpiryTime = expiryTime,
        OneTimeUse = true
    }
    print("Added new code:", codeText)
end

-- Admin function to get redemption stats
function CodesSystem.GetCodeStats(codeText)
    local stats = {
        TotalRedemptions = 0,
        RecentRedemptions = {}
    }
    
    -- This is a basic implementation - in a real game you'd want more sophisticated analytics
    print("Getting stats for code:", codeText)
    return stats
end

print("CodesSystem loaded - Available codes:", #CodesSystem.AvailableCodes)

return CodesSystem