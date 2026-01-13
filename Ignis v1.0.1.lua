-- ============ GAME DETECTION AND SETTINGS ============
local UNIVERSAL_KEY = "IGNIS" -- Мастер-ключ для всех игр

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
    }
}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get current game name
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

-- Search for match
local currentGame = nil
local detectedGameName = nil
for gameKey, gameData in pairs(supportedGames) do
    if string.find(gameName, gameKey) or string.find(string.lower(gameName), string.lower(gameKey)) then
        currentGame = gameData
        detectedGameName = gameKey
        print("✅ Game detected:", gameKey)
        break
    end
end

-- If game is not supported - kick
if not currentGame then
    player:Kick("❌ Game is not supported!\n\n📛 Game name: " .. gameName .. "\n\n🎮 Supported games:\n• Fate Trigger\n• SNIPER DUELS\n• Flick")
    return
end

-- Set key and link for current game
local validKey = currentGame.key
local keyLink = currentGame.link

-- ============ ОСНОВНЫЕ СЕРВИСЫ ============
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ============ ПРОВЕРКА НА МОБИЛЬНОЕ УСТРОЙСТВО ============
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
print("📱 Mobile device:", isMobile)

-- ============ НАСТРОЙКИ АИМА ============
local aimEnabled = false -- Включить/выключить аим
local aimKey = Enum.KeyCode.E -- Кнопка активации
local aimFOV = 200 -- Радиус поиска целей (в пикселях)

-- Шансы на части тела (в процентах, должны в сумме = 100)
local hitChances = {
    Head = 70,  -- 70% шанс на голову
    Torso = 30  -- 30% шанс на торс
}

local showFOV = false -- Показывать круг FOV
local wallCheck = true -- Проверка стен для аима
local autoSwitchTarget = true -- Автоматически менять цель после смерти

-- ============ НАСТРОЙКИ СПИДХАКА ============
local speedhackEnabled = false -- Включить/выключить спидхак
local speedMultiplier = 1 -- Множитель скорости (1 = нормальная скорость)
local defaultWalkSpeed = 16 -- Стандартная скорость ходьбы

-- ============ НАСТРОЙКИ ТРИГГЕРБОТА ============
local triggerbotEnabled = false -- Включить/выключить триггербот
local triggerbotDelay = 0.15 -- Задержка перед выстрелом (секунды)
local triggerbotMaxDistance = 1000 -- Максимальная дистанция для триггербота (стадов)

-- ============ НАСТРОЙКИ ЧАМСОВ ============
local chamsEnabled = false -- Включить/выключить чамсы
local maxChamsDistance = 1000 -- Максимальная дистанция для чамсов (в стадах)

-- Chams colors
local chamsColors = {
    visible = Color3.fromRGB(0, 255, 0),    -- Green for visible
    hidden = Color3.fromRGB(255, 0, 0)      -- Red for hidden behind walls
}

local chamsTransparency = 0.3 -- Прозрачность контура чамсов (0 - непрозрачно, 1 - прозрачно)
local chamsFillTransparency = 0.5 -- Прозрачность заливки

-- ============ НАСТРОЙКИ ESP (ХП, ИМЯ) ============
local espEnabled = false -- Включить/выключить ESP
local showBoxes = true -- Показывать боксы
local showHealthBar = true -- Показывать HP бар
local showNames = true -- Показывать имена
local maxESPDistance = 1000 -- Максимальная дистанция для ESP (в стадах)

-- RGB эффекты
local rgbBoxes = false -- RGB цвет для боксов
local rgbFOV = false -- RGB цвет для FOV круга

-- Цвета (если RGB выключен)
local boxColor = Color3.fromRGB(255, 255, 255) -- Цвет боксов
local fovColor = Color3.fromRGB(255, 255, 255) -- Цвет FOV круга

-- Стили
local boxThickness = 2 -- Толщина линий бокса
local healthBarHeight = 4 -- Высота HP бара
local nameColor = Color3.fromRGB(255, 255, 255) -- Цвет имени
local nameSize = 14 -- Размер шрифта имени

-- ============ ФУНКЦИЯ RGB ЦВЕТА ============
local function getRainbowColor()
    local hue = (tick() * 100) % 360 -- Фиксированная скорость
    return Color3.fromHSV(hue / 360, 1, 1)
end

-- ============ ПЕРЕМЕННЫЕ АИМА ============
local aiming = false
local lockedTarget = nil
local lockedTargetPart = nil
local fovCircle = nil

-- ============ ПЕРЕМЕННЫЕ ТРИГГЕРБОТА ============
local lastTriggerShot = 0

-- ============ ПЕРЕМЕННЫЕ ЧАМСОВ ============
local chamsCache = {}

-- ============ ПЕРЕМЕННЫЕ ESP ============
local espCache = {}

-- ============ GENERAL VARIABLES ============
local charactersList = {} -- Cache of all characters
local lastCharactersUpdate = 0
local charactersUpdateInterval = 3 -- Update character list every 3 seconds

-- ============ KEY SYSTEM ============
-- validKey and keyLink are already defined above based on the game
local keyVerified = false

-- ============ СОЗДАНИЕ GUI МЕНЮ ============
local function createMenu()
    local menuOpen = false
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HvHMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = screenGui
    
    -- Скругление углов
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background header
    title.BorderSizePixel = 0
    title.Text = "Ignis"
    title.TextColor3 = Color3.fromRGB(255, 140, 0) -- Orange текст
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Кнопка закрытия
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 100, 0) -- Orange
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = title
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Контейнер для вкладок
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.Position = UDim2.new(0, 0, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    -- Контейнер для контента
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -95)
    contentContainer.Position = UDim2.new(0, 10, 0, 85)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Function to create tabи
    local function createTab(name, position)
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Size = UDim2.new(0, 120, 0, 30)
        tab.Position = UDim2.new(0, position, 0, 0)
        tab.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Dark background
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
    
    -- Create tabи
    local combatTab = createTab("Combat", 10)
    local visualsTab = createTab("Visuals", 140)
    
    -- Function to create скролл фрейма
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
    
    -- Function to create чекбокса
    local function createCheckbox(parent, text, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
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
    
    -- Function to create слайдера
    local function createSlider(parent, text, min, max, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
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
        sliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark background трека
        sliderBG.BorderSizePixel = 0
        sliderBG.Parent = frame
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(1, 0)
        sliderCorner.Parent = sliderBG
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBG
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = sliderFill
        
        local dragging = false
        
        sliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        sliderBG.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = sliderBG.AbsolutePosition.X
                local sliderSize = sliderBG.AbsoluteSize.X
                
                local value = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)
                local actualValue = math.floor(min + (max - min) * value)
                
                sliderFill.Size = UDim2.new(value, 0, 1, 0)
                label.Text = text .. ": " .. tostring(actualValue)
                callback(actualValue)
            end
        end)
        
        return frame
    end


    -- Function to create кнопки выбора клавиши (С ПОДДЕРЖКОЙ МЫШИ)
    local function createKeybind(parent, text, defaultKey, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
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
        
        -- Функция для получения читаемого имени кнопки
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
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Тёмно-серый
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
                button.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange when waiting
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    -- Клавиатура
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        -- Игнорируем ESC для отмены
                        if input.KeyCode == Enum.KeyCode.Escape then
                            button.Text = type(currentKey) == "table" and getButtonName(currentKey.inputType, currentKey.keyCode) or currentKey.Name
                            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            listening = false
                            connection:Disconnect()
                            return
                        end
                        
                        -- Устанавливаем новую клавишу
                        currentKey = input.KeyCode
                        button.Text = input.KeyCode.Name
                        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        listening = false
                        connection:Disconnect()
                        callback(input.KeyCode, nil)
                    
                    -- Кнопки мыши
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
    
    -- Function to create кнопки
    local function createButton(parent, text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange
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
    
    -- ============ COMBAT ВКЛАДКА ============
    createCheckbox(combatContent, "Aimbot", aimEnabled, function(value)
        aimEnabled = value
        
        -- Обновляем видимость FOV круга
        if fovCircle then
            fovCircle.Visible = value and showFOV
        end
    end)

    -- Кнопка для изменения клавиши аима
    createKeybind(combatContent, "Aim Key", aimKey, function(newKey)
        aimKey = newKey
        print("🔑 Aim key changed to:", newKey.Name)
    end)

    createSlider(combatContent, "FOV Size", 50, 500, aimFOV, function(value)
        aimFOV = value
        if fovCircle then
            fovCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
        end
    end)

    createCheckbox(combatContent, "Show FOV Circle", showFOV, function(value)
        showFOV = value
        
        -- Create круг если его ещё нет
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
        
        -- Применяем/сбрасываем скорость
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
        
        -- Обновляем скорость если спидхак включен
        if speedhackEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = defaultWalkSpeed * speedMultiplier
            end
        end
    end)
    
    -- ============ VISUALS ВКЛАДКА ============
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
    
    -- Переключение вкладок
    local function switchTab(tab, content)
        combatTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        visualsTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        combatTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        visualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        combatContent.Visible = false
        visualsContent.Visible = false
        
        tab.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange for active tabи
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        content.Visible = true
    end
    
    combatTab.MouseButton1Click:Connect(function()
        switchTab(combatTab, combatContent)
    end)
    
    visualsTab.MouseButton1Click:Connect(function()
        switchTab(visualsTab, visualsContent)
    end)
    
    -- Изначально показываем Combat
    switchTab(combatTab, combatContent)
    
    -- Закрытие меню
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        menuOpen = false
    end)
    
    -- Перетаскивание
    local dragging = false
    local dragInput, mousePos, framePos
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
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
    
    -- Помещаем в PlayerGui
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Кнопка открытия меню (для мобильных и удобства)
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
    
    -- Уведомление для мобильных пользователей
    if isMobile then
        local mobileNotice = Instance.new("TextLabel")
        mobileNotice.Name = "MobileNotice"
        mobileNotice.Size = UDim2.new(0, 300, 0, 60)
        mobileNotice.Position = UDim2.new(0.5, -150, 0, 70)
        mobileNotice.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mobileNotice.BorderSizePixel = 0
        mobileNotice.Text = "⚠️ Aimbot is not available on mobile devices"
        mobileNotice.TextColor3 = Color3.fromRGB(255, 200, 0)
        mobileNotice.TextSize = 14
        mobileNotice.Font = Enum.Font.GothamBold
        mobileNotice.TextWrapped = true
        mobileNotice.Parent = screenGui
        
        local noticeCorner = Instance.new("UICorner")
        noticeCorner.CornerRadius = UDim.new(0, 8)
        noticeCorner.Parent = mobileNotice
        
        -- Автоматически скрыть через 5 секунд
        spawn(function()
            wait(5)
            mobileNotice:TweenPosition(
                UDim2.new(0.5, -150, 0, -70),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Quad,
                0.5,
                true,
                function()
                    mobileNotice:Destroy()
                end
            )
        end)
        
        print("📱 Mobile device detected - Aimbot disabled")
    end
    
    -- Открытие/закрытие на RightShift (для ПК)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            menuOpen = not menuOpen
            mainFrame.Visible = menuOpen
        end
    end)
    
    return screenGui
end

local function createKeySystem()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 2000
    
    -- Затемнённый фон
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background header
    title.BorderSizePixel = 0
    title.Text = "Ignis - Key System" -- New name
    title.TextColor3 = Color3.fromRGB(255, 140, 0) -- Orange текст
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Информация о распознанной игре
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
    
    -- Описание
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
    
    -- Поле ввода ключа
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -40, 0, 40)
    keyInput.Position = UDim2.new(0, 20, 0, 100)
    keyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
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
    
    -- Кнопка Redeem Key
    local redeemButton = Instance.new("TextButton")
    redeemButton.Name = "RedeemButton"
    redeemButton.Size = UDim2.new(1, -40, 0, 40)
    redeemButton.Position = UDim2.new(0, 20, 0, 155)
    redeemButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange
    redeemButton.BorderSizePixel = 0
    redeemButton.Text = "Redeem Key"
    redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    redeemButton.TextSize = 16
    redeemButton.Font = Enum.Font.GothamBold
    redeemButton.Parent = mainFrame
    
    local redeemCorner = Instance.new("UICorner")
    redeemCorner.CornerRadius = UDim.new(0, 6)
    redeemCorner.Parent = redeemButton
    
    -- Кнопка Copy Link
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(1, -40, 0, 35)
    copyButton.Position = UDim2.new(0, 20, 0, 205)
    copyButton.BackgroundColor3 = Color3.fromRGB(180, 100, 0) -- Тёмно-оранжевый
    copyButton.BorderSizePixel = 0
    copyButton.Text = "Copy Link"
    copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyButton.TextSize = 14
    copyButton.Font = Enum.Font.GothamBold
    copyButton.Parent = mainFrame
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyButton
    
    -- Сообщение об ошибке
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
    
    -- Функция проверки ключа
    local function checkKey()
        local enteredKey = keyInput.Text
        
        -- Проверяем как игровой ключ, так и универсальный
        if enteredKey == validKey or enteredKey == UNIVERSAL_KEY then
            keyVerified = true
            
            -- Успешная анимация
            redeemButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50) -- Green success
            redeemButton.Text = "✓ Success!"
            
            wait(0.5)
            
            -- Закрываем окно ключа
            screenGui:Destroy()
            
            -- ← ИЗМЕНЕНО: создаём меню только ПОСЛЕ успешной проверки ключа
            wait(0.2)
            local menuGui = createMenu()
            
            -- Create уведомление в стиле Roblox (правый нижний угол)
            local notificationGui = Instance.new("ScreenGui")
            notificationGui.Name = "NotificationGui"
            notificationGui.ResetOnSpawn = false
            notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            notificationGui.DisplayOrder = 3000
            
            local notification = Instance.new("Frame")
            notification.Name = "Notification"
            notification.Size = UDim2.new(0, 300, 0, 80)
            notification.Position = UDim2.new(1, 320, 1, -100) -- Начинаем справа (за экраном)
            notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Dark background
            notification.BorderSizePixel = 0
            notification.Parent = notificationGui
            
            local notifCorner = Instance.new("UICorner")
            notifCorner.CornerRadius = UDim.new(0, 8)
            notifCorner.Parent = notification
            
            local notifStroke = Instance.new("UIStroke")
            notifStroke.Color = Color3.fromRGB(255, 140, 0) -- Оранжевая обводка
            notifStroke.Thickness = 2
            notifStroke.Parent = notification
            
            -- Эмодзи огня вместо иконки
            local emojiLabel = Instance.new("TextLabel")
            emojiLabel.Name = "Emoji"
            emojiLabel.Size = UDim2.new(0, 50, 0, 50)
            emojiLabel.Position = UDim2.new(0, 10, 0.5, -25)
            emojiLabel.BackgroundTransparency = 1
            emojiLabel.Text = "🔥"
            emojiLabel.TextSize = 40
            emojiLabel.Font = Enum.Font.GothamBold
            emojiLabel.Parent = notification
            
            -- Заголовок
            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(1, -70, 0, 25)
            title.Position = UDim2.new(0, 65, 0, 10)
            title.BackgroundTransparency = 1
            title.Text = "🔥 Ignis Loaded!" -- Обновлённое название
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextSize = 16
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = notification
            
            -- Описание
            local description = Instance.new("TextLabel")
            description.Name = "Description"
            description.Size = UDim2.new(1, -70, 0, 35)
            description.Position = UDim2.new(0, 65, 0, 35)
            description.BackgroundTransparency = 1
            description.Text = "Press RightShift or click 🔥 button to open menu"
            description.TextColor3 = Color3.fromRGB(200, 200, 200)
            description.TextSize = 13
            description.Font = Enum.Font.Gotham
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.TextWrapped = true
            description.Parent = notification
            
            notificationGui.Parent = player:WaitForChild("PlayerGui")
            
            -- Анимация появления
            notification:TweenPosition(
                UDim2.new(1, -310, 1, -100),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.5,
                true
            )
            
            -- Автоматически скрываем через 5 секунд
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
            
            -- Print information
            print("=" .. string.rep("=", 50))
            print("🔥 Ignis loaded successfully!")
            print("💡 Press RightShift or click 🔥 button to open the menu!")
            print("=" .. string.rep("=", 50))
            print("")
            print("🐛 DEBUG COMMANDS:")
            print("   Type in console:")
            print("   _G.debugESP() - Check ESP status")
            print("")
            
            -- Debug функция
            _G.debugESP = function()
                print("═══ ESP DEBUG INFO ═══")
                print("ESP Enabled:", espEnabled)
                print("Show Boxes:", showBoxes)
                print("Show Names:", showNames)
                print("Show Health Bar:", showHealthBar)
                print("")
                print("Characters in list:", #charactersList)
                print("ESP Cache entries:")
                local count = 0
                for char, data in pairs(espCache) do
                    count = count + 1
                    print("  -", char.Name, "| Billboard:", data.billboard ~= nil)
                end
                print("Total cached:", count)
            end
            print("⚙️  AIMBOT Settings:")
            print("   • Status:", aimEnabled and "✅ Enabled" or "❌ Disabled")
            print("   • Activation key:", aimKey.Name)
            print("   • FOV radius:", aimFOV, "pixels")
            print("   • Head chance:", hitChances.Head .. "%")
            print("   • Torso chance:", hitChances.Torso .. "%")
            print("   • Wall check:", wallCheck and "✅ Enabled" or "❌ Disabled")
            print("")
            print("⚙️  TRIGGERBOT Settings:")
            print("   • Status:", triggerbotEnabled and "✅ Enabled" or "❌ Disabled")
            print("   • Delay:", triggerbotDelay, "sec")
            print("   • Max distance:", triggerbotMaxDistance, "studs")
            print("")
            print("⚙️  CHAMS Settings:")
            print("   • Status:", chamsEnabled and "✅ Enabled" or "❌ Disabled")
            print("   • 🟢 Green = Visible targets")
            print("   • 🔴 Red = Behind walls")
            print("")
            print("⚙️  ESP Settings:")
            print("   • Status:", espEnabled and "✅ Enabled" or "❌ Disabled")
            print("   • Boxes:", showBoxes and "✅ Enabled" or "❌ Disabled")
            print("   • HP bar:", showHealthBar and "✅ Enabled" or "❌ Disabled")
            print("   • Names:", showNames and "✅ Enabled" or "❌ Disabled")
            print("=" .. string.rep("=", 50))
            print("🚀 All features active! Press RightShift or click 🔥 to toggle menu")
            print("=" .. string.rep("=", 50))
            
        else
            -- Ошибка
            errorLabel.Text = "Invalid key!"
            errorLabel.Visible = true
            redeemButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Красная ошибка
            
            wait(1)
            
            redeemButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Возврат к оранжевому
            errorLabel.Visible = false
        end
    end

    -- Обработчик кнопки Redeem
    redeemButton.MouseButton1Click:Connect(function()
        checkKey()
    end)

    -- Enter для проверки ключа
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            checkKey()
        end
    end)

    -- Обработчик кнопки Copy Link
    copyButton.MouseButton1Click:Connect(function()
        setclipboard(keyLink)
        
        copyButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50) -- Green success
        copyButton.Text = "✓ Copied!"
        
        wait(1)
        
        copyButton.BackgroundColor3 = Color3.fromRGB(180, 100, 0) -- Возврат к тёмно-оранжевому
        copyButton.Text = "Copy Link"
    end)

    -- Помещаем в PlayerGui
    screenGui.Parent = player:WaitForChild("PlayerGui")

    return screenGui
end

-- Create систему ключа
spawn(function()
    wait(1)
    createKeySystem()
end)

-- Параметры для raycast
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- [... остальной код аима, триггербота, чамсов и ESP остаётся без изменений ...]
-- Для краткости я не копирую весь остальной код, так как изменения только в части с меню

-- ============ ПОЛУЧЕНИЕ ПОЗИЦИИ МЫШИ ============
local function getMouseLocation()
    local mouseLocation = UserInputService:GetMouseLocation()
    return Vector2.new(mouseLocation.X, mouseLocation.Y)
end

-- ============ СОЗДАНИЕ КРУГА FOV (GUI) ============
local function createFOVCircle()
    -- Удаляем старый круг если есть
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
    screenGui.DisplayOrder = 999 -- Поверх всего
    
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
    
    -- Помещаем в PlayerGui
    screenGui.Parent = playerGui
    
    return frame
end

-- Create FOV круг сразу (видимость контролируется в цикле обновления)
spawn(function()
    wait(0.1) -- Небольшая задержка для загрузки
    fovCircle = createFOVCircle()
end)

-- ============ СОЗДАНИЕ SCREENGUI ДЛЯ ТРЕЙСЕРОВ ============
-- ============ ПРОВЕРКА ВИДИМОСТИ (СТЕНЫ) ДЛЯ АИМА ============
local function isVisibleAim(targetPart)
    if not wallCheck then return true end
    if not targetPart or not targetPart.Parent then return false end
    
    local character = player.Character
    if not character then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    -- Обновляем фильтр raycast
    raycastParams.FilterDescendantsInstances = {character}
    
    -- Выполняем raycast
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if raycastResult then
        -- Проверяем что луч попал в нужного персонажа
        local hit = raycastResult.Instance
        local hitCharacter = hit:FindFirstAncestorOfClass("Model")
        
        if hitCharacter and hitCharacter == targetPart.Parent then
            return true
        end
        
        return false
    end
    
    return true -- Если ничего не попало, считаем что видно
end

-- ============ ПРОВЕРКА ВИДИМОСТИ ДЛЯ ЧАМСОВ ============
local function isVisibleChams(targetCharacter)
    if not targetCharacter then return false end
    
    local character = player.Character
    if not character then return false end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetRoot.Position - origin).Unit
    local distance = (targetRoot.Position - origin).Magnitude
    
    -- Обновляем фильтр raycast
    raycastParams.FilterDescendantsInstances = {character}
    
    -- Выполняем raycast
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if raycastResult then
        -- Проверяем что луч попал в нужного персонажа
        local hit = raycastResult.Instance
        local hitCharacter = hit:FindFirstAncestorOfClass("Model")
        
        if hitCharacter and hitCharacter == targetCharacter then
            return true
        end
        
        return false
    end
    
    return true -- Если ничего не попало, считаем что видно
end

-- ============ ФУНКЦИЯ ВЫБОРА ЧАСТИ ТЕЛА ============
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
    
    -- Фоллбэк
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"), "Head"
end

-- ============ ОБНОВЛЕНИЕ СПИСКА ПЕРСОНАЖЕЙ (КЭШИРОВАНИЕ) ============
local function updateCharactersList()
    charactersList = {}
    
    -- Добавляем персонажей игроков
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(charactersList, targetPlayer.Character)
            end
        end
    end
    
    -- Ищем ботов в workspace (только один уровень вглубь для оптимизации)
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
        
        -- Проверяем одну папку вглубь (например, если боты в папке "NPCs")
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

-- ============ ПОИСК БЛИЖАЙШЕЙ ЦЕЛИ ДЛЯ АИМА ============
local function findClosestTarget()
    local closestCharacter = nil
    local shortestDistance = aimFOV
    local mousePos = getMouseLocation()
    
    -- Функция проверки персонажа
    local function checkCharacter(character)
        if not character or not character.Parent then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
        if not rootPart then return end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        
        if onScreen then
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            local distance = (mousePos - targetPos).Magnitude
            
            if distance < shortestDistance then
                -- Проверка видимости
                if isVisibleAim(rootPart) then
                    closestCharacter = character
                    shortestDistance = distance
                end
            end
        end
    end
    
    -- Проверяем всех персонажей из кэша
    for _, character in pairs(charactersList) do
        checkCharacter(character)
    end
    
    return closestCharacter
end

-- ============ ПРОВЕРКА ВАЛИДНОСТИ ЦЕЛИ ============
local function isTargetValid(targetCharacter, targetPart)
    if not targetCharacter or not targetCharacter.Parent then return false end
    if not targetPart or not targetPart.Parent then return false end
    
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Проверка видимости
    if not isVisibleAim(targetPart) then return false end
    
    return true
end

-- ============ ТРИГГЕРБОТ - ПРОВЕРКА ЦЕЛИ ПОД ПРИЦЕЛОМ ============
local function getTargetUnderCrosshair()
    local character = player.Character
    if not character then return nil end
    
    -- Raycast от камеры
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
                -- Проверяем что это игрок или бот
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

-- ============ ФУНКЦИЯ СОЗДАНИЯ ЧАМСА (УЛУЧШЕННАЯ) ============
local function createCham(character, color)
    -- Удаляем старый highlight если есть
    local oldHighlight = character:FindFirstChild("ESP_Highlight")
    if oldHighlight then
        oldHighlight:Destroy()
    end
    
    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = chamsFillTransparency
    highlight.OutlineTransparency = chamsTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Видно через стены
    highlight.Parent = character
    
    return highlight
end

-- ============ СОЗДАНИЕ ESP ЭЛЕМЕНТОВ ============
local function createESP(character)
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_Elements"
    
    -- Create BillboardGui для ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    billboard.Size = UDim2.new(6, 0, 7, 0) -- Увеличил размер
    billboard.StudsOffset = Vector3.new(0, 2, 0) -- Поднял выше
    billboard.Parent = espFolder
    
    -- Бокс (4 линии через Frame)
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
    
    -- Верхняя линия
    boxLines[1].Size = UDim2.new(1, 0, 0, boxThickness)
    boxLines[1].Position = UDim2.new(0, 0, 0, 0)
    
    -- Нижняя линия
    boxLines[2].Size = UDim2.new(1, 0, 0, boxThickness)
    boxLines[2].Position = UDim2.new(0, 0, 1, -boxThickness)
    
    -- Левая линия
    boxLines[3].Size = UDim2.new(0, boxThickness, 1, 0)
    boxLines[3].Position = UDim2.new(0, 0, 0, 0)
    
    -- Правая линия
    boxLines[4].Size = UDim2.new(0, boxThickness, 1, 0)
    boxLines[4].Position = UDim2.new(1, -boxThickness, 0, 0)
    
    -- Имя игрока (создаём всегда, видимость контролируем позже)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, nameSize)
    nameLabel.Position = UDim2.new(0, 0, 0, 5) -- Внутри billboard, сверху
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = nameColor
    nameLabel.TextSize = nameSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Visible = showNames
    nameLabel.Parent = billboard
    
    -- HP бар (создаём всегда, видимость контролируем позже)
    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarBG"
    healthBarBG.Size = UDim2.new(0, 5, 0.8, 0) -- Увеличил толщину до 5px
    healthBarBG.Position = UDim2.new(0, 5, 0.1, 0) -- Внутри billboard, слева
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

-- ============ СОЗДАНИЕ БОКСА ============
-- ============ ДОБАВЛЕНИЕ ЧАМСА К ПЕРСОНАЖУ (УЛУЧШЕННАЯ) ============
local function addChams(character)
    if not chamsEnabled then return end
    if not character then return end
    if character == player.Character then return end -- Не добавляем себе
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Create или обновляем чамс
    local highlight = createCham(character, chamsColors.hidden)
    
    -- Сохраняем в кэш
    chamsCache[character] = {
        highlight = highlight,
        character = character,
        lastVisibilityCheck = 0
    }
end

-- ============ ДОБАВЛЕНИЕ ESP К ПЕРСОНАЖУ ============
local function addESP(character)
    if not espEnabled then 
        print("❌ ESP disabled")
        return 
    end
    if not character then 
        print("❌ No character")
        return 
    end
    if character == player.Character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then 
        print("❌ No humanoid:", character.Name)
        return 
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        print("❌ No HRP:", character.Name)
        return 
    end
    
    print("✅ Adding ESP to:", character.Name)
    
    -- Удаляем старый ESP если есть
    local oldESP = character:FindFirstChild("ESP_Elements")
    if oldESP then
        oldESP:Destroy()
    end
    
    -- Create ESP элементы
    local espFolder, billboard, boxLines = createESP(character)
    billboard.Adornee = rootPart
    espFolder.Parent = character
    
    print("✅ Billboard created for:", character.Name)
    print("   - showNames:", showNames)
    print("   - showHealthBar:", showHealthBar)
    
    -- Получаем имя
    local characterName = character.Name
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if targetPlayer then
        characterName = targetPlayer.Name
    end
    
    -- Сохраняем в кэш
    espCache[character] = {
        character = character,
        billboard = billboard,
        boxLines = boxLines,
        name = characterName
    }
end

-- ============ УДАЛЕНИЕ ЧАМСА ============
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
    
    -- Дополнительно удаляем highlight из персонажа если есть
    if character then
        local oldHighlight = character:FindFirstChild("ESP_Highlight")
        if oldHighlight then
            pcall(function()
                oldHighlight:Destroy()
            end)
        end
    end
end

-- ============ УДАЛЕНИЕ ESP ============
local function removeESP(character)
    if espCache[character] then
        local data = espCache[character]
        
        -- Удаляем billboard
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
    
    -- Удаляем ESP элементы из персонажа
    if character then
        local oldESP = character:FindFirstChild("ESP_Elements")
        if oldESP then
            pcall(function()
                oldESP:Destroy()
            end)
        end
    end
end

-- ============ ПРОВЕРКА И ВОССТАНОВЛЕНИЕ ЧАМСА ============
local function validateAndRestoreCham(character, data)
    -- Проверяем что highlight существует и корректен
    if not data.highlight or not data.highlight.Parent or data.highlight.Adornee ~= character then
        -- Пересоздаём highlight
        local newHighlight = createCham(character, chamsColors.hidden)
        data.highlight = newHighlight
        return true
    end
    return false
end

-- ============ ОБНОВЛЕНИЕ ЦВЕТА ЧАМСОВ (БЕЗ CONTINUE) ============
local visibilityCheckInterval = 0.3
local currentTime = 0

local function updateChamsColors()
    if not chamsEnabled then return end
    
    currentTime = tick()
    local toRemove = {}
    
    for character, data in pairs(chamsCache) do
        local shouldRemove = false
        local shouldSkip = false
        
        -- Проверяем валидность персонажа
        if not character or not character.Parent then
            shouldRemove = true
        elseif not shouldRemove then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                shouldRemove = true
            end
        end
        
        -- Проверка дистанции для чамсов
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

-- ============ ОБНОВЛЕНИЕ ESP (БЕЗ CONTINUE) ============
local espUpdateCount = 0
local function updateESP()
    if not espEnabled then return end
    
    espUpdateCount = espUpdateCount + 1
    if espUpdateCount % 120 == 0 then -- Каждые 2 секунды (60 FPS)
        local cacheCount = 0
        for _ in pairs(espCache) do cacheCount = cacheCount + 1 end
        print("🔄 ESP Update | Characters:", #charactersList, "| Cache:", cacheCount)
    end
    
    local toRemove = {}
    
    for character, data in pairs(espCache) do
        local shouldRemove = false
        local shouldSkip = false
        
        if not character or not character.Parent then
            shouldRemove = true
            print("⚠️ Removing ESP:", data.name, "- No parent")
        elseif not shouldRemove then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                shouldRemove = true
                print("⚠️ Removing ESP:", data.name, "- Dead or no humanoid")
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
            
            -- Боксы
            if showBoxes and data.boxLines then
                -- RGB цвет для боксов
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

-- ============ ОБНОВЛЕНИЕ ВСЕХ ЧАМСОВ (УЛУЧШЕННАЯ) ============
local function updateAllChams()
    if not chamsEnabled then return end
    
    -- Проверяем существующие чамсы
    for character, data in pairs(chamsCache) do
        if not character or not character.Parent then
            removeChams(character)
        else
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                removeChams(character)
            else
                -- Проверяем и восстанавливаем highlight
                validateAndRestoreCham(character, data)
            end
        end
    end
    
    -- Добавляем чамсы новым персонажам
    for _, character in pairs(charactersList) do
        if not chamsCache[character] then
            addChams(character)
        end
    end
end

-- ============ ОБНОВЛЕНИЕ ВСЕХ ESP ============
local function updateAllESP()
    if not espEnabled then return end
    
    -- Проверяем существующие ESP
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
    
    -- Добавляем ESP новым персонажам
    for _, character in pairs(charactersList) do
        if not espCache[character] then
            addESP(character)
        end
    end
end

-- ============ УДАЛЕНИЕ ВСЕХ ЧАМСОВ ============
function removeAllChams()
    for character, _ in pairs(chamsCache) do
        removeChams(character)
    end
    chamsCache = {}
end

-- ============ УДАЛЕНИЕ ВСЕХ ESP ============
function removeAllESP()
    for character, _ in pairs(espCache) do
        removeESP(character)
    end
    espCache = {}
end

-- ============ ПЕРИОДИЧЕСКАЯ ОЧИСТКА (НЕ НУЖНА БЕЗ БОКСОВ) ============
-- Оставляем пустую функцию для совместимости

-- ============ АКТИВАЦИЯ АИМА ============
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not aimEnabled then return end
    if isMobile then return end -- Отключено на мобильных
    
    if input.KeyCode == aimKey then
        if not aiming then
            local targetCharacter = findClosestTarget()
            
            if targetCharacter then
                aiming = true
                lockedTarget = targetCharacter
                local part, partName = selectTargetPart(targetCharacter)
                lockedTargetPart = part
                print("🔒 Target LOCKED:", targetCharacter.Name, "| Part:", partName)
            else
                print("❌ No target found in FOV!")
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if isMobile then return end -- Отключено на мобильных
    
    if input.KeyCode == aimKey then
        if aiming then
            aiming = false
            print("🔓 Target UNLOCKED")
            lockedTarget = nil
            lockedTargetPart = nil
        end
    end
end)

-- ============ ОБНОВЛЕНИЕ КРУГА FOV ============
spawn(function()
    while true do
        wait()
        
        -- Обновляем обычный FOV круг
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
                        stroke.Color = Color3.fromRGB(0, 255, 0) -- Зелёный при локе
                    elseif rgbFOV then
                        stroke.Color = getRainbowColor() -- RGB
                    else
                        stroke.Color = fovColor -- Обычный цвет
                    end
                end
            end
        end
    end
end)

-- ============ ОСНОВНОЙ ЦИКЛ АИМА ============
RunService.RenderStepped:Connect(function()
    if not aimEnabled then return end
    if not aiming then return end
    if isMobile then return end -- Отключено на мобильных
    
    -- Проверяем валидность текущей цели
    if not isTargetValid(lockedTarget, lockedTargetPart) then
        if autoSwitchTarget then
            -- Пытаемся найти новую цель автоматически
            local newTarget = findClosestTarget()
            
            if newTarget then
                lockedTarget = newTarget
                local part, partName = selectTargetPart(newTarget)
                lockedTargetPart = part
                print("🔄 Auto-switch: New target -", newTarget.Name, "| Part:", partName)
            else
                -- Целей нет - отключаем аим
                aiming = false
                lockedTarget = nil
                lockedTargetPart = nil
                print("❌ No targets found - aim disabled")
                return
            end
        else
            -- Автосмена выключена - просто отключаем аим
            aiming = false
            lockedTarget = nil
            lockedTargetPart = nil
            return
        end
    end
    
    -- Мгновенно наводим камеру на цель
    if lockedTargetPart and lockedTargetPart.Parent then
        local targetPos = lockedTargetPart.Position
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
    end
end)

-- ============ ОСНОВНОЙ ЦИКЛ ТРИГГЕРБОТА ============
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

-- ============ ОСНОВНОЙ ЦИКЛ ESP ============
RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end
end)

-- ============ ОБРАБОТЧИКИ СОБЫТИЙ ============
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

-- ============ ПЕРИОДИЧЕСКОЕ ОБНОВЛЕНИЕ ============
spawn(function()
    while true do
        wait(charactersUpdateInterval)
        updateCharactersList()
    end
end)

updateCharactersList()

-- ============ ОСНОВНОЙ ЦИКЛ ЧАМСОВ И ESP ============
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

-- ============ АВТОУДАЛЕНИЕ ПРИ СМЕРТИ ============
player.CharacterAdded:Connect(function()
    wait(1)
    fovCircle = createFOVCircle()
    aiming = false
    lockedTarget = nil
    lockedTargetPart = nil
    updateCharactersList()
    
    -- Применяем спидхак если был включен
    if speedhackEnabled then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Сохраняем оригинальную скорость при первом запуске
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

-- ============ ПОСТОЯННОЕ ПРИМЕНЕНИЕ СПИДХАКА ============
spawn(function()
    while true do
        wait(0.1)
        if speedhackEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Сохраняем оригинальную скорость при первом запуске
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
