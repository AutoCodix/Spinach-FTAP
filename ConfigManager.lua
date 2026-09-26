--[[ ConfigManager — save/load when executor provides file APIs ]]
local ConfigManager = {}
local SpinachRef = nil
local Config = nil

local function hasFileAPI()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

function ConfigManager.Init(spinach)
    SpinachRef = spinach
    Config = spinach.Get("config.lua")
    if type(Config) ~= "table" then return end
    if Config.AutoAntiLag then
        Config.AntiLag = true
    end
end

function ConfigManager.Get()
    return Config
end

function ConfigManager.Save(path)
    path = path or "spinach_config.json"
    if not hasFileAPI() then return false, "no file API" end
    if type(Config) ~= "table" then return false, "no config" end
    local ok, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        local dump = {}
        for k, v in pairs(Config) do
            local t = typeof(v)
            if t == "number" or t == "boolean" or t == "string" then
                dump[k] = v
            end
        end
        writefile(path, HttpService:JSONEncode(dump))
    end)
    return ok, err
end

function ConfigManager.Load(path)
    path = path or "spinach_config.json"
    if not hasFileAPI() then return false, "no file API" end
    if not isfile(path) then return false, "missing" end
    local ok, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        local data = HttpService:JSONDecode(readfile(path))
        if type(data) == "table" and type(Config) == "table" then
            for k, v in pairs(data) do
                if Config[k] ~= nil then Config[k] = v end
            end
        end
    end)
    return ok, err
end

function ConfigManager.Destroy() end

return ConfigManager
