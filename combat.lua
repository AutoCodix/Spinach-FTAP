--[[
    Combat — Super Strength (RMB throw only) / auras / reach / Noclip Barrier
    Super Strength NEVER fires on normal LMB drop / GrabParts destroy.
    Only when module enabled + actively holding + MouseButton2.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local Combat = {
    GrabTrackConn = nil,
    InputConn = nil,
    HeldPart = nil,       -- BasePart currently welded via GrabParts
    HeldModel = nil,      -- Model if any
    BarrierSaved = {},    -- [BasePart] = original CanCollide
    AuraLast = 0,
}

local Config = nil
local TargetManager = nil
local SpinachRef = nil

local function hrp()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function isLocalCharacterPart(part)
    local c = LP.Character
    return c and part and part:IsDescendantOf(c)
end

--- Valid throw target: player character part OR movable unanchored assembly. Never map/anchored/world/local body.
local function isValidThrowTarget(part)
    if not part or not part:IsA("BasePart") or not part.Parent then return false end
    if isLocalCharacterPart(part) then return false end
    if part:IsA("Terrain") then return false end
    -- player character (other)
    local model = part:FindFirstAncestorOfClass("Model")
    if model then
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if hum and root and model ~= LP.Character then
            return true
        end
    end
    -- movable object: must be unanchored (or assembly has unanchored root)
    if part.Anchored then return false end
    -- reject if parent is Workspace directly as static name heuristics
    local p = part.Parent
    if p == Workspace then
        return not part.Anchored
    end
    if model and model.Parent == Workspace then
        -- only apply to unanchored parts in the model, not whole map models
        return not part.Anchored
    end
    return not part.Anchored
end

local function collectAssemblyParts(part)
    local parts = {}
    if not part then return parts end
    local model = part:FindFirstAncestorOfClass("Model")
    if model and model ~= Workspace and model:FindFirstChildOfClass("Humanoid") then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then table.insert(parts, d) end
        end
        return parts
    end
    -- single part or small assembly: only unanchored BaseParts under same parent (not entire map)
    local parent = part.Parent
    if parent and parent:IsA("Model") and parent ~= Workspace then
        for _, d in ipairs(parent:GetChildren()) do
            if d:IsA("BasePart") and not d.Anchored then
                table.insert(parts, d)
            end
        end
        if #parts == 0 and not part.Anchored then table.insert(parts, part) end
        return parts
    end
    if not part.Anchored then table.insert(parts, part) end
    return parts
end

local function applyForceToValid(part, force)
    if not isValidThrowTarget(part) then return end
    local parts = collectAssemblyParts(part)
    for _, p in ipairs(parts) do
        if p.Parent and not p.Anchored and not isLocalCharacterPart(p) then
            p.AssemblyLinearVelocity = force
        end
    end
end

local function computeForce(part, mode)
    local cam = Workspace.CurrentCamera
    if not cam then return Vector3.zero end
    local dir = cam.CFrame.LookVector
    if mode == "up" then dir = Vector3.new(0, 1, 0)
    elseif mode == "slam" then dir = Vector3.new(dir.X * 0.15, -1, dir.Z * 0.15)
    elseif mode == "void" then dir = Vector3.new(0, -1, 0)
    end
    local mass = 0.5
    for _, p in ipairs(collectAssemblyParts(part)) do
        mass = mass + p:GetMass()
    end
    if mass < 0.5 then mass = 0.5 end
    local mult = Config.StrengthValue or Config.ThrowMult or 3.5
    local force = dir * (750 / mass) * mult + dir * 20
    if mode == "spin" then
        force = force + Vector3.new(math.random(-25, 25), 12, math.random(-25, 25))
    elseif mode == "slam" then
        force = Vector3.new(dir.X * 20, -100, dir.Z * 20)
    end
    if force.Magnitude > 300 then force = force.Unit * 300 end
    return force
end

--- Super Strength throw: ONLY called from RMB while holding
function Combat.PerformSuperStrengthThrow()
    if not Config or not Config.SuperStrength then return end
    local part = Combat.HeldPart
    if not part or not part.Parent then return end
    if not isValidThrowTarget(part) then return end
    local mode = "forward"
    if Config.FlingUp then mode = "up"
    elseif Config.Slam then mode = "slam"
    elseif Config.VoidFling then mode = "void"
    elseif Config.SpinFling then mode = "spin" end
    local force = computeForce(part, mode)
    applyForceToValid(part, force)
end

function Combat.FlingPlayer(plr, mode)
    if not TargetManager or not TargetManager.Valid(plr) then return end
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local force = computeForce(root, mode or "forward")
        applyForceToValid(root, force)
    end
end

local function clearHeld()
    Combat.restoreBarrier()
    Combat.HeldPart = nil
    Combat.HeldModel = nil
end

local function setHeldFromGrabParts(obj)
    local gp = obj:FindFirstChild("GrabPart")
    if not gp then return end
    local weld = gp:FindFirstChild("WeldConstraint")
    if not weld or not weld.Part1 then return end
    local target = weld.Part1
    if isLocalCharacterPart(target) then return end
    Combat.HeldPart = target
    Combat.HeldModel = target:FindFirstAncestorOfClass("Model")
    if Config and Config.NoclipBarrier then
        Combat.applyBarrier(target)
    end
end

function Combat.applyBarrier(part)
    Combat.restoreBarrier()
    if not part then return end
    for _, p in ipairs(collectAssemblyParts(part)) do
        if p:IsA("BasePart") and not isLocalCharacterPart(p) then
            Combat.BarrierSaved[p] = p.CanCollide
            p.CanCollide = false
        end
    end
end

function Combat.restoreBarrier()
    for p, orig in pairs(Combat.BarrierSaved) do
        if typeof(p) == "Instance" and p.Parent then
            pcall(function() p.CanCollide = orig end)
        end
    end
    Combat.BarrierSaved = {}
end

function Combat.EnableSuperStrength()
    -- tracking only; throw is on RMB
    if Combat.GrabTrackConn then return end
    Combat.GrabTrackConn = Workspace.ChildAdded:Connect(function(obj)
        if obj.Name ~= "GrabParts" then return end
        task.defer(function()
            setHeldFromGrabParts(obj)
            local c
            c = obj.AncestryChanged:Connect(function()
                if obj.Parent then return end
                -- normal drop/release: do NOT throw
                if Combat.HeldPart then
                    local still = false
                    for _, g in ipairs(Workspace:GetChildren()) do
                        if g.Name == "GrabParts" and g ~= obj then
                            local gp = g:FindFirstChild("GrabPart")
                            local w = gp and gp:FindFirstChild("WeldConstraint")
                            if w and w.Part1 == Combat.HeldPart then still = true break end
                        end
                    end
                    if not still then clearHeld() end
                end
                if c then c:Disconnect() end
            end)
        end)
    end)
    -- also scan existing
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "GrabParts" then setHeldFromGrabParts(obj) end
    end
    if not Combat.InputConn then
        Combat.InputConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if Config and Config.SuperStrength and Combat.HeldPart then
                    Combat.PerformSuperStrengthThrow()
                end
            end
        end)
        if SpinachRef then table.insert(SpinachRef.Connections, Combat.InputConn) end
    end
    if SpinachRef then table.insert(SpinachRef.Connections, Combat.GrabTrackConn) end
end

function Combat.DisableSuperStrength()
    if Combat.GrabTrackConn then
        Combat.GrabTrackConn:Disconnect()
        Combat.GrabTrackConn = nil
    end
    -- keep InputConn if we want barrier etc.; disconnect throw path by flag only
    clearHeld()
end

-- aliases for older UI hooks
function Combat.EnableSuperThrow() Combat.EnableSuperStrength() end
function Combat.DisableSuperThrow() Combat.DisableSuperStrength() end

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

local function barrierTick()
    if not Config then return end
    if Config.NoclipBarrier and Combat.HeldPart and Combat.HeldPart.Parent then
        if next(Combat.BarrierSaved) == nil then
            Combat.applyBarrier(Combat.HeldPart)
        end
    elseif next(Combat.BarrierSaved) ~= nil and not Config.NoclipBarrier then
        Combat.restoreBarrier()
    end
end

function Combat.Tick()
    forceReach()
    auraTick()
    barrierTick()
end

function Combat.Init(spinach)
    SpinachRef = spinach
    Config = spinach.Get("config.lua")
    TargetManager = spinach.Get("TargetManager.lua")
    -- always track grabs for barrier + optional super strength
    Combat.EnableSuperStrength()
    if Config and not Config.SuperStrength then
        -- tracking stays; throw gated by flag
    end
    spinach.Connect(RunService.Heartbeat, function()
        Combat.Tick()
    end)
end

function Combat.Destroy()
    Combat.DisableSuperStrength()
    if Combat.InputConn then
        Combat.InputConn:Disconnect()
        Combat.InputConn = nil
    end
    Combat.restoreBarrier()
end

return Combat
