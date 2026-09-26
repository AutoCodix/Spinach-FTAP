--[[ Pengu defense — only wired modules live here ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local LP=Players.LocalPlayer
local Defense={
 Connections={},
 BlobCache={},
 BlobCacheTime=0,
 AGLast=0,
 AGChecks=0,
 AGThreats=0,
 AGState="idle",
 PaintBackup={},
 PaintWatch=nil,
 StickyBackup={},
 ExplosionWatch=nil,
}

local Config=nil
local Client=nil

local function char() return LP.Character end
local function hum() local c=char();return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c=char();return c and c:FindFirstChild("HumanoidRootPart") end
local function own(c)table.insert(Defense.Connections,c);return c end

local function setRagdollOff()
 local h=hum()
 if not h then return end
 local rag=h:FindFirstChild("Ragdolled")
 if rag and rag:IsA("BoolValue") then rag.Value=false end
 h.PlatformStand=false
 pcall(function()h:ChangeState(Enum.HumanoidStateType.GettingUp)end)
end

local function antiGrabTick()
 if not Config or not Config.AntiGrab then return end
 local me=char();if not me then return end
 for _,v in ipairs(Workspace:GetChildren()) do
  if v.Name=="GrabParts" then
   local gp=v:FindFirstChild("GrabPart")
   local w=gp and gp:FindFirstChild("WeldConstraint")
   if w and w.Part1 and w.Part1:IsDescendantOf(me) then
    local ge=ReplicatedStorage:FindFirstChild("GrabEvents")
    local eg=ge and ge:FindFirstChild("EndGrabEarly")
    pcall(function()if eg then eg:FireServer()end end)
    pcall(function()if w then w:Destroy()end;if gp then gp:Destroy()end end)
    setRagdollOff()
   end
  end
 end
end

local function refreshBlobs()
 local now=tick()
 if now-Defense.BlobCacheTime<0.5 then return end
 Defense.BlobCacheTime=now
 table.clear(Defense.BlobCache)
 for _,m in ipairs(Workspace:GetDescendants()) do
  local n=string.lower(m.Name or "")
  if n:find("blobman") or n:find("gucci") then
   if m:IsA("Model") then table.insert(Defense.BlobCache,m) end
  end
 end
end

local function antiGucciTick()
 if not Config or not Config.AntiGucci then Defense.AGState="idle";Defense.AGThreats=0;return end
 local now=tick()
 if now-Defense.AGLast<(Config.AntiGucciInterval or .15) then return end
 Defense.AGLast=now;Defense.AGChecks+=1
 local me=char();if not me then return end
 refreshBlobs()
 local threats=0
 for _,model in ipairs(Defense.BlobCache) do
  if not model.Parent then continue end
  for _,d in ipairs(model:GetDescendants()) do
   if (d:IsA("Weld") or d:IsA("WeldConstraint")) and d.Part1 and d.Part1:IsDescendantOf(me) then
    threats+=1
    pcall(function()d:Destroy()end)
   end
  end
 end
 Defense.AGThreats=threats
 Defense.AGState=threats>0 and "active" or "idle"
end

local function antiBlobmanTick()
 if not Config or not Config.AntiBlobman then return end
 local h=hum()
 if not h or not h.SeatPart then return end
 local seat=h.SeatPart
 local p=seat.Parent
 if p and string.lower(p.Name):find("blobman") then
  pcall(function()
   local weld=seat:FindFirstChild("SeatWeld")
   if weld then weld:Destroy() end
   h.Sit=false
   h.PlatformStand=false
   h:ChangeState(Enum.HumanoidStateType.GettingUp)
  end)
 end
end

local function antiRagdollSitTick()
 if not Config then return end
 local h=hum();if not h then return end
 if Config.AntiRagdoll or Config.InstantGetUp or Config.AntiSnowball then
  local rag=h:FindFirstChild("Ragdolled")
  if (rag and rag:IsA("BoolValue") and rag.Value) or h.PlatformStand then setRagdollOff() end
 end
 if Config.AntiSit and h.Sit then h.Sit=false end
end

local function antiSnowballTick()
 if not Config or not Config.AntiSnowball then return end
 local r=root();if not r then return end
 for _,o in ipairs(Workspace:GetChildren()) do
  local n=string.lower(o.Name or "")
  if n:find("snowball") then
   local p=o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart",true)
   if p and (p.Position-r.Position).Magnitude<12 then
    setRagdollOff()
    if r.AssemblyLinearVelocity.Magnitude>35 then r.AssemblyLinearVelocity=Vector3.zero end
    break
   end
  end
 end
end

local function antiVoidTick()
 if not Config or not (Config.AntiVoid or Config.DisableVoid) then return end
 local r=root();if not r then return end
 if r.Position.Y<-490 then
  r.AssemblyLinearVelocity=Vector3.zero
  r.CFrame=CFrame.new(r.Position.X,-470,r.Position.Z)
 end
end

local function antiFlingTick()
 if not Config or not Config.AntiFling then return end
 local r=root()
 if r and r.AssemblyLinearVelocity.Magnitude>170 then
  r.AssemblyLinearVelocity=Vector3.zero
  r.AssemblyAngularVelocity=Vector3.zero
 end
end

local function antiBurnTick()
 if not Config or not Config.AntiBurn then return end
 local c=char();if not c then return end
 for _,d in ipairs(c:GetDescendants()) do
  if d.Name=="FirePlayerPart" and d:IsA("BasePart") then
   d.CanTouch=false
   d.CanQuery=false
   d.Size=Vector3.zero
  elseif d:IsA("Fire") then
   d.Enabled=false
  end
 end
end

local function applySticky(state)
 local c=char();if not c then return end
 if state then
  for _,p in ipairs(c:GetDescendants()) do
   if p:IsA("BasePart") then
    if Defense.StickyBackup[p]==nil then Defense.StickyBackup[p]={p.CanTouch,p.CanQuery} end
    p.CanTouch=false;p.CanQuery=false
   end
  end
 else
  for p,v in pairs(Defense.StickyBackup) do
   if p and p.Parent then pcall(function()p.CanTouch=v[1];p.CanQuery=v[2]end)end
  end
  table.clear(Defense.StickyBackup)
 end
end

local function removePaintPart(obj)
 if not obj:IsA("BasePart") or obj.Name~="PaintPlayerPart" then return end
 local ok,clone=pcall(function()return obj:Clone()end)
 if ok and clone then Defense.PaintBackup[obj]={clone=clone,parent=obj.Parent} end
 pcall(function()obj:Destroy()end)
end

local function setAntiPaint(state)
 if state then
  for _,o in ipairs(Workspace:GetDescendants()) do removePaintPart(o) end
  if not Defense.PaintWatch then
   Defense.PaintWatch=Workspace.DescendantAdded:Connect(function(o)
    if Config and Config.AntiPaint then task.defer(function()if o.Parent then removePaintPart(o)end end)end
   end)
  end
 else
  if Defense.PaintWatch then Defense.PaintWatch:Disconnect();Defense.PaintWatch=nil end
  for _,data in pairs(Defense.PaintBackup) do
   if data.clone and data.parent and data.parent.Parent then pcall(function()data.clone.Parent=data.parent end)end
  end
  table.clear(Defense.PaintBackup)
 end
end

local function neutralizeExplosion(obj)
 if not obj:IsA("Explosion") then return end
 obj.BlastPressure=0
 obj.BlastRadius=0
 obj.DestroyJointRadiusPercent=0
end

local function setAntiExplosion(state)
 if state then
  for _,o in ipairs(Workspace:GetDescendants()) do neutralizeExplosion(o) end
  if not Defense.ExplosionWatch then
   Defense.ExplosionWatch=Workspace.DescendantAdded:Connect(function(o)
    if Config and Config.AntiExplosion then neutralizeExplosion(o) end
   end)
  end
 else
  if Defense.ExplosionWatch then Defense.ExplosionWatch:Disconnect();Defense.ExplosionWatch=nil end
 end
end

function Defense.OnSettingChanged(key,value)
 if key=="AntiSticky" then applySticky(value)
 elseif key=="AntiPaint" then setAntiPaint(value)
 elseif key=="AntiExplosion" then setAntiExplosion(value)
 end
end

function Defense.GetAGDebug()
 return Defense.AGState,Defense.AGChecks,Defense.AGThreats
end

function Defense.Tick()
 antiGrabTick()
 antiGucciTick()
 antiBlobmanTick()
 antiRagdollSitTick()
 antiSnowballTick()
 antiVoidTick()
 antiFlingTick()
 antiBurnTick()
 if Config and Config.AntiSticky then applySticky(true) end
end

function Defense.Init(client)
 Client=client
 Config=client.Get("config.lua")
 own(RunService.Heartbeat:Connect(Defense.Tick))
 own(LP.CharacterAdded:Connect(function()
  task.wait(.25)
  if Config.AntiSticky then applySticky(true) end
 end))
 if Config.AntiSticky then applySticky(true) end
 if Config.AntiPaint then setAntiPaint(true) end
 if Config.AntiExplosion then setAntiExplosion(true) end
end

function Defense.Destroy()
 applySticky(false)
 setAntiPaint(false)
 setAntiExplosion(false)
 for _,c in ipairs(Defense.Connections) do pcall(function()c:Disconnect()end)end
 Defense.Connections={}
 Defense.BlobCache={}
end

return Defense
