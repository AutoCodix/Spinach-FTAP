--[[ Pengu VisualManager — player ESP + PCLD + blackhole/kick + grabbed-object visuals ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CoreGui=game:GetService("CoreGui")
local Workspace=game:GetService("Workspace")

local LP=Players.LocalPlayer
local VisualManager={
 PlayerESP={},
 PCLD={},
 Blackholes={},
 Grabbed=nil,
 Trace=nil,
 TraceAttachments={},
 Connections={},
}

local Config=nil
local TargetManager=nil
local Client=nil
local function own(c)table.insert(VisualManager.Connections,c);return c end

local PCLD_NAMES={partesp=true,playercharacterlocationdetector=true}
local BLACKHOLE_NAMES={
 blackholekick=true,
 ["blackholekicktweens(old)"]=true,
 blackholekicktweens=true,
 jhole=true,
 blackhole=true,
 black_hole=true,
 voidhole=true,
 singularity=true,
}

local function accent()
 if Config and Config.Rainbow then return Color3.fromHSV((tick()%5)/5,1,1) end
 return (Config and Config.Accent) or Color3.fromRGB(119,0,255)
end

local function clearMap(t)
 for k,v in pairs(t) do
  if typeof(v)=="Instance" then pcall(function()v:Destroy()end)
  elseif type(v)=="table" then
   for _,x in pairs(v) do if typeof(x)=="Instance" then pcall(function()x:Destroy()end)end end
  end
  t[k]=nil
 end
end

local function ensurePlayerESP(plr)
 local key=plr.UserId
 local bb=VisualManager.PlayerESP[key]
 if bb and bb.Parent then return bb end
 bb=Instance.new("BillboardGui")
 bb.Name="PenguESP_"..key
 bb.Size=UDim2.new(0,135,0,30)
 bb.StudsOffset=Vector3.new(0,2.7,0)
 bb.AlwaysOnTop=true
 bb.Parent=CoreGui
 local l=Instance.new("TextLabel")
 l.Name="L";l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1
 l.Font=Enum.Font.GothamMedium;l.TextSize=12;l.TextStrokeTransparency=.45;l.Parent=bb
 VisualManager.PlayerESP[key]=bb
 return bb
end

local function updatePlayers()
 if not Config then return end
 local enabled=Config.PlayerESP or Config.DistESP or Config.HealthESP or Config.TargetESP
 if not enabled then clearMap(VisualManager.PlayerESP);return end
 local my=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
 if not my then return end
 for _,p in ipairs(Players:GetPlayers()) do
  if p==LP or not p.Character then continue end
  local r=p.Character:FindFirstChild("HumanoidRootPart")
  local h=p.Character:FindFirstChildOfClass("Humanoid")
  if not r or not h then continue end
  local dist=(r.Position-my.Position).Magnitude
  local bb=ensurePlayerESP(p)
  if dist>(Config.ESPMaxDist or 400) then bb.Enabled=false;continue end
  bb.Enabled=true;bb.Adornee=r
  local l=bb:FindFirstChild("L")
  if l then
   local col=accent()
   if TargetManager and TargetManager.GetTarget and TargetManager.GetTarget()==p then col=Color3.fromRGB(255,70,70) end
   l.TextColor3=col
   local text=p.DisplayName
   if Config.DistESP then text..=string.format("  %.0fm",dist) end
   if Config.HealthESP then text..=string.format("  %.0fHP",h.Health) end
   l.Text=text
  end
 end
end

local function addBox(map,obj,color)
 if map[obj] and map[obj].Parent then return end
 local box=Instance.new("BoxHandleAdornment")
 box.Adornee=obj;box.AlwaysOnTop=true;box.ZIndex=6;box.Transparency=.5;box.Size=obj.Size
 box.Color3=color or accent();box.Parent=CoreGui
 map[obj]=box
end

local function scanPCLD()
 if not Config.PCLDESP then clearMap(VisualManager.PCLD);return end
 for _,o in ipairs(Workspace:GetDescendants()) do
  if o:IsA("BasePart") and PCLD_NAMES[string.lower(o.Name)] then addBox(VisualManager.PCLD,o,accent()) end
 end
 for o,b in pairs(VisualManager.PCLD) do
  if not o.Parent then pcall(function()b:Destroy()end);VisualManager.PCLD[o]=nil else b.Color3=accent();b.Size=o.Size end
 end
end

local function blackholePart(o)
 if o:IsA("BasePart") then return o end
 return o:FindFirstChildWhichIsA("BasePart",true)
end

local function addBlackhole(o)
 local p=blackholePart(o);if not p then return end
 addBox(VisualManager.Blackholes,p,Color3.fromRGB(180,70,255))
end

local function scanBlackholes()
 if not Config.BlackholeESP then clearMap(VisualManager.Blackholes);return end
 for _,o in ipairs(Workspace:GetChildren()) do
  if BLACKHOLE_NAMES[string.lower(o.Name or "")] then addBlackhole(o) end
 end
end

local function nearestPlayer(pos)
 local best,bestD=nil,math.huge
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and p.Character then
   local r=p.Character:FindFirstChild("HumanoidRootPart")
   if r then
    local d=(r.Position-pos).Magnitude
    if d<bestD then bestD=d;best=p end
   end
  end
 end
 return best
end

local function handleWorldAdded(o)
 local n=string.lower(o.Name or "")
 if Config and Config.PCLDESP and o:IsA("BasePart") and PCLD_NAMES[n] then addBox(VisualManager.PCLD,o,accent()) end
 if Config and BLACKHOLE_NAMES[n] then
  if Config.BlackholeESP then task.defer(function()if o.Parent then addBlackhole(o)end end)end
  if Config.KickNotify and Client and Client.Notify then
   task.delay(.1,function()
    if not o.Parent then return end
    local p=blackholePart(o)
    if not p then return end
    local who=nearestPlayer(p.Position)
    Client.Notify("Kick detected",who and (who.DisplayName.." ("..who.Name..")") or "Blackhole spawned",false)
   end)
  end
 end
end

local function updateGrabbed()
 if not Config.GrabbedObjectESP then
  if VisualManager.Grabbed then VisualManager.Grabbed:Destroy();VisualManager.Grabbed=nil end
  return
 end
 local target=nil
 for _,o in ipairs(Workspace:GetChildren()) do
  if o.Name=="GrabParts" then
   local gp=o:FindFirstChild("GrabPart")
   local w=gp and gp:FindFirstChild("WeldConstraint")
   if w and w.Part1 then target=w.Part1 break end
  end
 end
 if not target then
  if VisualManager.Grabbed then VisualManager.Grabbed:Destroy();VisualManager.Grabbed=nil end
  return
 end
 if not VisualManager.Grabbed then
  local h=Instance.new("Highlight")
  h.Name="PenguGrabbed";h.FillTransparency=.72;h.OutlineTransparency=0;h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=CoreGui
  VisualManager.Grabbed=h
 end
 VisualManager.Grabbed.Adornee=target:FindFirstAncestorOfClass("Model") or target
 VisualManager.Grabbed.OutlineColor=accent()
 VisualManager.Grabbed.FillColor=accent()
end

local function clearTrace()
 if VisualManager.Trace then VisualManager.Trace:Destroy();VisualManager.Trace=nil end
 clearMap(VisualManager.TraceAttachments)
end

local function updateTrace()
 if not Config.TargetTrace then clearTrace();return end
 local target=TargetManager and TargetManager.GetTarget and TargetManager.GetTarget()
 local a=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
 local b=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 if not a or not b then clearTrace();return end
 if not VisualManager.Trace then
  local a0=Instance.new("Attachment");a0.Name="PenguTraceA";a0.Parent=a
  local a1=Instance.new("Attachment");a1.Name="PenguTraceB";a1.Parent=b
  local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.05;beam.Width1=.05;beam.FaceCamera=true;beam.Parent=a0
  VisualManager.TraceAttachments={a0,a1};VisualManager.Trace=beam
 end
 VisualManager.Trace.Color=ColorSequence.new(accent())
end

local function antiInvis()
 if not Config.AntiInvis then return end
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and p.Character then
   for _,d in ipairs(p.Character:GetDescendants()) do
    if d:IsA("BasePart") then d.LocalTransparencyModifier=0 end
   end
  end
 end
end

function VisualManager.Init(client)
 Client=client
 Config=client.Get("config.lua")
 TargetManager=client.Get("TargetManager.lua")
 own(RunService.RenderStepped:Connect(function()
  updatePlayers()
  scanPCLD()
  scanBlackholes()
  updateGrabbed()
  updateTrace()
  antiInvis()
 end))
 own(Workspace.DescendantAdded:Connect(handleWorldAdded))
end

function VisualManager.Destroy()
 clearMap(VisualManager.PlayerESP)
 clearMap(VisualManager.PCLD)
 clearMap(VisualManager.Blackholes)
 if VisualManager.Grabbed then VisualManager.Grabbed:Destroy();VisualManager.Grabbed=nil end
 clearTrace()
 for _,c in ipairs(VisualManager.Connections) do pcall(function()c:Disconnect()end)end
 VisualManager.Connections={}
end

return VisualManager
