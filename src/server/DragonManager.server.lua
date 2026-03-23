-- DragonManager.server.lua - Dragon management system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local DragonData = require(ReplicatedStorage.Shared.DragonData)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

-- Wait for DataStore API to be ready
repeat wait() until _G.PlayerDataAPI
local DataAPI = _G.PlayerDataAPI

-- Track dragon models in the world
local dragonModels = {} -- [playerId] = {[dragonId] = model}

-- Create dragon model with fallback
local function createDragonModel(dragon, position)
    local element = dragon.Element
    local growthStage = Utils.GetGrowthStage(dragon.Level)
    local assetId
    
    -- Determine which model to use based on growth stage
    if AssetIds.Dragons[element] then
        if growthStage == "Baby" or growthStage == "Juvenile" then
            assetId = AssetIds.Dragons[element].Baby
        else
            assetId = AssetIds.Dragons[element].Adult
        end
    end
    
    local dragonModel
    
    -- Try to load from catalog first
    if assetId and assetId > 0 then
        local success, model = pcall(function()
            return InsertService:LoadAsset(assetId)
        end)
        
        if success and model then
            dragonModel = model:GetChildren()[1]:Clone()
            model:Destroy()
        end
    end
    
    -- Fallback to primitive dragon
    if not dragonModel then
        dragonModel = Instance.new("Model")
        dragonModel.Name = dragon.Name
        
        -- Body
        local body = Instance.new("Part")
        body.Name = "Body"
        body.Size = Vector3.new(3, 2, 6)
        body.Shape = Enum.PartType.Block
        body.CanCollide = false
        body.Anchored = true
        body.Parent = dragonModel
        
        -- Head
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(2, 2, 2)
        head.Shape = Enum.PartType.Ball
        head.CanCollide = false
        head.Anchored = true
        head.Parent = dragonModel
        
        -- Wings
        local leftWing = Instance.new("Part")
        leftWing.Name = "LeftWing"
        leftWing.Size = Vector3.new(0.5, 4, 2)
        leftWing.CanCollide = false
        leftWing.Anchored = true
        leftWing.Parent = dragonModel
        
        local rightWing = Instance.new("Part")
        rightWing.Name = "RightWing"
        rightWing.Size = Vector3.new(0.5, 4, 2)
        rightWing.CanCollide = false
        rightWing.Anchored = true
        rightWing.Parent = dragonModel
        
        -- Tail
        local tail = Instance.new("Part")
        tail.Name = "Tail"
        tail.Size = Vector3.new(1, 1, 4)
        tail.Shape = Enum.PartType.Cylinder
        tail.CanCollide = false
        tail.Anchored = true
        tail.Parent = dragonModel
        
        -- Position parts relative to body
        local bodyPosition = position
        body.Position = bodyPosition
        head.Position = bodyPosition + Vector3.new(0, 0, -4)
        leftWing.Position = bodyPosition + Vector3.new(-2.5, 1, 0)
        rightWing.Position = bodyPosition + Vector3.new(2.5, 1, 0)
        tail.Position = bodyPosition + Vector3.new(0, 0, 5)
        
        -- Rotate tail
        tail.CFrame = tail.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end
    
    -- Set dragon properties
    local dragonInfo = DragonData:GetDragon(dragon.Element, dragon.Rarity)
    if dragonInfo then
        -- Color all parts based on element
        local color = dragonInfo.Color
        for _, part in pairs(dragonModel:GetChildren()) do
            if part:IsA("Part") then
                part.Color = color
            end
        end
    end
    
    -- Scale based on growth stage
    local scale = 0.5 -- Start small for babies
    if growthStage == "Juvenile" then
        scale = 0.7
    elseif growthStage == "Teen" then
        scale = 0.85
    elseif growthStage == "Adult" then
        scale = 1.0
    elseif growthStage == "Elder" then
        scale = 1.2
    elseif growthStage == "Legendary" then
        scale = 1.5
    end
    
    -- Apply scaling
    for _, part in pairs(dragonModel:GetChildren()) do
        if part:IsA("Part") then
            part.Size = part.Size * scale
        end
    end
    
    -- Add name billboard
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = dragonModel:FindFirstChild("Body") or dragonModel:FindFirstChildOfClass("Part")
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = dragon.Nickname or dragon.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboardGui
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0.4, 0)
    levelLabel.Position = UDim2.new(0, 0, 0.6, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level " .. dragon.Level .. " " .. growthStage
    levelLabel.TextColor3 = dragonInfo and dragonInfo.RarityColor or Color3.new(0.7, 0.7, 0.7)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.Parent = billboardGui
    
    -- Add particle effects based on element
    local attachment = Instance.new("Attachment")
    attachment.Parent = dragonModel:FindFirstChild("Body") or dragonModel:FindFirstChildOfClass("Part")
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Lifetime = NumberRange.new(2.0, 4.0)
    particles.Rate = 5
    particles.SpreadAngle = Vector2.new(30, 30)
    particles.Speed = NumberRange.new(1, 3)
    
    -- Element-specific particle effects
    if dragon.Element == "Fire" then
        particles.Texture = "rbxasset://textures/particles/fire_main.dds"
        particles.Color = ColorSequence.new(Color3.new(1, 0.4, 0.1))
    elseif dragon.Element == "Ice" then
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Color = ColorSequence.new(Color3.new(0.5, 0.8, 1))
    elseif dragon.Element == "Nature" then
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Color = ColorSequence.new(Color3.new(0.2, 0.8, 0.3))
    elseif dragon.Element == "Shadow" then
        particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
        particles.Color = ColorSequence.new(Color3.new(0.3, 0.2, 0.5))
    elseif dragon.Element == "Light" then
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Color = ColorSequence.new(Color3.new(1, 1, 0.7))
    elseif dragon.Element == "Storm" then
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Color = ColorSequence.new(Color3.new(0.6, 0.4, 1))
    end
    
    -- Position and parent
    dragonModel:SetPrimaryPartCFrame(CFrame.new(position))
    dragonModel.Parent = Workspace
    
    return dragonModel
end

-- Feed dragon function
local function feedDragon(player, dragonId)
    local data = DataAPI.GetData(player)
    if not data then return false end
    
    local dragon = data.Dragons[dragonId]
    if not dragon then return false end
    
    -- Check if player can afford feeding
    if data.Coins < Config.Dragons.FeedingCost then
        return false, "Need " .. Config.Dragons.FeedingCost .. " coins to feed!"
    end
    
    -- Spend coins
    local success = DataAPI.SpendCurrency(player, Config.Dragons.FeedingCost, 0)
    if not success then return false, "Failed to spend coins" end
    
    -- Add XP to dragon
    dragon.XP = dragon.XP + Config.Dragons.FeedingXP
    
    -- Check for level up
    local requiredXP = Config.Dragons.XPRequired[dragon.Level] or Config.Dragons.XPRequired[#Config.Dragons.XPRequired]
    
    if dragon.XP >= requiredXP and dragon.Level < Config.Dragons.MaxLevel then
        dragon.Level = dragon.Level + 1
        dragon.XP = 0 -- Reset XP for next level
        
        -- Recalculate stats
        local dragonInfo = DragonData:GetDragon(dragon.Element, dragon.Rarity)
        if dragonInfo then
            dragon.Stats = Utils.CalculateStats(dragonInfo.BaseStats, dragon.Level)
            dragon.GrowthStage = Utils.GetGrowthStage(dragon.Level)
        end
        
        -- Update dragon model if it exists
        local playerDragons = dragonModels[player.UserId]
        if playerDragons and playerDragons[dragonId] then
            local model = playerDragons[dragonId]
            -- Update billboard with new level and growth stage
            local billboard = model:FindFirstChild("BillboardGui", true)
            if billboard then
                local levelLabel = billboard:FindFirstChild("TextLabel")
                if levelLabel and levelLabel.Name ~= "TextLabel" then -- Get the second label
                    levelLabel.Text = "Level " .. dragon.Level .. " " .. dragon.GrowthStage
                end
            end
        end
        
        print(player.Name .. "'s " .. dragon.Name .. " leveled up to " .. dragon.Level .. "!")
    end
    
    return true, "Fed " .. dragon.Name .. "! +" .. Config.Dragons.FeedingXP .. " XP"
end

-- Set active companion dragon
local function setActiveCompanion(player, dragonId)
    local data = DataAPI.GetData(player)
    if not data then return false end
    
    -- Validate dragon exists
    if dragonId and not data.Dragons[dragonId] then
        return false, "Dragon not found"
    end
    
    -- Set new active companion
    data.ActiveCompanion = dragonId
    
    return true, dragonId and "Companion set!" or "Companion dismissed"
end

-- Create remote functions
local feedDragonFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("FeedDragon")
if not feedDragonFunction then
    feedDragonFunction = Instance.new("RemoteFunction")
    feedDragonFunction.Name = "FeedDragon"
    feedDragonFunction.Parent = ReplicatedStorage.RemoteFunctions
end

feedDragonFunction.OnServerInvoke = function(player, dragonId)
    local success, message = feedDragon(player, dragonId)
    return {success = success, message = message}
end

local setCompanionFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("SetActiveCompanion")
if not setCompanionFunction then
    setCompanionFunction = Instance.new("RemoteFunction")
    setCompanionFunction.Name = "SetActiveCompanion"
    setCompanionFunction.Parent = ReplicatedStorage.RemoteFunctions
end

setCompanionFunction.OnServerInvoke = function(player, dragonId)
    local success, message = setActiveCompanion(player, dragonId)
    return {success = success, message = message}
end

-- Get dragon inventory
local getDragonsFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("GetDragons")
if not getDragonsFunction then
    getDragonsFunction = Instance.new("RemoteFunction")
    getDragonsFunction.Name = "GetDragons"
    getDragonsFunction.Parent = ReplicatedStorage.RemoteFunctions
end

getDragonsFunction.OnServerInvoke = function(player)
    local data = DataAPI.GetData(player)
    if not data then return {} end
    
    local dragons = {}
    for dragonId, dragon in pairs(data.Dragons) do
        -- Add calculated current stats
        local dragonInfo = DragonData:GetDragon(dragon.Element, dragon.Rarity)
        local stats = dragon.Stats
        
        if dragonInfo then
            stats = Utils.CalculateStats(dragonInfo.BaseStats, dragon.Level)
        end
        
        local dragonCopy = Utils.DeepCopy(dragon)
        dragonCopy.CurrentStats = stats
        dragonCopy.IsActive = (data.ActiveCompanion == dragonId)
        dragons[dragonId] = dragonCopy
    end
    
    return dragons
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    dragonModels[player.UserId] = {}
    
    player.CharacterAdded:Connect(function(character)
        wait(3) -- Let character load
        
        -- Spawn dragons on player's plot (simplified positioning)
        local data = DataAPI.GetData(player)
        if data and data.PlotId then
            local dragonCount = 0
            
            for dragonId, dragon in pairs(data.Dragons) do
                -- Calculate dragon position on plot
                local plotAngle = (data.PlotId - 1) * (360 / Config.Game.PlotCount)
                local plotX = math.cos(math.rad(plotAngle)) * Config.Game.PlotRadius
                local plotZ = math.sin(math.rad(plotAngle)) * Config.Game.PlotRadius
                
                -- Arrange dragons in a line on the plot
                local dragonPosition = Vector3.new(
                    plotX + (dragonCount * 5),
                    2,
                    plotZ + 10
                )
                
                local dragonModel = createDragonModel(dragon, dragonPosition)
                dragonModels[player.UserId][dragonId] = dragonModel
                
                dragonCount = dragonCount + 1
            end
        end
    end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    local playerDragons = dragonModels[player.UserId]
    if playerDragons then
        for dragonId, model in pairs(playerDragons) do
            if model and model.Parent then
                model:Destroy()
            end
        end
        dragonModels[player.UserId] = nil
    end
end)

print("DragonManager system loaded successfully!")