-- ShopInteraction.client.lua - Shop proximity prompts and interactions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Shared.Utils)

-- Wait for RemoteFunctions
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Shop locations (these would normally be created by the world building system)
local shopLocations = {
    EggShop = {
        Position = Vector3.new(60, 0, -50),
        Name = "Egg Shop",
        Description = "Buy eggs to hatch dragons!"
    },
    ItemShop = {
        Position = Vector3.new(-60, 0, -50), 
        Name = "Item Shop",
        Description = "Potions and dragon food!"
    }
}

-- Create shop proximity prompts
local function createShopPrompt(shopType, position, name, description)
    -- Create invisible part for proximity prompt
    local promptPart = Instance.new("Part")
    promptPart.Name = shopType .. "Prompt"
    promptPart.Size = Vector3.new(8, 8, 8)
    promptPart.Position = position
    promptPart.Anchored = true
    promptPart.CanCollide = false
    promptPart.Transparency = 1
    promptPart.Parent = Workspace
    
    -- Create proximity prompt
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.ObjectText = name
    proximityPrompt.ActionText = "Open"
    proximityPrompt.HoldDuration = 0.5
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
    proximityPrompt.Parent = promptPart
    
    -- Add visual indicator (floating text)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 120, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = promptPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Config.UI.MainTheme.Primary
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboardGui
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0.4, 0)
    descLabel.Position = UDim2.new(0, 0, 0.6, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.Parent = billboardGui
    
    return proximityPrompt
end

-- Handle egg shop interaction
local function openEggShop()
    print("Opening Egg Shop...")
    
    -- Use MainUI API to show egg shop screen
    if _G.MainUI then
        _G.MainUI.ShowScreen("EggShop")
    else
        -- Fallback if MainUI not ready
        local PlayerGui = Player:WaitForChild("PlayerGui")
        local eggShopUI = PlayerGui:FindFirstChild("EggShopUI")
        if eggShopUI then
            eggShopUI.Visible = true
        end
    end
end

-- Handle item shop interaction  
local function openItemShop()
    print("Opening Item Shop...")
    
    -- Show notification that item shop is coming soon
    if _G.MainUI then
        _G.MainUI.ShowNotification("Item Shop coming soon!", Color3.new(1, 1, 0))
    else
        print("Item Shop coming soon!")
    end
end

-- Setup shop interactions
local function setupShopInteractions()
    -- Wait for character to spawn
    if not Player.Character then
        Player.CharacterAdded:Wait()
    end
    
    wait(3) -- Give time for world to load
    
    -- Create egg shop prompt
    local eggShopPrompt = createShopPrompt(
        "EggShop",
        shopLocations.EggShop.Position,
        shopLocations.EggShop.Name,
        shopLocations.EggShop.Description
    )
    
    eggShopPrompt.Triggered:Connect(function(player)
        if player == Player then
            openEggShop()
        end
    end)
    
    -- Create item shop prompt
    local itemShopPrompt = createShopPrompt(
        "ItemShop", 
        shopLocations.ItemShop.Position,
        shopLocations.ItemShop.Name,
        shopLocations.ItemShop.Description
    )
    
    itemShopPrompt.Triggered:Connect(function(player)
        if player == Player then
            openItemShop()
        end
    end)
    
    print("Shop interactions setup complete!")
end

-- Handle proximity prompt styling
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    -- Customize prompt appearance
    if prompt.Parent.Name:find("Shop") then
        prompt.Style = Enum.ProximityPromptStyle.Default
        -- Could add custom styling here
    end
end)

-- Setup quest board interaction (bonus)
local function setupQuestBoard()
    local questBoardPosition = Vector3.new(0, 0, -80)
    
    local questPrompt = createShopPrompt(
        "QuestBoard",
        questBoardPosition,
        "Quest Board",
        "Daily and weekly quests!"
    )
    
    questPrompt.Triggered:Connect(function(player)
        if player == Player then
            if _G.MainUI then
                _G.MainUI.ShowScreen("Quests")
            end
        end
    end)
end

-- Handle shop purchase confirmations
local function setupPurchaseHandling()
    -- Listen for purchase confirmations
    local buyEggFunction = RemoteFunctions:FindFirstChild("BuyEgg")
    if buyEggFunction then
        -- This will be called from the EggShopUI
        print("Purchase handling ready")
    end
end

-- Distance-based shop detection (for mobile users without proximity prompts)
local function setupDistanceDetection()
    spawn(function()
        while true do
            wait(1) -- Check every second
            
            if Player.Character and Player.Character.PrimaryPart then
                local playerPosition = Player.Character.PrimaryPart.Position
                
                -- Check distance to each shop
                for shopType, shopData in pairs(shopLocations) do
                    local distance = (playerPosition - shopData.Position).Magnitude
                    
                    -- Show notification when near shop
                    if distance < 15 and distance > 12 then
                        if _G.MainUI then
                            _G.MainUI.ShowNotification(
                                "Near " .. shopData.Name .. " - Tap E or walk closer!",
                                Config.UI.MainTheme.Primary
                            )
                        end
                    end
                end
            end
        end
    end)
end

-- Touch support for mobile
local function setupMobileSupport()
    local UserInputService = game:GetService("UserInputService")
    
    if UserInputService.TouchEnabled then
        -- Add touch buttons for nearby shops
        local PlayerGui = Player:WaitForChild("PlayerGui")
        local touchUI = Instance.new("ScreenGui")
        touchUI.Name = "TouchShopUI"
        touchUI.ResetOnSpawn = false
        touchUI.Parent = PlayerGui
        
        -- Shop buttons will be created dynamically when near shops
        -- This is a simplified implementation
    end
end

-- Main initialization
spawn(function()
    setupShopInteractions()
    setupQuestBoard()
    setupPurchaseHandling() 
    setupDistanceDetection()
    setupMobileSupport()
    
    print("ShopInteraction client loaded successfully!")
end)

-- Public API
_G.ShopInteraction = {
    OpenEggShop = openEggShop,
    OpenItemShop = openItemShop,
    GetShopLocations = function() return shopLocations end
}