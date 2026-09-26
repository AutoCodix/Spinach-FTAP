--[[ VisualManager — single RenderStepped for ESP; cleanup-aware ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local VisualManager = {
    ESP = {},
    Conn = nil,
}

local Config = nil
local TargetManager = nil

function VisualManager.ClearESP()
    for k, v in pairs(VisualManager.ESP) do
        if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
        VisualManager.ESP[k] = nil
    end
end

local function updateESP()
    if not Config then return end
    if not (Config.PlayerESP or Config.DistESP or Config.TargetESP) then return end
    local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not my then return end
    local maxD = Config.ESPMaxDist or 400
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local root = p.Character:FindFirstChild("HumanoidRootPart")
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if not root or not h then continue end
        local dist = (root.Position - my.Position).Magnitude
        local key = "esp_" .. p.UserId
        if dist > maxD then
            if VisualManager.ESP[key] then
                VisualManager.ESP[key]:Destroy()
                VisualManager.ESP[key] = nil
            end
            continue
        end
        local bb = VisualManager.ESP[key]
        if not bb or not bb.Parent then
            bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 110, 0, 28)
            bb.StudsOffset = Vector3.new(0, 2.6, 0)
            bb.AlwaysOnTop = true
            bb.Parent = CoreGui
            local lab = Instance.new("TextLabel")
            lab.Name = "L"
            lab.Size = UDim2.new(1, 0, 1, 0)
            lab.BackgroundTransparency = 1
            lab.Font = Enum.Font.GothamBold
            lab.TextSize = 12
            lab.TextStrokeTransparency = 0.5
            lab.Parent = bb
            VisualManager.ESP[key] = bb
        end
        bb.Adornee = root
        local lab = bb:FindFirstChild("L")
        if not lab then continue end
        local col = (Config.Accent) or Color3.fromRGB(0, 200, 130)
        if TargetManager and TargetManager.GetTarget and TargetManager.GetTarget() == p then
            col = Color3.fromRGB(255, 70, 70)
        end
        if Config.Rainbow then
            col = Color3.fromHSV((tick() % 5) / 5, 1, 1)
        end
        lab.TextColor3 = col
        local txt = p.DisplayName
        if Config.DistESP then txt = txt .. string.format(" %.0f", dist) end
        if Config.HealthESP then txt = txt .. string.format(" %.0f", h.Health) end
        lab.Text = txt
    end
end

function VisualManager.Init(spinach)
    Config = spinach.Get("config.lua")
    TargetManager = spinach.Get("TargetManager.lua")
    if VisualManager.Conn then return end
    VisualManager.Conn = spinach.Connect(RunService.RenderStepped, function()
        updateESP()
    end)
end

function VisualManager.Destroy()
    if VisualManager.Conn then
        pcall(function() VisualManager.Conn:Disconnect() end)
        VisualManager.Conn = nil
    end
    VisualManager.ClearESP()
end

return VisualManager
