-- HatchUI.gui.lua - Dragon hatch celebration screen
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)

-- Create Hatch ScreenGui
local HatchUI = Instance.new("ScreenGui")
HatchUI.Name = "HatchUI"
HatchUI.ResetOnSpawn = false
HatchUI.Enabled = false
HatchUI.Parent = PlayerGui

-- Full screen overlay
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.Position = UDim2.new(0, 0, 0, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.BorderSizePixel = 0
Overlay.Parent = HatchUI

-- Main celebration frame
local CelebrationFrame = Instance.new("Frame")
CelebrationFrame.Size = UDim2.new(0, 400, 0, 300)
CelebrationFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
CelebrationFrame.BackgroundColor3 = Color3.new(1, 1, 1)
CelebrationFrame.BorderSizePixel = 0
CelebrationFrame.Parent = HatchUI

local celebrationCorner = Instance.new("UICorner")
celebrationCorner.CornerRadius = UDim.new(0, 25)
celebrationCorner.Parent = CelebrationFrame

-- Gradient background
local celebrationGradient = Instance.new("UIGradient")
celebrationGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(1, 0.9, 0.6)),
    ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.7, 1))
}
celebrationGradient.Rotation = 45
celebrationGradient.Parent = CelebrationFrame

-- Celebration text
local CelebrationText = Instance.new("TextLabel")
CelebrationText.Size = UDim2.new(1, -20, 0, 50)
CelebrationText.Position = UDim2.new(0, 10, 0, 20)
CelebrationText.BackgroundTransparency = 1
CelebrationText.Text = "🎉 DRAGON HATCHED! 🎉"
CelebrationText.TextColor3 = Config.UI.MainTheme.Background
CelebrationText.TextScaled = true
CelebrationText.Font = Enum.Font.SourceSansBold
CelebrationText.Parent = CelebrationFrame

-- Dragon placeholder (will be replaced with actual dragon info)
local DragonIcon = Instance.new("Frame")
DragonIcon.Size = UDim2.new(0, 80, 0, 80)
DragonIcon.Position = UDim2.new(0.5, -40, 0, 80)
DragonIcon.BackgroundColor3 = Config.UI.MainTheme.Primary
DragonIcon.BorderSizePixel = 0
DragonIcon.Parent = CelebrationFrame

local dragonIconCorner = Instance.new("UICorner")
dragonIconCorner.CornerRadius = UDim.new(0.5, 0)
dragonIconCorner.Parent = DragonIcon

local DragonEmoji = Instance.new("TextLabel")
DragonEmoji.Size = UDim2.new(1, 0, 1, 0)
DragonEmoji.BackgroundTransparency = 1
DragonEmoji.Text = "🐲"
DragonEmoji.TextScaled = true
DragonEmoji.Parent = DragonIcon

-- Dragon name
local DragonName = Instance.new("TextLabel")
DragonName.Name = "DragonName"
DragonName.Size = UDim2.new(1, -20, 0, 30)
DragonName.Position = UDim2.new(0, 10, 0, 170)
DragonName.BackgroundTransparency = 1
DragonName.Text = "New Dragon!"
DragonName.TextColor3 = Config.UI.MainTheme.Background
DragonName.TextScaled = true
DragonName.Font = Enum.Font.SourceSansBold
DragonName.Parent = CelebrationFrame

-- Dragon details
local DragonDetails = Instance.new("TextLabel")
DragonDetails.Name = "DragonDetails"
DragonDetails.Size = UDim2.new(1, -20, 0, 25)
DragonDetails.Position = UDim2.new(0, 10, 0, 205)
DragonDetails.BackgroundTransparency = 1
DragonDetails.Text = "Element • Rarity • Level 1"
DragonDetails.TextColor3 = Config.UI.MainTheme.Background
DragonDetails.TextScaled = true
DragonDetails.Font = Enum.Font.SourceSans
DragonDetails.Parent = CelebrationFrame

-- Continue button
local ContinueButton = Instance.new("TextButton")
ContinueButton.Size = UDim2.new(0, 120, 0, 35)
ContinueButton.Position = UDim2.new(0.5, -60, 1, -50)
ContinueButton.BackgroundColor3 = Config.UI.MainTheme.Primary
ContinueButton.Text = "Continue"
ContinueButton.TextColor3 = Config.UI.MainTheme.Text
ContinueButton.TextScaled = true
ContinueButton.Font = Enum.Font.SourceSansBold
ContinueButton.BorderSizePixel = 0
ContinueButton.Parent = CelebrationFrame

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 15)
continueCorner.Parent = ContinueButton

-- Sparkle effects
local function createSparkle(parent)
    local sparkle = Instance.new("TextLabel")
    sparkle.Size = UDim2.new(0, 20, 0, 20)
    sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
    sparkle.BackgroundTransparency = 1
    sparkle.Text = "✨"
    sparkle.TextColor3 = Color3.new(1, 1, 0)
    sparkle.TextScaled = true
    sparkle.ZIndex = 10
    sparkle.Parent = parent
    
    -- Animate sparkle
    local tween = TweenService:Create(sparkle,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = sparkle.Position + UDim2.new(0, math.random(-50, 50), 0, -100),
            TextTransparency = 1,
            Rotation = math.random(-180, 180)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        sparkle:Destroy()
    end)
end

-- Function to show dragon hatch
local function showDragonHatch(dragon)
    if not dragon then
        dragon = {
            Name = "Mystery Dragon",
            Element = "Fire",
            Rarity = "Common",
            Level = 1
        }
    end
    
    -- Update display with dragon info
    DragonName.Text = dragon.Name
    DragonDetails.Text = dragon.Element .. " • " .. dragon.Rarity .. " • Level " .. dragon.Level
    
    -- Set colors based on rarity
    local rarityColor = Config.UI.RarityColors[dragon.Rarity] or Config.UI.MainTheme.Primary
    DragonIcon.BackgroundColor3 = rarityColor
    
    -- Set celebration frame color based on rarity
    celebrationGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.new(1, 1, 1), 0.7)),
        ColorSequenceKeypoint.new(1, rarityColor:Lerp(Color3.new(1, 1, 1), 0.5))
    }
    
    -- Show UI
    HatchUI.Enabled = true
    
    -- Animate in with explosion effect
    CelebrationFrame.Size = UDim2.new(0, 0, 0, 0)
    CelebrationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local explodeTween = TweenService:Create(CelebrationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150)
        }
    )
    explodeTween:Play()
    
    -- Create sparkle effects
    for i = 1, 15 do
        spawn(function()
            wait(i * 0.1)
            createSparkle(HatchUI)
        end)
    end
end

-- Continue button functionality
ContinueButton.MouseButton1Click:Connect(function()
    HatchUI.Enabled = false
end)

-- Close on tap anywhere
Overlay.MouseButton1Click:Connect(function()
    HatchUI.Enabled = false
end)

-- Animation out
local function hideHatch()
    local hideTween = TweenService:Create(CelebrationFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    hideTween:Play()
    
    TweenService:Create(Overlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}
    ):Play()
    
    hideTween.Completed:Connect(function()
        HatchUI.Enabled = false
        Overlay.BackgroundTransparency = 0.5
    end)
end

-- Listen for dragon hatch events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dragonHatched = RemoteEvents:FindFirstChild("DragonHatched")
if dragonHatched then
    dragonHatched.OnClientEvent:Connect(function(dragon)
        showDragonHatch(dragon)
    end)
end

-- Property change handler
HatchUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if not HatchUI.Enabled then
        hideHatch()
    end
end)

-- Auto-close after 10 seconds
spawn(function()
    while true do
        if HatchUI.Enabled then
            wait(10)
            if HatchUI.Enabled then -- Still open after 10 seconds
                HatchUI.Enabled = false
            end
        else
            wait(1)
        end
    end
end)

-- Public API
_G.HatchUI = {
    ShowDragonHatch = showDragonHatch
}

print("HatchUI GUI created successfully!")