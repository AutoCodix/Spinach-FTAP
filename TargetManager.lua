--[[ Centralized TargetManager — single shared target state ]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local TargetManager = {
    CurrentTarget = nil,
    Targets = {},
}

local Config = nil
local SpinachRef = nil

local function isFriend(plr)
    if not plr or not Config then return false end
    if not Config.FriendWL and not Config.AutoWLFriends then return false end
    local ok, res = pcall(function() return LP:IsFriendsWith(plr.UserId) end)
    return ok and res
end

function TargetManager.Valid(plr)
    if not plr or plr == LP then return false end
    if isFriend(plr) then return false end
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and r and h.Health > 0
end

function TargetManager.GetNearest(maxDist)
    maxDist = maxDist or (Config and Config.DistLimit) or 200
    local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not my then return nil end
    local best, bestD = nil, maxDist
    for _, p in ipairs(Players:GetPlayers()) do
        if TargetManager.Valid(p) then
            local r = p.Character.HumanoidRootPart
            local d = (r.Position - my.Position).Magnitude
            if d < bestD then bestD, best = d, p end
        end
    end
    return best
end

function TargetManager.SetTarget(player)
    if player and not TargetManager.Valid(player) then return end
    TargetManager.CurrentTarget = player
    if SpinachRef and SpinachRef.Notify and player then
        SpinachRef.Notify("TARGET", player.DisplayName, false)
    end
end

function TargetManager.ClearTarget()
    TargetManager.CurrentTarget = nil
end

function TargetManager.GetTarget()
    local t = TargetManager.CurrentTarget
    if t and TargetManager.Valid(t) then return t end
    if Config and Config.NearestTarget then
        local n = TargetManager.GetNearest()
        if n then
            TargetManager.CurrentTarget = n
            return n
        end
    end
    if t and not TargetManager.Valid(t) then
        TargetManager.CurrentTarget = nil
    end
    return TargetManager.CurrentTarget
end

function TargetManager.Update()
    if Config and Config.TargetLock then
        if TargetManager.CurrentTarget and TargetManager.Valid(TargetManager.CurrentTarget) then
            return
        end
    end
    if Config and Config.NearestTarget then
        local n = TargetManager.GetNearest()
        if n ~= TargetManager.CurrentTarget then
            TargetManager.SetTarget(n)
        end
    end
end

function TargetManager.Init(spinach)
    SpinachRef = spinach
    Config = spinach.Get("config.lua")
end

function TargetManager.Destroy()
    TargetManager.CurrentTarget = nil
end

return TargetManager
