--[[
    MainHUD.gui.lua
    Main UI overlay with bottom bar and side HUD for V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Config = require(ReplicatedStorage.Shared.Config)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MainHUD = {}
MainHUD.CurrentScreen = "None"
MainHUD.UIElements = {}

-- Create main screen GUI
function MainHUD.CreateMainHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
    
    MainHUD.UIElements.ScreenGui = screenGui
    MainHUD.UIElements.MainFrame = mainFrame
    
    -- Create UI components
    MainHUD.CreateBottomBar()
    MainHUD.CreateSideHUD()
    MainHUD.CreateNotificationArea()
    
    return screenGui
end

-- Create bottom navigation bar
function MainHUD.CreateBottomBar()
    local mainFrame = MainHUD.UIElements.MainFrame
    
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, Config.UI.BottomBarHeight)
    bottomBar.Position = UDim2.new(0, 0, 1, -Config.UI.BottomBarHeight)
    bottomBar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.15, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.15))
    }
    gradient.Rotation = 90
    gradient.Parent = bottomBar
    
    -- Add border
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(1, 0, 0, 2)
    border.Position = UDim2.new(0, 0, 0, 0)
    border.BackgroundColor3 = Color3.new(0.8, 0.6, 0.2)
    border.BorderSizePixel = 0
    border.Parent = bottomBar
    
    -- Button configuration
    local buttons = {
        {Name = "Inventory", Icon = "🎒", Screen = "Inventory"},
        {Name = "Codes", Icon = "🎁", Screen = "Codes"},
        {Name = "Quests", Icon = "📋", Screen = "Quests"},
        {Name = "Shop", Icon = "🏪", Screen = "Shop"}, 
        {Name = "Settings", Icon = "⚙️", Screen = "Settings"}
    }
    
    -- Create buttons
    for i, buttonData in ipairs(buttons) do
        local button = MainHUD.CreateBottomBarButton(buttonData, i, #buttons)
        button.Parent = bottomBar
    end
    
    MainHUD.UIElements.BottomBar = bottomBar
end

-- Create individual bottom bar button
function MainHUD.CreateBottomBarButton(buttonData, index, totalButtons)
    local buttonSize = 1 / totalButtons
    local button = Instance.new("TextButton")
    button.Name = buttonData.Name .. "Button"
    button.Size = UDim2.new(buttonSize, -10, 0.8, 0)
    button.Position = UDim2.new(buttonSize * (index - 1), 5, 0.1, 0)
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Icon label
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(1, 0, 0.6, 0)
    iconLabel.Position = UDim2.new(0, 0, 0.05, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = buttonData.Icon
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = button
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Label"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.65, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = buttonData.Name
    nameLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.Parent = button
    
    -- Button animation and functionality
    button.MouseEnter:Connect(function()
        MainHUD.AnimateButtonHover(button, true)
    end)
    
    button.MouseLeave:Connect(function()
        MainHUD.AnimateButtonHover(button, false)
    end)
    
    button.MouseButton1Click:Connect(function()
        MainHUD.OnBottomBarButtonClicked(buttonData.Screen, button)
    end)
    
    return button
end

-- Create side HUD for currency and stats
function MainHUD.CreateSideHUD()
    local mainFrame = MainHUD.UIElements.MainFrame
    
    local sideHUD = Instance.new("Frame")
    sideHUD.Name = "SideHUD" 
    sideHUD.Size = UDim2.new(0, Config.UI.SideHUDWidth, 0, 200)
    sideHUD.Position = UDim2.new(0, 10, 0, 10)
    sideHUD.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    sideHUD.BorderSizePixel = 0
    sideHUD.Parent = mainFrame
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = sideHUD
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.15, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.15))
    }
    gradient.Rotation = 135
    gradient.Parent = sideHUD
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 5)
    layout.Parent = sideHUD
    
    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingAll = UDim.new(0, 10)
    padding.Parent = sideHUD
    
    -- Currency displays
    local coinsDisplay = MainHUD.CreateCurrencyDisplay("Coins", "💰", "0")
    coinsDisplay.Parent = sideHUD
    
    local essenceDisplay = MainHUD.CreateCurrencyDisplay("Essence", "✨", "0") 
    essenceDisplay.Parent = sideHUD
    
    -- Level display
    local levelDisplay = MainHUD.CreateLevelDisplay()
    levelDisplay.Parent = sideHUD
    
    MainHUD.UIElements.SideHUD = sideHUD
    MainHUD.UIElements.CoinsDisplay = coinsDisplay
    MainHUD.UIElements.EssenceDisplay = essenceDisplay
    MainHUD.UIElements.LevelDisplay = levelDisplay
end

-- Create currency display element
function MainHUD.CreateCurrencyDisplay(name, icon, amount)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Display"
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 25, 1, 0)
    iconLabel.Position = UDim2.new(0, 5, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = frame
    
    -- Amount
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "Amount"
    amountLabel.Size = UDim2.new(1, -35, 1, 0)
    amountLabel.Position = UDim2.new(0, 30, 0, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = amount
    amountLabel.TextColor3 = Color3.new(1, 1, 1)
    amountLabel.TextScaled = true
    amountLabel.Font = Enum.Font.SourceSans
    amountLabel.TextXAlignment = Enum.TextXAlignment.Right
    amountLabel.Parent = frame
    
    return frame
end

-- Create level display with XP bar
function MainHUD.CreateLevelDisplay()
    local frame = Instance.new("Frame")
    frame.Name = "LevelDisplay"
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    -- Level text
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "Level"
    levelLabel.Size = UDim2.new(1, 0, 0.6, 0)
    levelLabel.Position = UDim2.new(0, 0, 0, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level 1"
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSansBold
    levelLabel.Parent = frame
    
    -- XP bar background
    local xpBarBG = Instance.new("Frame")
    xpBarBG.Name = "XPBarBG"
    xpBarBG.Size = UDim2.new(0.9, 0, 0.25, 0)
    xpBarBG.Position = UDim2.new(0.05, 0, 0.7, 0)
    xpBarBG.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    xpBarBG.BorderSizePixel = 0
    xpBarBG.Parent = frame
    
    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0, 4)
    xpBarCorner.Parent = xpBarBG
    
    -- XP bar fill
    local xpBarFill = Instance.new("Frame")
    xpBarFill.Name = "XPBarFill"
    xpBarFill.Size = UDim2.new(0.3, 0, 1, 0)
    xpBarFill.Position = UDim2.new(0, 0, 0, 0)
    xpBarFill.BackgroundColor3 = Color3.new(0.2, 0.8, 1)
    xpBarFill.BorderSizePixel = 0
    xpBarFill.Parent = xpBarBG
    
    local xpFillCorner = Instance.new("UICorner")
    xpFillCorner.CornerRadius = UDim.new(0, 4)
    xpFillCorner.Parent = xpBarFill
    
    return frame
end

-- Create notification area
function MainHUD.CreateNotificationArea()
    local mainFrame = MainHUD.UIElements.MainFrame
    
    local notificationArea = Instance.new("Frame")
    notificationArea.Name = "NotificationArea"
    notificationArea.Size = UDim2.new(0, 300, 0, 100)
    notificationArea.Position = UDim2.new(1, -320, 0, 20)
    notificationArea.BackgroundTransparency = 1
    notificationArea.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 10)
    layout.Parent = notificationArea
    
    MainHUD.UIElements.NotificationArea = notificationArea
end

-- Button hover animation
function MainHUD.AnimateButtonHover(button, isHovering)
    local targetColor = isHovering and Color3.new(0.3, 0.3, 0.35) or Color3.new(0.2, 0.2, 0.25)
    local targetSize = isHovering and UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0.85, 0) or UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0.8, 0)
    
    local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        BackgroundColor3 = targetColor,
        Size = targetSize
    })
    tween:Play()
end

-- Handle bottom bar button clicks
function MainHUD.OnBottomBarButtonClicked(screenName, button)
    -- Visual feedback
    local originalSize = button.Size
    local shrinkTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0.75, 0)
    })
    shrinkTween:Play()
    
    shrinkTween.Completed:Connect(function()
        local expandTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = originalSize
        })
        expandTween:Play()
    end)
    
    -- Handle screen switching
    MainHUD.SwitchToScreen(screenName)
    
    -- Play click sound
    MainHUD.PlaySound("rbxassetid://131961136") -- Placeholder sound ID
end

-- Switch between screens
function MainHUD.SwitchToScreen(screenName)
    if MainHUD.CurrentScreen == screenName then
        -- Close current screen
        MainHUD.CloseCurrentScreen()
        return
    end
    
    -- Close current screen first
    MainHUD.CloseCurrentScreen()
    
    -- Open new screen
    MainHUD.CurrentScreen = screenName
    
    if screenName == "Inventory" then
        require(script.Parent.InventoryUI).Show()
    elseif screenName == "Quests" then
        require(script.Parent.QuestUI).Show()
    elseif screenName == "Shop" then
        require(script.Parent.EggShopUI).Show()
    elseif screenName == "Settings" then
        -- Create settings screen
        MainHUD.ShowSettings()
    end
end

-- Close current screen
function MainHUD.CloseCurrentScreen()
    if MainHUD.CurrentScreen == "None" then return end
    
    if MainHUD.CurrentScreen == "Inventory" then
        require(script.Parent.InventoryUI).Hide()
    elseif MainHUD.CurrentScreen == "Quests" then
        require(script.Parent.QuestUI).Hide() 
    elseif MainHUD.CurrentScreen == "Shop" then
        require(script.Parent.EggShopUI).Hide()
    elseif MainHUD.CurrentScreen == "Settings" then
        MainHUD.HideSettings()
    end
    
    MainHUD.CurrentScreen = "None"
end

-- Update currency displays
function MainHUD.UpdateCurrencyDisplay(currencyType, amount)
    local display = MainHUD.UIElements[currencyType .. "Display"]
    if display then
        local amountLabel = display:FindFirstChild("Amount")
        if amountLabel then
            amountLabel.Text = MainHUD.FormatNumber(amount)
        end
    end
end

-- Update level display
function MainHUD.UpdateLevelDisplay(level, xp, maxXP)
    local levelDisplay = MainHUD.UIElements.LevelDisplay
    if levelDisplay then
        local levelLabel = levelDisplay:FindFirstChild("Level")
        local xpBarFill = levelDisplay:FindFirstChild("XPBarBG"):FindFirstChild("XPBarFill")
        
        if levelLabel then
            levelLabel.Text = "Level " .. tostring(level)
        end
        
        if xpBarFill then
            local xpPercent = math.min(xp / maxXP, 1)
            local tween = TweenService:Create(xpBarFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                Size = UDim2.new(xpPercent, 0, 1, 0)
            })
            tween:Play()
        end
    end
end

-- Format large numbers
function MainHUD.FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

-- Show notification
function MainHUD.ShowNotification(text, color, duration)
    local notificationArea = MainHUD.UIElements.NotificationArea
    if not notificationArea then return end
    
    duration = duration or 3
    color = color or Color3.new(1, 1, 1)
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 40)
    notification.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    notification.BorderSizePixel = 0
    notification.BackgroundTransparency = 1
    notification.Parent = notificationArea
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = notification
    
    -- Animate in
    local showTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        BackgroundTransparency = 0.2
    })
    showTween:Play()
    
    -- Auto-hide
    spawn(function()
        wait(duration)
        local hideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        })
        hideTween:Play()
        hideTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

-- Play sound effect
function MainHUD.PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Settings screen
function MainHUD.ShowSettings()
    -- Create settings modal
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    settingsFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    settingsFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = MainHUD.UIElements.MainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = settingsFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = settingsFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = settingsFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        MainHUD.HideSettings()
    end)
    
    MainHUD.UIElements.SettingsFrame = settingsFrame
end

function MainHUD.HideSettings()
    local settingsFrame = MainHUD.UIElements.SettingsFrame
    if settingsFrame then
        settingsFrame:Destroy()
        MainHUD.UIElements.SettingsFrame = nil
    end
end

-- Initialize HUD
function MainHUD.Initialize()
    local screenGui = MainHUD.CreateMainHUD()
    
    -- Listen for remote events to update displays
    ReplicatedStorage.RemoteEvents.PlayerDataUpdated.Event:Connect(function(data)
        MainHUD.UpdateCurrencyDisplay("Coins", data.Coins)
        MainHUD.UpdateCurrencyDisplay("Essence", data.Essence)
        MainHUD.UpdateLevelDisplay(data.Level, data.XP, data.Level * 100)
    end)
    
    print("Main HUD initialized")
    return screenGui
end

-- Start the HUD
return MainHUD.Initialize()