--[[ Pengu Combat — FTAP grab tracking, RMB-only Super Strength, held-object barrier noclip ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LP=Players.LocalPlayer

local Combat={
 Connections={},
 GrabModels={},
 HeldPart=nil,
 HeldGrab=nil,
 PendingThrow=nil,
 BarrierSaved={},
 AuraLast=0,
}

local Config=nil
local TargetManager=nil
local Client=nil

local function own(c)table.insert(Combat.Connections,c);return c end
local function root()return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")end

local function isMine(part)
 return LP.Character and part and part:IsDescendantOf(LP.Character)
end

local function playerCharacterFrom(part)
 local m=part and part:FindFirstAncestorOfClass("Model")
 if m and Players:GetPlayerFromCharacter(m) then return m end
 return nil
end

local function movable(part)
 if not part or not part:IsA("BasePart") or not part.Parent or isMine(part) then return false end
 local pc=playerCharacterFrom(part)
 if pc then return true end
 local ar=part.AssemblyRootPart or part
 return ar and not ar.Anchored
end

local function partsFor(part)
 local out={}
 if not part then return out end
 local pc=playerCharacterFrom(part)
 if pc then
  for _,d in ipairs(pc:GetDescendants()) do if d:IsA("BasePart") then table.insert(out,d) end end
  return out
 end
 local model=part:FindFirstAncestorOfClass("Model")
 if model and model~=Workspace then
  for _,d in ipairs(model:GetDescendants()) do
   if d:IsA("BasePart") and not d.Anchored then table.insert(out,d) end
  end
  if #out>0 then return out end
 end
 if not part.Anchored then table.insert(out,part) end
 return out
end

local function mode()
 if Config.FlingUp then return "up" end
 if Config.Slam then return "slam" end
 if Config.VoidFling then return "void" end
 if Config.SpinFling then return "spin" end
 return "forward"
end

local function computeForce(part,throwMode)
 local cam=Workspace.CurrentCamera
 if not cam then return Vector3.zero end
 local dir=cam.CFrame.LookVector
 if throwMode=="up" then dir=Vector3.yAxis
 elseif throwMode=="void" then dir=-Vector3.yAxis
 elseif throwMode=="slam" then dir=Vector3.new(dir.X*.2,-1,dir.Z*.2).Unit end

 local mass=0
 for _,p in ipairs(partsFor(part)) do mass+=math.max(p:GetMass(),.05) end
 mass=math.max(mass,.5)
 local strength=tonumber(Config.StrengthValue) or 3.5
 local speed=math.clamp(70+(strength*38)+(120/math.sqrt(mass)),90,420)
 local force=dir*speed
 if throwMode=="spin" then force+=Vector3.new(math.random(-20,20),18,math.random(-20,20)) end
 return force
end

local function applyThrow(part,throwMode)
 if not Config.SuperStrength or not movable(part) then return end
 local force=computeForce(part,throwMode)
 for _,p in ipairs(partsFor(part)) do
  if p.Parent and not p.Anchored and not isMine(p) then
   p.AssemblyLinearVelocity=force
   if throwMode=="spin" then p.AssemblyAngularVelocity=Vector3.new(0,35,0) end
  end
 end
end

local function restoreBarrier()
 for p,v in pairs(Combat.BarrierSaved) do
  if p and p.Parent then pcall(function()p.CanCollide=v end)end
 end
 table.clear(Combat.BarrierSaved)
end

local function applyBarrier()
 if not Config.NoclipBarrier or not Combat.HeldPart or not movable(Combat.HeldPart) then
  restoreBarrier()
  return
 end
 for _,p in ipairs(partsFor(Combat.HeldPart)) do
  if Combat.BarrierSaved[p]==nil then Combat.BarrierSaved[p]=p.CanCollide end
  p.CanCollide=false
 end
end

local function grabTarget(model)
 local gp=model:FindFirstChild("GrabPart") or model:WaitForChild("GrabPart",.5)
 local weld=gp and (gp:FindFirstChild("WeldConstraint") or gp:FindFirstChildWhichIsA("WeldConstraint"))
 return weld and weld.Part1 or nil
end

local function registerGrab(model)
 if model.Name~="GrabParts" or Combat.GrabModels[model] then return end
 local target=grabTarget(model)
 if not target or isMine(target) then return end
 Combat.GrabModels[model]=target
 Combat.HeldGrab=model
 Combat.HeldPart=target
 applyBarrier()

 local c
 c=model.AncestryChanged:Connect(function()
  if model.Parent then return end
  Combat.GrabModels[model]=nil

  local wasTarget=Combat.HeldPart
  if Combat.HeldGrab==model then
   Combat.HeldGrab=nil
   Combat.HeldPart=nil
   restoreBarrier()
  end

  if Config and Config.SuperStrength and wasTarget and wasTarget.Parent then
   local throwMode=mode()
   task.defer(function()
    if wasTarget and wasTarget.Parent then applyThrow(wasTarget,throwMode) end
   end)
  end
  Combat.PendingThrow=nil
  if c then c:Disconnect() end
 end)
 own(c)
end

local function rmb(input,gpe)
 -- Old behavior restored: Super Strength triggers on normal grab release/drop.
 -- RMB is not required.
end

function Combat.EnableSuperStrength() Config.SuperStrength=true end
function Combat.DisableSuperStrength() Config.SuperStrength=false;Combat.PendingThrow=nil end
function Combat.EnableSuperThrow() Combat.EnableSuperStrength() end
function Combat.DisableSuperThrow() Combat.DisableSuperStrength() end

function Combat.FlingPlayer(plr,throwMode)
 if not TargetManager or not TargetManager.Valid(plr) then return end
 local r=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 if r then
  local old=Config.SuperStrength
  Config.SuperStrength=true
  applyThrow(r,throwMode or "forward")
  Config.SuperStrength=old
 end
end

local function reachTick()
 if not Config.GrabReach then return end
 local ge=ReplicatedStorage:FindFirstChild("GrabEvents")
 local ext=ge and ge:FindFirstChild("ExtendGrabLine")
 if ext then pcall(function()ext:FireServer(Config.MaxGrabReach)end)end
end

local function auraTick()
 if not (Config.FlingAura or Config.SpinAura or Config.VoidAura) then return end
 if tick()-Combat.AuraLast<(Config.AuraCD or .4) then return end
 Combat.AuraLast=tick()
 local me=root();if not me then return end
 local count=0
 for _,p in ipairs(Players:GetPlayers()) do
  if count>=(Config.AuraMax or 3) then break end
  if TargetManager and TargetManager.Valid(p) then
   local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if r and (r.Position-me.Position).Magnitude<=(Config.AuraRange or 25) then
    count+=1
    if Config.FlingAura then Combat.FlingPlayer(p,"forward")
    elseif Config.SpinAura then Combat.FlingPlayer(p,"spin")
    elseif Config.VoidAura then Combat.FlingPlayer(p,"void") end
   end
  end
 end
end

function Combat.Init(client)
 Client=client;Config=client.Get("config.lua");TargetManager=client.Get("TargetManager.lua")
 own(Workspace.ChildAdded:Connect(registerGrab))
 own(RunService.Heartbeat:Connect(function()
  applyBarrier()
  reachTick()
  auraTick()
 end))
 for _,o in ipairs(Workspace:GetChildren()) do if o.Name=="GrabParts" then task.defer(registerGrab,o) end end
end

function Combat.Destroy()
 restoreBarrier()
 Combat.PendingThrow=nil
 Combat.HeldPart=nil
 Combat.HeldGrab=nil
 table.clear(Combat.GrabModels)
 for _,c in ipairs(Combat.Connections) do pcall(function()c:Disconnect()end)end
 Combat.Connections={}
end

return Combat
