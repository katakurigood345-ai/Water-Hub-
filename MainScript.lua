-- [[ CONFIGURATION ]] --
local SAVE_FILE = "WaterHub_HunterLogs.json"
local MIN_VALUE = 10000000 -- 10M
local AUTO_JOIN_ENABLED = false -- Can be toggled in GUI

-- [[ SERVICES ]] --
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- [[ DATA MANAGEMENT ]] --
local function getLogs()
    if isfile(SAVE_FILE) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(SAVE_FILE)) end)
        return success and data or {}
    end
    return {}
end

local function saveServer(data)
    local logs = getLogs()
    -- Prevent duplicate IDs in the list
    for _, entry in pairs(logs) do if entry.JobId == data.JobId then return end end
    table.insert(logs, data)
    writefile(SAVE_FILE, HttpService:JSONEncode(logs))
end

-- [[ GUI CONSTRUCTION ]] --
local sg = Instance.new("ScreenGui", LP.PlayerGui)
sg.Name = "WaterHub_V3"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 400, 0, 320)
main.Position = UDim2.new(0.5, -200, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "WATER HUB | BRAINROT DETECTOR"
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.TextColor3 = Color3.new(1, 1, 1)

local listScroll = Instance.new("ScrollingFrame", main)
listScroll.Size = UDim2.new(0.95, 0, 0, 180)
listScroll.Position = UDim2.new(0.025, 0, 0.15, 0)
listScroll.CanvasSize = UDim2.new(0, 0, 10, 0) -- Long list support
listScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
listScroll.ScrollBarThickness = 6

-- [[ BUTTONS PANEL ]] --
local autoBtn = Instance.new("TextButton", main)
autoBtn.Size = UDim2.new(0.3, 0, 0, 30)
autoBtn.Position = UDim2.new(0.025, 0, 0.75, 0)
autoBtn.Text = "AUTO JOIN: OFF"
autoBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
autoBtn.TextColor3 = Color3.new(1, 1, 1)

local clearBtn = Instance.new("TextButton", main)
clearBtn.Size = UDim2.new(0.3, 0, 0, 30)
clearBtn.Position = UDim2.new(0.35, 0, 0.75, 0)
clearBtn.Text = "CLEAR LIST"
clearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
clearBtn.TextColor3 = Color3.new(1, 1, 1)

local huntBtn = Instance.new("TextButton", main)
huntBtn.Size = UDim2.new(0.3, 0, 0, 30)
huntBtn.Position = UDim2.new(0.675, 0, 0.75, 0)
huntBtn.Text = "HUNT NEXT"
huntBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
huntBtn.TextColor3 = Color3.new(1, 1, 1)

-- [[ LOGIC ]] --
local function updateUI()
    for _, v in pairs(listScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    local logs = getLogs()
    for i, data in pairs(logs) do
        local row = Instance.new("Frame", listScroll)
        row.Size = UDim2.new(1, -10, 0, 45)
        row.Position = UDim2.new(0, 5, 0, (i-1)*50)
        row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        local info = Instance.new("TextLabel", row)
        info.Size = UDim2.new(0.5, 0, 1, 0)
        info.Text = data.Name .. "\nOwner: " .. data.Owner
        info.TextColor3 = Color3.new(1, 1, 1)
        info.TextSize = 10
        info.BackgroundTransparency = 1

        local join = Instance.new("TextButton", row)
        join.Size = UDim2.new(0.2, 0, 0.8, 0)
        join.Position = UDim2.new(0.55, 0, 0.1, 0)
        join.Text = "JOIN"
        join.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        join.MouseButton1Click:Connect(function() 
            TeleportService:TeleportToPlaceInstance(game.PlaceId, data.JobId) 
        end)

        local force = Instance.new("TextButton", row)
        force.Size = UDim2.new(0.2, 0, 0.8, 0)
        force.Position = UDim2.new(0.78, 0, 0.1, 0)
        force.Text = "FORCE"
        force.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        force.MouseButton1Click:Connect(function()
            -- Force Join tries to join even if server was full last check
            TeleportService:TeleportToPlaceInstance(game.PlaceId, data.JobId)
        end)
    end
end

local function scanBases()
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Bases")
    if not plots then return nil end
    for _, plot in pairs(plots:GetChildren()) do
        local items = plot:FindFirstChild("Items") or plot:FindFirstChild("AnimalPodiums")
        if items then
            for _, item in pairs(items:GetChildren()) do
                local val = item:GetAttribute("Income") or item:GetAttribute("Value") or 0
                if val >= MIN_VALUE or item.Name:find("Ketupat") then
                    return {Name = item.Name, Val = val, Owner = tostring(plot:GetAttribute("Owner")), JobId = game.JobId}
                end
            end
        end
    end
end

-- [[ BUTTON CLICKS ]] --
clearBtn.MouseButton1Click:Connect(function()
    if isfile(SAVE_FILE) then delfile(SAVE_FILE) end
    updateUI()
end)

autoBtn.MouseButton1Click:Connect(function()
    AUTO_JOIN_ENABLED = not AUTO_JOIN_ENABLED
    autoBtn.Text = AUTO_JOIN_ENABLED and "AUTO JOIN: ON" or "AUTO JOIN: OFF"
    autoBtn.BackgroundColor3 = AUTO_JOIN_ENABLED and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

huntBtn.MouseButton1Click:Connect(function()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local servers = HttpService:JSONDecode(game:HttpGet(url))
    for _, s in pairs(servers.data) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
            break
        end
    end
end)

-- [[ MAIN LOOP ]] --
task.wait(3)
updateUI()
local found = scanBases()
if found then
    saveServer(found)
    updateUI()
    if AUTO_JOIN_ENABLED then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, found.JobId)
    end
end
