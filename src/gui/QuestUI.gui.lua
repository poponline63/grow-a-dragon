-- QuestUI.gui.lua - Quest interface (placeholder)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)

-- Create Quest ScreenGui
local QuestUI = Instance.new("ScreenGui")
QuestUI.Name = "QuestUI"
QuestUI.ResetOnSpawn = false
QuestUI.Enabled = false
QuestUI.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 500)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
MainFrame.BackgroundColor3 = Config.UI.MainTheme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = QuestUI

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Color3.new(1, 0.6, 0.2)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "📋 Quests & Missions"
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

-- Placeholder content
local PlaceholderLabel = Instance.new("TextLabel")
PlaceholderLabel.Size = UDim2.new(1, -40, 1, -120)
PlaceholderLabel.Position = UDim2.new(0, 20, 0, 80)
PlaceholderLabel.BackgroundTransparency = 1
PlaceholderLabel.Text = "🚧 Quest System Coming Soon! 🚧\n\nThis will show:\n• Daily Quests\n• Weekly Challenges\n• Progress Tracking\n• Reward Claims\n• Special Events"
PlaceholderLabel.TextColor3 = Config.UI.MainTheme.Text
PlaceholderLabel.TextScaled = true
PlaceholderLabel.Font = Enum.Font.SourceSans
PlaceholderLabel.Parent = MainFrame

-- Close functionality
CloseButton.MouseButton1Click:Connect(function()
    QuestUI.Enabled = false
end)

-- Animation functions
local function showQuests()
    QuestUI.Enabled = true
    MainFrame.Visible = true
    MainFrame.Position = UDim2.new(0.5, -300, -1, 0)
    
    TweenService:Create(MainFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -300, 0.5, -250)}
    ):Play()
end

local function hideQuests()
    local hideTween = TweenService:Create(MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -300, 1.2, 0)}
    )
    hideTween:Play()
    hideTween.Completed:Connect(function()
        MainFrame.Visible = false
        QuestUI.Enabled = false
    end)
end

-- Property change handler
QuestUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if QuestUI.Enabled then
        showQuests()
    else
        hideQuests()
    end
end)

print("QuestUI GUI created successfully!")