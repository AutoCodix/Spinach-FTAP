print("[SPINACH] SCRIPT EXECUTED")

local BASE = "https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/"

local function loadFile(path)
    print("[SPINACH] Downloading:", path)

    local ok, source = pcall(function()
        return game:HttpGet(BASE .. path)
    end)

    if not ok then
        warn("[SPINACH] HTTP FAILED:", path, source)
        return nil
    end

    print("[SPINACH] Downloaded:", path, "bytes:", #source)

    local fn, compileError = loadstring(source)

    if not fn then
        warn("[SPINACH] COMPILE FAILED:", path, compileError)
        return nil
    end

    local runOk, result = pcall(fn)

    if not runOk then
        warn("[SPINACH] RUNTIME FAILED:", path, result)
        return nil
    end

    print("[SPINACH] Loaded:", path)
    return result
end

print("[SPINACH] Starting...")

local Config = loadFile("config.lua")
local TargetManager = loadFile("TargetManager.lua")
local VisualManager = loadFile("VisualManager.lua")
local ConfigManager = loadFile("ConfigManager.lua")

local UI = loadFile("ui.lua")
local Combat = loadFile("combat.lua")
local Defense = loadFile("defense.lua")
local Visuals = loadFile("visuals.lua")
local Toys = loadFile("toys.lua")
local Misc = loadFile("misc.lua")

print("[SPINACH] FINISHED LOADING")
