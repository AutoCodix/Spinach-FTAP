--[[ PlayerController — movement + native Roblox third-person camera ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")

local LP=Players.LocalPlayer
local Controller={Connections={},Original=nil}
local Config=nil
local Spinach=nil

local function char() return LP.Character end
local function hum() local c=char();return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c=char();return c and c:FindFirstChild("HumanoidRootPart") end
local function conn(c)table.insert(Controller.Connections,c);return c end

local function saveOriginal()
 if Controller.Original then return end
 local cam=Workspace.CurrentCamera
 Controller.Original={
  CameraMode=LP.CameraMode,
  MinZoom=LP.CameraMinZoomDistance,
  MaxZoom=LP.CameraMaxZoomDistance,
  CameraType=cam and cam.CameraType,
  CameraSubject=cam and cam.CameraSubject,
  FOV=cam and cam.FieldOfView or 70,
 }
end

local function forceBodyVisible()
 local c=char();if not c then return end
 for _,v in ipairs(c:GetDescendants()) do
  if v:IsA("BasePart") then v.LocalTransparencyModifier=0 end
 end
end

function Controller.SetThirdPerson(on)
 if not Config then return end
 Config.ThirdPerson=on
 local cam=Workspace.CurrentCamera
 if on then
  saveOriginal()
  LP.CameraMode=Enum.CameraMode.Classic
  local h=hum()
  if cam then
   cam.CameraType=Enum.CameraType.Custom
   if h then cam.CameraSubject=h end
   cam.FieldOfView=Config.FOV or 70
  end
  local start=math.clamp(Config.TPDistance or 8,1,Config.TPMaxZoom or 32)
  LP.CameraMinZoomDistance=start
  LP.CameraMaxZoomDistance=start
  forceBodyVisible()
  task.defer(function()
   if not Config or not Config.ThirdPerson then return end
   LP.CameraMode=Enum.CameraMode.Classic
   LP.CameraMinZoomDistance=Config.TPMinZoom or 0.5
   LP.CameraMaxZoomDistance=Config.TPMaxZoom or 32
  end)
 else
  local o=Controller.Original
  if o then
   LP.CameraMode=o.CameraMode or Enum.CameraMode.Classic
   LP.CameraMinZoomDistance=o.MinZoom or 0.5
   LP.CameraMaxZoomDistance=o.MaxZoom or 12.5
   if cam then
    cam.CameraType=o.CameraType or Enum.CameraType.Custom
    cam.CameraSubject=o.CameraSubject or hum()
   end
  else
   LP.CameraMode=Enum.CameraMode.Classic
   if cam then cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=hum() end
  end
 end
end

function Controller.RestoreCamera()
 if Config then Config.ThirdPerson=false end
 Controller.SetThirdPerson(false)
 local cam=Workspace.CurrentCamera
 if cam and Controller.Original then cam.FieldOfView=Controller.Original.FOV or 70 end
 Controller.Original=nil
end

local function applyMovement()
 if not Config then return end
 local h=hum();local r=root()
 if h then
  if Config.SpeedEnabled then h.WalkSpeed=Config.WalkSpeed or 16 end
  if Config.JumpEnabled then
   h.UseJumpPower=true
   h.JumpPower=Config.JumpPower or 50
  end
 end
 if r then
  if Config.CharSpin then
   r.AssemblyAngularVelocity=Vector3.new(0,Config.SpinSpeed or 12,0)
  elseif r.AssemblyAngularVelocity.Y~=0 and math.abs(r.AssemblyAngularVelocity.Y)<100 then
   -- don't continuously fight game physics; only clear our moderate spin range
  end
  if Config.Flight then
   local cam=Workspace.CurrentCamera
   if cam then
    local move=Vector3.zero
    local look=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
    local right=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
    if look.Magnitude>0 then look=look.Unit end
    if right.Magnitude>0 then right=right.Unit end
    if UIS:IsKeyDown(Enum.KeyCode.W) then move+=look end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move-=look end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move+=right end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move-=right end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move-=Vector3.yAxis end
    if move.Magnitude>0 then move=move.Unit end
    r.AssemblyLinearVelocity=move*(Config.FlightSpeed or 50)
   end
  end
 end
end

local function applyNoclip()
 if not Config or not Config.Noclip then return end
 local c=char();if not c then return end
 for _,v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
end

local function cameraTick()
 if not Config then return end
 local cam=Workspace.CurrentCamera
 if not cam then return end
 cam.FieldOfView=Config.FOV or 70
 if Config.ThirdPerson then
  LP.CameraMode=Enum.CameraMode.Classic
  LP.CameraMinZoomDistance=Config.TPMinZoom or 0.5
  LP.CameraMaxZoomDistance=Config.TPMaxZoom or 32
  cam.CameraType=Enum.CameraType.Custom
  local h=hum();if h then cam.CameraSubject=h end
  forceBodyVisible()
 end
end

function Controller.Init(spinach)
 Spinach=spinach;Config=spinach.Get("config.lua")
 conn(RunService.Heartbeat:Connect(applyMovement))
 conn(RunService.Stepped:Connect(applyNoclip))
 conn(RunService.RenderStepped:Connect(cameraTick))
 conn(LP.CharacterAdded:Connect(function()
  task.wait(.25)
  if Config and Config.ThirdPerson then Controller.SetThirdPerson(true) end
 end))
 conn(UIS.JumpRequest:Connect(function()
  if Config and Config.InfJump then local h=hum();if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
 end))
 if Config and Config.ThirdPerson then Controller.SetThirdPerson(true) end
end

function Controller.Destroy()
 Controller.RestoreCamera()
 for _,c in ipairs(Controller.Connections) do pcall(function() c:Disconnect() end) end
 Controller.Connections={}
end

return Controller
