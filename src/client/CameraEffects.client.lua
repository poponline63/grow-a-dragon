-- CameraEffects.client.lua - Camera animations and visual effects
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Camera state tracking
local originalCFrame = nil
local isAnimating = false
local shakeConnection = nil

-- Smooth camera on spawn
local function smoothSpawnCamera()
    if not Player.Character or not Player.Character.PrimaryPart then
        return
    end
    
    -- Start camera far away and zoom in smoothly
    local character = Player.Character
    local humanoidRootPart = character.PrimaryPart
    
    -- Set starting position (high and far)
    local startCFrame = CFrame.new(
        humanoidRootPart.Position + Vector3.new(0, 50, 30),
        humanoidRootPart.Position
    )
    
    -- Target position (normal follow camera position)
    local targetCFrame = CFrame.new(
        humanoidRootPart.Position + Vector3.new(0, 10, 20),
        humanoidRootPart.Position
    )
    
    -- Store original for restoration
    originalCFrame = Camera.CFrame
    
    -- Set starting position
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = startCFrame
    
    -- Animate to target
    local tween = TweenService:Create(Camera,
        TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {CFrame = targetCFrame}
    )
    
    tween:Play()
    
    -- Return to normal camera after animation
    tween.Completed:Connect(function()
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- Zoom to egg on hatch
local function zoomToEgg(eggPosition)
    if isAnimating then return end
    isAnimating = true
    
    -- Store current camera state
    originalCFrame = Camera.CFrame
    local originalType = Camera.CameraType
    
    -- Calculate zoom position
    local zoomCFrame = CFrame.new(
        eggPosition + Vector3.new(0, 5, 8),
        eggPosition
    )
    
    -- Set to scriptable camera
    Camera.CameraType = Enum.CameraType.Scriptable
    
    -- Zoom in
    local zoomTween = TweenService:Create(Camera,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CFrame = zoomCFrame}
    )
    zoomTween:Play()
    
    -- Hold for a moment, then zoom back
    zoomTween.Completed:Connect(function()
        wait(2) -- Hold zoom for 2 seconds
        
        -- Zoom back to original position
        local returnTween = TweenService:Create(Camera,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {CFrame = originalCFrame}
        )
        returnTween:Play()
        
        returnTween.Completed:Connect(function()
            Camera.CameraType = originalType
            isAnimating = false
        end)
    end)
end

-- Screen shake effect
local function screenShake(intensity, duration)
    if shakeConnection then
        shakeConnection:Disconnect()
    end
    
    local startTime = tick()
    intensity = intensity or 2
    duration = duration or 1
    
    shakeConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        
        if progress >= 1 then
            -- End shake
            shakeConnection:Disconnect()
            shakeConnection = nil
            return
        end
        
        -- Calculate shake amount (decreases over time)
        local currentIntensity = intensity * (1 - progress)
        
        -- Add random shake to camera
        local shakeOffset = Vector3.new(
            (math.random() - 0.5) * currentIntensity,
            (math.random() - 0.5) * currentIntensity,
            (math.random() - 0.5) * currentIntensity
        )
        
        if Camera.CameraType == Enum.CameraType.Custom then
            -- For custom camera, modify the subject position
            local character = Player.Character
            if character and character.PrimaryPart then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    Camera.CFrame = Camera.CFrame + shakeOffset * 0.5
                end
            end
        end
    end)
end

-- Dragon hatch zoom effect
local function dragonHatchZoom()
    -- Find the most recent egg or dragon in the world
    local targetPosition = nil
    
    -- Look for player's plot position (simplified)
    if Player.Character and Player.Character.PrimaryPart then
        local playerPos = Player.Character.PrimaryPart.Position
        targetPosition = playerPos + Vector3.new(10, 0, 0) -- Offset to plot
    end
    
    if targetPosition then
        zoomToEgg(targetPosition)
    end
    
    -- Add screen shake for legendary dragons
    screenShake(3, 2)
end

-- Smooth camera transition to location
local function smoothTransitionTo(targetPosition, duration, callback)
    if isAnimating then return end
    isAnimating = true
    
    originalCFrame = Camera.CFrame
    local originalType = Camera.CameraType
    
    duration = duration or 2
    
    local targetCFrame = CFrame.new(
        targetPosition + Vector3.new(0, 10, 15),
        targetPosition
    )
    
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local tween = TweenService:Create(Camera,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {CFrame = targetCFrame}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        if callback then
            callback()
        end
        
        -- Return to normal after a moment
        wait(1)
        
        local returnTween = TweenService:Create(Camera,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {CFrame = originalCFrame}
        )
        returnTween:Play()
        
        returnTween.Completed:Connect(function()
            Camera.CameraType = originalType
            isAnimating = false
        end)
    end)
end

-- Atmospheric lighting effects
local function createAtmosphericEffects()
    -- Add subtle color correction for fantasy mood
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.1
    colorCorrection.Contrast = 0.2
    colorCorrection.Saturation = 0.3
    colorCorrection.TintColor = Color3.new(1, 0.95, 0.9) -- Warm tint
    colorCorrection.Parent = Lighting
    
    -- Add bloom for magical glow
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.5
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting
    
    -- Add subtle depth of field
    local depthOfField = Instance.new("DepthOfFieldEffect")
    depthOfField.FarIntensity = 0.1
    depthOfField.FocusDistance = 50
    depthOfField.InFocusRadius = 20
    depthOfField.NearIntensity = 0.2
    depthOfField.Parent = Lighting
end

-- Level up camera celebration
local function levelUpCelebration()
    -- Quick zoom out then back in with particles
    if isAnimating then return end
    
    screenShake(1, 0.5)
    
    -- Flash the screen briefly
    local screenFlash = Instance.new("Frame")
    screenFlash.Size = UDim2.new(1, 0, 1, 0)
    screenFlash.Position = UDim2.new(0, 0, 0, 0)
    screenFlash.BackgroundColor3 = Color3.new(1, 1, 0.5)
    screenFlash.BackgroundTransparency = 0.7
    screenFlash.ZIndex = 1000
    screenFlash.Parent = Player.PlayerGui
    
    -- Fade out the flash
    local flashTween = TweenService:Create(screenFlash,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    flashTween:Play()
    
    flashTween.Completed:Connect(function()
        screenFlash:Destroy()
    end)
end

-- Initialize camera effects
local function initializeCameraEffects()
    -- Set up atmospheric effects
    createAtmosphericEffects()
    
    -- Handle character spawning
    Player.CharacterAdded:Connect(function(character)
        wait(2) -- Let character load
        smoothSpawnCamera()
    end)
    
    -- If character already exists
    if Player.Character then
        spawn(function()
            wait(2)
            smoothSpawnCamera()
        end)
    end
end

-- Handle remote events for camera effects
local function setupRemoteEventHandlers()
    local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
    local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    
    -- Dragon hatched - zoom effect
    local dragonHatched = RemoteEvents:FindFirstChild("DragonHatched")
    if dragonHatched then
        dragonHatched.OnClientEvent:Connect(function(dragon)
            -- Trigger zoom based on rarity
            local rarityIndex = 1
            for i, rarity in pairs(Config.Dragons.Rarities) do
                if rarity == dragon.Rarity then
                    rarityIndex = i
                    break
                end
            end
            
            if rarityIndex >= 5 then -- Legendary or Mythic
                dragonHatchZoom()
            elseif rarityIndex >= 3 then -- Rare or Epic
                screenShake(1, 1)
            end
        end)
    end
    
    -- Level up - celebration effect
    local levelUp = RemoteEvents:FindFirstChild("LevelUp")
    if levelUp then
        levelUp.OnClientEvent:Connect(function(newLevel)
            levelUpCelebration()
        end)
    end
end

-- Cleanup on leave
local function cleanup()
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
    
    Camera.CameraType = Enum.CameraType.Custom
    isAnimating = false
end

-- Main initialization
spawn(function()
    wait(2) -- Let everything load
    
    initializeCameraEffects()
    setupRemoteEventHandlers()
    
    print("CameraEffects client loaded successfully!")
end)

-- Handle cleanup on leave
game.Players.PlayerRemoving:Connect(function(player)
    if player == Player then
        cleanup()
    end
end)

-- Public API
_G.CameraEffects = {
    ScreenShake = screenShake,
    ZoomToEgg = zoomToEgg,
    DragonHatchZoom = dragonHatchZoom,
    SmoothTransitionTo = smoothTransitionTo,
    LevelUpCelebration = levelUpCelebration,
    SmoothSpawnCamera = smoothSpawnCamera
}