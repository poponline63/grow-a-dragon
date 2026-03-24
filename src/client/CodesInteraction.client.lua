--[[
    CodesInteraction.client.lua
    Client-side codes interaction for Grow a Dragon V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules and remotes
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
repeat wait() until ReplicatedStorage:FindFirstChild("RemoteEvents")
repeat wait() until ReplicatedStorage.RemoteEvents:FindFirstChild("Codes")

local Config = require(ReplicatedStorage.Shared.Config)
local CodesRemote = ReplicatedStorage.RemoteEvents.Codes:WaitForChild("RedeemCode")

local CodesInteraction = {}

-- UI References
local CodesUI = nil
local MainHUD = nil

-- Animation tweens
local animationTweens = {}

-- Initialize codes interaction
function CodesInteraction.Initialize()
    -- Wait for main HUD and codes UI to load
    repeat wait() until PlayerGui:FindFirstChild("MainHUD")
    repeat wait() until PlayerGui:FindFirstChild("CodesUI")
    
    MainHUD = PlayerGui.MainHUD
    CodesUI = PlayerGui.CodesUI
    
    -- Connect codes button
    local codesButton = MainHUD.BottomBar:FindFirstChild("CodesButton")
    if codesButton then
        CodesInteraction.ConnectCodesButton(codesButton)
    end
    
    -- Connect UI elements
    CodesInteraction.ConnectCodesUI()
    
    print("CodesInteraction initialized")
end

-- Connect the codes button in main HUD
function CodesInteraction.ConnectCodesButton(button)
    button.Activated:Connect(function()
        CodesInteraction.ToggleCodesUI()
    end)
    
    -- Add button feedback
    button.MouseEnter:Connect(function()
        CodesInteraction.AnimateButton(button, 1.1, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        CodesInteraction.AnimateButton(button, 1.0, 0.2)
    end)
end

-- Connect codes UI interactions
function CodesInteraction.ConnectCodesUI()
    local frame = CodesUI.CodesFrame
    local textBox = frame.CodeInput.TextBox
    local redeemButton = frame.RedeemButton
    local closeButton = frame.CloseButton
    
    -- Redeem button
    redeemButton.Activated:Connect(function()
        local codeText = textBox.Text
        if codeText and #codeText > 0 then
            CodesInteraction.RedeemCode(codeText)
        else
            CodesInteraction.ShowMessage("Please enter a code first!", Color3.new(1, 0.5, 0))
        end
    end)
    
    -- Enter key to redeem
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            redeemButton.Activated:Fire()
        end
    end)
    
    -- Close button
    closeButton.Activated:Connect(function()
        CodesInteraction.HideCodesUI()
    end)
    
    -- Button hover effects
    CodesInteraction.AddButtonHoverEffect(redeemButton)
    CodesInteraction.AddButtonHoverEffect(closeButton)
end

-- Add hover effect to buttons
function CodesInteraction.AddButtonHoverEffect(button)
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        CodesInteraction.AnimateButton(button, 1.05, 0.15)
        TweenService:Create(button,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.2)}
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        CodesInteraction.AnimateButton(button, 1.0, 0.15)
        TweenService:Create(button,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = originalColor}
        ):Play()
    end)
end

-- Animate button scale
function CodesInteraction.AnimateButton(button, scale, duration)
    local originalSize = button:GetAttribute("OriginalSize")
    if not originalSize then
        originalSize = button.Size
        button:SetAttribute("OriginalSize", tostring(originalSize))
    else
        originalSize = UDim2.fromString(originalSize)
    end
    
    TweenService:Create(button,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(
            originalSize.X.Scale * scale,
            originalSize.X.Offset * scale,
            originalSize.Y.Scale * scale,
            originalSize.Y.Offset * scale
        )}
    ):Play()
end

-- Toggle codes UI visibility
function CodesInteraction.ToggleCodesUI()
    if CodesUI.Enabled then
        CodesInteraction.HideCodesUI()
    else
        CodesInteraction.ShowCodesUI()
    end
end

-- Show codes UI with animation
function CodesInteraction.ShowCodesUI()
    CodesUI.Enabled = true
    local frame = CodesUI.CodesFrame
    
    -- Start animation from scale 0
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Animate in
    local tween = TweenService:Create(frame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150)
        }
    )
    tween:Play()
    
    -- Clear previous text
    local textBox = frame.CodeInput.TextBox
    textBox.Text = ""
    
    -- Focus on text box after animation
    tween.Completed:Connect(function()
        textBox:CaptureFocus()
    end)
end

-- Hide codes UI with animation
function CodesInteraction.HideCodesUI()
    local frame = CodesUI.CodesFrame
    
    -- Animate out
    local tween = TweenService:Create(frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        CodesUI.Enabled = false
    end)
end

-- Redeem code via server
function CodesInteraction.RedeemCode(codeText)
    local frame = CodesUI.CodesFrame
    local redeemButton = frame.RedeemButton
    
    -- Disable button during request
    redeemButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    redeemButton.Text = "Redeeming..."
    redeemButton.Active = false
    
    -- Clear previous message
    CodesInteraction.ClearMessage()
    
    -- Make server request
    local success, result = pcall(function()
        return CodesRemote:InvokeServer(codeText)
    end)
    
    -- Re-enable button
    redeemButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    redeemButton.Text = "Redeem"
    redeemButton.Active = true
    
    if success and result then
        if result.Success then
            -- Success!
            CodesInteraction.ShowMessage(result.Message, Color3.new(0.2, 0.8, 0.2))
            CodesInteraction.PlaySuccessEffect()
            
            -- Clear text box
            frame.CodeInput.TextBox.Text = ""
            
            -- Auto-hide UI after short delay
            wait(2)
            CodesInteraction.HideCodesUI()
        else
            -- Error from server
            CodesInteraction.ShowMessage(result.Message, Color3.new(0.8, 0.2, 0.2))
            CodesInteraction.PlayErrorEffect()
        end
    else
        -- Network error
        CodesInteraction.ShowMessage("Network error. Please try again.", Color3.new(0.8, 0.2, 0.2))
        CodesInteraction.PlayErrorEffect()
    end
end

-- Show message in codes UI
function CodesInteraction.ShowMessage(text, color)
    local frame = CodesUI.CodesFrame
    local messageLabel = frame.MessageLabel
    
    messageLabel.Text = text
    messageLabel.TextColor3 = color
    messageLabel.Visible = true
    
    -- Animate message
    messageLabel.TextTransparency = 1
    TweenService:Create(messageLabel,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
end

-- Clear message
function CodesInteraction.ClearMessage()
    local messageLabel = CodesUI.CodesFrame.MessageLabel
    messageLabel.Visible = false
    messageLabel.Text = ""
end

-- Play success effect
function CodesInteraction.PlaySuccessEffect()
    -- Create particle effect
    CodesInteraction.CreateSuccessParticles()
    
    -- Play sound if available
    local soundManager = game.StarterPlayerScripts:FindFirstChild("SoundManager")
    if soundManager and soundManager:FindFirstChild("PlaySound") then
        soundManager.PlaySound:Fire("CodeRedeemed")
    end
end

-- Play error effect
function CodesInteraction.PlayErrorEffect()
    -- Shake animation
    local frame = CodesUI.CodesFrame
    local originalPosition = frame.Position
    
    for i = 1, 3 do
        TweenService:Create(frame,
            TweenInfo.new(0.05, Enum.EasingStyle.Linear),
            {Position = originalPosition + UDim2.new(0, math.random(-5, 5), 0, 0)}
        ):Play()
        wait(0.05)
    end
    
    TweenService:Create(frame,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad),
        {Position = originalPosition}
    ):Play()
end

-- Create success particles
function CodesInteraction.CreateSuccessParticles()
    local frame = CodesUI.CodesFrame
    
    for i = 1, 10 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 8, 0, 8)
        particle.Position = UDim2.new(0.5, math.random(-100, 100), 0.5, math.random(-50, 50))
        particle.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
        particle.BorderSizePixel = 0
        particle.Parent = frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = particle
        
        -- Animate particle
        TweenService:Create(particle,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = particle.Position + UDim2.new(0, math.random(-50, 50), 0, -100),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0)
            }
        ):Play()
        
        -- Clean up
        game:GetService("Debris"):AddItem(particle, 1)
    end
end

-- Handle keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        -- Ctrl+C opens codes UI
        CodesInteraction.ToggleCodesUI()
    elseif input.KeyCode == Enum.KeyCode.Escape and CodesUI.Enabled then
        -- Escape closes codes UI
        CodesInteraction.HideCodesUI()
    end
end)

-- Start initialization when script loads
spawn(function()
    wait(2) -- Wait for other systems to load
    CodesInteraction.Initialize()
end)

return CodesInteraction