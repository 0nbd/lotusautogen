local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

getgenv().lotusconf = {
    autogen_legit = false,
    autogen_tp = false,
    promptdelay = 0.05,
    mintime = 2.6,
    maxtime = 3.8,
}

local activeGenThread = nil

local function getMapFolder()
    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    return ingame and ingame:FindFirstChild("Map")
end

local function isSpectating()
    local char = lp.Character
    local playersFolder = Workspace:FindFirstChild("Players")
    local spectatingFolder = playersFolder and playersFolder:FindFirstChild("Spectating")
    
    if spectatingFolder and char and char:IsDescendantOf(spectatingFolder) then
        return true
    end
    return false
end

task.spawn(function()
    while true do
        if getgenv().lotusconf.autogen_tp and not isSpectating() then
            pcall(function()
                local mapFolder = getMapFolder()
                if mapFolder then
                    for _, genNode in ipairs(mapFolder:GetChildren()) do
                        if not getgenv().lotusconf.autogen_tp or isSpectating() then break end
                        
                        if genNode.Name:match("Generator") and not genNode.Name:match("fakeGenerator") then
                            local progressAttr = genNode:GetAttribute("Progress")
                            local progressInstance = genNode:FindFirstChild("Progress")
                            local currentProgress = progressAttr or (progressInstance and progressInstance.Value) or 0
                            
                            if currentProgress < 100 then
                                local positions = genNode:FindFirstChild("Positions")
                                local centerNode = positions and positions:FindFirstChild("Center")
                                local char = lp.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                local hum = char and char:FindFirstChildOfClass("Humanoid")
                                
                                if centerNode and hrp and hum and hum.Health > 0 then
                                    hrp.CFrame = centerNode.CFrame * CFrame.new(0, 0, -2)
                                    task.wait(0.15)
                                    
                                    for _, object in ipairs(genNode:GetDescendants()) do
                                        if isSpectating() then break end
                                        if object:IsA("ProximityPrompt") then
                                            if getgenv().lotusconf.promptdelay > 0 then
                                                task.wait(getgenv().lotusconf.promptdelay)
                                            end
                                            fireproximityprompt(object)
                                        end
                                    end
                                    
                                    if not isSpectating() then
                                        local remoteEvent = genNode:FindFirstChild("Remotes") and genNode.Remotes:FindFirstChild("RE")
                                        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                                            remoteEvent:FireServer()
                                        end
                                    end
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

local function startAutogenSequence(generatorFolder)
    if activeGenThread then task.cancel(activeGenThread) end
    
    activeGenThread = task.spawn(function()
        while getgenv().lotusconf.autogen_legit and generatorFolder and generatorFolder.Parent do
            if isSpectating() then task.wait(0.5) continue end
            
            local min = getgenv().lotusconf.mintime
            local max = getgenv().lotusconf.maxtime
            local delayTime = min
            if max > min then
                delayTime = math.random(math.floor(min * 100), math.floor(max * 100)) / 100
            end
            
            task.wait(delayTime)
            
            if not (generatorFolder and generatorFolder.Parent) or isSpectating() then break end
            local remoteEvent = generatorFolder:FindFirstChild("Remotes") and generatorFolder.Remotes:FindFirstChild("RE")
            
            if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                remoteEvent:FireServer()
                Rayfield:Notify({
                    Title = "auto-gen",
                    Content = string.format("solved in %.2fs", delayTime),
                    Duration = 3,
                    Image = 4483362458
                })
            else
                break
            end
        end
        activeGenThread = nil
    end)
end

local function stopAutogenSequence()
    if activeGenThread then
        task.cancel(activeGenThread)
        activeGenThread = nil
        Rayfield:Notify({
            Title = "auto-gen",
            Content = "stopped.",
            Duration = 2,
            Image = 4483362458
        })
    end
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "InvokeServer" and self.Name == "RF" and self.Parent and self.Parent.Name == "Remotes" then
        if getgenv().lotusconf.autogen_legit and not isSpectating() then
            if args[1] == "Enter" then
                if self.Parent.Parent then startAutogenSequence(self.Parent.Parent) end
            elseif args[1] == "Leave" then
                stopAutogenSequence()
            end
        end
    end
    return oldNamecall(self, ...)
end)

local Window = Rayfield:CreateWindow({
    Name = "lotus generator [BETA]",
    LoadingTitle = "sneaky peek",
    LoadingSubtitle = "sneaky peek",
    ConfigurationSaving = {
        Enabled = true
    },
    Discord = { Enabled = false },
    KeySystem = false
})

local TabMain = Window:CreateTab("automation")

TabMain:CreateSection("generator")
TabMain:CreateToggle({ 
    Name = "autogen (tp)", 
    CurrentValue = false, 
    Callback = function(v) getgenv().lotusconf.autogen_tp = v end 
})

TabMain:CreateToggle({ 
    Name = "legit auto-gen", 
    CurrentValue = false, 
    Callback = function(v) getgenv().lotusconf.autogen_legit = v end 
})

TabMain:CreateSection("settings")
TabMain:CreateSlider({ 
    Name = "proximity prompt delay", 
    Range = {0, 2}, 
    Increment = 0.01, 
    Suffix = "s", 
    CurrentValue = 0.05, 
    Callback = function(v) getgenv().lotusconf.promptdelay = v end 
})

TabMain:CreateSlider({ 
    Name = "minimum autogen speed", 
    Range = {0.1, 10.0}, 
    Increment = 0.1, 
    Suffix = "s", 
    CurrentValue = 2.6, 
    Callback = function(v) getgenv().lotusconf.mintime = v end 
})

TabMain:CreateSlider({ 
    Name = "maximum autogen speed", 
    Range = {0.1, 10.0}, 
    Increment = 0.1, 
    Suffix = "s", 
    CurrentValue = 3.8, 
    Callback = function(v) getgenv().lotusconf.maxtime = v end 
})

TabMain:CreateSection("instant")
TabMain:CreateButton({
    Name = "fire RE (finish generator)",
    Callback = function()
        if isSpectating() then return end
        local mapFolder = getMapFolder()
        if mapFolder then
            for _, node in ipairs(mapFolder:GetChildren()) do
                if node.Name:match("Generator") and not node.Name:match("fakeGenerator") then
                    pcall(function()
                        local remote = node:FindFirstChild("Remotes") and node.Remotes:FindFirstChild("RE")
                        if remote and remote:IsA("RemoteEvent") then remote:FireServer() end
                    end)
                end
            end
        end
    end
})

Rayfield:Notify({
    Title = "lotus",
    Content = ".gg/WQECS7ysPQ",
    Duration = 4,
    Image = 4483362458
})
