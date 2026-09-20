local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- === Переменные состояния ===
local AutoDeliverEnabled = false
local IsDelivering = false

-- === Защита от дублирования интерфейса ===
local guiName = "SimpleAutoDeliverTPGUI"
local targetParent = (gethui and gethui()) or CoreGui or LP:FindFirstChild("PlayerGui")
if targetParent:FindFirstChild(guiName) then
    targetParent[guiName]:Destroy()
end

-- === Создание интерфейса ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Auto Deliver (Teleport)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- === КНОПКА ЗАКРЫТИЯ (X) ===
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = MainFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, 0, 0, 2)
Divider.Position = UDim2.new(0, 0, 0, 35)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- Кнопка Toggle
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 210, 0, 35)
ToggleBtn.Position = UDim2.new(0, 20, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Красный (Выкл)
ToggleBtn.Text = "ВКЛЮЧИТЬ"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- === Логика перетаскивания окна (Drag) ===
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === UI Логика ===
ToggleBtn.MouseButton1Click:Connect(function()
    AutoDeliverEnabled = not AutoDeliverEnabled
    if AutoDeliverEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 75) -- Зеленый
        ToggleBtn.Text = "ВЫКЛЮЧИТЬ"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Красный
        ToggleBtn.Text = "ВКЛЮЧИТЬ"
    end
end)

-- Действие при нажатии на крестик
CloseBtn.MouseButton1Click:Connect(function()
    AutoDeliverEnabled = false -- Выключаем логику
    ScreenGui:Destroy() -- Удаляем интерфейс
end)

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
end)

-- === ЛОГИКА AUTO DELIVER ===

local function isCarrying()
    local char = LP.Character
    if not char then return false end
    
    if LP:GetAttribute("Stealing") == true then return true end
    if char:GetAttribute("Stealing") == true then return true end
    
    for _, name in ipairs({"Carrying", "IsCarrying", "Grabbed", "Holding", "StealHold", "HasGrab"}) do
        local v = char:FindFirstChild(name, true)
        if v then
            if v:IsA("BoolValue") and v.Value then return true end
            if v:IsA("ObjectValue") and v.Value then return true end
            if v:IsA("StringValue") and v.Value ~= "" then return true end
        end
    end
    
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChildWhichIsA("BasePart", true) then
            local n = child.Name:lower()
            if n:find("brainrot") or n:find("animal") or n:find("carry") or n:find("grab") or n:find("steal") or n:find("hold") then
                return true
            end
        end
    end
    
    return false
end

local function getMyDeliveryHitbox()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            local sign = plot:FindFirstChild("PlotSign")
            local yourBase = sign and sign:FindFirstChild("YourBase")
            
            if yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled == true then
                local hitbox = plot:FindFirstChild("DeliveryHitbox", true)
                return hitbox
            end
        end
    end
    return nil
end

local function deliverItemViaTeleport()
    if IsDelivering then return end
    
    local hitbox = getMyDeliveryHitbox()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hitbox or not hrp then return end
    
    IsDelivering = true
    
    task.spawn(function()
        local originalCFrame = hrp.CFrame
        local originalVelocity = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        hrp.CFrame = hitbox.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.35)
        
        hrp.CFrame = originalCFrame
        hrp.AssemblyLinearVelocity = originalVelocity
        
        task.wait(0.5)
        IsDelivering = false
    end)
end

-- Основной цикл (проверяет каждые 0.1 сек)
task.spawn(function()
    while task.wait(0.1) do
        -- Если интерфейс удален (нажат крестик), то останавливаем бесконечный цикл
        if not ScreenGui or not ScreenGui.Parent then break end 
        
        if AutoDeliverEnabled and not IsDelivering then
            if isCarrying() then
                deliverItemViaTeleport()
            end
        end
    end
end)
