--[[ WorldController — local lighting/world visuals ]]
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")

local World={Conn=nil,Original=nil,State={Fullbright=false,NoFog=false,NoShadows=false}}
local Config=nil

local function capture()
 if World.Original then return end
 World.Original={
  Brightness=Lighting.Brightness,
  Ambient=Lighting.Ambient,
  OutdoorAmbient=Lighting.OutdoorAmbient,
  FogEnd=Lighting.FogEnd,
  GlobalShadows=Lighting.GlobalShadows,
  ClockTime=Lighting.ClockTime,
 }
end

local function tickWorld()
 if not Config then return end
 capture()
 if Config.Fullbright then
  Lighting.Brightness=3
  Lighting.Ambient=Color3.fromRGB(190,190,190)
  Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
 elseif World.State.Fullbright then
  Lighting.Brightness=World.Original.Brightness
  Lighting.Ambient=World.Original.Ambient
  Lighting.OutdoorAmbient=World.Original.OutdoorAmbient
 end
 if Config.NoFog then Lighting.FogEnd=100000 elseif World.State.NoFog then Lighting.FogEnd=World.Original.FogEnd end
 if Config.NoShadows then Lighting.GlobalShadows=false elseif World.State.NoShadows then Lighting.GlobalShadows=World.Original.GlobalShadows end
 if Config.CustomTime then Lighting.ClockTime=Config.ClockTime or 14 elseif World.State.CustomTime then Lighting.ClockTime=World.Original.ClockTime end
 World.State.Fullbright=Config.Fullbright
 World.State.NoFog=Config.NoFog
 World.State.NoShadows=Config.NoShadows
 World.State.CustomTime=Config.CustomTime
end

function World.Init(spinach)
 Config=spinach.Get("config.lua")
 capture()
 World.Conn=RunService.RenderStepped:Connect(tickWorld)
 table.insert(spinach.Connections,World.Conn)
end

function World.Destroy()
 if World.Conn then pcall(function()World.Conn:Disconnect()end);World.Conn=nil end
 if World.Original then
  Lighting.Brightness=World.Original.Brightness
  Lighting.Ambient=World.Original.Ambient
  Lighting.OutdoorAmbient=World.Original.OutdoorAmbient
  Lighting.FogEnd=World.Original.FogEnd
  Lighting.GlobalShadows=World.Original.GlobalShadows
  Lighting.ClockTime=World.Original.ClockTime
 end
end

return World
