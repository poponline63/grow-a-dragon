-- EggShopUI.gui.lua - Egg shop interface
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local EggData = require(ReplicatedStorage.Shared.EggData)

-- Wait for RemoteFunctions
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Create Egg Shop ScreenGui
local EggShopUI = Instance.new("ScreenGui")
EggShopUI.Name = "EggShopUI"
EggShopUI.ResetOnSpawn = false
EggShopUI.Enabled = true
EggShopUI.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 500)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
MainFrame.BackgroundColor3 = Config.UI.MainTheme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = EggShopUI

-- Round corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = MainFrame

-- Background gradient
local backgroundGradient = Instance.new("UIGradient")
backgroundGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Config.UI.MainTheme.Background),
    ColorSequenceKeypoint.new(1, Config.UI.MainTheme.Background:Lerp(Config.UI.MainTheme.Primary, 0.1))
}
backgroundGradient.Rotation = 45
backgroundGradient.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Config.UI.MainTheme.Primary
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = Header

-- Header title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥚 Egg Shop"
Title.TextColor3 = Config.UI.MainTheme.Text
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -50, 0, 10)
CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Config.UI.MainTheme.Text
CloseButton.TextScaled = true
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.BorderSizePixel = 0
CloseButton.Parent = Header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 20)
closeCorner.Parent = CloseButton

-- Scroll Frame for egg cards
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -40, 1, -120)
ScrollFrame.Position = UDim2.new(0, 20, 0, 80)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.ScrollBarImageColor3 = Config.UI.MainTheme.Primary
ScrollFrame.Parent = MainFrame

-- Grid Layout for egg cards
local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0, 170, 0, 200)
GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.Parent = ScrollFrame

-- Function to create egg card
local function createEggCard(eggTier, layoutOrder)
    local tierData = EggData:GetTier(eggTier)
    if not tierData then return end
    
    -- Card Frame
    local Card = Instance.new("Frame")
    Card.Name = eggTier .. "Card"
    Card.Size = UDim2.new(1, 0, 1, 0)
    Card.BackgroundColor3 = Color3.new(1, 1, 1)
    Card.BorderSizePixel = 0
    Card.LayoutOrder = layoutOrder
    Card.Parent = ScrollFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 15)
    cardCorner.Parent = Card
    
    -- Card gradient
    local cardGradient = Instance.new("UIGradient")
    cardGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.95, 0.95, 0.95)),
        ColorSequenceKeypoint.new(1, Color3.new(0.85, 0.85, 0.85))
    }
    cardGradient.Rotation = 90
    cardGradient.Parent = Card
    
    -- Egg Image/Icon
    local EggIcon = Instance.new("Frame")
    EggIcon.Size = UDim2.new(0, 80, 0, 100)
    EggIcon.Position = UDim2.new(0.5, -40, 0, 10)
    EggIcon.BackgroundColor3 = tierData.Color
    EggIcon.BorderSizePixel = 0
    EggIcon.Parent = Card
    
    local eggCorner = Instance.new("UICorner")
    eggCorner.CornerRadius = UDim.new(0.5, 0)
    eggCorner.Parent = EggIcon
    
    -- Add sparkle effect
    local sparkleLabel = Instance.new("TextLabel")
    sparkleLabel.Size = UDim2.new(1, 0, 1, 0)
    sparkleLabel.BackgroundTransparency = 1
    sparkleLabel.Text = "✨"
    sparkleLabel.TextColor3 = Color3.new(1, 1, 1)
    sparkleLabel.TextScaled = true
    sparkleLabel.Font = Enum.Font.SourceSans
    sparkleLabel.Parent = EggIcon
    
    -- Egg Name
    local EggName = Instance.new("TextLabel")
    EggName.Size = UDim2.new(1, -10, 0, 25)
    EggName.Position = UDim2.new(0, 5, 0, 115)
    EggName.BackgroundTransparency = 1
    EggName.Text = tierData.Name
    EggName.TextColor3 = tierData.Color
    EggName.TextScaled = true
    EggName.Font = Enum.Font.SourceSansBold
    EggName.Parent = Card
    
    -- Price
    local PriceLabel = Instance.new("TextLabel")
    PriceLabel.Size = UDim2.new(1, -10, 0, 20)
    PriceLabel.Position = UDim2.new(0, 5, 0, 145)
    PriceLabel.BackgroundTransparency = 1
    PriceLabel.Text = "🪙 " .. Utils.FormatNumber(tierData.Price)
    PriceLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    PriceLabel.TextScaled = true
    PriceLabel.Font = Enum.Font.SourceSans
    PriceLabel.Parent = Card
    
    -- Buy Button
    local BuyButton = Instance.new("TextButton")
    BuyButton.Size = UDim2.new(1, -20, 0, 25)
    BuyButton.Position = UDim2.new(0, 10, 1, -35)
    BuyButton.BackgroundColor3 = Config.UI.MainTheme.Primary
    BuyButton.Text = "Buy"
    BuyButton.TextColor3 = Config.UI.MainTheme.Text
    BuyButton.TextScaled = true
    BuyButton.Font = Enum.Font.SourceSansBold
    BuyButton.BorderSizePixel = 0
    BuyButton.Parent = Card
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 10)
    buyCorner.Parent = BuyButton
    
    -- Hover effect for card
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = UDim2.new(1, 5, 1, 5)}
        ):Play()
    end)
    
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = UDim2.new(1, 0, 1, 0)}
        ):Play()
    end)
    
    -- Buy button functionality
    BuyButton.MouseButton1Click:Connect(function()
        local buyEggFunction = RemoteFunctions:FindFirstChild("BuyEgg")
        if buyEggFunction then
            BuyButton.Text = "Buying..."
            BuyButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
            
            local result = buyEggFunction:InvokeServer(eggTier)
            
            if result and result.success then
                BuyButton.Text = "Success!"
                BuyButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
                
                -- Show success notification
                if _G.MainUI then
                    _G.MainUI.ShowNotification(result.message, Color3.new(0, 1, 0))
                end
                
                -- Close shop after purchase
                wait(1)
                EggShopUI.Enabled = false
                
            else
                BuyButton.Text = "Failed"
                BuyButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
                
                -- Show error notification
                if _G.MainUI then
                    _G.MainUI.ShowNotification(result and result.reason or "Purchase failed", Color3.new(1, 0, 0))
                end
            end
            
            -- Reset button after delay
            wait(2)
            BuyButton.Text = "Buy"
            BuyButton.BackgroundColor3 = Config.UI.MainTheme.Primary
        end
    end)
    
    return Card
end

-- Load shop data and create cards
local function loadShopData()
    local getShopData = RemoteFunctions:FindFirstChild("GetShopData")
    if getShopData then
        local shopData = getShopData:InvokeServer()
        
        if shopData then
            -- Clear existing cards
            for _, child in pairs(ScrollFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name:find("Card") then
                    child:Destroy()
                end
            end
            
            -- Create cards for each egg tier
            for i, tierData in pairs(shopData) do
                createEggCard(tierData.TierName, i)
            end
            
            -- Update scroll frame size
            local cardCount = #shopData
            local rows = math.ceil(cardCount / 3) -- 3 cards per row
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 210)
        end
    end
end

-- Close button functionality
CloseButton.MouseButton1Click:Connect(function()
    EggShopUI.Enabled = false
end)

-- Show/Hide animations
local function showShop()
    EggShopUI.Enabled = true
    MainFrame.Visible = true
    
    -- Load fresh shop data
    loadShopData()
    
    -- Animate in
    MainFrame.Position = UDim2.new(0.5, -300, -1, 0) -- Start above screen
    local showTween = TweenService:Create(MainFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -300, 0.5, -250)}
    )
    showTween:Play()
end

local function hideShop()
    local hideTween = TweenService:Create(MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -300, 1.2, 0)}
    )
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        MainFrame.Visible = false
        EggShopUI.Enabled = false
    end)
end

-- Handle ESC key to close
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Escape and EggShopUI.Enabled then
        hideShop()
    end
end)

-- Override enabled property to trigger animations
EggShopUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if EggShopUI.Enabled then
        showShop()
    else
        hideShop()
    end
end)

-- Initialize as hidden
EggShopUI.Enabled = false

print("EggShopUI GUI created successfully!")