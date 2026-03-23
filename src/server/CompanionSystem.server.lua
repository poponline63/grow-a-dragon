-- CompanionSystem.server.lua - Dragon companion following system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local DragonData = require(ReplicatedStorage.Shared.DragonData)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

-- Wait for DataStore API to be ready
repeat wait() until _G.PlayerDataAPI
local DataAPI = _G.PlayerDataAPI

-- Track active companions
local activeCompanions = {} -- [playerId] = companionModel
local companionTargets = {} -- [playerId] = targetPosition

-- Create companion dragon model (smaller than plot dragons)
local function createCompanionModel(dragon)
    local element = dragon.Element
    local growthStage = Utils.GetGrowthStage(dragon.Level)
    local assetId
    
    -- Determine which model to use
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
    
    -- Fallback to primitive companion dragon
    if not dragonModel then
        dragonModel = Instance.new("Model")
        dragonModel.Name = "Companion_" .. dragon.Name
        
        -- Body (smaller for companion)
        local body = Instance.new("Part")
        body.Name = "Body"
        body.Size = Vector3.new(1.5, 1, 3)
        body.Shape = Enum.PartType.Block
        body.CanCollide = false
        body.Anchored = false
        body.Parent = dragonModel
        
        -- Head
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(1, 1, 1)
        head.Shape = Enum.PartType.Ball
        head.CanCollide = false
        head.Anchored = false
        head.Parent = dragonModel
        
        -- Wings (smaller)
        local leftWing = Instance.new("Part")
        leftWing.Name = "LeftWing"
        leftWing.Size = Vector3.new(0.3, 2, 1)
        leftWing.CanCollide = false
        leftWing.Anchored = false
        leftWing.Parent = dragonModel
        
        local rightWing = Instance.new("Part")
        rightWing.Name = "RightWing" 
        rightWing.Size = Vector3.new(0.3, 2, 1)
        rightWing.CanCollide = false
        rightWing.Anchored = false
        rightWing.Parent = dragonModel
        
        -- Tail
        local tail = Instance.new("Part")
        tail.Name = "Tail"
        tail.Size = Vector3.new(0.5, 0.5, 2)
        tail.Shape = Enum.PartType.Cylinder
        tail.CanCollide = false
        tail.Anchored = false
        tail.Parent = dragonModel
        
        -- Weld parts together
        local function weldPart(part, targetPart, offset)
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = body
            weld.Part1 = part
            weld.Parent = body
            part.CFrame = body.CFrame * CFrame.new(offset)
        end
        
        weldPart(head, body, Vector3.new(0, 0, -2))
        weldPart(leftWing, body, Vector3.new(-1.2, 0.5, 0))
        weldPart(rightWing, body, Vector3.new(1.2, 0.5, 0))
        weldPart(tail, body, Vector3.new(0, 0, 2.5))
        
        -- Set primary part
        dragonModel.PrimaryPart = body
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
    
    -- Scale companion to be smaller (75% of normal size)
    local scale = 0.75
    for _, part in pairs(dragonModel:GetChildren()) do
        if part:IsA("Part") then
            part.Size = part.Size * scale
        end
    end
    
    -- Add floating behavior
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = dragonModel.PrimaryPart
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = dragonModel.PrimaryPart
    
    -- Add name billboard (smaller)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 80, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = dragonModel.PrimaryPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = dragon.Nickname or dragon.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboardGui
    
    -- Add subtle particle effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = dragonModel.PrimaryPart
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Lifetime = NumberRange.new(1.0, 2.0)
    particles.Rate = 3 -- Subtle particles for companions
    particles.SpreadAngle = Vector2.new(20, 20)
    particles.Speed = NumberRange.new(0.5, 2)
    
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
    
    return dragonModel
end

-- Update companion movement
local function updateCompanionMovement(playerId, companion)
    local player = Players:GetPlayerByUserId(playerId)
    if not player or not player.Character or not player.Character.PrimaryPart then
        return
    end
    
    if not companion or not companion.Parent or not companion.PrimaryPart then
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character.PrimaryPart
    local companionPart = companion.PrimaryPart
    local bodyVelocity = companionPart:FindFirstChild("BodyVelocity")
    local bodyAngularVelocity = companionPart:FindFirstChild("BodyAngularVelocity")
    
    if not bodyVelocity or not bodyAngularVelocity then
        return
    end
    
    -- Calculate desired position (behind and to the side of player)
    local playerPosition = humanoidRootPart.Position
    local playerLookDirection = humanoidRootPart.CFrame.LookVector
    local playerRightDirection = humanoidRootPart.CFrame.RightVector
    
    -- Position companion behind and slightly to the right of player, at head height
    local followDistance = 5
    local sideOffset = 2
    local heightOffset = 3
    
    local targetPosition = playerPosition 
        - (playerLookDirection * followDistance) 
        + (playerRightDirection * sideOffset)
        + Vector3.new(0, heightOffset, 0)
    
    -- Add some floating motion
    local time = tick()
    local floatOffset = Vector3.new(
        math.sin(time * 2) * 0.5,
        math.sin(time * 3) * 0.3,
        math.cos(time * 1.5) * 0.3
    )
    
    targetPosition = targetPosition + floatOffset
    
    -- Calculate movement
    local currentPosition = companionPart.Position
    local distance = (targetPosition - currentPosition).Magnitude
    
    if distance > 1 then
        -- Move towards target
        local direction = (targetPosition - currentPosition).Unit
        local speed = math.min(distance * 2, 16) -- Speed scales with distance, max 16
        
        bodyVelocity.Velocity = direction * speed
        
        -- Face movement direction
        local lookDirection = direction
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        
        -- Smoothly rotate to face movement direction
        local targetCFrame = CFrame.lookAt(currentPosition, currentPosition + lookDirection)
        local currentCFrame = companionPart.CFrame
        local lerpedCFrame = currentCFrame:Lerp(targetCFrame, 0.1)
        companionPart.CFrame = lerpedCFrame
    else
        -- Slow down when close
        bodyVelocity.Velocity = bodyVelocity.Velocity * 0.8
        
        -- Gentle hovering rotation
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, math.sin(time) * 0.5, 0)
    end
end

-- Spawn companion for player
local function spawnCompanion(player)
    local data = DataAPI.GetData(player)
    if not data or not data.ActiveCompanion then
        return
    end
    
    local dragon = data.Dragons[data.ActiveCompanion]
    if not dragon then
        return
    end
    
    -- Remove existing companion
    local existingCompanion = activeCompanions[player.UserId]
    if existingCompanion then
        existingCompanion:Destroy()
        activeCompanions[player.UserId] = nil
    end
    
    -- Create new companion
    local companion = createCompanionModel(dragon)
    if companion then
        companion.Parent = Workspace
        activeCompanions[player.UserId] = companion
        
        print(player.Name .. " spawned companion: " .. dragon.Name)
    end
end

-- Remove companion for player
local function removeCompanion(player)
    local companion = activeCompanions[player.UserId]
    if companion then
        companion:Destroy()
        activeCompanions[player.UserId] = nil
        print(player.Name .. " removed companion")
    end
end

-- Main update loop
RunService.Heartbeat:Connect(function()
    -- Update all active companions
    for playerId, companion in pairs(activeCompanions) do
        updateCompanionMovement(playerId, companion)
    end
end)

-- Listen for companion changes
local setCompanionFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("SetActiveCompanion")
if setCompanionFunction then
    local originalInvoke = setCompanionFunction.OnServerInvoke
    
    setCompanionFunction.OnServerInvoke = function(player, dragonId)
        -- Call original function
        local result = originalInvoke(player, dragonId)
        
        -- Handle companion spawning
        if result.success then
            if dragonId then
                spawnCompanion(player)
            else
                removeCompanion(player)
            end
        end
        
        return result
    end
end

-- Handle dragon hatching (update companion if it's the active one)
local dragonHatched = ReplicatedStorage.RemoteEvents:FindFirstChild("DragonHatched")
if dragonHatched then
    dragonHatched.OnServerEvent:Connect(function(player, dragon)
        local data = DataAPI.GetData(player)
        if data and data.ActiveCompanion == dragon.Id then
            -- Respawn companion with updated dragon
            spawnCompanion(player)
        end
    end)
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(3) -- Let character and data load
        
        -- Spawn companion if player has one active
        spawnCompanion(player)
        
        -- Handle character respawning
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                -- Temporarily remove companion
                removeCompanion(player)
            end)
        end
        
        -- Respawn companion after respawn
        player.CharacterAdded:Connect(function(newCharacter)
            wait(2)
            spawnCompanion(player)
        end)
    end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    removeCompanion(player)
    companionTargets[player.UserId] = nil
end)

-- Companion interaction commands (for future expansion)
local companionCommandFunction = ReplicatedStorage.RemoteFunctions:FindFirstChild("CompanionCommand")
if not companionCommandFunction then
    companionCommandFunction = Instance.new("RemoteFunction")
    companionCommandFunction.Name = "CompanionCommand"
    companionCommandFunction.Parent = ReplicatedStorage.RemoteFunctions
end

companionCommandFunction.OnServerInvoke = function(player, command, target)
    local companion = activeCompanions[player.UserId]
    if not companion then
        return {success = false, message = "No active companion"}
    end
    
    if command == "stay" then
        -- Make companion stay at current position
        companionTargets[player.UserId] = companion.PrimaryPart.Position
        return {success = true, message = "Companion will stay here"}
        
    elseif command == "follow" then
        -- Resume following player
        companionTargets[player.UserId] = nil
        return {success = true, message = "Companion will follow you"}
        
    elseif command == "sit" then
        -- Make companion sit (reduce height)
        local bodyVelocity = companion.PrimaryPart:FindFirstChild("BodyVelocity")
        if bodyVelocity then
            bodyVelocity.Velocity = Vector3.new(0, -5, 0)
        end
        return {success = true, message = "Companion sits"}
        
    else
        return {success = false, message = "Unknown command"}
    end
end

print("CompanionSystem loaded successfully!")