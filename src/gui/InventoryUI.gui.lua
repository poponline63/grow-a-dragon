--[[
    InventoryUI.gui.lua
    Dragon inventory with card grid layout for V3
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonData = require(ReplicatedStorage.Shared.DragonData)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local InventoryUI = {}
InventoryUI.IsVisible = false
InventoryUI.UIElements = {}
InventoryUI.DragonCards = {}
InventoryUI.CurrentFilter = "All"
InventoryUI.CurrentSort = "Name"

-- Create inventory screen
function InventoryUI.CreateInventoryScreen()
    local mainHUD = PlayerGui:WaitForChild("MainHUD")
    local mainFrame = mainHUD:WaitForChild("MainFrame")
    
    local inventoryFrame = Instance.new("Frame")
    inventoryFrame.Name = "InventoryScreen"
    inventoryFrame.Size = UDim2.new(1, 0, 1, -Config.UI.BottomBarHeight)
    inventoryFrame.Position = UDim2.new(0, 0, 0, 0)
    inventoryFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    inventoryFrame.BorderSizePixel = 0
    inventoryFrame.Visible = false
    inventoryFrame.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    header.BorderSizePixel = 0
    header.Parent = inventoryFrame
    
    -- Header gradient
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.15, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.15))
    }
    headerGradient.Rotation = 90
    headerGradient.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.4, 0, 1, 0)
    title.Position = UDim2.new(0.02, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐉 My Dragons"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Filter dropdown
    local filterFrame = InventoryUI.CreateDropdown("Filter", {"All", "Fire", "Ice", "Nature", "Shadow", "Light", "Storm"}, "All")
    filterFrame.Position = UDim2.new(0.5, 0, 0.1, 0)
    filterFrame.Size = UDim2.new(0.2, 0, 0.8, 0)
    filterFrame.Parent = header
    
    -- Sort dropdown
    local sortFrame = InventoryUI.CreateDropdown("Sort", {"Name", "Level", "Rarity", "Power"}, "Name")
    sortFrame.Position = UDim2.new(0.72, 0, 0.1, 0)
    sortFrame.Size = UDim2.new(0.2, 0, 0.8, 0)
    sortFrame.Parent = header
    
    -- Stats display
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -20, 0, 40)
    statsFrame.Position = UDim2.new(0, 10, 0, 70)
    statsFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = inventoryFrame
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, -20, 1, 0)
    statsLabel.Position = UDim2.new(0, 10, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Dragons: 0 | Total Power: 0 | Rarest: None"
    statsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.SourceSans
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = statsFrame
    
    -- Scroll frame for dragon cards
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "DragonScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -120)
    scrollFrame.Position = UDim2.new(0, 10, 0, 120)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.4, 0.4)
    scrollFrame.Parent = inventoryFrame
    
    -- Grid layout for cards
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, Config.UI.CardSize[1], 0, Config.UI.CardSize[2])
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Padding for grid
    local gridPadding = Instance.new("UIPadding")
    gridPadding.PaddingAll = UDim.new(0, 10)
    gridPadding.Parent = scrollFrame
    
    InventoryUI.UIElements.InventoryFrame = inventoryFrame
    InventoryUI.UIElements.ScrollFrame = scrollFrame
    InventoryUI.UIElements.StatsLabel = statsLabel
    InventoryUI.UIElements.FilterFrame = filterFrame
    InventoryUI.UIElements.SortFrame = sortFrame
    
    return inventoryFrame
end

-- Create dropdown component
function InventoryUI.CreateDropdown(label, options, defaultValue)
    local frame = Instance.new("Frame")
    frame.Name = label .. "Dropdown"
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Name = "DropdownButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = defaultValue .. " ▼"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSans
    button.Parent = frame
    
    -- Dropdown list (hidden by default)
    local listFrame = Instance.new("Frame")
    listFrame.Name = "ListFrame"
    listFrame.Size = UDim2.new(1, 0, 0, #options * 30)
    listFrame.Position = UDim2.new(0, 0, 1, 5)
    listFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = listFrame
    
    -- Create option buttons
    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.new(1, 1, 1)
        optionButton.TextScaled = true
        optionButton.Font = Enum.Font.SourceSans
        optionButton.Parent = listFrame
        
        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.35)
        end)
        
        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            button.Text = option .. " ▼"
            listFrame.Visible = false
            
            if label == "Filter" then
                InventoryUI.CurrentFilter = option
                InventoryUI.RefreshInventory()
            elseif label == "Sort" then
                InventoryUI.CurrentSort = option
                InventoryUI.RefreshInventory()
            end
        end)
    end
    
    -- Toggle dropdown
    button.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)
    
    return frame
end

-- Create dragon card
function InventoryUI.CreateDragonCard(dragon, layoutOrder)
    local card = Instance.new("Frame")
    card.Name = "DragonCard_" .. dragon.UniqueId
    card.Size = UDim2.new(0, Config.UI.CardSize[1], 0, Config.UI.CardSize[2])
    card.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    card.BorderSizePixel = 0
    card.LayoutOrder = layoutOrder or 1
    
    -- Card border based on rarity
    local rarityColor = Config.Rarities[1].Color
    for _, rarity in ipairs(Config.Rarities) do
        if rarity.Name == dragon.Rarity then
            rarityColor = rarity.Color
            break
        end
    end
    
    local border = Instance.new("UIStroke")
    border.Color = rarityColor
    border.Thickness = 3
    border.Parent = card
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    -- Dragon image/icon
    local imageFrame = Instance.new("Frame")
    imageFrame.Name = "ImageFrame"
    imageFrame.Size = UDim2.new(1, -10, 0.6, -5)
    imageFrame.Position = UDim2.new(0, 5, 0, 5)
    imageFrame.BackgroundColor3 = Config.ElementColors[dragon.Element]
    imageFrame.BorderSizePixel = 0
    imageFrame.Parent = card
    
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 8)
    imageCorner.Parent = imageFrame
    
    -- Dragon element icon
    local elementIcon = Instance.new("TextLabel")
    elementIcon.Size = UDim2.new(1, 0, 1, 0)
    elementIcon.BackgroundTransparency = 1
    elementIcon.Text = InventoryUI.GetElementIcon(dragon.Element)
    elementIcon.TextColor3 = Color3.new(1, 1, 1)
    elementIcon.TextScaled = true
    elementIcon.Font = Enum.Font.SourceSansBold
    elementIcon.Parent = imageFrame
    
    -- Variant indicator
    if dragon.Variant ~= "Normal" then
        local variantLabel = Instance.new("TextLabel")
        variantLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
        variantLabel.Position = UDim2.new(0.1, 0, 0, 0)
        variantLabel.BackgroundColor3 = Color3.new(0, 0, 0)
        variantLabel.BackgroundTransparency = 0.5
        variantLabel.Text = dragon.Variant
        variantLabel.TextColor3 = Color3.new(1, 1, 1)
        variantLabel.TextScaled = true
        variantLabel.Font = Enum.Font.SourceSansBold
        variantLabel.Parent = imageFrame
        
        local variantCorner = Instance.new("UICorner")
        variantCorner.CornerRadius = UDim.new(0, 4)
        variantCorner.Parent = variantLabel
    end
    
    -- Info section
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -10, 0.4, -10)
    infoFrame.Position = UDim2.new(0, 5, 0.6, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    -- Dragon name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = string.format("%s %s", dragon.Element, Config.GrowthStages[dragon.Stage].Name)
    nameLabel.TextColor3 = rarityColor
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame
    
    -- Level and rarity
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0.3, 0)
    levelLabel.Position = UDim2.new(0, 0, 0.35, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = string.format("Level %d | %s", dragon.Level, dragon.Rarity)
    levelLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = infoFrame
    
    -- Stats
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, 0, 0.3, 0)
    statsLabel.Position = UDim2.new(0, 0, 0.7, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = string.format("⚔️%d ⚡%d 🍀%d", dragon.Power, dragon.Speed, dragon.Luck)
    statsLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.SourceSans
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = infoFrame
    
    -- Click detection
    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.Parent = card
    
    clickDetector.MouseButton1Click:Connect(function()
        InventoryUI.ShowDragonDetails(dragon)
    end)
    
    -- Hover effects
    clickDetector.MouseEnter:Connect(function()
        InventoryUI.AnimateCardHover(card, true)
    end)
    
    clickDetector.MouseLeave:Connect(function()
        InventoryUI.AnimateCardHover(card, false)
    end)
    
    return card
end

-- Get element icon
function InventoryUI.GetElementIcon(element)
    local icons = {
        Fire = "🔥",
        Ice = "❄️", 
        Nature = "🌿",
        Shadow = "🌙",
        Light = "☀️",
        Storm = "⚡",
        Steam = "🌫️",
        Magma = "🌋",
        Plasma = "⚡",
        FrostBloom = "🌸",
        VoidIce = "🕳️",
        Solar = "☀️",
        Eclipse = "🌑",
        ThunderDark = "⛈️",
        Prism = "🌈",
        Tempest = "🌪️"
    }
    
    return icons[element] or "🐉"
end

-- Animate card hover
function InventoryUI.AnimateCardHover(card, isHovering)
    local targetScale = isHovering and 1.05 or 1
    
    local tween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, Config.UI.CardSize[1] * targetScale, 0, Config.UI.CardSize[2] * targetScale)
    })
    tween:Play()
end

-- Show dragon details modal
function InventoryUI.ShowDragonDetails(dragon)
    local mainHUD = PlayerGui:WaitForChild("MainHUD")
    local mainFrame = mainHUD:WaitForChild("MainFrame")
    
    -- Create modal background
    local modal = Instance.new("Frame")
    modal.Name = "DragonDetailsModal"
    modal.Size = UDim2.new(1, 0, 1, 0)
    modal.Position = UDim2.new(0, 0, 0, 0)
    modal.BackgroundColor3 = Color3.new(0, 0, 0)
    modal.BackgroundTransparency = 0.5
    modal.BorderSizePixel = 0
    modal.ZIndex = 5
    modal.Parent = mainFrame
    
    -- Details frame
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
    detailsFrame.Position = UDim2.new(0.15, 0, 0.1, 0)
    detailsFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    detailsFrame.BorderSizePixel = 0
    detailsFrame.ZIndex = 6
    detailsFrame.Parent = modal
    
    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UDim.new(0, 16)
    detailsCorner.Parent = detailsFrame
    
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
    closeButton.ZIndex = 7
    closeButton.Parent = detailsFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        modal:Destroy()
    end)
    
    -- Dragon details content
    local dragonName = DragonData.GetDisplayName(dragon)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 0.15, 0)
    title.Position = UDim2.new(0.1, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Text = dragonName
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.ZIndex = 6
    title.Parent = detailsFrame
    
    -- Additional details would go here...
    
    modal.MouseButton1Click:Connect(function()
        modal:Destroy()
    end)
end

-- Filter and sort dragons
function InventoryUI.FilterAndSortDragons(dragons)
    local filtered = {}
    
    -- Apply filter
    for _, dragon in ipairs(dragons) do
        if InventoryUI.CurrentFilter == "All" or dragon.Element == InventoryUI.CurrentFilter then
            table.insert(filtered, dragon)
        end
    end
    
    -- Apply sort
    if InventoryUI.CurrentSort == "Name" then
        table.sort(filtered, function(a, b) return a.Element < b.Element end)
    elseif InventoryUI.CurrentSort == "Level" then
        table.sort(filtered, function(a, b) return a.Level > b.Level end)
    elseif InventoryUI.CurrentSort == "Rarity" then
        table.sort(filtered, function(a, b)
            local aIndex, bIndex = 1, 1
            for i, rarity in ipairs(Config.Rarities) do
                if rarity.Name == a.Rarity then aIndex = i end
                if rarity.Name == b.Rarity then bIndex = i end
            end
            return aIndex > bIndex
        end)
    elseif InventoryUI.CurrentSort == "Power" then
        table.sort(filtered, function(a, b) return DragonData.GetPowerRating(a) > DragonData.GetPowerRating(b) end)
    end
    
    return filtered
end

-- Refresh inventory display
function InventoryUI.RefreshInventory()
    local scrollFrame = InventoryUI.UIElements.ScrollFrame
    if not scrollFrame then return end
    
    -- Clear existing cards
    for _, card in ipairs(InventoryUI.DragonCards) do
        card:Destroy()
    end
    InventoryUI.DragonCards = {}
    
    -- Get player data (would come from remote)
    -- For now, create mock data
    local mockDragons = {
        DragonData.CreateDragon("Fire", "Common", 2, "Normal"),
        DragonData.CreateDragon("Ice", "Rare", 3, "Shiny"),
        DragonData.CreateDragon("Nature", "Epic", 4, "Normal")
    }
    
    local filteredDragons = InventoryUI.FilterAndSortDragons(mockDragons)
    
    -- Create dragon cards
    for i, dragon in ipairs(filteredDragons) do
        local card = InventoryUI.CreateDragonCard(dragon, i)
        card.Parent = scrollFrame
        table.insert(InventoryUI.DragonCards, card)
    end
    
    -- Update stats
    local totalPower = 0
    local rarestRarity = "Common"
    for _, dragon in ipairs(mockDragons) do
        totalPower = totalPower + DragonData.GetPowerRating(dragon)
        -- Update rarest logic here
    end
    
    InventoryUI.UIElements.StatsLabel.Text = string.format("Dragons: %d | Total Power: %d | Rarest: %s", 
        #mockDragons, totalPower, rarestRarity)
end

-- Show inventory screen
function InventoryUI.Show()
    if not InventoryUI.UIElements.InventoryFrame then
        InventoryUI.CreateInventoryScreen()
    end
    
    InventoryUI.UIElements.InventoryFrame.Visible = true
    InventoryUI.IsVisible = true
    InventoryUI.RefreshInventory()
end

-- Hide inventory screen
function InventoryUI.Hide()
    if InventoryUI.UIElements.InventoryFrame then
        InventoryUI.UIElements.InventoryFrame.Visible = false
    end
    InventoryUI.IsVisible = false
end

return InventoryUI