if _G.XTEAM_LOADER_LOADED then return end
_G.XTEAM_LOADER_LOADED = true

local LOADER_VERSION = "2.0"

-- ============ PACKAGES (har PUBG variant) ============
local PACKAGES = {
    "com.tencent.ig",       -- PUBG Global
    "com.pubg.krmobile",    -- PUBG KR
    "com.vng.pubgmobile",   -- PUBG VNG
    "com.rekoo.pubg",       -- PUBG Rekoo
    "com.pubg.imobile",     -- PUBG iMobile
    "com.tencent.igfit",    -- PUBG Fit
    "com.tencent.tmgp.pubgmhd", -- PUBG CN (Tencent)
    "com.pubg.newstate"     -- PUBG New State (agar)
}

-- ============ ROOT DIRS ============
-- Har root ke andar recursively scan hoga
local ROOT_DIRS = {}
for _, pkg in ipairs(PACKAGES) do
    ROOT_DIRS[#ROOT_DIRS + 1] = "/storage/emulated/0/Android/obb/" .. pkg .. "/"
    ROOT_DIRS[#ROOT_DIRS + 1] = "/sdcard/Android/obb/" .. pkg .. "/"
    ROOT_DIRS[#ROOT_DIRS + 1] = "/storage/emulated/0/Android/data/" .. pkg .. "/files/"
    ROOT_DIRS[#ROOT_DIRS + 1] = "/sdcard/Android/data/" .. pkg .. "/files/"
    ROOT_DIRS[#ROOT_DIRS + 1] = "/storage/emulated/0/Android/media/" .. pkg .. "/"
    ROOT_DIRS[#ROOT_DIRS + 1] = "/sdcard/Android/media/" .. pkg .. "/"
end

-- ============ HELPERS ============
local function log(msg)
    pcall(function() print("[loader_custom] " .. msg) end)
end

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*all")
    f:close()
    return c
end

-- Lua 5.1/5.2 dono ke liye directory listing
local function listDir(path)
    local sep = package.config:sub(1, 1)
    local isWindows = sep == "\\"
    local cmd = isWindows and ('dir "' .. path .. '" /b /a') or ('ls -a "' .. path .. '" 2>/dev/null')
    local p = io.popen(cmd)
    if not p then return {} end
    local out = {}
    for line in p:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and line ~= "." and line ~= ".." then
            out[#out + 1] = line
        end
    end
    p:close()
    return out
end

-- Recursive search for my.lua (with variants)
local function recursiveFindMyLua(root, maxDepth)
    maxDepth = maxDepth or 8
    if not root or root == "" then return nil end
    local tried = {}
    local function search(dir, depth)
        if depth > maxDepth then return nil end
        if tried[dir] then return nil end
        tried[dir] = true

        -- try direct files in this dir
        local variants = { "my.lua", "my.luac", "my.bytecode", "my.lua.txt" }
        for _, name in ipairs(variants) do
            local full = dir .. name
            if fileExists(full) then return full end
        end

        -- list subdirs
        local entries = listDir(dir)
        for _, name in ipairs(entries) do
            local full = dir .. name
            -- directory? try recurse
            if not name:match("%.") then
                local hit = search(full .. "/", depth + 1)
                if hit then return hit end
            end
            -- fallback: agar name .obb ya known file ho to skip
        end
        return nil
    end
    return search(root, 0)
end

-- ============ FIND my.lua ============
local function findMyLua()
    -- 1) manual override
    if _G.MY_LUA_PATH and fileExists(_G.MY_LUA_PATH) then
        return _G.MY_LUA_PATH
    end

    -- 2) direct known candidates (fast path)
    local fastCandidates = {
        "my.lua",
        "Paks/my.lua",
        "SAMEER/my.lua",
        "UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/my.lua",
        "UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/Paks/my.lua",
        "UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/AssetPaks/my.lua",
    }
    for _, root in ipairs(ROOT_DIRS) do
        for _, sub in ipairs(fastCandidates) do
            local full = root .. sub
            local variants = { full, full:gsub("%.lua$", ".luac"), full:gsub("%.lua$", ".bytecode"), full .. ".txt" }
            for _, v in ipairs(variants) do
                if fileExists(v) then return v end
            end
        end
    end

    -- 3) dynamic recursive scan (slow but universal)
    log("fast path miss — starting recursive scan")
    for _, root in ipairs(ROOT_DIRS) do
        local hit = recursiveFindMyLua(root, 8)
        if hit then return hit end
    end

    -- 4) absolute extra fallbacks
    local extras = {
        "/storage/emulated/0/SAMEER/my.lua",
        "/sdcard/SAMEER/my.lua",
    }
    for _, p in ipairs(extras) do
        if fileExists(p) then return p end
    end

    return nil
end

-- ============ LOAD my.lua ============
local function loadMyLua(path)
    local src = readFile(path)
    if not src then return nil, "cannot read " .. path end
    if #src == 0 then log("WARN: my.lua is empty") end

    local chunk, cerr
    if loadstring then
        chunk, cerr = loadstring(src, "@" .. path)
    else
        chunk, cerr = load(src, "@" .. path)
    end
    if not chunk then return nil, "compile error: " .. tostring(cerr) end

    if setfenv then
        local okEnv, env = pcall(getfenv, 1)
        if okEnv and type(env) == "table" then
            pcall(setfenv, chunk, env)
        end
    end

    local okRun, result = pcall(chunk)
    if not okRun then return nil, "runtime error: " .. tostring(result) end
    return result
end

-- ============ EXECUTE ============
local myPath = findMyLua()
if not myPath then
    log("FATAL: my.lua not found anywhere (Data/OBB/Media)")
else
    log("loading " .. myPath)
    local result, err = loadMyLua(myPath)
    if err then
        log("FATAL: " .. err)
    else
        if result == nil then log("WARN: my.lua returned nil") end
        log("loaded successfully (v" .. LOADER_VERSION .. ")")
    end
end
