-- EggInteraction.client.lua - Handle egg clicking and hatch progress
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Shared.Utils)
local EggData = require(ReplicatedStorage.Shared.EggData)

-- Wait for RemoteFunctions and RemoteEvents
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Track clicked eggs to prevent spam
local clickCooldowns = {}

-- Create egg progress UI
local function createEggProgressUI(eggData)
    -- Create popup UI
    local eggUI = Instance.new("ScreenGui")
    eggUI.Name = "EggProgressUI"
    eggUI.ResetOnSpawn = false
    eggUI.Parent = PlayerGui
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Config.UI.MainTheme.Background
    frame.BorderSizePixel = 0
    frame.Parent = eggUI
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Egg Progress"
    title.TextColor3 = Config.UI.MainTheme.Text
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Egg tier name
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(1, -20, 0, 20)
    tierLabel.Position = UDim2.new(0, 10, 0, 45)
    tierLabel.BackgroundTransparency = 1
    
    local tierData = EggData:GetTier(eggData.tier)
    tierLabel.Text = tierData and tierData.Name or "Unknown Egg"
    tierLabel.TextColor3 = tierData and tierData.Color or Color3.new(1, 1, 1)
    tierLabel.TextScaled = true
    tierLabel.Font = Enum.Font.SourceSans
    tierLabel.Parent = frame
    
    -- Progress bar background
    local progressBG = Instance.new("Frame")
    progressBG.Size = UDim2.new(1, -40, 0, 20)
    progressBG.Position = UDim2.new(0, 20, 0, 75)
    progressBG.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    progressBG.BorderSizePixel = 0
    progressBG.Parent = frame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 10)
    progressCorner.Parent = progressBG
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(eggData.progress, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Config.UI.MainTheme.Primary
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBG
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = progressFill
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = string.format("%.0f%%", eggData.progress * 100)
    progressText.TextColor3 = Config.UI.MainTheme.Text
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSansBold
    progressText.Parent = progressBG
    
    -- Time remaining
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -20, 0, 20)
    timeLabel.Position = UDim2.new(0, 10, 0, 105)
    timeLabel.BackgroundTransparency = 1
    
    if eggData.remainingTime > 0 then
        timeLabel.Text = "Time remaining: " .. Utils.FormatTime(eggData.remainingTime)
    else
        timeLabel.Text = "Ready to hatch!"
    end
    
    timeLabel.TextColor3 = Config.UI.MainTheme.Text
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.SourceSans
    timeLabel.Parent = frame
    
    -- Speed up button (if not ready)
    if eggData.remainingTime > 0 then
        local speedUpButton = Instance.new("TextButton")
        speedUpButton.Size = UDim2.new(0, 100, 0, 30)
        speedUpButton.Position = UDim2.new(0, 20, 0, 135)
        speedUpButton.BackgroundColor3 = Config.UI.MainTheme.Secondary
        speedUpButton.Text = "Speed Up (5 gems)"
        speedUpButton.TextColor3 = Config.UI.MainTheme.Text
        speedUpButton.TextScaled = true
        speedUpButton.Font = Enum.Font.SourceSansBold
        speedUpButton.BorderSizePixel = 0
        speedUpButton.Parent = frame
        
        local speedUpCorner = Instance.new("UICorner")
        speedUpCorner.CornerRadius = UDim.new(0, 6)
        speedUpCorner.Parent = speedUpButton
        
        speedUpButton.MouseButton1Click:Connect(function()
            local speedUpFunction = RemoteFunctions:FindFirstChild("SpeedUpEgg")
            if speedUpFunction then
                local result = speedUpFunction:InvokeServer(eggData.eggId)
                if result and result.success then
                    if _G.MainUI then
                        _G.MainUI.ShowNotification(result.message, Color3.new(0, 1, 0))
                    end
                    eggUI:Destroy()
                else
                    if _G.MainUI then
                        _G.MainUI.ShowNotification(result and result.reason or "Failed to speed up egg", Color3.new(1, 0, 0))
                    end
                end
            end
        end)
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 80, 0, 30)
    closeButton.Position = UDim2.new(1, -100, 0, 135)
    closeButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    closeButton.Text = "Close"
    closeButton.TextColor3 = Config.UI.MainTheme.Text
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        eggUI:Destroy()
    end)
    
    -- Animate in
    frame.Position = UDim2.new(0.5, -150, 1.5, 0) -- Start below screen
    local showTween = TweenService:Create(frame, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0.5, -100)}
    )
    showTween:Play()
    
    -- Auto-close after 10 seconds
    spawn(function()
        wait(10)
        if eggUI.Parent then
            eggUI:Destroy()
        end
    end)
end

-- Handle egg click
local function handleEggClick(eggModel, eggId)
    -- Check cooldown
    local currentTime = tick()
    local lastClick = clickCooldowns[eggId] or 0
    
    if currentTime - lastClick < 1 then -- 1 second cooldown
        return
    end
    clickCooldowns[eggId] = currentTime
    
    -- Visual click effect
    if eggModel and eggModel.Parent then
        local originalSize = eggModel.Size
        local clickTween = TweenService:Create(eggModel,
            TweenInfo.new(0.2, Enum.EasingStyle.Elastic),
            {Size = originalSize * 1.1}
        )
        clickTween:Play()
        
        clickTween.Completed:Connect(function()
            local returnTween = TweenService:Create(eggModel,
                TweenInfo.new(0.3, Enum.EasingStyle.Elastic),
                {Size = originalSize}
            )
            returnTween:Play()
        end)
    end
    
    -- Play sound effect
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = Config.Sounds.ButtonClick
    clickSound.Volume = 0.5
    clickSound.Parent = SoundService
    clickSound:Play()
    
    clickSound.Ended:Connect(function()
        clickSound:Destroy()
    end)
    
    -- Call server function
    local eggClickFunction = RemoteFunctions:FindFirstChild("EggClick")
    if eggClickFunction then
        eggClickFunction:InvokeServer(eggId)
    end
end

-- Setup egg model click detection
local function setupEggClickDetection()
    -- Listen for new egg models in workspace
    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Part") and child.Name == "Egg" then
            -- Wait a moment for click detector to be added
            wait(0.1)
            
            local clickDetector = child:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MouseClick:Connect(function(player)
                    if player == Player then
                        -- Extract egg ID from model (this would need to be set by server)
                        local eggId = child:GetAttribute("EggId")
                        if eggId then
                            handleEggClick(child, eggId)
                        end
                    end
                end)
            end
        end
    end)
    
    -- Setup click detection for existing eggs
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Part") and child.Name == "Egg" then
            local clickDetector = child:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MouseClick:Connect(function(player)
                    if player == Player then
                        local eggId = child:GetAttribute("EggId")
                        if eggId then
                            handleEggClick(child, eggId)
                        end
                    end
                end)
            end
        end
    end
end

-- Handle hatch celebration
local function showHatchCelebration(dragon)
    if not _G.MainUI then return end
    
    -- Show notification
    _G.MainUI.ShowNotification(
        "🥚 Hatched a " .. dragon.Rarity .. " " .. dragon.Element .. " Dragon!",
        Config.UI.RarityColors[dragon.Rarity]
    )
    
    -- Play hatch sound
    local hatchSound = Instance.new("Sound")
    hatchSound.SoundId = Config.Sounds.EggHatch
    hatchSound.Volume = 0.8
    hatchSound.Parent = SoundService
    hatchSound:Play()
    
    hatchSound.Ended:Connect(function()
        hatchSound:Destroy()
    end)
    
    -- Camera effect would go here (handled by CameraEffects.client.lua)
    if _G.CameraEffects then
        _G.CameraEffects.DragonHatchZoom()
    end
end

-- Setup remote event handlers
local function setupRemoteEvents()
    -- Show egg UI
    local showEggUI = RemoteEvents:FindFirstChild("ShowEggUI")
    if showEggUI then
        showEggUI.OnClientEvent:Connect(function(eggData)
            createEggProgressUI(eggData)
        end)
    end
    
    -- Egg hatched event
    local eggHatched = RemoteEvents:FindFirstChild("EggHatched")
    if eggHatched then
        eggHatched.OnClientEvent:Connect(function(eggId)
            print("Egg " .. eggId .. " hatched!")
            
            -- Remove from cooldowns
            clickCooldowns[eggId] = nil
        end)
    end
    
    -- Dragon hatched event (for celebration)
    local dragonHatched = RemoteEvents:FindFirstChild("DragonHatched")
    if dragonHatched then
        dragonHatched.OnClientEvent:Connect(function(dragon)
            showHatchCelebration(dragon)
        end)
    end
end

-- Main initialization
spawn(function()
    -- Wait for character
    if not Player.Character then
        Player.CharacterAdded:Wait()
    end
    
    wait(3) -- Let everything load
    
    setupEggClickDetection()
    setupRemoteEvents()
    
    print("EggInteraction client loaded successfully!")
end)

-- Public API
_G.EggInteraction = {
    HandleEggClick = handleEggClick,
    ShowHatchCelebration = showHatchCelebration
}