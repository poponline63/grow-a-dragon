-- EggHatching.server.lua - Egg system and hatching logic
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local EggData = require(ReplicatedStorage.Shared.EggData)
local DragonData = require(ReplicatedStorage.Shared.DragonData)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

-- Wait for DataStore API to be ready
repeat wait() until _G.PlayerDataAPI
local DataAPI = _G.PlayerDataAPI

-- Track egg models in the world
local eggModels = {} -- [eggId] = model

-- Create egg model with fallback
local function createEggModel(eggData, position)
    local assetId = AssetIds.Eggs[eggData.Tier]
    local eggModel
    
    -- Try to load from catalog first
    if assetId and assetId > 0 then
        local success, model = pcall(function()
            return InsertService:LoadAsset(assetId)
        end)
        
        if success and model then
            eggModel = model:GetChildren()[1]:Clone()
            model:Destroy()
        end
    end
    
    -- Fallback to primitive part
    if not eggModel then
        eggModel = Instance.new("Part")
        eggModel.Name = "Egg"
        eggModel.Shape = Enum.PartType.Ball
        eggModel.Size = Vector3.new(4, 5, 3)
        eggModel.CanCollide = false
        eggModel.Anchored = true
        
        -- Add mesh for better egg shape
        local specialMesh = Instance.new("SpecialMesh")
        specialMesh.MeshType = Enum.MeshType.FileMesh
        specialMesh.MeshId = "rbxasset://fonts/egg.mesh"
        specialMesh.Scale = Vector3.new(2, 2, 2)
        specialMesh.Parent = eggModel
    end
    
    -- Set egg properties
    local tierData = EggData:GetTier(eggData.Tier)
    if tierData then
        eggModel.Color = tierData.Color
    end
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = tierData and tierData.Color or Color3.new(1, 1, 1)
    pointLight.Brightness = 0.5
    pointLight.Range = 10
    pointLight.Parent = eggModel
    
    -- Add particle effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = eggModel
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1.0, 3.0)
    particles.Rate = 20
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 5)
    particles.Color = ColorSequence.new(tierData and tierData.Color or Color3.new(1, 1, 1))
    
    -- Add hovering animation
    local hoverInfo = TweenInfo.new(
        2, -- Duration
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Repeat infinitely
        true -- Reverse
    )
    
    local hoverTween = TweenService:Create(
        eggModel,
        hoverInfo,
        {Position = position + Vector3.new(0, 1, 0)}
    )
    
    -- Position and parent
    eggModel.Position = position
    eggModel.Parent = Workspace
    
    -- Start hover animation
    hoverTween:Play()
    
    -- Add click detector for player interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = eggModel
    
    -- Store reference to tween for cleanup
    eggModel:SetAttribute("HoverTween", hoverTween)
    
    return eggModel, clickDetector
end

-- Update egg model based on hatch progress
local function updateEggModel(eggModel, progress)
    if not eggModel or not eggModel.Parent then return end
    
    -- Change glow intensity based on progress
    local pointLight = eggModel:FindFirstChild("PointLight")
    if pointLight then
        pointLight.Brightness = 0.5 + (progress * 1.5) -- Brighter as it gets ready to hatch
    end
    
    -- Increase particle emission as hatch time approaches
    local attachment = eggModel:FindFirstChild("Attachment")
    if attachment then
        local particles = attachment:FindFirstChild("ParticleEmitter")
        if particles then
            particles.Rate = 20 + (progress * 80) -- More particles as ready to hatch
        end
    end
    
    -- Add shaking effect when almost ready (90%+ progress)
    if progress >= 0.9 then
        local shakeAmount = (progress - 0.9) * 20 -- Shake more as closer to hatching
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * shakeAmount,
            (math.random() - 0.5) * shakeAmount,
            (math.random() - 0.5) * shakeAmount
        ) * 0.1
        
        eggModel.Position = eggModel.Position + randomOffset
    end
end

-- Hatch an egg and create dragon
local function hatchEgg(player, eggId)
    local data = DataAPI.GetData(player)
    if not data then return false end
    
    local egg = data.Eggs[eggId]
    if not egg then return false end
    
    -- Roll for dragon rarity based on egg tier
    local rarity = EggData:RollRarity(egg.Tier)
    
    -- Pick random element
    local elements = Config.Dragons.Elements
    local element = elements[math.random(#elements)]
    
    -- Get dragon data
    local dragonData = DragonData:GetDragon(element, rarity)
    if not dragonData then
        warn("Failed to get dragon data for " .. element .. " " .. rarity)
        return false
    end
    
    -- Create new dragon
    local dragonId = Utils.GenerateId()
    local newDragon = {
        Id = dragonId,
        Element = element,
        Rarity = rarity,
        Level = 1,
        XP = 0,
        Name = dragonData.Name,
        Nickname = dragonData.Name, -- Can be customized later
        HatchTime = Utils.GetTimestamp(),
        Stats = Utils.CalculateStats(dragonData.BaseStats, 1),
        GrowthStage = "Baby"
    }
    
    -- Add dragon to player data
    data.Dragons[dragonId] = newDragon
    
    -- Remove egg from data
    data.Eggs[eggId] = nil
    
    -- Remove egg model from world
    local eggModel = eggModels[eggId]
    if eggModel then
        -- Stop hover animation
        local hoverTween = eggModel:GetAttribute("HoverTween")
        if hoverTween then
            hoverTween:Cancel()
        end
        
        eggModel:Destroy()
        eggModels[eggId] = nil
    end
    
    -- Give XP for hatching
    DataAPI.AddXP(player, 50)
    
    -- Fire events
    local eggHatched = ReplicatedStorage.RemoteEvents:FindFirstChild("EggHatched")
    if eggHatched then
        eggHatched:FireClient(player, eggId)
    end
    
    local dragonHatched = ReplicatedStorage.RemoteEvents:FindFirstChild("DragonHatched")
    if dragonHatched then
        dragonHatched:FireClient(player, newDragon)
    end
    
    print(player.Name .. " hatched a " .. rarity .. " " .. element .. " dragon!")
    return true
end

-- Check egg hatch status
local function checkEggHatchStatus(player, eggId)
    local data = DataAPI.GetData(player)
    if not data then return 0 end
    
    local egg = data.Eggs[eggId]
    if not egg then return 0 end
    
    local currentTime = Utils.GetTimestamp()
    local elapsedTime = currentTime - egg.StartTime
    local progress = elapsedTime / egg.HatchTime
    
    return math.min(progress, 1)
end

-- Main egg management loop
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- Update every 0.5 seconds to save performance
    if currentTime - lastUpdate < 0.5 then
        return
    end
    lastUpdate = currentTime
    
    -- Check all players' eggs
    for _, player in pairs(Players:GetPlayers()) do
        local data = DataAPI.GetData(player)
        if data then
            for eggId, egg in pairs(data.Eggs) do
                local progress = checkEggHatchStatus(player, eggId)
                
                -- Update egg model if it exists
                local eggModel = eggModels[eggId]
                if eggModel then
                    updateEggModel(eggModel, progress)
                end
                
                -- Auto-hatch if ready
                if progress >= 1 then
                    hatchEgg(player, eggId)
                end
            end
        end
    end
end)

-- Handle egg clicking (show progress, offer speedup)
local function handleEggClick(player, eggId)
    local progress = checkEggHatchStatus(player, eggId)
    
    if progress >= 1 then
        -- Ready to hatch!
        hatchEgg(player, eggId)
    else
        -- Show progress and speedup option
        local data = DataAPI.GetData(player)
        local egg = data.Eggs[eggId]
        
        if egg then
            local remainingTime = egg.HatchTime - ((Utils.GetTimestamp() - egg.StartTime))
            
            -- Fire client event to show egg UI
            local showEggUI = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowEggUI")
            if showEggUI then
                showEggUI:FireClient(player, {
                    eggId = eggId,
                    progress = progress,
                    remainingTime = math.max(remainingTime, 0),
                    tier = egg.Tier
                })
            end
        end
    end
end

-- Create RemoteFunction for egg clicking
local eggClickFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("EggClick")
if not eggClickFunction then
    eggClickFunction = Instance.new("RemoteFunction")
    eggClickFunction.Name = "EggClick"
    eggClickFunction.Parent = ReplicatedStorage.RemoteFunctions
end

eggClickFunction.OnServerInvoke = function(player, eggId)
    handleEggClick(player, eggId)
    return true
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(3) -- Let character and plot load
        
        -- Spawn existing eggs on player's plot
        local data = DataAPI.GetData(player)
        if data and data.PlotId then
            for eggId, egg in pairs(data.Eggs) do
                -- Calculate plot position (simplified - should match actual plot system)
                local plotAngle = (data.PlotId - 1) * (360 / Config.Game.PlotCount)
                local plotX = math.cos(math.rad(plotAngle)) * Config.Game.PlotRadius
                local plotZ = math.sin(math.rad(plotAngle)) * Config.Game.PlotRadius
                
                -- Position egg on plot (with some randomness)
                local eggPosition = Vector3.new(
                    plotX + math.random(-10, 10),
                    5,
                    plotZ + math.random(-10, 10)
                )
                
                local eggModel, clickDetector = createEggModel(egg, eggPosition)
                eggModels[eggId] = eggModel
                
                -- Handle clicking
                clickDetector.MouseClick:Connect(function(clickingPlayer)
                    if clickingPlayer == player then
                        handleEggClick(player, eggId)
                    end
                end)
            end
        end
    end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    local data = DataAPI.GetData(player)
    if data then
        -- Clean up egg models
        for eggId, _ in pairs(data.Eggs) do
            local eggModel = eggModels[eggId]
            if eggModel then
                eggModel:Destroy()
                eggModels[eggId] = nil
            end
        end
    end
end)

print("EggHatching system loaded successfully!")