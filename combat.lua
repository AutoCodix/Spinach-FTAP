--[[
    Combat — Super Throw / auras / reach
    CRITICAL: Strength/ThrowMult ONLY stored in Config.
    performThrow runs ONLY on GrabParts release or explicit action.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local Combat = {
    ThrowConn = nil,
    AuraLast = 0,
}

local Config = nil
local TargetManager = nil
local SpinachRef = nil

local function hrp()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function performThrow(part, mode)
    if not part or not part.Parent or not Config then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local dir = cam.CFrame.LookVector
    if mode == "up" then dir = Vector3.new(0, 1, 0)
    elseif mode == "slam" then dir = Vector3.new(dir.X * 0.15, -1, dir.Z * 0.15)
    elseif mode == "void" then dir = Vector3.new(0, -1, 0)
    end
    local mass = 0.5
    local model = part.Parent
    if model:IsA("Model") and model ~= Workspace then
        for _, p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") then mass = mass + p:GetMass() end
        end
    else
        mass = part:GetMass()
    end
    if mass < 0.5 then mass = 0.5 end
    local mult = Config.ThrowMult
    if Config.SuperStrength then mult = Config.StrengthValue end
    local force = dir * (750 / mass) * mult + dir * 20
    if mode == "spin" then
        force = force + Vector3.new(math.random(-25, 25), 12, math.random(-25, 25))
    elseif mode == "slam" then
        force = Vector3.new(dir.X * 20, -100, dir.Z * 20)
    end
    if force.Magnitude > 300 then force = force.Unit * 300 end
    if model:IsA("Model") and model ~= Workspace then
        for _, p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") then p.AssemblyLinearVelocity = force end
        end
    else
        part.AssemblyLinearVelocity = force
    end
end

function Combat.FlingPlayer(plr, mode)
    if not TargetManager or not TargetManager.Valid(plr) then return end
    performThrow(plr.Character.HumanoidRootPart, mode or "forward")
end

function Combat.EnableSuperThrow()
    if Combat.ThrowConn then return end
    Combat.ThrowConn = Workspace.ChildAdded:Connect(function(obj)
        if obj.Name ~= "GrabParts" then return end
        task.defer(function()
            local gp = obj:FindFirstChild("GrabPart")
            if not gp then return end
            local weld = gp:FindFirstChild("WeldConstraint")
            if not weld or not weld.Part1 then return end
            local target = weld.Part1
            local c
            c = obj.AncestryChanged:Connect(function()
                if obj.Parent then return end
                if Config and Config.SuperThrow and target and target.Parent then
                    local mode = "forward"
                    if Config.FlingUp then mode = "up"
                    elseif Config.Slam then mode = "slam"
                    elseif Config.VoidFling then mode = "void"
                    elseif Config.SpinFling then mode = "spin" end
                    performThrow(target, mode)
                end
                if c then c:Disconnect() end
            end)
        end)
    end)
    if SpinachRef then table.insert(SpinachRef.Connections, Combat.ThrowConn) end
end

function Combat.DisableSuperThrow()
    if Combat.ThrowConn then
        Combat.ThrowConn:Disconnect()
        Combat.ThrowConn = nil
    end
end

local function forceReach()
    if not Config or not Config.GrabReach then return end
    local ge = ReplicatedStorage:FindFirstChild("GrabEvents")
    local ext = ge and ge:FindFirstChild("ExtendGrabLine")
    pcall(function() if ext then ext:FireServer(Config.MaxGrabReach) end end)
end

local function auraTick()
    if not Config then return end
    local any = Config.FlingAura or Config.RagdollAura or Config.SitAura
        or Config.SpinAura or Config.BringAura or Config.VoidAura
    if not any then return end
    if tick() - Combat.AuraLast < (Config.AuraCD or 0.4) then return end
    Combat.AuraLast = tick()
    local my = hrp()
    if not my then return end
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if n >= (Config.AuraMax or 3) then break end
        if not TargetManager or not TargetManager.Valid(p) then continue end
        local r = p.Character.HumanoidRootPart
        if (r.Position - my.Position).Magnitude > (Config.AuraRange or 25) then continue end
        n = n + 1
        if Config.FlingAura then Combat.FlingPlayer(p) end
        if Config.RagdollAura then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = true end
        end
        if Config.SitAura then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Sit = true end
        end
        if Config.SpinAura then r.AssemblyAngularVelocity = Vector3.new(0, 30, 0) end
        if Config.BringAura then r.CFrame = my.CFrame + my.CFrame.LookVector * 5 end
        if Config.VoidAura then r.AssemblyLinearVelocity = Vector3.new(0, -120, 0) end
    end
end

function Combat.Tick()
    forceReach()
    auraTick()
end

function Combat.Init(spinach)
    SpinachRef = spinach
    Config = spinach.Get("config.lua")
    TargetManager = spinach.Get("TargetManager.lua")
    if Config and Config.SuperThrow then
        Combat.EnableSuperThrow()
    end
    spinach.Connect(RunService.Heartbeat, function()
        Combat.Tick()
    end)
end

function Combat.Destroy()
    Combat.DisableSuperThrow()
end

return Combat
