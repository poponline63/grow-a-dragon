--[[
    CodesUI.gui.lua
    Codes redemption UI for Grow a Dragon V3
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
local Config = require(ReplicatedStorage.Shared.Config)

-- Create main ScreenGui
local CodesUI = Instance.new("ScreenGui")
CodesUI.Name = "CodesUI"
CodesUI.ResetOnSpawn = false
CodesUI.IgnoreGuiInset = true
CodesUI.Enabled = false
CodesUI.Parent = PlayerGui

-- Background overlay
local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.Position = UDim2.new(0, 0, 0, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.BorderSizePixel = 0
Overlay.Parent = CodesUI

-- Main codes frame
local CodesFrame = Instance.new("Frame")
CodesFrame.Name = "CodesFrame"
CodesFrame.Size = UDim2.new(0, 400, 0, 300)
CodesFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
CodesFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
CodesFrame.BorderSizePixel = 0
CodesFrame.Parent = CodesUI

-- Frame corner and stroke
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 20)
frameCorner.Parent = CodesFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.new(0.3, 0.4, 1)
frameStroke.Thickness = 2
frameStroke.Parent = CodesFrame

-- Frame gradient
local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.15, 0.2)),
    ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.15))
}
frameGradient.Rotation = 45
frameGradient.Parent = CodesFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -40, 0, 60)
Title.Position = UDim2.new(0, 20, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "🎁 Redeem Codes"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = CodesFrame

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -50, 0, 10)
CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextScaled = true
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.BorderSizePixel = 0
CloseButton.Parent = CodesFrame

local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 20)
closeButtonCorner.Parent = CloseButton

-- Description
local Description = Instance.new("TextLabel")
Description.Name = "Description"
Description.Size = UDim2.new(1, -40, 0, 40)
Description.Position = UDim2.new(0, 20, 0, 70)
Description.BackgroundTransparency = 1
Description.Text = "Enter a code below to claim free rewards!"
Description.TextColor3 = Color3.new(0.8, 0.8, 0.9)
Description.TextScaled = true
Description.Font = Enum.Font.SourceSans
Description.TextWrapped = true
Description.Parent = CodesFrame

-- Code input container
local CodeInput = Instance.new("Frame")
CodeInput.Name = "CodeInput"
CodeInput.Size = UDim2.new(1, -40, 0, 50)
CodeInput.Position = UDim2.new(0, 20, 0, 130)
CodeInput.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
CodeInput.BorderSizePixel = 0
CodeInput.Parent = CodesFrame

local codeInputCorner = Instance.new("UICorner")
codeInputCorner.CornerRadius = UDim.new(0, 10)
codeInputCorner.Parent = CodeInput

local codeInputStroke = Instance.new("UIStroke")
codeInputStroke.Color = Color3.new(0.4, 0.4, 0.5)
codeInputStroke.Thickness = 1
codeInputStroke.Parent = CodeInput

-- Text input box
local TextBox = Instance.new("TextBox")
TextBox.Name = "TextBox"
TextBox.Size = UDim2.new(1, -20, 1, 0)
TextBox.Position = UDim2.new(0, 10, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.PlaceholderText = "Enter code here..."
TextBox.PlaceholderColor3 = Color3.new(0.6, 0.6, 0.7)
TextBox.Text = ""
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.TextScaled = true
TextBox.Font = Enum.Font.SourceSansBold
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.ClearTextOnFocus = false
TextBox.Parent = CodeInput

-- Redeem button
local RedeemButton = Instance.new("TextButton")
RedeemButton.Name = "RedeemButton"
RedeemButton.Size = UDim2.new(0, 160, 0, 50)
RedeemButton.Position = UDim2.new(0.5, -80, 0, 200)
RedeemButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
RedeemButton.Text = "Redeem"
RedeemButton.TextColor3 = Color3.new(1, 1, 1)
RedeemButton.TextScaled = true
RedeemButton.Font = Enum.Font.SourceSansBold
RedeemButton.BorderSizePixel = 0
RedeemButton.Parent = CodesFrame

local redeemButtonCorner = Instance.new("UICorner")
redeemButtonCorner.CornerRadius = UDim.new(0, 15)
redeemButtonCorner.Parent = RedeemButton

-- Redeem button gradient
local redeemGradient = Instance.new("UIGradient")
redeemGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(0.3, 1, 0.3)),
    ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.8, 0.2))
}
redeemGradient.Rotation = 90
redeemGradient.Parent = RedeemButton

-- Message label
local MessageLabel = Instance.new("TextLabel")
MessageLabel.Name = "MessageLabel"
MessageLabel.Size = UDim2.new(1, -40, 0, 30)
MessageLabel.Position = UDim2.new(0, 20, 0, 260)
MessageLabel.BackgroundTransparency = 1
MessageLabel.Text = ""
MessageLabel.TextColor3 = Color3.new(1, 1, 1)
MessageLabel.TextScaled = true
MessageLabel.Font = Enum.Font.SourceSansBold
MessageLabel.TextWrapped = true
MessageLabel.Visible = false
MessageLabel.Parent = CodesFrame

-- Add sparkle effect to title
local function createSparkles()
    for i = 1, 5 do
        local sparkle = Instance.new("Frame")
        sparkle.Size = UDim2.new(0, 4, 0, 4)
        sparkle.Position = UDim2.new(
            math.random(10, 90) / 100,
            0,
            math.random(10, 90) / 100,
            0
        )
        sparkle.BackgroundColor3 = Color3.new(1, 1, 0.8)
        sparkle.BorderSizePixel = 0
        sparkle.Parent = CodesFrame
        
        local sparkleCorner = Instance.new("UICorner")
        sparkleCorner.CornerRadius = UDim.new(0.5, 0)
        sparkleCorner.Parent = sparkle
        
        -- Animate sparkle
        local tween = TweenService:Create(sparkle,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {BackgroundTransparency = 1}
        )
        tween:Play()
        
        spawn(function()
            while sparkle.Parent do
                wait(math.random(1, 3))
                sparkle.Position = UDim2.new(
                    math.random(10, 90) / 100,
                    0,
                    math.random(10, 90) / 100,
                    0
                )
            end
        end)
    end
end

-- Create initial sparkles
createSparkles()

-- Sample codes display
local SampleCodes = Instance.new("Frame")
SampleCodes.Name = "SampleCodes"
SampleCodes.Size = UDim2.new(0, 150, 0, 120)
SampleCodes.Position = UDim2.new(1, 10, 0, 0)
SampleCodes.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
SampleCodes.BorderSizePixel = 0
SampleCodes.Visible = false -- Hidden by default, can be shown for hints
SampleCodes.Parent = CodesFrame

local sampleCorner = Instance.new("UICorner")
sampleCorner.CornerRadius = UDim.new(0, 10)
sampleCorner.Parent = SampleCodes

local sampleTitle = Instance.new("TextLabel")
sampleTitle.Size = UDim2.new(1, 0, 0, 25)
sampleTitle.Position = UDim2.new(0, 0, 0, 0)
sampleTitle.BackgroundTransparency = 1
sampleTitle.Text = "Try these codes:"
sampleTitle.TextColor3 = Color3.new(0.8, 0.8, 0.9)
sampleTitle.TextScaled = true
sampleTitle.Font = Enum.Font.SourceSans
sampleTitle.Parent = SampleCodes

local sampleList = Instance.new("TextLabel")
sampleList.Size = UDim2.new(1, -10, 1, -30)
sampleList.Position = UDim2.new(0, 5, 0, 25)
sampleList.BackgroundTransparency = 1
sampleList.Text = "• RELEASE\n• DRAGON\n• WELCOME\n• FIRE\n• LUCKY"
sampleList.TextColor3 = Color3.new(0.6, 0.8, 1)
sampleList.TextScaled = true
sampleList.Font = Enum.Font.SourceSansLight
sampleList.TextYAlignment = Enum.TextYAlignment.Top
sampleList.Parent = SampleCodes

-- Focus effects for text box
TextBox.Focused:Connect(function()
    TweenService:Create(codeInputStroke,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Color = Color3.new(0.3, 0.6, 1), Thickness = 2}
    ):Play()
end)

TextBox.FocusLost:Connect(function()
    TweenService:Create(codeInputStroke,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Color = Color3.new(0.4, 0.4, 0.5), Thickness = 1}
    ):Play()
end)

-- Close UI when clicking overlay
Overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        CodesUI.Enabled = false
    end
end)

print("CodesUI created successfully!")