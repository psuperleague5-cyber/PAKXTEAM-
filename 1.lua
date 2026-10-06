if _G.__PAKxTEAM_INJECTED then
    return
end
_G.__PAKxTEAM_INJECTED = true

-- ⬇⬇⬇ TERA PURA ORIGINAL CODE (JESA HAI WESA) ⬇⬇⬇

local API_BASE            = "https://tgowner.pythonanywhere.com"
local ADMIN_CONTACT       = "@TGOWNER7"
local TELEGRAM_LINK       = "https://t.me/TGOWNER7"
local KEY_FILES           = { "Xthrlen.txt", "key.txt", "tgo_key.txt" }
local HARDCODED_KEY       = ""
local OFFLINE_GRACE_HOURS = 12
local HEARTBEAT_SEC       = 90
local HTTP_TIMEOUT        = 10
local LOADER_MODE         = true
local CACHE_PAYLOAD       = true
local DEBUG_HTTP          = false
local SHOW_WELCOME_POPUP  = false
local SHOW_MOD_READY      = false
local ASK_KEY_EVERY_BOOT  = true
local TGO_VERSION         = "v6.0"

local TGO_FIRST_BOOT = not _G.TGO_BOOTED
_G.TGO_BOOTED = true
if TGO_FIRST_BOOT then

_G.TGO_OK            = _G.TGO_OK            or false
_G.TGO_REVOKED       = _G.TGO_REVOKED       or false
_G.TGO_STATUS        = _G.TGO_STATUS        or "CHECKING"
_G.KEY_ALREADY_VALID = _G.KEY_ALREADY_VALID or false
_G.KEY_INFO          = _G.KEY_INFO          or { key = "", expiry = "", days = 0 }

local function sc(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if ok then return r end
    return nil
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function clean(s) return trim(tostring(s or ""):gsub("[\r\n\t]", "")) end
local function LOG(m) pcall(print, "[TGO] " .. tostring(m)) end

local function getHttp()
    if _G._TGO_http then return _G._TGO_http end
    local mm = _G.ModuleManager
    if not mm then local ok, m = pcall(require, "ModuleManager"); if ok then mm = m end end
    if mm and mm.GetModule and mm.CommonModuleConfig then
        local ok, h = pcall(mm.GetModule, mm.CommonModuleConfig.http_manager)
        if ok and h and h.Post then _G._TGO_http = h; return h end
    end
    return nil
end

local function getMsgBox()
    if _G._TGO_mb then return _G._TGO_mb end
    local ok, m = pcall(require, "client.slua.logic.common.logic_common_msg_box")
    if ok and m and m.Show then _G._TGO_mb = m; return m end
    for _, n in ipairs({ "MsgBox", "MessageBox", "NewMessageBox", "UIMessageBox" }) do
        local ok2, m2 = pcall(require, n)
        if ok2 and m2 and m2.Show then _G._TGO_mb = m2; return m2 end
        if package.loaded[n] and package.loaded[n].Show then
            _G._TGO_mb = package.loaded[n]; return _G._TGO_mb
        end
    end
    return nil
end

local function getTimer()
    local t = package.loaded["<Timer>"]
    if not t then local ok, m = pcall(require, "<Timer>"); if ok then t = m end end
    return t
end

local function after(sec, fn)
    local t = getTimer()
    if t and t.AddTimerOnce then return sc(t.AddTimerOnce, sec, fn) ~= nil or true end
    local ok = pcall(function()
        if _G.Game and _G.Game.SetTimer then _G.Game:SetTimer(sec, false, fn) end
    end)
    return ok and _G.Game ~= nil
end

local function openURL(u)
    for _, n in ipairs({ "WebSDK", "WebView", "Browser", "OpenURL" }) do
        local ok, m = pcall(require, n)
        if ok and m and m.OpenURL then sc(m.OpenURL, m, u); return end
    end
end

local function Dialog(title, msg, b1, cb1, b2, cb2)
    local mb = getMsgBox()
    LOG(tostring(title) .. " :: " .. tostring(msg):gsub("\n", " | "))
    if not mb or not mb.Show then return false end
    local ok = pcall(function()
        if b2 then mb.Show(2, title, tostring(msg), cb1, cb2, b1, b2)
        else mb.Show(1, title, tostring(msg), cb1, nil, b1 or "OK", "") end
    end)
    if not ok then pcall(function() mb.Show(4, title, tostring(msg), nil, nil, "OK") end) end
    return true
end

local PKGS = {
    "com.pubg.imobile", "com.tencent.ig", "com.tencent.igfit", "com.rekoo.pubgm",
    "com.vng.pubgmobile", "com.tencent.tmgp.pubgmhd", "com.pubg.newstate",
    "com.tencent.igce", "com.epicgames.pubgm", "com.pubg.mobile",
}
local DIRS = {}
for _, p in ipairs(PKGS) do
    DIRS[#DIRS + 1] = "/storage/emulated/0/Android/data/" .. p .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"
    DIRS[#DIRS + 1] = "/sdcard/Android/data/" .. p .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"
    DIRS[#DIRS + 1] = "/storage/emulated/0/Android/data/" .. p .. "/files/mods/"
end
sc(function()
    if Client and Client.ProjectSavedDir then
        local d = Client.ProjectSavedDir()
        if d and d ~= "" then table.insert(DIRS, 1, d .. "/Paks/"); table.insert(DIRS, 2, d .. "/") end
    end
end)
DIRS[#DIRS + 1] = "/data/local/tmp/"
DIRS[#DIRS + 1] = ""

local function readF(p)
    local f = io.open(p, "r"); if not f then return nil end
    local c = f:read("*all"); f:close(); return c
end
local function writeF(p, d)
    local f = io.open(p, "w"); if not f then return false end
    f:write(d); f:close(); return true
end

local _wd
local function workDir()
    if _wd then return _wd end
    for _, d in ipairs(DIRS) do
        if d ~= "" and writeF(d .. ".tgo_p", "1") then os.remove(d .. ".tgo_p"); _wd = d; return d end
    end
    _wd = ""; return _wd
end

local HWFILE = ".tgo_hw"

local function readSavedHW()
    for _, dir in ipairs(DIRS) do
        local v = readF(dir .. HWFILE)
        if v then
            v = clean(v):gsub("[^%w_%-]", "")
            if #v >= 6 then return v end
        end
    end
    return nil
end

local function saveHW(v)
    local n = 0
    for _, dir in ipairs(DIRS) do
        if writeF(dir .. HWFILE, v) then n = n + 1 end
    end
    return n > 0
end

local function deviceID()
    if _G.TGO_HWID and _G.TGO_HWID ~= "" then return _G.TGO_HWID end
    local d = readSavedHW() or ""
    if d == "" then sc(function() local S = import("SystemUtil"); if S and S.GetAndroidID then d = S:GetAndroidID() or "" end end) end
    if d == "" then sc(function() if Client and Client.GetDeviceID then d = Client.GetDeviceID() or "" end end) end
    if d == "" then sc(function() if Client and Client.GetOpenId then d = Client.GetOpenId() or "" end end) end
    if d == "" then sc(function() if Device and Device.GetDeviceId then d = Device:GetDeviceId() or "" end end) end
    if d == "" then sc(function() if _G.GetDeviceID and _G.GetDeviceID ~= deviceID then d = _G.GetDeviceID() or "" end end) end
    if d == "" then sc(function() d = os.getenv("ANDROID_ID") or "" end) end
    if d == "" then
        sc(function()
            local Sec = import("android.provider.Settings$Secure")
            local AT  = import("android.app.ActivityThread")
            if Sec and AT then
                local app = AT.currentApplication()
                d = Sec.getString(app.getContentResolver(), "android_id") or ""
            end
        end)
    end
    if d == "" then
        math.randomseed(os.time() + (tonumber(tostring({}):match("0x(%x+)") or "0", 16) or 0))
        d = "FB" .. string.format("%08X", math.random(0, 2147483647))
        if not saveHW(d) then
            _G.TGO_HW_UNSTABLE = true
        end
    end
    d = tostring(d):gsub("[^%w_%-]", "")
    if not _G.TGO_HW_UNSTABLE then sc(saveHW, d) end
    _G.TGO_HWID = d
    return d
end

local function findKey()
    if HARDCODED_KEY and trim(HARDCODED_KEY) ~= "" then return trim(HARDCODED_KEY) end
    for _, dir in ipairs(DIRS) do
        for _, n in ipairs(KEY_FILES) do
            local c = readF(dir .. n)
            if c and #c > 3 then
                local k = clean(c):gsub("%s", "")
                if k:find("|") then k = k:match("^([^|]+)") end
                if k ~= "" then return k end
            end
        end
    end
    return nil
end

local function saveKey(k)
    local saved = false
    for _, dir in ipairs(DIRS) do
        if writeF(dir .. KEY_FILES[1], k) then saved = true; break end
    end
    return saved
end

local function J(s, k)
    if not s then return nil end
    local ok, t = pcall(function() return json.decode(s) end)
    if ok and type(t) == "table" and t[k] ~= nil then return t[k] end
    local v = s:match('"' .. k .. '"%s*:%s*"([^"]*)"'); if v then return v end
    v = s:match('"' .. k .. '"%s*:%s*(-?%d+%.?%d*)');   if v then return tonumber(v) end
    if s:match('"' .. k .. '"%s*:%s*true')  then return true end
    if s:match('"' .. k .. '"%s*:%s*false') then return false end
    return nil
end
local function esc(s) return tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("[\n\r\t]", "") end

local HTTPLOG = {}
local function POST(path, body, cb)
    local url = API_BASE .. path
    local h = getHttp()
    if h and h.Post then
        local fired = pcall(function()
            h:Post(url, { ["Content-Type"] = "application/json" }, body, nil,
                function(ok, resp)
                    if ok and resp and tostring(resp) ~= "" then cb(tostring(resp))
                    else HTTPLOG[#HTTPLOG + 1] = "http_manager: empty/fail"; cb(nil) end
                end, HTTP_TIMEOUT)
        end)
        if fired then HTTPLOG[#HTTPLOG + 1] = "http_manager: used"; return end
        HTTPLOG[#HTTPLOG + 1] = "http_manager: call threw"
    else
        HTTPLOG[#HTTPLOG + 1] = "http_manager: not found"
    end

    local function shellCall()
        local out = nil
        pcall(function()
            local tmp = workDir() .. ".tgo_r"
            os.remove(tmp)
            local q = "'" .. body:gsub("'", "'\\''") .. "'"
            local cmd = "curl -s -m " .. HTTP_TIMEOUT .. " -o '" .. tmp ..
                        "' -X POST -H 'Content-Type: application/json' --data " .. q .. " '" .. url .. "'"
            if os.execute then os.execute(cmd .. " 2>/dev/null") end
            out = readF(tmp); os.remove(tmp)
        end)
        if out and out:match("%S") then HTTPLOG[#HTTPLOG + 1] = "curl: used"; cb(out)
        else HTTPLOG[#HTTPLOG + 1] = "curl: fail"; cb(nil) end
    end
    if not after(2.0, shellCall) then
        HTTPLOG[#HTTPLOG + 1] = "no timer, sync curl"
        shellCall()
    end
end

local function cacheFile() return workDir() .. ".tgo_cache" end

local function cacheSave(k, hw, expMs, nm, d, md)
    writeF(cacheFile(), table.concat({ "TGO2", k, hw, tostring(expMs), tostring(os.time()),
        tostring(nm or ""), tostring(d or 0), tostring(md or 0) }, "|"))
end

local function cacheLoad(k, hw)
    local c = readF(cacheFile()); if not c then return nil end
    local p = {}; for f in c:gmatch("[^|]+") do p[#p + 1] = f end
    if p[1] ~= "TGO2" or #p < 8 or p[2] ~= k or p[3] ~= hw then return nil end
    local exp, last = tonumber(p[4]) or 0, tonumber(p[5]) or 0
    if os.time() * 1000 > exp then return nil end
    if OFFLINE_GRACE_HOURS <= 0 then return nil end
    if (os.time() - last) > OFFLINE_GRACE_HOURS * 3600 then return nil end
    return { expiry = exp, name = p[6], devices = tonumber(p[7]) or 0,
             maxDevices = tonumber(p[8]) or 0, ageMin = math.floor((os.time() - last) / 60) }
end

local function dstr(ms) return os.date("%Y-%m-%d %H:%M:%S", math.floor(ms / 1000)) end
local function dlbl(ms) return (os.date("%d %b %Y", math.floor(ms / 1000))):upper() end
local function dleft(ms)
    local s = math.floor(ms / 1000) - os.time(); if s < 0 then s = 0 end
    return math.floor(s / 86400), math.floor((s % 86400) / 3600)
end

local ERRS = {
    INVALID_KEY  = "Key galat hai ya panel me hai hi nahi.",
    KEY_DISABLED = "Ye key OFF kar di gayi hai.",
    KEY_EXPIRED  = "Key ki expiry nikal chuki hai.",
    DEVICE_LIMIT = "Device limit full hai.\nIs key pe naya device allow nahi.",
    UNAUTHORIZED = "Server ne request reject kar di.",
}

local function unlock(key, expMs, nm, dev, maxDev, offline)
    local days, hrs = dleft(expMs)
    _G.TGO_OK, _G.TGO_REVOKED = true, false
    _G._LICENSE_OK      = true
    _G.TGO_KEY, _G.TGO_EXPIRY_MS = key, expMs
    _G.TGO_EXPIRY_DATE, _G.TGO_EXPIRY_LABEL = dstr(expMs), dlbl(expMs)
    _G.TGO_DEVICES, _G.TGO_MAXDEVICES = dev, maxDev
    _G.TGO_OFFLINE = offline and true or false
    _G.TGO_STATUS = offline and "OFFLINE" or "ONLINE"
    _G.KEY_ALREADY_VALID = true
    _G.KEY_INFO = { key = key, expiry = dstr(expMs), days = days }
    _G.VALID_KEY_TYPE, _G.USER_EXPIRY_TIME = "VIP", dstr(expMs)

    if SHOW_WELCOME_POPUP then
    Dialog("VIP ACTIVATED" .. (offline and "  (OFFLINE)" or ""),
        table.concat({
            (nm and nm ~= "" and ("Name    : " .. nm) or nil),
            "Key     : " .. key,
            "Expiry  : " .. dstr(expMs),
            "Bacha   : " .. days .. "d " .. hrs .. "h",
            (_G.TGO_HW_UNSTABLE and "\n! Device ID save nahi ho pa rahi - storage\n  permission do, warna device limit bharegi" or nil),
            (DEBUG_HTTP and ("\n" .. table.concat(HTTPLOG, "\n")) or nil),
        }, "\n"),
        "OK")
    end
    LOG("vip unlock: dev=" .. tostring(dev) .. "/" .. tostring(maxDev) ..
        " hwid=" .. tostring(_G.TGO_HWID) .. " loader=" .. TGO_VERSION)
    if _G._LOGIN_UI and not _G._TGO_LOGINCB then pcall(_G.TGO_LoginClose) end
    _G._TGO_popup = false
    if _G._TGO_LOGINCB then
        local cb = _G._TGO_LOGINCB
        _G._TGO_LOGINCB = nil
        pcall(cb, true, nil, expMs)
    end
end

local function lock(title, msg, allowRetry, lreason)
    _G.TGO_OK, _G.KEY_ALREADY_VALID = false, false
    _G._LICENSE_OK = false
    _G.TGO_STATUS = "LOCKED"
    if lreason and _G._LOGIN_UI then
        local txt = (lreason == "blocked" and "Key blocked hai")
            or (lreason == "expired" and "Key expire ho gayi")
            or (lreason == "device_limit" and "Dusre device par lock hai")
            or (lreason == "nonet" and "Net slow - retry ho raha hai...")
            or "Galat key - dobara likho"
        pcall(_G.TGO_LoginStatus, txt, lreason ~= "nonet")
        return
    end
    if _G._TGO_LOGINCB then
        local cb = _G._TGO_LOGINCB
        _G._TGO_LOGINCB = nil
        pcall(cb, false, lreason or "invalid")
        return
    end
    if lreason and not _G.TGO_OK then
        _G.TGO_AskKey()
        return
    end
    if allowRetry then
        Dialog(title, msg .. "\n\nHWID: " .. tostring(_G.TGO_HWID),
            "Telegram", function() openURL(TELEGRAM_LINK); after(0.5, _G.TGO_AskKey) end,
            "Key daalo", function() after(0.3, _G.TGO_AskKey) end)
    else
        Dialog(title, msg, "OK")
    end
end

local TGO_ShowLoginUI
do
    local function mkTimerHost()
        local h = {}
        h.Object = {}
        function h:AddGameTimer(sec, loop, fn)
            if not loop then after(sec, fn); return nil end
            local alive = true
            local function step()
                if not alive then return end
                pcall(fn)
                if alive then after(sec, step) end
            end
            after(sec, step)
            local stop = function() alive = false end
            _G._TGO_LOGIN_STOPS = _G._TGO_LOGIN_STOPS or {}
            _G._TGO_LOGIN_STOPS[#_G._TGO_LOGIN_STOPS + 1] = stop
            return stop
        end
        function h:RemoveGameTimer(t) if type(t) == "function" then pcall(t) end end
        return h
    end
    local function GetSavedKey() return findKey() end

    local function DestroyLoginUI()
        pcall(function()
            if _G._TGO_LOGIN_STOPS then
                for _, h in ipairs(_G._TGO_LOGIN_STOPS) do pcall(h) end
            end
            _G._TGO_LOGIN_STOPS = nil
        end)
        pcall(function()
            if _G._LOGIN_TIMER and _G._LOGIN_CHAR and _G._LOGIN_CHAR.RemoveGameTimer then
                local ch = _G._LOGIN_CHAR
                if ch and ch.Object and slua.isValid(ch.Object) then
                    ch:RemoveGameTimer(_G._LOGIN_TIMER)
                end
            end
        end)
        _G._LOGIN_TIMER = nil
        _G._LOGIN_CHAR = nil
        pcall(function()
            if _G._LOGIN_UI and slua.isValid(_G._LOGIN_UI) then
                _G._LOGIN_UI:RemoveFromParent()
                if _G._LOGIN_UI.ConditionalBeginDestroy then _G._LOGIN_UI:ConditionalBeginDestroy() end
            end
        end)
        _G._LOGIN_UI = nil
        _G._LOGIN_DIM = nil
        _G._LOGIN_BOX = nil
        _G._LOGIN_BTN = nil
        _G._GETKEY_BTN = nil
        _G._PASTE_BTN = nil
        _G._LOGIN_PILL = nil
        _G._LOGIN_BTN_LABELS = nil
        _G._LOGIN_STATUS = nil
        _G._LOGIN_SLOTS = nil
        _G._LOGIN_ROOTSLOT = nil
        _G._LOGIN_CX = nil
        _G._LOGIN_CY = nil
        pcall(function()
            local ch2 = _G._LOGIN_PULSE_CHAR or _G._LOGIN_CHAR
            if _G._LOGIN_PULSE_TIMER and ch2 and ch2.RemoveGameTimer then
                if ch2.Object and slua.isValid(ch2.Object) then
                    ch2:RemoveGameTimer(_G._LOGIN_PULSE_TIMER)
                end
            end
        end)
        _G._LOGIN_PULSE_TIMER = nil
        _G._LOGIN_PULSE_CHAR = nil
        _G._LOGIN_PULSE_BARS = nil
        _G._LOGIN_PULSE_ON = nil
        _G._LOGIN_ANIM_TIMER = nil
        _G._LOGIN_ANIM_CHAR = nil
        _G._LOGIN_ANIM = nil
    end

    local function SetLoginStatus(txt, isError)
        pcall(function()
            if _G._LOGIN_STATUS and slua.isValid(_G._LOGIN_STATUS) then
                local s = tostring(txt)
                local c
                local FLinearColor = import("LinearColor")
                local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                if s:find("Waiting") then
                    s = "> SYSTEM READY"
                    c = FLinearColor(1.0, 1.0, 1.0, 1.0)
                elseif s:find("Checking") then
                    s = "> VERIFYING KEY..."
                    c = FLinearColor(1.0, 0.85, 0.3, 1.0)
                elseif s:find("Key OK") or s:find("LICENSE ACTIVE") then
                    s = "OK: ACCESS GRANTED"
                    c = FLinearColor(0.25, 1.0, 0.5, 1.0)
                else
                    c = isError and FLinearColor(1.0, 0.35, 0.32, 1.0) or FLinearColor(0.95, 0.88, 0.78, 1.0)
                end
                _G._LOGIN_STATUS:SetText(s)
                pcall(function()
                    if FSlateColor then _G._LOGIN_STATUS:SetColorAndOpacity(FSlateColor(c)) else _G._LOGIN_STATUS:SetColorAndOpacity(c) end
                end)
            end
        end)
    end

    local function GetInputText()
        local t = nil
        pcall(function()
            if _G._LOGIN_BOX and slua.isValid(_G._LOGIN_BOX) and _G._LOGIN_BOX.GetText then
                local ft = _G._LOGIN_BOX:GetText()
                if ft then
                    if type(ft) == "string" then t = ft
                    elseif ft.ToString then t = ft:ToString()
                    else t = tostring(ft) end
                end
            end
        end)
        if t then
            t = tostring(t):gsub("[^A-Za-z0-9%-_]", "")
        end
        if not t or t == "" then t = nil end
        return t
    end

    local function BindClick(b, fn)
        if not (b and slua.isValid(b)) then return end
        pcall(function() if b.OnClicked and b.OnClicked.Add then b.OnClicked:Add(function() fn() end) end end)
        pcall(function() if b.OnClicked and b.OnClicked.Add then b.OnClicked:Add(b, function() fn() end) end end)
        pcall(function() if slua.addDelegate then slua.addDelegate(b.OnClicked, function() fn() end) end end)
    end

    local function FillParent(slot)
        if not slot then return end
        pcall(function()
            if slot.SetAnchors then
                slot:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 1, Y = 1 } })
            end
        end)
        pcall(function()
            if slot.SetOffsets then slot:SetOffsets({ Left = 0, Top = 0, Right = 0, Bottom = 0 }) end
        end)
    end

    local function OpenTelegram()
        SetLoginStatus("Telegram khul raha hai...", false)
        local done = false
        pcall(function()
            local KSL = import("KismetSystemLibrary")
            if KSL and KSL.LaunchURL then
                KSL.LaunchURL(TELEGRAM_LINK)
                done = true
            end
        end)
        if not done then
            pcall(function()
                local KSL = import("KismetSystemLibrary")
                local w = slua.getWorld and slua.getWorld()
                if KSL and w and KSL.ExecuteConsoleCommand then KSL.ExecuteConsoleCommand(w, "LaunchURL " .. TELEGRAM_LINK) end
            end)
        end
    end

    local allWidgets = {}
    local rgbWidgets = {}

    local function Layer(parent, x, y, w, h, color, z, isRGB)
        local b = nil
        pcall(function()
            b = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if b and slua.isValid(b) then
                b:SetBrushColor(color)
                b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(b)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(FVector2D(x, y))
                    slot:SetSize(FVector2D(w, h))
                    slot:SetZOrder(z or 0)
                end
                if isRGB then table.insert(rgbWidgets, b) end
            end
        end)
        table.insert(allWidgets, b)
        return b
    end

    local LOGO_PAL = {
        [1] = FLinearColor(0.10, 0.12, 0.16, 1.0),
        [2] = FLinearColor(0.22, 0.26, 0.32, 1.0),
        [3] = FLinearColor(0.36, 0.41, 0.48, 1.0),
        [4] = FLinearColor(0.50, 0.56, 0.64, 1.0),
        [5] = FLinearColor(0.64, 0.70, 0.78, 1.0),
        [6] = FLinearColor(0.78, 0.84, 0.90, 1.0),
        [7] = FLinearColor(0.90, 0.94, 0.97, 1.0),
        [8] = FLinearColor(1.00, 1.00, 1.00, 1.0),
        [100] = FLinearColor(0.06, 0.26, 0.58, 1.0),
        [101] = FLinearColor(0.96, 0.34, 0.28, 1.0),
        [102] = FLinearColor(0.46, 0.10, 0.09, 1.0),
        [103] = FLinearColor(0.75, 0.20, 0.17, 1.0),
    }

    local function DrawLogo(parent, px, py, size, z, data, gridSz)
        local d = data or _G.EREN_LOGO
        if not d then return end
        local cell = size / (gridSz or _G.EREN_LOGO_SZ)
        for i = 1, #d do
            local r = d[i]
            local col = LOGO_PAL[r[5] + 1] or LOGO_PAL[r[5]]
            if r[5] >= 100 then col = LOGO_PAL[r[5]] end
            if col then
                Layer(parent, px + r[2]*cell, py + r[1]*cell,
                      r[3]*cell + 0.35, r[4]*cell + 0.35, col, z or 50)
            end
        end
    end

    local BAN_PAL_CACHE = nil
    local function DrawBanner(parent, px, py, w, h, z)
        local d = _G.EREN_BAN
        if not d then return false end
        if not BAN_PAL_CACHE then
            BAN_PAL_CACHE = {}
            for i, p in ipairs(_G.EREN_BAN_PAL) do
                BAN_PAL_CACHE[i] = FLinearColor(p[1], p[2], p[3], 1.0)
            end
        end
        local b = _G.EREN_BAN_BG
        if b then
            Layer(parent, px, py, w, h, FLinearColor(b[1], b[2], b[3], 1.0), (z or 20) - 1)
        end
        local cw = w / _G.EREN_BAN_W
        local ch = h / _G.EREN_BAN_H
        local bleed = math.max(0.6, cw * 0.10)
        for i = 1, #d do
            local r = d[i]
            local col = BAN_PAL_CACHE[r[5]]
            if col then
                Layer(parent, px + r[2]*cw, py + r[1]*ch,
                      r[3]*cw + bleed, r[4]*ch + bleed, col, z or 20)
            end
        end
        return true
    end

    _G.EREN_LOGO_SZ = 15
    _G.EREN_LOGO = {
        {1,8,1,1,102},
        {2,7,3,1,102},
        {3,6,5,1,102},
        {4,5,3,1,102},
        {4,8,1,1,103},
        {4,9,3,1,102},
        {5,4,3,1,102},
        {5,7,3,1,103},
        {5,10,3,1,102},
        {6,3,3,1,102},
        {6,6,2,1,103},
        {6,8,1,1,101},
        {6,9,2,1,103},
        {6,11,3,1,102},
        {7,2,3,1,102},
        {7,5,2,1,103},
        {7,7,3,1,101},
        {7,10,2,1,103},
        {7,12,3,1,102},
        {8,1,3,1,102},
        {8,4,2,1,103},
        {8,6,5,1,101},
        {8,11,2,1,103},
        {8,13,3,1,102},
        {9,2,3,1,102},
        {9,5,2,1,103},
        {9,7,3,1,101},
        {9,10,2,1,103},
        {9,12,3,1,102},
        {10,3,3,1,102},
        {10,6,2,1,103},
        {10,8,1,1,101},
        {10,9,2,1,103},
        {10,11,3,1,102},
        {11,4,3,1,102},
        {11,7,3,1,103},
        {11,10,3,1,102},
        {12,5,3,1,102},
        {12,8,1,1,103},
        {12,9,3,1,102},
        {13,6,5,1,102},
        {14,7,3,1,102},
        {15,8,1,1,102},
    }

    local function ShowLoginUI(character, topMsg, onLogin)
        DestroyLoginUI()
        local built = false
        local ok, err = pcall(function()
            local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local MainUI = InGameUITools.GetMainControlBaseUI()
            if not (MainUI and slua.isValid(MainUI)) then return end
            local Parent = (MainUI.CanvasPanel_0 and slua.isValid(MainUI.CanvasPanel_0)) and MainUI.CanvasPanel_0 or nil
            if not Parent and MainUI.CanvasPanel_42 and slua.isValid(MainUI.CanvasPanel_42) then
                Parent = MainUI.CanvasPanel_42
            end
            if not (Parent and slua.isValid(Parent)) then
                pcall(function()
                    local candidates = { "CanvasPanel_0", "CanvasPanel_42", "CanvasPanel", "CanvasPanel_1", "RootCanvas" }
                    for _, nm in ipairs(candidates) do
                        local c = MainUI[nm]
                        if c and slua.isValid(c) then Parent = c break end
                    end
                end)
            end
            if not (Parent and slua.isValid(Parent)) then
                pcall(function()
                    if MainUI.GetChildrenCount and MainUI.GetChildAt then
                        local n = MainUI:GetChildrenCount()
                        for i = 0, n - 1 do
                            local ch = nil
                            pcall(function() ch = MainUI:GetChildAt(i) end)
                            if ch and slua.isValid(ch) and ch.AddChildToCanvas then Parent = ch break end
                        end
                    end
                end)
            end
            if not (Parent and slua.isValid(Parent)) then
                pcall(function()
                    if MainUI.AddChildToCanvas then Parent = MainUI end
                end)
            end
            if not (Parent and slua.isValid(Parent)) then
                _G._LOGIN_LAST_ERROR = "no Parent canvas"
                return
            end
            local FVector2D = import("Vector2D")
            local FLinearColor = import("LinearColor")
            local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
            local function safeNew(path, outer)
                local o = nil
                pcall(function() o = CGame:NewObjectFromPath(path, outer) end)
                return o
            end
            local function ComputeLayout()
                local vw, vh = 1920, 1080
                pcall(function()
                    local ui_util = require("client.common.ui_util")
                    local vs = ui_util and ui_util.GetViewportSize and ui_util.GetViewportSize()
                    if vs and vs.X and vs.X > 0 then vw, vh = vs.X, vs.Y end
                end)
                local pw, ph = vw, vh
                pcall(function()
                    if Parent.GetCachedGeometry then
                        local cg = Parent:GetCachedGeometry()
                        if cg and cg.GetLocalSize then
                            local sz = cg:GetLocalSize()
                            if sz and sz.X and sz.X > 100 and sz.Y and sz.Y > 100 then
                                if sz.X > vw * 0.7 and sz.X < vw * 1.3 and sz.Y > vh * 0.7 and sz.Y < vh * 1.3 then
                                    pw, ph = sz.X, sz.Y
                                end
                            end
                        end
                    end
                end)
                local ox, oy = 0, 0
                pcall(function()
                    if Parent.GetCachedGeometry then
                        local cg = Parent:GetCachedGeometry()
                        if cg and cg.GetAbsolutePosition then
                            local ap = cg:GetAbsolutePosition()
                            if ap and ap.X and math.abs(ap.X) < vw * 0.25 and math.abs(ap.Y) < vh * 0.25 then
                                ox, oy = ap.X, ap.Y
                            end
                        end
                    end
                end)
                local cx2 = vw * 0.5 - ox
                local cy2 = vh * 0.5 - oy
                local panelW = pw * 0.42
                if panelW > 920 then panelW = 920 end
                if panelW < 420 then panelW = 420 end
                local panelH = panelW * (520 / 740)
                local u2 = panelW / 740
                return pw, ph, cx2, cy2, u2, panelW, panelH, vw, vh, ox, oy
            end
            local pw, ph, cx, cy, S, panelW, panelH, vw, vh, ox, oy = ComputeLayout()
            local function RelayoutLogin()
                pcall(function()
                    local sl = _G._LOGIN_SLOTS
                    if not sl or #sl == 0 then return end
                    local pw2, ph2, cx2, cy2 = ComputeLayout()
                    local dx, dy = cx2 - (_G._LOGIN_CX or cx2), cy2 - (_G._LOGIN_CY or cy2)
                    if math.abs(dx) < 2 and math.abs(dy) < 2 then return end
                    _G._LOGIN_CX, _G._LOGIN_CY = cx2, cy2
                    local FVector2D = import("Vector2D")
                    for _, e in ipairs(sl) do
                        pcall(function()
                            if e.s and slua.isValid(e.s) and e.s.SetPosition then
                                e.x, e.y = e.x + dx, e.y + dy
                                e.s:SetPosition(FVector2D(e.x, e.y))
                            end
                        end)
                    end
                    pcall(function()
                        if _G._LOGIN_ROOTSLOT and slua.isValid(_G._LOGIN_ROOTSLOT) and _G._LOGIN_ROOTSLOT.SetSize then
                            _G._LOGIN_ROOTSLOT:SetSize(FVector2D(pw2, ph2))
                        end
                    end)
                end)
            end
            local CLR = {
                cream       = FLinearColor(0.92, 0.87, 0.78, 1.0),
                cream_bright= FLinearColor(0.97, 0.93, 0.86, 1.0),
                cream_dim   = FLinearColor(0.66, 0.60, 0.53, 1.0),
                foot        = FLinearColor(0.55, 0.50, 0.44, 1.0),
                red         = FLinearColor(0.86, 0.22, 0.19, 1.0),
                red_bright  = FLinearColor(0.96, 0.34, 0.28, 1.0),
                red_dim     = FLinearColor(0.46, 0.10, 0.09, 1.0),
                white       = FLinearColor(1.0, 1.0, 1.0, 1.0),
                gray        = FLinearColor(0.60, 0.58, 0.56, 1.0),
                gray_dim    = FLinearColor(0.40, 0.38, 0.36, 1.0),
                input_bg    = FLinearColor(0.030, 0.026, 0.026, 0.97),
                pill_bg     = FLinearColor(0.040, 0.022, 0.022, 0.96),
            }
            _G._LOGIN_ANIM = _G._LOGIN_ANIM or {}
            local ANIM = _G._LOGIN_ANIM
            ANIM.bars = ANIM.bars or {}
            ANIM.scan = ANIM.scan or nil
            ANIM.tick = 0
            _G._LOGIN_PULSE_BARS = _G._LOGIN_PULSE_BARS or {}
            local function mkText(proot, txt, size, color, x, y, bold, ax)
                local w = safeNew("/Script/UMG.TextBlock", proot)
                if w and slua.isValid(w) then
                    pcall(function()
                        w:SetText(tostring(txt))
                        if FSlateColor then w:SetColorAndOpacity(FSlateColor(color)) else w:SetColorAndOpacity(color) end
                        if w.Font then
                            local f = w.Font
                            f.Size = size
                            if bold then pcall(function() f.TypefaceFontName = "Bold" end) end
                            w.Font = f
                        end
                        w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        pcall(function() w:SetShadowColorAndOpacity(FLinearColor(0, 0, 0, 0.85)) end)
                        pcall(function() w:SetShadowOffset(FVector2D(1.5, 1.5)) end)
                    end)
                    pcall(function()
                        local s = proot:AddChildToCanvas(w)
                        if s then pcall(function() s:SetAutoSize(true) s:SetAlignment(FVector2D(ax or 0.5, 0.5)) s:SetPosition(FVector2D(x, y)) s:SetZOrder(9999) end) end
                    end)
                end
                return w
            end
            local function mkBorder(proot, color, x, y, w, h, z, registerPulse)
                local b = safeNew("/Script/UMG.Border", proot)
                if not (b and slua.isValid(b)) then return nil end
                pcall(function()
                    b:SetBrushColor(color)
                    b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                pcall(function()
                    local s = proot:AddChildToCanvas(b)
                    if s then pcall(function() s:SetAlignment(FVector2D(0.5, 0.5)) s:SetPosition(FVector2D(x, y)) s:SetSize(FVector2D(w, h)) s:SetZOrder(z or 9998) end) end
                end)
                if registerPulse and ANIM.bars then table.insert(ANIM.bars, b) end
                return b
            end
            local S2 = ph / 720.0
            local function MY(ym) return cy + (ym - 360.0) * S2 end
            local margL = cx - pw * 0.5 + pw * 0.022
            local margR = cx + pw * 0.5 - pw * 0.022
            local root = safeNew("/Script/UMG.CanvasPanel", Parent)
            if not (root and slua.isValid(root)) then _G._LOGIN_LAST_ERROR = "root create fail" return end
            local dim = safeNew("/Script/UMG.Border", root)
            if dim and slua.isValid(dim) then
                pcall(function()
                    dim:SetBrushColor(FLinearColor(0.02, 0.008, 0.008, 0.95))
                    dim:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local ds = nil
                pcall(function() ds = root:AddChildToCanvas(dim) end)
                if ds then
                    pcall(function() ds:SetAlignment(FVector2D(0.5, 0.5)) ds:SetPosition(FVector2D(cx, cy)) ds:SetSize(FVector2D(pw * 2, ph * 2)) ds:SetZOrder(9985) end)
                    FillParent(ds)
                end
                _G._LOGIN_DIM = dim
            end
            local banAspect = (_G.EREN_BAN_W or 96) / (_G.EREN_BAN_H or 52)
            local banH = ph * 0.56
            local banW = banH * banAspect
            if banW > pw * 0.72 then banW = pw * 0.72; banH = banW / banAspect end
            if banH > ph * 0.62 then banH = ph * 0.62; banW = banH * banAspect end
            local banX = cx - banW * 0.5
            local banY = (cy - ph * 0.201) - banH * 0.5
            if banY < cy - ph * 0.5 then banY = cy - ph * 0.5 end
            local drewBan = false
            pcall(function() drewBan = DrawBanner(root, banX, banY, banW, banH, 9986) end)
            if not drewBan then
                mkBorder(root, FLinearColor(0.46, 0.11, 0.09, 0.34), cx, MY(215), pw * 0.58, ph * 0.50, 9986)
                mkBorder(root, FLinearColor(0.40, 0.09, 0.08, 0.28), cx, MY(215), pw * 0.84, ph * 0.68, 9986)
                mkBorder(root, FLinearColor(0.34, 0.08, 0.07, 0.24), cx - pw * 0.42, MY(320), pw * 0.18, ph * 0.85, 9986)
                mkBorder(root, FLinearColor(0.34, 0.08, 0.07, 0.24), cx + pw * 0.42, MY(320), pw * 0.18, ph * 0.85, 9866)
            end
            pcall(function()
                mkBorder(root, FLinearColor(0, 0, 0, 0.40), cx - pw * 0.46, cy, pw * 0.13, ph * 2, 9987)
                mkBorder(root, FLinearColor(0, 0, 0, 0.40), cx + pw * 0.46, cy, pw * 0.13, ph * 2, 9987)
            end)
            pcall(function()
                local scan = mkBorder(root, FLinearColor(0.80, 0.25, 0.20, 0.16), cx, cy, pw * 1.1, math.max(2, math.floor(3 * S2)), 9988)
                if scan then ANIM.scan = { widget = scan, baseY = cy, range = ph * 0.42, dir = 1 } end
            end)
            pcall(function()
                mkBorder(root, CLR.red,        cx - pw * 0.30, MY(120), math.floor(3 * S2), math.floor(3 * S2), 9992, true)
                mkBorder(root, CLR.red_bright, cx + pw * 0.22, MY(180), math.floor(4 * S2), math.floor(4 * S2), 9992, true)
                mkBorder(root, CLR.red,        cx - pw * 0.18, MY(90),  math.floor(3 * S2), math.floor(3 * S2), 9992, true)
                mkBorder(root, CLR.red_bright, cx + pw * 0.34, MY(300), math.floor(3 * S2), math.floor(3 * S2), 9992, true)
                mkBorder(root, CLR.red,        cx + pw * 0.05, MY(70),  math.floor(4 * S2), math.floor(4 * S2), 9992, true)
                mkBorder(root, CLR.red_dim,    cx - pw * 0.36, MY(420), math.floor(3 * S2), math.floor(3 * S2), 9992, true)
            end)
            local logoSz = 36 * S2
            pcall(function() DrawLogo(root, margL, MY(54) - logoSz * 0.5, logoSz, 9991, _G.EREN_LOGO, _G.EREN_LOGO_SZ) end)
            mkText(root, "TG OWNER", math.floor(26 * S2), CLR.cream_bright, margL + logoSz + 14 * S2, MY(54), true, 0.0)
            mkText(root, "RISE ABOVE ALL", math.floor(11 * S2), CLR.cream_dim, margL, MY(80), false, 0.0)
            mkText(root, "ONLY THE", math.floor(13 * S2), CLR.cream, margR, MY(130), true, 1.0)
            mkText(root, "STRONG", math.floor(13 * S2), CLR.cream, margR, MY(152), true, 1.0)
            mkText(root, "SURVIVE", math.floor(13 * S2), CLR.red_bright, margR, MY(174), true, 1.0)
            mkText(root, "STRENGTH", math.floor(12 * S2), CLR.cream, margL, MY(152), true, 0.0)
            mkText(root, "IS EARNED", math.floor(12 * S2), CLR.cream_dim, margL, MY(174), false, 0.0)
            local ft = math.max(2, math.floor(2 * S2))
            mkBorder(root, CLR.red_dim, cx - 86 * S2, MY(302), 128 * S2, ft, 9999, true)
            mkBorder(root, CLR.red_dim, cx + 86 * S2, MY(302), 128 * S2, ft, 9999, true)
            mkText(root, "◆", math.floor(16 * S2), CLR.red_bright, cx, MY(302), true)
            mkText(root, "POWER      HONOR      LEGACY", math.floor(16 * S2), CLR.cream, cx, MY(348), true)
            mkBorder(root, CLR.red_dim, cx, MY(368), 270 * S2, math.max(1, math.floor(1.5 * S2)), 9999, true)
            mkText(root, topMsg or "» Enter your key to unlock premium", math.floor(13 * S2), CLR.cream_dim, cx, MY(396), false)
            local iy = MY(436)
            local rowW, rowH = 380 * S2, 48 * S2
            local lx = cx - rowW * 0.5
            local inputBg = safeNew("/Script/UMG.Border", root)
            if inputBg and slua.isValid(inputBg) then
                pcall(function()
                    inputBg:SetBrushColor(CLR.input_bg)
                    inputBg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local ibs = nil
                pcall(function() ibs = root:AddChildToCanvas(inputBg) end)
                if ibs then pcall(function() ibs:SetAlignment(FVector2D(0.5, 0.5)) ibs:SetPosition(FVector2D(cx, iy)) ibs:SetSize(FVector2D(rowW, rowH)) ibs:SetZOrder(9997) end) end
            end
            mkBorder(root, CLR.gray_dim, cx, iy - rowH * 0.5, rowW + 6 * S2, ft, 9999, true)
            mkBorder(root, CLR.gray_dim, cx, iy + rowH * 0.5, rowW + 6 * S2, ft, 9999, true)
            mkBorder(root, CLR.gray_dim, cx - (rowW + 6 * S2) * 0.5, iy, ft, rowH, 9999, true)
            mkBorder(root, CLR.gray_dim, cx + (rowW + 6 * S2) * 0.5, iy, ft, rowH, 9999, true)
            mkText(root, "◆", math.floor(13 * S2), CLR.red_bright, lx + 20 * S2, iy, true)
            local edW = 244 * S2
            local edCX = lx + 36 * S2 + edW * 0.5
            local box = safeNew("/Script/UMG.EditableTextBox", root)
            if box and slua.isValid(box) then
                local bs = nil
                pcall(function() bs = root:AddChildToCanvas(box) end)
                if bs then pcall(function() bs:SetAlignment(FVector2D(0.5, 0.5)) bs:SetPosition(FVector2D(edCX, iy)) bs:SetSize(FVector2D(edW, 44 * S2)) bs:SetZOrder(9999) end) end
                pcall(function() if box.SetHintText then box:SetHintText("ENTER YOUR KEY") end end)
                pcall(function() if box.SetKeyboardFocus then box:SetKeyboardFocus() end end)
                pcall(function()
                    if box.SetForegroundColor then
                        if FSlateColor then box:SetForegroundColor(FSlateColor(CLR.cream)) else box:SetForegroundColor(CLR.cream) end
                    end
                end)
                _G._LOGIN_BOX = box
            else
                return
            end
            _G._LOGIN_BTN_LABELS = _G._LOGIN_BTN_LABELS or {}
            local function mkButton(bcx, by, bw, bh, label, lr, lg, lb, fontSize)
                local b = safeNew("/Script/UMG.Button", root)
                if not (b and slua.isValid(b)) then return nil end
                local bs2 = nil
                pcall(function() bs2 = root:AddChildToCanvas(b) end)
                if bs2 then pcall(function() bs2:SetAlignment(FVector2D(0.5, 0.5)) bs2:SetPosition(FVector2D(bcx, by)) bs2:SetSize(FVector2D(bw, bh)) bs2:SetZOrder(9999) end) end
                local l = safeNew("/Script/UMG.TextBlock", b)
                if l and slua.isValid(l) then
                    pcall(function()
                        l:SetText(label)
                        local lc = FLinearColor(lr, lg, lb, 1)
                        if FSlateColor then l:SetColorAndOpacity(FSlateColor(lc)) else l:SetColorAndOpacity(lc) end
                        if l.Font then local f2 = l.Font f2.Size = fontSize or math.floor(20 * S2) pcall(function() f2.TypefaceFontName = "Bold" end) l.Font = f2 end
                        pcall(function() l:SetShadowColorAndOpacity(FLinearColor(0, 0, 0, 0.9)) end)
                        pcall(function() l:SetShadowOffset(FVector2D(1.5, 1.5)) end)
                        l:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
                    end)
                    pcall(function() if b.AddChild then b:AddChild(l) end end)
                    _G._LOGIN_BTN_LABELS[b] = { label = l, r = lr, g = lg, b = lb }
                end
                return b
            end
            local function BindHover(b, hr, hg, hb)
                if not (b and slua.isValid(b)) then return end
                local function setHL(on)
                    pcall(function()
                        local rec = _G._LOGIN_BTN_LABELS and _G._LOGIN_BTN_LABELS[b]
                        if rec and rec.label and slua.isValid(rec.label) then
                            local c = on and FLinearColor(hr, hg, hb, 1) or FLinearColor(rec.r, rec.g, rec.b, 1)
                            if FSlateColor then rec.label:SetColorAndOpacity(FSlateColor(c)) else rec.label:SetColorAndOpacity(c) end
                        end
                        if on and b.SetColorAndOpacity then b:SetColorAndOpacity(FLinearColor(1.5, 1.5, 1.5, 1.0)) end
                        if (not on) and b.SetColorAndOpacity then b:SetColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0)) end
                    end)
                end
                pcall(function() if b.OnHovered and b.OnHovered.Add then b.OnHovered:Add(function() setHL(true) end) end end)
                pcall(function() if b.OnUnhovered and b.OnUnhovered.Add then b.OnUnhovered:Add(function() setHL(false) end) end end)
            end
            local function glowBehind(bx, by, bw, bh, color, z)
                pcall(function()
                    local gb = safeNew("/Script/UMG.Border", root)
                    if gb and slua.isValid(gb) then
                        gb:SetBrushColor(color)
                        gb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local gs2 = root:AddChildToCanvas(gb)
                        if gs2 then gs2:SetAlignment(FVector2D(0.5, 0.5)) gs2:SetPosition(FVector2D(bx, by)) gs2:SetSize(FVector2D(bw + 14, bh + 14)) gs2:SetZOrder(z or 9997) end
                        if ANIM.bars then table.insert(ANIM.bars, gb) end
                    end
                end)
            end
            local pasteCX = lx + rowW - 46 * S2
            _G._PASTE_BTN = mkButton(pasteCX, iy, 92 * S2, 34 * S2, "✚ PASTE", 0.60, 0.57, 0.55, math.floor(11 * S2))
            if _G._PASTE_BTN then
                pcall(function() if _G._PASTE_BTN.SetColorAndOpacity then _G._PASTE_BTN:SetColorAndOpacity(FLinearColor(0.20, 0.18, 0.17, 1.0)) end end)
                BindHover(_G._PASTE_BTN, 0.95, 0.90, 0.84)
                BindClick(_G._PASTE_BTN, function()
                    local k = GetSavedKey()
                    if k and _G._LOGIN_BOX and slua.isValid(_G._LOGIN_BOX) then
                        pcall(function() _G._LOGIN_BOX:SetText(tostring(k)) end)
                        SetLoginStatus("Saved key pasted - press LOGIN", false)
                    else
                        SetLoginStatus("No saved key found", true)
                    end
                end)
            end
            local ly = MY(518)
            local lw2, lh2 = 220 * S2, 48 * S2
            _G._LOGIN_BTN = mkButton(cx, ly, lw2, lh2, "LOGIN", 1.0, 1.0, 1.0, math.floor(18 * S2))
            if _G._LOGIN_BTN then
                pcall(function() if _G._LOGIN_BTN.SetColorAndOpacity then _G._LOGIN_BTN:SetColorAndOpacity(FLinearColor(1.45, 0.28, 0.25, 1.0)) end end)
                glowBehind(cx, ly, lw2, lh2, FLinearColor(0.80, 0.20, 0.16, 0.55), 9997)
                mkBorder(root, CLR.red_bright, cx, ly - lh2 * 0.5 - 3 * S2, lw2 + 12 * S2, ft, 9996)
                BindHover(_G._LOGIN_BTN, 1.0, 1.0, 1.0)
            end
            local oy2 = MY(566)
            mkBorder(root, CLR.gray_dim, cx - 50 * S2, oy2, 64 * S2, math.max(1, math.floor(1.2 * S2)), 9999)
            mkBorder(root, CLR.gray_dim, cx + 50 * S2, oy2, 64 * S2, math.max(1, math.floor(1.2 * S2)), 9999)
            mkText(root, "OR", math.floor(10 * S2), CLR.gray, cx, oy2, false)
            local gy = MY(600)
            local gw2, gh2 = 184 * S2, 32 * S2
            mkBorder(root, CLR.gray_dim, cx, gy - gh2 * 0.5, gw2, ft, 9998)
            mkBorder(root, CLR.gray_dim, cx, gy + gh2 * 0.5, gw2, ft, 9998)
            mkBorder(root, CLR.gray_dim, cx - gw2 * 0.5, gy, ft, gh2, 9998)
            mkBorder(root, CLR.gray_dim, cx + gw2 * 0.5, gy, ft, gh2, 9998)
            _G._GETKEY_BTN = mkButton(cx, gy, gw2, gh2, "★ GET KEY", 0.72, 0.70, 0.67, math.floor(12 * S2))
            if _G._GETKEY_BTN then
                pcall(function() if _G._GETKEY_BTN.SetColorAndOpacity then _G._GETKEY_BTN:SetColorAndOpacity(FLinearColor(0.10, 0.09, 0.09, 1.0)) end end)
                BindHover(_G._GETKEY_BTN, 1.0, 0.95, 0.88)
            end
            pcall(function()
                local pill = safeNew("/Script/UMG.Border", root)
                if pill and slua.isValid(pill) then
                    pill:SetBrushColor(CLR.pill_bg)
                    pill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    local ps = root:AddChildToCanvas(pill)
                    if ps then ps:SetAlignment(FVector2D(0.5, 0.5)) ps:SetPosition(FVector2D(cx, MY(646))) ps:SetSize(FVector2D(300 * S2, 30 * S2)) ps:SetZOrder(9998) end
                    _G._LOGIN_PILL = pill
                    mkBorder(root, CLR.red_dim, cx, MY(646) - 15 * S2, 300 * S2, ft, 9999, true)
                    mkBorder(root, CLR.red_dim, cx, MY(646) + 15 * S2, 300 * S2, ft, 9999, true)
                end
            end)
            _G._LOGIN_STATUS = mkText(root, "● SYSTEM READY", math.floor(13 * S2), CLR.cream, cx, MY(646))
            local hwTxt = ""
            pcall(function() hwTxt = _G.TGO_HWID or tostring(deviceID()) end)
            if hwTxt and hwTxt ~= "" and hwTxt ~= "nil" then
                mkText(root, "HWID: " .. tostring(hwTxt), math.floor(10 * S2), CLR.foot, cx, MY(670), false)
            end
            local fy = MY(694)
            mkText(root, "HONOR • POWER • LEGACY", math.floor(10 * S2), CLR.foot, margL, fy, false, 0.0)
            mkText(root, "ENTER THE WORLD • YOUR RULE", math.floor(10 * S2), CLR.foot, cx, fy, false)
            mkText(root, "TG OWNER · VERSION 6.0", math.floor(10 * S2), CLR.foot, margR, fy, false, 1.0)
            local rs = nil
            pcall(function() rs = Parent:AddChildToCanvas(root) end)
            if rs then pcall(function() rs:SetPosition(FVector2D(0, 0)) rs:SetSize(FVector2D(pw, ph)) rs:SetZOrder(9989) end) end
            FillParent(rs)
            _G._LOGIN_ROOTSLOT = rs
            _G._LOGIN_SLOTS = nil
            pcall(function()
                local t = {}
                if root and slua.isValid(root) and root.GetChildrenCount then
                    local n = root:GetChildrenCount()
                    for i = 0, n - 1 do
                        local ch = nil
                        pcall(function() ch = root:GetChildAt(i) end)
                        if ch and slua.isValid(ch) and ch ~= _G._LOGIN_DIM then
                            local sl = ch.Slot
                            if not sl and ch.GetSlot then pcall(function() sl = ch:GetSlot() end) end
                            if sl then
                                pcall(function()
                                    if sl.GetPosition then
                                        local v = sl:GetPosition()
                                        if v and v.X then table.insert(t, { s = sl, x = v.X, y = v.Y }) end
                                    end
                                end)
                            end
                        end
                    end
                end
                if #t > 0 then
                    _G._LOGIN_SLOTS = t
                    _G._LOGIN_CX, _G._LOGIN_CY = cx, cy
                    local anchored = false
                    pcall(function()
                        local s0 = t[1] and t[1].s
                        if s0 and slua.isValid(s0) and s0.SetAnchors then
                            s0:SetAnchors({ Minimum = { X = 0.5, Y = 0.5 }, Maximum = { X = 0.5, Y = 0.5 } })
                            anchored = true
                        end
                    end)
                    if anchored then
                        for _, e in ipairs(t) do
                            pcall(function()
                                if e.s.SetAnchors then e.s:SetAnchors({ Minimum = { X = 0.5, Y = 0.5 }, Maximum = { X = 0.5, Y = 0.5 } }) end
                                if e.s.SetPosition then e.s:SetPosition(FVector2D(e.x - cx, e.y - cy)) end
                            end)
                        end
                        _G._LOGIN_SLOTS = nil
                    end
                end
            end)
            _G._LOGIN_UI = root
            pcall(function()
                if _G._LOGIN_PULSE_TIMER and _G._LOGIN_PULSE_CHAR and _G._LOGIN_PULSE_CHAR.RemoveGameTimer then
                    local pc0 = _G._LOGIN_PULSE_CHAR
                    if pc0.Object and slua.isValid(pc0.Object) then pc0:RemoveGameTimer(_G._LOGIN_PULSE_TIMER) end
                end
                _G._LOGIN_PULSE_TIMER = nil
                _G._LOGIN_PULSE_ON = false
                _G._LOGIN_PULSE_CHAR = character
                if _G._LOGIN_ANIM_TIMER and _G._LOGIN_ANIM_CHAR and _G._LOGIN_ANIM_CHAR.RemoveGameTimer then
                    local oldC = _G._LOGIN_ANIM_CHAR
                    if oldC.Object and slua.isValid(oldC.Object) then pcall(function() oldC:RemoveGameTimer(_G._LOGIN_ANIM_TIMER) end) end
                end
                _G._LOGIN_ANIM_TIMER = nil
                _G._LOGIN_ANIM_CHAR = character
                if ANIM.bars then
                    _G._LOGIN_PULSE_BARS = _G._LOGIN_PULSE_BARS or {}
                    for _, b in ipairs(ANIM.bars) do table.insert(_G._LOGIN_PULSE_BARS, b) end
                    ANIM.bars = _G._LOGIN_PULSE_BARS
                end
                local FLinearColor_P = import("LinearColor")
                local bright = FLinearColor_P(0.88, 0.24, 0.20, 1.0)
                local dark = FLinearColor_P(0.42, 0.09, 0.08, 1.0)
                local animTick = 0
                local function pulseTick()
                    if not (_G._LOGIN_UI and slua.isValid(_G._LOGIN_UI)) then return end
                    animTick = animTick + 1
                    _G._LOGIN_PULSE_ON = not _G._LOGIN_PULSE_ON
                    local c = _G._LOGIN_PULSE_ON and bright or dark
                    if _G._LOGIN_PULSE_BARS then
                        for _, b in ipairs(_G._LOGIN_PULSE_BARS) do
                            pcall(function() if b and slua.isValid(b) then b:SetBrushColor(c) end end)
                        end
                    end
                    if ANIM.bars and ANIM.bars ~= _G._LOGIN_PULSE_BARS then
                        for _, b in ipairs(ANIM.bars) do
                            pcall(function() if b and slua.isValid(b) then b:SetBrushColor(c) end end)
                        end
                    end
                    pcall(function()
                        local sc = ANIM.scan
                        if sc and sc.widget and slua.isValid(sc.widget) then
                            local offset = math.sin(animTick * 0.18) * sc.range
                            local sl = sc.widget.Slot
                            if not sl and sc.widget.GetSlot then pcall(function() sl = sc.widget:GetSlot() end) end
                            if sl and sl.SetPosition then sl:SetPosition(FVector2D(cx, sc.baseY + offset)) end
                        end
                    end)
                end
                _G._LOGIN_PULSE_TIMER = character:AddGameTimer(0.35, true, pulseTick)
                _G._LOGIN_ANIM_TIMER = _G._LOGIN_PULSE_TIMER
            end)
            built = true
        end)
        if not ok then
            _G._LOGIN_LAST_ERROR = tostring(err)
            pcall(function() print("[TGOLOGIN] build failed: " .. tostring(err)) end)
            if _G._LOGIN_UI and slua.isValid(_G._LOGIN_UI) then built = true end
        end
        if not built then return false end
        local attempts = 0
        local lastText, stable = nil, 0
        local function doLoginAttempt(t)
            _G._LOGIN_TRYING = true
            SetLoginStatus("Checking...", false)
            onLogin(t, function(ok, reason, expiry)
                _G._LOGIN_TRYING = false
                if ok then
                    pcall(DestroyLoginUI)
                else
                    if reason == "nonet" or reason == "limited" then
                        SetLoginStatus("Net slow - retry ho raha hai...", false)
                        lastText, stable = nil, 0
                    else
                        attempts = attempts + 1
                        if reason == "invalid" then SetLoginStatus("Galat key - dobara likho", true)
                        elseif reason == "blocked" then SetLoginStatus("Key blocked hai", true)
                        elseif reason == "expired" then SetLoginStatus("Key expire ho gayi", true)
                        elseif reason == "device_limit" then SetLoginStatus("Dusre device par lock hai", true)
                        else SetLoginStatus("Net error - fir se try karo", true) end
                        if attempts >= 5 then SetLoginStatus("Seller se contact karo", true) end
                    end
                end
            end)
        end
        local function tryLoginTap()
            local t = GetInputText()
            if not t or #t < 4 then
                SetLoginStatus("Pehle key likho", true)
                return
            end
            doLoginAttempt(t)
        end
        BindClick(_G._LOGIN_BTN, tryLoginTap)
        BindClick(_G._GETKEY_BTN, OpenTelegram)
        local loginTimer = nil
        loginTimer = character:AddGameTimer(1.0, true, function()
            if not true then
                if loginTimer and character.RemoveGameTimer then pcall(function() character:RemoveGameTimer(loginTimer) end) end
                return
            end
            if not (_G._LOGIN_BOX and slua.isValid(_G._LOGIN_BOX)) then
                if loginTimer and character.RemoveGameTimer then pcall(function() character:RemoveGameTimer(loginTimer) end) end
                return
            end
            local t = GetInputText()
            if t and t == lastText and #t >= 4 and stable >= 0 then
                stable = stable + 1
                if stable >= 2 then
                    stable = -999
                    doLoginAttempt(t)
                end
            else
                lastText, stable = t, 0
            end
        end)
        _G._LOGIN_TIMER = loginTimer
        _G._LOGIN_CHAR = character
        return true
    end

    TGO_ShowLoginUI = function(topMsg)
        local host = mkTimerHost()
        local okBuild = ShowLoginUI(host, topMsg or "» Enter your key to unlock premium", function(typedKey, cb)
            local old = findKey()
            if old and typedKey ~= old then
                sc(os.remove, cacheFile())
                sc(os.remove, workDir() .. ".tgo_mod")
                LOG("key change: purana cache clear (" .. tostring(old) .. " -> " .. tostring(typedKey) .. ")")
            end
            _G._TGO_LOGINCB = cb
            saveKey(typedKey)
            _G.TGO_Verify(typedKey)
        end)
        if okBuild then
            _G._TGO_LOGINBUILT = (_G._TGO_LOGINBUILT or 0) + 1
        end
        return okBuild
    end
    _G.TGO_LoginStatus = SetLoginStatus
    _G.TGO_LoginClose  = DestroyLoginUI
end

function _G.TGO_AskKeyLegacy()
    if _G.TGO_OK or _G._TGO_popup then return end
    _G._TGO_popup = true

    local um = _G.UIManager
    if not um then local ok, m = pcall(require, "UIManager"); if ok then um = m end end
    local chat = package.loaded["ChatRoomPassword"]
    if not chat then local ok, m = pcall(require, "ChatRoomPassword"); if ok then chat = m end end

    if not (um and um.UI_Config and um.UI_Config.ui_chat_room_password
            and chat and chat.send_join_channel_req) then
        _G._TGO_popup = false
        Dialog("KEY CHAHIYE",
            "Paks folder me '" .. KEY_FILES[1] .. "' banao aur usme apni key likho.\n\n" ..
            "HWID: " .. tostring(_G.TGO_HWID) .. "\n\nKey lene ke liye: " .. ADMIN_CONTACT,
            "Telegram", function() openURL(TELEGRAM_LINK) end, "OK", nil)
        return
    end

    local uid = um.UI_Config.ui_chat_room_password

    sc(function()
        local orig = chat.GetValidString_EnglishOrNumber
        if orig and not _G._TGO_origValid then
            _G._TGO_origValid = orig
            chat.GetValidString_EnglishOrNumber = function(s, n)
                if _G._TGO_popup then return tostring(s or ""):gsub("[^%w_%-]", "") end
                return _G._TGO_origValid(s, n)
            end
        end
    end)

    local origSend = chat.send_join_channel_req
    chat.send_join_channel_req = function(self, ...)
        local k = ""
        sc(function()
            local ui = um.GetUI and um.GetUI(uid)
            if ui and ui.UIRoot and ui.UIRoot.InputBox_Psw and ui.UIRoot.InputBox_Psw.message_input then
                k = ui.UIRoot.InputBox_Psw.message_input:GetText() or ""
            end
        end)
        sc(function() um.CloseUI(uid) end)
        chat.send_join_channel_req = origSend
        _G._TGO_popup = false

        k = clean(k):upper()
        if k == "" then
            Dialog("KEY KHALI HAI", "Apni key daalo.", "Dobara", function() after(0.3, _G.TGO_AskKey) end)
            return
        end
        saveKey(k)
        _G.TGO_Verify(k)
    end

    sc(function() um.ShowUI(uid, "default") end)
end

function _G.TGO_LoginWithKey(k)
    if _G.TGO_OK or _G._TGO_popup then return end
    _G._TGO_popup = true
    local tries = 0
    local function attempt()
        if _G.TGO_OK then
            _G._TGO_popup = false
            if _G._LOGIN_UI then pcall(_G.TGO_LoginClose) end
            return
        end
        if _G._LOGIN_UI then return end
        if TGO_ShowLoginUI() then return end
        tries = tries + 1
        if tries < 40 then after(0.5, attempt)
        else
            _G._TGO_popup = false
            _G.TGO_Verify(k)
        end
    end
    attempt()
end

function _G.TGO_AskKey()
    if _G.TGO_OK or _G._TGO_popup then return end
    _G._TGO_popup = true
    local tries = 0
    local function attempt()
        if _G.TGO_OK then _G._TGO_popup = false return end
        if _G._LOGIN_UI then return end
        if TGO_ShowLoginUI() then return end
        tries = tries + 1
        if tries < 40 then
            after(0.5, attempt)
        else
            _G._TGO_popup = false
            _G.TGO_AskKeyLegacy()
        end
    end
    attempt()
end

function _G.TGO_Verify(key, try)
    if _G.TGO_OK then return end
    try = try or 1
    local hw = deviceID()
    _G.TGO_STATUS = "CHECKING"
    POST("/api/auth", '{"key":"' .. esc(key) .. '","hwid":"' .. esc(hw) .. '"}', function(resp)
        if _G.TGO_OK then return end
        if resp and J(resp, "ok") == true then
            local exp = tonumber(J(resp, "expiry")) or 0
            local nm  = tostring(J(resp, "name") or "")
            local dv  = tonumber(J(resp, "devices")) or 0
            local mx  = tonumber(J(resp, "maxDevices")) or 0
            _G.TGO_SESS   = J(resp, "sess")
            _G.TGO_TOKEN  = J(resp, "token")
            _G.TGO_SCRIPT = J(resp, "script")
            cacheSave(key, hw, exp, nm, dv, mx)
            unlock(key, exp, nm, dv, mx, false)
            _G.TGO_StartBeat()
            _G.TGO_FetchMod()
        elseif resp then
            local e = tostring(J(resp, "err") or "UNKNOWN")
            if _G.TGO_OK then return end
            if e == "INVALID_KEY" and try < 3 then
                LOG("INVALID_KEY (try " .. try .. ") - dobara poochh rahe hain")
                if after(2.5 * try, function()
                    if not _G.TGO_OK then _G.TGO_Verify(key, try + 1) end
                end) then return end
            end
            if e == "KEY_DISABLED" or e == "KEY_EXPIRED" or e == "INVALID_KEY" then
                sc(os.remove, cacheFile())
                pcall(function() os.remove(workDir() .. ".tgo_mod") end)
            end
            local lr = "invalid"
            if e == "KEY_DISABLED" then lr = "blocked"
            elseif e == "KEY_EXPIRED" then lr = "expired"
            elseif type(e) == "string" and (e:find("DEVICE") or e:find("LIMIT")) then lr = "device_limit"
            end
            lock("KEY REJECTED",
                (ERRS[e] or ("Error: " .. e)) .. "\n\nKey: " .. key ..
                (DEBUG_HTTP and ("\n\n" .. table.concat(HTTPLOG, "\n")) or ""), true, lr)
        else
            local c = cacheLoad(key, hw)
            if c then
                unlock(key, c.expiry, c.name, c.devices, c.maxDevices, true)
                _G.TGO_RunCachedMod()
            else
                lock("SERVER SE CONNECT NAHI HUA",
                    "Internet on karke game dobara kholo.\n\nServer: " .. API_BASE ..
                    (DEBUG_HTTP and ("\n\n" .. table.concat(HTTPLOG, "\n"))
                                 or "\n\nFir bhi na chale toh script me\nDEBUG_HTTP = true karke screenshot bhejo."),
                    true, "nonet")
            end
        end
    end)
end

function _G.TGO_StartBeat()
    if HEARTBEAT_SEC <= 0 or not _G.TGO_SESS or _G._TGO_beating then return end
    _G._TGO_beating = true
    local function beat()
        if _G.TGO_REVOKED or not _G.TGO_SESS then return end
        POST("/api/heartbeat", '{"sess":"' .. esc(_G.TGO_SESS) .. '"}', function(r)
            if r and J(r, "alive") == false then
                _G.TGO_REVOKED, _G.TGO_OK, _G.KEY_ALREADY_VALID = true, false, false
                _G._LICENSE_OK = false
                _G.TGO_STATUS = "REVOKED"
                _G.TGO_EXPIRY_MS, _G.TGO_EXPIRY_DATE = 0, "2000-01-01 00:00:00"
                _G.TGO_EXPIRY_LABEL = "REVOKED"
                pcall(function() os.remove(workDir() .. ".tgo_mod") end)
                Dialog("KEY BAND KAR DI GAYI",
                    "Owner ne tumhari key OFF kar di hai.\nMenu lock ho gaya.\n\nContact: " .. ADMIN_CONTACT,
                    "Telegram", function() openURL(TELEGRAM_LINK) end, "OK", nil)
                return
            end
            if r then
                local e = tonumber(J(r, "expiry"))
                if e then
                    _G.TGO_EXPIRY_MS, _G.TGO_EXPIRY_DATE, _G.TGO_EXPIRY_LABEL = e, dstr(e), dlbl(e)
                end
            end
            after(HEARTBEAT_SEC, beat)
        end)
    end
    after(HEARTBEAT_SEC, beat)
end

local function xorKey()
    local s = tostring(_G.TGO_HWID or "x") .. "|tgo|" .. tostring(API_BASE)
    local t = {}
    local h = 5381
    for i = 1, 64 do
        h = (h * 33 + string.byte(s, ((i - 1) % #s) + 1)) % 4294967296
        t[i] = h % 256
    end
    return t
end

local function xorStr(s)
    local k = xorKey()
    local out, n = {}, #k
    for i = 1, #s do
        out[i] = string.char((string.byte(s, i) ~ k[((i - 1) % n) + 1]))
    end
    return table.concat(out)
end

local function modCacheFile() return workDir() .. ".tgo_mod" end

function _G.TGO_ActivateMod(char)
    if not (_G.TGO_OK and _G._LICENSE_OK) then return end
    if _G._TGO_STYLE ~= "entry" then return end
    local re = _G._TGO_REATTACH
    if re and type(_G[re]) == "function" then
        pcall(_G[re])
        return
    end
    local src = _G._TGO_MOD_SRC
    if src then
        local f = load(src, "=tgo_mod", "t")
        if f then pcall(f) end
    end
    local en = _G._TGO_ENTRY
    if en and type(_G[en]) == "function" then
        pcall(_G[en], char or _G._TGO_LAST_CHAR)
    end
end

local function runMod(src, how)
    if not src or #src < 200 then return false end
    if src:match("^%s*{") then return false end
    local f, err = load(src, "=tgo_mod", "t")
    if not f then
        LOG("mod compile fail: " .. tostring(err))
        return false
    end

    local snap = {}
    for k, v in pairs(_G) do
        if type(v) == "function" then snap[k] = true end
    end

    local ok, e = pcall(f)
    if not ok then LOG("mod runtime error: " .. tostring(e)) end
    _G.TGO_MOD_LOADED = ok
    if ok then _G._TGO_MOD_SRC = src end

    if ok then
        local names = {}
        for k, v in pairs(_G) do
            if type(v) == "function" and not snap[k] then
                names[#names + 1] = k
            end
        end
        local newfn = {}
        for _, n in ipairs(names) do newfn[n] = true end

        local function looksLikeEntry(n)
            local ln = n:lower()
            if ln:match("^_?get") or ln:match("^_?is") or ln:match("^_?has")
               or ln:match("^_?read") or ln:match("^_?safe") or ln:match("^_?new$")
               or ln:match("^_?on") then
                return false
            end
            return true
        end

        local entry
        if #names <= 3 then
            if newfn["StartAdvancedSystems"] then
                entry = "StartAdvancedSystems"
            elseif #names == 1 and looksLikeEntry(names[1]) then
                entry = names[1]
            else
                for _, n in ipairs(names) do
                    if looksLikeEntry(n) then
                        local ln = n:lower()
                        if ln:match("^start") or ln:match("^init")
                           or ln:match("^begin") or ln:match("^boot")
                           or ln:match("^launch") then
                            entry = n
                            break
                        end
                    end
                end
            end
        end

        if entry then
            _G._TGO_STYLE, _G._TGO_ENTRY = "entry", entry
            LOG("payload style: ENTRY -> " .. entry .. "() call kiya")
            pcall(_G[entry], _G._TGO_LAST_CHAR)
            for k, v in pairs(_G) do
                if type(v) == "function" and not snap[k] and not newfn[k] then
                    local lk = k:lower()
                    if lk:find("reattach", 1, true) or lk:find("restart", 1, true)
                       or lk:find("reinit", 1, true) then
                        _G._TGO_REATTACH = k
                        LOG("payload reattach mila: " .. k)
                        break
                    end
                end
            end
        else
            _G._TGO_STYLE = "chunk"
            LOG("payload style: CHUNK (self-running) - har map load pe replay")
        end

        if SHOW_MOD_READY and not _G._TGO_READY_SHOWN then
            _G._TGO_READY_SHOWN = true
            LOG("mod ready: script=" .. tostring(_G.TGO_SCRIPT) ..
                " style=" .. tostring(_G._TGO_STYLE) ..
                " size=" .. math.floor(#src / 1024) .. "KB ver=" .. TGO_VERSION)
            Dialog("MOD READY",
                table.concat({
                    "Script  : " .. tostring(_G.TGO_SCRIPT or "?") .. ".lua",
                    "",
                    "Har match me mod active rahega.",
                }, "\n"), "OK")
        end
    end
    LOG("mod loaded (" .. how .. "): " .. tostring(ok))
    return ok
end

function _G.TGO_RunCachedMod()
    if not CACHE_PAYLOAD or _G.TGO_MOD_LOADED then return end
    local blob = readF(modCacheFile())
    if not blob or #blob < 200 then return end
    local okx, src = pcall(xorStr, blob)
    if okx then runMod(src, "cache") end
end

function _G.TGO_FetchMod()
    if not LOADER_MODE or _G.TGO_MOD_LOADED then return end
    if not _G.TGO_TOKEN then return end
    POST("/api/payload", '{"token":"' .. esc(_G.TGO_TOKEN) .. '"}', function(src)
        if src and runMod(src, "server") then
            if CACHE_PAYLOAD then pcall(function() writeF(modCacheFile(), xorStr(src)) end) end
        else
            _G.TGO_RunCachedMod()
            if not _G.TGO_MOD_LOADED then
                Dialog("MOD LOAD NAHI HUA",
                    "Key toh sahi hai par mod ka code server se nahi aaya.\n\n" ..
                    "Internet check karke game dobara kholo.\n\nContact: " .. ADMIN_CONTACT, "OK")
            end
        end
    end)
end

deviceID()
local k = findKey()
if k and ASK_KEY_EVERY_BOOT then
    LOG("key mili - TG OWNER login page khul rahi hai (MANUAL: khud key dalo)")
    _G.TGO_LoginWithKey(k)
elseif k then
    LOG("key mili, background me verify ho rahi hai...")
    _G.TGO_Verify(k)
else
    _G.TGO_STATUS = "NO_KEY"
    if not after(3.0, _G.TGO_AskKey) then _G.TGO_AskKey() end
end

end

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

local require   = require
local import    = import
local tostring  = tostring
local math      = math
local string    = string
local isValid   = (slua and slua.isValid) or function(o) return o ~= nil end
local IsValid   = function(obj) return obj and slua and slua.isValid and slua.isValid(obj) end

if _G._TGO_MOD_SRC and _G._TGO_STYLE ~= "entry" and _G.TGO_OK and _G._LICENSE_OK then
    local __tgoF = load(_G._TGO_MOD_SRC, "=tgo_mod", "t")
    if __tgoF then
        local __tgoOK, __tgoErr = pcall(__tgoF)
        if not __tgoOK then
            print("[TGO] mod reload fail: " .. tostring(__tgoErr))
        end
    end
end
_G.TGO_ActivateMod()

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  pcall(function()
    local me = false
    if self.IsLocallyControlled then me = self:IsLocallyControlled() end
    if not me and ENetRole and self.Role == ENetRole.ROLE_AutonomousProxy then me = true end
    if me then
      _G._TGO_LAST_CHAR = self
      if _G.TGO_OK and _G._LICENSE_OK then _G.TGO_ActivateMod(self) end
    end
  end)
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature"
  },
  {
    SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  }
}, "BRPlayerCharacterBase")
