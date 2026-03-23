-- MainUI.client.lua - Main UI controller for client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Shared.Utils)

-- Wait for RemoteFunctions and RemoteEvents
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- UI State
local currentScreen = nil
local playerStats = {
    Coins = 0,
    Gems = 0,
    Level = 1,
    XP = 0,
    NextLevelXP = 1000,
    Progress = 0
}

-- UI References (will be set when GUI loads)
local MainHUD = nil
local screenGuis = {}

-- Tween settings for smooth animations
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fastTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Initialize UI
local function initializeUI()
    -- Wait for all GUI elements to load
    repeat wait() until PlayerGui:FindFirstChild("MainHUD")
    
    MainHUD = PlayerGui.MainHUD
    
    -- Initialize screen references
    screenGuis.EggShop = PlayerGui:WaitForChild("EggShopUI")
    screenGuis.Inventory = PlayerGui:WaitForChild("InventoryUI") 
    screenGuis.Quests = PlayerGui:WaitForChild("QuestUI")
    screenGuis.Hatch = PlayerGui:WaitForChild("HatchUI")
    
    print("UI initialized successfully!")
end

-- Update currency display
local function updateCurrencyDisplay(coins, gems)
    if not MainHUD then return end
    
    local coinsLabel = MainHUD.TopBar:FindFirstChild("CoinsLabel")
    local gemsLabel = MainHUD.TopBar:FindFirstChild("GemsLabel")
    
    if coinsLabel then
        coinsLabel.Text = Utils.FormatNumber(coins)
        
        -- Animate coin changes
        local tween = TweenService:Create(coinsLabel, fastTweenInfo, {
            TextColor3 = Color3.new(0, 1, 0) -- Green flash
        })
        tween:Play()
        tween.Completed:Connect(function()
            local resetTween = TweenService:Create(coinsLabel, fastTweenInfo, {
                TextColor3 = Color3.new(1, 1, 1) -- Back to white
            })
            resetTween:Play()
        end)
    end
    
    if gemsLabel then
        gemsLabel.Text = Utils.FormatNumber(gems)
    end
    
    playerStats.Coins = coins
    playerStats.Gems = gems
end

-- Update XP and level display
local function updateXPDisplay(xp, level, nextLevelXP, progress)
    if not MainHUD then return end
    
    local levelLabel = MainHUD.TopBar:FindFirstChild("LevelLabel")
    local xpBar = MainHUD.TopBar:FindFirstChild("XPBar")
    local xpFill = xpBar and xpBar:FindFirstChild("Fill")
    
    if levelLabel then
        levelLabel.Text = "Level " .. level
    end
    
    if xpFill then
        -- Animate XP bar
        local tween = TweenService:Create(xpFill, tweenInfo, {
            Size = UDim2.new(progress, 0, 1, 0)
        })
        tween:Play()
    end
    
    playerStats.XP = xp
    playerStats.Level = level
    playerStats.NextLevelXP = nextLevelXP
    playerStats.Progress = progress
end

-- Show notification
local function showNotification(message, color)
    if not MainHUD then return end
    
    color = color or Config.UI.MainTheme.Text
    
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 250, 0, 50)
    notification.Position = UDim2.new(0.5, -125, 0, -60) -- Start above screen
    notification.BackgroundColor3 = Config.UI.MainTheme.Background
    notification.BorderSizePixel = 0
    notification.Parent = MainHUD
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Add text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = notification
    
    -- Animate in
    local slideIn = TweenService:Create(notification, tweenInfo, {
        Position = UDim2.new(0.5, -125, 0, 20)
    })
    slideIn:Play()
    
    -- Animate out after delay
    wait(2)
    local slideOut = TweenService:Create(notification, tweenInfo, {
        Position = UDim2.new(0.5, -125, 0, -60),
        BackgroundTransparency = 1
    })
    slideOut:Play()
    
    slideOut.Completed:Connect(function()
        notification:Destroy()
    end)
end

-- Screen management
local function showScreen(screenName)
    local screen = screenGuis[screenName]
    if not screen then
        warn("Screen not found: " .. screenName)
        return
    end
    
    -- Hide current screen
    if currentScreen and screenGuis[currentScreen] then
        local hideScreen = screenGuis[currentScreen]
        local hideTween = TweenService:Create(hideScreen, tweenInfo, {
            Position = UDim2.new(0.5, 0, -1.5, 0), -- Slide up
            BackgroundTransparency = 1
        })
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            hideScreen.Visible = false
        end)
    end
    
    -- Show new screen
    screen.Visible = true
    screen.Position = UDim2.new(0.5, 0, 1.5, 0) -- Start below screen
    screen.BackgroundTransparency = 1
    
    local showTween = TweenService:Create(screen, tweenInfo, {
        Position = UDim2.new(0.5, 0, 0.5, 0), -- Center
        BackgroundTransparency = 0
    })
    showTween:Play()
    
    currentScreen = screenName
end

local function hideCurrentScreen()
    if not currentScreen or not screenGuis[currentScreen] then
        return
    end
    
    local screen = screenGuis[currentScreen]
    local hideTween = TweenService:Create(screen, tweenInfo, {
        Position = UDim2.new(0.5, 0, -1.5, 0),
        BackgroundTransparency = 1
    })
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        screen.Visible = false
    end)
    
    currentScreen = nil
end

-- Button click effects
local function addButtonEffect(button)
    local originalSize = button.Size
    
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(button, fastTweenInfo, {
            Size = originalSize + UDim2.new(0, 5, 0, 5),
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.1)
        })
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(button, fastTweenInfo, {
            Size = originalSize,
            BackgroundColor3 = button.BackgroundColor3
        })
        leaveTween:Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Click animation
        local clickTween = TweenService:Create(button, fastTweenInfo, {
            Size = originalSize - UDim2.new(0, 3, 0, 3)
        })
        clickTween:Play()
        
        clickTween.Completed:Connect(function()
            local returnTween = TweenService:Create(button, fastTweenInfo, {
                Size = originalSize
            })
            returnTween:Play()
        end)
    end)
end

-- Click for coins functionality
local function setupClickForCoins()
    if not MainHUD then return end
    
    -- Add click detector to main area (excluding UI elements)
    local clickFrame = Instance.new("Frame")
    clickFrame.Size = UDim2.new(1, 0, 1, 0)
    clickFrame.Position = UDim2.new(0, 0, 0, 0)
    clickFrame.BackgroundTransparency = 1
    clickFrame.ZIndex = -1 -- Behind other UI elements
    clickFrame.Parent = MainHUD
    
    clickFrame.MouseButton1Click:Connect(function()
        local clickForCoins = RemoteFunctions:FindFirstChild("ClickForCoins")
        if clickForCoins then
            local result = clickForCoins:InvokeServer()
            if result and result.success then
                showNotification(result.message, Color3.new(1, 1, 0)) -- Yellow coins
            end
        end
    end)
end

-- Setup button connections
local function setupButtons()
    if not MainHUD then return end
    
    -- Shop button
    local shopButton = MainHUD.BottomBar:FindFirstChild("ShopButton")
    if shopButton then
        addButtonEffect(shopButton)
        shopButton.MouseButton1Click:Connect(function()
            showScreen("EggShop")
        end)
    end
    
    -- Inventory button
    local inventoryButton = MainHUD.BottomBar:FindFirstChild("InventoryButton")
    if inventoryButton then
        addButtonEffect(inventoryButton)
        inventoryButton.MouseButton1Click:Connect(function()
            showScreen("Inventory")
        end)
    end
    
    -- Quests button
    local questsButton = MainHUD.BottomBar:FindFirstChild("QuestsButton")
    if questsButton then
        addButtonEffect(questsButton)
        questsButton.MouseButton1Click:Connect(function()
            showScreen("Quests")
        end)
    end
    
    -- Settings button
    local settingsButton = MainHUD.TopBar:FindFirstChild("SettingsButton")
    if settingsButton then
        addButtonEffect(settingsButton)
        settingsButton.MouseButton1Click:Connect(function()
            -- TODO: Add settings screen
            showNotification("Settings coming soon!", Color3.new(1, 1, 1))
        end)
    end
end

-- Handle remote events
local function setupRemoteEvents()
    -- Currency updates
    local updateCurrency = RemoteEvents:FindFirstChild("UpdateCurrency")
    if updateCurrency then
        updateCurrency.OnClientEvent:Connect(function(coins, gems)
            updateCurrencyDisplay(coins, gems)
        end)
    end
    
    -- XP updates
    local updateXP = RemoteEvents:FindFirstChild("UpdateXP")
    if updateXP then
        updateXP.OnClientEvent:Connect(function(xp, level)
            local stats = RemoteFunctions.GetPlayerStats:InvokeServer()
            if stats then
                updateXPDisplay(stats.XP, stats.Level, stats.NextLevelXP, stats.Progress)
            end
        end)
    end
    
    -- Level up celebration
    local levelUp = RemoteEvents:FindFirstChild("LevelUp")
    if levelUp then
        levelUp.OnClientEvent:Connect(function(newLevel)
            showNotification("LEVEL UP! Level " .. newLevel, Color3.new(1, 1, 0))
            
            -- TODO: Add level up effects (particles, sound, etc.)
        end)
    end
    
    -- Egg purchased
    local eggPurchased = RemoteEvents:FindFirstChild("EggPurchased")
    if eggPurchased then
        eggPurchased.OnClientEvent:Connect(function(egg)
            showNotification("Egg purchased! Check your plot!", Color3.new(0, 1, 0))
        end)
    end
    
    -- Dragon hatched
    local dragonHatched = RemoteEvents:FindFirstChild("DragonHatched")
    if dragonHatched then
        dragonHatched.OnClientEvent:Connect(function(dragon)
            showScreen("Hatch")
            -- The HatchUI will handle the dragon display
        end)
    end
    
    -- Quest completed
    local questCompleted = RemoteEvents:FindFirstChild("QuestCompleted")
    if questCompleted then
        questCompleted.OnClientEvent:Connect(function(quests)
            for _, questData in pairs(quests) do
                local message = questData.Type .. " quest completed!"
                showNotification(message, Color3.new(0, 1, 0))
            end
        end)
    end
end

-- Handle screen closing (ESC key)
local function setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            if currentScreen then
                hideCurrentScreen()
            end
        end
    end)
end

-- Get initial player stats
local function loadInitialStats()
    local getStats = RemoteFunctions:FindFirstChild("GetPlayerStats")
    if getStats then
        local stats = getStats:InvokeServer()
        if stats then
            updateCurrencyDisplay(stats.Coins, stats.Gems)
            updateXPDisplay(stats.XP, stats.Level, stats.NextLevelXP, stats.Progress)
        end
    end
end

-- Main initialization
spawn(function()
    -- Wait for character to spawn
    if not Player.Character then
        Player.CharacterAdded:Wait()
    end
    
    wait(2) -- Give time for everything to load
    
    initializeUI()
    setupButtons()
    setupRemoteEvents()
    setupInputHandling()
    setupClickForCoins()
    loadInitialStats()
    
    print("MainUI client loaded successfully!")
end)

-- Public API for other scripts
_G.MainUI = {
    ShowScreen = showScreen,
    HideScreen = hideCurrentScreen,
    ShowNotification = showNotification,
    UpdateCurrency = updateCurrencyDisplay,
    UpdateXP = updateXPDisplay,
    GetCurrentScreen = function() return currentScreen end,
    GetPlayerStats = function() return playerStats end
}