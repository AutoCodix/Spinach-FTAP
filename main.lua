--[[
    SPINACH // FTAP HVH
    Bootstrap loader — entry point
    Raw: https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/main.lua
]]

local VERSION = "0.2.0"
local BASE = "https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/"
local CACHE_BUST = true

if shared.Spinach and type(shared.Spinach.Destroy) == "function" then
    pcall(function() shared.Spinach.Destroy() end)
end

local Spinach = {Version=VERSION,Modules={},Connections={},Destroyed=false}
shared.Spinach = Spinach

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local function ensureNotifHost()
    local existing = CoreGui:FindFirstChild("SpinachNotifHost")
    if existing then return existing end
    local sg = Instance.new("ScreenGui")
    sg.Name = "SpinachNotifHost"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
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
Spinach.Notify=notify

local LOAD_ORDER={"config.lua","ConfigManager.lua","TargetManager.lua","VisualManager.lua","ui.lua","combat.lua","defense.lua","visuals.lua","toys.lua","misc.lua"}

local function loadModule(path)
    if Spinach.Destroyed then return nil,"destroyed" end
    if Spinach.Modules[path]~=nil then return Spinach.Modules[path],nil end
    local url=BASE..path
    if CACHE_BUST then url=url.."?v="..tostring(os.clock()).."_"..tostring(math.random(1000,9999)) end
    local httpOK,source=pcall(function() return game:HttpGet(url) end)
    if not httpOK then local err="HTTP FAILED: "..tostring(source);notify("SPINACH LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    if type(source)~="string" then local err="HTTP returned "..typeof(source);notify("SPINACH LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    if #source==0 or source:match("^%s*$") then local err="FILE EMPTY OR WHITESPACE";notify("SPINACH LOAD ERROR","Module: "..path.."\nStage: download\nReason: "..err,true);return nil,err end
    local chunk,compileError=loadstring(source)
    if not chunk then local err=tostring(compileError);notify("SPINACH LOAD ERROR","Module: "..path.."\nStage: compile\nReason: "..err,true);return nil,err end
    local runOK,result=pcall(chunk)
    if not runOK then local err=tostring(result);notify("SPINACH LOAD ERROR","Module: "..path.."\nStage: runtime\nReason: "..err,true);return nil,err end
    Spinach.Modules[path]=result
    return result,nil
end

function Spinach.Get(path) return Spinach.Modules[path] end
function Spinach.Connect(signal,fn)
    if Spinach.Destroyed then return nil end
    local c=signal:Connect(fn);table.insert(Spinach.Connections,c);return c
end
function Spinach.Destroy()
    if Spinach.Destroyed then return end
    Spinach.Destroyed=true
    for _,c in ipairs(Spinach.Connections) do pcall(function() c:Disconnect() end) end
    Spinach.Connections={}
    for _,mod in pairs(Spinach.Modules) do if type(mod)=="table" and type(mod.Destroy)=="function" then pcall(function() mod.Destroy() end) end end
    Spinach.Modules={}
    for _,name in ipairs({"SpinachNotifHost","SpinachUI","SpinachIntro"}) do local x=CoreGui:FindFirstChild(name);if x then x:Destroy() end end
    if shared.Spinach==Spinach then shared.Spinach=nil end
end

local function bootstrap()
    notify("SPINACH","v"..VERSION.." loading…",false)
    local failed=0
    for _,path in ipairs(LOAD_ORDER) do local _,err=loadModule(path);if err then failed+=1 end end
    local initOrder={"config.lua","ConfigManager.lua","TargetManager.lua","VisualManager.lua","combat.lua","defense.lua","visuals.lua","toys.lua","misc.lua","ui.lua"}
    for _,path in ipairs(initOrder) do
        local mod=Spinach.Modules[path]
        if type(mod)=="table" and type(mod.Init)=="function" then
            local ok,err=pcall(function() mod.Init(Spinach) end)
            if not ok then notify("SPINACH INIT ERROR","Module: "..path.."\n"..tostring(err),true);failed+=1 end
        end
    end
    if failed==0 then notify("SPINACH","Ready v"..VERSION,false) else notify("SPINACH","Loaded with "..failed.." error(s)",true) end
end

local ok,err=pcall(bootstrap)
if not ok then notify("SPINACH FATAL",tostring(err),true) end
return Spinach
