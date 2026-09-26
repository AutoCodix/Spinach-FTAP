--[[
    Spinach UI — large Resonance-style client
    Third Person real camera; Strength slider = config only
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local LP = Players.LocalPlayer

local UI = {Gui=nil,Pages={},TPConn=nil,OrigCam=nil,HeartbeatConn=nil}
local Config,TargetManager,Combat,Defense,SpinachRef=nil,nil,nil,nil,nil
local dragging,dragStart,startPos=false,nil,nil

local function enableThirdPerson()
 if UI.TPConn then return end
 local cam=Workspace.CurrentCamera if not cam then return end
 UI.OrigCam={type=cam.CameraType,subject=cam.CameraSubject,fov=cam.FieldOfView}
 cam.CameraType=Enum.CameraType.Scriptable
 UI.TPConn=RunService.RenderStepped:Connect(function()
  if not Config or not Config.ThirdPerson then return end
  local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") if not root then return end
  local look,right=root.CFrame.LookVector,root.CFrame.RightVector
  local target=root.Position+right*(Config.TPShoulder or 2)+Vector3.new(0,Config.TPHeight or 1,0)-look*(Config.TPDistance or 8)
  if Config.TPCollision then
   local params=RaycastParams.new(); params.FilterDescendantsInstances={LP.Character}; params.FilterType=Enum.RaycastFilterType.Exclude
   local origin=root.Position+Vector3.new(0,Config.TPHeight or 1,0)
   local hit=Workspace:Raycast(origin,target-origin,params)
   if hit then target=hit.Position+hit.Normal*0.5 end
  end
  cam.CFrame=CFrame.lookAt(target,root.Position+Vector3.new(0,(Config.TPHeight or 1)*0.5,0)); cam.FieldOfView=Config.FOV or 70
 end)
 if SpinachRef then table.insert(SpinachRef.Connections,UI.TPConn) end
end
local function disableThirdPerson()
 if UI.TPConn then UI.TPConn:Disconnect(); UI.TPConn=nil end
 local cam=Workspace.CurrentCamera
 if cam and UI.OrigCam then cam.CameraType=UI.OrigCam.type or Enum.CameraType.Custom; if UI.OrigCam.subject then cam.CameraSubject=UI.OrigCam.subject end; cam.FieldOfView=UI.OrigCam.fov or 70
 elseif cam then cam.CameraType=Enum.CameraType.Custom; local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h then cam.CameraSubject=h end end
 UI.OrigCam=nil
end
local function applyStats()
 if not Config then return end
 local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
 if h then h.WalkSpeed=Config.WalkSpeed or 16; h.JumpPower=Config.JumpPower or 50; pcall(function() h.JumpHeight=(Config.JumpPower or 50)/3 end) end
end
local function setNoclip(on)
 local c=LP.Character if not c then return end
 for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=not on end end
end

local introDone=false
local function runIntro(done)
 if (Config and Config.SkipIntro) or introDone then done(); return end
 introDone=true
 local sg=Instance.new("ScreenGui"); sg.Name="SpinachIntro"; sg.IgnoreGuiInset=true; sg.Parent=CoreGui
 local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(6,6,8); bg.BorderSizePixel=0; bg.Parent=sg
 local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,36); title.Position=UDim2.new(0,0,.38,0); title.BackgroundTransparency=1; title.Text="SPINACH"; title.TextColor3=(Config and Config.Accent) or Color3.fromRGB(0,200,130); title.Font=Enum.Font.GothamBold; title.TextSize=34; title.Parent=bg
 local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,0,0,22); sub.Position=UDim2.new(0,0,.38,38); sub.BackgroundTransparency=1; sub.Text="FTAP // HVH"; sub.TextColor3=Color3.fromRGB(170,170,180); sub.Font=Enum.Font.Gotham; sub.TextSize=14; sub.Parent=bg
 local st=Instance.new("TextLabel"); st.Size=UDim2.new(1,0,0,18); st.Position=UDim2.new(0,0,.52,0); st.BackgroundTransparency=1; st.Text="Initializing Core..."; st.TextColor3=Color3.fromRGB(110,110,120); st.Font=Enum.Font.Gotham; st.TextSize=12; st.Parent=bg
 task.spawn(function() task.wait(.25);st.Text="Loading Modules...";task.wait(.3);st.Text="Loading Visuals...";task.wait(.25);st.Text="Loading Config...";task.wait(.22);st.Text="Ready";task.wait(.18);TweenService:Create(bg,TweenInfo.new(.28),{BackgroundTransparency=1}):Play();title.TextTransparency=1;sub.TextTransparency=1;st.TextTransparency=1;task.wait(.3);sg:Destroy();done() end)
end

local function accent() return (Config and Config.Accent) or Color3.fromRGB(0,200,130) end
local function card(parent,titleText)
 local f=Instance.new("Frame");f.BackgroundColor3=Color3.fromRGB(18,18,22);f.BorderSizePixel=0;f.Size=UDim2.new(1,0,0,0);f.AutomaticSize=Enum.AutomaticSize.Y;f.Parent=parent;Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
 local pad=Instance.new("UIPadding",f);pad.PaddingTop=UDim.new(0,8);pad.PaddingBottom=UDim.new(0,8);pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);Instance.new("UIListLayout",f).Padding=UDim.new(0,5)
 if titleText then local t=Instance.new("TextLabel");t.Size=UDim2.new(1,0,0,16);t.BackgroundTransparency=1;t.Text=titleText:upper();t.TextColor3=accent();t.Font=Enum.Font.GothamBold;t.TextSize=11;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=f end
 return f
end
local function toggle(parent,label,key,cb)
 local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,22);row.BackgroundTransparency=1;row.Parent=parent
 local lab=Instance.new("TextLabel");lab.Size=UDim2.new(1,-36,1,0);lab.BackgroundTransparency=1;lab.Text=label;lab.TextColor3=Color3.fromRGB(200,200,210);lab.Font=Enum.Font.Gotham;lab.TextSize=11;lab.TextXAlignment=Enum.TextXAlignment.Left;lab.Parent=row
 local b=Instance.new("TextButton");b.Size=UDim2.new(0,28,0,14);b.Position=UDim2.new(1,-28,.5,-7);b.BackgroundColor3=Config[key] and accent() or Color3.fromRGB(45,45,52);b.Text="";b.Parent=row;Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
 local kn=Instance.new("Frame");kn.Size=UDim2.new(0,10,0,10);kn.Position=Config[key] and UDim2.new(1,-12,.5,-5) or UDim2.new(0,2,.5,-5);kn.BackgroundColor3=Color3.fromRGB(240,240,245);kn.BorderSizePixel=0;kn.Parent=b;Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
 b.MouseButton1Click:Connect(function() Config[key]=not Config[key];b.BackgroundColor3=Config[key] and accent() or Color3.fromRGB(45,45,52);kn.Position=Config[key] and UDim2.new(1,-12,.5,-5) or UDim2.new(0,2,.5,-5);if cb then cb(Config[key]) end end)
end
local function slider(parent,label,key,min,max,cb)
 local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,34);row.BackgroundTransparency=1;row.Parent=parent
 local lab=Instance.new("TextLabel");lab.Size=UDim2.new(.55,0,0,14);lab.BackgroundTransparency=1;lab.Text=label;lab.TextColor3=Color3.fromRGB(200,200,210);lab.Font=Enum.Font.Gotham;lab.TextSize=11;lab.TextXAlignment=Enum.TextXAlignment.Left;lab.Parent=row
 local val=Instance.new("TextLabel");val.Size=UDim2.new(.45,0,0,14);val.Position=UDim2.new(.55,0,0,0);val.BackgroundTransparency=1;val.Text=tostring(Config[key]);val.TextColor3=accent();val.Font=Enum.Font.GothamBold;val.TextSize=11;val.TextXAlignment=Enum.TextXAlignment.Right;val.Parent=row
 local bar=Instance.new("Frame");bar.Size=UDim2.new(1,0,0,4);bar.Position=UDim2.new(0,0,0,20);bar.BackgroundColor3=Color3.fromRGB(40,40,48);bar.BorderSizePixel=0;bar.Parent=row;Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
 local fill=Instance.new("Frame");fill.Size=UDim2.new(math.clamp((Config[key]-min)/math.max(max-min,1),0,1),0,1,0);fill.BackgroundColor3=accent();fill.BorderSizePixel=0;fill.Parent=bar;Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
 local sliding=false
 bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true end end)
 UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
 UserInputService.InputChanged:Connect(function(i) if not sliding then return end;if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end;local rel=math.clamp((i.Position.X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1);local v=math.floor(min+(max-min)*rel+.5);Config[key]=v;fill.Size=UDim2.new(rel,0,1,0);val.Text=tostring(v);if cb then cb(v) end end)
end
local function btn(parent,label,fn)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,24);b.BackgroundColor3=Color3.fromRGB(0,85,60);b.BorderSizePixel=0;b.Text=label;b.TextColor3=Color3.fromRGB(230,230,235);b.Font=Enum.Font.GothamBold;b.TextSize=11;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,3);b.MouseButton1Click:Connect(function() if fn then fn() end end)
end
local function lbl(parent,text)
 local t=Instance.new("TextLabel");t.Size=UDim2.new(1,0,0,14);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color3.fromRGB(130,130,140);t.Font=Enum.Font.Gotham;t.TextSize=10;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent
end
local function makePage(name,subtitle)
 local page=Instance.new("ScrollingFrame");page.Name=name;page.Size=UDim2.new(1,0,1,0);page.BackgroundTransparency=1;page.BorderSizePixel=0;page.ScrollBarThickness=3;page.ScrollBarImageColor3=accent();page.AutomaticCanvasSize=Enum.AutomaticSize.Y;page.CanvasSize=UDim2.new(0,0,0,0);page.Visible=false
 local pad=Instance.new("UIPadding",page);pad.PaddingTop=UDim.new(0,10);pad.PaddingLeft=UDim.new(0,14);pad.PaddingRight=UDim.new(0,14);pad.PaddingBottom=UDim.new(0,14);Instance.new("UIListLayout",page).Padding=UDim.new(0,10)
 local head=Instance.new("Frame");head.Size=UDim2.new(1,0,0,42);head.BackgroundTransparency=1;head.Parent=page
 local title=Instance.new("TextLabel");title.Size=UDim2.new(1,0,0,20);title.BackgroundTransparency=1;title.Text=name:upper();title.TextColor3=Color3.fromRGB(235,235,240);title.Font=Enum.Font.GothamBold;title.TextSize=18;title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=head
 local sub=Instance.new("TextLabel");sub.Size=UDim2.new(1,0,0,16);sub.Position=UDim2.new(0,0,0,22);sub.BackgroundTransparency=1;sub.Text=subtitle or "";sub.TextColor3=Color3.fromRGB(120,120,130);sub.Font=Enum.Font.Gotham;sub.TextSize=12;sub.TextXAlignment=Enum.TextXAlignment.Left;sub.Parent=head
 local cols=Instance.new("Frame");cols.Size=UDim2.new(1,0,0,0);cols.AutomaticSize=Enum.AutomaticSize.Y;cols.BackgroundTransparency=1;cols.Parent=page
 local grid=Instance.new("UIListLayout",cols);grid.FillDirection=Enum.FillDirection.Horizontal;grid.Padding=UDim.new(0,12)
 local left=Instance.new("Frame");left.Size=UDim2.new(.5,-6,0,0);left.AutomaticSize=Enum.AutomaticSize.Y;left.BackgroundTransparency=1;left.Parent=cols;Instance.new("UIListLayout",left).Padding=UDim.new(0,8)
 local right=Instance.new("Frame");right.Size=UDim2.new(.5,-6,0,0);right.AutomaticSize=Enum.AutomaticSize.Y;right.BackgroundTransparency=1;right.Parent=cols;Instance.new("UIListLayout",right).Padding=UDim.new(0,8)
 UI.Pages[name]={page=page,left=left,right=right};return UI.Pages[name]
end
local function switch(name) for n,d in pairs(UI.Pages) do d.page.Visible=(n==name) end end

local function buildGUI()
 if UI.Gui then UI.Gui:Destroy() end
 UI.Gui=Instance.new("ScreenGui");UI.Gui.Name="SpinachUI";UI.Gui.ResetOnSpawn=false;UI.Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;UI.Gui.Parent=CoreGui
 local main=Instance.new("Frame");main.Size=UDim2.new(0,960,0,540);main.Position=UDim2.new(.5,-480,.5,-270);main.BackgroundColor3=Color3.fromRGB(10,10,12);main.BorderSizePixel=0;main.Parent=UI.Gui;Instance.new("UICorner",main).CornerRadius=UDim.new(0,6)
 local stroke=Instance.new("UIStroke",main);stroke.Color=Color3.fromRGB(32,32,38);stroke.Thickness=1
 local tb=Instance.new("Frame");tb.Size=UDim2.new(1,0,0,34);tb.BackgroundColor3=Color3.fromRGB(14,14,17);tb.BorderSizePixel=0;tb.Parent=main;Instance.new("UICorner",tb).CornerRadius=UDim.new(0,6)
 local logo=Instance.new("Frame");logo.Size=UDim2.new(0,12,0,12);logo.Position=UDim2.new(0,12,.5,-6);logo.BackgroundColor3=accent();logo.BorderSizePixel=0;logo.Parent=tb;Instance.new("UICorner",logo).CornerRadius=UDim.new(0,2)
 local title=Instance.new("TextLabel");title.Size=UDim2.new(0,260,1,0);title.Position=UDim2.new(0,32,0,0);title.BackgroundTransparency=1;title.Text="SPINACH  //  FTAP HVH  v"..((Config and Config.Version) or "?");title.TextColor3=Color3.fromRGB(230,230,235);title.Font=Enum.Font.GothamBold;title.TextSize=13;title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=tb
 local close=Instance.new("TextButton");close.Size=UDim2.new(0,34,0,34);close.Position=UDim2.new(1,-34,0,0);close.BackgroundTransparency=1;close.Text="×";close.TextColor3=Color3.fromRGB(150,150,160);close.Font=Enum.Font.GothamBold;close.TextSize=18;close.Parent=tb;close.MouseButton1Click:Connect(function() UI.Gui.Enabled=false end)
 tb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;dragStart=i.Position;startPos=main.Position;i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
 tb.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-dragStart;main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
 local side=Instance.new("ScrollingFrame");side.Size=UDim2.new(0,128,1,-34);side.Position=UDim2.new(0,0,0,34);side.BackgroundColor3=Color3.fromRGB(12,12,15);side.BorderSizePixel=0;side.ScrollBarThickness=2;side.CanvasSize=UDim2.new(0,0,0,480);side.Parent=main
 local contentFrame=Instance.new("Frame");contentFrame.Size=UDim2.new(1,-128,1,-34);contentFrame.Position=UDim2.new(0,128,0,34);contentFrame.BackgroundColor3=Color3.fromRGB(10,10,12);contentFrame.BorderSizePixel=0;contentFrame.Parent=main
 local names={{"Home","Overview and quick actions"},{"Player","Local character and camera"},{"Combat","Throw, auras, line — strength is config only"},{"Defense","Antis and protection"},{"Target","Shared target manager"},{"Blobman","Blobman control"},{"Toys","Toy aura and barriers"},{"Visual","ESP and HUD"},{"Misc","Detectors and extras"},{"Settings","Menu and notifications"}}
 for _,info in ipairs(names) do local d=makePage(info[1],info[2]);d.page.Parent=contentFrame end

 do local p=UI.Pages.Home;local c1=card(p.left,"Server");lbl(c1,"Players / Ping / FPS live");lbl(c1,"Version "..((Config and Config.Version) or "?"));local c2=card(p.left,"Protection");lbl(c2,"Anti Grab / Anti Gucci / Anti Lag");local c3=card(p.right,"Quick Actions")
  btn(c3,"Emergency Escape",function() local ge=game:GetService("ReplicatedStorage"):FindFirstChild("GrabEvents");local eg=ge and ge:FindFirstChild("EndGrabEarly");pcall(function() if eg then eg:FireServer() end end);local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid");if h then h.PlatformStand=false;pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end;if SpinachRef then SpinachRef.Notify("Emergency Escape","",false) end end)
  btn(c3,"Reset Character",function() local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid");if h then h.Health=0 end end)
  btn(c3,"Clear Target",function() if TargetManager then TargetManager.ClearTarget() end end)
  btn(c3,"Disable Combat",function() Config.SuperThrow=false;if Combat then Combat.DisableSuperThrow() end;Config.FlingAura=false;Config.RagdollAura=false;if SpinachRef then SpinachRef.Notify("Combat","disabled",false) end end)
 end
 do local p=UI.Pages.Player;local c1=card(p.left,"Values");slider(c1,"Walk Speed","WalkSpeed",16,80,applyStats);slider(c1,"Jump Power","JumpPower",50,120,applyStats);local c2=card(p.left,"Character");toggle(c2,"Noclip","Noclip",setNoclip);toggle(c2,"Infinite Jump","InfJump");local c3=card(p.right,"Camera / Third Person");toggle(c3,"Third Person","ThirdPerson",function(v) if v then enableThirdPerson() else disableThirdPerson() end end);slider(c3,"TP Distance","TPDistance",4,20);slider(c3,"TP Shoulder","TPShoulder",-5,5);slider(c3,"TP Height","TPHeight",0,5);toggle(c3,"Camera Collision","TPCollision");slider(c3,"FOV","FOV",50,120,function(v) local cam=Workspace.CurrentCamera;if cam and not Config.ThirdPerson then cam.FieldOfView=v end end) end
 do local p=UI.Pages.Combat;local c1=card(p.left,"Throw (config only)");toggle(c1,"Super Throw","SuperThrow",function(v) if Combat then if v then Combat.EnableSuperThrow() else Combat.DisableSuperThrow() end end end);slider(c1,"Throw Multiplier","ThrowMult",1,8);slider(c1,"Strength Value","StrengthValue",1,10);toggle(c1,"Super Strength","SuperStrength");toggle(c1,"Grab Reach","GrabReach");slider(c1,"Max Grab Reach","MaxGrabReach",20,45);local c2=card(p.left,"Fling Modes");toggle(c2,"Fling Up","FlingUp");toggle(c2,"Slam","Slam");toggle(c2,"Void Fling","VoidFling");toggle(c2,"Spin Fling","SpinFling");local c3=card(p.right,"Auras");toggle(c3,"Fling Aura","FlingAura");toggle(c3,"Ragdoll Aura","RagdollAura");toggle(c3,"Sit Aura","SitAura");toggle(c3,"Spin Aura","SpinAura");toggle(c3,"Bring Aura","BringAura");slider(c3,"Aura Range","AuraRange",10,60);slider(c3,"Aura CD","AuraCD",.2,2);local c4=card(p.right,"Actions");btn(c4,"Fling Nearest",function() if TargetManager and Combat then local n=TargetManager.GetNearest(80);if n then Combat.FlingPlayer(n) end end end);btn(c4,"Fling Target",function() if TargetManager and Combat then local t=TargetManager.GetTarget();if t then Combat.FlingPlayer(t) end end end) end
 do local p=UI.Pages.Defense;local c1=card(p.left,"Antis");toggle(c1,"Anti Grab","AntiGrab");toggle(c1,"[GUCCI] Anti Grab","AntiGrabGucci");toggle(c1,"Anti Gucci","AntiGucci");toggle(c1,"Anti Blobman","AntiBlobman");toggle(c1,"Anti Fling","AntiFling");toggle(c1,"Anti Ragdoll","AntiRagdoll");toggle(c1,"Instant Get Up","InstantGetUp");toggle(c1,"Anti Sit","AntiSit");toggle(c1,"Anti Void / Disable Void","AntiVoid");toggle(c1,"Anti Lag","AntiLag");local c2=card(p.right,"Anti Gucci Config");lbl(c2,"Interval-based; idle ≈ free");slider(c2,"Interval (x100ms)","AntiGucciInterval",5,40,function(v) Config.AntiGucciInterval=v/100 end);toggle(c2,"Emergency Only","AntiGucciEmergencyOnly");local c3=card(p.right,"Known limits");lbl(c3,"Anti Network Ownership: UNSUPPORTED");lbl(c3,"Net Owner Spam: UNSUPPORTED");lbl(c3,"Noclip Barrier: architecture only") end
 do local p=UI.Pages.Target;local c1=card(p.left,"Selection");toggle(c1,"Nearest Target","NearestTarget");toggle(c1,"Target Lock","TargetLock");toggle(c1,"Friend Whitelist","FriendWL");slider(c1,"Distance Limit","DistLimit",50,400);local c2=card(p.right,"Actions");btn(c2,"Clear Target",function() if TargetManager then TargetManager.ClearTarget() end end) end
 do local p=UI.Pages.Blobman;local c1=card(p.left,"Control");toggle(c1,"Blob Loop","BlobLoop");toggle(c1,"Blob Grab All","BlobGrabAll");local c2=card(p.right,"Defense");toggle(c2,"Anti Blobman","AntiBlobman");lbl(c2,"Net Owner Spam: UNSUPPORTED") end
 do local p=UI.Pages.Toys;local c1=card(p.left,"Toy Aura");lbl(c1,"Shapes / grab all — expand next");local c2=card(p.right,"Barrier");toggle(c2,"Noclip Barrier (plot)","NoclipBarrier");lbl(c2,"NOT character noclip") end
 do local p=UI.Pages.Visual;local c1=card(p.left,"Player ESP");toggle(c1,"Player ESP","PlayerESP");toggle(c1,"Distance","DistESP");toggle(c1,"Health","HealthESP");toggle(c1,"Target ESP","TargetESP");toggle(c1,"Rainbow","Rainbow");slider(c1,"Max Distance","ESPMaxDist",100,800);local c2=card(p.right,"HUD");lbl(c2,"FPS / events via VisualManager") end
 do local p=UI.Pages.Misc;local c1=card(p.left,"Notes");lbl(c1,"Crazy Line: not random CFrame");lbl(c1,"Detectors: heuristic only") end
 do local p=UI.Pages.Settings;local c1=card(p.left,"Menu");toggle(c1,"Skip Intro","SkipIntro");toggle(c1,"Notifications","NotifEnabled");local c2=card(p.right,"Test");btn(c2,"Test Notification",function() if SpinachRef then SpinachRef.Notify("Test","OK",false) end end) end

 for i,info in ipairs(names) do local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,28);b.Position=UDim2.new(0,0,0,(i-1)*30+6);b.BackgroundColor3=Color3.fromRGB(12,12,15);b.BorderSizePixel=0;b.Text="  "..info[1];b.TextColor3=Color3.fromRGB(150,150,160);b.Font=Enum.Font.Gotham;b.TextSize=12;b.TextXAlignment=Enum.TextXAlignment.Left;b.Parent=side;b.MouseButton1Click:Connect(function() switch(info[1]);for _,ch in ipairs(side:GetChildren()) do if ch:IsA("TextButton") then ch.TextColor3=Color3.fromRGB(150,150,160);ch.BackgroundColor3=Color3.fromRGB(12,12,15) end end;b.TextColor3=accent();b.BackgroundColor3=Color3.fromRGB(20,20,24) end);if i==1 then b.TextColor3=accent();b.BackgroundColor3=Color3.fromRGB(20,20,24) end end
 switch("Home")
 UserInputService.InputBegan:Connect(function(input,gpe) if gpe then return end;if Config and input.KeyCode==Config.MenuKey then UI.Gui.Enabled=not UI.Gui.Enabled end end)
end

function UI.Init(spinach)
 SpinachRef=spinach;Config=spinach.Get("config.lua");TargetManager=spinach.Get("TargetManager.lua");Combat=spinach.Get("combat.lua");Defense=spinach.Get("defense.lua")
 local function onChar() task.wait(.2);applyStats();if Config and Config.Noclip then setNoclip(true) end;if Config and Config.ThirdPerson then disableThirdPerson();enableThirdPerson() end end
 if LP.Character then onChar() end
 spinach.Connect(LP.CharacterAdded,onChar)
 spinach.Connect(UserInputService.JumpRequest,function() if Config and Config.InfJump then local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid");if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
 runIntro(function() buildGUI();if Config and Config.ThirdPerson then enableThirdPerson() end;if Config and Config.SuperThrow and Combat then Combat.EnableSuperThrow() end;if TargetManager then spinach.Connect(RunService.Heartbeat,function() TargetManager.Update() end) end end)
end
function UI.Destroy() disableThirdPerson();if UI.Gui then UI.Gui:Destroy();UI.Gui=nil end end
return UI
