-- [[ WATER HUB CONFIG ]] --
local VERSION = "v1.4"
local ACCENT_COLOR = Color3.fromRGB(0, 170, 255) -- Water Blue
local SAVE_FILE = "WaterHub_Data.json"
local MIN_VALUE = 10000000 -- 10M

-- [[ SERVICES ]] --
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- [[ FILE SYSTEM ]] --
local function getLogs()
    if isfile(SAVE_FILE) then
        return HttpService:JSONDecode(readfile(SAVE_FILE))
    end
    return {AutoJoin = false, Servers = {}}
end

local function saveData(data)
    writefile(SAVE_FILE, HttpService:JSONEncode(data))
end

local currentData = getLogs()

-- [[ UI CONSTRUCTION ]] --
local sg = Instance.new("ScreenGui", LP.PlayerGui)
sg.Name = "WaterHub_UI"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 450, 0, 300)
main.Position = UDim2.new(0.5, -225, 0.4, -150)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0, 8)

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner", header)
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "WATER HUB | " .. VERSION
title.TextColor3 = ACCENT_COLOR
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

-- Server List Area
local list = Instance.new("ScrollingFrame", main)
list.Size = UDim2.new(0, 430, 0, 180)
list.Position = UDim2.new(0, 10, 0, 50)
list.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new(0, 0, 5, 0)
list.ScrollBarThickness = 2

local listCorner = Instance.new("UICorner", list)

-- Control Panel
local controls = Instance.new("Frame", main)
controls.Size = UDim2.new(1, 0, 0, 60)
controls.Position = UDim2.new(0, 0, 1, -65)
controls.BackgroundTransparency = 1

local function createBtn(name, pos, color)
    local btn = Instance.new("TextButton", controls)
    btn.Size = UDim2.new(0.3, -10, 0, 35)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local autoBtn = createBtn("AUTO JOIN: " .. (currentData.AutoJoin and "ON" or "OFF"), UDim2.new(0.025, 0, 0, 0), currentData.AutoJoin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
local clearBtn = createBtn("CLEAR LIST", UDim2.new(0.35, 0, 0, 0), Color3.fromRGB(40, 40, 40))
local huntBtn = createBtn("HUNT NEXT", UDim2.new(0.675, 0, 0, 0), ACCENT_COLOR)

-- [[ FUNCTIONS ]] --

local function updateUI()
    for _, v in pairs(list:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for i, s in pairs(currentData.Servers) do
        local row = Instance.new("Frame", list)
        row.Size = UDim2.new(1, -10, 0, 45)
        row.Position = UDim2.new(0, 5, 0, (i-1)*50)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Instance.new("UICorner", row)

        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Text = s.Name .. "\n" .. s.Owner
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham

        local join = Instance.new("TextButton", row)
        join.Size = UDim2.new(0.2, 0, 0.7, 0)
        join.Position = UDim2.new(0.55, 0, 0.15, 0)
        join.Text = "JOIN"
        join.BackgroundColor3 = ACCENT_COLOR
        join.Font = Enum.Font.GothamBold
        Instance.new("UICorner", join)

        local force = Instance.new("TextButton", row)
        force.Size = UDim2.new(0.2, 0, 0.7, 0)
        force.Position = UDim2.new(0.77, 0, 0.15, 0)
        force.Text = "FORCE"
        force.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        force.Font = Enum.Font.GothamBold
        Instance.new("UICorner", force)

        join.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.JobId) end)
        force.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.JobId) end)
    end
end

local function scan()
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Bases")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local items = plot:FindFirstChild("Items") or plot:FindFirstChild("AnimalPodiums")
        if items then
            for _, item in pairs(items:GetChildren()) do
                local val = item:GetAttribute("Income") or 0
                if val >= MIN_VALUE or item.Name:find("Ketupat") then
                    local entry = {Name = item.Name, Owner = tostring(plot:GetAttribute("Owner")), JobId = game.JobId}
                    table.insert(currentData.Servers, entry)
                    saveData(currentData)
                    return entry
                end
            end
        end
    end
end

-- [[ BUTTON LOGIC ]] --
autoBtn.MouseButton1Click:Connect(function()
    currentData.AutoJoin = not currentData.AutoJoin
    saveData(currentData)
    autoBtn.Text = "AUTO JOIN: " .. (currentData.AutoJoin and "ON" or "OFF")
    autoBtn.BackgroundColor3 = currentData.AutoJoin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

clearBtn.MouseButton1Click:Connect(function()
    currentData.Servers = {}
    saveData(currentData)
    updateUI()
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

-- [[ MAIN ]] --
task.wait(2)
updateUI()
local found = scan()
if found then
    updateUI()
else
    if currentData.AutoJoin then huntBtn.MouseButton1Click:Fire() end
end
