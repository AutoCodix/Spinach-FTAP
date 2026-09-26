local BASE = "https://raw.githubusercontent.com/AutoCodix/Spinach-FTAP/main/"

local FILES = {
    "config.lua",
    "TargetManager.lua",
    "VisualManager.lua",
    "ConfigManager.lua",
    "ui.lua",
    "combat.lua",
    "defense.lua",
    "visuals.lua",
    "toys.lua",
    "misc.lua"
}

local function checkFile(path)
    local url = BASE .. path .. "?v=" .. tostring(os.time())

    -- 1. DOWNLOAD
    local httpOK, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not httpOK then
        return false, "HTTP REQUEST FAILED: " .. tostring(source)
    end

    -- 2. VERIFY CONTENT
    if type(source) ~= "string" then
        return false, "HTTP returned " .. typeof(source) .. " instead of source code"
    end

    if #source == 0 then
        return false, "FILE IS COMPLETELY EMPTY"
    end

    if source:match("^%s*$") then
        return false, "FILE ONLY CONTAINS WHITESPACE"
    end

    -- 3. COMPILE
    local chunk, compileError = loadstring(source)

    if not chunk then
        return false, "LUA COMPILE ERROR: " .. tostring(compileError)
    end

    -- 4. EXECUTE
    local runOK, result = pcall(chunk)

    if not runOK then
        return false, "RUNTIME ERROR: " .. tostring(result)
    end

    return true, {
        bytes = #source,
        returned = result
    }
end

print("========== SPINACH CHECK ==========")

local passed = 0
local failed = 0

for _, path in ipairs(FILES) do
    local ok, info = checkFile(path)

    if ok then
        passed += 1
        print(
            "[PASS]",
            path,
            "|",
            info.bytes,
            "bytes",
            "| returned:",
            typeof(info.returned)
        )
    else
        failed += 1
        warn("[FAIL]", path, "|", info)
    end
end

print("===================================")
print("PASSED:", passed)
print("FAILED:", failed)

if failed == 0 then
    print("[SPINACH] ALL FILES DOWNLOAD + COMPILE + EXECUTE")
else
    warn("[SPINACH] NOT READY - FIX FAILED FILES ABOVE")
end
