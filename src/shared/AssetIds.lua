--[[
    AssetIds.lua
    AI-generated textured 3D model asset IDs (Meshy.ai + Roblox Open Cloud).
    Use InsertService:LoadAsset(id) to load at runtime.
]]

local AssetIds = {}

--------------------------------------------------------------------------------
-- Egg Meshes (by rarity) - Fully textured
--------------------------------------------------------------------------------
AssetIds.Eggs = {
    Common    = 127964968816046,
    Uncommon  = 70608877034444,
    Rare      = 84466411421448,
    Epic      = 109855720262365,
    Legendary = 122955482520720,
    Mythic    = 84074502827707,
}

--------------------------------------------------------------------------------
-- Dragon Meshes (by element + stage) - Fully textured
--------------------------------------------------------------------------------
AssetIds.Dragons = {
    Fire = {
        Baby  = 138716756126773,
        Adult = 119521608504556,
    },
    Ice = {
        Baby  = 80150388506848,
        Adult = 122921300457083,
    },
    Nature = {
        Baby  = 129791654083720,
        Adult = 92242971841527,
    },
    Shadow = {
        Baby  = 76575116789523,
        Adult = 86667215810605,
    },
    Light = {
        Baby  = 123254147621309,
        Adult = 109211170634151,
    },
    Storm = {
        Baby  = 135996031408802,
        Adult = 131145879406286,
    },
}

--------------------------------------------------------------------------------
-- Building Meshes - Fully textured
--------------------------------------------------------------------------------
AssetIds.Buildings = {
    EggShop          = 80705828442376,
    ItemShop         = 126309892274856,
    QuestBoard       = 100444992269466,
    BreedingStation  = 113186714537172,
}

--------------------------------------------------------------------------------
-- Environment Props - Fully textured
--------------------------------------------------------------------------------
AssetIds.Environment = {
    SpawnPlatform  = 87333294416943,
    DragonStatue   = 84797668086551,
    Torch          = 114306092016821,
    CrystalCluster = 105855587107379,
    FantasyTree    = 72561076646198,
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
function AssetIds.GetEggAsset(eggName)
    local rarity = eggName:match("^(%w+)%s+Egg")
    if rarity and AssetIds.Eggs[rarity] then
        return AssetIds.Eggs[rarity]
    end
    return AssetIds.Eggs.Common
end

function AssetIds.GetDragonAsset(element, stage)
    local elementAssets = AssetIds.Dragons[element]
    if not elementAssets then
        elementAssets = AssetIds.Dragons.Fire
    end
    local meshStage = "Adult"
    if stage == "Baby" or stage == "Juvenile" then
        meshStage = "Baby"
    end
    return elementAssets[meshStage] or elementAssets.Adult
end

return AssetIds
