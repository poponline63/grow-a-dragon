--[[
    TutorialClient.client.lua
    Client-side tutorial system for Grow a Dragon V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for shared modules and remotes
repeat wait() until ReplicatedStorage:FindFirstChild("Shared")
repeat wait() until ReplicatedStorage:FindFirstChild("RemoteEvents")
repeat wait() until ReplicatedStorage.RemoteEvents:FindFirstChild("Tutorial")

local Config = require(ReplicatedStorage.Shared.Config)
local TutorialRemotes = ReplicatedStorage.RemoteEvents.Tutorial

local TutorialClient = {}
TutorialClient.CurrentStep = nil
TutorialClient.TutorialUI = nil
TutorialClient.ActiveElements = {}
TutorialClient.IsActive = false

-- Initialize tutorial client
function TutorialClient.Initialize()
    TutorialClient.CreateTutorialUI()
    TutorialClient.ConnectRemoteEvents()
    print("TutorialClient initialized")
end

-- Create tutorial UI elements
function TutorialClient.CreateTutorialUI()
    local tutorialGui = Instance.new("ScreenGui")
    tutorialGui.Name = "TutorialUI"
    tutorialGui.ResetOnSpawn = false
    tutorialGui.IgnoreGuiInset = true
    tutorialGui.DisplayOrder = 100 -- High priority
    tutorialGui.Enabled = false
    tutorialGui.Parent = PlayerGui
    
    -- Overlay for highlighting/dimming
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.7
    overlay.BorderSizePixel = 0
    overlay.Parent = tutorialGui
    
    -- Tutorial popup container
    local popupContainer = Instance.new("Frame")
    popupContainer.Name = "PopupContainer"
    popupContainer.Size = UDim2.new(0, 400, 0, 200)
    popupContainer.Position = UDim2.new(0.5, -200, 0.3, 0)
    popupContainer.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    popupContainer.BorderSizePixel = 0
    popupContainer.Visible = false
    popupContainer.Parent = tutorialGui
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 20)
    popupCorner.Parent = popupContainer
    
    local popupStroke = Instance.new("UIStroke")
    popupStroke.Color = Color3.new(0.8, 0.6, 0.2)
    popupStroke.Thickness = 3
    popupStroke.Parent = popupContainer
    
    -- Popup title
    local popupTitle = Instance.new("TextLabel")
    popupTitle.Name = "Title"
    popupTitle.Size = UDim2.new(1, -40, 0, 60)
    popupTitle.Position = UDim2.new(0, 20, 0, 10)
    popupTitle.BackgroundTransparency = 1
    popupTitle.Text = "Tutorial Step"
    popupTitle.TextColor3 = Color3.new(1, 1, 1)
    popupTitle.TextScaled = true
    popupTitle.Font = Enum.Font.SourceSansBold
    popupTitle.Parent = popupContainer
    
    -- Popup description
    local popupDescription = Instance.new("TextLabel")
    popupDescription.Name = "Description"
    popupDescription.Size = UDim2.new(1, -40, 0, 80)
    popupDescription.Position = UDim2.new(0, 20, 0, 70)
    popupDescription.BackgroundTransparency = 1
    popupDescription.Text = "Tutorial description goes here..."
    popupDescription.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    popupDescription.TextScaled = true
    popupDescription.Font = Enum.Font.SourceSans
    popupDescription.TextWrapped = true
    popupDescription.Parent = popupContainer
    
    -- Next button
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 100, 0, 40)
    nextButton.Position = UDim2.new(1, -120, 1, -50)
    nextButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    nextButton.Text = "Next"
    nextButton.TextColor3 = Color3.new(1, 1, 1)
    nextButton.TextScaled = true
    nextButton.Font = Enum.Font.SourceSansBold
    nextButton.BorderSizePixel = 0
    nextButton.Parent = popupContainer
    
    local nextButtonCorner = Instance.new("UICorner")
    nextButtonCorner.CornerRadius = UDim.new(0, 10)
    nextButtonCorner.Parent = nextButton
    
    -- Skip button
    local skipButton = Instance.new("TextButton")
    skipButton.Name = "SkipButton"
    skipButton.Size = UDim2.new(0, 80, 0, 30)
    skipButton.Position = UDim2.new(0, 20, 1, -40)
    skipButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    skipButton.Text = "Skip Tutorial"
    skipButton.TextColor3 = Color3.new(1, 1, 1)
    skipButton.TextScaled = true
    skipButton.Font = Enum.Font.SourceSans
    skipButton.BorderSizePixel = 0
    skipButton.Parent = popupContainer
    
    local skipButtonCorner = Instance.new("UICorner")
    skipButtonCorner.CornerRadius = UDim.new(0, 8)
    skipButtonCorner.Parent = skipButton
    
    TutorialClient.TutorialUI = tutorialGui
    TutorialClient.PopupContainer = popupContainer
    
    -- Connect button events
    TutorialClient.ConnectUIEvents()
end

-- Connect UI button events
function TutorialClient.ConnectUIEvents()
    local popupContainer = TutorialClient.PopupContainer
    local nextButton = popupContainer.NextButton
    local skipButton = popupContainer.SkipButton
    
    -- Next button
    nextButton.Activated:Connect(function()
        TutorialRemotes.AdvanceTutorial:FireServer(true)
    end)
    
    -- Skip button
    skipButton.Activated:Connect(function()
        TutorialClient.ConfirmSkip()
    end)
end

-- Show tutorial step
function TutorialClient.ShowStep(stepData)
    TutorialClient.CurrentStep = stepData
    TutorialClient.IsActive = true
    TutorialClient.TutorialUI.Enabled = true
    
    print("Showing tutorial step:", stepData.Title)
    
    if stepData.Type == "popup" then
        TutorialClient.ShowPopup(stepData)
    elseif stepData.Type == "arrow" then
        TutorialClient.ShowArrow(stepData)
    elseif stepData.Type == "highlight" then
        TutorialClient.ShowHighlight(stepData)
    elseif stepData.Type == "celebration" then
        TutorialClient.ShowCelebration(stepData)
    end
    
    -- Handle auto-advance
    if stepData.AutoAdvance and stepData.Duration then
        spawn(function()
            wait(stepData.Duration)
            if TutorialClient.CurrentStep == stepData then
                TutorialRemotes.AdvanceTutorial:FireServer(true)
            end
        end)
    end
end

-- Show popup tutorial step
function TutorialClient.ShowPopup(stepData)
    local popup = TutorialClient.PopupContainer
    
    popup.Title.Text = stepData.Title
    popup.Description.Text = stepData.Description
    popup.Visible = true
    
    -- Animate in
    popup.Size = UDim2.new(0, 0, 0, 0)
    popup.Position = UDim2.new(0.5, 0, 0.3, 0)
    
    TweenService:Create(popup,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 200),
            Position = UDim2.new(0.5, -200, 0.3, 0)
        }
    ):Play()
    
    -- Hide next button if auto-advance
    popup.NextButton.Visible = not stepData.AutoAdvance
end

-- Show arrow pointing to target
function TutorialClient.ShowArrow(stepData)
    TutorialClient.ShowPopup(stepData)
    
    local target = TutorialClient.FindTarget(stepData.Target)
    if target then
        local arrow = TutorialClient.CreateArrow(target)
        table.insert(TutorialClient.ActiveElements, arrow)
        
        if stepData.Highlight then
            local highlight = TutorialClient.CreateHighlight(target)
            table.insert(TutorialClient.ActiveElements, highlight)
        end
    else
        warn("Tutorial target not found:", stepData.Target)
    end
end

-- Show highlight around target
function TutorialClient.ShowHighlight(stepData)
    local target = TutorialClient.FindTarget(stepData.Target)
    if target then
        local highlight = TutorialClient.CreateHighlight(target)
        table.insert(TutorialClient.ActiveElements, highlight)
        
        -- Make popup smaller and positioned near target
        local popup = TutorialClient.PopupContainer
        popup.Size = UDim2.new(0, 300, 0, 150)
        TutorialClient.ShowPopup(stepData)
    end
end

-- Show celebration effect
function TutorialClient.ShowCelebration(stepData)
    TutorialClient.ShowPopup(stepData)
    
    -- Create confetti effect
    if stepData.Effect == "confetti" then
        TutorialClient.CreateConfettiEffect()
    end
    
    -- Play celebration sound
    TutorialClient.PlayCelebrationSound()
end

-- Create arrow pointing to target
function TutorialClient.CreateArrow(target)
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "TutorialArrow"
    arrow.Size = UDim2.new(0, 60, 0, 60)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Replace with actual arrow image
    arrow.ImageColor3 = Color3.new(1, 0.8, 0.2)
    arrow.Parent = TutorialClient.TutorialUI
    
    -- Position arrow pointing to target
    local targetPosition = TutorialClient.GetElementScreenPosition(target)
    arrow.Position = UDim2.new(0, targetPosition.X - 80, 0, targetPosition.Y - 80)
    
    -- Animate arrow bouncing
    spawn(function()
        while arrow.Parent do
            TweenService:Create(arrow,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = arrow.Position + UDim2.new(0, 0, 0, -10)}
            ):Play()
            wait(0.8)
            TweenService:Create(arrow,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = arrow.Position + UDim2.new(0, 0, 0, 10)}
            ):Play()
            wait(0.8)
        end
    end)
    
    return arrow
end

-- Create highlight effect around target
function TutorialClient.CreateHighlight(target)
    local highlight = Instance.new("Frame")
    highlight.Name = "TutorialHighlight"
    highlight.BackgroundTransparency = 1
    highlight.BorderSizePixel = 3
    highlight.BorderColor3 = Color3.new(1, 0.8, 0.2)
    highlight.Parent = TutorialClient.TutorialUI
    
    -- Match target size and position
    local targetPosition = TutorialClient.GetElementScreenPosition(target)
    local targetSize = target.AbsoluteSize
    
    highlight.Size = UDim2.new(0, targetSize.X + 10, 0, targetSize.Y + 10)
    highlight.Position = UDim2.new(0, targetPosition.X - 5, 0, targetPosition.Y - 5)
    
    -- Animate highlight pulsing
    spawn(function()
        while highlight.Parent do
            TweenService:Create(highlight,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BorderColor3 = Color3.new(1, 1, 0.5)}
            ):Play()
            wait(1)
            TweenService:Create(highlight,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BorderColor3 = Color3.new(1, 0.8, 0.2)}
            ):Play()
            wait(1)
        end
    end)
    
    return highlight
end

-- Create confetti celebration effect
function TutorialClient.CreateConfettiEffect()
    for i = 1, 20 do
        local confetti = Instance.new("Frame")
        confetti.Size = UDim2.new(0, 8, 0, 8)
        confetti.Position = UDim2.new(0.5, math.random(-200, 200), 0.2, 0)
        confetti.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
        confetti.BorderSizePixel = 0
        confetti.Parent = TutorialClient.TutorialUI
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = confetti
        
        -- Animate confetti falling
        TweenService:Create(confetti,
            TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = confetti.Position + UDim2.new(0, math.random(-100, 100), 0, 600),
                Rotation = math.random(0, 360),
                BackgroundTransparency = 1
            }
        ):Play()
        
        game:GetService("Debris"):AddItem(confetti, 3)
    end
end

-- Find UI target element
function TutorialClient.FindTarget(targetName)
    -- Check MainHUD first
    local mainHUD = PlayerGui:FindFirstChild("MainHUD")
    if mainHUD then
        local element = TutorialClient.FindElementRecursive(mainHUD, targetName)
        if element then return element end
    end
    
    -- Check other GUIs
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local element = TutorialClient.FindElementRecursive(gui, targetName)
            if element then return element end
        end
    end
    
    return nil
end

-- Recursively find element by name
function TutorialClient.FindElementRecursive(parent, targetName)
    for _, child in pairs(parent:GetChildren()) do
        if child.Name == targetName or child.Name:find(targetName) then
            return child
        end
        
        local found = TutorialClient.FindElementRecursive(child, targetName)
        if found then return found end
    end
    
    return nil
end

-- Get screen position of GUI element
function TutorialClient.GetElementScreenPosition(element)
    return {
        X = element.AbsolutePosition.X + element.AbsoluteSize.X / 2,
        Y = element.AbsolutePosition.Y + element.AbsoluteSize.Y / 2
    }
end

-- Clean up tutorial elements
function TutorialClient.CleanupElements()
    for _, element in pairs(TutorialClient.ActiveElements) do
        if element and element.Parent then
            element:Destroy()
        end
    end
    TutorialClient.ActiveElements = {}
end

-- Hide tutorial
function TutorialClient.HideTutorial()
    TutorialClient.IsActive = false
    TutorialClient.TutorialUI.Enabled = false
    TutorialClient.PopupContainer.Visible = false
    TutorialClient.CleanupElements()
end

-- Confirm skip tutorial
function TutorialClient.ConfirmSkip()
    -- Show confirmation dialog
    local confirmDialog = Instance.new("Frame")
    confirmDialog.Size = UDim2.new(0, 300, 0, 150)
    confirmDialog.Position = UDim2.new(0.5, -150, 0.5, -75)
    confirmDialog.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    confirmDialog.BorderSizePixel = 2
    confirmDialog.BorderColor3 = Color3.new(0.8, 0.3, 0.3)
    confirmDialog.Parent = TutorialClient.TutorialUI
    
    local confirmTitle = Instance.new("TextLabel")
    confirmTitle.Size = UDim2.new(1, -20, 0, 40)
    confirmTitle.Position = UDim2.new(0, 10, 0, 10)
    confirmTitle.BackgroundTransparency = 1
    confirmTitle.Text = "Skip Tutorial?"
    confirmTitle.TextColor3 = Color3.new(1, 1, 1)
    confirmTitle.TextScaled = true
    confirmTitle.Font = Enum.Font.SourceSansBold
    confirmTitle.Parent = confirmDialog
    
    local confirmDesc = Instance.new("TextLabel")
    confirmDesc.Size = UDim2.new(1, -20, 0, 40)
    confirmDesc.Position = UDim2.new(0, 10, 0, 50)
    confirmDesc.BackgroundTransparency = 1
    confirmDesc.Text = "Are you sure? You won't get the starter rewards!"
    confirmDesc.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    confirmDesc.TextScaled = true
    confirmDesc.Font = Enum.Font.SourceSans
    confirmDesc.TextWrapped = true
    confirmDesc.Parent = confirmDialog
    
    -- Yes button
    local yesButton = Instance.new("TextButton")
    yesButton.Size = UDim2.new(0, 80, 0, 30)
    yesButton.Position = UDim2.new(0, 40, 0, 110)
    yesButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    yesButton.Text = "Yes, Skip"
    yesButton.TextColor3 = Color3.new(1, 1, 1)
    yesButton.TextScaled = true
    yesButton.Font = Enum.Font.SourceSans
    yesButton.Parent = confirmDialog
    
    -- No button
    local noButton = Instance.new("TextButton")
    noButton.Size = UDim2.new(0, 80, 0, 30)
    noButton.Position = UDim2.new(0, 180, 0, 110)
    noButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    noButton.Text = "Continue"
    noButton.TextColor3 = Color3.new(1, 1, 1)
    noButton.TextScaled = true
    noButton.Font = Enum.Font.SourceSans
    noButton.Parent = confirmDialog
    
    yesButton.Activated:Connect(function()
        TutorialRemotes.SkipTutorial:FireServer()
        confirmDialog:Destroy()
    end)
    
    noButton.Activated:Connect(function()
        confirmDialog:Destroy()
    end)
end

-- Play celebration sound
function TutorialClient.PlayCelebrationSound()
    -- Use SoundManager if available
    local soundManager = game.StarterPlayerScripts:FindFirstChild("SoundManager")
    if soundManager and soundManager:FindFirstChild("PlaySound") then
        soundManager.PlaySound:Fire("TutorialComplete")
    end
end

-- Connect remote events
function TutorialClient.ConnectRemoteEvents()
    TutorialRemotes.TutorialAction.OnClientEvent:Connect(function(action, data)
        if action == "show_step" then
            TutorialClient.ShowStep(data)
        elseif action == "tutorial_complete" then
            TutorialClient.HideTutorial()
            print("Tutorial completed!")
        elseif action == "tutorial_skipped" then
            TutorialClient.HideTutorial()
            print("Tutorial skipped")
        end
    end)
end

-- Start initialization
spawn(function()
    wait(2) -- Wait for other systems to load
    TutorialClient.Initialize()
end)

return TutorialClient