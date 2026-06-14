if queue_on_teleport then
    queue_on_teleport([[loadstring(game:HttpGet('https://raw.githubusercontent.com/0nbd/lotusautogen/refs/heads/main/auto.lua'))()]])
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer

getgenv().lotusconf = {
    autogen_tp = true,
    promptdelay = 0.05,
    puzzles_completed = 3,       
    max_players = 10,         
    min_round_time = 60,              
}

local completedPuzzlesInServer = 0
local hitboxUpdated = false
local autogenAllowed = false
local lastSpectateCheck = true

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

local function getMapFolder()
    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    return ingame and ingame:FindFirstChild("Map")
end

local function isSpectating()
    local spectators = Workspace:FindFirstChild("Spectators")
    if spectators and spectators:FindFirstChild(lp.Name) then
        return true
    end
    return false
end

local function serverHop()
    notify("System", "Finding preferred server profile...", 5)
    task.wait(1)
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local api = HttpService:JSONDecode(game:HttpGet(url))
        
        local targetServer = nil
        local bestPlayerCount = -1
        
        for _, server in ipairs(api.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                if server.playing <= getgenv().lotusconf.max_players and server.playing > bestPlayerCount then
                    bestPlayerCount = server.playing
                    targetServer = server.id
                end
            end
        end
        
        if targetServer then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, lp)
        else
            TeleportService:Teleport(game.PlaceId, lp)
        end
    end)
end

local function getRoundTime()
    local timerObj = ReplicatedStorage:FindFirstChild("RoundTimer")
    if not timerObj then return 0 end
    
    local rawValue = timerObj.Value
    if type(rawValue) == "number" then
        return rawValue
    elseif type(rawValue) == "string" then
        local min, sec = rawValue:match("(%d+):(%d+)")
        if min and sec then
            return (tonumber(min) * 60) + tonumber(sec)
        else
            return tonumber(rawValue) or 0
        end
    end
    return 0
end

task.spawn(function()
    while true do
        local playersFolder = Workspace:FindFirstChild("Players")
        local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
        if killersFolder then
            for _, killer in ipairs(killersFolder:GetChildren()) do
                if killer:GetAttribute("Username") == lp.Name then
                    local char = lp.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        hum.Health = 0
                    end
                end
            end
        end

        local spectating = isSpectating()
        if not spectating then
            if lastSpectateCheck then
                task.wait(5)
                if not isSpectating() then
                    autogenAllowed = true
                    if Workspace:GetAttribute("ExperimentalHitboxes") ~= nil and not hitboxUpdated then
                        Workspace:SetAttribute("ExperimentalHitboxes", false)
                        notify("Security", "ExperimentalHitboxes disabled safely.", 3)
                        hitboxUpdated = true
                    end
                end
                lastSpectateCheck = false
            end
        else
            autogenAllowed = false
            hitboxUpdated = false
            lastSpectateCheck = true
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    notify("Lotus", "Automation actively scanning environment...", 4)
    
    while true do
        if getRoundTime() < getgenv().lotusconf.min_round_time then
            notify("Match Alert", "Round time conditions unsatisfied. Finding replacement instance...", 4)
            serverHop()
            break
        end

        if completedPuzzlesInServer >= getgenv().lotusconf.puzzles_completed then
            notify("Quota Met", "Completed task thresholds! Rotating nodes...", 4)
            serverHop()
            break
        end

        if getgenv().lotusconf.autogen_tp and autogenAllowed then
            local mapFolder = getMapFolder()
            if mapFolder then
                for _, genNode in ipairs(mapFolder:GetChildren()) do
                    if completedPuzzlesInServer >= getgenv().lotusconf.puzzles_completed or not autogenAllowed then break end
                    
                    if genNode.Name == "Generator" then
                        local progressAttr = genNode:GetAttribute("Progress")
                        local progressInstance = genNode:FindFirstChild("Progress")
                        local currentProgress = progressAttr or (progressInstance and progressInstance.Value) or 0
                        
                        if currentProgress < 100 then
                            pcall(function()
                                local positions = genNode:FindFirstChild("Positions")
                                local centerNode = positions and positions:FindFirstChild("Center")
                                local char = lp.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                local hum = char and char:FindFirstChildOfClass("Humanoid")
                                
                                if centerNode and hrp and hum and hum.Health > 0 then
                                    hrp.CFrame = centerNode.CFrame * CFrame.new(0, 0, -2)
                                    task.wait(0.15)
                                    
                                    local completedThisInteraction = false
                                    for _, object in ipairs(genNode:GetDescendants()) do
                                        if not autogenAllowed then break end
                                        if object:IsA("ProximityPrompt") then
                                            if getgenv().lotusconf.promptdelay > 0 then
                                                task.wait(getgenv().lotusconf.promptdelay)
                                            end
                                            fireproximityprompt(object)
                                            completedThisInteraction = true
                                        end
                                    end
                                    
                                    if autogenAllowed then
                                        local remoteEvent = genNode:FindFirstChild("Remotes") and genNode.Remotes:FindFirstChild("RE")
                                        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                                            remoteEvent:FireServer()
                                            completedThisInteraction = true
                                        end
                                    end
                                    
                                    if completedThisInteraction then
                                        completedPuzzlesInServer = completedPuzzlesInServer + 1
                                        notify("Puzzle Completed", string.format("You completed a puzzle! (%d/%d)", completedPuzzlesInServer, getgenv().lotusconf.puzzles_completed), 3)
                                    end
                                    task.wait(0.15)
                                end
                            end)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)
