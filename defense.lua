--[[
    Defense — Anti Grab, Anti Gucci (interval+cache), Anti Void, etc.
    Anti Gucci: NO full Workspace scan every frame.
]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LP=Players.LocalPlayer
local Defense={BlobCache={},BlobCacheTime=0,AGState="idle",AGChecks=0,AGThreats=0,AGLast=0}
local Config=nil
local SpinachRef=nil
local function char() return LP.Character end
local function hum() local c=char() return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c=char() return c and c:FindFirstChild("HumanoidRootPart") end

local function antiGrabTick()
 if not Config or not (Config.AntiGrab or Config.AntiGrabGucci) then return end
 local me=char() if not me then return end
 for _,v in ipairs(Workspace:GetChildren()) do
  if v.Name=="GrabParts" then
   local gp=v:FindFirstChild("GrabPart");local w=gp and gp:FindFirstChild("WeldConstraint")
   if w and w.Part1 and w.Part1:IsDescendantOf(me) then
    local ge=ReplicatedStorage:FindFirstChild("GrabEvents");local eg=ge and ge:FindFirstChild("EndGrabEarly")
    pcall(function() if eg then eg:FireServer() end end);pcall(function() if w then w:Destroy() end;if gp then gp:Destroy() end end)
    local h=hum();if h then local rag=h:FindFirstChild("Ragdolled");if rag and rag:IsA("BoolValue") then rag.Value=false end;h.PlatformStand=false;pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    if SpinachRef and SpinachRef.Notify then SpinachRef.Notify("Anti Grab","triggered",false) end
   end
  end
 end
end

local function refreshBlobs()
 local now=tick();if now-Defense.BlobCacheTime<0.5 then return end;Defense.BlobCacheTime=now
 local list={}
 for _,m in ipairs(Workspace:GetDescendants()) do
  local n=m.Name
  if n=="CreatureBlobman" or (type(n)=="string" and (n:find("Blobman") or n:find("Gucci"))) then
   if m:IsA("Model") or m:FindFirstChildWhichIsA("VehicleSeat",true) then table.insert(list,m) end
  end
 end
 Defense.BlobCache=list
end

local function antiGucciTick()
 if not Config or not Config.AntiGucci then Defense.AGState="idle";Defense.AGThreats=0;return end
 local now=tick();local interval=Config.AntiGucciInterval or 0.15;if now-Defense.AGLast<interval then return end
 Defense.AGLast=now;Defense.AGChecks+=1
 local me=char();if not me then Defense.AGState="idle";return end
 refreshBlobs()
 local threats=0
 for _,model in ipairs(Defense.BlobCache) do
  if not model.Parent then continue end
  local seat=model:FindFirstChildWhichIsA("VehicleSeat",true) or model:FindFirstChildWhichIsA("Seat",true)
  if seat then local w=seat:FindFirstChild("SeatWeld");if w and w.Part1 and w.Part1:IsDescendantOf(me) then threats+=1;pcall(function() w:Destroy() end);if SpinachRef and SpinachRef.Notify then SpinachRef.Notify("Anti Gucci","seat broken",false) end end end
  for _,side in ipairs({"LeftDetector","RightDetector"}) do
   local det=model:FindFirstChild(side,true)
   if det then local w=det:FindFirstChild(side:gsub("Detector","Weld")) or det:FindFirstChildWhichIsA("Weld") or det:FindFirstChildWhichIsA("WeldConstraint");if w and w.Part1 and w.Part1:IsDescendantOf(me) then threats+=1;pcall(function() w:Destroy() end) end end
  end
  if Config.AntiGucciMode=="Aggressive" then
   for _,d in ipairs(model:GetDescendants()) do if (d:IsA("Weld") or d:IsA("WeldConstraint")) and d.Part1 and d.Part1:IsDescendantOf(me) then threats+=1;pcall(function() d:Destroy() end) end end
  end
 end
 Defense.AGThreats=threats;Defense.AGState=threats>0 and "active" or "idle"
end

local function antiRagSit()
 if not Config then return end
 local h=hum() if not h then return end
 if Config.AntiRagdoll or Config.InstantGetUp then
  local rag=h:FindFirstChild("Ragdolled");if rag and rag:IsA("BoolValue") and rag.Value then rag.Value=false;h.PlatformStand=false;pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
  if h.PlatformStand then h.PlatformStand=false end
 end
 if Config.AntiSit and h.Sit then h.Sit=false end
end
local function antiVoid()
 if not Config or not (Config.AntiVoid or Config.DisableVoid) then return end
 local root=hrp() if not root then return end
 if root.Position.Y<-40 then local sp=Workspace:FindFirstChildWhichIsA("SpawnLocation");if sp then root.CFrame=sp.CFrame+Vector3.new(0,5,0) else root.CFrame=CFrame.new(0,60,0) end;root.AssemblyLinearVelocity=Vector3.zero end
end
local function antiFling()
 if not Config or not Config.AntiFling then return end
 local root=hrp();if root and root.AssemblyLinearVelocity.Magnitude>220 then root.AssemblyLinearVelocity=root.AssemblyLinearVelocity.Unit*35 end
end
function Defense.Tick() antiGrabTick();antiGucciTick();antiRagSit();antiVoid();antiFling() end
function Defense.GetAGDebug() return Defense.AGState,Defense.AGChecks,Defense.AGThreats end
function Defense.Init(spinach)
 SpinachRef=spinach;Config=spinach.Get("config.lua")
 if Config and Config.AutoAntiLag then Config.AntiLag=true end
 spinach.Connect(RunService.Heartbeat,function() Defense.Tick() end)
end
function Defense.Destroy() Defense.BlobCache={} end
return Defense
