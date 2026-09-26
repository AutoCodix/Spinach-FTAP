local BASE = "https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/"

local function loadFile(path)
    local source = game:HttpGet(BASE .. path)
    local fn, err = loadstring(source)

    if not fn then
        error("[SPINACH] Failed loading " .. path .. ": " .. tostring(err))
    end

    return fn()
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

print("[SPINACH] Loaded successfully.")
