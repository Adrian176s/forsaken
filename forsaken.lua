local targetGameId = 6331902150
if game.GameId ~= targetGameId then
    game.Players.LocalPlayer:Kick("Wrong game, please join forsaken if you wish to use this script")
    return
end

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua"))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local highlightSurvivors = false
local highlightKillers = false
local highlightTools = false
local allHighlights = {}
local lastUpdate = 0

local jumpEnabled = false
local localPlayer = Players.LocalPlayer

local bypassKillerWallsEnabled = false
local lastBypassUpdate = 0
local bypassConnection = nil

local function createHighlight(character, color, name)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    highlight.Name = name
    return highlight
end

local function clearHighlights(highlightType)
    for i = #allHighlights, 1, -1 do
        local highlight = allHighlights[i]
        if highlight and highlight.Name == highlightType then
            if highlight.Parent then
                highlight:Destroy()
            end
            table.remove(allHighlights, i)
        end
    end
end

local function updateSurvivors()
    clearHighlights("SurvivorHighlight")
    if highlightSurvivors then
        pcall(function()
            for _, survivor in pairs(workspace.Players.Survivors:GetChildren()) do
                if survivor:IsA("Model") and survivor:FindFirstChild("HumanoidRootPart") then
                    local hl = createHighlight(survivor, Color3.fromRGB(0,100,255),"SurvivorHighlight")
                    table.insert(allHighlights, hl)
                end
            end
        end)
    end
end

local function updateKillers()
    clearHighlights("KillerHighlight")
    if highlightKillers then
        pcall(function()
            for _, killer in pairs(workspace.Players.Killers:GetChildren()) do
                if killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart") then
                    local hl = createHighlight(killer, Color3.fromRGB(255,0,0),"KillerHighlight")
                    table.insert(allHighlights, hl)
                end
            end
        end)
    end
end

local function updateTools()
    clearHighlights("ToolHighlight")
    if highlightTools then
        pcall(function()
            for _, tool in pairs(workspace.Map.Ingame:GetChildren()) do
                if tool:IsA("Tool") then
                    local hl = createHighlight(tool, Color3.fromRGB(255,165,0),"ToolHighlight")
                    table.insert(allHighlights, hl)
                end
            end
        end)
    end
end

local function disableKillerCollision()
    local function disableCollisionRecursively(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                if child.CanCollide then
                    child.CanCollide = false
                end
            elseif child:IsA("Folder") or child:IsA("Model") then
                disableCollisionRecursively(child)
            end
        end
    end

    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local ingame = map:FindFirstChild("Ingame")
    if not ingame then return end
    local mapFolder = ingame:FindFirstChild("Map")
    if not mapFolder then return end

    local killerOnlyEntrances = mapFolder:FindFirstChild("KillerOnlyEntrances")
    local killerOnlyWalls = mapFolder:FindFirstChild("Killer_Only Wall")
    local wallsFolder = mapFolder:FindFirstChild("Walls (Red Trans = Killer Walkthrough)")
    local killerWalkThru = wallsFolder and wallsFolder:FindFirstChild("KillerWalkThru")

    if killerOnlyEntrances then disableCollisionRecursively(killerOnlyEntrances) end
    if killerOnlyWalls then disableCollisionRecursively(killerOnlyWalls) end
    if killerWalkThru then disableCollisionRecursively(killerWalkThru) end
end

local function enableKillerCollision()
    local function enableCollisionRecursively(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                if not child.CanCollide then
                    child.CanCollide = true
                end
            elseif child:IsA("Folder") or child:IsA("Model") then
                enableCollisionRecursively(child)
            end
        end
    end

    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local ingame = map:FindFirstChild("Ingame")
    if not ingame then return end
    local mapFolder = ingame:FindFirstChild("Map")
    if not mapFolder then return end

    local killerOnlyEntrances = mapFolder:FindFirstChild("KillerOnlyEntrances")
    local killerOnlyWalls = mapFolder:FindFirstChild("Killer_Only Wall")
    local wallsFolder = mapFolder:FindFirstChild("Walls (Red Trans = Killer Walkthrough)")
    local killerWalkThru = wallsFolder and wallsFolder:FindFirstChild("KillerWalkThru")

    if killerOnlyEntrances then enableCollisionRecursively(killerOnlyEntrances) end
    if killerOnlyWalls then enableCollisionRecursively(killerOnlyWalls) end
    if killerWalkThru then enableCollisionRecursively(killerWalkThru) end
end

local function enableBypassKillerWalls()
    if bypassConnection then return end
    
    bypassConnection = task.spawn(function()
        while bypassKillerWallsEnabled do
            pcall(disableKillerCollision)
            task.wait(0.1)
        end
    end)
end

local function disableBypassKillerWalls()
    bypassKillerWallsEnabled = false
    if bypassConnection then
        task.cancel(bypassConnection)
        bypassConnection = nil
    end
    
    pcall(enableKillerCollision)
end

local Window = Rayfield:CreateWindow({
    Name = "Player Highlighter",
    LoadingTitle = "Loading Highlighter",
    LoadingSubtitle = "by T3 Chat",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PlayerHighlighter",
        FileName = "config"
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483345998)

MainTab:CreateToggle({
    Name = "Bypass Killer Walls Only",
    CurrentValue = false,
    Callback = function(val)
        bypassKillerWallsEnabled = val
        if val then
            enableBypassKillerWalls()
            Rayfield:Notify({
                Title = "Bypass Enabled",
                Content = "Killer wall bypass is now active!",
                Duration = 3,
                Image = 4483362458
            })
        else
            disableBypassKillerWalls()
            Rayfield:Notify({
                Title = "Bypass Disabled",
                Content = "Killer wall bypass has been disabled!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "Highlight Survivors",
    CurrentValue = false,
    Callback = function(val)
        highlightSurvivors = val
        updateSurvivors()
    end,
})

MainTab:CreateToggle({
    Name = "Highlight Killers",
    CurrentValue = false,
    Callback = function(val)
        highlightKillers = val
        updateKillers()
    end,
})

MainTab:CreateToggle({
    Name = "Highlight Tools",
    CurrentValue = false,
    Callback = function(val)
        highlightTools = val
        updateTools()
    end,
})

local repairCooldown = false

local function repairGenerator()
    if repairCooldown then
        Rayfield:Notify({
            Title = "Cooldown Active",
            Content = "if there was no cooldown yall would of been banned so yw!",
            Duration = 2,
            Image = 4483362458
        })
        return
    end
    
    local plr = game.Players.LocalPlayer
    local playerGui = plr:WaitForChild("PlayerGui")
    local puzzleUI = playerGui:FindFirstChild("PuzzleUI")
    
    if not puzzleUI then
        Rayfield:Notify({
            Title = "Enter Generator First",
            Content = "Please enter a generator before using this",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    
    local char = plr.Character or plr.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local mapFolder = workspace:WaitForChild("Map"):WaitForChild("Ingame"):WaitForChild("Map")
    
    local count = 1
    for _, child in ipairs(mapFolder:GetChildren()) do
        if child.Name == "Generator" then
            child.Name = "generator "..count
            count = count + 1
            if count > 5 then break end
        end
    end
    
    local gens = {}
    for _, child in ipairs(mapFolder:GetChildren()) do
        if child.Name:match("^generator %d+$") then
            table.insert(gens, child)
        end
    end
    
    if #gens == 0 then return end
    
    local closestGen
    local shortestDist = math.huge
    for _, gen in ipairs(gens) do
        local part = gen:FindFirstChildWhichIsA("BasePart")
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestGen = gen
            end
        end
    end
    
    if not closestGen then return end
    
    local remotes = closestGen:FindFirstChild("Remotes")
    if not remotes then return end
    local re = remotes:FindFirstChild("RE")
    if not re or not re:IsA("RemoteEvent") then return end
    
    re:FireServer()
    
    repairCooldown = true
    Rayfield:Notify({
        Title = "Generator Step Completed",
        Content = "Generator step has been completed!",
        Duration = 2,
        Image = 4483362458
    })
    
    task.spawn(function()
        task.wait(1.5)
        repairCooldown = false
    end)
end

MiscTab:CreateButton({
    Name = "Enable Jump",
    Callback = function()
        jumpEnabled = true
        Rayfield:Notify({
            Title = "Jump Enabled",
            Content = "Infinite jump is now active!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

MiscTab:CreateButton({
    Name = "Auto Finish Generator Step",
    Callback = function()
        repairGenerator()
    end,
})

task.delay(0.5, function()
    for _, obj in ipairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Text == "Enable Jump" then
            obj.Text = ""
            obj.BackgroundTransparency = 1
            local icon = Instance.new("ImageLabel")
            icon.Image = "rbxassetid://6031090996"
            icon.Size = UDim2.new(0, 24, 0, 24)
            icon.Position = UDim2.new(0.5, -12, 0.5, -12)
            icon.BackgroundTransparency = 1
            icon.Parent = obj
            break
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if jumpEnabled then
        local h = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            h.JumpPower = 50
            h.JumpHeight = 7.2
        end
    end
end)

local updateRate = 0.3
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastUpdate >= updateRate then
        lastUpdate = now
        if highlightSurvivors then updateSurvivors() end
        if highlightKillers then updateKillers() end
        if highlightTools then updateTools() end
    end
end)
