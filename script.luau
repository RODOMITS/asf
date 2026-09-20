-- Загрузка библиотеки Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Создание главного окна
local Window = Rayfield:CreateWindow({
    Name = "Auto Steal | Standalone",
    LoadingTitle = "Загрузка скрипта...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil, -- Имя папки для сохранения конфигов
        FileName = "AutoSteal"
    },
    KeySystem = false
})

-- Создание вкладки
local Tab = Window:CreateTab("Главная", 4483362458) -- Иконка (ID)

-- Переменные состояния
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local AutoStealEnabled = false
local StealRadius = 62
local IsStealing = false

-- Функция проверки, является ли база нашей (основано на оригинальной логике)
local function isMyBase(plot)
    local sign = plot:FindFirstChild("PlotSign")
    local yourBase = sign and sign:FindFirstChild("YourBase")
    return yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled == true
end

-- Функция поиска ближайшего ProximityPrompt
local function getClosestTarget()
    local char = LP.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
    if not root then return nil end

    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local closestPrompt = nil
    local minDist = StealRadius

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and not isMyBase(plot) then
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    if podium:IsA("Model") then
                        -- Путь до ProximityPrompt из оригинального скрипта
                        local base = podium:FindFirstChild("Base")
                        local spawn = base and base:FindFirstChild("Spawn")
                        local attach = spawn and spawn:FindFirstChild("PromptAttachment")
                        
                        if attach then
                            for _, prompt in ipairs(attach:GetChildren()) do
                                if prompt:IsA("ProximityPrompt") then
                                    local dist = (root.Position - prompt.Parent.Position).Magnitude
                                    if dist <= minDist then
                                        minDist = dist
                                        closestPrompt = prompt
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPrompt
end

-- Функция активации Prompt
local function fireTarget(prompt)
    if IsStealing then return end
    IsStealing = true

    task.spawn(function()
        pcall(function()
            -- Если экзекутор поддерживает нативную функцию fireproximityprompt, используем её
            if fireproximityprompt then
                fireproximityprompt(prompt, 1)
                task.wait(1.3)
            -- Иначе используем getconnections (как в оригинальном коде)
            elseif getconnections then
                for _, conn in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if type(conn.Function) == "function" then pcall(conn.Function) end
                end
                
                task.wait(1.3) -- Длительность удержания (duration из оригинала)
                
                for _, conn in ipairs(getconnections(prompt.Triggered)) do
                    if type(conn.Function) == "function" then pcall(conn.Function) end
                end
            end
        end)
        
        task.wait(0.1)
        IsStealing = false
    end)
end

-- Главный цикл, работающий каждый кадр
RunService.Heartbeat:Connect(function()
    if AutoStealEnabled and not IsStealing then
        local targetPrompt = getClosestTarget()
        if targetPrompt then
            fireTarget(targetPrompt)
        end
    end
end)

-- Создание UI элементов в Rayfield
Tab:CreateToggle({
    Name = "Включить Auto Steal",
    CurrentValue = false,
    Flag = "ToggleAutoSteal", 
    Callback = function(Value)
        AutoStealEnabled = Value
        if not Value then
            IsStealing = false -- Сброс состояния при выключении
        end
    end,
})

Tab:CreateSlider({
    Name = "Радиус кражи",
    Range = {10, 200},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 62,
    Flag = "SliderRadius", 
    Callback = function(Value)
        StealRadius = Value
    end,
})

-- Уведомление о том, что UI загружен
Rayfield:Notify({
    Title = "Скрипт загружен",
    Content = "Интерфейс успешно инициализирован.",
    Duration = 3,
    Image = 4483362458,
})
