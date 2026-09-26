--[[ Spinach UI v0.3 — Cowin-style tabs + RusherHack-inspired floating ClickGUI ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CoreGui=game:GetService("CoreGui")
local Workspace=game:GetService("Workspace")
local LP=Players.LocalPlayer

local UI={Gui=nil,TPConn=nil,OrigCam=nil,InputConns={},Windows={}}
local Config,TargetManager,Combat,Defense,Spinach
local ACCENT=Color3.fromRGB(119,0,255)
local BG=Color3.fromRGB(13,13,16)
local PANEL=Color3.fromRGB(19,19,23)
local ROW=Color3.fromRGB(25,25,30)
local TEXT=Color3.fromRGB(224,224,230)
local MUTED=Color3.fromRGB(135,135,148)

local function corner(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o end
local function stroke(o,col,t)local s=Instance.new("UIStroke");s.Color=col or Color3.fromRGB(45,45,55);s.Thickness=t or 1;s.Parent=o end
local function track(c)table.insert(UI.InputConns,c);return c end
local function drag(frame,handle)
 local active,start,pos=false
 track(handle.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active=true;start=i.Position;pos=frame.Position end end))
 track(UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active=false end end))
 track(UIS.InputChanged:Connect(function(i)if active and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-start;frame.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)end end))
end

local function restoreCamera()
 if UI.TPConn then UI.TPConn:Disconnect();UI.TPConn=nil end
 local cam=Workspace.CurrentCamera
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  if h then cam.CameraSubject=h end
  if UI.OrigCam then cam.FieldOfView=UI.OrigCam.fov or 70 end
 end
 UI.OrigCam=nil
end
local function enableThirdPerson()
 restoreCamera()
 local cam=Workspace.CurrentCamera;if not cam then return end
 UI.OrigCam={fov=cam.FieldOfView}
 cam.CameraType=Enum.CameraType.Scriptable
 local yaw,pitch=0,math.rad(-10)
 UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
 UI.TPConn=RunService.RenderStepped:Connect(function(dt)
  if not Config or not Config.ThirdPerson then return end
  local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart");if not root then return end
  local delta=UIS:GetMouseDelta()
  yaw-=delta.X*0.0026;pitch=math.clamp(pitch-delta.Y*0.0026,math.rad(-75),math.rad(70))
  local pivot=root.Position+Vector3.new(0,Config.TPHeight or 1.5,0)
  local rot=CFrame.fromEulerAnglesYXZ(pitch,yaw,0)
  local forward=rot.LookVector;local right=rot.RightVector
  local desired=pivot-forward*(Config.TPDistance or 8)+right*(Config.TPShoulder or 1.5)
  if Config.TPCollision then
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={LP.Character}
   local hit=Workspace:Raycast(pivot,desired-pivot,rp)
   if hit then desired=hit.Position+hit.Normal*.35 end
  end
  local targetCF=CFrame.lookAt(desired,pivot+forward*2)
  cam.CFrame=cam.CFrame:Lerp(targetCF,math.clamp(dt*18,0,1));cam.FieldOfView=Config.FOV or 70
 end)
 table.insert(Spinach.Connections,UI.TPConn)
end

local function toggle(parent,name,key,cb)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,25);b.BackgroundColor3=ROW;b.BorderSizePixel=0;b.Text="";b.Parent=parent
 local l=Instance.new("TextLabel");l.Size=UDim2.new(1,-32,1,0);l.Position=UDim2.new(0,7,0,0);l.BackgroundTransparency=1;l.Text=name;l.TextColor3=TEXT;l.Font=Enum.Font.Code;l.TextSize=13;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=b
 local state=Instance.new("Frame");state.Size=UDim2.new(0,8,0,8);state.Position=UDim2.new(1,-16,.5,-4);state.BorderSizePixel=0;state.BackgroundColor3=Config[key] and ACCENT or Color3.fromRGB(65,65,75);state.Parent=b;corner(state,2)
 b.MouseButton1Click:Connect(function()Config[key]=not Config[key];state.BackgroundColor3=Config[key] and ACCENT or Color3.fromRGB(65,65,75);if cb then cb(Config[key])end end)
 return b
end
local function slider(parent,name,key,min,max,cb)
 local f=Instance.new("Frame");f.Size=UDim2.new(1,0,0,35);f.BackgroundColor3=ROW;f.BorderSizePixel=0;f.Parent=parent
 local l=Instance.new("TextLabel");l.Size=UDim2.new(.72,-7,0,18);l.Position=UDim2.new(0,7,0,1);l.BackgroundTransparency=1;l.Text=name;l.TextColor3=TEXT;l.Font=Enum.Font.Code;l.TextSize=12;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=f
 local v=Instance.new("TextLabel");v.Size=UDim2.new(.28,-7,0,18);v.Position=UDim2.new(.72,0,0,1);v.BackgroundTransparency=1;v.Text=tostring(Config[key]);v.TextColor3=ACCENT;v.Font=Enum.Font.Code;v.TextSize=12;v.TextXAlignment=Enum.TextXAlignment.Right;v.Parent=f
 local bar=Instance.new("Frame");bar.Size=UDim2.new(1,-14,0,3);bar.Position=UDim2.new(0,7,0,26);bar.BackgroundColor3=Color3.fromRGB(48,48,58);bar.BorderSizePixel=0;bar.Parent=f
 local fill=Instance.new("Frame");fill.Size=UDim2.new(math.clamp(((Config[key] or min)-min)/(max-min),0,1),0,1,0);fill.BackgroundColor3=ACCENT;fill.BorderSizePixel=0;fill.Parent=bar
 local down=false
 bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=true end end)
 track(UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end))
 track(UIS.InputChanged:Connect(function(i)if down and i.UserInputType==Enum.UserInputType.MouseMovement then local a=math.clamp((i.Position.X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1);local n=min+(max-min)*a;n=math.floor(n*100+.5)/100;Config[key]=n;v.Text=tostring(n);fill.Size=UDim2.new(a,0,1,0);if cb then cb(n)end end end))
end
local function button(parent,name,cb)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,25);b.BackgroundColor3=ROW;b.BorderSizePixel=0;b.Text=name;b.TextColor3=TEXT;b.Font=Enum.Font.Code;b.TextSize=12;b.Parent=parent;b.MouseButton1Click:Connect(cb);return b
end

local function module(parent,name,key,build,cb)
 local wrap=Instance.new("Frame");wrap.Size=UDim2.new(1,0,0,26);wrap.AutomaticSize=Enum.AutomaticSize.Y;wrap.BackgroundTransparency=1;wrap.Parent=parent
 local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,1);list.Parent=wrap
 local row=Instance.new("TextButton");row.Size=UDim2.new(1,0,0,26);row.BackgroundColor3=ROW;row.BorderSizePixel=0;row.Text="";row.Parent=wrap
 local label=Instance.new("TextLabel");label.Size=UDim2.new(1,-42,1,0);label.Position=UDim2.new(0,8,0,0);label.BackgroundTransparency=1;label.Text=name;label.TextColor3=Config[key] and ACCENT or TEXT;label.Font=Enum.Font.Code;label.TextSize=13;label.TextXAlignment=Enum.TextXAlignment.Left;label.Parent=row
 local dot=Instance.new("Frame");dot.Size=UDim2.new(0,7,0,7);dot.Position=UDim2.new(1,-16,.5,-3);dot.BorderSizePixel=0;dot.BackgroundColor3=Config[key] and ACCENT or Color3.fromRGB(60,60,70);dot.Parent=row;corner(dot,2)
 local settings
 if build then settings=Instance.new("Frame");settings.Size=UDim2.new(1,0,0,0);settings.AutomaticSize=Enum.AutomaticSize.Y;settings.BackgroundTransparency=1;settings.Visible=false;settings.Parent=wrap;local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,1);ll.Parent=settings;build(settings)end
 row.MouseButton1Click:Connect(function()Config[key]=not Config[key];label.TextColor3=Config[key] and ACCENT or TEXT;dot.BackgroundColor3=Config[key] and ACCENT or Color3.fromRGB(60,60,70);if cb then cb(Config[key])end end)
 row.MouseButton2Click:Connect(function()if settings then settings.Visible=not settings.Visible end end)
end

local function window(parent,title,x,categoryBuilder)
 local f=Instance.new("Frame");f.Size=UDim2.new(0,205,0,34);f.Position=UDim2.new(0,x,0,54);f.AutomaticSize=Enum.AutomaticSize.Y;f.BackgroundColor3=BG;f.BorderSizePixel=0;f.Parent=parent;corner(f,4);stroke(f,Color3.fromRGB(47,42,58))
 local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,1);list.Parent=f
 local h=Instance.new("TextButton");h.Size=UDim2.new(1,0,0,30);h.BackgroundColor3=Color3.fromRGB(20,18,25);h.BorderSizePixel=0;h.Text="  "..title:upper();h.TextColor3=ACCENT;h.Font=Enum.Font.Code;h.TextSize=14;h.TextXAlignment=Enum.TextXAlignment.Left;h.Parent=f
 local body=Instance.new("Frame");body.Size=UDim2.new(1,0,0,0);body.AutomaticSize=Enum.AutomaticSize.Y;body.BackgroundTransparency=1;body.Parent=f;local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,1);ll.Parent=body
 h.MouseButton2Click:Connect(function()body.Visible=not body.Visible end);drag(f,h);categoryBuilder(body);table.insert(UI.Windows,f);return f
end

local function buildModules(page)
 window(page,"Combat",16,function(p)
  module(p,"Super Throw","SuperThrow",function(s)slider(s,"Strength","StrengthValue",1,10);slider(s,"Throw Mult","ThrowMult",1,8);toggle(s,"Super Strength","SuperStrength")end,function(v)if Combat then if v then Combat.EnableSuperThrow()else Combat.DisableSuperThrow()end end end)
  module(p,"Fling Aura","FlingAura",function(s)slider(s,"Range","AuraRange",10,60);slider(s,"Cooldown","AuraCD",.1,2)end)
  module(p,"Ragdoll Aura","RagdollAura");module(p,"Spin Aura","SpinAura");module(p,"Grab Reach","GrabReach",function(s)slider(s,"Reach","MaxGrabReach",20,45)end)
 end)
 window(page,"Player",233,function(p)
  module(p,"Third Person","ThirdPerson",function(s)slider(s,"Distance","TPDistance",3,20);slider(s,"Shoulder X","TPShoulder",-5,5);slider(s,"Height","TPHeight",0,5);slider(s,"FOV","FOV",50,110);toggle(s,"Camera Collision","TPCollision");button(s,"Restore Camera",restoreCamera)end,function(v)if v then enableThirdPerson()else restoreCamera();UIS.MouseBehavior=Enum.MouseBehavior.Default end end)
  module(p,"Noclip","Noclip");module(p,"Infinite Jump","InfJump")
  module(p,"Walk Speed","WalkSpeed",function(s)slider(s,"Speed","WalkSpeed",16,80)end)
 end)
 window(page,"Defense",450,function(p)
  module(p,"Anti Grab","AntiGrab");module(p,"Gucci Anti-Grab","AntiGucci",function(s)slider(s,"Check Interval","AntiGucciInterval",.05,.4);toggle(s,"Emergency Only","AntiGucciEmergencyOnly")end)
  module(p,"Anti Blobman","AntiBlobman");module(p,"Anti Fling","AntiFling");module(p,"Anti Ragdoll","AntiRagdoll");module(p,"Anti Void","AntiVoid");module(p,"Anti Lag","AntiLag")
 end)
 window(page,"World / Misc",667,function(p)
  module(p,"Noclip Barrier","NoclipBarrier");module(p,"Auto Anti-Lag","AutoAntiLag");module(p,"Anti Invis","AntiInvis")
 end)
end

local function buildTargets(page)
 window(page,"Targets",20,function(p)
  toggle(p,"Nearest Target","NearestTarget");toggle(p,"Target Lock","TargetLock");slider(p,"Distance","DistLimit",25,400)
  button(p,"Select Nearest",function()if TargetManager then TargetManager.SetTarget(TargetManager.GetNearest())end end);button(p,"Clear Target",function()if TargetManager then TargetManager.ClearTarget()end end)
 end)
 window(page,"Blobman",240,function(p)toggle(p,"Blob Loop","BlobLoop");toggle(p,"Blob Grab All","BlobGrabAll");toggle(p,"Anti Blobman","AntiBlobman")end)
end
local function buildVisuals(page)
 window(page,"ESP",20,function(p)toggle(p,"Player ESP","PlayerESP");toggle(p,"Distance ESP","DistESP");toggle(p,"Health ESP","HealthESP");toggle(p,"Target ESP","TargetESP");slider(p,"Max Distance","ESPMaxDist",100,800)end)
 window(page,"Style",240,function(p)toggle(p,"Rainbow","Rainbow");slider(p,"FOV","FOV",50,110)end)
end
local function buildWhitelist(page)
 window(page,"Whitelisted",20,function(p)
  toggle(p,"Whitelist Enabled","WhitelistEnabled");toggle(p,"Auto Whitelist Friends","AutoWLFriends")
  local list=Instance.new("TextLabel");list.Size=UDim2.new(1,0,0,180);list.BackgroundColor3=ROW;list.BorderSizePixel=0;list.TextColor3=MUTED;list.Font=Enum.Font.Code;list.TextSize=12;list.TextXAlignment=Enum.TextXAlignment.Left;list.TextYAlignment=Enum.TextYAlignment.Top;list.Text="  Roblox friends are ignored while\n  Auto Whitelist Friends is enabled.\n\n  Custom persistent list coming via\n  ConfigManager.";list.Parent=p
 end)
end
local function buildConfigs(page)
 window(page,"Configs",20,function(p)
  button(p,"Save Default",function()local m=Spinach.Get("ConfigManager.lua");if m then local ok,e=m.Save();Spinach.Notify("CONFIG",ok and "Saved" or tostring(e),not ok)end end)
  button(p,"Load Default",function()local m=Spinach.Get("ConfigManager.lua");if m then local ok,e=m.Load();Spinach.Notify("CONFIG",ok and "Loaded" or tostring(e),not ok)end end)
  toggle(p,"Skip Intro","SkipIntro");toggle(p,"Notifications","NotifEnabled")
 end)
end

local function buildGUI()
 if UI.Gui then UI.Gui:Destroy()end
 UI.Gui=Instance.new("ScreenGui");UI.Gui.Name="SpinachUI";UI.Gui.ResetOnSpawn=false;UI.Gui.IgnoreGuiInset=true;UI.Gui.Parent=CoreGui
 local bar=Instance.new("Frame");bar.Size=UDim2.new(0,630,0,34);bar.Position=UDim2.new(.5,-315,0,12);bar.BackgroundColor3=BG;bar.BorderSizePixel=0;bar.Parent=UI.Gui;corner(bar,5);stroke(bar,Color3.fromRGB(52,45,66))
 local brand=Instance.new("TextLabel");brand.Size=UDim2.new(0,105,1,0);brand.BackgroundTransparency=1;brand.Text="SPINACH";brand.TextColor3=ACCENT;brand.Font=Enum.Font.Code;brand.TextSize=15;brand.Parent=bar
 local pages={}
 local tabs={{"MODULES",buildModules},{"TARGETS",buildTargets},{"VISUALS",buildVisuals},{"WHITELISTED",buildWhitelist},{"CONFIGS",buildConfigs}}
 local function show(n)for name,p in pairs(pages)do p.Visible=name==n end end
 for i,t in ipairs(tabs)do
  local b=Instance.new("TextButton");b.Size=UDim2.new(0,i==4 and 105 or 90,1,0);b.Position=UDim2.new(0,100+(i-1)*96,0,0);b.BackgroundTransparency=1;b.Text=t[1];b.TextColor3=i==1 and ACCENT or MUTED;b.Font=Enum.Font.Code;b.TextSize=12;b.Parent=bar
  local page=Instance.new("Frame");page.Size=UDim2.new(1,0,1,-48);page.Position=UDim2.new(0,0,0,48);page.BackgroundTransparency=1;page.Visible=i==1;page.Parent=UI.Gui;pages[t[1]]=page;t[2](page)
  b.MouseButton1Click:Connect(function()show(t[1]);for _,x in ipairs(bar:GetChildren())do if x:IsA("TextButton")then x.TextColor3=MUTED end end;b.TextColor3=ACCENT end)
 end
 drag(bar,bar)
 track(UIS.InputBegan:Connect(function(i,g)if not g and Config and i.KeyCode==Config.MenuKey then UI.Gui.Enabled=not UI.Gui.Enabled;if not UI.Gui.Enabled then UIS.MouseBehavior=Config.ThirdPerson and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default end end end))
end

function UI.Init(spinach)
 Spinach=spinach;Config=spinach.Get("config.lua");TargetManager=spinach.Get("TargetManager.lua");Combat=spinach.Get("combat.lua");Defense=spinach.Get("defense.lua")
 Config.Accent=ACCENT
 buildGUI()
 track(LP.CharacterAdded:Connect(function()task.wait(.3);if Config.ThirdPerson then enableThirdPerson()end end))
 track(UIS.JumpRequest:Connect(function()if Config.InfJump then local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid");if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end end end))
 if Config.ThirdPerson then enableThirdPerson()end
end
function UI.Destroy()
 restoreCamera();UIS.MouseBehavior=Enum.MouseBehavior.Default
 for _,c in ipairs(UI.InputConns)do pcall(function()c:Disconnect()end)end;UI.InputConns={}
 if UI.Gui then UI.Gui:Destroy();UI.Gui=nil end
end
return UI
