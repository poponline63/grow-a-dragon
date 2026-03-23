-- MainHUD.gui.lua - Main heads-up display
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)

-- Create main HUD ScreenGui
local MainHUD = Instance.new("ScreenGui")
MainHUD.Name = "MainHUD"
MainHUD.ResetOnSpawn = false
MainHUD.IgnoreGuiInset = true
MainHUD.Parent = PlayerGui

-- Top Bar Container
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 60)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Config.UI.MainTheme.Background
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainHUD

-- Top bar gradient
local topBarGradient = Instance.new("UIGradient")
topBarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Config.UI.MainTheme.Background),
    ColorSequenceKeypoint.new(1, Config.UI.MainTheme.Background:Lerp(Color3.new(0, 0, 0), 0.3))
}
topBarGradient.Rotation = 90
topBarGradient.Parent = TopBar

-- Coins Display
local CoinFrame = Instance.new("Frame")
CoinFrame.Name = "CoinFrame"
CoinFrame.Size = UDim2.new(0, 120, 0, 40)
CoinFrame.Position = UDim2.new(0, 10, 0, 10)
CoinFrame.BackgroundColor3 = Color3.new(1, 0.8, 0)
CoinFrame.BorderSizePixel = 0
CoinFrame.Parent = TopBar

local coinFrameCorner = Instance.new("UICorner")
coinFrameCorner.CornerRadius = UDim.new(0, 20)
coinFrameCorner.Parent = CoinFrame

local CoinIcon = Instance.new("TextLabel")
CoinIcon.Size = UDim2.new(0, 30, 1, 0)
CoinIcon.Position = UDim2.new(0, 5, 0, 0)
CoinIcon.BackgroundTransparency = 1
CoinIcon.Text = "🪙"
CoinIcon.TextScaled = true
CoinIcon.Font = Enum.Font.SourceSansBold
CoinIcon.Parent = CoinFrame

local CoinsLabel = Instance.new("TextLabel")
CoinsLabel.Name = "CoinsLabel"
CoinsLabel.Size = UDim2.new(1, -35, 1, 0)
CoinsLabel.Position = UDim2.new(0, 35, 0, 0)
CoinsLabel.BackgroundTransparency = 1
CoinsLabel.Text = "0"
CoinsLabel.TextColor3 = Config.UI.MainTheme.Background
CoinsLabel.TextScaled = true
CoinsLabel.Font = Enum.Font.SourceSansBold
CoinsLabel.TextXAlignment = Enum.TextXAlignment.Left
CoinsLabel.Parent = CoinFrame

-- Gems Display
local GemFrame = Instance.new("Frame")
GemFrame.Name = "GemFrame"
GemFrame.Size = UDim2.new(0, 100, 0, 40)
GemFrame.Position = UDim2.new(0, 140, 0, 10)
GemFrame.BackgroundColor3 = Color3.new(0.6, 0.2, 1)
GemFrame.BorderSizePixel = 0
GemFrame.Parent = TopBar

local gemFrameCorner = Instance.new("UICorner")
gemFrameCorner.CornerRadius = UDim.new(0, 20)
gemFrameCorner.Parent = GemFrame

local GemIcon = Instance.new("TextLabel")
GemIcon.Size = UDim2.new(0, 30, 1, 0)
GemIcon.Position = UDim2.new(0, 5, 0, 0)
GemIcon.BackgroundTransparency = 1
GemIcon.Text = "💎"
GemIcon.TextScaled = true
GemIcon.Font = Enum.Font.SourceSansBold
GemIcon.Parent = GemFrame

local GemsLabel = Instance.new("TextLabel")
GemsLabel.Name = "GemsLabel"
GemsLabel.Size = UDim2.new(1, -35, 1, 0)
GemsLabel.Position = UDim2.new(0, 35, 0, 0)
GemsLabel.BackgroundTransparency = 1
GemsLabel.Text = "0"
GemsLabel.TextColor3 = Config.UI.MainTheme.Text
GemsLabel.TextScaled = true
GemsLabel.Font = Enum.Font.SourceSansBold
GemsLabel.TextXAlignment = Enum.TextXAlignment.Left
GemsLabel.Parent = GemFrame

-- Level and XP Display (Center)
local LevelFrame = Instance.new("Frame")
LevelFrame.Name = "LevelFrame"
LevelFrame.Size = UDim2.new(0, 200, 0, 40)
LevelFrame.Position = UDim2.new(0.5, -100, 0, 10)
LevelFrame.BackgroundColor3 = Config.UI.MainTheme.Primary
LevelFrame.BorderSizePixel = 0
LevelFrame.Parent = TopBar

local levelFrameCorner = Instance.new("UICorner")
levelFrameCorner.CornerRadius = UDim.new(0, 20)
levelFrameCorner.Parent = LevelFrame

local LevelLabel = Instance.new("TextLabel")
LevelLabel.Name = "LevelLabel"
LevelLabel.Size = UDim2.new(0, 80, 1, 0)
LevelLabel.Position = UDim2.new(0, 0, 0, 0)
LevelLabel.BackgroundTransparency = 1
LevelLabel.Text = "Level 1"
LevelLabel.TextColor3 = Config.UI.MainTheme.Text
LevelLabel.TextScaled = true
LevelLabel.Font = Enum.Font.SourceSansBold
LevelLabel.Parent = LevelFrame

-- XP Bar
local XPBar = Instance.new("Frame")
XPBar.Name = "XPBar"
XPBar.Size = UDim2.new(0, 110, 0, 20)
XPBar.Position = UDim2.new(0, 85, 0, 10)
XPBar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
XPBar.BorderSizePixel = 0
XPBar.Parent = LevelFrame

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(0, 10)
xpBarCorner.Parent = XPBar

local XPFill = Instance.new("Frame")
XPFill.Name = "Fill"
XPFill.Size = UDim2.new(0, 0, 1, 0)
XPFill.Position = UDim2.new(0, 0, 0, 0)
XPFill.BackgroundColor3 = Color3.new(0, 1, 0.5)
XPFill.BorderSizePixel = 0
XPFill.Parent = XPBar

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(0, 10)
xpFillCorner.Parent = XPFill

-- Settings Button (Right side)
local SettingsButton = Instance.new("TextButton")
SettingsButton.Name = "SettingsButton"
SettingsButton.Size = UDim2.new(0, 40, 0, 40)
SettingsButton.Position = UDim2.new(1, -50, 0, 10)
SettingsButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
SettingsButton.Text = "⚙️"
SettingsButton.TextScaled = true
SettingsButton.Font = Enum.Font.SourceSansBold
SettingsButton.BorderSizePixel = 0
SettingsButton.Parent = TopBar

local settingsButtonCorner = Instance.new("UICorner")
settingsButtonCorner.CornerRadius = UDim.new(0, 20)
settingsButtonCorner.Parent = SettingsButton

-- Bottom Bar Container
local BottomBar = Instance.new("Frame")
BottomBar.Name = "BottomBar"
BottomBar.Size = UDim2.new(1, 0, 0, 80)
BottomBar.Position = UDim2.new(0, 0, 1, -80)
BottomBar.BackgroundColor3 = Config.UI.MainTheme.Background
BottomBar.BackgroundTransparency = 0.2
BottomBar.BorderSizePixel = 0
BottomBar.Parent = MainHUD

-- Bottom bar gradient
local bottomBarGradient = Instance.new("UIGradient")
bottomBarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Config.UI.MainTheme.Background:Lerp(Color3.new(0, 0, 0), 0.3)),
    ColorSequenceKeypoint.new(1, Config.UI.MainTheme.Background)
}
bottomBarGradient.Rotation = 90
bottomBarGradient.Parent = BottomBar

-- Shop Button
local ShopButton = Instance.new("TextButton")
ShopButton.Name = "ShopButton"
ShopButton.Size = UDim2.new(0, 100, 0, 60)
ShopButton.Position = UDim2.new(0, 20, 0, 10)
ShopButton.BackgroundColor3 = Config.UI.MainTheme.Primary
ShopButton.Text = "🏪\nShop"
ShopButton.TextColor3 = Config.UI.MainTheme.Text
ShopButton.TextScaled = true
ShopButton.Font = Enum.Font.SourceSansBold
ShopButton.BorderSizePixel = 0
ShopButton.Parent = BottomBar

local shopButtonCorner = Instance.new("UICorner")
shopButtonCorner.CornerRadius = UDim.new(0, 15)
shopButtonCorner.Parent = ShopButton

-- Inventory Button
local InventoryButton = Instance.new("TextButton")
InventoryButton.Name = "InventoryButton"
InventoryButton.Size = UDim2.new(0, 100, 0, 60)
InventoryButton.Position = UDim2.new(0.5, -50, 0, 10)
InventoryButton.BackgroundColor3 = Config.UI.MainTheme.Secondary
InventoryButton.Text = "🎒\nDragons"
InventoryButton.TextColor3 = Config.UI.MainTheme.Text
InventoryButton.TextScaled = true
InventoryButton.Font = Enum.Font.SourceSansBold
InventoryButton.BorderSizePixel = 0
InventoryButton.Parent = BottomBar

local inventoryButtonCorner = Instance.new("UICorner")
inventoryButtonCorner.CornerRadius = UDim.new(0, 15)
inventoryButtonCorner.Parent = InventoryButton

-- Quests Button
local QuestsButton = Instance.new("TextButton")
QuestsButton.Name = "QuestsButton"
QuestsButton.Size = UDim2.new(0, 100, 0, 60)
QuestsButton.Position = UDim2.new(1, -120, 0, 10)
QuestsButton.BackgroundColor3 = Color3.new(1, 0.6, 0.2)
QuestsButton.Text = "📋\nQuests"
QuestsButton.TextColor3 = Config.UI.MainTheme.Text
QuestsButton.TextScaled = true
QuestsButton.Font = Enum.Font.SourceSansBold
QuestsButton.BorderSizePixel = 0
QuestsButton.Parent = BottomBar

local questsButtonCorner = Instance.new("UICorner")
questsButtonCorner.CornerRadius = UDim.new(0, 15)
questsButtonCorner.Parent = QuestsButton

-- Add button hover effects
local function addButtonHoverEffect(button)
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = originalSize + UDim2.new(0, 5, 0, 5),
                BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.2)
            }
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = originalSize,
                BackgroundColor3 = originalColor
            }
        ):Play()
    end)
end

-- Apply hover effects to all buttons
addButtonHoverEffect(ShopButton)
addButtonHoverEffect(InventoryButton) 
addButtonHoverEffect(QuestsButton)
addButtonHoverEffect(SettingsButton)

-- Animate HUD on spawn
local function animateHUDIn()
    -- Start with bars off-screen
    TopBar.Position = UDim2.new(0, 0, 0, -60)
    BottomBar.Position = UDim2.new(0, 0, 1, 80)
    
    -- Animate in
    TweenService:Create(TopBar,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()
    
    TweenService:Create(BottomBar,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 1, -80)}
    ):Play()
end

-- Start animation
spawn(function()
    wait(1) -- Let character spawn first
    animateHUDIn()
end)

print("MainHUD GUI created successfully!")