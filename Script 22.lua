local UNIVERSAL_KEY = "IGNIS"

local supportedGames = {
    ["Fate Trigger"] = {
        key = "tCHfkGJtnJH7436Gkh5G783GJHhlfl",
        link = "https://link-target.net/2973424/cKaMCYC79jKo"
    },
    ["SNIPER DUELS"] = {
        key = "kgj137GBh47hg&7jfhn23jghgjHGfk",
        link = "https://link-target.net/2973424/G5n4O7gXCmkK"
    },
    ["Flick"] = {
        key = "JFtzEY1d9LSRQ0oClcAfUBnNC",
        link = "https://link-hub.net/2973424/y0nX4fvHfFyk"
    },
    ["Quick Shot"] = {
        key = "djgjsklfghlkdfnwelljhijgbndfhfl",
        link = "https://link.com"
    },
    ["One Shot"] = {
        key = "djgjsklfghlkdfnwelljhijgbndfhfl",
        link = "https://link.com"
    }
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local gameName = "Unknown Game"
local success, result = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

if success and result then
    gameName = result
else
    local fallbackNames = {
        [game.PlaceId] = game.Name,
        [0] = workspace.Name
    }
    gameName = fallbackNames[game.PlaceId] or game.Name or "Unknown"
end

local currentGame = nil
local detectedGameName = "Universal"

for gameKey, gameData in pairs(supportedGames) do
    local nameCheck = gameName and (
        string.find(string.lower(gameName), string.lower(gameKey)) or
        string.find(string.lower(game.Name or ""), string.lower(gameKey)) or
        string.find(string.lower(workspace.Name or ""), string.lower(gameKey))
    )
    
    if nameCheck then
        currentGame = gameData
        detectedGameName = gameKey
        break
    end
end

if not currentGame then
    currentGame = {
        key = UNIVERSAL_KEY,
        link = "https://link.com"
    }
    detectedGameName = "Universal (Auto-detected)"
end

local validKey = currentGame.key
local keyLink = currentGame.link
local keyVerified = false

-- Game-specific health check
local function isHealthValid(humanoid)
    if not humanoid then return false end
    
    -- Flick needs stricter check (> 1 HP)
    if detectedGameName == "Flick" then
        return humanoid.Health > 1
    end
    
    -- Other games: >= 1 HP
    return humanoid.Health >= 1
end

local aimEnabled = false
local aimKey = Enum.KeyCode.E
local aimFOV = 200
local hitChances = {Head = 70, Torso = 30}
local showFOV = false
local wallCheck = true
local autoSwitchTarget = true
local aimSmoothness = 0.2
local autoAim = false
local smoothAim = true
local dynamicTargetSwitch = true

local speedhackEnabled = false
local speedMultiplier = 1
local defaultWalkSpeed = 16

local triggerbotEnabled = false
local triggerbotDelay = 0.15
local triggerbotMaxDistance = 1000

local chamsEnabled = false
local maxChamsDistance = 1000
local chamsColors = {
    visible = Color3.fromRGB(0, 255, 0),
    hidden = Color3.fromRGB(255, 0, 0)
}
local chamsTransparency = 0.3
local chamsFillTransparency = 0.5

local espEnabled = false
local showBoxes = true
local showHealthBar = true
local showNames = true
local maxESPDistance = 1000
local rgbBoxes = false
local rgbFOV = false
local boxColor = Color3.fromRGB(255, 255, 255)
local fovColor = Color3.fromRGB(255, 255, 255)
local boxThickness = 2
local healthBarHeight = 4
local nameColor = Color3.fromRGB(255, 255, 255)
local nameSize = 14

local aiming = false
local lockedTarget = nil
local lockedTargetPart = nil
local fovCircle = nil
local lastTriggerShot = 0
local chamsCache = {}
local espCache = {}
local charactersList = {}
local lastCharactersUpdate = 0
local charactersUpdateInterval = 3

local mobileAimButton = nil
local mobileAimActive = false
local mobileAimStrength = 0.25

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

local function getRainbowColor()
    local hue = (tick() * 100) % 360
    return Color3.fromHSV(hue / 360, 1, 1)
end

local function getMouseLocation()
    if isMobile then
        local viewportSize = camera.ViewportSize
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
    local mouseLocation = UserInputService:GetMouseLocation()
    return Vector2.new(mouseLocation.X, mouseLocation.Y)
end

local function createFOVCircle()
    local playerGui = player:WaitForChild("PlayerGui")
    local oldCircle = playerGui:FindFirstChild("FOVCircle")
    if oldCircle then
        oldCircle:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    
    local frame = Instance.new("Frame")
    frame.Name = "Circle"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(0, aimFOV * 2, 0, aimFOV * 2)
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    screenGui.Parent = playerGui
    
    return frame
end

local function isVisibleAim(targetPart)
    if not wallCheck then return true end
    if not targetPart or not targetPart.Parent then return false end
    
    local character = player.Character
    if not character then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if raycastResult then
        local hit = raycastResult.Instance
        local hitCharacter = hit:FindFirstAncestorOfClass("Model")
        
        if hitCharacter and hitCharacter == targetPart.Parent then
            return true
        end
        
        return false
    end
    
    return true
end

local function isVisibleChams(targetCharacter)
    if not targetCharacter then return false end
    
    local character = player.Character
    if not character then return false end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetRoot.Position - origin).Unit
    local distance = (targetRoot.Position - origin).Magnitude
    
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if raycastResult then
        local hit = raycastResult.Instance
        local hitCharacter = hit:FindFirstAncestorOfClass("Model")
        
        if hitCharacter and hitCharacter == targetCharacter then
            return true
        end
        
        return false
    end
    
    return true
end

local function selectTargetPart(character)
    local random = math.random(1, 100)
    local cumulative = 0
    
    for partName, chance in pairs(hitChances) do
        cumulative = cumulative + chance
        if random <= cumulative then
            if partName == "Head" then
                local head = character:FindFirstChild("Head")
                if head then
                    return head, "Head"
                end
            elseif partName == "Torso" then
                local torso = character:FindFirstChild("UpperTorso") 
                    or character:FindFirstChild("Torso")
                if torso then
                    return torso, "Torso"
                end
            end
        end
    end
    
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"), "Head"
end

local function updateCharactersList()
    charactersList = {}
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(charactersList, targetPlayer.Character)
            end
        end
    end
    
    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA("Model") and child ~= player.Character then
            local humanoid = child:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if not Players:GetPlayerFromCharacter(child) then
                    if child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head") then
                        table.insert(charactersList, child)
                    end
                end
            end
        end
        
        if child:IsA("Folder") or child:IsA("Model") then
            for _, subChild in pairs(child:GetChildren()) do
                if subChild:IsA("Model") and subChild ~= player.Character then
                    local humanoid = subChild:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        if not Players:GetPlayerFromCharacter(subChild) then
                            if subChild:FindFirstChild("HumanoidRootPart") or subChild:FindFirstChild("Head") then
                                table.insert(charactersList, subChild)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function findClosestTarget()
    local closestCharacter = nil
    local shortestDistance = aimFOV
    local mousePos = getMouseLocation()
    
    local function checkCharacter(character)
        if not character or not character.Parent then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        -- Game-specific health check
        if not isHealthValid(humanoid) then return end
        
        -- Additional triggerbot checks
        local isPlayer = Players:GetPlayerFromCharacter(character)
        local hasHRP = character:FindFirstChild("HumanoidRootPart")
        
        -- Must be player or have HRP (like triggerbot)
        if not (isPlayer or hasHRP) then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
        if not rootPart then return end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        
        if onScreen then
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            local distance = (mousePos - targetPos).Magnitude
            
            if distance < shortestDistance then
                if isVisibleAim(rootPart) then
                    closestCharacter = character
                    shortestDistance = distance
                end
            end
        end
    end
    
    for _, character in pairs(charactersList) do
        checkCharacter(character)
    end
    
    return closestCharacter
end

local function isTargetValid(targetCharacter, targetPart)
    if not targetCharacter or not targetCharacter.Parent then return false end
    if not targetPart or not targetPart.Parent then return false end
    
    -- Game-specific health check
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not isHealthValid(humanoid) then return false end
    
    -- Additional triggerbot checks
    local isPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    local hasHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    -- Must be player or have HRP (like triggerbot)
    if not (isPlayer or hasHRP) then return false end
    
    -- Additional checks for ragdoll/death state
    if humanoid.PlatformStand == true then return false end
    
    if not isVisibleAim(targetPart) then return false end
    
    return true
end

local function getTargetUnderCrosshair()
    local character = player.Character
    if not character then return nil end
    
    local origin = camera.CFrame.Position
    local direction = camera.CFrame.LookVector * triggerbotMaxDistance
    
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult then
        local hit = raycastResult.Instance
        local hitCharacter = hit:FindFirstAncestorOfClass("Model")
        
        if hitCharacter and hitCharacter ~= character then
            local humanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local isPlayer = Players:GetPlayerFromCharacter(hitCharacter)
                local hasHRP = hitCharacter:FindFirstChild("HumanoidRootPart")
                
                if isPlayer or hasHRP then
                    return hitCharacter
                end
            end
        end
    end
    
    return nil
end

local function createCham(character, color)
    local oldHighlight = character:FindFirstChild("ESP_Highlight")
    if oldHighlight then
        oldHighlight:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = chamsFillTransparency
    highlight.OutlineTransparency = chamsTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    return highlight
end

local function createESP(character)
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_Elements"
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    billboard.Size = UDim2.new(6, 0, 7, 0)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = espFolder
    
    local boxLines = {}
    for i = 1, 4 do
        local line = Instance.new("Frame")
        line.Name = "BoxLine" .. i
        line.BackgroundColor3 = boxColor
        line.BorderSizePixel = 0
        line.Visible = false
        line.Parent = billboard
        boxLines[i] = line
    end
    
    boxLines[1].Size = UDim2.new(1, 0, 0, boxThickness)
    boxLines[1].Position = UDim2.new(0, 0, 0, 0)
    
    boxLines[2].Size = UDim2.new(1, 0, 0, boxThickness)
    boxLines[2].Position = UDim2.new(0, 0, 1, -boxThickness)
    
    boxLines[3].Size = UDim2.new(0, boxThickness, 1, 0)
    boxLines[3].Position = UDim2.new(0, 0, 0, 0)
    
    boxLines[4].Size = UDim2.new(0, boxThickness, 1, 0)
    boxLines[4].Position = UDim2.new(1, -boxThickness, 0, 0)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, nameSize)
    nameLabel.Position = UDim2.new(0, 0, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = nameColor
    nameLabel.TextSize = nameSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Visible = showNames
    nameLabel.Parent = billboard
    
    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarBG"
    healthBarBG.Size = UDim2.new(0, 5, 0.8, 0)
    healthBarBG.Position = UDim2.new(0, 5, 0.1, 0)
    healthBarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBG.BorderSizePixel = 0
    healthBarBG.Visible = showHealthBar
    healthBarBG.Parent = billboard
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBG
    
    return espFolder, billboard, boxLines
end

local function addChams(character)
    if not chamsEnabled then return end
    if not character then return end
    if character == player.Character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local highlight = createCham(character, chamsColors.hidden)
    
    chamsCache[character] = {
        highlight = highlight,
        character = character,
        lastVisibilityCheck = 0
    }
end

local function addESP(character)
    if not espEnabled then return end
    if not character then return end
    if character == player.Character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local oldESP = character:FindFirstChild("ESP_Elements")
    if oldESP then
        oldESP:Destroy()
    end
    
    local espFolder, billboard, boxLines = createESP(character)
    billboard.Adornee = rootPart
    espFolder.Parent = character
    
    local characterName = character.Name
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if targetPlayer then
        characterName = targetPlayer.Name
    end
    
    espCache[character] = {
        character = character,
        billboard = billboard,
        boxLines = boxLines,
        name = characterName
    }
end

local function removeChams(character)
    if chamsCache[character] then
        local data = chamsCache[character]
        if data.highlight then
            pcall(function()
                if data.highlight.Parent then
                    data.highlight:Destroy()
                end
            end)
        end
        chamsCache[character] = nil
    end
    
    if character then
        local oldHighlight = character:FindFirstChild("ESP_Highlight")
        if oldHighlight then
            pcall(function()
                oldHighlight:Destroy()
            end)
        end
    end
end

local function removeESP(character)
    if espCache[character] then
        local data = espCache[character]
        
        if data.billboard then
            pcall(function()
                if data.billboard.Parent then
                    data.billboard.Enabled = false
                    data.billboard:Destroy()
                end
            end)
            data.billboard = nil
        end
        
        espCache[character] = nil
    end
    
    if character then
        local oldESP = character:FindFirstChild("ESP_Elements")
        if oldESP then
            pcall(function()
                oldESP:Destroy()
            end)
        end
    end
end

local function validateAndRestoreCham(character, data)
    if not data.highlight or not data.highlight.Parent or data.highlight.Adornee ~= character then
        local newHighlight = createCham(character, chamsColors.hidden)
        data.highlight = newHighlight
        return true
    end
    return false
end

local visibilityCheckInterval = 0.3
local currentTime = 0

local function updateChamsColors()
    if not chamsEnabled then return end
    
    currentTime = tick()
    local toRemove = {}
    
    for character, data in pairs(chamsCache) do
        local shouldRemove = false
        local shouldSkip = false
        
        if not character or not character.Parent then
            shouldRemove = true
        elseif not shouldRemove then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                shouldRemove = true
            end
        end
        
        if not shouldRemove and player.Character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            
            if rootPart and playerRoot then
                local distance = (rootPart.Position - playerRoot.Position).Magnitude
                
                if distance > maxChamsDistance then
                    if data.highlight then
                        data.highlight.Enabled = false
                    end
                    shouldSkip = true
                elseif data.highlight then
                    data.highlight.Enabled = true
                end
            end
        end
        
        if shouldRemove then
            table.insert(toRemove, character)
        elseif not shouldSkip then
            validateAndRestoreCham(character, data)
            
            if currentTime - data.lastVisibilityCheck > visibilityCheckInterval then
                data.lastVisibilityCheck = currentTime
                
                if data.highlight and data.highlight.Parent then
                    local visible = isVisibleChams(character)
                    local newColor = visible and chamsColors.visible or chamsColors.hidden
                    
                    pcall(function()
                        data.highlight.FillColor = newColor
                        data.highlight.OutlineColor = newColor
                    end)
                end
            end
        end
    end
    
    for _, character in pairs(toRemove) do
        removeChams(character)
    end
end

local function updateESP()
    if not espEnabled then return end
    
    local toRemove = {}
    
    for character, data in pairs(espCache) do
        local shouldRemove = false
        local shouldSkip = false
        
        if not character or not character.Parent then
            shouldRemove = true
        elseif not shouldRemove then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                shouldRemove = true
            end
        end
        
        if not shouldRemove then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart and player.Character then
                local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    local distance = (rootPart.Position - playerRoot.Position).Magnitude
                    
                    if distance > maxESPDistance then
                        if data.billboard then
                            data.billboard.Enabled = false
                        end
                        
                        shouldSkip = true
                    elseif data.billboard then
                        data.billboard.Enabled = true
                    end
                end
            end
        end
        
        if shouldRemove then
            table.insert(toRemove, character)
        elseif not shouldSkip then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if showBoxes and data.boxLines then
                local currentBoxColor = rgbBoxes and getRainbowColor() or boxColor
                
                for _, line in pairs(data.boxLines) do
                    line.BackgroundColor3 = currentBoxColor
                    line.Visible = true
                end
            elseif data.boxLines then
                for _, line in pairs(data.boxLines) do
                    line.Visible = false
                end
            end
            
            if showNames and data.billboard then
                local nameLabel = data.billboard:FindFirstChild("NameLabel")
                if nameLabel then
                    nameLabel.Text = data.name
                    nameLabel.Visible = true
                end
            elseif data.billboard then
                local nameLabel = data.billboard:FindFirstChild("NameLabel")
                if nameLabel then
                    nameLabel.Visible = false
                end
            end
            
            if showHealthBar and data.billboard and humanoid then
                local healthBarBG = data.billboard:FindFirstChild("HealthBarBG")
                if healthBarBG then
                    local healthBar = healthBarBG:FindFirstChild("HealthBar")
                    if healthBar then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                        
                        if healthPercent > 0.6 then
                            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        elseif healthPercent > 0.3 then
                            healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                        else
                            healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        end
                        
                        healthBarBG.Visible = true
                    end
                end
            elseif data.billboard then
                local healthBarBG = data.billboard:FindFirstChild("HealthBarBG")
                if healthBarBG then
                    healthBarBG.Visible = false
                end
            end
        end
    end
    
    for _, character in pairs(toRemove) do
        removeESP(character)
    end
end

local function updateAllChams()
    if not chamsEnabled then return end
    
    for character, data in pairs(chamsCache) do
        if not character or not character.Parent then
            removeChams(character)
        else
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                removeChams(character)
            else
                validateAndRestoreCham(character, data)
            end
        end
    end
    
    for _, character in pairs(charactersList) do
        if not chamsCache[character] then
            addChams(character)
        end
    end
end

local function updateAllESP()
    if not espEnabled then return end
    
    for character, data in pairs(espCache) do
        if not character or not character.Parent then
            removeESP(character)
        else
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                removeESP(character)
            end
        end
    end
    
    for _, character in pairs(charactersList) do
        if not espCache[character] then
            addESP(character)
        end
    end
end

function removeAllChams()
    for character, _ in pairs(chamsCache) do
        removeChams(character)
    end
    chamsCache = {}
end

function removeAllESP()
    for character, _ in pairs(espCache) do
        removeESP(character)
    end
    espCache = {}
end

local function createMenu()
    local menuOpen = false
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HvHMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.BorderSizePixel = 0
    title.Text = "Ignis"
    title.TextColor3 = Color3.fromRGB(255, 140, 0)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 100, 0)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = title
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.Position = UDim2.new(0, 0, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -95)
    contentContainer.Position = UDim2.new(0, 10, 0, 85)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    local function createTab(name, position)
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Size = UDim2.new(0, 120, 0, 30)
        tab.Position = UDim2.new(0, position, 0, 0)
        tab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        tab.BorderSizePixel = 0
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(200, 200, 200)
        tab.TextSize = 16
        tab.Font = Enum.Font.GothamBold
        tab.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab
        
        return tab
    end
    
    local combatTab = createTab("Combat", 10)
    local visualsTab = createTab("Visuals", 140)
    
    local function createScrollFrame()
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Visible = false
        scrollFrame.Parent = contentContainer
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scrollFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        return scrollFrame
    end
    
    local combatContent = createScrollFrame()
    local visualsContent = createScrollFrame()
    
    local function createCheckbox(parent, text, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = parent
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local checkbox = Instance.new("TextButton")
        checkbox.Size = UDim2.new(0, 20, 0, 20)
        checkbox.Position = UDim2.new(1, -25, 0.5, -10)
        checkbox.BackgroundColor3 = defaultValue and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(60, 60, 60)
        checkbox.BorderSizePixel = 0
        checkbox.Text = ""
        checkbox.Parent = frame
        
        local checkCorner = Instance.new("UICorner")
        checkCorner.CornerRadius = UDim.new(0, 4)
        checkCorner.Parent = checkbox
        
        checkbox.MouseButton1Click:Connect(function()
            defaultValue = not defaultValue
            checkbox.BackgroundColor3 = defaultValue and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(60, 60, 60)
            callback(defaultValue)
        end)
        
        return frame
    end
    
    local function createSlider(parent, text, min, max, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = parent
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(defaultValue)
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local sliderBG = Instance.new("Frame")
        sliderBG.Size = UDim2.new(1, -20, 0, 10)
        sliderBG.Position = UDim2.new(0, 10, 0, 30)
        sliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sliderBG.BorderSizePixel = 0
        sliderBG.Parent = frame
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(1, 0)
        sliderCorner.Parent = sliderBG
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBG
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = sliderFill
        
        local dragging = false
        
        local function updateSlider(input)
            local mousePos = input.Position.X
            local sliderPos = sliderBG.AbsolutePosition.X
            local sliderSize = sliderBG.AbsoluteSize.X
            
            local value = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
            local actualValue = math.floor(min + (max - min) * value)
            
            sliderFill.Size = UDim2.new(value, 0, 1, 0)
            label.Text = text .. ": " .. tostring(actualValue)
            callback(actualValue)
        end
        
        sliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
            end
        end)
        
        sliderBG.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)
        
        return frame
    end

    local function createKeybind(parent, text, defaultKey, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = parent
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -120, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local function getButtonName(inputType, keyCode)
            if inputType == Enum.UserInputType.MouseButton1 then
                return "LMB"
            elseif inputType == Enum.UserInputType.MouseButton2 then
                return "RMB"
            elseif inputType == Enum.UserInputType.MouseButton3 then
                return "MMB"
            elseif keyCode == Enum.KeyCode.ButtonX1 or keyCode == Enum.KeyCode.ButtonX then
                return "Mouse4"
            elseif keyCode == Enum.KeyCode.ButtonX2 then
                return "Mouse5"
            elseif keyCode then
                return keyCode.Name
            else
                return "Unknown"
            end
        end
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 0, 20)
        button.Position = UDim2.new(1, -105, 0.5, -10)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BorderSizePixel = 0
        button.Text = type(defaultKey) == "table" and getButtonName(defaultKey.inputType, defaultKey.keyCode) or defaultKey.Name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.Parent = frame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        local listening = false
        local currentKey = defaultKey
        
        button.MouseButton1Click:Connect(function()
            if not listening then
                listening = true
                button.Text = "..."
                button.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            button.Text = type(currentKey) == "table" and getButtonName(currentKey.inputType, currentKey.keyCode) or currentKey.Name
                            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            listening = false
                            connection:Disconnect()
                            return
                        end
                        
                        currentKey = input.KeyCode
                        button.Text = input.KeyCode.Name
                        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        listening = false
                        connection:Disconnect()
                        callback(input.KeyCode, nil)
                    
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or 
                        input.UserInputType == Enum.UserInputType.MouseButton2 or 
                        input.UserInputType == Enum.UserInputType.MouseButton3 then
                        
                        currentKey = {inputType = input.UserInputType, keyCode = nil}
                        button.Text = getButtonName(input.UserInputType, nil)
                        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        listening = false
                        connection:Disconnect()
                        callback(nil, input.UserInputType)
                    end
                end)
            end
        end)
        
        return frame
    end
    
    local function createButton(parent, text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.GothamBold
        button.Parent = parent
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(callback)
        
        return button
    end
    
    createCheckbox(combatContent, "Aimbot", aimEnabled, function(value)
        aimEnabled = value
        
        if fovCircle then
            fovCircle.Visible = value and showFOV
        end
        
        if isMobile and mobileAimButton then
            mobileAimButton.Visible = value
        end
    end)

    if not isMobile then
        createKeybind(combatContent, "Aim Key", aimKey, function(newKey)
            aimKey = newKey
        end)
    end

    createSlider(combatContent, "FOV Size", 50, 500, aimFOV, function(value)
        aimFOV = value
        if fovCircle then
            fovCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
        end
    end)

    createCheckbox(combatContent, "Show FOV Circle", showFOV, function(value)
        showFOV = value
        
        if value and not fovCircle then
            fovCircle = createFOVCircle()
        end
        
        if fovCircle then
            fovCircle.Visible = value and aimEnabled
        end
    end)

    createCheckbox(combatContent, "Wall Check", wallCheck, function(value)
        wallCheck = value
    end)
    
    createCheckbox(combatContent, "Auto Switch Target", autoSwitchTarget, function(value)
        autoSwitchTarget = value
    end)
    
    createCheckbox(combatContent, "Auto Aim", autoAim, function(value)
        autoAim = value
    end)
    
    createCheckbox(combatContent, "Dynamic Target Switch", dynamicTargetSwitch, function(value)
        dynamicTargetSwitch = value
    end)
    
    createCheckbox(combatContent, "Smooth Aim", smoothAim, function(value)
        smoothAim = value
    end)
    
    createSlider(combatContent, "Aim Smoothness", 5, 50, aimSmoothness * 100, function(value)
        aimSmoothness = value / 100
    end)

    createSlider(combatContent, "Head Chance %", 0, 100, hitChances.Head, function(value)
        hitChances.Head = value
        hitChances.Torso = 100 - value
    end)

    createCheckbox(combatContent, "Triggerbot", triggerbotEnabled, function(value)
        triggerbotEnabled = value
    end)

    createSlider(combatContent, "Triggerbot Delay", 0, 500, triggerbotDelay * 1000, function(value)
        triggerbotDelay = value / 1000
    end)
    
    createCheckbox(combatContent, "Speed Hack", speedhackEnabled, function(value)
        speedhackEnabled = value
        
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if value then
                    humanoid.WalkSpeed = defaultWalkSpeed * speedMultiplier
                else
                    humanoid.WalkSpeed = defaultWalkSpeed
                end
            end
        end
    end)
    
    
    createSlider(combatContent, "Speed Multiplier", 1, 5, speedMultiplier, function(value)
        speedMultiplier = value
        
        if speedhackEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = defaultWalkSpeed * speedMultiplier
            end
        end
    end)
    
    createCheckbox(visualsContent, "Chams", chamsEnabled, function(value)
        chamsEnabled = value
        if not value then
            removeAllChams()
        end
    end)
    
    createSlider(visualsContent, "Chams Distance", 100, 2000, maxChamsDistance, function(value)
        maxChamsDistance = value
    end)
    
    createCheckbox(visualsContent, "ESP", espEnabled, function(value)
        espEnabled = value
        if not value then
            removeAllESP()
        end
    end)
    
    createSlider(visualsContent, "ESP Distance", 100, 2000, maxESPDistance, function(value)
        maxESPDistance = value
    end)
    
    createCheckbox(visualsContent, "Show Boxes", showBoxes, function(value)
        showBoxes = value
    end)
    
    createCheckbox(visualsContent, "RGB Boxes", rgbBoxes, function(value)
        rgbBoxes = value
    end)
    
    createSlider(visualsContent, "Box Thickness", 1, 5, boxThickness, function(value)
        boxThickness = value
    end)
    
    createCheckbox(visualsContent, "RGB FOV Circle", rgbFOV, function(value)
        rgbFOV = value
    end)
    
    createCheckbox(visualsContent, "Show Health Bar", showHealthBar, function(value)
        showHealthBar = value
    end)
    
    createCheckbox(visualsContent, "Show Names", showNames, function(value)
        showNames = value
    end)
    
    createSlider(visualsContent, "Name Size", 10, 20, nameSize, function(value)
        nameSize = value
    end)
    
    local function switchTab(tab, content)
        combatTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        visualsTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        combatTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        visualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        combatContent.Visible = false
        visualsContent.Visible = false
        
        tab.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        content.Visible = true
    end
    
    combatTab.MouseButton1Click:Connect(function()
        switchTab(combatTab, combatContent)
    end)
    
    visualsTab.MouseButton1Click:Connect(function()
        switchTab(visualsTab, visualsContent)
    end)
    
    switchTab(combatTab, combatContent)
    
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        menuOpen = false
    end)
    
    local dragging = false
    local dragInput, mousePos, framePos
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local menuButton = Instance.new("TextButton")
    menuButton.Name = "MenuButton"
    menuButton.Size = UDim2.new(0, 50, 0, 50)
    menuButton.Position = UDim2.new(0, 10, 0, 10)
    menuButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    menuButton.BorderSizePixel = 0
    menuButton.Text = "🔥"
    menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuButton.TextSize = 28
    menuButton.Font = Enum.Font.GothamBold
    menuButton.Parent = screenGui
    
    local menuBtnCorner = Instance.new("UICorner")
    menuBtnCorner.CornerRadius = UDim.new(0, 8)
    menuBtnCorner.Parent = menuButton
    
    menuButton.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        mainFrame.Visible = menuOpen
    end)
    
    if isMobile then
        mobileAimButton = Instance.new("TextButton")
        mobileAimButton.Name = "MobileAimButton"
        mobileAimButton.Size = UDim2.new(0, 70, 0, 70)
        mobileAimButton.Position = UDim2.new(1, -80, 1, -150)
        mobileAimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        mobileAimButton.BorderSizePixel = 0
        mobileAimButton.Text = "🎯"
        mobileAimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        mobileAimButton.TextSize = 32
        mobileAimButton.Font = Enum.Font.GothamBold
        mobileAimButton.Visible = true
        mobileAimButton.Parent = screenGui
        
        local aimBtnCorner = Instance.new("UICorner")
        aimBtnCorner.CornerRadius = UDim.new(1, 0)
        aimBtnCorner.Parent = mobileAimButton
        
        local aimBtnStroke = Instance.new("UIStroke")
        aimBtnStroke.Color = Color3.fromRGB(255, 140, 0)
        aimBtnStroke.Thickness = 3
        aimBtnStroke.Parent = mobileAimButton
        
        mobileAimButton.MouseButton1Click:Connect(function()
            mobileAimActive = not mobileAimActive
            
            if mobileAimActive then
                local targetCharacter = findClosestTarget()
                if targetCharacter then
                    aiming = true
                    lockedTarget = targetCharacter
                    local part = selectTargetPart(targetCharacter)
                    lockedTargetPart = part
                    mobileAimButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                else
                    mobileAimActive = false
                end
            else
                mobileAimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
            end
        end)
    end
    
    if not isMobile then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == Enum.KeyCode.RightShift then
                menuOpen = not menuOpen
                mainFrame.Visible = menuOpen
            end
        end)
    end
    
    return screenGui
end

local function createKeySystem()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 2000
    
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.BorderSizePixel = 0
    title.Text = "Ignis - Key System"
    title.TextColor3 = Color3.fromRGB(255, 140, 0)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Name = "GameInfo"
    gameInfo.Size = UDim2.new(1, -40, 0, 20)
    gameInfo.Position = UDim2.new(0, 20, 0, 55)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "🎮 Detected: " .. detectedGameName
    gameInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
    gameInfo.TextSize = 12
    gameInfo.Font = Enum.Font.GothamBold
    gameInfo.Parent = mainFrame
    
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -40, 0, 30)
    description.Position = UDim2.new(0, 20, 0, 75)
    description.BackgroundTransparency = 1
    description.Text = "Enter your key to continue (Universal key: IGNIS)"
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.Parent = mainFrame
    
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -40, 0, 40)
    keyInput.Position = UDim2.new(0, 20, 0, 100)
    keyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    keyInput.BorderSizePixel = 0
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter key here..."
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    keyInput.TextSize = 16
    keyInput.Font = Enum.Font.Gotham
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = keyInput
    
    local redeemButton = Instance.new("TextButton")
    redeemButton.Name = "RedeemButton"
    redeemButton.Size = UDim2.new(1, -40, 0, 40)
    redeemButton.Position = UDim2.new(0, 20, 0, 155)
    redeemButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    redeemButton.BorderSizePixel = 0
    redeemButton.Text = "Redeem Key"
    redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    redeemButton.TextSize = 16
    redeemButton.Font = Enum.Font.GothamBold
    redeemButton.Parent = mainFrame
    
    local redeemCorner = Instance.new("UICorner")
    redeemCorner.CornerRadius = UDim.new(0, 6)
    redeemCorner.Parent = redeemButton
    
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(1, -40, 0, 35)
    copyButton.Position = UDim2.new(0, 20, 0, 205)
    copyButton.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    copyButton.BorderSizePixel = 0
    copyButton.Text = "Copy Link"
    copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyButton.TextSize = 14
    copyButton.Font = Enum.Font.GothamBold
    copyButton.Parent = mainFrame
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyButton
    
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Name = "ErrorLabel"
    errorLabel.Size = UDim2.new(1, -40, 0, 20)
    errorLabel.Position = UDim2.new(0, 20, 0, 145)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = ""
    errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    errorLabel.TextSize = 12
    errorLabel.Font = Enum.Font.Gotham
    errorLabel.Visible = false
    errorLabel.Parent = mainFrame
    
    local function checkKey()
        local enteredKey = keyInput.Text
        
        if enteredKey == validKey or enteredKey == UNIVERSAL_KEY then
            keyVerified = true
            
            redeemButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            redeemButton.Text = "✓ Success!"
            
            wait(0.5)
            
            screenGui:Destroy()
            
            wait(0.2)
            local menuGui = createMenu()
            
            local notificationGui = Instance.new("ScreenGui")
            notificationGui.Name = "NotificationGui"
            notificationGui.ResetOnSpawn = false
            notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            notificationGui.DisplayOrder = 3000
            
            local notification = Instance.new("Frame")
            notification.Name = "Notification"
            notification.Size = UDim2.new(0, 300, 0, 80)
            notification.Position = UDim2.new(1, 320, 1, -100)
            notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            notification.BorderSizePixel = 0
            notification.Parent = notificationGui
            
            local notifCorner = Instance.new("UICorner")
            notifCorner.CornerRadius = UDim.new(0, 8)
            notifCorner.Parent = notification
            
            local notifStroke = Instance.new("UIStroke")
            notifStroke.Color = Color3.fromRGB(255, 140, 0)
            notifStroke.Thickness = 2
            notifStroke.Parent = notification
            
            local emojiLabel = Instance.new("TextLabel")
            emojiLabel.Name = "Emoji"
            emojiLabel.Size = UDim2.new(0, 50, 0, 50)
            emojiLabel.Position = UDim2.new(0, 10, 0.5, -25)
            emojiLabel.BackgroundTransparency = 1
            emojiLabel.Text = "🔥"
            emojiLabel.TextSize = 40
            emojiLabel.Font = Enum.Font.GothamBold
            emojiLabel.Parent = notification
            
            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(1, -70, 0, 25)
            title.Position = UDim2.new(0, 65, 0, 10)
            title.BackgroundTransparency = 1
            title.Text = "🔥 Ignis Loaded!"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextSize = 16
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = notification
            
            local description = Instance.new("TextLabel")
            description.Name = "Description"
            description.Size = UDim2.new(1, -70, 0, 35)
            description.Position = UDim2.new(0, 65, 0, 35)
            description.BackgroundTransparency = 1
            description.Text = isMobile and "Tap 🔥 to open menu. Use 🎯 for aim toggle" or "Press RightShift or click 🔥 to open menu"
            description.TextColor3 = Color3.fromRGB(200, 200, 200)
            description.TextSize = 13
            description.Font = Enum.Font.Gotham
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.TextWrapped = true
            description.Parent = notification
            
            notificationGui.Parent = player:WaitForChild("PlayerGui")
            
            notification:TweenPosition(
                UDim2.new(1, -310, 1, -100),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.5,
                true
            )
            
            spawn(function()
                wait(5)
                notification:TweenPosition(
                    UDim2.new(1, 320, 1, -100),
                    Enum.EasingDirection.In,
                    Enum.EasingStyle.Back,
                    0.4,
                    true
                )
                wait(0.5)
                notificationGui:Destroy()
            end)
            
        else
            errorLabel.Text = "Invalid key!"
            errorLabel.Visible = true
            redeemButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            
            wait(1)
            
            redeemButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            errorLabel.Visible = false
        end
    end

    redeemButton.MouseButton1Click:Connect(function()
        checkKey()
    end)

    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            checkKey()
        end
    end)

    copyButton.MouseButton1Click:Connect(function()
        setclipboard(keyLink)
        
        copyButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        copyButton.Text = "✓ Copied!"
        
        wait(1)
        
        copyButton.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
        copyButton.Text = "Copy Link"
    end)

    screenGui.Parent = player:WaitForChild("PlayerGui")

    return screenGui
end

spawn(function()
    wait(1)
    createKeySystem()
end)

spawn(function()
    wait(0.1)
    fovCircle = createFOVCircle()
end)

if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not aimEnabled then return end
        
        if input.KeyCode == aimKey then
            if not aiming then
                local targetCharacter = findClosestTarget()
                
                if targetCharacter then
                    aiming = true
                    lockedTarget = targetCharacter
                    local part, partName = selectTargetPart(targetCharacter)
                    lockedTargetPart = part
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == aimKey then
            if aiming then
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
            end
        end
    end)
end

spawn(function()
    while true do
        wait()
        
        if fovCircle and fovCircle.Parent then
            if not aimEnabled or not showFOV then 
                fovCircle.Visible = false
            else
                fovCircle.Visible = true
                local mousePos = getMouseLocation()
                fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
                
                local stroke = fovCircle:FindFirstChildOfClass("UIStroke")
                if stroke then
                    if aiming and lockedTarget then
                        stroke.Color = Color3.fromRGB(0, 255, 0)
                    elseif rgbFOV then
                        stroke.Color = getRainbowColor()
                    else
                        stroke.Color = fovColor
                    end
                end
            end
        end
    end
end)

if isMobile then
    RunService.RenderStepped:Connect(function()
        if not aimEnabled then return end
        
        if autoAim and not aiming then
            local targetCharacter = findClosestTarget()
            if targetCharacter then
                -- Verify target is alive before locking
                local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
                if isHealthValid(targetHumanoid) then
                    aiming = true
                    lockedTarget = targetCharacter
                    local part = selectTargetPart(targetCharacter)
                    lockedTargetPart = part
                    
                    if mobileAimButton then
                        mobileAimButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    end
                end
            end
        end
        
        if not aiming then return end
        
        if dynamicTargetSwitch and aiming then
            local newTarget = findClosestTarget()
            if newTarget and newTarget ~= lockedTarget then
                -- Verify new target is alive
                local newHumanoid = newTarget:FindFirstChildOfClass("Humanoid")
                if isHealthValid(newHumanoid) then
                    local mousePos = getMouseLocation()
                    
                    local currentPart = lockedTargetPart
                    local currentScreenPos, currentOnScreen = camera:WorldToViewportPoint(currentPart.Position)
                    local currentDistance = (mousePos - Vector2.new(currentScreenPos.X, currentScreenPos.Y)).Magnitude
                    
                    local newPart = selectTargetPart(newTarget)
                    local newScreenPos, newOnScreen = camera:WorldToViewportPoint(newPart.Position)
                    local newDistance = (mousePos - Vector2.new(newScreenPos.X, newScreenPos.Y)).Magnitude
                    
                    if newOnScreen and newDistance < currentDistance then
                        lockedTarget = newTarget
                        lockedTargetPart = newPart
                    end
                end
            end
        end
        
        if not isTargetValid(lockedTarget, lockedTargetPart) then
            aiming = false
            lockedTarget = nil
            lockedTargetPart = nil
            mobileAimActive = false
            if mobileAimButton then
                mobileAimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            return
        end
        
        if lockedTargetPart and lockedTargetPart.Parent and lockedTarget then
            -- Game-specific health check before camera movement
            local targetHumanoid = lockedTarget:FindFirstChildOfClass("Humanoid")
            
            -- Flick: > 1 HP, Others: >= 1 HP
            if not isHealthValid(targetHumanoid) then
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
                mobileAimActive = false
                if mobileAimButton then
                    mobileAimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
                return
            end
            
            local targetPos = lockedTargetPart.Position
            local cameraPos = camera.CFrame.Position
            
            if smoothAim then
                local targetDirection = (targetPos - cameraPos).Unit
                local currentLook = camera.CFrame.LookVector
                
                local smoothedLook = currentLook:Lerp(targetDirection, aimSmoothness)
                
                camera.CFrame = CFrame.new(cameraPos, cameraPos + smoothedLook)
            else
                camera.CFrame = CFrame.new(cameraPos, targetPos)
            end
        end
    end)
else
    RunService.RenderStepped:Connect(function()
        if not aimEnabled then return end
        
        if autoAim and not aiming then
            local targetCharacter = findClosestTarget()
            if targetCharacter then
                -- Verify target is alive before locking
                local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
                if isHealthValid(targetHumanoid) then
                    aiming = true
                    lockedTarget = targetCharacter
                    local part = selectTargetPart(targetCharacter)
                    lockedTargetPart = part
                end
            end
        end
        
        if not aiming then return end
        
        if dynamicTargetSwitch and aiming then
            local newTarget = findClosestTarget()
            if newTarget and newTarget ~= lockedTarget then
                -- Verify new target is alive
                local newHumanoid = newTarget:FindFirstChildOfClass("Humanoid")
                if isHealthValid(newHumanoid) then
                    local mousePos = getMouseLocation()
                    
                    local currentPart = lockedTargetPart
                    local currentScreenPos, currentOnScreen = camera:WorldToViewportPoint(currentPart.Position)
                    local currentDistance = (mousePos - Vector2.new(currentScreenPos.X, currentScreenPos.Y)).Magnitude
                    
                    local newPart = selectTargetPart(newTarget)
                    local newScreenPos, newOnScreen = camera:WorldToViewportPoint(newPart.Position)
                    local newDistance = (mousePos - Vector2.new(newScreenPos.X, newScreenPos.Y)).Magnitude
                    
                    if newOnScreen and newDistance < currentDistance then
                        lockedTarget = newTarget
                        lockedTargetPart = newPart
                    end
                end
            end
        end
        
        if not isTargetValid(lockedTarget, lockedTargetPart) then
            if autoSwitchTarget then
                local newTarget = findClosestTarget()
                
                if newTarget then
                    -- Verify target is alive before switching
                    local newHumanoid = newTarget:FindFirstChildOfClass("Humanoid")
                    if isHealthValid(newHumanoid) then
                        lockedTarget = newTarget
                        local part, partName = selectTargetPart(newTarget)
                        lockedTargetPart = part
                    else
                        aiming = false
                        lockedTarget = nil
                        lockedTargetPart = nil
                        return
                    end
                else
                    aiming = false
                    lockedTarget = nil
                    lockedTargetPart = nil
                    return
                end
            else
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
                return
            end
        end
        
        if lockedTargetPart and lockedTargetPart.Parent and lockedTarget then
            -- Game-specific health check before camera movement
            local targetHumanoid = lockedTarget:FindFirstChildOfClass("Humanoid")
            
            -- Flick: > 1 HP, Others: >= 1 HP
            if not isHealthValid(targetHumanoid) then
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
                return
            end
            
            local targetPos = lockedTargetPart.Position
            local cameraPos = camera.CFrame.Position
            
            if smoothAim then
                local targetDirection = (targetPos - cameraPos).Unit
                local currentLook = camera.CFrame.LookVector
                
                local smoothedLook = currentLook:Lerp(targetDirection, aimSmoothness)
                
                camera.CFrame = CFrame.new(cameraPos, cameraPos + smoothedLook)
            else
                camera.CFrame = CFrame.new(cameraPos, targetPos)
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not triggerbotEnabled then return end
    
    local currentTime = tick()
    if currentTime - lastTriggerShot < triggerbotDelay then return end
    
    local target = getTargetUnderCrosshair()
    if target then
        mouse1click()
        lastTriggerShot = currentTime
    end
end)

RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end
end)

Players.PlayerAdded:Connect(function(targetPlayer)
    targetPlayer.CharacterAdded:Connect(function(character)
        wait(0.5)
        updateCharactersList()
        addChams(character)
        addESP(character)
    end)
end)

Players.PlayerRemoving:Connect(function(targetPlayer)
    if targetPlayer.Character then
        removeChams(targetPlayer.Character)
        removeESP(targetPlayer.Character)
        updateCharactersList()
    end
end)

for _, targetPlayer in pairs(Players:GetPlayers()) do
    if targetPlayer.Character then
        addChams(targetPlayer.Character)
        addESP(targetPlayer.Character)
    end
    
    targetPlayer.CharacterAdded:Connect(function(character)
        wait(0.5)
        updateCharactersList()
        addChams(character)
        addESP(character)
    end)
end

spawn(function()
    while true do
        wait(charactersUpdateInterval)
        updateCharactersList()
    end
end)

updateCharactersList()

local lastUpdate = 0
local updateInterval = 0.5

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    if currentTime - lastUpdate > updateInterval then
        lastUpdate = currentTime
        
        if chamsEnabled then
            updateAllChams()
        else
            removeAllChams()
        end
        
        if espEnabled then
            updateAllESP()
        else
            removeAllESP()
        end
    end
    
    if chamsEnabled then
        updateChamsColors()
    end
end)

player.CharacterAdded:Connect(function()
    wait(1)
    fovCircle = createFOVCircle()
    aiming = false
    lockedTarget = nil
    lockedTargetPart = nil
    updateCharactersList()
    
    if speedhackEnabled then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if defaultWalkSpeed == 16 then
                defaultWalkSpeed = humanoid.WalkSpeed
            end
            humanoid.WalkSpeed = defaultWalkSpeed * speedMultiplier
        end
    end
    
    if chamsEnabled then
        updateAllChams()
    end
    
    if espEnabled then
        updateAllESP()
    end
end)

spawn(function()
    while true do
        wait(0.1)
        if speedhackEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if defaultWalkSpeed == 16 and humanoid.WalkSpeed ~= 16 then
                    defaultWalkSpeed = humanoid.WalkSpeed
                end
                
                local expectedSpeed = defaultWalkSpeed * speedMultiplier
                if humanoid.WalkSpeed ~= expectedSpeed then
                    humanoid.WalkSpeed = expectedSpeed
                end
            end
        end
    end
end)
