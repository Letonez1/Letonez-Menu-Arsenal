
-- LetonezMenu.client.lua
-- Roblox Studio | LETONEZ MENU | ARSENAL | Painel de treino + ESP + FOV
-- Assistência de mira suave para jogadores adversários no jogo próprio.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIGURAÇÃO
--==================================================

local Config = {
    AimEnabled = false,
    FOVVisible = true,
    AimFOV = 150,
    AimDistance = 500,
    AimPart = "Head",
    AimSmoothness = 12, -- maior = movimento mais suave/lento

    ESPEnabled = true,
    ESPNames = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPHighlight = true,
    ESPDistanceLimit = 1500,
    GodMode = false, -- solicita imortalidade ao servidor (somente no jogo próprio)
}

-- Limpa uma instância antiga do painel
local oldGui = playerGui:FindFirstChild("LetonezMenu")
if oldGui then
    oldGui:Destroy()
end

local espData = {}
local connections = {}
local minimized = false
local closed = false

--==================================================
-- INTERFACE
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "LetonezMenu"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(330, 490)
panel.Position = UDim2.new(0, 25, 0.2, 0)
panel.BackgroundColor3 = Color3.fromRGB(13, 17, 29)
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 25, 42)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 25)),
})
panelGradient.Rotation = 90
panelGradient.Parent = panel

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(0, 190, 255)
outline.Thickness = 1.5
outline.Transparency = 0.12
outline.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(20, 31, 52)
header.BorderSizePixel = 0
header.Parent = panel

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(23, 55, 86)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 29, 49)),
})
headerGradient.Rotation = 0
headerGradient.Parent = header

local accent = Instance.new("Frame")
accent.Name = "AccentLine"
accent.BorderSizePixel = 0
accent.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
accent.Size = UDim2.new(1, -24, 0, 2)
accent.Position = UDim2.new(0, 12, 1, -2)
accent.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -115, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "LETONEZ MENU | ARSENAL"
title.TextColor3 = Color3.fromRGB(245, 250, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local function button(parent, text, size, position)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = Color3.fromRGB(31, 45, 69)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.Parent = parent

    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(74, 112, 151)
    stroke.Transparency = 0.68
    stroke.Thickness = 1
    stroke.Parent = b

    return b
end

local minimizeButton = button(
    header, "—", UDim2.fromOffset(30, 28),
    UDim2.new(1, -70, 0, 8)
)

local closeButton = button(
    header, "×", UDim2.fromOffset(30, 28),
    UDim2.new(1, -35, 0, 8)
)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 55, 78)

-- Navegação entre a página principal e os créditos
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Position = UDim2.fromOffset(10, 50)
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local mainTabButton = button(tabBar, "PAINEL", UDim2.new(0.5, -3, 1, 0), UDim2.new(0, 0, 0, 0))
local creditsTabButton = button(tabBar, "CRÉDITOS", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0))

local content = Instance.new("ScrollingFrame")
content.Name = "Controls"
content.Position = UDim2.fromOffset(10, 86)
content.Size = UDim2.new(1, -20, 1, -96)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local creditsPage = Instance.new("Frame")
creditsPage.Name = "CreditsPage"
creditsPage.Position = content.Position
creditsPage.Size = content.Size
creditsPage.BackgroundColor3 = Color3.fromRGB(17, 25, 42)
creditsPage.BorderSizePixel = 0
creditsPage.Visible = false
creditsPage.Parent = panel
Instance.new("UICorner", creditsPage).CornerRadius = UDim.new(0, 10)

local creditsStroke = Instance.new("UIStroke")
creditsStroke.Color = Color3.fromRGB(0, 155, 210)
creditsStroke.Transparency = 0.55
creditsStroke.Parent = creditsPage

local creditsTitle = Instance.new("TextLabel")
creditsTitle.Position = UDim2.fromOffset(12, 18)
creditsTitle.Size = UDim2.new(1, -24, 0, 34)
creditsTitle.BackgroundTransparency = 1
creditsTitle.Text = "LETONEZ MENU | ARSENAL"
creditsTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
creditsTitle.Font = Enum.Font.GothamBold
creditsTitle.TextSize = 16
creditsTitle.TextWrapped = true
creditsTitle.Parent = creditsPage

local creditsAuthor = Instance.new("TextLabel")
creditsAuthor.Position = UDim2.fromOffset(12, 62)
creditsAuthor.Size = UDim2.new(1, -24, 0, 48)
creditsAuthor.BackgroundTransparency = 1
creditsAuthor.Text = "Feito por Letonez"
creditsAuthor.TextColor3 = Color3.fromRGB(235, 242, 252)
creditsAuthor.Font = Enum.Font.GothamSemibold
creditsAuthor.TextSize = 14
creditsAuthor.Parent = creditsPage

local discordCaption = Instance.new("TextLabel")
discordCaption.Position = UDim2.fromOffset(12, 120)
discordCaption.Size = UDim2.new(1, -24, 0, 28)
discordCaption.BackgroundTransparency = 1
discordCaption.Text = "Servidor oficial do Discord:"
discordCaption.TextColor3 = Color3.fromRGB(175, 195, 215)
discordCaption.Font = Enum.Font.Gotham

discordCaption.TextSize = 12
discordCaption.TextXAlignment = Enum.TextXAlignment.Left
discordCaption.Parent = creditsPage

local discordLink = Instance.new("TextBox")
discordLink.Position = UDim2.fromOffset(12, 151)
discordLink.Size = UDim2.new(1, -24, 0, 38)
discordLink.BackgroundColor3 = Color3.fromRGB(25, 38, 59)
discordLink.BorderSizePixel = 0
discordLink.Text = "https://discord.gg/9sVFcK5wuA"
discordLink.TextColor3 = Color3.fromRGB(100, 210, 255)
discordLink.Font = Enum.Font.GothamSemibold
discordLink.TextSize = 12
discordLink.ClearTextOnFocus = false
discordLink.TextEditable = true
discordLink.Parent = creditsPage
Instance.new("UICorner", discordLink).CornerRadius = UDim.new(0, 7)

local discordHint = Instance.new("TextLabel")
discordHint.Position = UDim2.fromOffset(12, 198)
discordHint.Size = UDim2.new(1, -24, 0, 46)
discordHint.BackgroundTransparency = 1
discordHint.Text = "Selecione o link acima para copiá-lo. Obrigado por usar o menu!"
discordHint.TextColor3 = Color3.fromRGB(145, 165, 190)
discordHint.Font = Enum.Font.Gotham
discordHint.TextSize = 11
discordHint.TextWrapped = true
discordHint.Parent = creditsPage

local activeCredits = false

local function setActiveTab(showCredits)
    activeCredits = showCredits
    content.Visible = not showCredits
    creditsPage.Visible = showCredits
    mainTabButton.BackgroundColor3 = showCredits and Color3.fromRGB(31, 45, 69) or Color3.fromRGB(0, 125, 180)
    creditsTabButton.BackgroundColor3 = showCredits and Color3.fromRGB(0, 125, 180) or Color3.fromRGB(31, 45, 69)
end

mainTabButton.Activated:Connect(function()
    setActiveTab(false)
end)

creditsTabButton.Activated:Connect(function()
    setActiveTab(true)
end)

local function section(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 27)
    label.BackgroundColor3 = Color3.fromRGB(21, 36, 59)
    label.BorderSizePixel = 0
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(0, 200, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content

    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 7)

    local sectionStroke = Instance.new("UIStroke")
    sectionStroke.Color = Color3.fromRGB(0, 155, 210)
    sectionStroke.Transparency = 0.78
    sectionStroke.Thickness = 1
    sectionStroke.Parent = label
end

local function toggleRow(text, getValue, setValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -105, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local b = button(
        row, "", UDim2.fromOffset(95, 28),
        UDim2.new(1, -95, 0, 2)
    )

    local function refresh()
        local enabled = getValue()
        b.Text = enabled and "ON" or "OFF"
        b.BackgroundColor3 = enabled
            and Color3.fromRGB(0, 155, 112)
            or Color3.fromRGB(132, 48, 67)
    end

    b.Activated:Connect(function()
        setValue(not getValue())
        refresh()
    end)

    refresh()
end

local function numberRow(text, getValue, setValue, minValue, maxValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.fromOffset(90, 28)
    input.Position = UDim2.new(1, -90, 0, 2)
    input.BackgroundColor3 = Color3.fromRGB(25, 35, 54)
    input.BorderSizePixel = 0
    input.TextColor3 = Color3.new(1, 1, 1)
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.Text = tostring(getValue())
    input.ClearTextOnFocus = false
    input.Parent = row

    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 5)

    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value then
            setValue(math.clamp(value, minValue, maxValue))
        end
        input.Text = tostring(getValue())
    end)
end

local function choiceRow(text, choices, getValue, setValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -145, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local b = button(
        row, getValue(), UDim2.fromOffset(135, 28),
        UDim2.new(1, -135, 0, 2)
    )

    b.Activated:Connect(function()
        local index = table.find(choices, getValue()) or 1
        index = index % #choices + 1
        setValue(choices[index])
        b.Text = choices[index]
    end)
end

--==================================================
-- CÍRCULO DO FOV
--==================================================

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = gui

Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(0, 210, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

--==================================================
-- CONTROLES DA MIRA DE TREINO
--==================================================

section("MIRA DE TREINO")

toggleRow("Aimbot", function()
    return Config.AimEnabled
end, function(value)
    Config.AimEnabled = value
end)

toggleRow("Mostrar FOV", function()
    return Config.FOVVisible
end, function(value)
    Config.FOVVisible = value
end)

numberRow("Raio FOV (px)", function()
    return Config.AimFOV
end, function(value)
    Config.AimFOV = value
end, 30, 400)

numberRow("Alcance (studs)", function()
    return Config.AimDistance
end, function(value)
    Config.AimDistance = value
end, 25, 2000)

choiceRow("Parte-alvo", {"Head", "HumanoidRootPart"}, function()
    return Config.AimPart
end, function(value)
    Config.AimPart = value
end)

numberRow("Delay para puxar a mira (maior = mais lenta)", function()
    return Config.AimSmoothness
end, function(value)
    Config.AimSmoothness = value
end, 2, 30)

--==================================================
-- CONTROLES DO ESP
--==================================================

section("ESP DE JOGADORES")

toggleRow("Ativar ESP", function()
    return Config.ESPEnabled
end, function(value)
    Config.ESPEnabled = value
end)

toggleRow("Mostrar nomes", function()
    return Config.ESPNames
end, function(value)
    Config.ESPNames = value
end)

toggleRow("Mostrar vida", function()
    return Config.ESPHealth
end, function(value)
    Config.ESPHealth = value
end)

toggleRow("Mostrar distância", function()
    return Config.ESPDistance
end, function(value)
    Config.ESPDistance = value
end)

toggleRow("Mostrar contornos", function()
    return Config.ESPHighlight
end, function(value)
    Config.ESPHighlight = value
end)

numberRow("Alcance do ESP", function()
    return Config.ESPDistanceLimit
end, function(value)
    Config.ESPDistanceLimit = value
end, 50, 3000)

--==================================================
-- IMORTALIDADE DE TESTE (somente em experiência própria com suporte no servidor)
--==================================================

toggleRow("Imortalidade (servidor próprio)", function()
    return Config.GodMode
end, function(value)
    Config.GodMode = value

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local event = replicatedStorage:FindFirstChild("TrainingGodModeEvent")

    if event and event:IsA("RemoteEvent") then
        -- Este evento só funciona se o desenvolvedor implementar e autorizar
        -- a função em um Script do servidor da própria experiência.
        event:FireServer(value)
    else
        Config.GodMode = false
        warn("Imortalidade indisponível: a invulnerabilidade precisa ser implementada e autorizada no servidor da sua própria experiência Roblox. Um LocalScript não consegue concedê-la em Arsenal ou em jogos de terceiros.")
    end
end)

--==================================================
-- ARRASTAR / MINIMIZAR / REABRIR
--==================================================

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

minimizeButton.Activated:Connect(function()
    minimized = not minimized
    tabBar.Visible = not minimized
    content.Visible = not minimized and not activeCredits
    creditsPage.Visible = not minimized and activeCredits
    panel.Size = minimized
        and UDim2.fromOffset(330, 44)
        or UDim2.fromOffset(330, 490)
    minimizeButton.Text = minimized and "+" or "—"
end)

closeButton.Activated:Connect(function()
    gui.Enabled = false
    closed = true
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
        closed = not gui.Enabled
    end
end)

--==================================================
-- ESP DE JOGADORES
--==================================================

local function getTeamColor(player)
    if localPlayer.Team and player.Team then
        if localPlayer.Team == player.Team then
            return Color3.fromRGB(70, 170, 255)
        end
        return Color3.fromRGB(255, 75, 75)
    end
    return Color3.fromRGB(255, 210, 70)
end

local function removeESP(player)
    local data = espData[player]
    if not data then return end

    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end

    espData[player] = nil
end

local function createESP(player, character)
    removeESP(player)
    if player == localPlayer or not character then return end

    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        local root = character:WaitForChild("HumanoidRootPart", 5)

        if not humanoid or not root or not character.Parent then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "LetonezPlayerHighlight"
        highlight.Adornee = character
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "LetonezPlayerInfo"
        billboard.Adornee = root
        billboard.Size = UDim2.fromOffset(220, 60)
        billboard.StudsOffset = Vector3.new(0, 3.2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = playerGui

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextStrokeTransparency = 0.25
        label.TextWrapped = true
        label.Parent = billboard

        espData[player] = {
            character = character,
            humanoid = humanoid,
            root = root,
            highlight = highlight,
            billboard = billboard,
            label = label,
        }
    end)
end

local function trackPlayer(player)
    if player == localPlayer then return end

    table.insert(connections, player.CharacterAdded:Connect(function(character)
        createESP(player, character)
    end))

    table.insert(connections, player.CharacterRemoving:Connect(function()
        removeESP(player)
    end))

    if player.Character then
        createESP(player, player.Character)
    end
end

for _, player in Players:GetPlayers() do
    trackPlayer(player)
end

table.insert(connections, Players.PlayerAdded:Connect(trackPlayer))
table.insert(connections, Players.PlayerRemoving:Connect(removeESP))

--==================================================
-- VERIFICAÇÃO DE LINHA DE VISÃO
--==================================================

local function hasLineOfSight(camera, targetCharacter, targetPart)
    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {
        localPlayer.Character,
    }
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)

    -- Se o primeiro objeto atingido pertence ao alvo, ele está visível.
    return result ~= nil and result.Instance:IsDescendantOf(targetCharacter)
end

--==================================================
-- ALVOS: JOGADORES ADVERSÁRIOS
--==================================================

local function getTrainingTarget()
    local camera = workspace.CurrentCamera
    local character = localPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")

    if not camera or not myRoot then
        return nil
    end

    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local bestPart = nil
    local bestScreenDistance = Config.AimFOV

    for _, player in Players:GetPlayers() do
        if player == localPlayer then
            continue
        end

        -- Só considera adversários quando as equipes estão definidas.
        if localPlayer.Team ~= nil
            and player.Team ~= nil
            and player.Team == localPlayer.Team then
            continue
        end

        local targetCharacter = player.Character
        if not targetCharacter then
            continue
        end

        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        local root = targetCharacter:FindFirstChild("HumanoidRootPart")
        local part = targetCharacter:FindFirstChild(Config.AimPart)

        if not humanoid or humanoid.Health <= 0 or not root or not part then
            continue
        end

        if (myRoot.Position - root.Position).Magnitude > Config.AimDistance then
            continue
        end

        local screenPoint, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen or screenPoint.Z <= 0 then
            continue
        end

        -- Ignora o alvo se uma parede/objeto bloquear a linha de visão.
        if not hasLineOfSight(camera, targetCharacter, part) then
            continue
        end

        local screenDistance = (
            Vector2.new(screenPoint.X, screenPoint.Y) - center
        ).Magnitude

        if screenDistance >= bestScreenDistance then
            continue
        end

        bestScreenDistance = screenDistance
        bestPart = part
    end

    return bestPart
end

--==================================================
-- LOOP PRINCIPAL
--==================================================

RunService:BindToRenderStep(
    "TrainingPanelUpdate",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        local camera = workspace.CurrentCamera

        fovCircle.Visible = Config.FOVVisible
        fovCircle.Size = UDim2.fromOffset(
            Config.AimFOV * 2,
            Config.AimFOV * 2
        )

        if Config.AimEnabled and camera then
            local target = getTrainingTarget()

            if target then
                -- Interpola em vez de travar a câmera diretamente no alvo.
                -- A interpolação deixa o movimento manual mais fácil de controlar.
                local desiredCFrame = CFrame.lookAt(
                    camera.CFrame.Position,
                    target.Position
                )
                local smoothness = math.clamp(Config.AimSmoothness, 2, 30)
                local alpha = 1 / smoothness
                camera.CFrame = camera.CFrame:Lerp(desiredCFrame, alpha)
            end
        end
    end
)

table.insert(connections, RunService.RenderStepped:Connect(function()
    local character = localPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(espData) do
        local valid = Config.ESPEnabled
            and player.Parent == Players
            and data.character.Parent ~= nil
            and data.humanoid.Health > 0
            and myRoot ~= nil

        if not valid then
            data.billboard.Enabled = false
            data.highlight.Enabled = false
            continue
        end

        local distance = (myRoot.Position - data.root.Position).Magnitude
        local inRange = distance <= Config.ESPDistanceLimit
        data.billboard.Enabled = inRange
        data.highlight.Enabled = inRange and Config.ESPHighlight

        local color = getTeamColor(player)
        data.highlight.FillColor = color
        data.highlight.OutlineColor = color

        local lines = {}

        if Config.ESPNames then
            table.insert(lines, player.DisplayName)
        end

        if Config.ESPHealth then
            table.insert(lines, string.format(
                "HP: %d/%d",
                math.ceil(data.humanoid.Health),
                math.ceil(data.humanoid.MaxHealth)
            ))
        end

        if Config.ESPDistance then
            table.insert(lines, string.format("%d studs", distance))
        end

        data.label.Text = table.concat(lines, "\n")
        data.label.TextColor3 = color
    end
end))
