--[[
    PENGU // FTAP HVH
    Bootstrap loader — entry point
    Raw: https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/main.lua
]]

local VERSION = "0.3.1"
local BASE = "https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/"
local CACHE_BUST = true

if shared.Spinach and type(shared.Spinach.Destroy) == "function" then
    pcall(function() shared.Spinach.Destroy() end)
    shared.Spinach = nil
end

if shared.Pengu and type(shared.Pengu.Destroy) == "function" then
    pcall(function() shared.Pengu.Destroy() end)
end

local Pengu = {Version=VERSION,Modules={},Connections={},Destroyed=false}
shared.Pengu = Pengu

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local function ensureNotifHost()
    local existing = CoreGui:FindFirstChild("PenguNotifHost")
    if existing then return existing end
    local sg = Instance.new("ScreenGui")
    sg.Name = "PenguNotifHost"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = CoreGui
    return sg
end

local function notify(title, body, isError)
    local host = ensureNotifHost()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,320,0,0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = UDim2.new(1,-340,0,20+(#host:GetChildren()*8))
    frame.BackgroundColor3 = Color3.fromRGB(16,16,20); frame.BorderSizePixel = 0; frame.Parent = host
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)
    local stroke=Instance.new("UIStroke",frame); stroke.Color=isError and Color3.fromRGB(220,60,60) or Color3.fromRGB(0,200,130); stroke.Thickness=1
    local pad=Instance.new("UIPadding",frame); pad.PaddingTop=UDim.new(0,10);pad.PaddingBottom=UDim.new(0,10);pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12)
    local list=Instance.new("UIListLayout",frame);list.Padding=UDim.new(0,4)
    local t=Instance.new("TextLabel");t.Size=UDim2.new(1,0,0,18);t.BackgroundTransparency=1;t.Text=title;t.TextColor3=isError and Color3.fromRGB(255,120,120) or Color3.fromRGB(0,220,150);t.Font=Enum.Font.GothamBold;t.TextSize=13;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=frame
    if body and body~="" then
        local b=Instance.new("TextLabel");b.Size=UDim2.new(1,0,0,0);b.AutomaticSize=Enum.AutomaticSize.Y;b.BackgroundTransparency=1;b.Text=body;b.TextColor3=Color3.fromRGB(200,200,210);b.Font=Enum.Font.Gotham;b.TextSize=11;b.TextWrapped=true;b.TextXAlignment=Enum.TextXAlignment.Left;b.Parent=frame
    end
    task.delay(isError and 8 or 3.5,function()
        if frame and frame.Parent then pcall(function() TweenService:Create(frame,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play();task.wait(0.3);frame:Destroy() end) end
    end)
end
Pengu.Notify=notify

local LOAD_ORDER={"config.lua","ConfigManager.lua","TargetManager.lua","VisualManager.lua","PlayerController.lua","WorldController.lua","ui.lua","combat.lua","defense.lua","visuals.lua","toys.lua","misc.lua"}

local function loadModule(path)
    if Pengu.Destroyed then return nil,"destroyed" end
    if Pengu.Modules[path]~=nil then return Pengu.Modules[path],nil end
    local url=BASE..path
    if CACHE_BUST then url=url.."?v="..tostring(os.clock()).."_"..tostring(math.random(1000,9999)) end
    local httpOK,source=pcall(function() return game:HttpGet(url) end)
    if not httpOK then local err="HTTP FAILED: "..tostring(source);notify("PENGU LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    if type(source)~="string" then local err="HTTP returned "..typeof(source);notify("PENGU LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    if #source==0 or source:match("^%s*$") then local err="FILE EMPTY OR WHITESPACE";notify("PENGU LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    local chunk,compileError=loadstring(source)
    if not chunk then local err=tostring(compileError);notify("PENGU LOAD ERROR","Module: "..path.."\nStage: compile\nReason: "..err,true);return nil,err end
    local runOK,result=pcall(chunk)
    if not runOK then local err=tostring(result);notify("PENGU LOAD ERROR","Module: "..path.."\nStage: runtime\nReason: "..err,true);return nil,err end
    Pengu.Modules[path]=result
    return result,nil
end

function Pengu.Get(path) return Pengu.Modules[path] end
function Pengu.Connect(signal,fn)
    if Pengu.Destroyed then return nil end
    local c=signal:Connect(fn);table.insert(Pengu.Connections,c);return c
end
function Pengu.Destroy()
    if Pengu.Destroyed then return end
    Pengu.Destroyed=true
    for _,c in ipairs(Pengu.Connections) do pcall(function() c:Disconnect() end) end
    Pengu.Connections={}
    for _,mod in pairs(Pengu.Modules) do if type(mod)=="table" and type(mod.Destroy)=="function" then pcall(function() mod.Destroy() end) end end
    Pengu.Modules={}
    for _,name in ipairs({"PenguNotifHost","PenguUI","PenguIntro","SpinachNotifHost","SpinachUI","SpinachIntro"}) do local x=CoreGui:FindFirstChild(name);if x then x:Destroy() end end
    if shared.Pengu==Pengu then shared.Pengu=nil end
end

local function bootstrap()
    notify("PENGU","v"..VERSION.." loading…",false)
    local failed=0
    for _,path in ipairs(LOAD_ORDER) do local _,err=loadModule(path);if err then failed+=1 end end
    local initOrder={"config.lua","ConfigManager.lua","TargetManager.lua","VisualManager.lua","PlayerController.lua","WorldController.lua","combat.lua","defense.lua","visuals.lua","toys.lua","misc.lua","ui.lua"}
    for _,path in ipairs(initOrder) do
        local mod=Pengu.Modules[path]
        if type(mod)=="table" and type(mod.Init)=="function" then
            local ok,err=pcall(function() mod.Init(Pengu) end)
            if not ok then notify("PENGU INIT ERROR","Module: "..path.."\n"..tostring(err),true);failed+=1 end
        end
    end
    if failed==0 then notify("PENGU","Ready v"..VERSION,false) else notify("PENGU","Loaded with "..failed.." error(s)",true) end
end

local ok,err=pcall(bootstrap)
if not ok then notify("PENGU FATAL",tostring(err),true) end
return Pengu
