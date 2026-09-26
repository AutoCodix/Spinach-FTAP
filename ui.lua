--[[ Spinach UI v0.3.0 — compact Cowin tabs + RusherHack-inspired floating panels ]]
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local CoreGui=game:GetService("CoreGui")
local TeleportService=game:GetService("TeleportService")

local LP=Players.LocalPlayer
local UI={
 Gui=nil,
 Connections={},
 AccentBindings={},
 Windows={},
 ActiveTab="MODULES",
}
local Config,TargetManager,Combat,Defense,PlayerController,Spinach

local BG=Color3.fromRGB(11,11,14)
local PANEL=Color3.fromRGB(17,17,21)
local HEADER=Color3.fromRGB(20,20,25)
local ROW=Color3.fromRGB(25,25,30)
local ROW_HOVER=Color3.fromRGB(30,30,36)
local TEXT=Color3.fromRGB(225,225,232)
local MUTED=Color3.fromRGB(125,125,140)
local OFF=Color3.fromRGB(64,64,74)
local PURPLE=Color3.fromRGB(119,0,255)

local function bind(c)table.insert(UI.Connections,c);return c end
local function corner(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o;return c end
local function outline(o,col,thick)local s=Instance.new("UIStroke");s.Color=col or Color3.fromRGB(46,43,55);s.Thickness=thick or 1;s.Parent=o;return s end
local function currentAccent()
 if Config and Config.RainbowUI then
  local speed=Config.RainbowSpeed or .12
  return Color3.fromHSV((time()*speed)%1,.88,1)
 end
 return (Config and Config.Accent) or PURPLE
end
local function accentBind(obj,prop,condition,off)
 table.insert(UI.AccentBindings,{obj=obj,prop=prop,condition=condition,off=off})
 obj[prop]=(not condition or condition()) and currentAccent() or (off or obj[prop])
end
local function refreshAccents()
 local col=currentAccent()
 for i=#UI.AccentBindings,1,-1 do
  local a=UI.AccentBindings[i]
  if not a.obj or not a.obj.Parent then
   table.remove(UI.AccentBindings,i)
  else
   local active=not a.condition or a.condition()
   a.obj[a.prop]=active and col or (a.off or a.obj[a.prop])
  end
 end
end

local function hover(btn)
 bind(btn.MouseEnter:Connect(function()if btn.BackgroundColor3==ROW then btn.BackgroundColor3=ROW_HOVER end end))
 bind(btn.MouseLeave:Connect(function()if btn.BackgroundColor3==ROW_HOVER then btn.BackgroundColor3=ROW end end))
end

local function drag(frame,handle)
 local down=false
 local start=nil
 local original=nil
 bind(handle.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then
   down=true;start=i.Position;original=frame.Position
  end
 end))
 bind(UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end))
 bind(UIS.InputChanged:Connect(function(i)
  if down and i.UserInputType==Enum.UserInputType.MouseMovement then
   local d=i.Position-start
   frame.Position=UDim2.new(original.X.Scale,original.X.Offset+d.X,original.Y.Scale,original.Y.Offset+d.Y)
  end
 end))
end

local function label(parent,text,height,color,size,bold)
 local l=Instance.new("TextLabel")
 l.Size=UDim2.new(1,0,0,height or 20)
 l.BackgroundTransparency=1
 l.Text=text
 l.TextColor3=color or TEXT
 l.Font=bold and Enum.Font.Code or Enum.Font.Code
 l.TextSize=size or 12
 l.TextXAlignment=Enum.TextXAlignment.Left
 l.Parent=parent
 return l
end

local function button(parent,name,cb)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,0,0,27)
 b.BackgroundColor3=ROW
 b.BorderSizePixel=0
 b.Text=name
 b.TextColor3=TEXT
 b.Font=Enum.Font.Code
 b.TextSize=12
 b.AutoButtonColor=false
 b.Parent=parent
 hover(b)
 bind(b.MouseButton1Click:Connect(function()if cb then cb()end end))
 return b
end

local function toggle(parent,name,key,cb)
 local row=Instance.new("TextButton")
 row.Size=UDim2.new(1,0,0,27)
 row.BackgroundColor3=ROW
 row.BorderSizePixel=0
 row.Text=""
 row.AutoButtonColor=false
 row.Parent=parent
 hover(row)

 local left=Instance.new("Frame")
 left.Size=UDim2.new(0,2,1,0)
 left.BorderSizePixel=0
 left.Parent=row
 accentBind(left,"BackgroundColor3",function()return Config[key] end,ROW)

 local txt=Instance.new("TextLabel")
 txt.Size=UDim2.new(1,-38,1,0)
 txt.Position=UDim2.new(0,8,0,0)
 txt.BackgroundTransparency=1
 txt.Text=name
 txt.TextColor3=TEXT
 txt.Font=Enum.Font.Code
 txt.TextSize=12
 txt.TextXAlignment=Enum.TextXAlignment.Left
 txt.Parent=row
 accentBind(txt,"TextColor3",function()return Config[key] end,TEXT)

 local sw=Instance.new("Frame")
 sw.Size=UDim2.new(0,20,0,10)
 sw.Position=UDim2.new(1,-28,.5,-5)
 sw.BackgroundColor3=OFF
 sw.BorderSizePixel=0
 sw.Parent=row
 corner(sw,5)

 local knob=Instance.new("Frame")
 knob.Size=UDim2.new(0,8,0,8)
 knob.Position=Config[key] and UDim2.new(1,-9,.5,-4) or UDim2.new(0,1,.5,-4)
 knob.BackgroundColor3=Color3.fromRGB(235,235,240)
 knob.BorderSizePixel=0
 knob.Parent=sw
 corner(knob,4)
 accentBind(sw,"BackgroundColor3",function()return Config[key] end,OFF)

 bind(row.MouseButton1Click:Connect(function()
  Config[key]=not Config[key]
  knob.Position=Config[key] and UDim2.new(1,-9,.5,-4) or UDim2.new(0,1,.5,-4)
  refreshAccents()
  if cb then cb(Config[key])end
 end))
 return row
end

local function slider(parent,name,key,min,max,cb)
 local f=Instance.new("Frame")
 f.Size=UDim2.new(1,0,0,39)
 f.BackgroundColor3=ROW
 f.BorderSizePixel=0
 f.Parent=parent

 local n=Instance.new("TextLabel")
 n.Size=UDim2.new(.67,-8,0,19)
 n.Position=UDim2.new(0,8,0,2)
 n.BackgroundTransparency=1
 n.Text=name
 n.TextColor3=TEXT
 n.Font=Enum.Font.Code
 n.TextSize=11
 n.TextXAlignment=Enum.TextXAlignment.Left
 n.Parent=f

 local val=Instance.new("TextLabel")
 val.Size=UDim2.new(.33,-8,0,19)
 val.Position=UDim2.new(.67,0,0,2)
 val.BackgroundTransparency=1
 val.Text=tostring(Config[key])
 val.Font=Enum.Font.Code
 val.TextSize=11
 val.TextXAlignment=Enum.TextXAlignment.Right
 val.Parent=f
 accentBind(val,"TextColor3")

 local bar=Instance.new("Frame")
 bar.Size=UDim2.new(1,-16,0,3)
 bar.Position=UDim2.new(0,8,0,29)
 bar.BackgroundColor3=Color3.fromRGB(47,47,57)
 bar.BorderSizePixel=0
 bar.Parent=f

 local fill=Instance.new("Frame")
 fill.Size=UDim2.new(math.clamp(((Config[key] or min)-min)/(max-min),0,1),0,1,0)
 fill.BackgroundColor3=currentAccent()
 fill.BorderSizePixel=0
 fill.Parent=bar
 accentBind(fill,"BackgroundColor3")

 local hit=Instance.new("TextButton")
 hit.Size=UDim2.new(1,0,0,14)
 hit.Position=UDim2.new(0,0,.5,-7)
 hit.BackgroundTransparency=1
 hit.Text=""
 hit.Parent=bar

 local down=false
 local function apply(x)
  local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
  local num=min+(max-min)*a
  if max-min<=2 then num=math.floor(num*100+.5)/100 else num=math.floor(num+.5) end
  Config[key]=num
  val.Text=tostring(num)
  fill.Size=UDim2.new(a,0,1,0)
  if cb then cb(num)end
 end
 bind(hit.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=true;apply(i.Position.X)end end))
 bind(UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end))
 bind(UIS.InputChanged:Connect(function(i)if down and i.UserInputType==Enum.UserInputType.MouseMovement then apply(i.Position.X)end end))
 return f
end

local function module(parent,name,key,settingsBuilder,cb)
 local wrap=Instance.new("Frame")
 wrap.Size=UDim2.new(1,0,0,27)
 wrap.AutomaticSize=Enum.AutomaticSize.Y
 wrap.BackgroundTransparency=1
 wrap.LayoutOrder=10
 wrap.Parent=parent

 local stack=Instance.new("UIListLayout")
 stack.Padding=UDim.new(0,1)
 stack.SortOrder=Enum.SortOrder.LayoutOrder
 stack.Parent=wrap

 local row=Instance.new("TextButton")
 row.Size=UDim2.new(1,0,0,27)
 row.LayoutOrder=0
 row.BackgroundColor3=ROW
 row.BorderSizePixel=0
 row.Text=""
 row.AutoButtonColor=false
 row.Parent=wrap
 hover(row)

 local strip=Instance.new("Frame")
 strip.Size=UDim2.new(0,2,1,0)
 strip.BorderSizePixel=0
 strip.Parent=row
 accentBind(strip,"BackgroundColor3",function()return Config[key] end,ROW)

 local txt=Instance.new("TextLabel")
 txt.Size=UDim2.new(1,-45,1,0)
 txt.Position=UDim2.new(0,8,0,0)
 txt.BackgroundTransparency=1
 txt.Text=name
 txt.TextColor3=TEXT
 txt.Font=Enum.Font.Code
 txt.TextSize=12
 txt.TextXAlignment=Enum.TextXAlignment.Left
 txt.Parent=row
 accentBind(txt,"TextColor3",function()return Config[key] end,TEXT)

 local arrow=Instance.new("TextLabel")
 arrow.Size=UDim2.new(0,20,1,0)
 arrow.Position=UDim2.new(1,-27,0,0)
 arrow.BackgroundTransparency=1
 arrow.Text=settingsBuilder and ">" or "•"
 arrow.TextColor3=MUTED
 arrow.Font=Enum.Font.Code
 arrow.TextSize=12
 arrow.Parent=row

 local settings=nil
 if settingsBuilder then
  settings=Instance.new("Frame")
  settings.Size=UDim2.new(1,0,0,0)
  settings.AutomaticSize=Enum.AutomaticSize.Y
  settings.LayoutOrder=1
  settings.BackgroundTransparency=1
  settings.Visible=false
  settings.Parent=wrap
  local list=Instance.new("UIListLayout")
  list.Padding=UDim.new(0,1)
  list.SortOrder=Enum.SortOrder.LayoutOrder
  list.Parent=settings
  settingsBuilder(settings)
 end

 bind(row.MouseButton1Click:Connect(function()
  Config[key]=not Config[key]
  refreshAccents()
  if cb then cb(Config[key])end
 end))
 bind(row.MouseButton2Click:Connect(function()
  if settings then
   settings.Visible=not settings.Visible
   arrow.Text=settings.Visible and "v" or ">"
  end
 end))
 return wrap
end

local function panel(parent,title,x,builder)
 local f=Instance.new("Frame")
 f.Size=UDim2.new(0,225,0,34)
 f.Position=UDim2.new(0,x,0,10)
 f.AutomaticSize=Enum.AutomaticSize.Y
 f.BackgroundColor3=BG
 f.BackgroundTransparency=.03
 f.BorderSizePixel=0
 f.Parent=parent
 corner(f,5)
 outline(f,Color3.fromRGB(48,45,57))

 local layout=Instance.new("UIListLayout")
 layout.Padding=UDim.new(0,1)
 layout.SortOrder=Enum.SortOrder.LayoutOrder
 layout.Parent=f

 local head=Instance.new("TextButton")
 head.Size=UDim2.new(1,0,0,31)
 head.LayoutOrder=0
 head.BackgroundColor3=HEADER
 head.BorderSizePixel=0
 head.Text=""
 head.AutoButtonColor=false
 head.Parent=f

 local accentLine=Instance.new("Frame")
 accentLine.Size=UDim2.new(1,0,0,2)
 accentLine.Position=UDim2.new(0,0,0,0)
 accentLine.BorderSizePixel=0
 accentLine.Parent=head
 accentBind(accentLine,"BackgroundColor3")

 local titleLabel=Instance.new("TextLabel")
 titleLabel.Size=UDim2.new(1,-36,1,0)
 titleLabel.Position=UDim2.new(0,9,0,1)
 titleLabel.BackgroundTransparency=1
 titleLabel.Text=title:upper()
 titleLabel.TextColor3=TEXT
 titleLabel.Font=Enum.Font.Code
 titleLabel.TextSize=13
 titleLabel.TextXAlignment=Enum.TextXAlignment.Left
 titleLabel.Parent=head

 local collapse=Instance.new("TextLabel")
 collapse.Size=UDim2.new(0,20,1,0)
 collapse.Position=UDim2.new(1,-27,0,0)
 collapse.BackgroundTransparency=1
 collapse.Text="−"
 collapse.TextColor3=MUTED
 collapse.Font=Enum.Font.Code
 collapse.TextSize=13
 collapse.Parent=head

 local body=Instance.new("Frame")
 body.Size=UDim2.new(1,0,0,0)
 body.AutomaticSize=Enum.AutomaticSize.Y
 body.LayoutOrder=1
 body.BackgroundTransparency=1
 body.Parent=f
 local bodyList=Instance.new("UIListLayout")
 bodyList.Padding=UDim.new(0,1)
 bodyList.SortOrder=Enum.SortOrder.LayoutOrder
 bodyList.Parent=body

 bind(head.MouseButton2Click:Connect(function()
  body.Visible=not body.Visible
  collapse.Text=body.Visible and "−" or "+"
 end))
 drag(f,head)
 builder(body)
 table.insert(UI.Windows,f)
 return f
end

local function localRoot()
 return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end
local function tpTo(plr)
 if not plr or not plr.Character then return end
 local theirs=plr.Character:FindFirstChild("HumanoidRootPart")
 local mine=localRoot()
 if theirs and mine then mine.CFrame=theirs.CFrame*CFrame.new(0,0,4) end
end

local function buildModules(page)
 panel(page,"Combat",14,function(p)
  module(p,"Super Throw","SuperThrow",function(s)
   slider(s,"Strength","StrengthValue",1,10)
   slider(s,"Throw Multiplier","ThrowMult",1,8)
   toggle(s,"Super Strength","SuperStrength")
   toggle(s,"Fling Up","FlingUp")
   toggle(s,"Slam","Slam")
   toggle(s,"Void Fling","VoidFling")
   toggle(s,"Spin Fling","SpinFling")
  end,function(v)if Combat then if v then Combat.EnableSuperThrow()else Combat.DisableSuperThrow()end end end)
  module(p,"Fling Aura","FlingAura",function(s)slider(s,"Range","AuraRange",8,80);slider(s,"Cooldown","AuraCD",.1,2)end)
  module(p,"Ragdoll Aura","RagdollAura")
  module(p,"Sit Aura","SitAura")
  module(p,"Spin Aura","SpinAura")
  module(p,"Bring Aura","BringAura")
  module(p,"Void Aura","VoidAura")
  module(p,"Grab Reach","GrabReach",function(s)slider(s,"Reach","MaxGrabReach",20,50)end)
 end)

 panel(page,"Player",249,function(p)
  module(p,"Third Person","ThirdPerson",function(s)
   slider(s,"Start Zoom","TPDistance",2,20)
   slider(s,"Max Wheel Zoom","TPMaxZoom",8,60)
   slider(s,"FOV","FOV",50,120)
   button(s,"Restore Roblox Camera",function()if PlayerController then PlayerController.RestoreCamera()end end)
  end,function(v)if PlayerController then PlayerController.SetThirdPerson(v)end end)
  module(p,"Speed","SpeedEnabled",function(s)slider(s,"Walk Speed","WalkSpeed",16,100)end)
  module(p,"Jump Boost","JumpEnabled",function(s)slider(s,"Jump Power","JumpPower",50,150)end)
  module(p,"Flight","Flight",function(s)slider(s,"Flight Speed","FlightSpeed",10,120);label(s,"  WASD + Space / Ctrl",20,MUTED,10)end)
  module(p,"Noclip","Noclip")
  module(p,"Infinite Jump","InfJump")
  module(p,"Character Spin","CharSpin",function(s)slider(s,"Spin Speed","SpinSpeed",2,60)end)
 end)

 panel(page,"Defense",484,function(p)
  module(p,"Anti Grab","AntiGrab")
  module(p,"Gucci Anti-Grab","AntiGucci",function(s)
   slider(s,"Check Interval","AntiGucciInterval",.05,.4)
   toggle(s,"Emergency Only","AntiGucciEmergencyOnly")
  end)
  module(p,"Anti Blobman","AntiBlobman")
  module(p,"Anti Fling","AntiFling")
  module(p,"Anti Ragdoll","AntiRagdoll")
  module(p,"Instant Get Up","InstantGetUp")
  module(p,"Anti Sit","AntiSit")
  module(p,"Anti Void","AntiVoid")
  module(p,"Anti Lag","AntiLag")
  module(p,"Auto Anti-Lag","AutoAntiLag")
 end)

 panel(page,"World / Misc",719,function(p)
  module(p,"Fullbright","Fullbright")
  module(p,"No Fog","NoFog")
  module(p,"No Shadows","NoShadows")
  module(p,"Custom Time","CustomTime",function(s)slider(s,"Clock Time","ClockTime",0,24)end)
  module(p,"Noclip Barrier","NoclipBarrier")
  module(p,"Anti Invis","AntiInvis")
  button(p,"Respawn",function()local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid");if h then h.Health=0 end end)
  button(p,"Rejoin Server",function()pcall(function()TeleportService:Teleport(game.PlaceId,LP)end)end)
 end)
end

local function buildTargets(page)
 panel(page,"Targeting",14,function(p)
  toggle(p,"Nearest Target","NearestTarget")
  toggle(p,"Target Lock","TargetLock")
  slider(p,"Distance Limit","DistLimit",25,500)
  button(p,"Select Nearest",function()if TargetManager then TargetManager.SetTarget(TargetManager.GetNearest())end end)
  button(p,"Teleport To Target",function()if TargetManager then tpTo(TargetManager.GetTarget())end end)
  button(p,"Teleport To Nearest",function()if TargetManager then tpTo(TargetManager.GetNearest())end end)
  button(p,"Clear Target",function()if TargetManager then TargetManager.ClearTarget()end end)
 end)
 panel(page,"Blobman",249,function(p)
  toggle(p,"Blob Loop","BlobLoop")
  toggle(p,"Blob Grab All","BlobGrabAll")
  toggle(p,"Anti Blobman","AntiBlobman")
  label(p,"  Net Owner Spam: unsupported",22,MUTED,10)
 end)
end

local function buildVisuals(page)
 panel(page,"Player ESP",14,function(p)
  toggle(p,"Player ESP","PlayerESP")
  toggle(p,"Distance ESP","DistESP")
  toggle(p,"Health ESP","HealthESP")
  toggle(p,"Target ESP","TargetESP")
  toggle(p,"Rainbow ESP","Rainbow")
  slider(p,"ESP Distance","ESPMaxDist",100,1000)
 end)
 panel(page,"Camera",249,function(p)
  slider(p,"FOV","FOV",50,120)
  toggle(p,"Third Person","ThirdPerson",function(v)if PlayerController then PlayerController.SetThirdPerson(v)end end)
  slider(p,"Max Wheel Zoom","TPMaxZoom",8,60)
  label(p,"  Third Person uses Roblox's native",18,MUTED,10)
  label(p,"  scroll-wheel camera now.",18,MUTED,10)
 end)
 panel(page,"World",484,function(p)
  toggle(p,"Fullbright","Fullbright")
  toggle(p,"No Fog","NoFog")
  toggle(p,"No Shadows","NoShadows")
  toggle(p,"Custom Time","CustomTime")
  slider(p,"Clock Time","ClockTime",0,24)
 end)
end

local function buildWhitelist(page)
 panel(page,"Whitelisted",14,function(p)
  toggle(p,"Whitelist Enabled","WhitelistEnabled")
  toggle(p,"Auto Whitelist Friends","AutoWLFriends")
  local info=Instance.new("TextLabel")
  info.Size=UDim2.new(1,0,0,115)
  info.BackgroundColor3=ROW
  info.BorderSizePixel=0
  info.Text="  Whitelisted players are ignored by\n  targeting/combat where supported.\n\n  Auto Whitelist Friends uses your\n  Roblox friends list."
  info.TextColor3=MUTED
  info.Font=Enum.Font.Code
  info.TextSize=11
  info.TextXAlignment=Enum.TextXAlignment.Left
  info.TextYAlignment=Enum.TextYAlignment.Top
  info.Parent=p
 end)
end

local function buildConfigs(page)
 panel(page,"Appearance",14,function(p)
  toggle(p,"Rainbow UI","RainbowUI")
  slider(p,"Rainbow Speed","RainbowSpeed",.03,.5)
  label(p,"  Base accent: #7700ff",20,MUTED,10)
 end)
 panel(page,"Config",249,function(p)
  button(p,"Save Default",function()
   local m=Spinach.Get("ConfigManager.lua")
   if m then local ok,e=m.Save();Spinach.Notify("CONFIG",ok and "Saved" or tostring(e),not ok)end
  end)
  button(p,"Load Default",function()
   local m=Spinach.Get("ConfigManager.lua")
   if m then local ok,e=m.Load();Spinach.Notify("CONFIG",ok and "Loaded" or tostring(e),not ok)end
  end)
  toggle(p,"Notifications","NotifEnabled")
  toggle(p,"Skip Intro","SkipIntro")
 end)
 panel(page,"Info",484,function(p)
  label(p,"Spinach "..tostring(Config.Version or "?"),24,TEXT,12,true)
  label(p,"Right-click a module for settings.",20,MUTED,10)
  label(p,"Right-click a category to collapse.",20,MUTED,10)
  label(p,"Right Ctrl toggles the GUI.",20,MUTED,10)
 end)
end

local function makePage(parent,name,builder)
 local p=Instance.new("Frame")
 p.Name=name
 p.Size=UDim2.new(1,0,1,-52)
 p.Position=UDim2.new(0,0,0,52)
 p.BackgroundTransparency=1
 p.Visible=name==UI.ActiveTab
 p.Parent=parent
 builder(p)
 return p
end

local function buildGUI()
 if UI.Gui then UI.Gui:Destroy()end
 UI.AccentBindings={}
 UI.Windows={}

 UI.Gui=Instance.new("ScreenGui")
 UI.Gui.Name="SpinachUI"
 UI.Gui.ResetOnSpawn=false
 UI.Gui.IgnoreGuiInset=true
 UI.Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 UI.Gui.Parent=CoreGui

 local top=Instance.new("Frame")
 top.Size=UDim2.new(0,650,0,36)
 top.Position=UDim2.new(.5,-325,0,10)
 top.BackgroundColor3=BG
 top.BorderSizePixel=0
 top.Parent=UI.Gui
 corner(top,6)
 outline(top,Color3.fromRGB(48,45,57))

 local topAccent=Instance.new("Frame")
 topAccent.Size=UDim2.new(1,0,0,2)
 topAccent.Position=UDim2.new(0,0,1,-2)
 topAccent.BorderSizePixel=0
 topAccent.Parent=top
 accentBind(topAccent,"BackgroundColor3")

 local brand=Instance.new("TextLabel")
 brand.Size=UDim2.new(0,112,1,0)
 brand.Position=UDim2.new(0,10,0,0)
 brand.BackgroundTransparency=1
 brand.Text="SPINACH"
 brand.Font=Enum.Font.Code
 brand.TextSize=15
 brand.TextXAlignment=Enum.TextXAlignment.Left
 brand.Parent=top
 accentBind(brand,"TextColor3")

 local version=Instance.new("TextLabel")
 version.Size=UDim2.new(0,50,1,0)
 version.Position=UDim2.new(0,79,0,0)
 version.BackgroundTransparency=1
 version.Text="v"..tostring(Config.Version or "?")
 version.TextColor3=MUTED
 version.Font=Enum.Font.Code
 version.TextSize=9
 version.TextXAlignment=Enum.TextXAlignment.Left
 version.Parent=top

 local pages={}
 local tabButtons={}
 local tabs={
  {"MODULES",buildModules,96},
  {"TARGETS",buildTargets,90},
  {"VISUALS",buildVisuals,90},
  {"WHITELISTED",buildWhitelist,110},
  {"CONFIGS",buildConfigs,90},
 }
 local x=132
 for _,t in ipairs(tabs)do
  local name,builder,w=t[1],t[2],t[3]
  local b=Instance.new("TextButton")
  b.Size=UDim2.new(0,w,0,26)
  b.Position=UDim2.new(0,x,0,5)
  b.BackgroundColor3=name==UI.ActiveTab and Color3.fromRGB(27,24,34) or BG
  b.BackgroundTransparency=name==UI.ActiveTab and 0 or 1
  b.BorderSizePixel=0
  b.Text=name
  b.TextColor3=name==UI.ActiveTab and currentAccent() or MUTED
  b.Font=Enum.Font.Code
  b.TextSize=11
  b.AutoButtonColor=false
  b.Parent=top
  corner(b,4)
  tabButtons[name]=b
  accentBind(b,"TextColor3",function()return UI.ActiveTab==name end,MUTED)

  pages[name]=makePage(UI.Gui,name,builder)
  bind(b.MouseButton1Click:Connect(function()
   UI.ActiveTab=name
   for n,p in pairs(pages)do p.Visible=n==name end
   for n,btn in pairs(tabButtons)do
    btn.BackgroundTransparency=n==name and 0 or 1
    btn.BackgroundColor3=Color3.fromRGB(27,24,34)
   end
   refreshAccents()
  end))
  x+=w+4
 end

 bind(UIS.InputBegan:Connect(function(i,g)
  if not g and Config and i.KeyCode==Config.MenuKey then
   UI.Gui.Enabled=not UI.Gui.Enabled
  end
 end))

 bind(RunService.RenderStepped:Connect(refreshAccents))
end

function UI.Init(spinach)
 Spinach=spinach
 Config=spinach.Get("config.lua")
 TargetManager=spinach.Get("TargetManager.lua")
 Combat=spinach.Get("combat.lua")
 Defense=spinach.Get("defense.lua")
 PlayerController=spinach.Get("PlayerController.lua")
 Config.Accent=PURPLE
 buildGUI()
 if Config.ThirdPerson and PlayerController then PlayerController.SetThirdPerson(true) end
end

function UI.Destroy()
 for _,c in ipairs(UI.Connections)do pcall(function()c:Disconnect()end)end
 UI.Connections={}
 UI.AccentBindings={}
 if UI.Gui then UI.Gui:Destroy();UI.Gui=nil end
end

return UI
