local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local settings = {
    enabled = false,
    fov = 120,
    smoothness = 0.15,
    targetPart = "Head",
    teamCheck = true,
    visibleCheck = true,
    targetNPCs = true,
    showFOV = true
}

local currentTarget = nil
local fovCircle = nil
local connection = nil

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MobileAimbotGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game.CoreGui
    end
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 380, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 16)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(80, 80, 100)
    Stroke.Thickness = 2
    Stroke.Transparency = 0.4
    Stroke.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundTransparency = 1
    Title.Text = "🎯 Mobile Aimbot"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Parent = MainFrame
    
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, -20, 1, -60)
    Content.Position = UDim2.new(0, 10, 0, 55)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 6
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.Parent = MainFrame
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 12)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.Parent = Content
    
    local function createToggle(text, defaultState, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 60)
        Container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Container.BorderSizePixel = 0
        Container.Parent = Content
        
        local ContCorner = Instance.new("UICorner")
        ContCorner.CornerRadius = UDim.new(0, 12)
        ContCorner.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.65, 0, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 16
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local Switch = Instance.new("Frame")
        Switch.Size = UDim2.new(0, 65, 0, 32)
        Switch.Position = UDim2.new(1, -75, 0.5, -16)
        Switch.BackgroundColor3 = defaultState and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(60, 60, 70)
        Switch.BorderSizePixel = 0
        Switch.Parent = Container
        
        local SwitchCorner = Instance.new("UICorner")
        SwitchCorner.CornerRadius = UDim.new(1, 0)
        SwitchCorner.Parent = Switch
        
        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 26, 0, 26)
        Knob.Position = defaultState and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = Switch
        
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob
        
        local state = defaultState
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 1, 0)
        Button.BackgroundTransparency = 1
        Button.Text = ""
        Button.Parent = Container
        
        Button.MouseButton1Click:Connect(function()
            state = not state
            
            local targetColor = state and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(60, 60, 70)
            local targetPos = state and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
            
            TweenService:Create(Switch, tweenInfo, {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(Knob, tweenInfo, {Position = targetPos}):Play()
            
            if callback then callback(state) end
        end)
        
        return Container
    end
    
    local function createSlider(text, min, max, default, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 70)
        Container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Container.BorderSizePixel = 0
        Container.Parent = Content
        
        local ContCorner = Instance.new("UICorner")
        ContCorner.CornerRadius = UDim.new(0, 12)
        ContCorner.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 0, 25)
        Label.Position = UDim2.new(0, 15, 0, 8)
        Label.BackgroundTransparency = 1
        Label.Text = text .. ": " .. default
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 15
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local SliderBack = Instance.new("Frame")
        SliderBack.Size = UDim2.new(1, -30, 0, 8)
        SliderBack.Position = UDim2.new(0, 15, 1, -18)
        SliderBack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        SliderBack.BorderSizePixel = 0
        SliderBack.Parent = Container
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(1, 0)
        SliderCorner.Parent = SliderBack
        
        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        SliderFill.BorderSizePixel = 0
        SliderFill.Parent = SliderBack
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = SliderFill
        
        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 20, 0, 20)
        Knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = SliderBack
        
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob
        
        local dragging = false
        local value = default
        
        Knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pos)
                
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                Knob.Position = UDim2.new(pos, -10, 0.5, -10)
                Label.Text = text .. ": " .. value
                
                if callback then callback(value) end
            end
        end)
        
        return Container
    end
    
    local function createDropdown(text, options, default, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 60)
        Container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Container.BorderSizePixel = 0
        Container.Parent = Content
        
        local ContCorner = Instance.new("UICorner")
        ContCorner.CornerRadius = UDim.new(0, 12)
        ContCorner.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.4, 0, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 15
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.5, -20, 0, 40)
        Button.Position = UDim2.new(0.5, 0, 0.5, -20)
        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        Button.BorderSizePixel = 0
        Button.Text = default
        Button.TextColor3 = Color3.fromRGB(230, 230, 230)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.AutoButtonColor = false
        Button.Parent = Container
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 10)
        ButtonCorner.Parent = Button
        
        local Arrow = Instance.new("TextLabel")
        Arrow.Size = UDim2.new(0, 25, 1, 0)
        Arrow.Position = UDim2.new(1, -30, 0, 0)
        Arrow.BackgroundTransparency = 1
        Arrow.Text = "▼"
        Arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
        Arrow.Font = Enum.Font.GothamBold
        Arrow.TextSize = 12
        Arrow.Parent = Button
        
        local DropFrame = Instance.new("Frame")
        DropFrame.Size = UDim2.new(0.5, -20, 0, #options * 45)
        DropFrame.Position = UDim2.new(0.5, 0, 1, 5)
        DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        DropFrame.BorderSizePixel = 0
        DropFrame.Visible = false
        DropFrame.ZIndex = 10
        DropFrame.Parent = Container
        
        local DropCorner = Instance.new("UICorner")
        DropCorner.CornerRadius = UDim.new(0, 10)
        DropCorner.Parent = DropFrame
        
        local DropLayout = Instance.new("UIListLayout")
        DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
        DropLayout.Padding = UDim.new(0, 2)
        DropLayout.Parent = DropFrame
        
        for _, option in ipairs(options) do
            local OptionButton = Instance.new("TextButton")
            OptionButton.Size = UDim2.new(1, 0, 0, 43)
            OptionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            OptionButton.BorderSizePixel = 0
            OptionButton.Text = option
            OptionButton.TextColor3 = Color3.fromRGB(220, 220, 220)
            OptionButton.Font = Enum.Font.Gotham
            OptionButton.TextSize = 13
            OptionButton.AutoButtonColor = false
            OptionButton.Parent = DropFrame
            
            OptionButton.MouseEnter:Connect(function()
                OptionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            end)
            
            OptionButton.MouseLeave:Connect(function()
                OptionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            end)
            
            OptionButton.MouseButton1Click:Connect(function()
                Button.Text = option
                DropFrame.Visible = false
                if callback then callback(option) end
            end)
        end
        
        Button.MouseButton1Click:Connect(function()
            DropFrame.Visible = not DropFrame.Visible
        end)
        
        return Container
    end
    
    createToggle("Enable Aimbot", settings.enabled, function(state)
        settings.enabled = state
        if state then
            startAimbot()
        else
            stopAimbot()
        end
    end)
    
    createSlider("FOV Radius", 50, 300, settings.fov, function(value)
        settings.fov = value
        if fovCircle then
            fovCircle.Radius = value
        end
    end)
    
    createSlider("Smoothness", 1, 50, math.floor(settings.smoothness * 100), function(value)
        settings.smoothness = value / 100
    end)
    
    createDropdown("Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, settings.targetPart, function(value)
        settings.targetPart = value
    end)
    
    createToggle("Team Check", settings.teamCheck, function(state)
        settings.teamCheck = state
    end)
    
    createToggle("Visible Check", settings.visibleCheck, function(state)
        settings.visibleCheck = state
    end)
    
    createToggle("Target NPCs", settings.targetNPCs, function(state)
        settings.targetNPCs = state
    end)
    
    createToggle("Show FOV Circle", settings.showFOV, function(state)
        settings.showFOV = state
        if fovCircle then
            fovCircle.Visible = state and settings.enabled
        end
    end)
end

local function createFOVCircle()
    if not Drawing then return end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 64
    fovCircle.Radius = settings.fov
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.8
    fovCircle.Visible = false
    fovCircle.Filled = false
end

local function isValidTarget(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end
    
    return true
end

local function isPlayerTarget(entity)
    return entity:IsA("Player")
end

local function isNPCTarget(model)
    if not model or not model:IsA("Model") then return false end
    if not settings.targetNPCs then return false end
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end
    
    if humanoid.Health <= 0 then return false end
    
    return true
end

local function isVisible(targetPart)
    if not settings.visibleCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, targetPart.Parent})
    
    return hit == nil or hit:IsDescendantOf(targetPart.Parent)
end

local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = settings.fov
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if settings.teamCheck and player.Team == LocalPlayer.Team then continue end
            
            local character = player.Character
            if not isValidTarget(character) then continue end
            
            local targetPart = character:FindFirstChild(settings.targetPart)
            if not targetPart then continue end
            
            if not isVisible(targetPart) then continue end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if not onScreen then continue end
            
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            
            if distance < shortestDistance then
                shortestDistance = distance
                closestTarget = targetPart
            end
        end
    end
    
    if settings.targetNPCs then
        for _, model in ipairs(workspace:GetDescendants()) do
            if isNPCTarget(model) then
                local targetPart = model:FindFirstChild(settings.targetPart)
                if not targetPart then continue end
                
                if not isVisible(targetPart) then continue end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if not onScreen then continue end
                
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = targetPart
                end
            end
        end
    end
    
    return closestTarget
end

local function aimAt(targetPart)
    if not targetPart then return end
    
    local targetPos = targetPart.Position
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
    
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, settings.smoothness)
end

function startAimbot()
    if connection then return end
    
    if fovCircle then
        fovCircle.Visible = settings.showFOV
    end
    
    connection = RunService.Heartbeat:Connect(function()
        if not settings.enabled then return end
        
        if fovCircle then
            local mousePos = UserInputService:GetMouseLocation()
            fovCircle.Position = mousePos
            fovCircle.Radius = settings.fov
            fovCircle.Visible = settings.showFOV
        end
        
        currentTarget = getClosestTarget()
        
        if currentTarget then
            aimAt(currentTarget)
        end
    end)
end

function stopAimbot()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if fovCircle then
        fovCircle.Visible = false
    end
    
    currentTarget = nil
end

createFOVCircle()
createGUI()
