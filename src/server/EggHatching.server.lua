--[[
    EggHatching.server.lua
    Egg incubation and hatching system for V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EggData = require(ReplicatedStorage.Shared.EggData)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local DataStore = require(script.Parent.DataStore)
local DragonManager = require(script.Parent.DragonManager)

local EggHatching = {}
EggHatching.ActiveEggModels = {} -- Player -> {EggId -> EggModel}

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EggPurchasedEvent = RemoteEvents:FindFirstChild("EggPurchased") or Instance.new("RemoteEvent")
EggPurchasedEvent.Name = "EggPurchased"
EggPurchasedEvent.Parent = RemoteEvents

local EggPlacedEvent = RemoteEvents:FindFirstChild("EggPlaced") or Instance.new("RemoteEvent")
EggPlacedEvent.Name = "EggPlaced"
EggPlacedEvent.Parent = RemoteEvents

local EggHatchRequestEvent = RemoteEvents:FindFirstChild("EggHatchRequest") or Instance.new("RemoteEvent")
EggHatchRequestEvent.Name = "EggHatchRequest"
EggHatchRequestEvent.Parent = RemoteEvents

-- Remote functions
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local PurchaseEggFunction = RemoteFunctions:FindFirstChild("PurchaseEgg") or Instance.new("RemoteFunction")
PurchaseEggFunction.Name = "PurchaseEgg"
PurchaseEggFunction.Parent = RemoteFunctions

local PlaceEggFunction = RemoteFunctions:FindFirstChild("PlaceEgg") or Instance.new("RemoteFunction")
PlaceEggFunction.Name = "PlaceEgg"
PlaceEggFunction.Parent = RemoteFunctions

-- Egg model creation
function EggHatching.CreateEggModel(egg, position)
    local eggTemplate = EggData.EggTypes[egg.Type]
    if not eggTemplate then return nil end
    
    local assetId = AssetIds.GetEggAsset(egg.Type)
    
    local model = Instance.new("Model")
    model.Name = egg.Type
    model.Parent = workspace
    
    -- Create placeholder until asset loads
    local placeholder = Instance.new("Part")
    placeholder.Name = "EggPart"
    placeholder.Size = Vector3.new(2, 3, 2)
    placeholder.Material = Enum.Material.Neon
    placeholder.Anchored = true
    placeholder.CanCollide = false
    placeholder.TopSurface = Enum.SurfaceType.Smooth
    placeholder.BottomSurface = Enum.SurfaceType.Smooth
    placeholder.Shape = Enum.PartType.Ball
    placeholder.Position = position
    placeholder.Parent = model
    
    -- Set color based on egg type
    local eggColors = {
        ["Stone Egg"] = Color3.new(0.6, 0.6, 0.7),
        ["Crystal Egg"] = Color3.new(0.7, 0.8, 1),
        ["Shadow Egg"] = Color3.new(0.3, 0.2, 0.5),
        ["Golden Egg"] = Color3.new(1, 0.8, 0.2),
        ["Mythic Egg"] = Color3.new(0.8, 0.2, 0.8),
        ["Event Egg"] = Color3.new(1, 1, 1)
    }
    
    placeholder.Color = eggColors[egg.Type] or Color3.new(0.8, 0.8, 0.8)
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = placeholder.Color
    pointLight.Brightness = 1
    pointLight.Range = 8
    pointLight.Parent = placeholder
    
    -- Load actual mesh asynchronously
    spawn(function()
        local success, meshModel = pcall(function()
            return game:GetService("InsertService"):LoadAsset(assetId)
        end)
        
        if success and meshModel then
            local mesh = meshModel:GetChildren()[1]
            if mesh and mesh:IsA("Model") then
                mesh.Parent = model
                mesh.Name = "EggMesh"
                
                -- Position mesh
                if mesh.PrimaryPart then
                    mesh:SetPrimaryPartCFrame(CFrame.new(position))
                else
                    mesh:MoveTo(position)
                end
                
                placeholder:Destroy()
            end
            meshModel:Destroy()
        else
            warn("Failed to load egg mesh:", assetId)
        end
    end)
    
    -- Add click detection for hatching
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = placeholder
    
    clickDetector.MouseClick:Connect(function(player)
        EggHatching.OnEggClicked(player, egg)
    end)
    
    return model
end

-- Update egg visual based on hatching progress
function EggHatching.UpdateEggVisual(eggModel, progress)
    local eggPart = eggModel:FindFirstChild("EggPart") or eggModel:FindFirstChildOfClass("BasePart")
    if not eggPart then return end
    
    -- Change intensity based on progress
    local pointLight = eggPart:FindFirstChild("PointLight")
    if pointLight then
        pointLight.Brightness = 1 + progress * 2
    end
    
    -- Add cracking effects at certain thresholds
    if progress >= 0.25 and not eggModel:FindFirstChild("Crack1") then
        EggHatching.AddCrackEffect(eggModel, 1)
    elseif progress >= 0.5 and not eggModel:FindFirstChild("Crack2") then
        EggHatching.AddCrackEffect(eggModel, 2)
    elseif progress >= 0.75 and not eggModel:FindFirstChild("Crack3") then
        EggHatching.AddCrackEffect(eggModel, 3)
    elseif progress >= 0.9 and not eggModel:FindFirstChild("ShakeEffect") then
        EggHatching.StartShakeEffect(eggModel)
    end
end

-- Add crack visual effects
function EggHatching.AddCrackEffect(eggModel, stage)
    local crackPart = Instance.new("Part")
    crackPart.Name = "Crack" .. stage
    crackPart.Size = Vector3.new(0.1, 2 + stage * 0.5, 0.1)
    crackPart.Material = Enum.Material.Neon
    crackPart.Color = Color3.new(1, 1, 0)
    crackPart.Anchored = true
    crackPart.CanCollide = false
    crackPart.Transparency = 0.5
    crackPart.Parent = eggModel
    
    local eggPart = eggModel:FindFirstChild("EggPart") or eggModel:FindFirstChildOfClass("BasePart")
    if eggPart then
        local angle = math.random() * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * 1.1, 0, math.sin(angle) * 1.1)
        crackPart.Position = eggPart.Position + offset
        crackPart.Rotation = Vector3.new(0, math.deg(angle), math.random(-10, 10))
    end
end

-- Start shake effect for nearly ready eggs
function EggHatching.StartShakeEffect(eggModel)
    local eggPart = eggModel:FindFirstChild("EggPart") or eggModel:FindFirstChildOfClass("BasePart")
    if not eggPart then return end
    
    local originalPosition = eggPart.Position
    
    spawn(function()
        local shakeEffect = Instance.new("Part")
        shakeEffect.Name = "ShakeEffect"
        shakeEffect.Size = Vector3.new(0, 0, 0)
        shakeEffect.Transparency = 1
        shakeEffect.Anchored = true
        shakeEffect.CanCollide = false
        shakeEffect.Parent = eggModel
        
        while shakeEffect.Parent and EggHatching.IsEggActive(eggModel) do
            local shakeX = (math.random() - 0.5) * 0.5
            local shakeZ = (math.random() - 0.5) * 0.5
            eggPart.Position = originalPosition + Vector3.new(shakeX, 0, shakeZ)
            wait(0.1)
        end
        
        if eggPart.Parent then
            eggPart.Position = originalPosition
        end
    end)
end

-- Check if egg is still in the game
function EggHatching.IsEggActive(eggModel)
    return eggModel and eggModel.Parent
end

-- Handle egg purchase
function EggHatching.PurchaseEgg(player, eggType, currency)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false, "Player data not found" end
    
    local price = EggData.GetEggPrice(eggType, currency)
    if not price then return false, "Invalid egg type or currency" end
    
    -- Check if player has enough currency
    if currency == "Coins" then
        if not DataStore.SpendCoins(player, price) then
            return false, "Not enough coins"
        end
    elseif currency == "Essence" then
        if not DataStore.SpendEssence(player, price) then
            return false, "Not enough essence"
        end
    else
        return false, "Invalid currency"
    end
    
    -- Create egg
    local egg, message = EggData.CreateEgg(eggType, player.UserId)
    if not egg then
        -- Refund on failure
        if currency == "Coins" then
            DataStore.AddCoins(player, price)
        else
            DataStore.AddEssence(player, price)
        end
        return false, message
    end
    
    -- Add to player inventory
    table.insert(playerData.EggsInInventory, egg)
    playerData.Stats.EggsBought = playerData.Stats.EggsBought + 1
    DataStore.MarkDataDirty(player)
    
    EggPurchasedEvent:FireClient(player, egg)
    print(player.Name .. " purchased " .. eggType .. " for " .. price .. " " .. currency)
    
    return true, "Egg purchased successfully"
end

-- Handle egg placement in incubator
function EggHatching.PlaceEgg(player, eggId, incubatorSlot)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false, "Player data not found" end
    
    -- Check if player has enough incubator slots
    if incubatorSlot > playerData.Plot.Incubators then
        return false, "Incubator slot not unlocked"
    end
    
    -- Check if incubator slot is occupied
    for _, incubatorEgg in ipairs(playerData.EggsInIncubators) do
        if incubatorEgg.IncubatorSlot == incubatorSlot then
            return false, "Incubator slot already occupied"
        end
    end
    
    -- Find egg in inventory
    local egg = nil
    local eggIndex = nil
    for i, inventoryEgg in ipairs(playerData.EggsInInventory) do
        if inventoryEgg.UniqueId == eggId then
            egg = inventoryEgg
            eggIndex = i
            break
        end
    end
    
    if not egg then
        return false, "Egg not found in inventory"
    end
    
    -- Move egg from inventory to incubator
    egg.IncubatorSlot = incubatorSlot
    EggData.StartHatching(egg)
    
    table.insert(playerData.EggsInIncubators, egg)
    table.remove(playerData.EggsInInventory, eggIndex)
    DataStore.MarkDataDirty(player)
    
    -- Create egg model in world
    local incubatorPosition = EggHatching.GetIncubatorPosition(incubatorSlot)
    local eggModel = EggHatching.CreateEggModel(egg, incubatorPosition)
    
    if not EggHatching.ActiveEggModels[player] then
        EggHatching.ActiveEggModels[player] = {}
    end
    EggHatching.ActiveEggModels[player][egg.UniqueId] = eggModel
    
    EggPlacedEvent:FireClient(player, egg, incubatorSlot)
    print(player.Name .. " placed egg in incubator " .. incubatorSlot)
    
    return true, "Egg placed in incubator"
end

-- Get incubator position based on slot number
function EggHatching.GetIncubatorPosition(slot)
    -- Base position for incubators
    local baseX, baseY, baseZ = -30, 5, -25
    local spacing = 6
    
    return Vector3.new(baseX + ((slot - 1) * spacing), baseY, baseZ)
end

-- Handle egg click for manual hatching
function EggHatching.OnEggClicked(player, egg)
    if EggData.IsReadyToHatch(egg) then
        local success, message = DragonManager.HatchEgg(player, egg.UniqueId, false)
        if success then
            -- Remove egg model
            local playerEggs = EggHatching.ActiveEggModels[player]
            if playerEggs and playerEggs[egg.UniqueId] then
                playerEggs[egg.UniqueId]:Destroy()
                playerEggs[egg.UniqueId] = nil
            end
        end
        EggHatchRequestEvent:FireClient(player, success, message)
    else
        local progress = EggData.GetHatchProgress(egg)
        local timeRemaining = math.max(0, egg.HatchTime - (tick() - egg.StartTime))
        EggHatchRequestEvent:FireClient(player, false, 
            string.format("Egg is %d%% ready. Time remaining: %d minutes", 
            math.floor(progress * 100), math.floor(timeRemaining / 60)))
    end
end

-- Update all active eggs
function EggHatching.UpdateActiveEggs()
    for player, playerEggs in pairs(EggHatching.ActiveEggModels) do
        local playerData = DataStore.GetPlayerData(player)
        if playerData then
            for eggId, eggModel in pairs(playerEggs) do
                -- Find corresponding egg data
                local egg = nil
                for _, incubatorEgg in ipairs(playerData.EggsInIncubators) do
                    if incubatorEgg.UniqueId == eggId then
                        egg = incubatorEgg
                        break
                    end
                end
                
                if egg and EggHatching.IsEggActive(eggModel) then
                    local progress = EggData.GetHatchProgress(egg)
                    EggHatching.UpdateEggVisual(eggModel, progress)
                    
                    -- Auto-hatch if player has auto-hatch gamepass and egg is ready
                    if playerData.Settings.AutoHatch and EggData.IsReadyToHatch(egg) then
                        spawn(function()
                            local success, message = DragonManager.HatchEgg(player, egg.UniqueId, false)
                            if success then
                                eggModel:Destroy()
                                playerEggs[eggId] = nil
                            end
                        end)
                    end
                else
                    -- Clean up orphaned models
                    if eggModel then
                        eggModel:Destroy()
                    end
                    playerEggs[eggId] = nil
                end
            end
        end
    end
end

-- Player cleanup
function EggHatching.OnPlayerRemoving(player)
    if EggHatching.ActiveEggModels[player] then
        for eggId, eggModel in pairs(EggHatching.ActiveEggModels[player]) do
            if eggModel then
                eggModel:Destroy()
            end
        end
        EggHatching.ActiveEggModels[player] = nil
    end
end

-- Remote function handlers
PurchaseEggFunction.OnServerInvoke = function(player, eggType, currency)
    return EggHatching.PurchaseEgg(player, eggType, currency)
end

PlaceEggFunction.OnServerInvoke = function(player, eggId, incubatorSlot)
    return EggHatching.PlaceEgg(player, eggId, incubatorSlot)
end

-- Main update loop
spawn(function()
    while true do
        wait(5) -- Update every 5 seconds
        EggHatching.UpdateActiveEggs()
    end
end)

-- Event connections
Players.PlayerRemoving:Connect(EggHatching.OnPlayerRemoving)

return EggHatching