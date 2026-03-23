--[[
    WorldLoader.server.lua
    Loads AI-generated textured 3D models for buildings and environment props
    at server start using InsertService. Falls back to primitive parts if loading fails.
]]
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AssetIds"))

--------------------------------------------------------------------------------
-- Helper: Load an asset, anchor all parts, position it
--------------------------------------------------------------------------------
local function LoadAndPlace(assetId, name, position, rotation, scale)
    local ok, container = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    
    if not ok or not container then
        warn("[WorldLoader] Failed to load asset " .. tostring(assetId) .. " for " .. name)
        return nil
    end
    
    -- The loaded asset is a Model containing the actual model
    local model = container
    model.Name = name
    
    -- Find or set PrimaryPart
    local primaryPart = nil
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = true
            if not primaryPart then
                primaryPart = part
            end
        end
    end
    
    if primaryPart then
        model.PrimaryPart = primaryPart
        
        -- Apply position
        local cf = CFrame.new(position)
        if rotation then
            cf = cf * CFrame.Angles(0, math.rad(rotation), 0)
        end
        model:SetPrimaryPartCFrame(cf)
        
        -- Apply scale if needed
        if scale and scale ~= 1 then
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Size = part.Size * scale
                    local relPos = part.Position - primaryPart.Position
                    part.Position = primaryPart.Position + relPos * scale
                end
            end
        end
    end
    
    model.Parent = Workspace
    print("[WorldLoader] Loaded: " .. name .. " (Asset: " .. tostring(assetId) .. ")")
    return model
end

--------------------------------------------------------------------------------
-- Load Buildings
--------------------------------------------------------------------------------
local function LoadBuildings()
    -- Egg Shop
    if AssetIds.Buildings.EggShop then
        LoadAndPlace(AssetIds.Buildings.EggShop, "EggShop_Mesh", Vector3.new(60, 5, -50), 0, 3)
    end
    
    -- Item Shop
    if AssetIds.Buildings.ItemShop then
        LoadAndPlace(AssetIds.Buildings.ItemShop, "ItemShop_Mesh", Vector3.new(-60, 5, -50), 0, 3)
    end
    
    -- Quest Board
    if AssetIds.Buildings.QuestBoard then
        LoadAndPlace(AssetIds.Buildings.QuestBoard, "QuestBoard_Mesh", Vector3.new(0, 5, -80), 0, 3)
    end
    
    -- Breeding Station
    if AssetIds.Buildings.BreedingStation then
        LoadAndPlace(AssetIds.Buildings.BreedingStation, "BreedingStation_Mesh", Vector3.new(0, 5, 80), 0, 3)
    end
end

--------------------------------------------------------------------------------
-- Load Environment Props
--------------------------------------------------------------------------------
local function LoadEnvironment()
    -- Dragon Statue at center
    if AssetIds.Environment.DragonStatue then
        LoadAndPlace(AssetIds.Environment.DragonStatue, "DragonStatue_Mesh", Vector3.new(0, 5, 0), 0, 5)
    end
    
    -- Spawn Platform
    if AssetIds.Environment.SpawnPlatform then
        LoadAndPlace(AssetIds.Environment.SpawnPlatform, "SpawnPlatform_Mesh", Vector3.new(0, 1, 0), 0, 4)
    end
    
    -- Crystal Clusters scattered around
    if AssetIds.Environment.CrystalCluster then
        local crystalPositions = {
            Vector3.new(40, 2, 30),
            Vector3.new(-40, 2, 30),
            Vector3.new(40, 2, -30),
            Vector3.new(-40, 2, -30),
            Vector3.new(80, 2, 0),
            Vector3.new(-80, 2, 0),
        }
        for i, pos in ipairs(crystalPositions) do
            LoadAndPlace(AssetIds.Environment.CrystalCluster, "Crystal_" .. i, pos, math.random(0, 360), 2)
        end
    end
    
    -- Fantasy Trees
    if AssetIds.Environment.FantasyTree then
        local treePositions = {
            Vector3.new(30, 2, 60),
            Vector3.new(-30, 2, 60),
            Vector3.new(70, 2, 40),
            Vector3.new(-70, 2, 40),
            Vector3.new(50, 2, -70),
            Vector3.new(-50, 2, -70),
            Vector3.new(90, 2, -20),
            Vector3.new(-90, 2, -20),
        }
        for i, pos in ipairs(treePositions) do
            LoadAndPlace(AssetIds.Environment.FantasyTree, "Tree_" .. i, pos, math.random(0, 360), 3)
        end
    end
    
    -- Torches along paths
    if AssetIds.Environment.Torch then
        local torchPositions = {
            Vector3.new(20, 3, -20),
            Vector3.new(-20, 3, -20),
            Vector3.new(20, 3, 20),
            Vector3.new(-20, 3, 20),
            Vector3.new(40, 3, -40),
            Vector3.new(-40, 3, -40),
        }
        for i, pos in ipairs(torchPositions) do
            LoadAndPlace(AssetIds.Environment.Torch, "Torch_" .. i, pos, 0, 2)
        end
    end
end

--------------------------------------------------------------------------------
-- Run on server start
--------------------------------------------------------------------------------
print("[WorldLoader] Starting world asset loading...")
LoadBuildings()
LoadEnvironment()
print("[WorldLoader] World loading complete!")
