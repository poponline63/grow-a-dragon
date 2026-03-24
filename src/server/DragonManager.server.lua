--[[
    DragonManager.server.lua
    Dragon system management for V3 - hatching, growth, feeding, breeding
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonData = require(ReplicatedStorage.Shared.DragonData)
local EggData = require(ReplicatedStorage.Shared.EggData)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local DataStore = require(script.Parent.DataStore)

local DragonManager = {}
DragonManager.ActiveDragons = {} -- Player -> {DragonId -> DragonModel}
DragonManager.BreedingPairs = {} -- {Dragon1, Dragon2, StartTime, CompletionTime}
DragonManager.ExpeditionDragons = {} -- {Dragon, StartTime, Duration, Type}

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local DragonHatchedEvent = RemoteEvents:FindFirstChild("DragonHatched") or Instance.new("RemoteEvent")
DragonHatchedEvent.Name = "DragonHatched"
DragonHatchedEvent.Parent = RemoteEvents

local DragonFedEvent = RemoteEvents:FindFirstChild("DragonFed") or Instance.new("RemoteEvent") 
DragonFedEvent.Name = "DragonFed"
DragonFedEvent.Parent = RemoteEvents

local DragonGrownEvent = RemoteEvents:FindFirstChild("DragonGrown") or Instance.new("RemoteEvent")
DragonGrownEvent.Name = "DragonGrown"
DragonGrownEvent.Parent = RemoteEvents

local BreedingStartedEvent = RemoteEvents:FindFirstChild("BreedingStarted") or Instance.new("RemoteEvent")
BreedingStartedEvent.Name = "BreedingStarted" 
BreedingStartedEvent.Parent = RemoteEvents

-- Dragon model creation
function DragonManager.CreateDragonModel(dragon, parent)
    local assetId = AssetIds.GetDragonAsset(dragon.Element, Config.GrowthStages[dragon.Stage].Name)
    
    local model = Instance.new("Model")
    model.Name = DragonData.GetDisplayName(dragon)
    model.Parent = parent or workspace
    
    -- Create placeholder until asset loads
    local placeholder = Instance.new("Part")
    placeholder.Name = "Placeholder"
    placeholder.Size = Vector3.new(dragon.Size, dragon.Size * 0.8, dragon.Size)
    placeholder.Material = Enum.Material.Neon
    placeholder.Color = Config.ElementColors[dragon.Element]
    placeholder.Anchored = true
    placeholder.CanCollide = false
    placeholder.TopSurface = Enum.SurfaceType.Smooth
    placeholder.BottomSurface = Enum.SurfaceType.Smooth
    placeholder.Parent = model
    
    -- Add glow effect for variants
    if dragon.Variant == "Shiny" then
        local shinyEffect = Instance.new("PointLight")
        shinyEffect.Color = Color3.new(1, 1, 1)
        shinyEffect.Brightness = 2
        shinyEffect.Range = 10
        shinyEffect.Parent = placeholder
    elseif dragon.Variant == "Golden" then
        placeholder.Color = Color3.new(1, 0.8, 0.2)
        local goldenEffect = Instance.new("PointLight")
        goldenEffect.Color = Color3.new(1, 0.8, 0.2)
        goldenEffect.Brightness = 1.5
        goldenEffect.Range = 8
        goldenEffect.Parent = placeholder
    elseif dragon.Variant == "Rainbow" then
        local rainbowEffect = Instance.new("PointLight")
        rainbowEffect.Color = Color3.new(1, 0.5, 1)
        rainbowEffect.Brightness = 3
        rainbowEffect.Range = 15
        rainbowEffect.Parent = placeholder
        
        -- Color cycling
        spawn(function()
            local hue = 0
            while placeholder.Parent do
                hue = (hue + 0.01) % 1
                placeholder.Color = Color3.fromHSV(hue, 1, 1)
                rainbowEffect.Color = Color3.fromHSV(hue, 0.8, 1)
                wait(0.1)
            end
        end)
    end
    
    -- Load actual mesh asynchronously
    spawn(function()
        local success, meshModel = pcall(function()
            return game:GetService("InsertService"):LoadAsset(assetId)
        end)
        
        if success and meshModel then
            local mesh = meshModel:GetChildren()[1]
            if mesh and mesh:IsA("Model") then
                mesh.Parent = model
                mesh.Name = "DragonMesh"
                
                -- Scale mesh to match dragon size
                DragonManager.ScaleModel(mesh, dragon.Size / 3) -- Base size is 3
                
                -- Position mesh
                if mesh.PrimaryPart then
                    mesh:SetPrimaryPartCFrame(placeholder.CFrame)
                end
                
                placeholder:Destroy()
            end
            meshModel:Destroy()
        else
            warn("Failed to load dragon mesh:", assetId)
        end
    end)
    
    -- Add click detection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = placeholder
    
    clickDetector.MouseClick:Connect(function(player)
        DragonManager.OnDragonClicked(player, dragon)
    end)
    
    -- Add idle behaviors
    DragonManager.StartIdleBehavior(model, dragon)
    
    return model
end

-- Scale model recursively
function DragonManager.ScaleModel(model, scale)
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Size = child.Size * scale
            child.CFrame = model.PrimaryPart.CFrame * (model.PrimaryPart.CFrame:Inverse() * child.CFrame * scale)
        end
    end
end

-- Dragon idle behaviors
function DragonManager.StartIdleBehavior(model, dragon)
    spawn(function()
        while model.Parent do
            local behavior = math.random(1, 4)
            
            if behavior == 1 then
                -- Sleep animation
                DragonManager.AnimateSleep(model)
                wait(math.random(5, 15))
            elseif behavior == 2 then
                -- Play animation  
                DragonManager.AnimatePlay(model)
                wait(math.random(3, 8))
            elseif behavior == 3 then
                -- Fly around
                DragonManager.AnimateFly(model, dragon)
                wait(math.random(8, 20))
            else
                -- Just wait
                wait(math.random(10, 30))
            end
        end
    end)
end

-- Animation functions
function DragonManager.AnimateSleep(model)
    local primaryPart = model.PrimaryPart or model:FindFirstChild("Placeholder")
    if not primaryPart then return end
    
    local originalCFrame = primaryPart.CFrame
    local sleepCFrame = originalCFrame * CFrame.Angles(math.rad(15), 0, 0)
    
    local tween = TweenService:Create(primaryPart, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        CFrame = sleepCFrame
    })
    tween:Play()
    
    -- Return to normal after a while
    spawn(function()
        wait(math.random(3, 8))
        if primaryPart.Parent then
            local returnTween = TweenService:Create(primaryPart, TweenInfo.new(1, Enum.EasingStyle.Quad), {
                CFrame = originalCFrame
            })
            returnTween:Play()
        end
    end)
end

function DragonManager.AnimatePlay(model)
    local primaryPart = model.PrimaryPart or model:FindFirstChild("Placeholder")
    if not primaryPart then return end
    
    local originalPos = primaryPart.Position
    
    for i = 1, 3 do
        local jumpHeight = math.random(3, 8)
        local tween = TweenService:Create(primaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Position = originalPos + Vector3.new(0, jumpHeight, 0)
        })
        tween:Play()
        tween.Completed:Wait()
        
        local fallTween = TweenService:Create(primaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Position = originalPos
        })
        fallTween:Play()
        fallTween.Completed:Wait()
        
        wait(0.2)
    end
end

function DragonManager.AnimateFly(model, dragon)
    local primaryPart = model.PrimaryPart or model:FindFirstChild("Placeholder")
    if not primaryPart then return end
    
    -- Only adult+ dragons can fly
    if dragon.Stage < 4 then return end
    
    local originalPos = primaryPart.Position
    local flyHeight = originalPos.Y + math.random(10, 20)
    local distance = math.random(15, 30)
    local angle = math.random() * math.pi * 2
    
    local flyPos = Vector3.new(
        originalPos.X + math.cos(angle) * distance,
        flyHeight,
        originalPos.Z + math.sin(angle) * distance
    )
    
    -- Fly up
    local upTween = TweenService:Create(primaryPart, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        Position = Vector3.new(originalPos.X, flyHeight, originalPos.Z)
    })
    upTween:Play()
    upTween.Completed:Wait()
    
    -- Fly to position
    local flyTween = TweenService:Create(primaryPart, TweenInfo.new(3, Enum.EasingStyle.Linear), {
        Position = flyPos
    })
    flyTween:Play()
    flyTween.Completed:Wait()
    
    wait(math.random(2, 5))
    
    -- Fly back
    local returnTween = TweenService:Create(primaryPart, TweenInfo.new(3, Enum.EasingStyle.Quad), {
        Position = originalPos
    })
    returnTween:Play()
end

-- Dragon interaction
function DragonManager.OnDragonClicked(player, dragon)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Find this dragon in player's collection
    local dragonIndex = nil
    for i, playerDragon in ipairs(playerData.Dragons) do
        if playerDragon.UniqueId == dragon.UniqueId then
            dragonIndex = i
            break
        end
    end
    
    if not dragonIndex then return end
    
    -- Check if dragon can be fed
    local success, message = DragonData.FeedDragon(playerData.Dragons[dragonIndex])
    
    if success then
        -- Award coins for feeding
        DataStore.AddCoins(player, 10)
        
        -- Check if dragon grew
        if DragonData.CanGrowToNextStage(playerData.Dragons[dragonIndex]) then
            local grownDragon = DragonData.GrowDragon(playerData.Dragons[dragonIndex])
            if grownDragon then
                playerData.Dragons[dragonIndex] = grownDragon
                DataStore.MarkDataDirty(player)
                
                -- Update visual model
                DragonManager.UpdateDragonModel(player, grownDragon)
                
                -- Notify client
                DragonGrownEvent:FireClient(player, grownDragon)
                
                print(player.Name .. "'s dragon grew to " .. Config.GrowthStages[grownDragon.Stage].Name)
            end
        end
        
        DataStore.MarkDataDirty(player)
        DragonFedEvent:FireClient(player, message)
    else
        DragonFedEvent:FireClient(player, message)
    end
end

-- Update dragon model when it grows
function DragonManager.UpdateDragonModel(player, dragon)
    local playerDragons = DragonManager.ActiveDragons[player]
    if not playerDragons then return end
    
    local existingModel = playerDragons[dragon.UniqueId]
    if existingModel then
        existingModel:Destroy()
    end
    
    -- Create new model with updated size
    local newModel = DragonManager.CreateDragonModel(dragon)
    playerDragons[dragon.UniqueId] = newModel
end

-- Egg hatching
function DragonManager.HatchEgg(player, eggId, luckyBonus)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return end
    
    -- Find egg in incubators
    local egg = nil
    local eggIndex = nil
    for i, incubatorEgg in ipairs(playerData.EggsInIncubators) do
        if incubatorEgg.UniqueId == eggId then
            egg = incubatorEgg
            eggIndex = i
            break
        end
    end
    
    if not egg or not EggData.IsReadyToHatch(egg) then
        return false, "Egg is not ready to hatch"
    end
    
    -- Hatch the egg
    local dragon, message = EggData.HatchEgg(egg, luckyBonus)
    if not dragon then
        return false, message
    end
    
    -- Add to player's collection
    table.insert(playerData.Dragons, dragon)
    table.remove(playerData.EggsInIncubators, eggIndex)
    
    -- Update stats
    playerData.Stats.DragonsHatched = playerData.Stats.DragonsHatched + 1
    
    -- Update rarest dragon
    local rarityIndex = 1
    for i, rarityData in ipairs(Config.Rarities) do
        if rarityData.Name == dragon.Rarity then
            rarityIndex = i
            break
        end
    end
    
    local currentRarestIndex = 1
    for i, rarityData in ipairs(Config.Rarities) do
        if rarityData.Name == playerData.Stats.RarestDragon then
            currentRarestIndex = i
            break
        end
    end
    
    if rarityIndex > currentRarestIndex then
        playerData.Stats.RarestDragon = dragon.Rarity
    end
    
    DataStore.MarkDataDirty(player)
    
    -- Create dragon model in world
    local dragonModel = DragonManager.CreateDragonModel(dragon)
    if not DragonManager.ActiveDragons[player] then
        DragonManager.ActiveDragons[player] = {}
    end
    DragonManager.ActiveDragons[player][dragon.UniqueId] = dragonModel
    
    -- Notify client with effects
    DragonHatchedEvent:FireClient(player, dragon)
    
    -- Server announcement for rare dragons
    if dragon.Rarity == "Mythic" or dragon.Rarity == "Huge" then
        local announcement = string.format("🐉 %s just hatched a %s %s Dragon!", 
            player.Name, dragon.Rarity, dragon.Element)
        
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            -- Send to all players (you'd implement a proper announcement system)
            print(announcement) -- Placeholder
        end
    end
    
    print(player.Name .. " hatched a " .. DragonData.GetDisplayName(dragon))
    return true, "Dragon hatched successfully!"
end

-- Breeding system
function DragonManager.StartBreeding(player, dragon1Id, dragon2Id)
    local playerData = DataStore.GetPlayerData(player)
    if not playerData then return false, "Player data not found" end
    
    -- Find dragons
    local dragon1, dragon2 = nil, nil
    for _, dragon in ipairs(playerData.Dragons) do
        if dragon.UniqueId == dragon1Id then
            dragon1 = dragon
        elseif dragon.UniqueId == dragon2Id then
            dragon2 = dragon
        end
    end
    
    if not dragon1 or not dragon2 then
        return false, "Dragons not found"
    end
    
    -- Check if breeding is allowed
    local canBreed, reason = DragonData.CanBreed(dragon1, dragon2)
    if not canBreed then
        return false, reason
    end
    
    -- Check breeding altar
    if not playerData.Plot.HasBreedingAltar then
        return false, "Breeding altar required"
    end
    
    -- Start breeding process
    local breedingData = {
        Player = player,
        Dragon1 = dragon1,
        Dragon2 = dragon2,
        StartTime = tick(),
        CompletionTime = tick() + (4 * 60 * 60) -- 4 hours
    }
    
    table.insert(DragonManager.BreedingPairs, breedingData)
    
    dragon1.IsBreeding = true
    dragon2.IsBreeding = true
    DataStore.MarkDataDirty(player)
    
    BreedingStartedEvent:FireClient(player, dragon1, dragon2, 4 * 60 * 60)
    
    return true, "Breeding started - 4 hours remaining"
end

-- Check breeding completion
function DragonManager.CheckBreedingCompletion()
    local currentTime = tick()
    
    for i = #DragonManager.BreedingPairs, 1, -1 do
        local breeding = DragonManager.BreedingPairs[i]
        
        if currentTime >= breeding.CompletionTime then
            -- Breeding complete
            local baby, message = DragonData.BreedDragons(breeding.Dragon1, breeding.Dragon2)
            
            if baby then
                local playerData = DataStore.GetPlayerData(breeding.Player)
                if playerData then
                    table.insert(playerData.Dragons, baby)
                    playerData.Stats.DragonsBreed = playerData.Stats.DragonsBreed + 1
                    DataStore.MarkDataDirty(breeding.Player)
                    
                    -- Create model
                    if not DragonManager.ActiveDragons[breeding.Player] then
                        DragonManager.ActiveDragons[breeding.Player] = {}
                    end
                    
                    local babyModel = DragonManager.CreateDragonModel(baby)
                    DragonManager.ActiveDragons[breeding.Player][baby.UniqueId] = babyModel
                    
                    -- Notify player
                    DragonHatchedEvent:FireClient(breeding.Player, baby)
                    print(breeding.Player.Name .. " bred a " .. DragonData.GetDisplayName(baby))
                end
            end
            
            -- Reset breeding status
            breeding.Dragon1.IsBreeding = false
            breeding.Dragon2.IsBreeding = false
            
            -- Remove from breeding list
            table.remove(DragonManager.BreedingPairs, i)
        end
    end
end

-- Player cleanup
function DragonManager.OnPlayerRemoving(player)
    if DragonManager.ActiveDragons[player] then
        for dragonId, model in pairs(DragonManager.ActiveDragons[player]) do
            if model then
                model:Destroy()
            end
        end
        DragonManager.ActiveDragons[player] = nil
    end
    
    -- Remove from breeding pairs
    for i = #DragonManager.BreedingPairs, 1, -1 do
        if DragonManager.BreedingPairs[i].Player == player then
            table.remove(DragonManager.BreedingPairs, i)
        end
    end
end

-- Main update loop
spawn(function()
    while true do
        wait(60) -- Check every minute
        DragonManager.CheckBreedingCompletion()
    end
end)

-- Event connections
Players.PlayerRemoving:Connect(DragonManager.OnPlayerRemoving)

return DragonManager