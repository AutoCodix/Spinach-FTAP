local TargetManager = {}

TargetManager.CurrentTarget = nil
TargetManager.Targets = {}

function TargetManager.SetTarget(player)
    TargetManager.CurrentTarget = player
end

function TargetManager.ClearTarget()
    TargetManager.CurrentTarget = nil
end

function TargetManager.GetTarget()
    return TargetManager.CurrentTarget
end

return TargetManager
