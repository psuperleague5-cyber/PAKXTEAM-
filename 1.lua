local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

-- AEGIS v3.5 — Full Stealth (Distance/Box/Skeleton Only, No Name)
if _G._AEGIS_V2 then return end
_G._AEGIS_V2 = true

local A = _G.Aegis or { Up = {} }
_G.Aegis = A
if A.Up.Installed then return end

local NoOp    = function() return true  end
local NoFalse = function() return false end
local NoZero  = function() return 0     end
local NoStr   = function() return ""    end

local function Safe(fn, ...) pcall(fn, ...) end

local function MuteFunctions(tbl, keywords)
    if type(tbl) ~= "table" then return end
    keywords = keywords or {
        "Report","Send","Verify","Check","Detect",
        "Ban","Kick","Notice","Scan","Flag","Suspic"
    }
    for k, v in pairs(tbl) do
        if type(v) == "function" and type(k) == "string" then
            for _, kw in ipairs(keywords) do
                if k:find(kw, 1, true) then
                    pcall(function() tbl[k] = NoOp end)
                    break
                end
            end
        end
    end
end

local function MuteGlobals()
    local names = {
        "BanPlayer","ReportCheat","OnCheatDetected","AntiCheatReport",
        "KickPlayer","ReportHack","ReportSuspicious",
        "ReportESP","ReportAimBot","ReportSpeedHack",
        "ReportAntiCheatInfo","CheckNeedReport",
    }
    for _, fn in ipairs(names) do
        if _G[fn] then _G[fn] = NoOp end
        if _G.GameplayCallbacks and _G.GameplayCallbacks[fn] then
            _G.GameplayCallbacks[fn] = NoOp
        end
    end
end

local SUB_NAMES = {
    "AntiCheatSubsystem","HiggsBosonSubsystem",
    "ClientReportPlayerSubsystem",
    "BehaviorScoreSubsystem","ClientHawkEyePatrolSubsystem",
    "AFKReportorSubsystem","FileCheckSubsystem","MemoryCheckSubsystem",
    "MD5CheckSubsystem","ClientSwiftHawkSubsystem",
    "ModifierExceptionSubsystem","PakVerifySubsystem","IntegrityCheckSubsystem",
}

local function MuteSubsystems()
    local ok, mgr = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not ok or not mgr then return end
    for _, name in ipairs(SUB_NAMES) do
        local ok2, sub = pcall(function() return mgr:Get(name) end)
        if ok2 and sub then
            MuteFunctions(sub)
            pcall(function()
                sub.bBanned         = false
                sub.bKicked         = false
                sub.SuspicionScore  = 0
                sub.ReportData      = nil
                sub.ReportException = nil
            end)
        end
    end
end

local BLOCKED_PACKETS = {
    ["ReportCheat"]=1, ["ReportHack"]=1, ["BanPlayer"]=1, ["KickPlayer"]=1,
    ["CheatDetection"]=1, ["AntiCheatReport"]=1,
    ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1,
    ["client_anti_cheat_report"]=1, ["ReportSuspicious"]=1,
    ["SendBanReport"]=1, ["report_esp"]=1, ["report_modded_files"]=1,
    ["on_ban_notice"]=1, ["on_kick_notice"]=1,
    ["tss_sdk_report"]=1, ["report_lua_violation"]=1,
    ["report_player_move_route"]=1,
    ["ReportSimulateCharacterLocation"]=1,
    ["report_players_ping"]=1, ["report_player_ip"]=1, ["report_net_saturate"]=1,
}

local function HookSendPacket()
    if not NetUtil or type(NetUtil.SendPacket) ~= "function" then return end
    if NetUtil.__aegis then return end
    local orig = NetUtil.SendPacket
    NetUtil.SendPacket = function(pkt, ...)
        if BLOCKED_PACKETS[pkt] then return nil end
        return orig(pkt, ...)
    end
    NetUtil.__aegis = true
end

local function HookTSS()
    local tss = package.loaded["TssSdk"] or _G.TssSdk
    if not tss or tss.__aegis then return end
    tss.SendReportInfo      = NoOp
    tss.ScanMemory          = function() return true, {code=0, msg="clean"} end
    tss.ScanSo              = function() return true, {code=0, msg="clean"} end
    tss.ScanFile            = function() return true, {code=0} end
    tss.GetRiskFlag         = NoZero
    tss.VerifyFileHash      = NoOp
    tss.IsEmulator          = NoFalse
    tss.GetTssSdkReportInfo = NoStr
    tss.CheckEnvironment    = NoOp
    tss.VerifyProcess       = NoOp
    tss.CheckKernel         = function() return true, {status="verified", tampered=false} end
    tss.VerifyBoot          = function() return true, {locked=true, verified=true} end
    tss.OnRecvData = function(data)
        if type(data) == "string" then
            local low = data:lower()
            if low:find("report") or low:find("cheat") or low:find("ban") then return end
        end
    end
    tss.__aegis = true
end

local function HookFileIntegrity()
    local HASHES = {
        ["mini.21525.com.tencent.ig.obb"] = {
            md5    = "66424184654abd0fa81c39f34aa6d84b",
            sha1   = "d7918e862e2f09dd66b268b7327240491531ccdc",
            sha256 = "face18b7794f49155053360d1dae94125f080c1216fc098cb76cc0d71e5f20c1",
        },
        ["main.21525.com.tencent.ig.obb"] = {
            md5    = "fc9e43170b5e9318dc0285333079111d",
            sha1   = "bc5e376a48accf3325a444dabd7e297273e03fc2",
            sha256 = "e4f3cd257c3d3c1759f96a047253ec52e754174da397cb9484d3125cb7a3d9f2",
        },
        ["BRPlayerCharacterBase.lua"] = {
            md5    = "ea38f48a217c5f67551cdcc4d6d4cfeb",
            sha1   = "e939e59925a9256bf98f378ca66076e1f8987931",
            sha256 = "505c211cedf974fc6e072442f450e0f08a33f39931255e33714057ad0c6a28dc",
        },
    }
    local function findHashByPath(path, algo)
        if not path then return nil end
        local p = string.lower(tostring(path)):gsub("\\", "/")
        for pattern, hashes in pairs(HASHES) do
            local pat = string.lower(pattern):gsub("\\", "/")
            if p:find(pat, 1, true) then return hashes[algo] end
        end
        return nil
    end
    local function extractPath(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            if type(v) == "string" and v ~= "" then return v end
        end
        return nil
    end
    local ok, CM = pcall(function() return import("CreativeModeBlueprintLibrary") end)
    if ok and CM then
        local orig_md5, orig_sha1, orig_sha256 = CM.MD5HashFile, CM.SHA1HashFile, CM.SHA256HashFile
        CM.MD5HashFile = function(...)
            local path = extractPath(...)
            if path then
                local h = findHashByPath(path, "md5")
                if h and h ~= "" then return h end
            end
            if orig_md5 then return orig_md5(...) end
            return ""
        end
        CM.SHA1HashFile = function(...)
            local path = extractPath(...)
            if path then
                local h = findHashByPath(path, "sha1")
                if h and h ~= "" then return h end
            end
            if orig_sha1 then return orig_sha1(...) end
            return ""
        end
        CM.SHA256HashFile = function(...)
            local path = extractPath(...)
            if path then
                local h = findHashByPath(path, "sha256")
                if h and h ~= "" then return h end
            end
            if orig_sha256 then return orig_sha256(...) end
            return ""
        end
        CM.VerifyFileIntegrity = NoOp
        CM.GetContentDiffData  = function() return true, "OK" end
    end
    local ok2, KSL = pcall(function() return import("KismetSystemLibrary") end)
    if ok2 and KSL then
        pcall(function() KSL.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1") end)
        pcall(function() KSL.ExecuteConsoleCommand(nil, "sig.Check 0") end)
    end
end

local function HookScreenshotMaker()
    local ok, SM = pcall(import, "ScreenshotMaker")
    if not ok or not SM or SM.__aegis then return end
    if type(SM.MakePictureWithName) == "function" then SM.MakePictureWithName = function() return "" end end
    if type(SM.MakePicture) == "function" then SM.MakePicture = function() return "" end end
    if type(SM.SaveScreenshot) == "function" then SM.SaveScreenshot = function() return false end end
    for k, v in pairs(SM) do
        if type(v) == "function" and type(k) == "string" then
            if k:find("Picture") or k:find("Screenshot") or k:find("Capture") or k:find("Snap") then
                pcall(function() SM[k] = function() return "" end end)
            end
        end
    end
    SM.__aegis = true
end

local function HookNativeScreenshot()
    local ok, KSL = pcall(function() return import("KismetSystemLibrary") end)
    if ok and KSL then
        pcall(function() if KSL.CaptureScreenshot then KSL.CaptureScreenshot = function() return end end end)
    end
    local ok2, SR = pcall(import, "ScreenshotRequest")
    if ok2 and SR then
        for k, v in pairs(SR) do
            if type(v) == "function" and (k:find("Request") or k:find("Capture") or k:find("Take")) then
                pcall(function() SR[k] = function() return end end)
            end
        end
    end
    local ok3, PC = pcall(function()
        if _G.UE and _G.UE.UGameplayStatics then
            return _G.UE.UGameplayStatics.GetPlayerController(_G, 0)
        end
    end)
    if ok3 and PC then
        pcall(function()
            if PC.RequestScreenshot    then PC.RequestScreenshot    = function() return end end
            if PC.TakeScreenshot       then PC.TakeScreenshot       = function() return end end
            if PC.ClientScreenshot     then PC.ClientScreenshot     = function() return end end
            if PC.ServerScreenshot     then PC.ServerScreenshot     = function() return end end
            if PC.SendScreenshotToServer then PC.SendScreenshotToServer = function() return end end
            if PC.bEnableAntiCheatScreenshot ~= nil then PC.bEnableAntiCheatScreenshot = false end
        end)
    end
    local ok4, GI = pcall(function()
        local STExtraGameInstance = import("STExtraGameInstance")
        return STExtraGameInstance and STExtraGameInstance.GetInstance and STExtraGameInstance.GetInstance()
    end)
    if ok4 and GI then
        pcall(function() if GI.RequestScreenshot then GI.RequestScreenshot = function() return end end end)
    end
    for _, name in ipairs({"AntiCheatExpert","ACE","Anogs","Tss","TencentAntiCheat","TPAntiCheat"}) do
        local okx, mod = pcall(import, name)
        if okx and mod and not mod.__aegis_screen then
            for k, v in pairs(mod) do
                if type(v) == "function" and type(k) == "string" then
                    if k:find("Screenshot") or k:find("ScreenCapture") or k:find("TakeScreen") then
                        pcall(function() mod[k] = function() return end end)
                    end
                end
            end
            mod.__aegis_screen = true
        end
    end
end

local function HookServerVerify()
    local ok, PC = pcall(function()
        if _G.UE and _G.UE.UGameplayStatics then
            return _G.UE.UGameplayStatics.GetPlayerController(_G, 0)
        end
    end)
    if ok and PC then
        pcall(function()
            if PC.CheckNeedReport then PC.CheckNeedReport = NoFalse end
            if PC.ReportAntiCheatInfo then PC.ReportAntiCheatInfo = NoOp end
        end)
    end
    local ok2, char = pcall(function()
        if _G.UE and _G.UE.UGameplayStatics then
            return _G.UE.UGameplayStatics.GetPlayerCharacter(_G, 0)
        end
    end)
    if ok2 and char then
        pcall(function()
            local move = char.CharacterMovement
            if move and move.ClientAdjustPositionAndRotation then
                move.ClientAdjustPositionAndRotation = NoOp
            end
        end)
    end
end

local function Boot()
    Safe(MuteGlobals)
    Safe(MuteSubsystems)
    Safe(HookSendPacket)
    Safe(HookTSS)
    Safe(HookFileIntegrity)
    Safe(HookServerVerify)
    Safe(HookScreenshotMaker)
    Safe(HookNativeScreenshot)
    A.Up.Installed = true
    A.Up.Shielded  = true
    print("[AEGIS v3.5] loaded (No Name)")
end
Boot()

-- [FIX 1] Safe local binding for hot functions
local next   = next
local ipairs = ipairs
local pairs  = pairs
local pcall  = pcall
local type   = type
local tostring = tostring
local tonumber = tonumber
local math   = math
local string = string

-- ============================================================
-- PART 1/6 — LICENSE CORE (unchanged logic, minor hardening)
-- ============================================================

local MasterLicenseConfig = (function()
    return {
        url = 'https://sameer.keysgen.online/connect', game = 'PUBGM',
        timeout = 10, clockSkew = 120, expiryPath = nil,
        manualExpiry = "2026-12-31 23:59:59", tamperTolerance = 5,
        secret = 'DIAMONDYT',
    }
end)()

local MasterLicenseCore = (function()
    local Primitives = (function()
        local floor, abs, max = math.floor, math.abs, math.max
        local byte, char, format = string.byte, string.char, string.format
        local U32 = 4294967296
        local AND, XOR = {}, {}
        for a = 0, 15 do for b = 0, 15 do
            local av, bv, both, different, place = a, b, 0, 0, 1
            for _ = 1, 4 do
                local x, y = av % 2, bv % 2
                if x == 1 and y == 1 then both = both + place end
                if x ~= y then different = different + place end
                av, bv, place = floor(av / 2), floor(bv / 2), place * 2
            end
            AND[a * 16 + b], XOR[a * 16 + b] = both, different
        end end
        local function bitop(a, b, lookup)
            local value, place = 0, 1
            for _ = 1, 8 do
                value = value + lookup[(a % 16) * 16 + b % 16] * place
                a, b, place = floor(a / 16), floor(b / 16), place * 16
            end
            return value
        end
        local function band(a, b) return bitop(a, b, AND) end
        local function bxor(a, b) return bitop(a, b, XOR) end
        local function rol(value, amount)
            local divisor = 2 ^ (32 - amount)
            return (value % divisor) * 2 ^ amount + floor(value / divisor)
        end
        local function little32(value)
            return char(value % 256, floor(value / 256) % 256,
                floor(value / 65536) % 256, floor(value / 16777216) % 256)
        end
        local K = {
            0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
            0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
            0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
            0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
            0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
            0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
            0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
            0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391
        }
        local SHIFT = {7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21}
        local function md5_raw(input)
            assert(type(input) == "string", "MD5 input must be a string")
            local size = #input
            local message = input .. char(128) .. string.rep(char(0), (55 - size) % 64)
                .. little32((size * 8) % U32) .. little32(floor(size / 536870912))
            local h0, h1, h2, h3 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
            local words = {}
            for offset = 1, #message, 64 do
                for j = 0, 15 do
                    local a, b, c, d = byte(message, offset + j * 4, offset + j * 4 + 3)
                    words[j] = a + b * 256 + c * 65536 + d * 16777216
                end
                local a, b, c, d = h0, h1, h2, h3
                for i = 0, 63 do
                    local f, g, shiftBase
                    if i < 16 then
                        f, g, shiftBase = band(b, c) + band(U32 - 1 - b, d), i, 0
                    elseif i < 32 then
                        f, g, shiftBase = band(d, b) + band(U32 - 1 - d, c), (5 * i + 1) % 16, 4
                    elseif i < 48 then
                        f, g, shiftBase = bxor(bxor(b, c), d), (3 * i + 5) % 16, 8
                    else
                        local bOrNotD = U32 - 1 - band(U32 - 1 - b, d)
                        f, g, shiftBase = bxor(c, bOrNotD), (7 * i) % 16, 12
                    end
                    local nextB = (b + rol((a + f + K[i + 1] + words[g]) % U32,
                        SHIFT[shiftBase + i % 4 + 1])) % U32
                    a, b, c, d = d, nextB, b, c
                end
                h0, h1, h2, h3 = (h0 + a) % U32, (h1 + b) % U32, (h2 + c) % U32, (h3 + d) % U32
            end
            return little32(h0) .. little32(h1) .. little32(h2) .. little32(h3)
        end
        local function hex(input)
            return (input:gsub(".", function(c) return format("%02x", byte(c)) end))
        end
        local function md5(input) return hex(md5_raw(input)) end
        local function form_encode(input)
            assert(type(input) == "string", "Form value must be a string")
            return (input:gsub("[^A-Za-z0-9%-%._~ ]", function(c)
                return format("%%%02X", byte(c)) end):gsub(" ", "+"))
        end
        local function constant_time_equal(a, b)
            if type(a) ~= "string" or type(b) ~= "string" then return false end
            local difference = abs(#a - #b)
            for i = 1, max(#a, #b) do
                difference = difference + abs((byte(a, i) or 0) - (byte(b, i) or 0))
            end
            return difference == 0
        end
        local function name_uuid(input)
            local digest = md5_raw(input)
            local h = hex(digest:sub(1,6) .. char(byte(digest,7) % 16 + 48)
                .. digest:sub(8,8) .. char(byte(digest,9) % 64 + 128) .. digest:sub(10))
            return h:sub(1,8) .. "-" .. h:sub(9,12) .. "-" .. h:sub(13,16)
                .. "-" .. h:sub(17,20) .. "-" .. h:sub(21,32)
        end
        return {md5 = md5, md5_raw = md5_raw, form_encode = form_encode,
                constant_time_equal = constant_time_equal, name_uuid = name_uuid}
    end)()

    local SESSION_KEY = '__MasterLicenseSession_v1'
    local SAVED_KEY_FILE = 'UX_Official_license_key.txt'

    local function getSavedKeyPaths()
        return {
            '/Documents/UXOfficialTrackerExtra/Saved/Paks/' .. SAVED_KEY_FILE,
            '/Documents/UXOfficialTrackerExtra/Saved/Paks/puffer_temp/' .. SAVED_KEY_FILE,
            'UXOfficialTrackerExtra/Saved/Paks/' .. SAVED_KEY_FILE,
            '../../UXOfficialTrackerExtra/Saved/Paks/' .. SAVED_KEY_FILE,
            '//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/UXOfficialTrackerExtra/UXOfficialTrackerExtra/Saved/Paks/' .. SAVED_KEY_FILE,
            '//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/UXOfficialTrackerExtra/UXOfficialTrackerExtra/Saved/Paks/' .. SAVED_KEY_FILE,
        }
    end

    local function loadSavedKey()
        for _, path in ipairs(getSavedKeyPaths()) do
            local f = io.open(path, 'r')
            if f then
                local key = f:read('*a')
                f:close()
                if type(key) == 'string' then
                    key = key:match('^%s*(.-)%s*$')
                    if #key > 0 and #key <= 512 then return key end
                end
            end
        end
        return nil
    end

    local function saveSavedKey(key)
        if type(key) ~= 'string' then return false end
        key = key:match('^%s*(.-)%s*$')
        if #key == 0 or #key > 512 then return false end
        local wroteAny = false
        for _, path in ipairs(getSavedKeyPaths()) do
            local f = io.open(path, 'w')
            if f then
                f:write(key)
                f:close()
                wroteAny = true
            end
        end
        return wroteAny
    end

    local function loadSession()
        local g = rawget(_G, SESSION_KEY)
        if type(g) ~= 'table' or g.authorized ~= true then return nil end
        if type(g.expiresAt) == 'number' and g.expiresAt <= os.time() then
            _G[SESSION_KEY] = nil; return nil
        end
        return g
    end
    local function saveSession(expiresAt)
        pcall(function()
            _G[SESSION_KEY] = {authorized = true, expiresAt = expiresAt, issuedAt = os.time()}
        end)
    end
    local function clearSession() pcall(function() _G[SESSION_KEY] = nil end) end

    local CreateLocalExpiry = (function()
        return function(cfg, wallReader)
            local E = {}
            local expiredText = 'Mod expired. DM +92 [ 03704831068 ] for renewal.'
            local tamperText  = "Don't be over smart"
            local blockedMessage, blockedPhase
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function parse(text)
                if type(text) ~= 'string' then return nil end
                local y,m,d,h,n,s = text:match('^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)$')
                y,m,d,h,n,s = tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n),tonumber(s)
                if not y or y < 1970 or y > 9999 or m < 1 or m > 12 or h > 23 or n > 59 or s > 59 then return nil end
                local leap = y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
                local months = {31, leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
                if d < 1 or d > months[m] then return nil end
                local prior = y - 1
                local days = 365 * (y - 1970) + math.floor(prior / 4) - math.floor(1969 / 4)
                    - math.floor(prior / 100) + math.floor(1969 / 100)
                    + math.floor(prior / 400) - math.floor(1969 / 400)
                for i = 1, m - 1 do days = days + months[i] end
                return (days + d - 1) * 86400 + h * 3600 + n * 60 + s - 6 * 3600
            end
            local configured = type(cfg.manualExpiry) == 'string'
                and cfg.manualExpiry:match('^%s*(.-)%s*$') or cfg.manualExpiry
            local expiry = parse(configured)
            local skew = cfg.clockSkew or 120
            if configured ~= nil and configured ~= '' and not expiry then
                blockedMessage, blockedPhase = 'Invalid local expiry date. Use YYYY-MM-DD HH:MM:SS.', 'error'
            end
            local function block(message, phase)
                if not blockedMessage then blockedMessage, blockedPhase = message, phase end
                return false, blockedMessage, blockedPhase
            end
            function E.Status() return not blockedMessage, blockedMessage, blockedPhase end
            function E.MarkTampered() return block(tamperText, 'tampered') end
            function E.GetExpiry() return expiry end
            function E.Accept(server, now, world, phone, rtt)
                if blockedMessage then return E.Status() end
                if not finite(server) or not finite(now) or now < 0 or world == nil
                    or not finite(rtt) or rtt < 0 or not finite(phone) then
                    return block('Clock verification unavailable.', 'error')
                end
                if math.abs(phone - server) > skew + rtt then return E.MarkTampered() end
                if expiry and server + rtt >= expiry then return block(expiredText, 'expired') end
                return true
            end
            return E
        end
    end)()

    local CreateAuth = (function()
        return function(P, cfg, deps)
            local A = {}
            local phase, message = 'locked', 'Enter your key to sign in.'
            local allowed, pending, generation = false, nil, 0
            local expiresAt
            local lastRequestLatencyMs, lastResponseTime, lastResponseWorld
            local startFn, stopFn, payloadStarted, restartRequired
            local localExpiry = deps.localExpiry
            local savedKey = loadSavedKey()
            do
                local stored = loadSession()
                if stored then
                    allowed = true; expiresAt = stored.expiresAt
                    phase, message = 'active', 'Session restored'
                end
            end
            if localExpiry then
                local ok, text, state = localExpiry.Status()
                if not ok then message, phase = text, state end
            end
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function readClock()
                local ok, n, w = pcall(deps.clock)
                if ok and finite(n) and n >= 0 and w ~= nil then return n, w end
            end
            local function notify(text, state)
                message, phase = text, state
                if type(deps.status) == 'function' then pcall(deps.status, text, state) end
            end
            local function stopPayload()
                if payloadStarted then
                    payloadStarted = false
                    local ok, accepted = pcall(stopFn)
                    if not ok or accepted == false then restartRequired = true end
                end
            end
            local function revoke(text, state)
                generation = generation + 1
                allowed, pending, expiresAt = false, nil, nil
                lastRequestLatencyMs, lastResponseTime, lastResponseWorld = nil, nil, nil
                stopPayload()
                local localDenied = false
                if localExpiry then
                    local ok, localText, localPhase = localExpiry.Status()
                    if not ok then text, state, localDenied = localText, localPhase, true end
                end
                notify(restartRequired and not localDenied
                    and 'Restart required: payload cleanup failed.' or text, state or 'error')
            end
            local function startPayload()
                if payloadStarted or not startFn then return true end
                payloadStarted = true
                local before = generation
                local ok, accepted = pcall(startFn)
                if not ok or accepted == false then
                    restartRequired = true
                    revoke('Restart required: offline script startup failed.', 'error')
                    return false
                end
                return generation == before and allowed
            end
            local function denyReason(reason)
                if type(reason) ~= 'string' then return 'Expired' end
                local lower = reason:sub(1, 120):lower():gsub('[_%s%-]+', ' ')
                if lower == 'max devices' or lower == 'maximum devices'
                    or lower == 'max devices reached' then
                    return 'Max Devices'
                end
                local clean = reason
                for _, field in ipairs({'key', 'serial'}) do
                    if pending and type(pending[field]) == 'string' and #pending[field] > 0 then
                        local needle = pending[field]:gsub('([^%w])', '%%%1')
                        clean = clean:gsub(needle, '[' .. field .. ']')
                    end
                end
                if type(cfg.secret) == 'string' and #cfg.secret > 0 then
                    clean = clean:gsub(cfg.secret:gsub('([^%w])', '%%%1'), '[credential]')
                end
                clean = clean:gsub('[%c]', ' '):sub(1, 120)
                return clean == '' and 'Expired' or ('Expired: ' .. clean)
            end
            local function configuredExpiry(result)
                if cfg.expiryPath == nil then return nil, true end
                if type(cfg.expiryPath) ~= 'table' or #cfg.expiryPath == 0 then return nil, false end
                local v = result
                for _, name in ipairs(cfg.expiryPath) do
                    if type(v) ~= 'table' then return nil, false end
                    v = rawget(v, name)
                end
                return v, finite(v) and v > 0 and v % 1 == 0
            end
            local function begin(key)
                if restartRequired or pending then return false end
                if localExpiry then
                    local ok, text, state = localExpiry.Status()
                    if not ok then revoke(text, state); return false end
                end
                if type(key) ~= 'string' then key = '' end
                key = key:match('^%s*(.-)%s*$')
                if #key == 0 or #key > 512 then
                    revoke('Expired: enter a valid key.', 'denied'); return false
                end
                local now, world = readClock()
                if not now then
                    revoke('Game clock unavailable. Try again in a match.', 'error'); return false
                end
                local okSerial, serial = pcall(deps.serial, key)
                if not okSerial or type(serial) ~= 'string' or #serial == 0 or #serial > 512 then
                    revoke('Device identifier unavailable.', 'error'); return false
                end
                generation = generation + 1
                local requestId = generation
                pending = {id = requestId, key = key, serial = serial,
                           started = now, world = world, deadline = now + cfg.timeout}
                notify('Signing in...', 'pending')
                if not pending or pending.id ~= requestId or generation ~= requestId then return false end
                local body = 'game=' .. P.form_encode(cfg.game)
                    .. '&user_key=' .. P.form_encode(key)
                    .. '&serial=' .. P.form_encode(serial)
                local function received(success, raw)
                    if not pending or pending.id ~= requestId or generation ~= requestId then return end
                    local current, worldNow = readClock()
                    if not current or worldNow ~= pending.world or current < pending.started
                        or current >= pending.deadline then
                        revoke('Request expired. Please sign in again.', 'error'); return
                    end
                    if success ~= true or type(raw) ~= 'string' or #raw == 0 or #raw > 32768 then
                        revoke('Connection failed. Please try again.', 'error'); return
                    end
                    local ok, result = pcall(deps.decode, raw)
                    if not ok or type(result) ~= 'table' then
                        revoke('Invalid server response.', 'error'); return
                    end
                    if result.status ~= true then revoke(denyReason(result.reason), 'denied'); return end
                    local data = result.data
                    if type(data) ~= 'table' or type(data.token) ~= 'string' or #data.token ~= 32
                        or not data.token:match('^[%x]+$') or not finite(data.rng) or data.rng % 1 ~= 0 then
                        revoke('Incomplete server response.', 'error'); return
                    end
                    local expected = P.md5(cfg.game .. '-' .. key .. '-' .. serial .. '-' .. cfg.secret)
                    if not P.constant_time_equal(data.token:lower(), expected) then
                        revoke('Server token verification failed.', 'denied'); return
                    end
                    local okWall, wall = pcall(deps.wall)
                    if not okWall or not finite(wall) then
                        revoke('Phone clock unavailable.', 'error'); return
                    end
                    if localExpiry then
                        local accepted, text, state = localExpiry.Accept(
                            data.rng, current, worldNow, wall, current - pending.started)
                        if not accepted then revoke(text, state); return end
                    elseif math.abs(wall - data.rng) > cfg.clockSkew then
                        revoke('Phone/server clock mismatch. Check automatic time.', 'error'); return
                    end
                    local expiry, validExpiry = configuredExpiry(result)
                    if not validExpiry then
                        revoke('Configured server expiry field is missing or invalid.', 'error'); return
                    end
                    if expiry and expiry - data.rng - (current - pending.started) <= 0 then
                        revoke('Expired', 'denied'); return
                    end
                    local fixedExpiry = localExpiry and localExpiry.GetExpiry()
                    if fixedExpiry then expiry = math.min(expiry or fixedExpiry, fixedExpiry) end
                    lastRequestLatencyMs = (current - pending.started) * 1000
                    lastResponseTime, lastResponseWorld = current, worldNow
                    pending = nil
                    allowed, expiresAt = true, expiry
                    saveSession(expiresAt)
                    pcall(function()
                        saveSavedKey(key)
                        savedKey = key
                        _G.__UX_SAVED_LICENSE_KEY = key
                    end)
                    if not startPayload() then return end
                    notify('Login successful.', 'active')
                end
                local ok, accepted = pcall(deps.post, cfg.url,
                    {['Content-Type'] = 'application/x-www-form-urlencoded'},
                    body, received, cfg.timeout)
                if not ok or accepted == false then
                    revoke('HTTP request could not start.', 'error'); return false
                end
                return true
            end
            function A.Login(key) if allowed then return false end; return begin(key) end
            function A.Tick()
                if not pending then return end
                local now, world = readClock()
                if not now or world ~= pending.world or now < pending.started then
                    revoke('Login interrupted by map loading. Please try again when ready.', 'locked'); return
                end
                if now >= pending.deadline then
                    revoke('Request timed out. Please try again.', 'error')
                end
            end
            function A.IsAuthorized()
                if allowed and not restartRequired then return true end
                local stored = loadSession()
                if stored and not restartRequired then
                    allowed = true; expiresAt = stored.expiresAt; return true
                end
                return false
            end
            function A.Logout() clearSession(); revoke('Expired: signed out.', 'locked') end
            function A.FailClosed(text, requiresRestart)
                if requiresRestart == true then restartRequired = true end
                revoke(text or 'Online access unavailable.', 'error')
            end
            function A.ReportClockTampering()
                if localExpiry then localExpiry.MarkTampered() end
                revoke("Don't be over smart", 'tampered')
            end
            function A.Bind(onStart, onStop)
                if type(onStart) ~= 'function' or type(onStop) ~= 'function' then
                    return false, 'START_AND_STOP_REQUIRED'
                end
                if startFn and (startFn ~= onStart or stopFn ~= onStop) then
                    return false, 'ALREADY_BOUND'
                end
                startFn, stopFn = onStart, onStop
                if A.IsAuthorized() then return startPayload() end
                return true
            end
            function A.Unbind()
                revoke('Offline script disconnected.', 'locked')
                startFn, stopFn = nil, nil
            end
            function A.GetSavedKey()
                if type(savedKey) == 'string' and #savedKey > 0 then return savedKey end
                local g = rawget(_G, '__UX_SAVED_LICENSE_KEY')
                if type(g) == 'string' and #g > 0 then return g end
                return nil
            end
            function A.SetSavedKey(key)
                if type(key) ~= 'string' then return false end
                key = key:match('^%s*(.-)%s*$')
                if #key == 0 or #key > 512 then return false end
                savedKey = key
                pcall(function()
                    _G.__UX_SAVED_LICENSE_KEY = key
                    saveSavedKey(key)
                end)
                return true
            end
            function A.GetRemainingSeconds() return nil end
            function A.GetState()
                local authorized = A.IsAuthorized()
                local sample, age
                if authorized and lastRequestLatencyMs ~= nil then
                    local now, world = readClock()
                    if now and world == lastResponseWorld and now >= lastResponseTime then
                        sample, age = lastRequestLatencyMs, now - lastResponseTime
                    end
                end
                return {
                    phase = phase, message = message, authorized = authorized,
                    sessionAuthorized = authorized, expiresAt = expiresAt,
                    accessPolicy = "game_session", expiryCheckPolicy = "login_only",
                    periodicRecheck = false, pending = pending ~= nil,
                    linked = startFn ~= nil, restartRequired = restartRequired == true,
                    lastRequestLatencyMs = sample, lastRequestLatencyAgeSeconds = age,
                    latencyScope = "license_http_round_trip"
                }
            end
            return A
        end
    end)()

    local Core = {Primitives = Primitives, createExpiry = CreateLocalExpiry}
    function Core.new(config, dependencies)
        assert(type(config) == 'table' and type(dependencies) == 'table',
            'License configuration and dependencies required')
        local deps = {}
        for key, value in pairs(dependencies) do deps[key] = value end
        if deps.localExpiry == nil then deps.localExpiry = CreateLocalExpiry(config, deps.wall) end
        return CreateAuth(Primitives, config, deps)
    end
    return Core
end)()

print("[NADEEM 1/6] Auth core loaded")

-- ============================================================
-- PART 2/6 — Login UI + Welcome UI
-- ============================================================

local MasterLoginUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(name)
            local ok, value = pcall(function() return env[name] end)
            if ok then return value end
        end
        local UI = {_status = "Enter your key", _busy = false, _data = nil}
        local function member(object, name)
            if object == nil then return nil end
            local ok, value = pcall(function() return object[name] end)
            if ok then return value end
        end
        local function valid(object)
            local check = member(global("slua"), "isValid")
            if object == nil then return false end
            if type(check) == 'function' then
                local ok, result = pcall(check, object)
                if ok and result == true then return true end
            end
            local game = global('Game')
            local fallback = member(game, 'IsValid')
            if type(fallback) == 'function' then
                local ok, result = pcall(fallback, game, object)
                return ok and result == true
            end
            return false
        end
        local function imported(name)
            local loader = global("import")
            if type(loader) ~= "function" then return nil end
            local ok, result = pcall(loader, name)
            if ok then return result end
        end
        local function construct(class, ...)
            if class == nil then return nil end
            local ok, result = pcall(class, ...)
            if ok then return result end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y)
                or {X = x, Y = y}
        end
        local function color(r, g, b, a)
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(widget, value)
            local setter = member(widget, "SetWidgetVisibility") or member(widget, "SetVisibility")
            assert(type(setter) == "function", "UI_VISIBILITY_UNAVAILABLE")
            setter(widget, value)
        end
        local function setTextStyle(widget, size, textColor)
            pcall(function()
                local font = widget.Font
                if font then
                    font.Size = math.max(1, math.floor(size * (UI._scale or 1) + 0.5))
                    local assigned = pcall(function() widget.Font = font end)
                    if not assigned then widget:SetFont(font) end
                end
            end)
            pcall(function() widget:SetAutoWrapText(true) end)
            pcall(function()
                local slate = construct(imported("SlateColor"), textColor)
                if slate then widget:SetColorAndOpacity(slate) end
            end)
        end
        local function detach(data)
            if not data then return end
            data.visible = false
            pcall(function() if valid(data.input) then data.input:SetText("") end end)
            if data.event and data.eventHandle ~= nil then
                pcall(function() data.event:Remove(data.eventHandle) end)
            end
            if valid(data.container) then
                pcall(function() data.container:RemoveFromParent() end)
            end
            data.onSubmit = nil
        end
        function UI.Destroy()
            local previous = UI._data; UI._data = nil; detach(previous)
        end
        function UI.Hide()
            local data = UI._data
            if not data or data.hiddenApplied then return true end
            data.visible = false
            local ok = pcall(function()
                if valid(data.input) then data.input:SetText("") end
                if valid(data.container) then visibility(data.container, data.hidden) end
            end)
            if ok then data.hiddenApplied = true end
            return ok
        end
        function UI.SetStatus(message)
            UI._status = type(message) == "string" and message:sub(1, 160) or "Login unavailable"
            local data = UI._data
            if data and data.deliveredStatus == UI._status then return true end
            if data and valid(data.status) then
                local ok = pcall(function() data.status:SetText(UI._status) end)
                if ok then data.deliveredStatus = UI._status end
                return ok
            end
            return false
        end
        function UI.SetBusy(busy)
            UI._busy = busy == true
            local data = UI._data
            if data then
                if data.deliveredBusy == UI._busy then return true end
                local buttonOK = pcall(function() data.button:SetIsEnabled(not UI._busy) end)
                local inputOK  = pcall(function() data.input:SetIsEnabled(not UI._busy) end)
                if buttonOK and inputOK then data.deliveredBusy = UI._busy; return true end
            end
            return false
        end
        local function fitScale(parent)
            local result = 1
            pcall(function()
                local size = parent:GetCachedGeometry():GetLocalSize()
                local width, height = size.X, size.Y
                if type(width) == 'number' and type(height) == 'number'
                    and width > 24 and height > 24 then
                    result = math.min(1, (width - 24) / 500, (height - 24) / 248)
                end
            end)
            return result
        end
        function UI.Show(onSubmit, initialKey)
            if type(onSubmit) ~= "function" then return false, "UI_SUBMIT_REQUIRED" end
            if type(initialKey) == "string" then
                initialKey = initialKey:match("^%s*(.-)%s*$")
                if #initialKey == 0 or #initialKey > 512 then initialKey = nil end
            else
                initialKey = nil
            end
            local data = UI._data
            if data and valid(data.parent)
                and math.abs(fitScale(data.parent) - (data.scale or 1)) > 0.001 then
                UI.Destroy(); data = nil
            end
            if data and valid(data.container) and valid(data.parent) then
                local ok = data.visible or pcall(function()
                    visibility(data.container, data.visibleEnum)
                end)
                if ok then
                    data.onSubmit, data.visible, data.hiddenApplied = onSubmit, true, false
                    if initialKey and valid(data.input) then pcall(function() data.input:SetText(initialKey) end) end
                    UI.SetStatus(UI._status); UI.SetBusy(UI._busy); return true
                end
            end
            UI.Destroy()
            local okTools, uiTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local getRoot = okTools and member(uiTools, "GetMainControlBaseUI")
            if type(getRoot) ~= "function" then return false, "UI_NOT_READY" end
            local okRoot, root = pcall(getRoot)
            if not okRoot or not valid(root) then return false, "UI_NOT_READY" end
            local parent = member(root, "CanvasPanel_0")
            if not valid(parent) then parent = member(root, "CanvasPanel_42") end
            if not valid(parent) then return false, "UI_NOT_READY" end
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "UI_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visibleEnum, hidden = member(enums, "Visible"), member(enums, "Collapsed")
            local passive = member(enums, "SelfHitTestInvisible")
            if visibleEnum == nil or hidden == nil or passive == nil then
                return false, "UI_ENUM_UNAVAILABLE"
            end
            UI._scale = fitScale(parent)
            data = {parent = parent, visible = false, onSubmit = onSubmit,
                    initialKey = initialKey, visibleEnum = visibleEnum, hidden = hidden, scale = UI._scale}
            local okBuild = pcall(function()
                local function make(class, outer)
                    local widget = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(widget), "UI_WIDGET_UNAVAILABLE")
                    return widget
                end
                data.container = make("CanvasPanel", parent)
                local function add(widget, x, y, width, height, z)
                    local slot = data.container:AddChildToCanvas(widget)
                    slot:SetAutoSize(false)
                    slot:SetPosition(vector(x * UI._scale, y * UI._scale))
                    slot:SetSize(vector(width * UI._scale, height * UI._scale))
                    slot:SetZOrder(z)
                    return slot
                end
                local background = make("Border", data.container)
                background:SetBrushColor(color(0.025, 0.035, 0.05, 0.98))
                visibility(background, visibleEnum)
                add(background, 0, 0, 500, 248, 0)
                local title = make("TextBlock", data.container)
                title:SetText("t.me/PAKxTEAM7 03211154129 LOGIN")
                setTextStyle(title, 19, color(0.1, 0.9, 1, 1))
                visibility(title, passive); add(title, 22, 15, 456, 30, 1)
                data.input = make("EditableTextBox", data.container)
                data.input:SetText(initialKey or "")
                setTextStyle(data.input, 17, color(0.92, 0.94, 0.96, 1))
                pcall(function() data.input:SetHintText("Enter your key") end)
                visibility(data.input, visibleEnum); add(data.input, 22, 58, 456, 44, 2)
                local hint = make("TextBlock", data.container)
                hint:SetText("Enter your key, then tap LOGIN.")
                setTextStyle(hint, 12, color(0.72, 0.78, 0.83, 1))
                visibility(hint, passive); add(hint, 22, 106, 456, 20, 2)
                data.status = make("TextBlock", data.container)
                data.status:SetText(UI._status); data.deliveredStatus = UI._status
                setTextStyle(data.status, 13, color(0.92, 0.94, 0.96, 1))
                visibility(data.status, passive)
                pcall(function() data.status:SetAutoWrapText(true) end)
                add(data.status, 22, 129, 456, 54, 2)
                data.button = make("Button", data.container)
                visibility(data.button, visibleEnum)
                local label = make("TextBlock", data.button)
                label:SetText("LOGIN")
                setTextStyle(label, 17, color(0.05, 0.08, 0.12, 1))
                visibility(label, passive); data.button:AddChild(label)
                add(data.button, 150, 190, 200, 40, 2)
                data.event = data.button.OnClicked
                data.eventHandle = data.event:Add(function()
                    if UI._data ~= data or not data.visible or UI._busy then return end
                    local readOK, key = pcall(function() return data.input:GetText() end)
                    if not readOK or type(key) ~= "string" then
                        UI.SetStatus("Unable to read the key"); return
                    end
                    key = key:match("^%s*(.-)%s*$")
                    if key == "" or #key > 512 then UI.SetStatus("Enter a valid key"); return end
                    local submitOK = pcall(data.onSubmit, key)
                    if not submitOK then UI.SetBusy(false); UI.SetStatus("Login could not start") end
                end)
                local slot = parent:AddChildToCanvas(data.container)
                slot:SetAutoSize(false)
                slot:SetSize(vector(500 * UI._scale, 248 * UI._scale))
                slot:SetZOrder(9000)
                local anchors = slot:GetAnchors()
                anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
                slot:SetAnchors(anchors)
                slot:SetAlignment(vector(0.5, 0.5))
                slot:SetPosition(vector(0, 0))
                visibility(data.container, passive)
            end)
            if not okBuild then
                detach(data); return false, "UI_BUILD_UNAVAILABLE"
            end
            data.visible = true; UI._data = data; UI.SetBusy(UI._busy)
            return true
        end
        function UI.ShowNotice(message)
            local shown, reason = UI.Show(function() return false end)
            if not shown then return false, reason end
            UI.SetStatus(message); UI.SetBusy(true); return true
        end
        return UI
    end
    return Module
end)()

-- WELCOME UI
local MasterWelcomeUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(n)
            local ok, v = pcall(function() return env[n] end)
            if ok then return v end
        end
        local function member(o, k)
            if o == nil then return nil end
            local ok, v = pcall(function() return o[k] end)
            if ok then return v end
        end
        local function valid(o)
            local c = member(global("slua"), "isValid")
            if o == nil then return false end
            if type(c) == 'function' then
                local ok, v = pcall(c, o)
                if ok and v == true then return true end
            end
            local g = global('Game'); local f = member(g, 'IsValid')
            if type(f) == 'function' then
                local ok, v = pcall(f, g, o)
                return ok and v == true
            end
            return false
        end
        local function imported(n)
            local l = global("import")
            if type(l) ~= "function" then return nil end
            local ok, v = pcall(l, n); if ok then return v end
        end
        local function construct(c, ...)
            if c == nil then return nil end
            local ok, v = pcall(c, ...); if ok then return v end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y) or {X = x, Y = y}
        end
        local function linear(v)
            v = v / 255
            if v <= 0.04045 then return v / 12.92 end
            return ((v + 0.055) / 1.055) ^ 2.4
        end
        local function color(r, g, b, a)
            r, g, b, a = linear(r), linear(g), linear(b), a or 1
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(w, v)
            local s = member(w, "SetWidgetVisibility") or member(w, "SetVisibility")
            if type(s) == 'function' then s(w, v) end
        end
        local WelcomeUI = {Width = 600, Height = 276}
        local WelcomeText = {
            "OWNER [ +923211154129 ]",
            "Kill limit 8-10",
            "Play smart and avoid report",
        }
        local UI = {_shown = false, _data = nil, _dismissTimer = nil}
        local function detach(data)
            if not data then return end
            data.Visible = false
            if data.Event and data.EventHandle ~= nil then
                pcall(function() data.Event:Remove(data.EventHandle) end)
            end
            if valid(data.Container) then
                pcall(function() visibility(data.Container, data.Hidden) end)
                pcall(function() data.Container:RemoveFromParent() end)
            end
        end
        function UI:Destroy()
            local p = UI._data; UI._data = nil; detach(p)
        end
        local function parent()
            local okT, tools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            if not okT then return nil end
            local getRoot = member(tools, "GetMainControlBaseUI")
            if type(getRoot) ~= "function" then return nil end
            local ok, root = pcall(getRoot)
            if not ok or not valid(root) then return nil end
            local canvas = member(root, "CanvasPanel_0")
            if not valid(canvas) then canvas = member(root, "CanvasPanel_42") end
            if valid(canvas) then return root, canvas end
        end
        function UI:Show()
            if UI._shown and UI._data and valid(UI._data.Container) then
                visibility(UI._data.Container, UI._data.Passive)
                UI._data.Visible = true
                return true
            end
            UI:Destroy()
            local root, par = parent()
            if not par then return false, "WELCOME_ROOT_UNAVAILABLE" end
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "WELCOME_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visible, hidden, passive = member(enums, "Visible"),
                member(enums, "Collapsed"), member(enums, "SelfHitTestInvisible")
            if visible == nil or hidden == nil or passive == nil then
                return false, "WELCOME_ENUM_UNAVAILABLE"
            end
            local data = {Root = root, Parent = par, Visible = false,
                          Hidden = hidden, Passive = passive}
            local ok = pcall(function()
                local function make(class, outer)
                    local w = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(w), "WELCOME_WIDGET_UNAVAILABLE")
                    return w
                end
                data.Container = make("CanvasPanel", par)
                visibility(data.Container, hidden)
                local function add(w, x, y, ww, hh, z)
                    local s = data.Container:AddChildToCanvas(w)
                    s:SetAutoSize(false)
                    s:SetPosition(vector(x, y))
                    s:SetSize(vector(ww, hh))
                    s:SetZOrder(z)
                    return s
                end
                local function rect(x, y, ww, hh, c, z)
                    local w = make("Border", data.Container)
                    w:SetBrushColor(c)
                    visibility(w, passive)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local slateColor
                pcall(function() slateColor = imported("SlateColor") end)
                local function textStyle(w, size, c)
                    local font = member(w, "Font")
                    if font ~= nil then
                        if type(font) == 'table' then
                            local copy = {}
                            for k, v in pairs(font) do copy[k] = v end
                            font = copy
                        end
                        font.Size = size
                        pcall(function() w:SetFont(font) end)
                    end
                    pcall(function() w:SetColorAndOpacity(slateColor and slateColor(c) or c) end)
                    pcall(function() w:SetJustification(1) end)
                    visibility(w, passive)
                end
                local function text(value, x, y, ww, hh, size, c, z)
                    local w = make("TextBlock", data.Container)
                    w:SetText(value)
                    textStyle(w, size, c)
                    pcall(function() w:SetAutoWrapText(true) end)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local W, H = WelcomeUI.Width, WelcomeUI.Height
                rect(4, 6, W, H, color(18, 5, 10, 0.25), 0)
                rect(0, 0, W, H, color(186, 137, 74), 1)
                rect(2, 2, W - 4, H - 4, color(255, 244, 214), 2)
                local stops = {{116, 16, 46}, {169, 38, 47}, {194, 105, 35}}
                local segments = 64
                for i = 0, segments - 1 do
                    local t = i / (segments - 1)
                    local left, right, blend
                    if t <= 0.5 then left, right, blend = stops[1], stops[2], t * 2
                    else left, right, blend = stops[2], stops[3], (t - 0.5) * 2 end
                    local x0 = 2 + (W - 4) * i / segments
                    local x1 = 2 + (W - 4) * (i + 1) / segments
                    rect(x0, 2, math.min(W - 2, x1 + 0.3) - x0, 76,
                        color(left[1] + (right[1] - left[1]) * blend,
                              left[2] + (right[2] - left[2]) * blend,
                              left[3] + (right[3] - left[3]) * blend), 3)
                end
                rect(18, 3, W - 36, 1, color(255, 255, 255, 0.32), 4)
                rect(2, 78, W - 4, 3, color(238, 188, 93), 4)
                local title = text(WelcomeText[1], 24, 23, W - 48, 44, 19, color(255, 253, 247), 5)
                pcall(function() title:SetShadowOffset(vector(0, 1)) end)
                pcall(function() title:SetShadowColorAndOpacity(color(40, 3, 12, 0.45)) end)
                rect(30, 100, W - 60, 54, color(255, 226, 159), 3)
                rect(30, 100, 4, 54, color(160, 33, 49), 4)
                text(WelcomeText[2], 46, 110, W - 92, 38, 23, color(115, 25, 45), 5)
                text(WelcomeText[3], 30, 168, W - 60, 32, 17, color(130, 34, 47), 5)
                local button = make("Button", data.Container)
                pcall(function() button:SetBackgroundColor(color(131, 25, 47)) end)
                visibility(button, visible)
                local label = make("TextBlock", button)
                label:SetText("OK")
                textStyle(label, 17, color(255, 251, 238))
                local ls = button:AddChild(label)
                pcall(function() ls:SetHorizontalAlignment(2) end)
                pcall(function() ls:SetVerticalAlignment(2) end)
                add(button, (W - 164) / 2, 212, 164, 42, 6)
                data.Event = member(button, "OnClicked")
                data.EventHandle = data.Event:Add(function()
                    if UI._data == data and data.Visible then UI:Destroy() end
                end)
                local slot = par:AddChildToCanvas(data.Container)
                slot:SetAutoSize(false)
                slot:SetSize(vector(W, H))
                slot:SetZOrder(9200)
                local anchors = slot:GetAnchors()
                anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
                slot:SetAnchors(anchors)
                slot:SetAlignment(vector(0.5, 0.5))
                slot:SetPosition(vector(0, 0))
                visibility(data.Container, passive)
            end)
            if not ok then detach(data); return false, "WELCOME_BUILD_FAILED" end
            data.Visible = true
            UI._data = data
            UI._shown = true
            pcall(function()
                local ticker = require("common.time_ticker")
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(10.0, function()
                        if UI._data == data then
                            pcall(function() UI:Destroy() end)
                        end
                    end)
                end
            end)
            return true
        end
        function UI:Hide() if UI._data then detach(UI._data) end; UI._data = nil end
        function UI:IsShown() return UI._shown == true end
        return UI
    end
    return Module
end)()
_G.MasterWelcomeUI = MasterWelcomeUI

print("[NADEEM 2/6] Login + Welcome UI loaded")

-- ============================================================
-- PART 3/6 — Runtime + Bootstrap + Legacy + Trigger + MATCH RESET
-- ============================================================

local MasterLicenseRuntime = (function()
    local Runtime = {}
    Runtime.__index = Runtime
    local function finite(n)
        return type(n) == 'number' and n == n and n >= 0 and n < math.huge
    end
    local function read(o, k)
        if o == nil then return nil end
        local ok, v = pcall(function() return o[k] end)
        if ok then return v end
    end
    local function static(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, ...); if ok then return v end
    end
    local function call(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, o, ...); if ok then return v end
    end
    local function validConfig(c)
        return type(c) == 'table' and type(c.url) == 'string' and c.url:match('^https://') ~= nil
            and type(c.game) == 'string' and #c.game > 0
            and type(c.secret) == 'string' and #c.secret > 0
            and finite(c.timeout) and c.timeout > 0 and finite(c.clockSkew)
    end
    function Runtime.new(env, config, Core, LoginUI)
        local self = setmetatable({
            env = env or _G, reason = 'login_required', active = false,
            ready = false, disposed = false, uiRetryAt = 0, uiFailures = 0
        }, Runtime)
        if not validConfig(config) or type(Core) ~= 'table' or type(Core.new) ~= 'function'
            or type(Core.Primitives) ~= 'table' then
            self.reason = 'license_dependencies_unavailable'; return self
        end
        local cfg = {}
        for k, v in pairs(config) do cfg[k] = v end
        self.timeout = cfg.timeout
        if type(LoginUI) == 'table' and type(LoginUI.new) == 'function' then
            local ok, ui = pcall(LoginUI.new, self.env)
            if ok and type(ui) == 'table' then self.ui = ui end
        end
        if type(_G.MasterWelcomeUI) == 'table' and type(_G.MasterWelcomeUI.new) == 'function' then
            local okW, w = pcall(_G.MasterWelcomeUI.new, self.env)
            if okW and type(w) == 'table' then self.welcome = w end
        end
        self.welcomeShownThisSession = (_G.__MASTER_WELCOME_SHOWN_SESSION == true)
        self.welcomeScheduledAt = nil
        self.welcomeDelaySeconds = 3.0
        self.submit = function(key) return self:login(key) end
        local ok, auth = pcall(Core.new, cfg, {
            clock = function() return self:_clock() end,
            wall = function()
                local value = static(read(self.env, 'os'), 'time')
                if finite(value) and value > 0 then return value end
            end,
            serial = function(key)
                local client = read(self.env, 'Client')
                local value = static(client, 'GetPhoneDeviceID')
                assert(type(value) == 'string' and #value > 0 and #value <= 512,
                    'DEVICE_ID_UNAVAILABLE')
                return Core.Primitives.name_uuid('MASTER-LUA-V1\0' .. key .. '\0' .. value)
            end,
            decode = function(raw)
                local json = self:_module('json', nil, 'common.json_util', 'decode')
                assert(json, 'JSON_UNAVAILABLE')
                return json.decode(raw)
            end,
            post = function(url, headers, body, callback, timeout)
                local manager = read(self.env, 'ModuleManager')
                local config = read(manager, 'CommonModuleConfig')
                local getter = read(manager, 'GetModule')
                assert(type(getter) == 'function' and config, 'HTTP_MANAGER_UNAVAILABLE')
                local http = getter(read(config, 'http_manager'))
                local post = read(http, 'Post')
                assert(type(post) == 'function', 'HTTP_POST_UNAVAILABLE')
                return post(http, url, headers, body, nil, callback, timeout)
            end,
            status = function(message, phase)
                self.active = false
                self.reason = phase == 'active' and 'waiting_maintenance' or 'login_required'
                self:_ui('SetStatus', message)
                self:_ui('SetBusy', phase == 'pending')
                if phase == 'active' then self:_ui('Hide') end
            end,
        })
        if ok and type(auth) == 'table' then self.auth = auth
        else self.reason = 'license_initialization_unavailable' end
        return self
    end
    function Runtime:_module(cache, globalName, path, method)
        local found = globalName and read(self.env, globalName)
        if type(read(found, method)) == 'function' then return found end
        found = self[cache]
        if type(read(found, method)) == 'function' then return found end
        local loader = read(self.env, 'require')
        if type(loader) == 'function' then
            local ok, value = pcall(loader, path)
            if ok and type(read(value, method)) == 'function' then
                self[cache] = value; return value
            end
        end
    end
    function Runtime:_valid(object)
        if object == nil then return false end
        if static(read(self.env, 'slua'), 'isValid', object) == true then return true end
        return call(read(self.env, 'Game'), 'IsValid', object) == true
    end
    function Runtime:_clock()
        local world = static(read(self.env, 'slua'), 'getWorld')
        if world == nil then return nil end
        local statics = read(self.env, 'GameplayStatics') or self.statics
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then
            local loader = read(self.env, 'import')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameplayStatics')
                if ok then statics = value end
            end
        end
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then return nil end
        self.statics = statics
        local now = static(statics, 'GetRealTimeSeconds', world)
        if finite(now) then return now, world end
    end
    function Runtime:_readGameplay(world)
        local data = read(self.env, 'GameplayData') or self.gameplayData
        if data == nil then
            local loader = read(self.env, 'require')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameLua.GameCore.Data.GameplayData')
                if ok and value ~= nil then self.gameplayData = value; data = value end
            end
        end
        local pc = static(data, 'GetPlayerController')
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            pc = call(read(self.env, 'slua_GameFrontendHUD'), 'GetPlayerController')
        end
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            return nil, 'waiting_controller'
        end
        local pawn = static(data, 'GetPlayerCharacter')
        if not self:_valid(pawn) then pawn = static(data, 'GetLocalCharacter') end
        for _, method in ipairs({'GetPlayerCharacterSafety', 'GetCurPawn', 'GetPawn'}) do
            if not self:_valid(pawn) then pawn = call(pc, method) end
            if not self:_valid(pawn) then pawn = call(read(pc, 'Object'), method) end
        end
        if not self:_valid(pawn) then return nil, 'waiting_pawn' end
        local tools = self:_module('tools', nil,
            'GameLua.Mod.BaseMod.Common.UI.InGameUITools', 'GetMainControlBaseUI')
        local root = static(tools, 'GetMainControlBaseUI')
        if not self:_valid(root) then return nil, 'waiting_control_ui' end
        local status = self:_module('gameStatus', 'GameStatus',
            'client.common.game_status', 'IsInFightingStatus')
        local loading = self:_module('loading', nil,
            'client.slua.logic.loading.logic_loading', 'IsShowing')
        if not status or not loading then return nil, 'readiness_services_unavailable' end
        if static(status, 'IsInFightingStatus') ~= true then return nil, 'waiting_gameplay' end
        if static(loading, 'IsShowing') ~= false then return nil, 'waiting_loading' end
        return {world = world, controller = pc, pawn = pawn, root = root}
    end
    local function same(a, b)
        return a and b and a.world == b.world and a.controller == b.controller
            and a.pawn == b.pawn and a.root == b.root
    end
    function Runtime:_ui(method, ...)
        local fn = read(self.ui, method)
        if type(fn) ~= 'function' then return false, 'UI_UNAVAILABLE' end
        local ok, value, reason = pcall(fn, ...)
        if not ok then return false, 'UI_TEMPORARILY_UNAVAILABLE' end
        return value, reason
    end
    function Runtime:_clearReadiness(reason)
        self.active, self.ready = false, false
        self.identity, self.readySince, self.maintenanceAt, self.maintenanceWorld = nil, nil, nil, nil
        self.reason = reason
        self:_ui('Hide')
    end
    function Runtime:_showPanel(now, state, blocked, initialKey)
        if now < self.uiRetryAt then return false end
        local shown, uiReason
        if blocked then shown, uiReason = self:_ui('ShowNotice', state.message)
        else shown, uiReason = self:_ui('Show', self.submit, initialKey) end
        if shown then
            self.uiFailures, self.uiError = 0, nil
            self:_ui('SetStatus', state.message)
            self:_ui('SetBusy', blocked or state.pending)
        else
            self.uiFailures = self.uiFailures + 1
            self.uiRetryAt = now + (self.uiFailures >= 10 and 5 or 1)
            self.uiError = type(uiReason) == 'string' and uiReason:match('^UI_[A-Z_]+$')
                or 'UI_UNAVAILABLE'
        end
        return shown == true
    end
    function Runtime:update()
        if self.disposed then self.reason = 'disposed'; return false end
        if not self.auth then return false end
        local tickOK = pcall(self.auth.Tick)
        if not tickOK then
            self.auth.FailClosed('License maintenance unavailable.')
            self:_clearReadiness('license_maintenance_unavailable'); return false
        end
        local now, world = self:_clock()
        if not now then self:_clearReadiness('clock_unavailable'); return false end
        local ready, reason = self:_readGameplay(world)
        if not ready then self:_clearReadiness(reason); return false end
        if not same(self.identity, ready) or not self.readySince or now < self.readySince then
            self.identity, self.readySince = ready, now
        end
        self.ready = now - self.readySince >= 3
        self.maintenanceAt, self.maintenanceWorld = now, world
        self.active = self.ready and self.auth.IsAuthorized()
        if not self.ready then
            self.reason = 'waiting_stable_gameplay'; self:_ui('Hide'); return false
        end
        local state = self.auth.GetState()
        if self.active then
            self.reason = 'active'
            self:_ui('Hide')
            if self.welcome and not self.welcomeShownThisSession then
                if not self.welcomeScheduledAt then self.welcomeScheduledAt = now end
                if self.welcomeScheduledAt
                    and (now - self.welcomeScheduledAt) >= self.welcomeDelaySeconds then
                    local shown = false
                    pcall(function()
                        if self.welcome:Show() then shown = true end
                    end)
                    if shown then
                        self.welcomeShownThisSession = true
                        _G.__MASTER_WELCOME_SHOWN_SESSION = true
                        self.welcomeScheduledAt = nil
                    else
                        self.welcomeScheduledAt = now
                    end
                end
            end
            return true
        end
        self.reason = 'login_required'
        local rememberedKey = nil
        pcall(function()
            if self.auth and type(self.auth.GetSavedKey) == 'function' then
                rememberedKey = self.auth.GetSavedKey()
            end
            if not rememberedKey then
                local g = rawget(_G, '__UX_SAVED_LICENSE_KEY')
                if type(g) == 'string' and #g > 0 then rememberedKey = g end
            end
        end)
        self.rememberedKey = rememberedKey
        if state.restartRequired or state.phase == 'expired' or state.phase == 'tampered' then
            self.reason = state.restartRequired and 'restart_required' or state.phase
            self:_showPanel(now, state, true); return false
        end
        if not self:_showPanel(now, state, false, rememberedKey) and self.uiError then
            self.reason = 'login_ui_unavailable'
        end
        return false
    end
    function Runtime:isActive()
        if self.disposed or not self.auth or not self.active or not self.ready then return false end
        if not self.auth.IsAuthorized() then self.active = false; return false end
        local now, world = self:_clock()
        if not now or world ~= self.maintenanceWorld or not self.maintenanceAt
            or now < self.maintenanceAt or now - self.maintenanceAt >= 3 then
            self.active = false; self.reason = 'maintenance_stale'; return false
        end
        return true
    end
    function Runtime:login(key)
        if self.disposed or not self.auth then return false end
        if self.auth.IsAuthorized() then return true end
        local now, world = self:_clock()
        if not self.ready or not now or world ~= self.maintenanceWorld
            or not self.maintenanceAt or now < self.maintenanceAt
            or now - self.maintenanceAt >= 3 then return false end
        local identity = self:_readGameplay(world)
        if not same(identity, self.identity) then
            self:_clearReadiness('waiting_stable_gameplay'); return false
        end
        local ok, accepted = pcall(self.auth.Login, key)
        if not ok then self.auth.FailClosed('Login could not start.'); return false end
        return accepted == true
    end
    function Runtime:getStatus()
        local active = self:isActive()
        local state = self.auth and self.auth.GetState() or {}
        return {
            authorized = active, sessionAuthorized = state.authorized == true,
            phase = state.phase or 'locked',
            message = state.message or 'License dependencies unavailable.',
            reason = self.reason, pending = state.pending == true,
            gameplayReady = self.ready, expiresAt = state.expiresAt,
            accessPolicy = 'game_session', expiryCheckPolicy = 'login_only',
            clockProtection = 'login_only', periodicRecheck = false,
            loginDelaySeconds = 3, restartRequired = state.restartRequired == true,
            uiError = self.uiError,
            lastRequestLatencyMs = state.lastRequestLatencyMs,
            latencyScope = 'license_http_round_trip', disposed = self.disposed
        }
    end
    function Runtime:logout()
        self.active = false
        if self.auth then self.auth.Logout() end
        self.reason = 'login_required'; return true
    end
    function Runtime:dispose()
        if self.disposed then return true end
        self:logout(); self.disposed = true; self.ready = false
        self:_ui('Destroy'); self.reason = 'disposed'
        self.submit = nil
        return true
    end
    return Runtime
end)()

-- AUTH BOOTSTRAP
local masterESPLicenseInstance

local function masterESPEnsureLicense()
    if masterESPLicenseInstance then return end
    local host = setmetatable({}, {__index = _ENV})
    masterESPLicenseInstance = MasterLicenseRuntime.new(
        host, MasterLicenseConfig, MasterLicenseCore, MasterLoginUI)
end

local function AHMADAuthActive()
    if not masterESPLicenseInstance then
        masterESPEnsureLicense()
    end
    local active = false
    pcall(function()
        active = masterESPLicenseInstance and masterESPLicenseInstance:isActive() == true
    end)
    return active
end

_G.AHMADAuthActive = AHMADAuthActive

function _G.MasterLicenseLogin(key)
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then return false, 'license_unavailable' end
    local ok, result = pcall(masterESPLicenseInstance.login, masterESPLicenseInstance, key)
    if not ok then return false, 'license_unavailable' end
    return result
end

function _G.MasterLicenseLogout()
    if not masterESPLicenseInstance then return false end
    return pcall(masterESPLicenseInstance.logout, masterESPLicenseInstance)
end

function _G.MasterLicenseStatus()
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then
        return {authorized = false, phase = 'locked', message = 'license_unavailable'}
    end
    local ok, value = pcall(masterESPLicenseInstance.getStatus, masterESPLicenseInstance)
    return ok and value or {authorized = false, phase = 'locked'}
end

-- [FIX 2] Auth tick has retry-on-fail watchdog to avoid permanent stop
local _authTickFails = 0
local function AHMADAuthTick()
    local ok = true
    if masterESPLicenseInstance then
        ok = pcall(masterESPLicenseInstance.update, masterESPLicenseInstance)
    end
    if not ok then _authTickFails = _authTickFails + 1 else _authTickFails = 0 end
    local delay = (_authTickFails >= 5) and 2.0 or 0.5
    local scheduled = false
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(delay, AHMADAuthTick)
            scheduled = true
        end
    end)
    if not scheduled then
        pcall(function()
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(2.0, AHMADAuthTick)
            end
        end)
    end
end

masterESPEnsureLicense()
AHMADAuthTick()
print("[AUTH] Feature gate initialized: login required.")

-- LEGACY LICENSE API COMPATIBILITY BRIDGE
_G.LicenseValid = _G.LicenseValid == true
_G.ModsEnabled = _G.ModsEnabled == true

local function SyncLegacyLicenseState()
  local active = false
  pcall(function()
    active = AHMADAuthActive() == true
  end)
  _G.LicenseValid = active
  _G.ModsEnabled = active
  return active
end

_G.IsLicenseOK = function()
  return SyncLegacyLicenseState()
end

_G.License_ReadKey = function()
  if masterESPLicenseInstance and masterESPLicenseInstance.auth
      and type(masterESPLicenseInstance.auth.GetSavedKey) == "function" then
    local ok, key = pcall(masterESPLicenseInstance.auth.GetSavedKey)
    if ok and type(key) == "string" then return key end
  end
  local key = rawget(_G, "__UX_SAVED_LICENSE_KEY")
  return type(key) == "string" and key or ""
end

_G.License_GetHWID = function() return nil end

_G.License_API_URL = "https://sameer.keysgen.online/connect"

_G.License_Validate = function(callback)
  local function check()
    local active = SyncLegacyLicenseState()
    if active then
      if type(callback) == "function" then pcall(callback, true) end
      return
    end
    if masterESPLicenseInstance then
      pcall(masterESPLicenseInstance.update, masterESPLicenseInstance)
    end
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
      ticker.AddTimerOnce(0.5, check)
    end
  end
  check()
end

-- [FIX 19] Merge legacy sync into AHMADAuthTick via single timer (was duplicate)
-- LegacyLicenseSyncTick removed — SyncLegacyLicenseState called in AHMADAuthTick
-- Keep a light 1s tick for external callers that rely on LicenseValid flipping fast:
local function LegacyLicenseSyncTick()
  SyncLegacyLicenseState()
  local okTicker, ticker = pcall(require, "common.time_ticker")
  if okTicker and ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(0.5, LegacyLicenseSyncTick)
  end
end
LegacyLicenseSyncTick()

-- ============================================================================
-- AUTH TRIGGER (per-match, resettable)
-- ============================================================================
do
    local _authScheduled = false
    local _authDone = false

    local function TryFireAuth()
        if _G.LicenseValid == true or _authScheduled or _authDone then return end
        local ok, GDP = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GDP then return end
        local pc = GDP.GetPlayerController and GDP.GetPlayerController()
        if not slua.isValid(pc) then return end
        local pawn = pc.GetPlayerCharacterSafety and pc:GetPlayerCharacterSafety()
        if not slua.isValid(pawn) then return end
        local status = package.loaded["client.common.game_status"]
        if status and status.IsInFightingStatus and status.IsInFightingStatus() ~= true then
            return
        end
        _authScheduled = true
        pawn:AddGameTimer(1.5, false, function()
            pcall(function()
                if _G.License_Validate then
                    _G.License_Validate(function(valid)
                        if valid then
                            print("[License] VALID - Mods enabled.")
                            _authDone = true
                            if _G.OnLicenseValid then pcall(_G.OnLicenseValid) end
                        else
                            print("[License] INVALID - Waiting for key.")
                            _G.ModsEnabled = false
                        end
                        _authScheduled = false
                    end)
                end
            end)
        end)
    end

    local function AuthPoller()
        if not _authDone then pcall(TryFireAuth) end
        local ok, ticker = pcall(require, "common.time_ticker")
        if ok and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, AuthPoller)
        end
    end

    local ok, ticker = pcall(require, "common.time_ticker")
    if ok and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, AuthPoller)
    end

    -- [FIX 4] Export per-match reset hook
    _G.ResetAuthTrigger = function()
        _authScheduled = false
        _authDone = false
    end
end

_G.OnLicenseValid = _G.OnLicenseValid or function() end

print("[NADEEM 3/6] Runtime + Bootstrap + Auth trigger loaded")

-- ============================================================
-- DEFAULTS
-- ============================================================
if not _G.Mod_ESP_Enabled then _G.Mod_ESP_Enabled = true end
if not _G.Mod_ESP_AnimeBox then _G.Mod_ESP_AnimeBox = false end
if not _G.Mod_ESP_ShowSnapline then _G.Mod_ESP_ShowSnapline = false end
if not _G.Mod_ESP_ShowName then _G.Mod_ESP_ShowName = false end
if not _G.Mod_ESP_ShowDistance then _G.Mod_ESP_ShowDistance = false end
if not _G.Mod_ESP_ShowHealthBar then _G.Mod_ESP_ShowHealthBar = false end
if not _G.Mod_ESP_ShowPlayerCount then _G.Mod_ESP_ShowPlayerCount = false end

-- ============================================================
-- LOCALS
-- ============================================================
local require = require
local import  = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end


-- ============================================================
-- SECTION 1 — RedBoxOverlay (Player Count UI)
-- ============================================================
local PlayerMapMarker = {}
local RedBoxOverlay = {
    bActive = false,
    MainContainer = nil,
    WidgetSlot = nil,
    PlayerText = nil,
    BotText = nil,
    CrownText = nil,
    Width = 430,
    Height = 62,
    OffsetY = 46,
    PlayerCount = 0,
    BotCount = 0,
    Layers = {},
    FontSize = 22,
    TextScaleValue = 1.0,
    _CachedText = "",
    _CachedPosVec = nil
}

function RedBoxOverlay.Create()
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return true end

    local ParentCanvas = PlayerMapMarker.ESPCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then
        if not PlayerMapMarker.InitESPCanvas() then return false end
        ParentCanvas = PlayerMapMarker.ESPCanvas
    end
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local FLinearColor = import("LinearColor") or _G.FLinearColor
    local FVector2D = import("Vector2D") or _G.FVector2D
    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local PANEL_W      = 230
    local PANEL_H      = 30
    local CENTER_X     = 115
    local OFFSET_SIDE  = 76
    local SIDE_W       = 84
    local OFFSET_BLACK = 15

    local GREEN_DARK   = FLinearColor(0.0, 0.45, 0.20, 1.0)
    local GREEN_BRIGHT = FLinearColor(0.0, 0.65, 0.30, 1.0)
    local GREEN_EDGE   = FLinearColor(0.0, 0.85, 0.45, 1.0)
    local RED_DARK     = FLinearColor(0.55, 0.0, 0.0, 1.0)
    local RED_BRIGHT   = FLinearColor(0.85, 0.05, 0.05, 1.0)
    local RED_EDGE     = FLinearColor(1.0, 0.15, 0.15, 1.0)
    local BLACK_DARK   = FLinearColor(0.02, 0.02, 0.02, 1.0)
    local BLACK_EDGE   = FLinearColor(0.15, 0.15, 0.15, 1.0)
    local WHITE_TEXT   = FLinearColor(1.0, 1.0, 1.0, 1.0)

    RedBoxOverlay.Layers = {}

    local function MakeSkewed(parent, offsetX, width, height, color, zOrder, shearX)
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", parent) end)
        if not border or not slua.isValid(border) then return nil end
        pcall(function()
            border:SetBrushColor(color)
            border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            border:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            pcall(function() border:SetRenderShear(FVector2D(shearX or 0.0, 0.0)) end)
            pcall(function() border:SetRenderShear({X=shearX or 0.0, Y=0.0}) end)
        end)
        local slot = nil
        pcall(function()
            slot = parent:AddChildToCanvas(border)
            if slot then
                slot:SetAutoSize(false)
                slot:SetAlignment(FVector2D(0.5, 0.5))
                slot:SetPosition(FVector2D(offsetX, 0))
                slot:SetSize(FVector2D(width, height))
                slot:SetZOrder(zOrder or 0)
            end
        end)
        table.insert(RedBoxOverlay.Layers, {Widget = border, Slot = slot})
        return border
    end

    local LEFT_SHEAR = 25.0
    local RIGHT_SHEAR = -25.0

    MakeSkewed(Container, CENTER_X - OFFSET_SIDE, SIDE_W + 4, PANEL_H + 4, RED_EDGE, 0, LEFT_SHEAR)
    MakeSkewed(Container, CENTER_X - OFFSET_SIDE, SIDE_W, PANEL_H, RED_BRIGHT, 1, LEFT_SHEAR)
    MakeSkewed(Container, CENTER_X - OFFSET_SIDE, SIDE_W - 2, PANEL_H - 2, RED_DARK, 2, LEFT_SHEAR)

    MakeSkewed(Container, CENTER_X + OFFSET_SIDE, SIDE_W + 4, PANEL_H + 4, GREEN_EDGE, 0, RIGHT_SHEAR)
    MakeSkewed(Container, CENTER_X + OFFSET_SIDE, SIDE_W, PANEL_H, GREEN_BRIGHT, 1, RIGHT_SHEAR)
    MakeSkewed(Container, CENTER_X + OFFSET_SIDE, SIDE_W - 2, PANEL_H - 2, GREEN_DARK, 2, RIGHT_SHEAR)

    MakeSkewed(Container, CENTER_X - OFFSET_BLACK, 40, PANEL_H + 8, BLACK_EDGE, 3, LEFT_SHEAR)
    MakeSkewed(Container, CENTER_X - OFFSET_BLACK, 36, PANEL_H + 4, BLACK_DARK, 4, LEFT_SHEAR)
    MakeSkewed(Container, CENTER_X + OFFSET_BLACK, 40, PANEL_H + 8, BLACK_EDGE, 3, RIGHT_SHEAR)
    MakeSkewed(Container, CENTER_X + OFFSET_BLACK, 36, PANEL_H + 4, BLACK_DARK, 4, RIGHT_SHEAR)

    local playerText = nil
    pcall(function() playerText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if playerText and slua.isValid(playerText) then
        pcall(function()
            playerText:SetText("REAL: 0")
            if FSlateColor then playerText:SetColorAndOpacity(FSlateColor(WHITE_TEXT)) else playerText:SetColorAndOpacity(WHITE_TEXT) end
            if playerText.Font then
                local f = playerText.Font
                f.Size = 13
                f.TypefaceFontName = "Bold"
                playerText.Font = f
            end
            playerText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = Container:AddChildToCanvas(playerText)
        if slot then
            pcall(function()
                slot:SetAutoSize(true)
                slot:SetAlignment(FVector2D(0.5, 0.5))
                slot:SetPosition(FVector2D(CENTER_X - OFFSET_SIDE, 0))
                slot:SetZOrder(100)
            end)
        end
        RedBoxOverlay.PlayerText = playerText
    end

    local crownText = nil
    pcall(function() crownText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if crownText and slua.isValid(crownText) then
        pcall(function()
            crownText:SetText("▼")
            if FSlateColor then crownText:SetColorAndOpacity(FSlateColor(WHITE_TEXT)) else crownText:SetColorAndOpacity(WHITE_TEXT) end
            if crownText.Font then
                local f = crownText.Font
                f.Size = 16
                f.TypefaceFontName = "Bold"
                crownText.Font = f
            end
            crownText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = Container:AddChildToCanvas(crownText)
        if slot then
            pcall(function()
                slot:SetAutoSize(true)
                slot:SetAlignment(FVector2D(0.5, 0.5))
                slot:SetPosition(FVector2D(CENTER_X, -2))
                slot:SetZOrder(101)
            end)
        end
        RedBoxOverlay.CrownText = crownText
    end

    local botText = nil
    pcall(function() botText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if botText and slua.isValid(botText) then
        pcall(function()
            botText:SetText("BOT: 0")
            if FSlateColor then botText:SetColorAndOpacity(FSlateColor(WHITE_TEXT)) else botText:SetColorAndOpacity(WHITE_TEXT) end
            if botText.Font then
                local f = botText.Font
                f.Size = 13
                f.TypefaceFontName = "Bold"
                botText.Font = f
            end
            botText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = Container:AddChildToCanvas(botText)
        if slot then
            pcall(function()
                slot:SetAutoSize(true)
                slot:SetAlignment(FVector2D(0.5, 0.5))
                slot:SetPosition(FVector2D(CENTER_X + OFFSET_SIDE, 0))
                slot:SetZOrder(100)
            end)
        end
        RedBoxOverlay.BotText = botText
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if not MainSlot then return false end

    RedBoxOverlay.MainContainer = Container
    RedBoxOverlay.WidgetSlot = MainSlot

    pcall(function()
        MainSlot:SetAutoSize(false)
        MainSlot:SetZOrder(999)
        MainSlot:SetAlignment(FVector2D(0.5, 0.0))
        MainSlot:SetSize(FVector2D(PANEL_W, PANEL_H))
    end)

    RedBoxOverlay.UpdatePosition()
    return true
end

function RedBoxOverlay.SetCounts(players, bots)
    players = tonumber(players) or 0
    bots = tonumber(bots) or 0
    if RedBoxOverlay.PlayerCount == players and RedBoxOverlay.BotCount == bots then return end
    RedBoxOverlay.PlayerCount = players
    RedBoxOverlay.BotCount = bots

    if RedBoxOverlay.PlayerText and slua.isValid(RedBoxOverlay.PlayerText) then
        pcall(function() RedBoxOverlay.PlayerText:SetText(string.format("REAL: %d", players)) end)
    end
    if RedBoxOverlay.BotText and slua.isValid(RedBoxOverlay.BotText) then
        pcall(function() RedBoxOverlay.BotText:SetText(string.format("BOT: %d", bots)) end)
    end
end

function RedBoxOverlay.UpdatePosition()
    local Slot = RedBoxOverlay.WidgetSlot
    if not Slot or not slua.isValid(Slot) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not slua.isValid(PC) then return end

    local fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    local FVector2D = import("Vector2D") or _G.FVector2D
    pcall(function()
        if not RedBoxOverlay._CachedPosVec then
            RedBoxOverlay._CachedPosVec = FVector2D(fromX, fromY + 28)
        else
            RedBoxOverlay._CachedPosVec.X = fromX
            RedBoxOverlay._CachedPosVec.Y = fromY + 28
        end
        Slot:SetPosition(RedBoxOverlay._CachedPosVec)
        pcall(function()
            Slot:SetAlignment(FVector2D(0.5, 1.0))
            Slot:SetSize(FVector2D(230, 30))
        end)
    end)
end

function RedBoxOverlay.Start()
    if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return end
    if RedBoxOverlay.Create() then
        RedBoxOverlay.bActive = true
        pcall(function() RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
end

function RedBoxOverlay.Stop()
    RedBoxOverlay.bActive = false
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        pcall(function()
            RedBoxOverlay.MainContainer:RemoveFromParent()
            RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
        end)
    end
    RedBoxOverlay.MainContainer = nil
    RedBoxOverlay.WidgetSlot = nil
    RedBoxOverlay.PlayerText = nil
    RedBoxOverlay.BotText = nil
    RedBoxOverlay.CrownText = nil
    RedBoxOverlay.Layers = {}
    RedBoxOverlay._CachedPosVec = nil
end

_G.RedBoxOverlay = RedBoxOverlay


-- ============================================================
-- SECTION 2 — PlayerMapMarker (ESP V2 engine / Snaplines)
-- ============================================================
local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local KismetMathLibrary_ESP9 = nil
local KismetSystemLibrary_ESP9 = nil

pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)
pcall(function() KismetMathLibrary_ESP9 = import("KismetMathLibrary") end)
pcall(function() KismetSystemLibrary_ESP9 = import("KismetSystemLibrary") end)

local FVector2D_ESP9 = _G.FVector2D or import("Vector2D")
local FLinearColor_ESP9 = _G.FLinearColor or import("LinearColor")
local FVector_ESP9 = _G.FVector or import("Vector")

PlayerMapMarker.bUseScreenESP = true
PlayerMapMarker.ESPWorldOffsetZ = 0
PlayerMapMarker.ESPAnchorOffsetX = 35
PlayerMapMarker.ESPAnchorOffsetY = 0
PlayerMapMarker.ESPWidgetZOrder = 2
PlayerMapMarker.bShowDistance = true
PlayerMapMarker.HPWidgetSwitcherTypeIndex = 0
PlayerMapMarker.HPWidgetSwitcherType2Index = 0
PlayerMapMarker.bForceSwitcherIndexEveryUpdate = true
PlayerMapMarker.bUseSnapLines = false
PlayerMapMarker.SnapLineThickness = 1.4
PlayerMapMarker.SnapLineOriginY = 70
PlayerMapMarker.SnapLineOriginOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetY = -14
PlayerMapMarker.SnapLineColor = FLinearColor_ESP9 and FLinearColor_ESP9(1.0, 0.85, 0.0, 1.0) or {R=255, G=217, B=0, A=255}
PlayerMapMarker.SnapLineOpacity = 0.9

PlayerMapMarker.nUpdateInterval = 0.5
PlayerMapMarker._LightUpdateInterval = 0.02
PlayerMapMarker._DistanceUpdateInterval = 0.1
PlayerMapMarker.bIncludeMe = false
PlayerMapMarker.bIncludeAI = true
PlayerMapMarker.bActive = false
PlayerMapMarker.ESPCanvas = nil
PlayerMapMarker.ESPWidgets = {}
PlayerMapMarker.ESPWidgetPtrs = {}
PlayerMapMarker.SnapLineWidgets = {}
PlayerMapMarker._cachedViewportW = 1920
PlayerMapMarker._cachedViewportH = 1080
PlayerMapMarker._CanvasScaleX = 1.0
PlayerMapMarker._CanvasScaleY = 1.0
PlayerMapMarker._CanvasOffsetX = 0.0
PlayerMapMarker._CanvasOffsetY = 0.0
PlayerMapMarker._OBHeadWidgetClass = nil
PlayerMapMarker._OBHeadWidgetLoadFailed = false
PlayerMapMarker._CachedGameplayData = nil
PlayerMapMarker._CachedPC = nil
PlayerMapMarker._CachedCGameState = nil
PlayerMapMarker._CachedTopCenterPixel = nil
PlayerMapMarker._tempScreenPixelPos = nil

local function IsValid_ESP9(obj)
    if obj == nil then return false end
    if slua and slua.isValid then return slua.isValid(obj) end
    return obj ~= nil
end

function PlayerMapMarker.GetGameplayData()
    if PlayerMapMarker._CachedGameplayData then return PlayerMapMarker._CachedGameplayData end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then PlayerMapMarker._CachedGameplayData = GDP return GDP end
    return nil
end

function PlayerMapMarker.GetMyPlayerController()
    local PC = PlayerMapMarker._CachedPC
    if PC and IsValid_ESP9(PC) then return PC end
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
    if PC and IsValid_ESP9(PC) then PlayerMapMarker._CachedPC = PC return PC end
    return nil
end

function PlayerMapMarker.GetCGameState()
    if CGameState and IsValid_ESP9(CGameState) then return CGameState end
    if PlayerMapMarker._CachedCGameState and IsValid_ESP9(PlayerMapMarker._CachedCGameState) then return PlayerMapMarker._CachedCGameState end
    local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
    if ok and GS then PlayerMapMarker._CachedCGameState = GS return GS end
    return nil
end

function PlayerMapMarker.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    if not next(AllChars) then
        local GS = PlayerMapMarker.GetCGameState()
        if GS and GS.GetAllCharacters then pcall(function() AllChars = GS:GetAllCharacters() end) end
    end
    return AllChars
end

function PlayerMapMarker.GetMyPlayerKey()
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid_ESP9(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
    end)
    return MyKey
end

function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true return end
        end
        local PC = PlayerMapMarker.GetMyPlayerController()
        if PC and PC.GetPawn then
            local Pawn = PC:GetPawn()
            if Pawn and Character == Pawn then bIsMe = true return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then bIsMe = (tostring(PlayerKey) == tostring(MyKey)) end
    return bIsMe
end

function PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid_ESP9(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    if not Loc then pcall(function() if Game and Game.GetActorLocation then Loc = Game:GetActorLocation(Character) end end) end
    return Loc
end

function PlayerMapMarker.CalcDistance(Loc1, Loc2)
    if not Loc1 or not Loc2 then return nil end
    local Dist = nil
    pcall(function() if FVector_ESP9 and FVector_ESP9.Dist2D then Dist = FVector_ESP9.Dist2D(Loc1, Loc2) end end)
    if not Dist then
        pcall(function()
            local DX = (Loc1.X or 0) - (Loc2.X or 0)
            local DY = (Loc1.Y or 0) - (Loc2.Y or 0)
            Dist = math.sqrt(DX * DX + DY * DY)
        end)
    end
    return Dist
end

function PlayerMapMarker.GetDistanceString(MyLoc, TargetLoc)
    if not PlayerMapMarker.bShowDistance then return "" end
    if not MyLoc or not TargetLoc then return "" end
    local Dist = PlayerMapMarker.CalcDistance(MyLoc, TargetLoc)
    if not Dist then return "" end
    local Meters = Dist / 100
    if Meters < 1000 then return string.format("%dm", math.floor(Meters))
    else return string.format("%.1fkm", Meters / 1000) end
end

function PlayerMapMarker.GetMyLocation()
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    local MyChar = nil
    pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
    if not IsValid_ESP9(MyChar) then return nil end
    return PlayerMapMarker.GetCharacterLocation(MyChar)
end

function PlayerMapMarker.GetPlayerName(Character)
    if not IsValid_ESP9(Character) then return "Unknown" end
    local Name = nil
    pcall(function() if Character.GetPlayerNameSafety then Name = Character:GetPlayerNameSafety() end end)
    if not Name then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid_ESP9(PS) and PS.GetPlayerName then Name = PS:GetPlayerName() end
        end)
    end
    return Name or "Unknown"
end

function PlayerMapMarker.IsAI(Character)
    local bAI = false
    pcall(function() if Game and Game.IsAI then bAI = Game:IsAI(Character) end end)
    return bAI
end

function PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function() if Character.IsAlive then bAlive = Character:IsAlive() end end)
    return bAlive
end

function PlayerMapMarker.GetTeamID(Character)
    if not IsValid_ESP9(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid_ESP9(PS) and PS.GetTeamID then TeamID = PS:GetTeamID()
            elseif IsValid_ESP9(PS) and PS.TeamID then TeamID = PS.TeamID end
        end)
    end
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function PlayerMapMarker.InitESPCanvas()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
    local InGameUITools = nil
    pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    if not InGameUITools then return false end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end
    local ParentCanvas = nil
    pcall(function()
        if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then ParentCanvas = MainControlBaseUI.CanvasPanel_0
        elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then ParentCanvas = MainControlBaseUI.CanvasPanel_42 end
    end)
    if not ParentCanvas then return false end
    PlayerMapMarker.ESPCanvas = ParentCanvas
    return true
end

function PlayerMapMarker.GetESPLocation(Character)
    if not IsValid_ESP9(Character) then return nil end
    local BoneLoc = PlayerMapMarker.GetCharacterLocation(Character)
    if BoneLoc then
        local heightOffset = 85
        pcall(function()
            if Character.bIsCrouched then heightOffset = 60 end
            if Character.IsProne and Character:IsProne() then heightOffset = 30 end
        end)
        pcall(function() BoneLoc.Z = BoneLoc.Z + heightOffset + (PlayerMapMarker.ESPWorldOffsetZ or 0) end)
    end
    return BoneLoc
end

function PlayerMapMarker.FindProgressBarInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0
    MaxDepth = MaxDepth or 5
    if Depth > MaxDepth then return nil end

    local bIsPB = false
    pcall(function() if WidgetObj.SetPercent and WidgetObj.SetFillColorAndOpacity then bIsPB = true end end)
    if bIsPB then return WidgetObj end

    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindProgressBarInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.CreateESPWidget()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    if PlayerMapMarker._OBHeadWidgetLoadFailed then return nil end

    if not PlayerMapMarker._OBHeadWidgetClass then
        pcall(function()
            local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
            local uClass = slua.loadClass(Path)
            if uClass then PlayerMapMarker._OBHeadWidgetClass = uClass end
        end)
        if not PlayerMapMarker._OBHeadWidgetClass then
            PlayerMapMarker._OBHeadWidgetLoadFailed = true
            return nil
        end
    end

    local Widget = nil
    pcall(function()
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        local PC = PlayerMapMarker.GetMyPlayerController()
        local OuterObj = IsValid_ESP9(PC) and PC.Object or PlayerMapMarker.ESPCanvas
        Widget = STExtraBlueprintFunctionLibrary.CreateWidgetByClass(PlayerMapMarker._OBHeadWidgetClass, OuterObj)
    end)
    if not Widget then return nil end

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Widget:SetRenderOpacity(1.0) end)

    local NameText = nil
    local HealthFill = nil
    pcall(function()
        NameText = Widget.TextBlock_TeamName
        if NameText and slua.isValid(NameText) then pcall(function() NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
        if Widget.TextBlock_PlayerName and slua.isValid(Widget.TextBlock_PlayerName) then pcall(function() Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
        local SizeBox_HP = Widget.SizeBox_HP
        if SizeBox_HP and slua.isValid(SizeBox_HP) then
            pcall(function() SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            local ExistingChild = nil
            pcall(function() if SizeBox_HP.GetContent then ExistingChild = SizeBox_HP:GetContent() end end)
            if ExistingChild and slua.isValid(ExistingChild) then
                local FoundPB = PlayerMapMarker.FindProgressBarInWidget(ExistingChild, 0, 5)
                if FoundPB and slua.isValid(FoundPB) then HealthFill = FoundPB end
            end
        end
    end)

    return {
        Container = Widget,
        NameText = NameText,
        HealthFill = HealthFill,
        IsGameWidget = true,
        HasChildren = (NameText ~= nil)
    }
end

function PlayerMapMarker.UpdateESPText(Widget, Text)
    if not Widget then return end
    if Widget._LastESPText == Text then return end
    Widget._LastESPText = Text

    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
    local premiumRed = FLinearColor_ESP9 and FLinearColor_ESP9(1.0, 0.0, 0.0, 1.0) or {R=255,G=0,B=0,A=255}

    local function applyText(w, txt)
        if not w or not slua.isValid(w) then return end
        if txt == "" then
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            return
        else
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        end
        pcall(function() w:SetText(txt) end)
        pcall(function()
            if FSlateColor then w:SetColorAndOpacity(FSlateColor(premiumRed))
            else w:SetColorAndOpacity(premiumRed) end
        end)
    end

    if Widget.NameText and slua.isValid(Widget.NameText) then applyText(Widget.NameText, Text) end
    if Widget.IsGameWidget and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                applyText(W.TextBlock_TeamName, Text)
                applyText(W.TextBlock_PlayerName, Text)
            end
        end)
    end
end

function PlayerMapMarker.UpdateESPHealth(Widget, pct)
    if not Widget then return end
    Widget.LastPct = pct
    local bShowHP = _G.Mod_ESP_ShowHealthBar
    if not bShowHP then return end

    if PlayerMapMarker.bForceSwitcherIndexEveryUpdate and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                if W.WidgetSwitcher_Type and slua.isValid(W.WidgetSwitcher_Type) then pcall(function() if W.WidgetSwitcher_Type.SetActiveWidgetIndex then W.WidgetSwitcher_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
                if W.WidgetSwitcher_Type2 and slua.isValid(W.WidgetSwitcher_Type2) then pcall(function() if W.WidgetSwitcher_Type2.SetActiveWidgetIndex then W.WidgetSwitcher_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end
            end
        end)
    end

    if Widget.HealthFill then
        local bValid = false
        pcall(function() bValid = slua.isValid(Widget.HealthFill) end)
        if bValid then
            pcall(function()
                if Widget.HealthFill.SetPercent then
                    Widget.HealthFill:SetPercent(pct)
                    local color = FLinearColor_ESP9 and FLinearColor_ESP9(0.0, 1.0, 0.0, 1.0) or {R=0,G=255,B=0,A=255}
                    if Widget.HealthFill.SetFillColorAndOpacity then Widget.HealthFill:SetFillColorAndOpacity(color) end
                end
            end)
        end
    end
end

function PlayerMapMarker.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
    if not Widget or not IsValid_ESP9(PC) then return false end

    local Container = Widget.Container or Widget
    local bOnScreen = true

    if not CanvasPos then
        if not WorldLoc then return false end
        bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    end

    if not bOnScreen then pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) return false end

    pcall(function()
        local bShowAnyUI = _G.Mod_ESP_ShowName or _G.Mod_ESP_ShowDistance or _G.Mod_ESP_ShowHealthBar
        if bShowAnyUI then Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end

        if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
            local ptr = tostring(Container)
            local Slot = PlayerMapMarker.ESPWidgetPtrs[ptr]
            if not Slot or not slua.isValid(Slot) then
                local addedSlot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Container)
                if addedSlot and slua.isValid(addedSlot) then
                    Slot = addedSlot
                    PlayerMapMarker.ESPWidgetPtrs[ptr] = addedSlot
                    pcall(function() Slot:SetAutoSize(true) end)
                    pcall(function() Slot:SetAlignment(FVector2D_ESP9 and FVector2D_ESP9(0.5, 1.0) or {X=0.5, Y=1.0}) end)
                    pcall(function() Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 20) end)
                end
            end
            if Slot and slua.isValid(Slot) then
                local finalX = CanvasPos.X + (PlayerMapMarker.ESPAnchorOffsetX or 0)
                local finalY = CanvasPos.Y + (PlayerMapMarker.ESPAnchorOffsetY or 0)
                if not Widget._CachedPosVec then Widget._CachedPosVec = FVector2D_ESP9 and FVector2D_ESP9(finalX, finalY) or {X=finalX, Y=finalY}
                else Widget._CachedPosVec.X = finalX; Widget._CachedPosVec.Y = finalY end
                pcall(function() Slot:SetPosition(Widget._CachedPosVec) end)
            end
        end
    end)
    return true
end

function PlayerMapMarker.UpdateCanvasTransform(PC)
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local success = false
    pcall(function()
        local SBL = SlateBlueprintLibrary
        if SBL and SBL.AbsoluteToLocal then
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg then
                local pt0 = SBL.AbsoluteToLocal(cg, FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0})
                local pt1 = SBL.AbsoluteToLocal(cg, FVector2D_ESP9 and FVector2D_ESP9(100, 100) or {X=100, Y=100})
                if pt0 and pt1 then
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)

    if not success then
        local scale = 1.0
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0 end
        PlayerMapMarker._CanvasScaleX = 1.0 / scale
        PlayerMapMarker._CanvasScaleY = 1.0 / scale
        PlayerMapMarker._CanvasOffsetX = 0
        PlayerMapMarker._CanvasOffsetY = 0
    end
end

function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    if not ScreenPixelPos then return FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0} end
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return (FVector2D_ESP9 and FVector2D_ESP9(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)) or {X = ScreenPixelPos.X * scaleX + offsetX, Y = ScreenPixelPos.Y * scaleY + offsetY}
end

function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid_ESP9(PC) or not WorldLoc then return false, (FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}) end

    local ScreenPixelPos = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
        if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then bOK = true end
    end)

    if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then return false, (FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}) end

    local CanvasLocalPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    return true, CanvasLocalPos
end

function PlayerMapMarker.GetSnapLineStartPos(PC)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0,Y=0}
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
        end
    end)

    if screenPixelW <= 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportSize then
                local vs = WLL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
            end
        end)
    end

    pcall(function()
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportScale then
            local s = WLL.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)

    if screenPixelW <= 200 then
        screenPixelW = (PlayerMapMarker._cachedViewportW or 1920) * scale
        screenPixelH = (PlayerMapMarker._cachedViewportH or 1080) * scale
    end

    if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0,Y=0} end
    PlayerMapMarker._CachedTopCenterPixel.X = screenPixelW / 2.0
    PlayerMapMarker._CachedTopCenterPixel.Y = (PlayerMapMarker.SnapLineOriginY or 50) * scale

    local fromCanvasPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
    return fromCanvasPos.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0), fromCanvasPos.Y
end

function PlayerMapMarker.CreateSnapLine()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end

    local layerDefs = {
        {r = 0.9, g = 0.05, b = 0.0, a = 0.35, thick = 2.5, z = 0},
        {r = 1.0, g = 0.85, b = 0.0, a = 0.9, thick = 1.0, z = 1},
    }

    if _G.SnapLineCustomColor then
        layerDefs[1].r = _G.SnapLineCustomColor.R
        layerDefs[1].g = _G.SnapLineCustomColor.G
        layerDefs[1].b = _G.SnapLineCustomColor.B
        layerDefs[1].a = 0.4
        layerDefs[2].r = _G.SnapLineCustomColor.R
        layerDefs[2].g = _G.SnapLineCustomColor.G
        layerDefs[2].b = _G.SnapLineCustomColor.B
        layerDefs[2].a = 1.0
    end

    local Layers = {}
    for _, ld in ipairs(layerDefs) do
        local Border = nil
        pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
        if Border and slua.isValid(Border) then
            local lc = FLinearColor_ESP9 and FLinearColor_ESP9(ld.r, ld.g, ld.b, ld.a) or {R=ld.r,G=ld.g,B=ld.b,A=ld.a}
            pcall(function() Border:SetBrushColor(lc) end)
            pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() Border.RenderTransformPivot = FVector2D_ESP9 and FVector2D_ESP9(0.0, 0.5) or {X=0,Y=0.5} end)
            pcall(function() Border:SetRenderTransformPivot(FVector2D_ESP9 and FVector2D_ESP9(0.0, 0.5) or {X=0,Y=0.5}) end)

            local Slot = nil
            pcall(function()
                Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
                if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(ld.z) end
            end)
            if Slot then
                table.insert(Layers, { Widget = Border, Slot = Slot, Thick = ld.thick })
            end
        end
    end

    if #Layers == 0 then return nil end

    local coreLayer = Layers[2] or Layers[1]
    return {
        Widget = coreLayer.Widget,
        Slot = coreLayer.Slot,
        Layers = Layers,
        _CachedPosVec = nil,
        _CachedSizeVec = nil,
    }
end

function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
    if not PlayerMapMarker.bUseSnapLines then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]

    local function IsLineDataValid(ld)
        if not ld or not ld.Widget or not slua.isValid(ld.Widget) or not ld.Slot then return false end
        if ld.Layers then
            for _, layer in ipairs(ld.Layers) do
                if not layer.Widget or not slua.isValid(layer.Widget) or not layer.Slot then return false end
            end
        end
        return true
    end

    if LineData and not IsLineDataValid(LineData) then
        PlayerMapMarker.RemoveSnapLine(KeyStr)
        LineData = nil
    end

    if not bOnScreen or not CanvasPos then
        if LineData then
            if LineData.Layers then
                for _, layer in ipairs(LineData.Layers) do
                    if layer.Widget and slua.isValid(layer.Widget) then
                        pcall(function() layer.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                    end
                end
            elseif LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            end
        end
        return
    end

    if not LineData then
        LineData = PlayerMapMarker.CreateSnapLine()
        if not LineData or not LineData.Widget or not LineData.Slot then return end
        PlayerMapMarker.SnapLineWidgets[KeyStr] = LineData
    end

    local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
    local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)

    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local baseThick = PlayerMapMarker.SnapLineThickness or 3.0
    local angle_rad = 0
    if math.atan2 then angle_rad = math.atan2(dy, dx) else angle_rad = math.atan(dy, dx) end
    local angle = angle_rad * (180.0 / math.pi)

    local FLC = _G.FLinearColor or import("LinearColor")

    if LineData.Layers then
        for i, layer in ipairs(LineData.Layers) do
            local lt = baseThick * (layer.Thick or 1.0)
            local lY = fromY - lt / 2.0
            pcall(function() layer.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

            if _G.SnapLineCustomColor then
                local alpha = (i == 1) and 0.35 or 0.9
                local lc = FLC and FLC(_G.SnapLineCustomColor.R, _G.SnapLineCustomColor.G, _G.SnapLineCustomColor.B, alpha) or {R=_G.SnapLineCustomColor.R, G=_G.SnapLineCustomColor.G, B=_G.SnapLineCustomColor.B, A=alpha}
                pcall(function() layer.Widget:SetBrushColor(lc) end)
            end

            if not layer._posVec then
                layer._posVec = FVector2D_ESP9 and FVector2D_ESP9(fromX, lY) or {X=fromX, Y=lY}
                layer._sizeVec = FVector2D_ESP9 and FVector2D_ESP9(length, lt) or {X=length, Y=lt}
            else
                layer._posVec.X = fromX; layer._posVec.Y = lY
                layer._sizeVec.X = length; layer._sizeVec.Y = lt
            end
            pcall(function()
                layer.Slot:SetPosition(layer._posVec)
                layer.Slot:SetSize(layer._sizeVec)
            end)
            pcall(function() layer.Widget:SetRenderAngle(angle) end)
        end
    end
end

function PlayerMapMarker.RemoveSnapLine(KeyStr)
    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LineData then
        if LineData.Layers then
            for _, layer in ipairs(LineData.Layers) do
                if layer.Widget and slua.isValid(layer.Widget) then
                    pcall(function() layer.Widget:RemoveFromParent() layer.Widget:ConditionalBeginDestroy() end)
                end
            end
        elseif LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        end
    end
    PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
end

function PlayerMapMarker.ClearAllSnapLines()
    for KeyStr, LineData in pairs(PlayerMapMarker.SnapLineWidgets) do
        if LineData then
            if LineData.Layers then
                for _, layer in ipairs(LineData.Layers) do
                    if layer.Widget and slua.isValid(layer.Widget) then
                        pcall(function() layer.Widget:RemoveFromParent() layer.Widget:ConditionalBeginDestroy() end)
                    end
                end
            elseif LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
            end
        end
    end
    PlayerMapMarker.SnapLineWidgets = {}
end

function PlayerMapMarker.RemoveESPWidget(Widget, KeyStr)
    if not Widget then return end
    local Container = Widget.Container or Widget
    pcall(function()
        local ptr = tostring(Container)
        PlayerMapMarker.ESPWidgetPtrs[ptr] = nil
        Container:RemoveFromParent()
        Container:ConditionalBeginDestroy()
    end)
    if KeyStr then PlayerMapMarker.RemoveSnapLine(KeyStr) end
end

function PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, screenX, screenY)
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return screenX * scaleX + offsetX, screenY * scaleY + offsetY
end

function PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, WorldLoc)
    if not IsValid_ESP9(PC) or not WorldLoc then return false, 0, 0 end

    if not PlayerMapMarker._tempScreenPixelPos then
        PlayerMapMarker._tempScreenPixelPos = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}
    end
    local tempPos = PlayerMapMarker._tempScreenPixelPos

    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, tempPos, true)
        if res == true or res == 1 then bOK = true end
    end)

    if not bOK or (tempPos.X == 0 and tempPos.Y == 0) then return false, 0, 0 end

    local canvasX, canvasY = PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, tempPos.X, tempPos.Y)
    return true, canvasX, canvasY
end

function PlayerMapMarker.ClearAllESP()
    RedBoxOverlay.Stop()
    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
    end
    PlayerMapMarker.ESPWidgets = {}
    PlayerMapMarker.ESPWidgetPtrs = {}
    PlayerMapMarker.ClearAllSnapLines()
    PlayerMapMarker.ESPCanvas = nil
    PlayerMapMarker._OBHeadWidgetClass = nil
    PlayerMapMarker._OBHeadWidgetLoadFailed = false
    PlayerMapMarker._cachedViewportW = 1920
    PlayerMapMarker._cachedViewportH = 1080
    -- match-transition reset
    PlayerMapMarker.bActive = false
    PlayerMapMarker._timersAttached = false
    PlayerMapMarker._timersPC = nil
    PlayerMapMarker._CachedPC = nil
    PlayerMapMarker._CachedTopCenterPixel = nil
end

function PlayerMapMarker.UpdateESP(AllPlayers, MyLoc)
    if not PlayerMapMarker.bUseScreenESP then return end

    PlayerMapMarker.bUseSnapLines = _G.Mod_ESP_ShowSnapline

    if not PlayerMapMarker.InitESPCanvas() then return end
    if PlayerMapMarker._OBHeadWidgetLoadFailed then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if IsValid_ESP9(PC) then PlayerMapMarker.UpdateCanvasTransform(PC) end

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines and IsValid_ESP9(PC) then
        fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local SeenKeys = {}
    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
        else if PC and PC.GetPawn then MyChar = PC:GetPawn() end end
    end)

    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    for PlayerKey, Character in pairs(AllPlayers) do
        if IsValid_ESP9(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local KeyStr = tostring(PlayerKey)
            local Name = PlayerMapMarker.GetPlayerName(Character)
            local Loc = PlayerMapMarker.GetESPLocation(Character)
            local DistStr = ""
            if MyLoc and Loc then DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc) end

            local bSkip = false
            if bIsMe and not PlayerMapMarker.bIncludeMe then bSkip = true end
            if bIsAI and not PlayerMapMarker.bIncludeAI then bSkip = true end

            local TeamID = PlayerMapMarker.GetTeamID(Character)
            if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then bSkip = true end

            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if not bSkip and Loc then
                SeenKeys[KeyStr] = true
                local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]

                local Text = ""
                if _G.Mod_ESP_ShowName then Text = Name end
                if _G.Mod_ESP_ShowDistance and DistStr ~= "" then
                    if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                end

                local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)

                if not ESPData then
                    local Widget = PlayerMapMarker.CreateESPWidget()
                    if Widget then
                        PlayerMapMarker.ESPWidgets[KeyStr] = { Widget = Widget, Character = Character, Name = Name, LastDistStr = DistStr, TeamID = TeamID }
                        PlayerMapMarker.UpdateESPText(Widget, Text)
                        if bIsAlive then
                            PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                            local HP = Character.Health or 0
                            local MaxHP = Character.MaxHealth or 120
                            local pct = 0
                            if HP > 0 and MaxHP > 0 then pct = HP / MaxHP; if pct > 1 then pct = 1 end; if pct < 0 then pct = 0 end end
                            PlayerMapMarker.UpdateESPHealth(Widget, pct)
                            if PlayerMapMarker.bUseSnapLines then
                                PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                            else
                                PlayerMapMarker.RemoveSnapLine(KeyStr)
                            end
                        else
                            local Container = Widget.Container or Widget
                            pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            PlayerMapMarker.UpdateESPHealth(Widget, 0)
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                        end
                    end
                else
                    ESPData.Character = Character
                    ESPData.Name = Name
                    ESPData.LastDistStr = DistStr
                    ESPData.TeamID = TeamID
                    ESPData.Widget._LastESPText = nil
                    PlayerMapMarker.UpdateESPText(ESPData.Widget, Text)
                    PlayerMapMarker.UpdateESPPositionWithPC(ESPData.Widget, Loc, PC, CanvasPos)

                    local HP = Character.Health or 0
                    local MaxHP = Character.MaxHealth or 120
                    local pct = 0
                    if HP > 0 and MaxHP > 0 then pct = HP / MaxHP; if pct > 1 then pct = 1 end; if pct < 0 then pct = 0 end end
                    PlayerMapMarker.UpdateESPHealth(ESPData.Widget, pct)

                    if bIsAlive then
                        if PlayerMapMarker.bUseSnapLines then
                            PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                        else
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                        end
                    else
                        -- DEAD FIX: don't redraw snap line on corpse
                        local Container = ESPData.Widget.Container or ESPData.Widget
                        pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        PlayerMapMarker.RemoveSnapLine(KeyStr)
                    end
                end
            end
        end
    end

    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        if not SeenKeys[KeyStr] then
            PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
            PlayerMapMarker.ESPWidgets[KeyStr] = nil
        end
    end
    for KeyStr in pairs(PlayerMapMarker.SnapLineWidgets) do
        if not PlayerMapMarker.ESPWidgets[KeyStr] then PlayerMapMarker.RemoveSnapLine(KeyStr) end
    end
end

function PlayerMapMarker.UpdateESPLight()
    if RedBoxOverlay and RedBoxOverlay.bActive then RedBoxOverlay.UpdatePosition() end
    if not PlayerMapMarker.bUseScreenESP then return end

    PlayerMapMarker.bUseSnapLines = _G.Mod_ESP_ShowSnapline

    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid_ESP9(PC) then return end

    PlayerMapMarker.UpdateCanvasTransform(PC)

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Widget = ESPData.Widget
        local Character = ESPData.Character
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)

        if Widget and bWidgetValid and Character and IsValid_ESP9(Character) then
            local bIsAlive = PlayerMapMarker.IsAlive(Character)
            if not bIsAlive then
                pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                PlayerMapMarker.RemoveSnapLine(KeyStr)
            else
                local bShowAnyUI = _G.Mod_ESP_ShowName or _G.Mod_ESP_ShowDistance or _G.Mod_ESP_ShowHealthBar
                if bShowAnyUI then
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                else
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                end

                local Loc = PlayerMapMarker.GetESPLocation(Character)
                if Loc then
                    local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
                    PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)

                    if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                    else PlayerMapMarker.RemoveSnapLine(KeyStr) end
                else
                    PlayerMapMarker.RemoveSnapLine(KeyStr)
                end
            end
        end
    end
end

function PlayerMapMarker.UpdateESPDistances()
    if not PlayerMapMarker.bUseScreenESP then return end

    local MyLoc = PlayerMapMarker.GetMyLocation()
    if not MyLoc then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid_ESP9(PC) then return end

    PlayerMapMarker.UpdateCanvasTransform(PC)

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Character = ESPData.Character
        local Widget = ESPData.Widget
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)

        if Character and IsValid_ESP9(Character) and Widget and bWidgetValid then
            local Loc = PlayerMapMarker.GetESPLocation(Character)
            if Loc then
                local Dist = PlayerMapMarker.CalcDistance(MyLoc, Loc)
                ESPData.LastDistance = Dist

                if PlayerMapMarker.bShowDistance then
                    local DistStr = ""
                    if Dist then
                        local Meters = Dist / 100
                        if Meters < 1000 then DistStr = string.format("%dm", math.floor(Meters))
                        else DistStr = string.format("%.1fkm", Meters / 1000) end
                    end

                    local Name = ESPData.Name or "Unknown"
                    local Text = ""
                    if _G.Mod_ESP_ShowName then Text = Name end
                    if _G.Mod_ESP_ShowDistance and DistStr ~= "" then
                        if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                    end

                    ESPData.LastDistStr = DistStr
                    Widget._LastESPText = nil
                    PlayerMapMarker.UpdateESPText(Widget, Text)
                end
            end
        end
    end
end

function PlayerMapMarker.ScanAndUpdate()
    local AllChars = PlayerMapMarker.GetAllCharacters()
    if not AllChars then RedBoxOverlay.SetCounts(0, 0) return 0 end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local MyLoc = PlayerMapMarker.GetMyLocation()
    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
        else local PC = PlayerMapMarker.GetMyPlayerController() if PC and PC.GetPawn then MyChar = PC:GetPawn() end end
    end)

    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)
    local realPlayers = 0
    local botPlayers = 0

    for PlayerKey, Character in pairs(AllChars) do
        if IsValid_ESP9(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if bIsAlive and not bIsMe then
                local bIsMyTeam = false
                if MyTeamID ~= nil then
                    local targetTeamID = PlayerMapMarker.GetTeamID(Character)
                    if targetTeamID == MyTeamID then bIsMyTeam = true end
                end
                if not bIsMyTeam then
                    if bIsAI then botPlayers = botPlayers + 1
                    else realPlayers = realPlayers + 1 end
                end
            end
        end
    end

    if RedBoxOverlay.bActive then RedBoxOverlay.SetCounts(realPlayers, botPlayers) end

    if PlayerMapMarker.bUseScreenESP then
        PlayerMapMarker.UpdateESP(AllChars, MyLoc)
    end

    return 0
end

function PlayerMapMarker.AttachTimers()
    pcall(function()
        local pc = PlayerMapMarker.GetMyPlayerController()
        if not slua.isValid(pc) or not pc.AddGameTimer then return end

        -- stale-PC reset
        if PlayerMapMarker._timersPC and not slua.isValid(PlayerMapMarker._timersPC) then
            PlayerMapMarker._timersPC = nil
            PlayerMapMarker._timersAttached = false
        end

        if PlayerMapMarker._timersPC == pc and PlayerMapMarker._timersAttached then return end
        PlayerMapMarker._timersPC = pc
        PlayerMapMarker._timersAttached = true

        pcall(function() pc:AddGameTimer(PlayerMapMarker.nUpdateInterval or 0.5, true, function() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.ScanAndUpdate() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._LightUpdateInterval or 0.02, true, function() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.UpdateESPLight() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._DistanceUpdateInterval or 0.1, true, function() if PlayerMapMarker.bActive and PlayerMapMarker.bUseScreenESP and PlayerMapMarker.bShowDistance then pcall(function() PlayerMapMarker.UpdateESPDistances() end) end end) end)
    end)
end

function PlayerMapMarker.Start()
    -- hard guard: agar canvas dead hai to pehle stop
    if PlayerMapMarker.bActive and PlayerMapMarker.ESPCanvas
        and not Game:IsValid(PlayerMapMarker.ESPCanvas) then
        pcall(PlayerMapMarker.Stop)
        PlayerMapMarker.bActive = false
        PlayerMapMarker._timersAttached = false
        PlayerMapMarker._timersPC = nil
    end
    if PlayerMapMarker.bActive then return end
    PlayerMapMarker.bActive = true
    PlayerMapMarker.ScanAndUpdate()
    PlayerMapMarker.AttachTimers()
end

function PlayerMapMarker.Stop()
    PlayerMapMarker.bActive = false
    PlayerMapMarker.ClearAllESP()
end

_G.PlayerMapMarker = PlayerMapMarker

-- ============================================================
-- SECTION 3.5 — ESP V1 (PAKxTEAM/Botmater engine)
-- ============================================================
if not _G.__BOTMATER_V1_INSTALLED then
    _G.__BOTMATER_V1_INSTALLED = true

    if not _G.LunarFeatures then _G.LunarFeatures = {} end
    local LF = _G.LunarFeatures
    if not LF.Now then
        LF.Now = function()
            local t = nil
            pcall(function()
                local GS = _G.GameplayStatics or import("GameplayStatics")
                local w = slua and slua.getWorld and slua.getWorld() or nil
                if GS and w and GS.GetRealTimeSeconds then t = GS.GetRealTimeSeconds(w) end
            end)
            t = tonumber(t)
            if t and t==t and t>=-math.huge and t<math.huge and t>=0 then return t end
            return os.clock()
        end
    end
    if not LF.Error then LF.Error = function(area, err) print("[V1 ERROR]", tostring(area), tostring(err)) end end
    if not LF.Token then LF.Token = { Stopped = false } end
    if not LF.Pump then LF.Pump = function() end end
    if not LF.Wake then LF.Wake = function() end end
    if not LF.NextInterval then LF.NextInterval = function() return 0.5 end end
    if not LF.InstallNativeBulkSwitch then LF.InstallNativeBulkSwitch = function() return true end end
    LF.ESPSettingsEventType = LF.ESPSettingsEventType or -14050701
    LF.ESPSettingsEventID = LF.ESPSettingsEventID or 2
    if not _G.LunarLoginRuntime then _G.LunarLoginRuntime = { Authorized = true } end

    local V2C = _G.FVector2D; if not V2C then pcall(function() V2C = import("Vector2D") end) end
    local V3C = _G.FVector; if not V3C then pcall(function() V3C = import("Vector") end) end
    local LCC = _G.FLinearColor; if not LCC then pcall(function() LCC = import("LinearColor") end) end
    local SBL = nil; pcall(function() SBL = import("SlateBlueprintLibrary") end)
    local WLL = nil; pcall(function() WLL = import("WidgetLayoutLibrary") end)
    local SLC = nil; pcall(function() SLC = import("SlateColor") end)

    _G.g_vipserver_ESPV2 = _G.g_vipserver_ESPV2 or function(x,y) if V2C then return V2C(x,y) end return {X=x,Y=y} end
    _G.g_vipserver_ESPV3 = _G.g_vipserver_ESPV3 or function(x,y,z)
        if V3C then local ok,v=pcall(V3C,x,y,z); if ok and v then return v end end return {X=x,Y=y,Z=z}
    end
    _G.g_vipserver_ESPColor = _G.g_vipserver_ESPColor or function(r,g,b,a)
        if LCC then return LCC(r,g,b,a or 1) end return {R=r,G=g,B=b,A=a or 1}
    end

    local function Finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
    local function SafeNumber(v,fb,lo,hi) local n=tonumber(v); if not Finite(n) then n=fb end return math.max(lo,math.min(hi,n)) end
    local function VectorValues(v)
        if not v then return nil end
        local ok,x,y,z=pcall(function() return tonumber(v.X),tonumber(v.Y),tonumber(v.Z) end)
        if ok and Finite(x) and Finite(y) and Finite(z) and math.abs(x)<1e12 and math.abs(y)<1e12 and math.abs(z)<1e12 then return x,y,z end
    end
    local function ESPValid(o) if not o then return false end local ok,v=pcall(function() return slua.isValid(o) end) return ok and v==true end
    _G.g_vipserver_ESPValid = _G.g_vipserver_ESPValid or ESPValid

    local ESPShared = {}
    ESPShared.Finite = Finite
    ESPShared.SafeNumber = SafeNumber
    ESPShared.VectorValues = VectorValues

    ESPShared.Frame = {Active=false, Entries={}, Pool={}, PoolLimit=256, Now=0, ViewAt=-999, Controllers={}, Transforms={}, TransformPool={}}
    ESPShared.Frame.Finish = function()
        local frame=ESPShared.Frame
        for actor,entry in pairs(frame.Entries) do
            frame.Entries[actor]=nil
            entry.Location=nil;entry.LocationX=nil;entry.LocationY=nil;entry.LocationZ=nil
            entry.DistanceOrigin=nil;entry.DistanceSquared=nil;entry.DistanceMeters=nil
            entry.Alive=false;entry.Projected=false;entry.OnScreen=false
            entry.HasHead=false;entry.HasFeet=false;entry.PC=nil
            if #frame.Pool<frame.PoolLimit then frame.Pool[#frame.Pool+1]=entry end
        end
        for pc in pairs(frame.Controllers) do frame.Controllers[pc]=nil end
        for state,value in pairs(frame.Transforms) do
            frame.Transforms[state]=nil
            if #frame.TransformPool<4 then frame.TransformPool[#frame.TransformPool+1]=value end
        end
        frame.DistanceOrigin=nil;frame.OriginX=nil;frame.OriginY=nil;frame.OriginZ=nil
        frame.Pawns=nil;frame.Active=false;frame.V1CanvasChecked=false
    end
    ESPShared.Frame.Begin = function(now) ESPShared.Frame.Finish(); ESPShared.Frame.Now=now; ESPShared.Frame.Active=true end

    ESPShared.Events = {Records=setmetatable({}, {__mode="k"}), Clearers={}}
    _G.LunarESPEvents = ESPShared.Events
    local E = ESPShared.Events
    function E.WorldChanged(world)
        if world==nil then return end
        if E.World~=nil and E.World~=world then E.Records=setmetatable({}, {__mode="k"}) end
        E.World=world
    end
    function E.Clear(actor) for _,clear in ipairs(E.Clearers) do pcall(clear,actor) end end
    function E.Counted(actor) return E.Records[actor]~=2 end
    function E.Visible(actor,snapshot)
        local state=E.Records[actor]
        if state==2 or state==1 then return false end
        return snapshot and snapshot.Alive and snapshot.LifeState~="knocked"
    end
    function E.Project(pc,actor,state)
        local snapshot=ESPShared.GetFrameRecord(actor)
        if not E.Visible(actor,snapshot) then return nil,nil,false,"life" end
        local head,feet,onScreen,reason=ESPShared.ProjectActor(pc,actor,state)
        if not E.Visible(actor,snapshot) then return nil,nil,false,"life" end
        return head,feet,onScreen,reason
    end
    function E.ClearIn(state,prune,actor)
        for _,item in ipairs(state.Enemies) do
            if item.Character==actor then
                local key=item.Key
                local keep=setmetatable({[key]=false},{__index=function() return true end})
                state.Active[key]=nil
                state.Alive[key]=nil
                if state.LastProjected then state.LastProjected[key]=nil end
                prune(keep,keep)
            end
        end
    end
    function E.Observe(actor) return false end
    function E.SyncObservedPawns(pawns) end
    function E.UnbindAll() end
    function E.Unobserve(actor) end

    function ESPShared.GetFrameRecord(actor)
        local frame=ESPShared.Frame
        local entry=frame.Active and frame.Entries[actor]
        if entry then return entry end
        entry=frame.Active and table.remove(frame.Pool) or nil
        if not entry then entry={} end
        entry.Alive,entry.LifeState=_G.g_vipserver_ESPIsAlive(actor)
        entry.Projected=false;entry.OnScreen=false;entry.HasHead=false;entry.HasFeet=false
        entry.Location=entry.Alive and _G.g_vipserver_ESPActorLocation(actor) or nil
        entry.LocationX,entry.LocationY,entry.LocationZ=ESPShared.VectorValues(entry.Location)
        if not entry.LocationX then entry.Location=nil end
        if frame.Active and actor~=nil then frame.Entries[actor]=entry end
        return entry
    end
    function ESPShared.GetFramePawns()
        if ESPShared.Frame.Active and ESPShared.Frame.Pawns then return ESPShared.Frame.Pawns end
        local pawns
        pcall(function() if Game and Game.GetAllPlayerPawns then pawns=Game:GetAllPlayerPawns() end end)
        if not pawns then
            local GDP = _G.GameplayData or require("GameLua.GameCore.Data.GameplayData")
            if GDP then
                if type(GDP.GetAllPlayerCharacters)=="function" then pcall(function() pawns=GDP.GetAllPlayerCharacters() end) end
                if not pawns and type(GDP.GetAllCharacters)=="function" then pcall(function() pawns=GDP:GetAllCharacters() end) end
            end
        end
        if ESPShared.Frame.Active then ESPShared.Frame.Pawns=pawns end
        return pawns
    end
    function ESPShared.DistanceSquaredFrom(entry,origin)
        if not entry or not entry.LocationX then return math.huge end
        local frame=ESPShared.Frame
        if frame.Active and entry.DistanceOrigin==origin and entry.DistanceSquared~=nil then return entry.DistanceSquared end
        local x,y,z
        if frame.Active and frame.DistanceOrigin==origin then
            x,y,z=frame.OriginX,frame.OriginY,frame.OriginZ
        else
            x,y,z=ESPShared.VectorValues(origin)
            if frame.Active then frame.DistanceOrigin=origin;frame.OriginX=x;frame.OriginY=y;frame.OriginZ=z end
        end
        if not x then
            if frame.Active then entry.DistanceOrigin=origin;entry.DistanceSquared=math.huge;entry.DistanceMeters=nil end
            return math.huge
        end
        local dx,dy,dz=x-entry.LocationX,y-entry.LocationY,z-entry.LocationZ
        local sq=dx*dx+dy*dy+dz*dz
        if frame.Active then entry.DistanceOrigin=origin;entry.DistanceSquared=sq;entry.DistanceMeters=nil end
        return sq
    end
    function ESPShared.DistanceMetersFrom(entry,origin)
        local sq=ESPShared.DistanceSquaredFrom(entry,origin)
        if ESPShared.Frame.Active and entry.DistanceMeters~=nil then return entry.DistanceMeters end
        local d=math.sqrt(sq)/100.0
        if ESPShared.Frame.Active then entry.DistanceMeters=d end
        return d
    end
    function ESPShared.InRange(entry,origin,maxRange)
        if not Finite(maxRange) or maxRange<=0 then return ESPShared.DistanceMetersFrom(entry,origin)<=maxRange end
        local sq=ESPShared.DistanceSquaredFrom(entry,origin)
        if sq==math.huge then return false end
        local limit=maxRange*100.0;limit=limit*limit
        if math.abs(sq-limit)<=math.max(1,limit)*1e-12 then return ESPShared.DistanceMetersFrom(entry,origin)<=maxRange end
        return sq<limit
    end
    function ESPShared.ProjectionControllerValid(pc)
        if pc==nil then return false end
        local frame=ESPShared.Frame
        if frame.Active then
            local cached=frame.Controllers[pc]
            if cached~=nil then return cached end
            local valid=ESPValid(pc);frame.Controllers[pc]=valid;return valid
        end
        return ESPValid(pc)
    end
    function ESPShared.CanvasTransform(state)
        local frame=ESPShared.Frame
        local value=frame.Active and frame.Transforms[state]
        local rx,ry,rox,roy=state.CanvasScaleX,state.CanvasScaleY,state.CanvasOffsetX,state.CanvasOffsetY
        if not value or value.RX~=rx or value.RY~=ry or value.ROX~=rox or value.ROY~=roy then
            value=value or (frame.Active and table.remove(frame.TransformPool)) or {}
            value.RX=rx;value.RY=ry;value.ROX=rox;value.ROY=roy
            value.SX=SafeNumber(rx,1,0.00001,100);value.SY=SafeNumber(ry,1,0.00001,100)
            value.OX=SafeNumber(rox,0,-1e7,1e7);value.OY=SafeNumber(roy,0,-1e7,1e7)
            if frame.Active then frame.Transforms[state]=value end
        end
        return value.SX,value.SY,value.OX,value.OY
    end
    function ESPShared.AssignProbeVector(vector,x,y,z) vector.X=x;vector.Y=y;vector.Z=z end
    function ESPShared.UpdateProbeVector(vector,x,y,z)
        if vector and pcall(ESPShared.AssignProbeVector,vector,x,y,z) then return vector end
        return _G.g_vipserver_ESPV3(x,y,z)
    end
    function ESPShared.ViewSize(pc)
        local now=ESPShared.Frame.Active and ESPShared.Frame.Now or _G.g_vipserver_ESPNow()
        if not ESPShared.Frame.Active or ESPShared.Frame.ViewPC~=pc or now<ESPShared.Frame.ViewAt or now-ESPShared.Frame.ViewAt>=0.25 then
            ESPShared.Frame.ViewW,ESPShared.Frame.ViewH=_G.g_vipserver_ESPViewport(pc)
            ESPShared.Frame.ViewPC=pc;ESPShared.Frame.ViewAt=now
        end
        return ESPShared.Frame.ViewW,ESPShared.Frame.ViewH
    end
    function ESPShared.CanvasBounds(pc,state)
        local width,height=ESPShared.ViewSize(pc)
        local sx,sy,ox,oy=ESPShared.CanvasTransform(state)
        local maxX,maxY=ox+width*sx,oy+height*sy
        if Finite(state.ViewportW) and state.ViewportW>1 then maxX=math.min(maxX,ox+state.ViewportW) end
        if Finite(state.ViewportH) and state.ViewportH>1 then maxY=math.min(maxY,oy+state.ViewportH) end
        return ox,oy,maxX,maxY
    end
    function ESPShared.NativeProject(pc,location,pix) return pc:ProjectWorldLocationToScreen(location,pix,true) end
    function ESPShared.ActorProbeLocations(actor,entry)
        local center,height,x,y,z=_G.g_vipserver_ESPGetCharacterVerticalBounds(actor,entry.Location)
        if not x or not height then return nil,nil end
        entry.WorldHead=ESPShared.UpdateProbeVector(entry.WorldHead,x,y,z+height)
        entry.WorldFeet=ESPShared.UpdateProbeVector(entry.WorldFeet,x,y,z-height)
        return entry.WorldHead,entry.WorldFeet
    end
    function ESPShared.ProjectRaw(pc,location,pix)
        if not ESPShared.VectorValues(location) or not ESPShared.ProjectionControllerValid(pc) then return nil end
        pix=pix or _G.g_vipserver_ESPV2(0,0);pix.X=0;pix.Y=0
        local ok,result,out=pcall(ESPShared.NativeProject,pc,location,pix)
        if out then pix=out end
        local good,x,y=pcall(function() return tonumber(pix.X),tonumber(pix.Y) end)
        if not ok or not good or not Finite(x) or not Finite(y) or math.abs(x)>=1e7 or math.abs(y)>=1e7 then return nil,"unavailable" end
        if result==false or result==0 then return nil,"offscreen" end
        if result~=true and result~=1 and not (result==nil and (x~=0 or y~=0)) then return nil,"unavailable" end
        return pix,"visible"
    end
    function ESPShared.ProbeActor(pc,actor)
        local entry=ESPShared.GetFrameRecord(actor)
        if entry.Projected and entry.PC==pc then return entry end
        entry.Projected=true;entry.PC=pc;entry.OnScreen=false;entry.ProjectionReason="unavailable"
        if not entry.Alive or not entry.Location then return entry end
        local ok,head,feet=pcall(ESPShared.ActorProbeLocations,actor,entry)
        if not ok then return entry end
        entry.RawHead=entry.RawHead or _G.g_vipserver_ESPV2(0,0)
        entry.RawFeet=entry.RawFeet or _G.g_vipserver_ESPV2(0,0)
        local hp,hr=ESPShared.ProjectRaw(pc,head,entry.RawHead)
        local fp,fr=ESPShared.ProjectRaw(pc,feet,entry.RawFeet)
        if hp then entry.RawHead=hp end;if fp then entry.RawFeet=fp end
        entry.HasHead=hp~=nil;entry.HasFeet=fp~=nil
        local width,height=ESPShared.ViewSize(pc)
        entry.OnScreen=_G.g_vipserver_ESPActorOnScreen(hp,fp,0,0,width,height)
        if entry.OnScreen then entry.ProjectionReason="visible"
        elseif hp or fp or hr=="offscreen" or fr=="offscreen" then entry.ProjectionReason="offscreen" end
        return entry
    end
    function ESPShared.ProjectActor(pc,actor,state)
        local entry=ESPShared.ProbeActor(pc,actor)
        if not entry.OnScreen then return nil,nil,false,entry.ProjectionReason end
        local sx,sy,ox,oy=ESPShared.CanvasTransform(state)
        local prefix=state==_G.g_vipserver_ShotESP and "V2" or "V1"
        local function convert(raw,field)
            local p=entry[field] or _G.g_vipserver_ESPV2(0,0);entry[field]=p
            p.X=raw.X*sx+ox;p.Y=raw.Y*sy+oy;return p
        end
        local head=entry.HasHead and convert(entry.RawHead,prefix.."Head") or nil
        local feet=entry.HasFeet and convert(entry.RawFeet,prefix.."Feet") or nil
        local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,state)
        local visible=_G.g_vipserver_ESPActorOnScreen(head,feet,minX,minY,maxX,maxY)
        return head,feet,visible,visible and "visible" or "offscreen"
    end

    _G.ESPShared = ESPShared
    _G.g_vipserver_ShotESP = _G.g_vipserver_ShotESP or {
        _BotCache = {},
        TemplateFont = nil, TemplateFontObject = nil, TemplateTypeface = nil, TemplateColorAndOpacity = nil,
        CanvasScaleX = 1.0, CanvasScaleY = 1.0, CanvasOffsetX = 0.0, CanvasOffsetY = 0.0,
    }

    _G.g_vipserver_ESPNow = _G.g_vipserver_ESPNow or function() return LF.Now() end
    _G.g_vipserver_ESPWorld = _G.g_vipserver_ESPWorld or function()
        local w=nil; pcall(function() if slua and slua.getWorld then w=slua.getWorld() end end); return w
    end
    _G.g_vipserver_ESPGetController = _G.g_vipserver_ESPGetController or function()
        local pc=nil
        pcall(function() local GDP = _G.GameplayData or require("GameLua.GameCore.Data.GameplayData"); if GDP and GDP.GetPlayerController then pc=GDP.GetPlayerController() end end)
        if not ESPValid(pc) then pcall(function() if slua_GameFrontendHUD then pc=slua_GameFrontendHUD:GetPlayerController() end end) end
        return ESPValid(pc) and pc or nil
    end
    _G.g_vipserver_ESPGetLocalCharacter = _G.g_vipserver_ESPGetLocalCharacter or function()
        local c=nil
        pcall(function() local GDP=_G.GameplayData or require("GameLua.GameCore.Data.GameplayData"); if GDP then
            if GDP.GetPlayerCharacter then c=GDP.GetPlayerCharacter() end
            if not ESPValid(c) and GDP.GetLocalCharacter then c=GDP.GetLocalCharacter() end
        end end)
        if not ESPValid(c) then local pc=_G.g_vipserver_ESPGetController(); if pc then pcall(function() if pc.GetPawn then c=pc:GetPawn() end end) end end
        return ESPValid(c) and c or nil
    end
    _G.g_vipserver_ESPGetPlayerKey = _G.g_vipserver_ESPGetPlayerKey or function(character)
        if not ESPValid(character) then return tostring(character) end
        local key=nil
        pcall(function() if character.GetPlayerKey then key=character:GetPlayerKey() end end)
        if key==nil then pcall(function() key=character.PlayerKey end) end
        if key==nil then pcall(function() local ps=character.PlayerState; if ps then key=ps.PlayerKey end end) end
        if key==nil or tostring(key)=="" or tostring(key)=="0" or tostring(key)=="-1" then return tostring(character) end
        return tostring(key).."_"..tostring(character)
    end
    _G.g_vipserver_ESPIsAlive = _G.g_vipserver_ESPIsAlive or function(c)
        if not ESPValid(c) then return false,"invalid" end
        local dead=false
        pcall(function() if c.bDead==true or c.bIsDead==true or c.bIsDeadFlag==true then dead=true end end)
        if dead then return false,"dead" end
        local hp=nil
        pcall(function() hp=c.Health or c.HP or c.CurrentHealth end)
        hp=tonumber(hp)
        if Finite(hp) then return hp>0,hp>0 and "alive" or "dead" end
        local alive=false
        pcall(function() if c.IsAlive then alive=c:IsAlive() end end)
        if alive==true then return true,"alive" end
        return false,"unknown"
    end
    _G.g_vipserver_ESPActorLocation = _G.g_vipserver_ESPActorLocation or function(c)
        local loc=nil
        if not ESPValid(c) then return nil end
        pcall(function()
            if c.K2_GetActorLocation then loc=c:K2_GetActorLocation()
            elseif Game and Game.GetActorLocation then loc=Game:GetActorLocation(c) end
        end)
        return loc
    end
    _G.g_vipserver_ESPIsBot = _G.g_vipserver_ESPIsBot or function(c, key, cache, now)
        if not ESPValid(c) then return false end
        key = key or _G.g_vipserver_ESPGetPlayerKey(c)
        cache = cache or (_G.g_vipserver_ShotESP and _G.g_vipserver_ShotESP._BotCache) or {}
        now = now or LF.Now()
        local entry = cache[key]
        if entry and now>=entry.Clock and now-entry.Clock<2.0 then return entry.Value end
        local result = nil
        local function take(v) if result==nil and (v==true or v==false or v==1 or v==0) then result=(v==true or v==1) end end
        pcall(function() if Game and Game.IsAI then take(Game:IsAI(c)) end end)
        if result==nil then pcall(function() take(c.bIsAI) end) end
        if result==nil then pcall(function() if c.IsBot then take(c:IsBot()) end end) end
        if result==nil then
            pcall(function()
                local ps=c.PlayerState or (c.GetPlayerState and c:GetPlayerState())
                if ps then
                    take(ps.bIsABot); take(ps.bIsBot); take(ps.bIsAI)
                    if result==nil and ps.IsBot then take(ps:IsBot()) end
                end
            end)
        end
        cache[key] = result ~= nil and {Value=result, Clock=now} or nil
        return result == true
    end
    _G.g_vipserver_ESPViewport = _G.g_vipserver_ESPViewport or function(pc)
        local w,h=nil,nil
        local function take(x,y) x,y=tonumber(x),tonumber(y); if Finite(x) and Finite(y) and x>200 and y>200 and x<1e6 and y<1e6 then w,h=x,y; return true end end
        pcall(function() if WLL and WLL.GetViewportSize then local v=WLL.GetViewportSize(pc); if v then take(v.X,v.Y) end end end)
        if not w and pc then pcall(function() local x,y=pc:GetViewportSize(); take(x,y) end) end
        if not w and pc then pcall(function() local v=_G.g_vipserver_ESPV2(0,0); pc:GetViewportSize(v); take(v.X,v.Y) end) end
        return w or 2400.0, h or 1080.0
    end
    _G.g_vipserver_ESPGetCanvas = _G.g_vipserver_ESPGetCanvas or function()
        local state=_G.g_vipserver_ShotESP
        if ESPValid(state.Canvas) then return state.Canvas end
        local root=nil
        pcall(function()
            local ui=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            if ui and ui.GetMainControlBaseUI then root=ui.GetMainControlBaseUI() end
        end)
        if not ESPValid(root) then return nil end
        state.RootUI = root
        local canvas=nil
        pcall(function()
            if ESPValid(root.CanvasPanel_0) then canvas=root.CanvasPanel_0
            elseif ESPValid(root.CanvasPanel_42) then canvas=root.CanvasPanel_42 end
        end)
        if ESPValid(canvas) then state.Canvas=canvas; return canvas end
        return nil
    end
    _G.g_vipserver_ESPGetCanvasLocalSize = _G.g_vipserver_ESPGetCanvasLocalSize or function()
        local canvas=_G.g_vipserver_ESPGetCanvas()
        if not ESPValid(canvas) then return nil,nil end
        local cw,ch=nil,nil
        pcall(function()
            local geo=canvas:GetCachedGeometry()
            if not geo then return end
            local size=nil
            if geo.GetLocalSize then size=geo:GetLocalSize()
            elseif SBL and SBL.GetLocalSize then size=SBL.GetLocalSize(geo) end
            if size and Finite(size.X) and Finite(size.Y) and size.X>100 and size.Y>100 then cw,ch=tonumber(size.X),tonumber(size.Y) end
        end)
        return cw,ch
    end
    _G.g_vipserver_ESPUpdateCanvasTransform = _G.g_vipserver_ESPUpdateCanvasTransform or function(pc)
        local state=_G.g_vipserver_ShotESP
        local canvas=_G.g_vipserver_ESPGetCanvas()
        if not ESPValid(canvas) then return false end
        local calibrated=false
        pcall(function()
            if SBL and SBL.AbsoluteToLocal then
                local geo=canvas:GetCachedGeometry()
                if geo then
                    local p0=SBL.AbsoluteToLocal(geo,_G.g_vipserver_ESPV2(0,0))
                    local p1=SBL.AbsoluteToLocal(geo,_G.g_vipserver_ESPV2(100,100))
                    if p0 and p1 and Finite(p0.X) and Finite(p0.Y) and Finite(p1.X) and Finite(p1.Y)
                        and math.abs(p0.X)<1e7 and math.abs(p0.Y)<1e7 and p1.X>p0.X and p1.Y>p0.Y
                        and p1.X-p0.X<10000 and p1.Y-p0.Y<10000 then
                        state.CanvasScaleX=(p1.X-p0.X)/100
                        state.CanvasScaleY=(p1.Y-p0.Y)/100
                        state.CanvasOffsetX=p0.X
                        state.CanvasOffsetY=p0.Y
                        calibrated=true
                    end
                end
            end
        end)
        if not calibrated then
            local scale=1.0
            pcall(function() if WLL and WLL.GetViewportScale then local s=WLL.GetViewportScale(pc); if Finite(s) and s>=0.01 and s<=100 then scale=s end end end)
            state.CanvasScaleX=1.0/scale; state.CanvasScaleY=1.0/scale
            state.CanvasOffsetX=0.0; state.CanvasOffsetY=0.0
        end
        return true
    end
    _G.g_vipserver_ESPSetFont = _G.g_vipserver_ESPSetFont or function(textWidget, size, _)
        if not ESPValid(textWidget) then return end
        pcall(function()
            local f = textWidget.Font
            if f then
                pcall(function() f.Size = size end)
                pcall(function() textWidget:SetFont(f) end)
                pcall(function() textWidget.Font = f end)
            end
            if textWidget.SetShadowOffset then pcall(function() textWidget:SetShadowOffset(_G.g_vipserver_ESPV2(0,0)) end) end
        end)
    end
    _G.g_vipserver_ESPSetTextColor = _G.g_vipserver_ESPSetTextColor or function(textWidget, color)
        if not ESPValid(textWidget) or not color then return end
        local applied=false
        pcall(function()
            local sc=textWidget.ColorAndOpacity or (SLC and SLC())
            if sc then
                sc.SpecifiedColor=color
                pcall(function() sc.ColorUseRule=0 end)
                textWidget:SetColorAndOpacity(sc)
                pcall(function() textWidget.ColorAndOpacity=sc end)
                applied=true
            end
        end)
        if not applied then pcall(function() textWidget:SetColorAndOpacity(color) end) end
        pcall(function() if textWidget.SetOpacity then textWidget:SetOpacity(1.0) end end)
        pcall(function() if textWidget.SetRenderOpacity then textWidget:SetRenderOpacity(1.0) end end)
    end
    _G.g_vipserver_ESPDrawLine = _G.g_vipserver_ESPDrawLine or function(data, x1, y1, x2, y2, thickness)
        if not data or not data.Widget or not data.Slot then return false end
        local dx,dy=x2-x1,y2-y1
        local len=math.sqrt(dx*dx+dy*dy)
        if len<1 then
            if data.Visible~=false then
                pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                data.Visible=false
            end
            return false
        end
        local angle=((math.atan2 and math.atan2(dy,dx)) or math.atan(dy,dx))*180.0/math.pi
        local unchanged=data.Visible==true and data.X1 and
            math.abs(data.X1-x1)<0.25 and math.abs(data.Y1-y1)<0.25 and
            math.abs(data.X2-x2)<0.25 and math.abs(data.Y2-y2)<0.25 and
            math.abs((data.Thickness or 0)-thickness)<0.05
        if unchanged then return true end
        local ok=pcall(function()
            data.Slot:SetPosition(_G.g_vipserver_ESPV2(x1,y1-thickness*0.5))
            data.Slot:SetSize(_G.g_vipserver_ESPV2(len,thickness))
            data.Widget:SetRenderAngle(angle)
            if not data.Visible then data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
        end)
        if not ok then data.Broken=true return false end
        data.Broken=false
        data.X1,data.Y1,data.X2,data.Y2,data.Thickness=x1,y1,x2,y2,thickness
        data.Visible=true
        return true
    end
    _G.g_vipserver_ESPHide = _G.g_vipserver_ESPHide or function(data)
        if data and data.Visible~=false and data.Widget then
            local ok=pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            if not ok then data.Broken=true end
            data.Visible=false
        end
    end
    _G.g_vipserver_ESPDestroyWidgetData = _G.g_vipserver_ESPDestroyWidgetData or function(data)
        if not data then return end
        if _G.ESPWidgetPool and _G.ESPWidgetPool.Release and _G.ESPWidgetPool.Release(data) then return end
        for _,f in ipairs({"Widget","Container","Text","DistanceText"}) do
            local w=data[f]
            if ESPValid(w) then pcall(function() w:RemoveFromParent() end) end
        end
    end
    _G.g_vipserver_ESPGetCharacterVerticalBounds = _G.g_vipserver_ESPGetCharacterVerticalBounds or function(character,cachedLocation)
        if not ESPValid(character) then return nil,nil end
        local center,halfHeight=nil,nil
        local capsule=nil
        pcall(function()
            if character.GetCapsuleComponent then capsule=character:GetCapsuleComponent()
            elseif character.CapsuleComponent then capsule=character.CapsuleComponent end
        end)
        if capsule and ESPValid(capsule) then
            pcall(function()
                if capsule.K2_GetComponentLocation then center=capsule:K2_GetComponentLocation()
                elseif capsule.GetComponentLocation then center=capsule:GetComponentLocation() end
                if capsule.GetScaledCapsuleHalfHeight then halfHeight=capsule:GetScaledCapsuleHalfHeight()
                elseif capsule.GetUnscaledCapsuleHalfHeight then halfHeight=capsule:GetUnscaledCapsuleHalfHeight()
                elseif capsule.CapsuleHalfHeight then halfHeight=capsule.CapsuleHalfHeight end
            end)
        end
        local cx,cy,cz=ESPShared.VectorValues(center)
        if center and not cx then center=nil end
        if not center then center=cachedLocation end
        if not center then pcall(function() if character.K2_GetActorLocation then center=character:K2_GetActorLocation() end end) end
        if not center then pcall(function() if Game and Game.GetActorLocation then center=Game:GetActorLocation(character) end end) end
        if not cx then cx,cy,cz=ESPShared.VectorValues(center) end
        if not cx then return nil,nil end
        halfHeight=tonumber(halfHeight)
        if not Finite(halfHeight) or halfHeight<10 or halfHeight>200 then
            halfHeight=85
            pcall(function()
                if character.bIsCrouched then halfHeight=60 end
                if character.IsProne and character:IsProne() then halfHeight=25 end
            end)
        end
        return center,halfHeight,cx,cy,cz
    end
    _G.g_vipserver_ESPActorOnScreen = _G.g_vipserver_ESPActorOnScreen or function(head,feet,minX,minY,maxX,maxY)
        local function usable(p) return p and Finite(p.X) and Finite(p.Y) end
        head=usable(head) and head or nil;feet=usable(feet) and feet or nil
        if not head and not feet then return false end
        head=head or feet;feet=feet or head
        return math.max(head.X,feet.X)>=minX and math.min(head.X,feet.X)<=maxX
            and math.max(head.Y,feet.Y)>=minY and math.min(head.Y,feet.Y)<=maxY
    end
    _G.g_vipserver_ESPFilterEnemies = _G.g_vipserver_ESPFilterEnemies or function(list, myLocation, maxRange, alive)
        for key in pairs(alive) do alive[key]=nil end
        local count,kept,realCount,botCount=#list,0,0,0
        maxRange=tonumber(maxRange) or 450.0
        if maxRange~=maxRange or maxRange<=0 or maxRange==math.huge then maxRange=450.0 end
        for i=1,count do
            local item=list[i]
            local character=item and item.Character
            local snapshot=item and item.Key and ESPShared.GetFrameRecord(character)
            if snapshot and snapshot.Alive and ESPShared.Events.Counted(character) then
                local distance=ESPShared.DistanceMetersFrom(snapshot,myLocation)
                if distance<=maxRange then
                    item.Distance=distance
                    kept=kept+1;list[kept]=item;alive[item.Key]=true
                    if item.IsBot then botCount=botCount+1 else realCount=realCount+1 end
                end
            end
        end
        for i=kept+1,count do list[i]=nil end
        return realCount,botCount
    end

    -- ESPWidgetPool
    do
        local ESPWidgetPool = _G.ESPWidgetPool or {V1={}, V2={}}
        local shapes = {
            Line = {Fields={"Widget","Slot","PosVec","SizeVec","VectorReuseDisabled"}, Check={"Widget","Slot"}, Limit=256},
            NameV1 = {Fields={"Widget","BottomLine","HealthBg","HealthFill","Text","DistanceText","LineSlot","HealthBgSlot","HealthFillSlot","TextSlot","DistanceSlot","Slot"},
                Check={"Widget","BottomLine","HealthBg","HealthFill","Text","DistanceText","LineSlot","HealthBgSlot","HealthFillSlot","TextSlot","DistanceSlot","Slot"}, Limit=16},
        }
        local function remove(widget) if widget then pcall(function() widget:RemoveFromParent() end) end end
        function ESPWidgetPool.New(cap) return {Bins={},Canvas=nil,Enabled=true,Weight=0,Capacity=cap,Reused=0,Released=0,Created=0,Discarded=0} end
        if not ESPWidgetPool.V1 or not ESPWidgetPool.V1.Bins then ESPWidgetPool.V1 = ESPWidgetPool.New(128) end
        if not ESPWidgetPool.V2 or not ESPWidgetPool.V2.Bins then ESPWidgetPool.V2 = ESPWidgetPool.New(1024) end
        function ESPWidgetPool.Flush(pool)
            for kind,bin in pairs(pool.Bins) do
                for i=#bin,1,-1 do local item=bin[i];bin[i]=nil;remove(item.Widget);for k in pairs(item) do item[k]=nil end end
                pool.Bins[kind]=nil
            end
            pool.Canvas=nil;pool.Weight=0
        end
        function ESPWidgetPool.Tag(pool,kind,canvas,data)
            if pool.Canvas~=canvas then ESPWidgetPool.Flush(pool);pool.Canvas=canvas end
            data.PoolOwner=pool;data.PoolKind=kind;data.PoolCanvas=canvas
            pool.Created=pool.Created+1
            return data
        end
        function ESPWidgetPool.Release(data)
            if data.PoolReleased then return true end
            local pool,kind,canvas=data.PoolOwner,data.PoolKind,data.PoolCanvas
            if not pool or not pool.Enabled or pool.Canvas~=canvas or data.Broken or not ESPValid(data.Widget) then return false end
            local shape=shapes[kind]
            if not shape then return false end
            local bin=pool.Bins[kind]
            if not bin then bin={};pool.Bins[kind]=bin end
            if #bin>=shape.Limit or pool.Weight+1>pool.Capacity then return false end
            local ok=pcall(function()
                data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                if data.Text then data.Text:SetText("") end
                if data.DistanceText then data.DistanceText:SetText("") end
            end)
            if not ok then return false end
            local item={Weight=1}
            for _,field in ipairs(shape.Fields) do item[field]=data[field] end
            for field in pairs(data) do data[field]=nil end
            data.PoolReleased=true
            bin[#bin+1]=item;pool.Weight=pool.Weight+1;pool.Released=pool.Released+1
            return true
        end
        function ESPWidgetPool.Take(pool,kind,canvas)
            if pool.Canvas~=canvas then ESPWidgetPool.Flush(pool);pool.Canvas=canvas end
            if not pool.Enabled then return nil end
            local shape,bin=shapes[kind],pool.Bins[kind]
            if not shape or not bin then return nil end
            while #bin>0 do
                local item=bin[#bin];bin[#bin]=nil;pool.Weight=pool.Weight-item.Weight
                local valid=true
                for _,field in ipairs(shape.Check) do
                    if not ESPValid(item[field]) then valid=false;break end
                end
                if valid then
                    local ok,parent=pcall(function() return item.Widget:GetParent() end)
                    valid=ok and parent==canvas
                end
                if valid then
                    local data={PoolOwner=pool,PoolKind=kind,PoolCanvas=canvas}
                    for _,field in ipairs(shape.Fields) do data[field]=item[field] end
                    pool.Reused=pool.Reused+1
                    return data
                end
                remove(item.Widget);pool.Discarded=pool.Discarded+1
                for key in pairs(item) do item[key]=nil end
            end
            return nil
        end
        _G.ESPWidgetPool = ESPWidgetPool
    end

    _G.g_Botmater_ESPOptions = _G.g_Botmater_ESPOptions or {
        Name = true, Line = false, Health = true, Distance = true, EnemyCounter = true,
    }
    _G.g_Botmater_VIPShotESP = _G.g_Botmater_VIPShotESP or {
        Enabled = true,
        MaxRangeMeters = 300.0,
        ScanInterval = 0.05,
        UpdateInterval = 1/60,
        TransformInterval = 0.033,
        MaxRendered = 10,
        TracerThickness = 1.0,
        NameGap = 2.0,
        NameFontSize = 9,
        DistanceFontSize = 10,
        DistanceBelowFeet = 14,
    }

    local g_Botmater_ShotESP = {
        Canvas = nil, Enemies = {}, Lines = {}, Names = {},
        LastScanClock = -999.0, LastTransformClock = -999.0, LastWorld = nil,
        CanvasScaleX = 1.0, CanvasScaleY = 1.0, CanvasOffsetX = 0.0, CanvasOffsetY = 0.0,
        LastPawn=nil, LastController=nil, Active={}, Alive={}, LastProjected={},
        RealCount = 0, BotCount = 0,
    }

    local V2 = _G.FVector2D
    if not V2 then pcall(function() V2 = import("Vector2D") end) end
    local LinearColor = _G.FLinearColor
    if not LinearColor then pcall(function() LinearColor = import("LinearColor") end) end
    local SlateBlueprintLibrary_V1 = nil
    pcall(function() SlateBlueprintLibrary_V1 = import("SlateBlueprintLibrary") end)
    local WidgetLayoutLibrary_V1 = nil
    pcall(function() WidgetLayoutLibrary_V1 = import("WidgetLayoutLibrary") end)

    local function g_Botmater_ESPV2(x, y)
        if V2 then return V2(x, y) end
        return {X = x, Y = y}
    end
    local function g_Botmater_ESPColor(r, g, b, a)
        if LinearColor then return LinearColor(r, g, b, a or 1.0) end
        return {R=r, G=g, B=b, A=a or 1.0}
    end

    local COLOR_REAL_VIS_RED          = g_Botmater_ESPColor(1.00, 0.00, 0.00, 1.00)
    local COLOR_BOT_VIS_CYAN          = g_Botmater_ESPColor(1.00, 1.00, 1.00, 1.00)
    local COLOR_TEXT_WHITE            = g_Botmater_ESPColor(1.00, 1.00, 1.00, 1.00)
    local COLOR_TEXT_BLACK            = g_Botmater_ESPColor(0.00, 0.00, 0.00, 1.00)
    local CACHE_COUNTER_PLAYER_BG   = g_Botmater_ESPColor(1.0, 0.0, 0.0, 1.0)
    local CACHE_COUNTER_BOT_BG      = g_Botmater_ESPColor(1.0, 1.0, 1.0, 1.0)
    local CACHE_COUNTER_PLAYER_TEXT = g_Botmater_ESPColor(0.0, 0.0, 0.0, 1.0)
    local CACHE_COUNTER_BOT_TEXT    = g_Botmater_ESPColor(0.0, 0.0, 0.0, 1.0)
    local COLOR_HP = {
        RealText=g_Botmater_ESPColor(1.0,0.86,0.84,1.0),
        BotText=g_Botmater_ESPColor(1.0,1.0,1.0,1.0),
        RealMid=g_Botmater_ESPColor(0.78,0.0,0.0,1.0),
        RealLow=g_Botmater_ESPColor(0.55,0.0,0.0,1.0),
        BotMid=g_Botmater_ESPColor(0.075,0.75,0.75,1.0),
        BotLow=g_Botmater_ESPColor(0.055,0.55,0.55,1.0),
        RealBG=g_Botmater_ESPColor(0.06,0.005,0.005,0.75),
        BotBG=g_Botmater_ESPColor(0.005,0.06,0.06,0.75)
    }

    _G.g_Botmater_VIPShotESP.NameFontSize=math.max(12,tonumber(_G.g_Botmater_VIPShotESP.NameFontSize) or 12)
    _G.g_Botmater_VIPShotESP.DistanceFontSize=math.max(12,tonumber(_G.g_Botmater_VIPShotESP.DistanceFontSize) or 12)

    local function g_Botmater_ESPGetColors(isBot)
        if isBot then return COLOR_BOT_VIS_CYAN, COLOR_HP.BotText
        else return COLOR_REAL_VIS_RED, COLOR_HP.RealText end
    end
    local function g_Botmater_ESPValid(obj)
        if not obj then return false end
        local ok, valid = pcall(function() return slua.isValid(obj) end)
        return ok and valid == true
    end
    local function g_Botmater_ESPNow() return _G.LunarFeatures.Now() end
    local function g_Botmater_ESPWorld()
        local w = nil
        pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
        return w
    end
    local function g_Botmater_ESPGetController() return _G.g_vipserver_ESPGetController() end
    local function g_Botmater_ESPGetLocalCharacter() return _G.g_vipserver_ESPGetLocalCharacter() end
    local function g_Botmater_ESPGetPlayerState(character)
        if not g_Botmater_ESPValid(character) then return nil end
        local ps = nil
        pcall(function() if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end end)
        if not g_Botmater_ESPValid(ps) then pcall(function() if character.GetPlayerState then ps = character:GetPlayerState() end end) end
        if not g_Botmater_ESPValid(ps) then pcall(function() ps = character.PlayerState end) end
        return g_Botmater_ESPValid(ps) and ps or nil
    end
    local function g_Botmater_ESPNormalizeName(value)
        if value == nil or value == false then return nil end
        local ok, text = pcall(tostring, value)
        if not ok or not text then return nil end
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" or text == "nil" or text == "None" or text == "NULL" then return nil end
        return text
    end
    local function g_Botmater_ESPResolvePlayerName(character)
        if not g_Botmater_ESPValid(character) then return nil end
        local name = nil
        local function take(value) if not name then name = g_Botmater_ESPNormalizeName(value) end end
        pcall(function() if character.GetPlayerNameSafety then take(character:GetPlayerNameSafety()) end end)
        pcall(function() if not name and character.GetPlayerName then take(character:GetPlayerName()) end end)
        pcall(function() if not name then take(character.PlayerName) end end)
        pcall(function() if not name then take(character.NickName) end end)
        if not name then
            local ps = g_Botmater_ESPGetPlayerState(character)
            if ps then
                pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
                pcall(function() if not name then take(ps.PlayerName) end end)
                pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
                pcall(function() if not name then take(ps.NickName) end end)
            end
        end
        return name
    end
    local function g_Botmater_ESPGetPlayerKey(c) return _G.g_vipserver_ESPGetPlayerKey(c) end
    local function g_Botmater_ESPGetTeamID(character)
        if not g_Botmater_ESPValid(character) then return nil end
        local id = nil
        pcall(function() if character.GetTeamID then id = character:GetTeamID() end end)
        if id == nil then pcall(function() id = character.TeamID end) end
        if id == nil then
            local ps = g_Botmater_ESPGetPlayerState(character)
            if ps then
                pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
                if id == nil then pcall(function() id = ps.TeamID end) end
            end
        end
        return id
    end
    local function g_Botmater_ESPGetHealthPct(character)
        if not g_Botmater_ESPValid(character) then return 1.0 end
        local hp, maxHp = nil, nil
        pcall(function() hp = character.Health end)
        if type(hp) ~= "number" then pcall(function() hp = character.HP end) end
        pcall(function() maxHp = character.MaxHealth end)
        if type(maxHp) ~= "number" then pcall(function() maxHp = character.MaxHP end) end
        if not ESPShared.Finite(hp) then return 1.0 end
        if not ESPShared.Finite(maxHp) or maxHp <= 0 then maxHp = 100 end
        local pct = hp / maxHp
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        return pct
    end
    local function g_Botmater_ESPGetHealthColor(pct,isBot)
        pct = tonumber(pct) or 1.0
        if pct >= 0.75 then return isBot and COLOR_BOT_VIS_CYAN or COLOR_REAL_VIS_RED
        elseif pct >= 0.50 then return isBot and COLOR_HP.BotMid or COLOR_HP.RealMid
        else return isBot and COLOR_HP.BotLow or COLOR_HP.RealLow end
    end
    local function g_Botmater_ESPIsBot(c)
        g_Botmater_ShotESP._BotCache=g_Botmater_ShotESP._BotCache or {}
        return _G.g_vipserver_ESPIsBot(c,_G.g_vipserver_ESPGetPlayerKey(c),g_Botmater_ShotESP._BotCache,_G.LunarFeatures.Now())
    end

    local V1Cleanup={Items={},Members={},Count=0,Cursor=1,Due=0,Limit=512,AdmissionLimit=128}
    function V1Cleanup.Try(widget)
        if not g_Botmater_ESPValid(widget) then return true end
        local hidden,accepted=pcall(function() return widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        if not hidden or accepted==false then pcall(function() widget:SetRenderOpacity(0) end) end
        local ok,result=pcall(function() return widget:RemoveFromParent() end)
        if not ok or result==false then return false end
        local checked,parent=pcall(function() return widget:GetParent() end)
        return not checked or parent==nil
    end
    function V1Cleanup.Retire(widget)
        if not widget then return true end
        if V1Cleanup.Members[widget] then return true end
        if V1Cleanup.Try(widget) then return true end
        if V1Cleanup.Count>=V1Cleanup.Limit then return false end
        V1Cleanup.Count=V1Cleanup.Count+1
        V1Cleanup.Items[V1Cleanup.Count]=widget
        V1Cleanup.Members[widget]=true
        return true
    end
    function V1Cleanup.Pump(now)
        if V1Cleanup.Count==0 then return end
        if now>=V1Cleanup.Due-0.05 and now<V1Cleanup.Due then return end
        V1Cleanup.Due=now+0.05
        local budget=math.min(8,V1Cleanup.Count)
        while budget>0 and V1Cleanup.Count>0 do
            budget=budget-1
            local i=V1Cleanup.Cursor
            if i>V1Cleanup.Count then i=1 end
            local widget=V1Cleanup.Items[i]
            if V1Cleanup.Try(widget) then
                V1Cleanup.Members[widget]=nil
                V1Cleanup.Items[i]=V1Cleanup.Items[V1Cleanup.Count]
                V1Cleanup.Items[V1Cleanup.Count]=nil
                V1Cleanup.Count=V1Cleanup.Count-1
                V1Cleanup.Cursor=i
            else
                V1Cleanup.Cursor=i+1
            end
        end
    end
    _G.ESPWidgetPool.V1.Remove=V1Cleanup.Retire

    local function g_Botmater_ESPDestroyWidgetData(data)
        if not data then return true end
        if _G.ESPWidgetPool.Release(data) then return true end
        return V1Cleanup.Retire(data.Widget or data.Container)
    end

    local function g_Botmater_ESPResetWidgets()
        ESPShared.Frame.V1CanvasChecked=false
        _G.ESPWidgetPool.V1.Enabled=false
        for _,registry in ipairs({g_Botmater_ShotESP.Lines,g_Botmater_ShotESP.Names}) do
            for key,data in pairs(registry) do
                if g_Botmater_ESPDestroyWidgetData(data) then registry[key]=nil end
            end
        end
        g_Botmater_ShotESP.Canvas=nil
        g_Botmater_ShotESP.RootUI=nil
        g_Botmater_ShotESP.Enemies={}
        g_Botmater_ShotESP._BotCache={}
        g_Botmater_ShotESP.Active={}
        g_Botmater_ShotESP.Alive={}
        g_Botmater_ShotESP.LastProjected={}
        g_Botmater_ShotESP.RealCount=0;g_Botmater_ShotESP.BotCount=0
        g_Botmater_ShotESP.LastScanClock=-999
        g_Botmater_ShotESP.LastTransformClock=-999
        g_Botmater_ShotESP.LastPawn=nil;g_Botmater_ShotESP.LastController=nil
        g_Botmater_ShotESP.CanvasScaleX=1;g_Botmater_ShotESP.CanvasScaleY=1
        g_Botmater_ShotESP.CanvasOffsetX=0;g_Botmater_ShotESP.CanvasOffsetY=0
        g_Botmater_ShotESP.TransformReady=false
        g_Botmater_ShotESP.TransformW=nil;g_Botmater_ShotESP.TransformH=nil
        _G.ESPWidgetPool.Flush(_G.ESPWidgetPool.V1)
        _G.ESPWidgetPool.V1.Enabled=true
    end

    local function g_Botmater_ESPGetCanvas()
        local frame=ESPShared.Frame
        if frame.Active and frame.V1CanvasChecked then
            return g_Botmater_ESPValid(g_Botmater_ShotESP.Canvas) and g_Botmater_ShotESP.Canvas or nil
        end
        local root
        pcall(function()
            local ui=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            if ui and ui.GetMainControlBaseUI then root=ui.GetMainControlBaseUI() end
        end)
        if not g_Botmater_ESPValid(root) then
            if g_Botmater_ShotESP.Canvas then g_Botmater_ESPResetWidgets() end
            return nil
        end
        local canvas
        pcall(function()
            if g_Botmater_ESPValid(root.CanvasPanel_0) then canvas=root.CanvasPanel_0
            elseif g_Botmater_ESPValid(root.CanvasPanel_42) then canvas=root.CanvasPanel_42 end
        end)
        if not g_Botmater_ESPValid(canvas) then
            if g_Botmater_ShotESP.Canvas then g_Botmater_ESPResetWidgets() end
            return nil
        end
        if g_Botmater_ShotESP.Canvas~=canvas or g_Botmater_ShotESP.RootUI~=root then
            g_Botmater_ESPResetWidgets()
            g_Botmater_ShotESP.Canvas=canvas;g_Botmater_ShotESP.RootUI=root
        end
        if frame.Active then frame.V1CanvasChecked=true end
        return canvas
    end
    local function g_Botmater_ESPViewport(pc) return _G.g_vipserver_ESPViewport(pc) end
    local function g_Botmater_ESPGetCanvasLocalSize()
        local canvas = g_Botmater_ESPGetCanvas()
        if not g_Botmater_ESPValid(canvas) then return nil, nil end
        local cw, ch = nil, nil
        pcall(function()
            local geo = canvas:GetCachedGeometry()
            if not geo then return end
            local size = nil
            if geo.GetLocalSize then size = geo:GetLocalSize()
            elseif SlateBlueprintLibrary_V1 and SlateBlueprintLibrary_V1.GetLocalSize then size = SlateBlueprintLibrary_V1.GetLocalSize(geo) end
            if size and ESPShared.Finite(size.X) and ESPShared.Finite(size.Y) and size.X > 1 and size.Y > 1 then
                cw, ch = tonumber(size.X), tonumber(size.Y)
            end
        end)
        return cw, ch
    end
    local function g_Botmater_ESPUpdateCanvasTransform(pc)
        local state=g_Botmater_ShotESP
        local canvas=g_Botmater_ESPGetCanvas()
        if not g_Botmater_ESPValid(canvas) then return false end
        local width,height=ESPShared.ViewSize(pc)
        local sameViewport=state.TransformW==width and state.TransformH==height
        local calibrated=false
        pcall(function()
            local geo=canvas:GetCachedGeometry()
            if SlateBlueprintLibrary_V1 and SlateBlueprintLibrary_V1.AbsoluteToLocal and geo then
                local p0=SlateBlueprintLibrary_V1.AbsoluteToLocal(geo,g_Botmater_ESPV2(0,0))
                local p1=SlateBlueprintLibrary_V1.AbsoluteToLocal(geo,g_Botmater_ESPV2(100,100))
                if p0 and p1 and ESPShared.Finite(p0.X) and ESPShared.Finite(p0.Y)
                    and ESPShared.Finite(p1.X) and ESPShared.Finite(p1.Y)
                    and math.abs(p0.X)<1e7 and math.abs(p0.Y)<1e7
                    and p1.X>p0.X and p1.Y>p0.Y
                    and p1.X-p0.X<10000 and p1.Y-p0.Y<10000 then
                    state.CanvasScaleX=(p1.X-p0.X)/100
                    state.CanvasScaleY=(p1.Y-p0.Y)/100
                    state.CanvasOffsetX=p0.X;state.CanvasOffsetY=p0.Y
                    calibrated=true
                end
            end
        end)
        if not calibrated and state.TransformReady and sameViewport then return true end
        if not calibrated then
            local scale=1
            pcall(function()
                if WidgetLayoutLibrary_V1 and WidgetLayoutLibrary_V1.GetViewportScale then
                    local s=WidgetLayoutLibrary_V1.GetViewportScale(pc)
                    if ESPShared.Finite(s) and s>=0.01 and s<=100 then scale=s end
                end
            end)
            state.CanvasScaleX=1/scale;state.CanvasScaleY=1/scale
            state.CanvasOffsetX=0;state.CanvasOffsetY=0
        end
        state.TransformReady=true;state.TransformW=width;state.TransformH=height
        return true
    end
    local function g_Botmater_ESPSetFont(widget,size) _G.g_vipserver_ESPSetFont(widget,size,0) end
    local function g_Botmater_ESPSetTextColor(widget,color) _G.g_vipserver_ESPSetTextColor(widget,color) end

    local function g_Botmater_ESPCreateLine(color)
        if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return nil end
        local canvas = g_Botmater_ESPGetCanvas()
        if not g_Botmater_ESPValid(canvas) then return nil end
        local pooled=true and _G.ESPWidgetPool.Take(_G.ESPWidgetPool.V1,"Line",canvas)
        if pooled then
            local ok=pcall(function() pooled.Widget:SetBrushColor(color) end)
            if ok then pooled.Visible=false;return pooled end
            V1Cleanup.Retire(pooled.Widget)
        end
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
        if not g_Botmater_ESPValid(border) then return nil end
        pcall(function()
            border:SetBrushColor(color)
            border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            border:SetRenderTransformPivot(g_Botmater_ESPV2(0.0, 0.5))
        end)
        local slot = nil
        pcall(function() slot = canvas:AddChildToCanvas(border) end)
        if not slot then g_Botmater_ESPDestroyWidgetData({Widget=border}) return nil end
        pcall(function() slot:SetAutoSize(false) slot:SetZOrder(30) end)
        local data={Widget=border, Slot=slot, Visible=true}
        return _G.ESPWidgetPool.Tag(_G.ESPWidgetPool.V1,"Line",canvas,data)
    end
    local function g_Botmater_ESPDrawLine(...) return _G.g_vipserver_ESPDrawLine(...) end
    local function g_Botmater_ESPHide(data)
        if data and g_Botmater_ESPValid(data.Widget) then
            if data.Visible ~= false then
                pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                data.Visible = false
            end
        end
    end

    local function g_Botmater_ESPCreateNameTag(isBot)
        if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return nil end
        local canvas = g_Botmater_ESPGetCanvas()
        if not g_Botmater_ESPValid(canvas) then return nil end
        local pooled=_G.ESPWidgetPool.Take(_G.ESPWidgetPool.V1,"NameV1",canvas)
        if pooled then
            local mainColor,textColor=g_Botmater_ESPGetColors(isBot)
            local ok=pcall(function()
                pooled.BottomLine:SetBrushColor(mainColor)
                pooled.BottomLine:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                pooled.HealthBg:SetBrushColor(isBot and COLOR_HP.BotBG or COLOR_HP.RealBG)
                pooled.HealthFill:SetBrushColor(mainColor)
            end)
            if not ok then V1Cleanup.Retire(pooled.Widget);pooled=nil end
            if pooled then
                g_Botmater_ESPSetTextColor(pooled.Text,textColor)
                g_Botmater_ESPSetTextColor(pooled.DistanceText,textColor)
                g_Botmater_ESPSetFont(pooled.Text,tonumber(_G.g_Botmater_VIPShotESP.NameFontSize) or 9)
                g_Botmater_ESPSetFont(pooled.DistanceText,tonumber(_G.g_Botmater_VIPShotESP.DistanceFontSize) or 10)
                pooled.IsBot=isBot;pooled.Visible=false;pooled.LastHealthPct=-1
            end
            if pooled then return pooled end
        end
        local container = nil
        pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
        if not g_Botmater_ESPValid(container) then return nil end
        local bottomLine = nil
        pcall(function() bottomLine = CGame:NewObjectFromPath("/Script/UMG.Border", container) end)
        local nameText = nil
        pcall(function() nameText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
        local distanceText = nil
        pcall(function() distanceText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
        local healthBarBg = nil
        pcall(function() healthBarBg = CGame:NewObjectFromPath("/Script/UMG.Border", container) end)
        local healthBarFill = nil
        pcall(function() healthBarFill = CGame:NewObjectFromPath("/Script/UMG.Border", container) end)
        if not g_Botmater_ESPValid(bottomLine) or not g_Botmater_ESPValid(nameText)
            or not g_Botmater_ESPValid(distanceText) or not g_Botmater_ESPValid(healthBarBg)
            or not g_Botmater_ESPValid(healthBarFill) then
            g_Botmater_ESPDestroyWidgetData({Widget=container});return nil
        end
        local mainColor,textColor=g_Botmater_ESPGetColors(isBot)
        local background=isBot and COLOR_HP.BotBG or COLOR_HP.RealBG
        pcall(function()
            bottomLine:SetBrushColor(mainColor)
            bottomLine:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            nameText:SetText("");distanceText:SetText("")
            nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            distanceText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            if nameText.SetJustification then nameText:SetJustification(1) end
            if distanceText.SetJustification then distanceText:SetJustification(1) end
            healthBarBg:SetBrushColor(background)
            healthBarBg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            healthBarFill:SetBrushColor(mainColor)
            healthBarFill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        g_Botmater_ESPSetTextColor(nameText, textColor)
        g_Botmater_ESPSetTextColor(distanceText, textColor)
        g_Botmater_ESPSetFont(nameText, tonumber(_G.g_Botmater_VIPShotESP.NameFontSize) or 9)
        g_Botmater_ESPSetFont(distanceText, tonumber(_G.g_Botmater_VIPShotESP.DistanceFontSize) or 10)
        local lineSlot, nameSlot, distanceSlot, mainSlot = nil, nil, nil, nil
        local healthBgSlot, healthFillSlot = nil, nil
        pcall(function() lineSlot = container:AddChildToCanvas(bottomLine) end)
        pcall(function() healthBgSlot = container:AddChildToCanvas(healthBarBg) end)
        pcall(function() healthFillSlot = container:AddChildToCanvas(healthBarFill) end)
        pcall(function() nameSlot = container:AddChildToCanvas(nameText) end)
        pcall(function() distanceSlot = container:AddChildToCanvas(distanceText) end)
        pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
        if not lineSlot or not nameSlot or not distanceSlot or not mainSlot or not healthBgSlot or not healthFillSlot then
            g_Botmater_ESPDestroyWidgetData({Widget=container});return nil
        end
        pcall(function()
            lineSlot:SetAutoSize(false) lineSlot:SetAlignment(g_Botmater_ESPV2(0.0, 0.0)) lineSlot:SetZOrder(1)
            healthBgSlot:SetAutoSize(false) healthBgSlot:SetAlignment(g_Botmater_ESPV2(0.0, 0.0)) healthBgSlot:SetZOrder(1)
            healthFillSlot:SetAutoSize(false) healthFillSlot:SetAlignment(g_Botmater_ESPV2(0.0, 0.0)) healthFillSlot:SetZOrder(2)
            nameSlot:SetAutoSize(true) nameSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5)) nameSlot:SetZOrder(3)
            distanceSlot:SetAutoSize(true) distanceSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5)) distanceSlot:SetZOrder(3)
            mainSlot:SetAutoSize(false) mainSlot:SetZOrder(35)
        end)
        local data={
            Widget=container, BottomLine=bottomLine, HealthBg=healthBarBg, HealthFill=healthBarFill,
            Text=nameText, DistanceText=distanceText,
            LineSlot=lineSlot, HealthBgSlot=healthBgSlot, HealthFillSlot=healthFillSlot,
            TextSlot=nameSlot, DistanceSlot=distanceSlot, Slot=mainSlot,
            IsBot=isBot, Visible=true, LastDistValue=nil, LastDistLabel=nil, LastHealthPct=-1,
        }
        return _G.ESPWidgetPool.Tag(_G.ESPWidgetPool.V1,"NameV1",canvas,data)
    end

    local function g_Botmater_ESPUpdateNameTag(key, character, headScreen, footScreen, isBot, distance, healthPct, pc)
        local showName     = _G.g_Botmater_ESPOptions.Name == true
        local showDistance = _G.g_Botmater_ESPOptions.Distance == true
        local showHealth   = _G.g_Botmater_ESPOptions.Health == true
        local data = g_Botmater_ShotESP.Names[key]
        if not showName and not showDistance and not showHealth then
            if data and g_Botmater_ESPValid(data.Widget) then
                if data.Visible ~= false then
                    pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                    data.Visible = false
                end
            end
            return
        end
        if data and data.IsBot~=isBot then data.CachedName=nil end
        local name = nil
        if not showName then name=""
        elseif isBot then name = "BOT"
        else
            name = data and data.CachedName or nil
            if not name then
                name = g_Botmater_ESPResolvePlayerName(character)
                if data and name then data.CachedName = name end
            end
            if not name then name = showName and "UNKNOWN" or "" end
        end
        headScreen=headScreen or footScreen
        if not headScreen then
            if data and g_Botmater_ESPValid(data.Widget) then
                if data.Visible ~= false then
                    pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                    data.Visible = false
                end
            end
            return
        end
        if not data or not g_Botmater_ESPValid(data.Widget) then
            g_Botmater_ESPDestroyWidgetData(data)
            data = g_Botmater_ESPCreateNameTag(isBot)
            g_Botmater_ShotESP.Names[key] = data
            if data then data.CachedName = name end
        end
        if not data then return end
        if data.IsBot ~= isBot then
            local mainColor,textColor=g_Botmater_ESPGetColors(isBot)
            g_Botmater_ESPSetTextColor(data.Text,textColor)
            g_Botmater_ESPSetTextColor(data.DistanceText,textColor)
            local ok=pcall(function()
                data.BottomLine:SetBrushColor(mainColor)
                data.HealthBg:SetBrushColor(isBot and COLOR_HP.BotBG or COLOR_HP.RealBG)
            end)
            if ok then data.IsBot=isBot;data.LastHealthPct=nil end
        end
        local dist=math.floor(ESPShared.SafeNumber(distance,0,0,1e8)+0.5)
        local distanceLabel
        if data.LastDistValue ~= dist then
            distanceLabel = string.format("%d m", dist)
            data.LastDistValue = dist
            data.LastDistLabel = distanceLabel
        else
            distanceLabel = data.LastDistLabel or string.format("%d m", dist)
        end
        local hp=ESPShared.SafeNumber(healthPct,1.0,0.0,1.0)
        if hp<0 then hp=0 end
        if hp>1 then hp=1 end
        local healthChanged=data.LastHealthPct~=hp
        if healthChanged then
            local hpColor = g_Botmater_ESPGetHealthColor(hp,isBot)
            pcall(function()
                if data.HealthFill and g_Botmater_ESPValid(data.HealthFill) then
                    data.HealthFill:SetBrushColor(hpColor)
                end
            end)
        end
        local bottomLineH = 4.32
        local baseFontSize=ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.NameFontSize,12,1,96)
        local baseBottomLineH = 3.6
        local fontSize = baseFontSize * (bottomLineH / baseBottomLineH)
        local paddingX = 5.0
        local paddingY = 2.0
        local nameHeight = fontSize + paddingY * 2 + bottomLineH
        local gap=ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.NameGap,2,0,128)
        local nameChars = #name
        local textWidth = math.max(30.0, nameChars * (fontSize * 0.52))
        local boxWidth = math.max(50.0, textWidth + paddingX * 2)
        local boxHeight = nameHeight
        local LINE_UP_SHIFT = boxHeight * 0.25
        local baseY = headScreen.Y - boxHeight - gap
        local containerY = baseY - LINE_UP_SHIFT
        local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,g_Botmater_ShotESP)
        boxWidth=math.min(boxWidth,math.max(1,maxX-minX-4))
        local x=ESPShared.SafeNumber(headScreen.X-boxWidth*0.5,minX,minX,maxX-boxWidth)
        containerY=ESPShared.SafeNumber(containerY,minY,minY,math.max(minY,maxY-boxHeight))
        local anchor=footScreen or headScreen
        local df=ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.DistanceFontSize,12,1,96)
        local halfW=math.min(math.max(18,#distanceLabel*df*0.30),(maxX-minX)*0.49)
        local halfH=math.min(df*0.7+2,(maxY-minY)*0.49)
        local distAbsX=ESPShared.SafeNumber(anchor.X,headScreen.X,minX+halfW,maxX-halfW)
        local distAbsY=ESPShared.SafeNumber(anchor.Y+ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.DistanceBelowFeet,14,0,128),minY+halfH,minY+halfH,maxY-halfH)
        containerY=math.min(containerY,distAbsY-halfH)
        local distanceY=distAbsY-containerY
        local totalHeight=math.max(boxHeight,distanceY+halfH)
        local needsPosUpdate = true
        if data.LastBoxX and math.abs(x-data.LastBoxX)<0.001 and math.abs(containerY-data.LastBoxY)<0.001
            and data.LastBoxW==boxWidth and data.LastDistanceY==distanceY then
            needsPosUpdate = false
        end
        local shownName     = showName and name or ""
        local shownDistance = showDistance and distanceLabel or ""
        pcall(function()
            if data.LastName ~= shownName then data.Text:SetText(shownName);data.LastName=shownName end
            if data.LastDistance ~= shownDistance then data.DistanceText:SetText(shownDistance);data.LastDistance=shownDistance end
        end)
        local lineWidth=boxWidth*0.68
        local lineOffsetX=(boxWidth-lineWidth)*0.5
        local healthWidth=lineWidth*hp
        if healthWidth<1 then healthWidth=0 end
        local geometryChanged=data.GeometryWidth~=boxWidth or data.GeometryHeight~=boxHeight
        if geometryChanged or healthChanged then
            local ok=pcall(function()
                if geometryChanged then
                    data.HealthBgSlot:SetPosition(g_Botmater_ESPV2(lineOffsetX,boxHeight-bottomLineH))
                    data.HealthBgSlot:SetSize(g_Botmater_ESPV2(lineWidth,bottomLineH))
                    data.HealthFillSlot:SetPosition(g_Botmater_ESPV2(lineOffsetX,boxHeight-bottomLineH))
                    data.TextSlot:SetPosition(g_Botmater_ESPV2(boxWidth*0.5,(boxHeight-bottomLineH)*0.5))
                end
                data.HealthFillSlot:SetSize(g_Botmater_ESPV2(healthWidth,bottomLineH))
            end)
            if ok then data.GeometryWidth=boxWidth;data.GeometryHeight=boxHeight;data.LastHealthPct=hp end
        end
        if needsPosUpdate then
            local ok=pcall(function() data.Slot:SetPosition(g_Botmater_ESPV2(x,containerY)) end)
            if ok then data.LastBoxX=x;data.LastBoxY=containerY;data.LastBoxW=boxWidth end
        end
        if data.LayoutW~=boxWidth or data.LayoutH~=totalHeight then
            local ok=pcall(function() data.Slot:SetSize(g_Botmater_ESPV2(boxWidth,totalHeight)) end)
            if ok then data.LayoutW=boxWidth;data.LayoutH=totalHeight end
        end
        local distX=distAbsX-x
        if data.LastDistanceX~=distX or data.LastDistanceY~=distanceY then
            local ok=pcall(function() data.DistanceSlot:SetPosition(g_Botmater_ESPV2(distX,distanceY)) end)
            if ok then data.LastDistanceX=distX;data.LastDistanceY=distanceY end
        end
        if data.LastHealthVis~=showHealth then
            local ok=pcall(function()
                local vis=showHealth and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed
                data.HealthBg:SetWidgetVisibility(vis);data.HealthFill:SetWidgetVisibility(vis)
            end)
            if ok then data.LastHealthVis=showHealth end
        end
        if data.LastNameVis ~= showName then
            local ok=pcall(function() data.Text:SetWidgetVisibility(showName and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed) end)
            if ok then data.LastNameVis=showName end
        end
        if data.LastDistVis ~= showDistance then
            local ok=pcall(function() data.DistanceText:SetWidgetVisibility(showDistance and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed) end)
            if ok then data.LastDistVis=showDistance end
        end
        if data.Visible ~= true then
            local ok=pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            if ok then data.Visible=true end
        end
        data.FinalX=x; data.FinalY=containerY; data.FinalW=boxWidth; data.FinalH=boxHeight
        data.LineEndX = x + boxWidth * 0.5
        data.LineEndY = containerY + (boxHeight - bottomLineH)
    end

    local function g_Botmater_ESPScanEnemies()
        local pc = g_Botmater_ESPGetController()
        local me = g_Botmater_ESPGetLocalCharacter()
        if not pc or not me then
            g_Botmater_ShotESP.Enemies = {}
            g_Botmater_ShotESP.RealCount = 0
            g_Botmater_ShotESP.BotCount = 0
            return nil
        end
        local myLoc = ESPShared.GetFrameRecord(me).Location
        if not myLoc then
            g_Botmater_ShotESP.Enemies = {}
            g_Botmater_ShotESP.RealCount = 0
            g_Botmater_ShotESP.BotCount = 0
            return pc
        end
        local myTeam = g_Botmater_ESPGetTeamID(me)
        local list = {}
        local realCount = 0
        local botCount = 0
        local pawns=ESPShared.GetFramePawns()
        if not pawns then return pc end
        for _, character in pairs(pawns) do
            if character~=me and ESPShared.GetFrameRecord(character).Alive and ESPShared.Events.Counted(character) then
                local team = g_Botmater_ESPGetTeamID(character)
                if myTeam == nil or team == nil or tostring(team) ~= tostring(myTeam) then
                    local dist = ESPShared.DistanceMetersFrom(ESPShared.GetFrameRecord(character),myLoc)
                    if dist <= (tonumber(_G.g_Botmater_VIPShotESP.MaxRangeMeters) or 300.0) then
                        local isBot = g_Botmater_ESPIsBot(character)
                        local k = g_Botmater_ESPGetPlayerKey(character)
                        if k then
                            list[#list+1] = {Character=character, Key=k, IsBot=isBot, Distance=dist}
                            if isBot then botCount = botCount + 1 else realCount = realCount + 1 end
                        end
                    end
                end
            end
        end
        local maxRendered = math.floor(ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.MaxRendered,10,1,64))
        if #list > maxRendered then
            table.sort(list,function(a,b)
                if a.Distance==b.Distance then return a.Key<b.Key end
                return a.Distance<b.Distance
            end)
        end
        g_Botmater_ShotESP.Enemies = list
        g_Botmater_ShotESP.RealCount = realCount
        g_Botmater_ShotESP.BotCount = botCount
        return pc
    end

    local function g_Botmater_ESPPrune(active,alive)
        alive=alive or active
        for _,registry in ipairs({g_Botmater_ShotESP.Lines,g_Botmater_ShotESP.Names}) do
            for key,data in pairs(registry) do
                if not active[key] and g_Botmater_ESPDestroyWidgetData(data) then registry[key]=nil end
            end
        end
        for key in pairs(g_Botmater_ShotESP._BotCache or {}) do if not alive[key] then g_Botmater_ShotESP._BotCache[key]=nil end end
        for key in pairs(g_Botmater_ShotESP.LastProjected) do if not alive[key] then g_Botmater_ShotESP.LastProjected[key]=nil end end
    end

    ESPShared.Events.Clearers[#ESPShared.Events.Clearers+1]=function(actor)
        ESPShared.Events.ClearIn(g_Botmater_ShotESP,g_Botmater_ESPPrune,actor)
    end

    local g_Botmater_EnemyCounter = {
        Container = nil, Slot = nil, PlayerBG = nil, BotBG = nil, PlayerText = nil, BotText = nil,
        Width = 218.4, Height = 33.6, OffsetY = 22.5, FontSize = 13, FontScale = 1.2,
        _LastPlayers = -1, _LastBots = -1, _PosVec = nil, _LastPosX = nil, _LastPosY = nil,
        CanvasCenterX = 0.0, CanvasCenterY = 0.0,
    }
    local function g_Botmater_CounterTextColor(widget,color) _G.g_vipserver_ESPSetTextColor(widget,color) end
    local function g_Botmater_CounterCreate()
        if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return false end
        if g_Botmater_EnemyCounter.Container and slua.isValid(g_Botmater_EnemyCounter.Container) then return true end
        local canvas = g_Botmater_ESPGetCanvas()
        if not canvas or not g_Botmater_ESPValid(canvas) then return false end
        local W, H = g_Botmater_EnemyCounter.Width, g_Botmater_EnemyCounter.Height
        local halfW = W * 0.5
        local Container, PlayerBG, BotBG, PlayerText, BotText = nil, nil, nil, nil, nil
        pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
        if not Container or not slua.isValid(Container) then return false end
        pcall(function() PlayerBG = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        pcall(function() BotBG = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        pcall(function() PlayerText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
        pcall(function() BotText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
        if not PlayerBG or not BotBG or not PlayerText or not BotText
            or not slua.isValid(PlayerBG) or not slua.isValid(BotBG)
            or not slua.isValid(PlayerText) or not slua.isValid(BotText) then
            V1Cleanup.Retire(Container);return false
        end
        pcall(function()
            PlayerBG:SetBrushColor(CACHE_COUNTER_PLAYER_BG)
            PlayerBG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            BotBG:SetBrushColor(CACHE_COUNTER_BOT_BG)
            BotBG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local pbgSlot, bbgSlot = nil, nil
        pcall(function() pbgSlot = Container:AddChildToCanvas(PlayerBG) end)
        pcall(function() bbgSlot = Container:AddChildToCanvas(BotBG) end)
        if not pbgSlot or not bbgSlot then V1Cleanup.Retire(Container);return false end
        pcall(function()
            pbgSlot:SetAutoSize(false) pbgSlot:SetPosition(g_Botmater_ESPV2(0, 0)) pbgSlot:SetSize(g_Botmater_ESPV2(halfW, H)) pbgSlot:SetZOrder(0)
            bbgSlot:SetAutoSize(false) bbgSlot:SetPosition(g_Botmater_ESPV2(halfW, 0)) bbgSlot:SetSize(g_Botmater_ESPV2(halfW, H)) bbgSlot:SetZOrder(0)
        end)
        pcall(function()
            PlayerText:SetText("REAL: 0")
            BotText:SetText("BOT: 0")
            _G.g_vipserver_ESPSetFont(PlayerText,g_Botmater_EnemyCounter.FontSize,0)
            _G.g_vipserver_ESPSetFont(BotText,g_Botmater_EnemyCounter.FontSize,0)
            local scale=g_Botmater_EnemyCounter.FontScale
            PlayerText:SetRenderTransformPivot(g_Botmater_ESPV2(0.5,0.5))
            BotText:SetRenderTransformPivot(g_Botmater_ESPV2(0.5,0.5))
            PlayerText:SetRenderScale(g_Botmater_ESPV2(scale,scale))
            BotText:SetRenderScale(g_Botmater_ESPV2(scale,scale))
            PlayerText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            BotText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        g_Botmater_CounterTextColor(PlayerText, CACHE_COUNTER_PLAYER_TEXT)
        g_Botmater_CounterTextColor(BotText, CACHE_COUNTER_BOT_TEXT)
        local ptSlot, btSlot = nil, nil
        pcall(function() ptSlot = Container:AddChildToCanvas(PlayerText) end)
        pcall(function() btSlot = Container:AddChildToCanvas(BotText) end)
        if ptSlot then pcall(function()
            ptSlot:SetAutoSize(true) ptSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5))
            ptSlot:SetPosition(g_Botmater_ESPV2(halfW * 0.5, H * 0.5)) ptSlot:SetZOrder(2)
        end) end
        if btSlot then pcall(function()
            btSlot:SetAutoSize(true) btSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5))
            btSlot:SetPosition(g_Botmater_ESPV2(halfW + halfW * 0.5, H * 0.5)) btSlot:SetZOrder(2)
        end) end
        local mainSlot = nil
        pcall(function() mainSlot = canvas:AddChildToCanvas(Container) end)
        if not mainSlot then V1Cleanup.Retire(Container);return false end
        pcall(function() mainSlot:SetAutoSize(false) mainSlot:SetSize(g_Botmater_ESPV2(W, H)) mainSlot:SetZOrder(50) end)
        g_Botmater_EnemyCounter.Container = Container
        g_Botmater_EnemyCounter.Slot = mainSlot
        g_Botmater_EnemyCounter.PlayerBG = PlayerBG
        g_Botmater_EnemyCounter.BotBG = BotBG
        g_Botmater_EnemyCounter.PlayerText = PlayerText
        g_Botmater_EnemyCounter.BotText = BotText
        g_Botmater_EnemyCounter._LastPlayers = -1
        g_Botmater_EnemyCounter._LastBots = -1
        pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        return true
    end
    local function g_Botmater_CounterUpdatePosition(pc)
        local slot = g_Botmater_EnemyCounter.Slot
        if not slot or not slua.isValid(slot) then return end
        if not pc or not g_Botmater_ESPValid(pc) then return end
        local canvasW, canvasH = g_Botmater_ESPGetCanvasLocalSize()
        if not canvasW or not canvasH then
            local vw, vh = g_Botmater_ESPViewport(pc)
            if not vw or vw <= 200 then return end
            local sx = g_Botmater_ShotESP.CanvasScaleX or 1.0
            local sy = g_Botmater_ShotESP.CanvasScaleY or 1.0
            local ox = g_Botmater_ShotESP.CanvasOffsetX or 0.0
            local oy = g_Botmater_ShotESP.CanvasOffsetY or 0.0
            canvasW = (vw * sx) - ox; canvasH = (vh * sy) - oy
        end
        if not canvasW or not canvasH then return end
        local canvasCenterX = canvasW * 0.5
        local canvasCenterY = g_Botmater_EnemyCounter.OffsetY
        local x = canvasCenterX - g_Botmater_EnemyCounter.Width * 0.5
        local y = canvasCenterY
        g_Botmater_EnemyCounter.CanvasCenterX = canvasCenterX
        g_Botmater_EnemyCounter.CanvasCenterY = canvasCenterY + g_Botmater_EnemyCounter.Height * 0.5
        local lx, ly = g_Botmater_EnemyCounter._LastPosX, g_Botmater_EnemyCounter._LastPosY
        if lx ~= nil and ly ~= nil and math.abs(lx - x) < 0.1 and math.abs(ly - y) < 0.1 then return end
        g_Botmater_EnemyCounter._PosVec = g_Botmater_ESPV2(x, y)
        local ok = pcall(function() slot:SetPosition(g_Botmater_EnemyCounter._PosVec) end)
        if ok then g_Botmater_EnemyCounter._LastPosX = x; g_Botmater_EnemyCounter._LastPosY = y end
    end
    local function g_Botmater_GetLineOrigin(pc)
        if _G.g_Botmater_ESPOptions.EnemyCounter then
            g_Botmater_CounterUpdatePosition(pc)
            return g_Botmater_ESPV2(g_Botmater_EnemyCounter.CanvasCenterX,g_Botmater_EnemyCounter.CanvasCenterY+g_Botmater_EnemyCounter.Height*0.5)
        end
        local width=g_Botmater_ESPGetCanvasLocalSize()
        if not width then
            local vw=g_Botmater_ESPViewport(pc)
            width=(vw or 2400)*g_Botmater_ShotESP.CanvasScaleX+g_Botmater_ShotESP.CanvasOffsetX
        end
        local top=g_Botmater_EnemyCounter.OffsetY
        return g_Botmater_ESPV2(width*0.5,top+g_Botmater_EnemyCounter.Height)
    end
    local function g_Botmater_CounterSetCounts(realCount, botCount)
        realCount = tonumber(realCount) or 0
        botCount = tonumber(botCount) or 0
        if g_Botmater_EnemyCounter._LastPlayers ~= realCount and g_Botmater_EnemyCounter.PlayerText and slua.isValid(g_Botmater_EnemyCounter.PlayerText) then
            local ok = pcall(function() return g_Botmater_EnemyCounter.PlayerText:SetText(string.format("REAL: %d", realCount)) ~= false end)
            if ok then g_Botmater_EnemyCounter._LastPlayers = realCount end
        end
        if g_Botmater_EnemyCounter._LastBots ~= botCount and g_Botmater_EnemyCounter.BotText and slua.isValid(g_Botmater_EnemyCounter.BotText) then
            local ok = pcall(function() return g_Botmater_EnemyCounter.BotText:SetText(string.format("BOT: %d", botCount)) ~= false end)
            if ok then g_Botmater_EnemyCounter._LastBots = botCount end
        end
    end
    local function g_Botmater_CounterStart(pc)
        if not g_Botmater_CounterCreate() then return end
        pcall(function() g_Botmater_EnemyCounter.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        g_Botmater_CounterUpdatePosition(pc)
    end
    local function g_Botmater_CounterStop()
        local container = g_Botmater_EnemyCounter.Container
        g_Botmater_EnemyCounter.Container = nil
        g_Botmater_EnemyCounter.Slot = nil
        g_Botmater_EnemyCounter.PlayerBG = nil
        g_Botmater_EnemyCounter.BotBG = nil
        g_Botmater_EnemyCounter.PlayerText = nil
        g_Botmater_EnemyCounter.BotText = nil
        g_Botmater_EnemyCounter._LastPlayers = -1
        g_Botmater_EnemyCounter._LastBots = -1
        g_Botmater_EnemyCounter._PosVec = nil
        g_Botmater_EnemyCounter._LastPosX = nil
        g_Botmater_EnemyCounter._LastPosY = nil
        g_Botmater_EnemyCounter.CanvasCenterX = 0.0
        g_Botmater_EnemyCounter.CanvasCenterY = 0.0
        if g_Botmater_ESPValid(container) then V1Cleanup.Retire(container) end
    end

    local _V1VisCache = setmetatable({}, {__mode = "k"})
    local function g_Botmater_ESPRenderActor(item,pc,opt,origin,now)
        local state=g_Botmater_ShotESP
        local c,key,isBot=item.Character,item.Key,item.IsBot
        local head,feet,onScreen,reason=ESPShared.Events.Project(pc,c,state)
        if not onScreen then
            local last=state.LastProjected[key]
            if reason=="unavailable" and last and now>=last and now-last<=0.08 then
                state.Active[key]=true
            else
                state.LastProjected[key]=nil
            end
            return
        end
        local anchor=head or feet
        if not anchor then return end
        state.Active[key]=true;state.LastProjected[key]=now
        local isVisible = true
        if not isBot then
            local curTime = os.clock()
            local cached = _V1VisCache[c]
            if not cached or (curTime - cached.time) > 0.2 then
                local hidden = true
                pcall(function()
                    if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                        if pc:LineOfSightTo(c) then hidden = false end
                    else hidden = false end
                end)
                _V1VisCache[c] = { hidden = hidden, time = curTime }
                cached = _V1VisCache[c]
            end
            isVisible = not cached.hidden
        end
        local color
        if isBot then color = COLOR_BOT_VIS_CYAN
        else
            if isVisible then color = g_Botmater_ESPColor(0.0, 1.0, 0.0, 1.0)
            else color = g_Botmater_ESPColor(1.0, 0.0, 0.0, 1.0) end
        end
        local hp=opt.Health and g_Botmater_ESPGetHealthPct(c) or 1
        g_Botmater_ESPUpdateNameTag(key,c,anchor,feet,isBot,item.Distance,hp,pc)
        local line=state.Lines[key]
        if opt.Line and (not line or line.Broken or not g_Botmater_ESPValid(line.Widget) or not g_Botmater_ESPValid(line.Slot)) then
            if not g_Botmater_ESPDestroyWidgetData(line) then return end
            line=g_Botmater_ESPCreateLine(color);state.Lines[key]=line
        end
        if opt.Line and line then
            local colorKey = isBot and "B" or (isVisible and "G" or "R")
            if line.ColorKey~=colorKey then
                local ok=pcall(function() line.Widget:SetBrushColor(color) end)
                if ok then line.ColorKey=colorKey end
            end
            local tag=state.Names[key]
            local x,y=tag and tag.LineEndX or anchor.X,tag and tag.LineEndY or anchor.Y
            g_Botmater_ESPDrawLine(line,origin.X,origin.Y,x,y,ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.TracerThickness,1,0.1,12))
        elseif line then g_Botmater_ESPHide(line) end
    end
    local function g_Botmater_ESPDrawCandidates(pc,opt,now)
        local state=g_Botmater_ShotESP
        local origin=g_Botmater_GetLineOrigin(pc)
        local limit=math.floor(ESPShared.SafeNumber(_G.g_Botmater_VIPShotESP.MaxRendered,10,1,64))
        for i,item in ipairs(state.Enemies) do
            if i>limit then break end
            local ok,err=pcall(g_Botmater_ESPRenderActor,item,pc,opt,origin,now)
            if not ok then
                state.Active[item.Key]=nil;state.LastProjected[item.Key]=nil
                local f=_G.LunarFeatures
                if f and f.Error then f.Error("V1.Actor",err) end
            end
        end
    end

    local function g_Botmater_ESPUpdate()
        local state=g_Botmater_ShotESP
        local opt=_G.g_Botmater_ESPOptions
        local details=opt and (opt.Name or opt.Line or opt.Health or opt.Distance)
        local counter=opt and opt.EnemyCounter
        local now=g_Botmater_ESPNow()
        V1Cleanup.Pump(now)
        if not _G.g_Botmater_VIPShotESP.Enabled or (not details and not counter) then
            g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();return
        end
        local world=g_Botmater_ESPWorld()
        ESPShared.Events.WorldChanged(world)
        if world~=state.LastWorld then
            g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();state.LastWorld=world
        end
        local oldCanvas=state.Canvas
        local canvas=g_Botmater_ESPGetCanvas()
        if canvas~=oldCanvas then g_Botmater_CounterStop() end
        if not canvas then return end
        local pc=g_Botmater_ESPGetController()
        if now<state.LastScanClock or now-state.LastScanClock>=(tonumber(_G.g_Botmater_VIPShotESP.ScanInterval) or 0.05) then
            pc=g_Botmater_ESPScanEnemies() or pc;state.LastScanClock=now
        end
        pc=pc or g_Botmater_ESPGetController()
        if not pc then g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();return end
        local location=ESPShared.GetFrameRecord(g_Botmater_ESPGetLocalCharacter()).Location
        local active,alive=state.Active,state.Alive
        state.RealCount,state.BotCount=_G.g_vipserver_ESPFilterEnemies(state.Enemies,location,_G.g_Botmater_VIPShotESP.MaxRangeMeters,alive)
        g_Botmater_ESPPrune(alive,alive)
        for k in pairs(active) do active[k]=nil end
        if now<state.LastTransformClock or now-state.LastTransformClock>=(tonumber(_G.g_Botmater_VIPShotESP.TransformInterval) or 0.033) then
            g_Botmater_ESPUpdateCanvasTransform(pc);state.LastTransformClock=now
        end
        if counter then
            pcall(g_Botmater_CounterStart,pc)
            pcall(g_Botmater_CounterSetCounts,state.RealCount,state.BotCount)
        else g_Botmater_CounterStop() end
        local ok,err=true,nil
        if details then ok,err=pcall(g_Botmater_ESPDrawCandidates,pc,opt,now) end
        g_Botmater_ESPPrune(active,alive)
        if not ok then
            local f=_G.LunarFeatures
            if f and f.Error then f.Error("V1.Draw",err) end
        end
    end

    local Fv = _G.LunarFeatures
    Fv.V1={State=g_Botmater_ShotESP,Counter=g_Botmater_EnemyCounter,Tick=g_Botmater_ESPUpdate,
        Cleanup=V1Cleanup,
        Reset=function() g_Botmater_ESPResetWidgets();g_Botmater_CounterStop() end,
        Refresh=function() g_Botmater_ShotESP.LastScanClock=-999;g_Botmater_ShotESP.LastTransformClock=-999 end}

    _G.LunarESP_V1_Tick = function()
        if not _G.g_Botmater_ESPOptions then return end
        local now = LF.Now()
        ESPShared.Frame.Begin(now)
        local ok,err = pcall(function()
            local FF = _G.LunarFeatures
            if FF and FF.V1 and FF.V1.Tick then FF.V1.Tick() end
        end)
        ESPShared.Frame.Finish()
        if not ok then print("[V1 Tick Error]", tostring(err)) end
    end

    _G.LunarESP_V1_Reset = function()
        local FF = _G.LunarFeatures
        if FF and FF.V1 and FF.V1.Reset then pcall(FF.V1.Reset) end
    end

    _G.ESP_V1_EnableAll = function()
        if not _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions = {} end
        _G.g_Botmater_ESPOptions.Name = true
        _G.g_Botmater_ESPOptions.Line = true
        _G.g_Botmater_ESPOptions.Health = true
        _G.g_Botmater_ESPOptions.Distance = true
        _G.g_Botmater_ESPOptions.EnemyCounter = true
    end
    _G.ESP_V1_DisableAll = function()
        if not _G.g_Botmater_ESPOptions then return end
        _G.g_Botmater_ESPOptions.Name = false
        _G.g_Botmater_ESPOptions.Line = false
        _G.g_Botmater_ESPOptions.Health = false
        _G.g_Botmater_ESPOptions.Distance = false
        _G.g_Botmater_ESPOptions.EnemyCounter = false
    end
    _G.ESP_V1_Toggle = function(key)
        if not _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions = {} end
        _G.g_Botmater_ESPOptions[key] = not _G.g_Botmater_ESPOptions[key]
    end

    if not _G.g_Botmater_ESPOptions._AutoInit then
        _G.g_Botmater_ESPOptions._AutoInit = true
    end

    print("[ESP V1] Botmater module installed")
end

-- ============================================================
-- SECTION 4 — Orchestration
-- ============================================================
function _G.NewFreshRuntimeTick()
    _G.Mod_ESP_Enabled = _G.Mod_ESP_ShowSnapline or false

    if _G.PlayerMapMarker then
        -- ── MATCH TRANSITION DETECTOR ──
        pcall(function()
            local PC = _G.PlayerMapMarker.GetMyPlayerController()
            local GDP = _G.PlayerMapMarker.GetGameplayData()
            local MyChar = GDP and GDP.GetLocalCharacter and GDP.GetLocalCharacter() or nil
            if not MyChar and PC and PC.GetPawn then MyChar = PC:GetPawn() end

            local prevPawn = _G.PlayerMapMarker._LastPawnForMatch
            local prevCanvas = _G.PlayerMapMarker.ESPCanvas

            local canvasDead = (prevCanvas ~= nil and not Game:IsValid(prevCanvas))
            local pawnChanged = (prevPawn ~= nil and MyChar ~= nil and prevPawn ~= MyChar)

            if canvasDead or pawnChanged or (prevPawn ~= nil and MyChar == nil) then
                pcall(function()
                    if _G.PlayerMapMarker.bActive then
                        pcall(_G.PlayerMapMarker.Stop)
                    end
                end)
                _G.PlayerMapMarker.bActive = false
                _G.PlayerMapMarker._timersAttached = false
                _G.PlayerMapMarker._timersPC = nil
                _G.PlayerMapMarker._OBHeadWidgetLoadFailed = false
                _G.PlayerMapMarker._OBHeadWidgetClass = nil
                _G.PlayerMapMarker._CachedPC = nil
                _G.PlayerMapMarker._CachedCGameState = nil
                _G.PlayerMapMarker._CachedTopCenterPixel = nil
                _G.PlayerMapMarker.ESPCanvas = nil
            end

            if MyChar ~= nil then
                _G.PlayerMapMarker._LastPawnForMatch = MyChar
            end
        end)

        _G.PlayerMapMarker.bUseSnapLines = _G.Mod_ESP_ShowSnapline or false
        _G.PlayerMapMarker.bShowDistance = false

        if _G.Mod_ESP_Enabled then
            if not _G.PlayerMapMarker.bActive then pcall(_G.PlayerMapMarker.Start) end
        elseif _G.PlayerMapMarker.bActive then
            pcall(_G.PlayerMapMarker.Stop)
        end
    end

    -- ── V1 engine: reset on match change too ──
    pcall(function()
        if _G.LunarESP_V1_Reset and _G.PlayerMapMarker then
            local PC = _G.PlayerMapMarker.GetMyPlayerController()
            local GDP = _G.PlayerMapMarker.GetGameplayData()
            local MyChar = GDP and GDP.GetLocalCharacter and GDP.GetLocalCharacter() or nil
            if not MyChar and PC and PC.GetPawn then MyChar = PC:GetPawn() end
            local prevV1Pawn = _G._V1LastPawnForMatch
            if prevV1Pawn ~= nil and MyChar ~= nil and prevV1Pawn ~= MyChar then
                pcall(_G.LunarESP_V1_Reset)
            end
            if MyChar ~= nil then
                _G._V1LastPawnForMatch = MyChar
            end
        end
    end)
end

local function MainUpdate()
    pcall(_G.NewFreshRuntimeTick)
end


-- ============================================================
-- SECTION 4.5 — FastTick for ESP V1 (PAKxTEAM) — 100 fps
-- ============================================================
local function GrwFastTick()
    if _G.LunarESP_V1_Tick then
        pcall(_G.LunarESP_V1_Tick)
    end
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.01, GrwFastTick)
    end
end
GrwFastTick()


-- ============================================================
-- SECTION 5 — Watchdog
-- ============================================================
pcall(function()
    if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end

    local function StartESP_Watchdog(targetActor)
        if not isValid(targetActor) then return end
        _G._ESPTimerChar = targetActor
        _G._ESPTimerHandle = targetActor:AddGameTimer(0.2, true, function()
            pcall(MainUpdate)
        end)
    end

    local function Watchdog()
        pcall(function()
            -- dead timer char clear
            if _G._ESPTimerChar and not isValid(_G._ESPTimerChar) then
                _G._ESPTimerHandle = nil
                _G._ESPTimerChar = nil
            end

            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and (pc.GetPawn and pc:GetPawn() or (pc.GetCurPawn and pc:GetCurPawn()))
            if isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
                if _G._ESPTimerHandle and isValid(_G._ESPTimerChar) then
                    pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                end
                _G._ESPTimerHandle = nil
                StartESP_Watchdog(curPawn)
            elseif not _G._ESPTimerHandle then
                StartESP_Watchdog(curPawn)
            end
        end)
    end

    _G._ESPWatchdogHandle = Game:SetTimer(1.0, true, Watchdog)
    Watchdog()
end)


-- ============================================================
-- SECTION 6 — Single Menu (Snaplines + PAKxTEAM ESP)
-- ============================================================
do
    local IsValid = function(obj) return obj and slua and slua.isValid and slua.isValid(obj) end
    local FLinearColor = import("LinearColor")
    local FVector2D = import("Vector2D")
    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")

    local C = {
        bg_panel        = FLinearColor(0.96, 0.96, 0.96, 0.75),
        bg_header       = FLinearColor(0.88, 0.88, 0.88, 0.80),
        bg_row          = FLinearColor(0.85, 0.85, 0.85, 0.55),
        bg_row_alt      = FLinearColor(0.78, 0.78, 0.78, 0.50),
        bg_slider_row   = FLinearColor(0.75, 0.85, 1.0, 0.55),
        bg_section      = FLinearColor(0.70, 0.80, 1.0, 0.35),
        text_black      = FLinearColor(0.0, 0.0, 0.0, 1.0),
        text_blue       = FLinearColor(0.0, 0.35, 0.85, 1.0),
        text_light      = FLinearColor(1.0, 1.0, 1.0, 1.0),
        toggle_on       = FLinearColor(0.20, 0.85, 0.30, 1.0),
        toggle_off      = FLinearColor(0.60, 0.60, 0.60, 1.0),
        toggle_knob     = FLinearColor(1.0, 1.0, 1.0, 1.0),
        close_btn       = FLinearColor(0.9, 0.2, 0.2, 1.0),
        transparent     = FLinearColor(0, 0, 0, 0.01),
        border_blue     = FLinearColor(0.0, 0.35, 0.85, 0.6),
        btn_minus       = FLinearColor(0.9, 0.3, 0.3, 1.0),
        btn_plus        = FLinearColor(0.2, 0.8, 0.3, 1.0),
    }

    local M_W = 520
    local M_H = 590
    local ROW_H = 44
    local SLIDER_ROW_H = 50
    local HEADER_H = 70
    local SECTION_H = 32

    -- ===== SNAPLINE COLOR PRESETS (PAKxTEAM) =====
    local SNAPLINE_COLORS = {
        {name = "Yellow",  r = 1.00, g = 0.85, b = 0.00},
        {name = "Red",     r = 1.00, g = 0.10, b = 0.10},
        {name = "Green",   r = 0.10, g = 1.00, b = 0.20},
        {name = "Cyan",    r = 0.00, g = 1.00, b = 1.00},
        {name = "Blue",    r = 0.20, g = 0.40, b = 1.00},
        {name = "Purple",  r = 0.70, g = 0.20, b = 1.00},
        {name = "Pink",    r = 1.00, g = 0.40, b = 0.70},
        {name = "Orange",  r = 1.00, g = 0.50, b = 0.00},
        {name = "White",   r = 1.00, g = 1.00, b = 1.00},
        {name = "Magenta", r = 1.00, g = 0.00, b = 1.00},
    }

    if not _G.SnapLineColorIndex then _G.SnapLineColorIndex = 1 end

    local function ApplySnapLineColor()
        pcall(function()
            local cfg = SNAPLINE_COLORS[_G.SnapLineColorIndex] or SNAPLINE_COLORS[1]
            local FLC = import("LinearColor")
            if not FLC then return end
            _G.SnapLineCustomColor = FLC(cfg.r, cfg.g, cfg.b, 1.0)
        end)
    end
    ApplySnapLineColor()

    -- ===== AUTO-ON SYNC (MENU DEFAULTS) =====
    _G.Mod_ESP_ShowSnapline = true
    _G.Mod_ESP_Enabled = true
    if _G.g_Botmater_VIPShotESP then _G.g_Botmater_VIPShotESP.Enabled = true end
    if _G.g_Botmater_ESPOptions then
        _G.g_Botmater_ESPOptions.Name = true
        _G.g_Botmater_ESPOptions.Health = true
        _G.g_Botmater_ESPOptions.Distance = true
        _G.g_Botmater_ESPOptions.EnemyCounter = true
    end

    -- ===== FEATURE MAP =====
    local FeatureMap = {
        ESP_Line       = "_G.Mod_ESP_ShowSnapline",
        V1_Master      = "_G.g_Botmater_VIPShotESP.Enabled",
        V1_Name        = "_G.g_Botmater_ESPOptions.Name",
        V1_Health      = "_G.g_Botmater_ESPOptions.Health",
        V1_Distance    = "_G.g_Botmater_ESPOptions.Distance",
        V1_Counter     = "_G.g_Botmater_ESPOptions.EnemyCounter",
    }

    local function GetFeatureState(key)
        local gVar = FeatureMap[key]
        if not gVar then return false end
        local val = false
        pcall(function() val = load("return " .. gVar)() end)
        return val
    end

    local function SyncFeature(key, value)
        if key == "V1_Master" then
            if _G.g_Botmater_VIPShotESP then _G.g_Botmater_VIPShotESP.Enabled = value end
            return
        elseif key == "V1_Name" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Name = value end
            return
        elseif key == "V1_Health" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Health = value end
            return
        elseif key == "V1_Distance" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Distance = value end
            return
        elseif key == "V1_Counter" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.EnemyCounter = value end
            return
        end
        local gVar = FeatureMap[key]
        if gVar then pcall(function() load(gVar .. " = " .. tostring(value))() end) end
    end

    local function ApplyFeature(key, state)
        SyncFeature(key, state)
        pcall(function()
            if key == "ESP_Line" then
                _G.Mod_ESP_Enabled = state
                if state then
                    if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive then
                        pcall(_G.PlayerMapMarker.Start)
                    end
                else
                    if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then
                        pcall(_G.PlayerMapMarker.Stop)
                    end
                end
            end
        end)
    end

    for cfgKey, _ in pairs(FeatureMap) do
        GetFeatureState(cfgKey)
    end

    local parentCanvas = nil
    local bgPanel = nil
    local allWidgets = {}
    local toggleRows = {}
    local floatItem = nil
    local isMenuOpen = false
    local menuBuilt = false

    local function GetCanvas()
        if parentCanvas and Game:IsValid(parentCanvas) then return parentCanvas end
        parentCanvas = nil
        pcall(function()
            local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local MainUI = InGameUITools.GetMainControlBaseUI()
            if not MainUI or not Game:IsValid(MainUI) then return end
            if MainUI.CanvasPanel_0 and Game:IsValid(MainUI.CanvasPanel_0) then parentCanvas = MainUI.CanvasPanel_0
            elseif MainUI.CanvasPanel_42 and Game:IsValid(MainUI.CanvasPanel_42) then parentCanvas = MainUI.CanvasPanel_42 end
        end)
        return parentCanvas
    end

    local function MakeBtn(parent, x, y, w, h, z, onClick)
        local btn = nil
        pcall(function()
            btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if btn and slua.isValid(btn) then
                pcall(function() btn:SetColorAndOpacity(C.transparent) end)
                pcall(function() btn:SetBackgroundColor(C.transparent) end)
                pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
                local slot = parent:AddChildToCanvas(btn)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(FVector2D(x, y))
                    slot:SetSize(FVector2D(w, h))
                    slot:SetZOrder(z or 900)
                end
                if onClick then
                    pcall(function() if btn.OnClicked then btn.OnClicked:Add(function() pcall(onClick) end) end end)
                end
            end
        end)
        table.insert(allWidgets, btn)
        return btn
    end

    local function Layer(parent, x, y, w, h, color, z)
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
            end
        end)
        table.insert(allWidgets, b)
        return b
    end

    local function Text(parent, txt, x, y, size, color, z, alignX, alignY)
        local t = nil
        pcall(function()
            t = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
            if t and slua.isValid(t) then
                t:SetText(txt)
                if FSlateColor then t:SetColorAndOpacity(FSlateColor(color))
                else t:SetColorAndOpacity(color) end
                if t.Font then local f = t.Font f.Size = size t.Font = f end
                t:SetRenderTransformPivot(FVector2D(alignX or 0.5, alignY or 0.5))
                t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(t)
                if slot then
                    slot:SetAutoSize(true)
                    slot:SetAlignment(FVector2D(alignX or 0.5, alignY or 0.5))
                    slot:SetPosition(FVector2D(x, y))
                    slot:SetZOrder(z or 100)
                end
            end
        end)
        table.insert(allWidgets, t)
        return t
    end

    local function UpdateToggleRow(rowData)
        if not rowData then return end
        local state = GetFeatureState(rowData.key)
        if rowData.track and IsValid(rowData.track) then
            pcall(function() rowData.track:SetBrushColor(state and C.toggle_on or C.toggle_off) end)
        end
        if rowData.knobSlot then
            pcall(function()
                local knobX = state and (rowData.toggleX + rowData.toggleW - rowData.knobSize - 2) or (rowData.toggleX + 2)
                rowData.knobSlot:SetPosition(FVector2D(knobX, rowData.toggleY + 2))
            end)
        end
    end

    local function MakeToggleRow(parent, label, x, y, w, h, toggleKey, isZebra)
        local state = GetFeatureState(toggleKey)
        local rowBg = isZebra and C.bg_row_alt or C.bg_row
        local rowData = { key = toggleKey }

        rowData.bg = Layer(parent, x, y, w, h, rowBg, 200)
        rowData.label = Text(parent, label, x + 16, y + h * 0.5, 16, C.text_black, 300, 0, 0.5)

        local toggleW = 48
        local toggleH = 24
        local toggleX = x + w - toggleW - 16
        local toggleY = y + h * 0.5 - toggleH * 0.5
        local knobSize = toggleH - 4

        rowData.toggleX = toggleX
        rowData.toggleY = toggleY
        rowData.toggleW = toggleW
        rowData.knobSize = knobSize

        rowData.track = Layer(parent, toggleX, toggleY, toggleW, toggleH, state and C.toggle_on or C.toggle_off, 300)
        local knobX = state and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)

        pcall(function()
            local k = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if k and slua.isValid(k) then
                k:SetBrushColor(C.toggle_knob)
                k:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(k)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(FVector2D(knobX, toggleY + 2))
                    slot:SetSize(FVector2D(knobSize, knobSize))
                    slot:SetZOrder(301)
                end
                rowData.knob = k
                rowData.knobSlot = slot
            end
        end)

        rowData.btn = MakeBtn(parent, x, y, w, h, 900, function()
            local newState = not GetFeatureState(toggleKey)
            ApplyFeature(toggleKey, newState)
            UpdateToggleRow(rowData)
        end)

        table.insert(toggleRows, rowData)
        return rowData
    end

    local function MakeSliderRow(parent, label, x, y, w, h, getDisplayText, onMinus, onPlus, isZebra)
        local rowBg = isZebra and C.bg_row_alt or C.bg_slider_row
        local rowData = { key = label, isSlider = true }

        rowData.bg = Layer(parent, x, y, w, h, rowBg, 200)
        rowData.label = Text(parent, label, x + 16, y + h * 0.5 - 8, 15, C.text_black, 300, 0, 0.5)
        rowData.valueText = Text(parent, getDisplayText(), x + 16, y + h * 0.5 + 10, 13, C.text_blue, 300, 0, 0.5)

        local function RefreshText()
            if rowData.valueText and IsValid(rowData.valueText) then
                pcall(function() rowData.valueText:SetText(getDisplayText()) end)
            end
        end

        local btnW = 40
        local btnH = 36
        local btnY = y + h * 0.5 - btnH * 0.5
        local minusX = x + w - 100
        local plusX = x + w - 52

        Layer(parent, minusX, btnY, btnW, btnH, C.btn_minus, 299)
        Text(parent, "-", minusX + btnW * 0.5, btnY + btnH * 0.5, 26, C.text_light, 400, 0.5, 0.5)
        MakeBtn(parent, minusX, btnY, btnW, btnH, 900, function() onMinus() RefreshText() end)

        Layer(parent, plusX, btnY, btnW, btnH, C.btn_plus, 299)
        Text(parent, "+", plusX + btnW * 0.5, btnY + btnH * 0.5, 24, C.text_light, 400, 0.5, 0.5)
        MakeBtn(parent, plusX, btnY, btnW, btnH, 900, function() onPlus() RefreshText() end)

        table.insert(toggleRows, rowData)
        return rowData
    end

    local function SectionHeader(parent, txt, x, y, w)
        Layer(parent, x, y, w, SECTION_H, C.bg_section, 250)
        Text(parent, txt, x + w * 0.5, y + SECTION_H * 0.5, 15, C.text_blue, 300, 0.5, 0.5)
    end

    local function BuildMenu()
        if menuBuilt and bgPanel and IsValid(bgPanel) then
            pcall(function() bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            return
        end

        local canvas = GetCanvas()
        if not canvas then return end

        allWidgets = {}
        toggleRows = {}

        pcall(function()
            bgPanel = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
            if bgPanel and slua.isValid(bgPanel) then
                local slot = canvas:AddChildToCanvas(bgPanel)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetZOrder(10000)

                    local anchored = false
                    pcall(function()
                        local anchors = { Minimum = FVector2D(1.0, 0.0), Maximum = FVector2D(1.0, 0.0) }
                        slot:SetAnchors(anchors)
                        anchored = true
                    end)

                    if anchored then
                        slot:SetAlignment(FVector2D(1, 0))
                        slot:SetPosition(FVector2D(-20, 20))
                    else
                        slot:SetAlignment(FVector2D(0, 0))
                        local sw = 1920
                        pcall(function()
                            local ui = require("client.common.ui_util")
                            if ui and ui.GetViewportSize then
                                local s = ui.GetViewportSize()
                                if s and s.X and s.X > 0 then sw = s.X end
                            end
                        end)
                        slot:SetPosition(FVector2D(sw - M_W - 20, 20))
                    end
                    slot:SetSize(FVector2D(M_W, M_H))
                end
            end
        end)
        if not bgPanel or not slua.isValid(bgPanel) then return end

        Layer(bgPanel, 0, 0, M_W, M_H, C.bg_panel, 1)
        Layer(bgPanel, 0, 0, M_W, 2, C.border_blue, 2)
        Layer(bgPanel, 0, M_H - 2, M_W, 2, C.border_blue, 2)
        Layer(bgPanel, 0, 0, 2, M_H, C.border_blue, 2)
        Layer(bgPanel, M_W - 2, 0, 2, M_H, C.border_blue, 2)

        Layer(bgPanel, 2, 2, M_W - 4, HEADER_H - 4, C.bg_header, 3)
        Text(bgPanel, "PAKxTEAM ESP VERSION", M_W * 0.5, HEADER_H * 0.5, 24, C.text_black, 400, 0.5, 0.5)
        Layer(bgPanel, 20, 18, 12, 12, FLinearColor(1, 0.4, 0.4), 5)
        Layer(bgPanel, 40, 18, 12, 12, FLinearColor(1, 0.8, 0.2), 5)
        Layer(bgPanel, 60, 18, 12, 12, FLinearColor(0.2, 0.9, 0.2), 5)

        MakeBtn(bgPanel, M_W - 40, 20, 30, 30, 900, function()
            isMenuOpen = false
            pcall(function() bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end)
        Text(bgPanel, "X", M_W - 25, 35, 20, C.close_btn, 400, 0.5, 0.5)

        local contentX = 12
        local contentW = M_W - 24
        local y = HEADER_H + 10

        -- ===== SNAPLINES (PAKxTEAM) =====
        SectionHeader(bgPanel, "SNAPLINES (PAKxTEAM)", contentX, y, contentW)
        y = y + SECTION_H + 4

        MakeToggleRow(bgPanel, "ESP LINE", contentX, y, contentW, ROW_H, "ESP_Line", false)
        y = y + ROW_H + 4

        MakeSliderRow(bgPanel, "SNAPLINE COLOR", contentX, y, contentW, SLIDER_ROW_H,
            function()
                local cfg = SNAPLINE_COLORS[_G.SnapLineColorIndex] or SNAPLINE_COLORS[1]
                return "Color: " .. cfg.name .. "  (" .. _G.SnapLineColorIndex .. "/" .. #SNAPLINE_COLORS .. ")"
            end,
            function()
                _G.SnapLineColorIndex = _G.SnapLineColorIndex - 1
                if _G.SnapLineColorIndex < 1 then _G.SnapLineColorIndex = #SNAPLINE_COLORS end
                ApplySnapLineColor()
            end,
            function()
                _G.SnapLineColorIndex = _G.SnapLineColorIndex + 1
                if _G.SnapLineColorIndex > #SNAPLINE_COLORS then _G.SnapLineColorIndex = 1 end
                ApplySnapLineColor()
            end,
            true)
        y = y + SLIDER_ROW_H + 10

        -- ===== PAKxTEAM ESP =====
        SectionHeader(bgPanel, "PAKxTEAM ESP", contentX, y, contentW)
        y = y + SECTION_H + 4

        local v1Options = {
            {label = "V1 MASTER ENABLE",  key = "V1_Master"},
            {label = "V1 NAME TAG",       key = "V1_Name"},
            {label = "V1 HEALTH BAR",     key = "V1_Health"},
            {label = "V1 DISTANCE",       key = "V1_Distance"},
            {label = "V1 ENEMY COUNTER",  key = "V1_Counter"},
        }
        for i, opt in ipairs(v1Options) do
            MakeToggleRow(bgPanel, opt.label, contentX, y, contentW, ROW_H, opt.key, i % 2 == 0)
            y = y + ROW_H + 4
        end

        Layer(bgPanel, 2, M_H - 32, M_W - 4, 30, C.bg_header, 5)
        Text(bgPanel, "DEVELOPER - @PAKxTEAM", M_W * 0.5, M_H - 15, 12, C.text_blue, 400, 0.5, 0.5)

        menuBuilt = true
        isMenuOpen = true
    end

    local function CreateFloat()
        if floatItem and floatItem.btn and IsValid(floatItem.btn) then return end
        floatItem = nil
        pcall(function()
            local canvas = GetCanvas()
            if not canvas then return end

            floatItem = {}
            local fX = 20
            local fY = 15
            local fW = 110
            local fH = 45

            floatItem.s8 = Layer(canvas, fX, fY, fW, fH, FLinearColor(0.96, 0.96, 0.96, 0.75), 11902)
            Layer(canvas, fX, fY, fW, 4, C.border_blue, 11903)
            Layer(canvas, fX, fY, fW, 2, C.border_blue, 11904)
            Layer(canvas, fX, fY + fH - 2, fW, 2, C.border_blue, 11904)

            pcall(function()
                floatItem.text = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                if floatItem.text and slua.isValid(floatItem.text) then
                    floatItem.text:SetText("MENU")
                    if FSlateColor then floatItem.text:SetColorAndOpacity(FSlateColor(C.text_black))
                    else floatItem.text:SetColorAndOpacity(C.text_black) end
                    if floatItem.text.Font then local f = floatItem.text.Font f.Size = 20 floatItem.text.Font = f end
                    floatItem.text:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    local slot = canvas:AddChildToCanvas(floatItem.text)
                    if slot then
                        slot:SetAutoSize(true)
                        slot:SetAlignment(FVector2D(0.5, 0.5))
                        slot:SetPosition(FVector2D(fX + fW * 0.5, fY + fH * 0.5))
                        slot:SetZOrder(12001)
                    end
                end
            end)

            pcall(function()
                floatItem.btn = CGame:NewObjectFromPath("/Script/UMG.Button", canvas)
                if floatItem.btn and slua.isValid(floatItem.btn) then
                    pcall(function() floatItem.btn:SetColorAndOpacity(C.transparent) end)
                    pcall(function() floatItem.btn:SetBackgroundColor(C.transparent) end)
                    pcall(function() floatItem.btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
                    local slot = canvas:AddChildToCanvas(floatItem.btn)
                    if slot then
                        slot:SetAutoSize(false)
                        slot:SetPosition(FVector2D(fX, fY))
                        slot:SetSize(FVector2D(fW, fH))
                        slot:SetZOrder(12002)
                    end
                    pcall(function()
                        if floatItem.btn.OnClicked then
                            floatItem.btn.OnClicked:Add(function()
                                pcall(function()
                                    isMenuOpen = not isMenuOpen
                                    if isMenuOpen then
                                        if menuBuilt and bgPanel and IsValid(bgPanel) then
                                            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                        else
                                            BuildMenu()
                                        end
                                    else
                                        if bgPanel and IsValid(bgPanel) then
                                            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                        end
                                    end
                                end)
                            end)
                        end
                    end)
                end
            end)
        end)
    end

    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and IsValid(pc) then
            CreateFloat()
            pc:AddGameTimer(3, true, function()
                if not floatItem or not floatItem.btn or not IsValid(floatItem.btn) then
                    floatItem = nil
                    CreateFloat()
                end
            end)
        end
    end)
end


print("[FINAL ESP] Snaplines (PAKxTEAM) + PAKxTEAM ESP V1 loaded (AUTO-ON)")
-- ═══════════════════════════════════════════════════════════════════════════════
-- [BLOCK 4] SAMEER FILE LOADER — scoped do ... end
-- ═══════════════════════════════════════════════════════════════════════════════
do
  local SAMEER_SCOPE = "master-file:Android/data/<package>/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/_s"

  local function SameerMakeState(existing)
    local S = {
      Version = 1, Scope = SAMEER_SCOPE,
      Generation = ((type(existing) == "table" and tonumber(existing.Generation)) or 0) + 1,
      Epoch = 0, Checks = 0, Attempts = 0, Executions = 0,
      Active = false, Loaded = false, InFlight = false,
      Phase = "WaitingEntry",
      HookAttempts = setmetatable({}, { __mode = "k" }),
    }
    _G.__MasterAhsanFileEntryBootstrap = S
    _G.MasterOfflineLoader = S
    return S
  end
  local function SameerIsValid(S) return _G.__MasterAhsanFileEntryBootstrap == S end
  local function SameerSafeIndex(obj, key)
    if obj == nil then return nil end
    local ok, res = pcall(function() return obj[key] end)
    if ok then return res end
    return nil
  end
  local function SameerHandleError(S, phase, err, terminal)
    S.InFlight = false; S.Active = false
    if S.Pending then S.Pending.Used = true end
    S.Pending = nil; S.Error = err; S.LastError = err
    S.Phase = phase; S.Loaded = S.Loaded == true
    if terminal then S.Terminal = true end
  end
  local function SameerGetTimer()
    local ok, ticker = pcall(require, "common.time_ticker")
    if not ok then return nil end
    return SameerSafeIndex(ticker, "AddTimerOnce")
  end
  local function SameerIsSluaValid(obj)
    local fn = SameerSafeIndex(_G.slua, "isValid")
    if obj ~= nil and type(fn) == "function" then
      local ok, res = pcall(fn, obj)
      return ok and res == true
    end
    return false
  end
  local function SameerCheckGameReady()
    if not _G.Client then return false, "ClientNotReady" end
    if not SameerGetTimer() then return false, "TickerUnavailable" end
    local ok, GPD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok or not GPD then return false, "GameplayDataUnavailable" end
    local getChar = SameerSafeIndex(GPD, "GetPlayerCharacter")
    local getCtrl = SameerSafeIndex(GPD, "GetPlayerController")
    if type(getChar) ~= "function" or type(getCtrl) ~= "function" then return false, "PlayerAccessUnavailable" end
    local cOk, chr = pcall(getChar)
    local kOk, ctl = pcall(getCtrl)
    if not cOk or not SameerIsSluaValid(chr) then return false, "PlayerNotReady" end
    if not kOk or not SameerIsSluaValid(ctl) then return false, "ControllerNotReady" end
    if type(SameerSafeIndex(_G.CGame, "NewObjectFromPath")) ~= "function" then return false, "WidgetFactoryUnavailable" end
    if SameerSafeIndex(_G.UEnums, "ESlateVisibility") == nil then return false, "VisibilityEnumUnavailable" end
    local ok2, IGT = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    local getMain = ok2 and SameerSafeIndex(IGT, "GetMainControlBaseUI")
    if type(getMain) ~= "function" then return false, "InGameUIUnavailable" end
    local mOk, main = pcall(getMain)
    if not mOk or not SameerIsSluaValid(main) then return false, "MainControlUnavailable" end
    if not SameerIsSluaValid(SameerSafeIndex(main, "CanvasPanel_0"))
       and not SameerIsSluaValid(SameerSafeIndex(main, "CanvasPanel_42")) then
      return false, "CanvasUnavailable"
    end
    return true
  end
  local function SameerFindPayload(S)
    local openFn = SameerSafeIndex(_G.io, "open")
    if type(openFn) ~= "function" then return nil, "FileIOUnavailable" end
    local ok, file, err = pcall(openFn, "/proc/self/cmdline", "rb")
    if not ok then return nil, "PackageReadError: " .. tostring(file) end
    if not file then return nil, "PackageReadError: " .. tostring(err) end
    local rOk, content = pcall(function() return file:read("*a") end)
    pcall(function() file:close() end)
    if not rOk then return nil, "PackageReadError: " .. tostring(content) end
    local pkg = nil
    if type(content) == "string" then pkg = content:match("^[^%z:]+") end
    if not pkg or not pkg:match("^[%w_]+%.[%w_%.]+$") then return nil, "Package unavailable" end
    S.Package = pkg
    S.Path = "/storage/emulated/0/Android/data/" .. pkg
          .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/_s.so"
    S.path = S.Path
    local loadFile = SameerSafeIndex(_G, "loadfile")
    if type(loadFile) ~= "function" then return nil, "LoadFileUnavailable" end
    local lOk, chunk, lErr = pcall(loadFile, S.Path)
    if not lOk then return nil, "FileLoadError: " .. tostring(chunk) end
    if type(chunk) == "function" then return chunk end
    return nil, "FileLoadError: " .. tostring(lErr)
  end
  local function SameerRegisterHook(S)
    local ES = _G.EventSystem
    local regist = SameerSafeIndex(ES, "registEvent")
    local eType = _G.EVENTTYPE_INGAME
    local eId = _G.EVENTID_INGAME_CONTROLLER_BEGINPLAY_FINISH
    if type(regist) ~= "function" or eType == nil or eId == nil then
      S.HookPhase = "WaitingEventSystem"; return
    end
    if S.HookAttempts[ES] then return end
    S.HookAttempts[ES] = true
    local ok = pcall(regist, ES, eType, eId, function()
      if SameerIsValid(S) and type(S.Wake) == "function" then S.Wake("controller_beginplay") end
    end)
    S.HookPhase = ok and "Registered" or "RegistrationFailed"
  end
  local SameerTick
  local SameerArmTimer
  SameerArmTimer = function(S, delay, callback)
    if not SameerIsValid(S) then return false end
    if not S.Active or S.Pending or S.Terminal then return false end
    local timerFn = SameerGetTimer()
    if not timerFn then SameerHandleError(S, "WaitingReadyEvent", "TickerUnavailable", false); return false end
    local task = { Epoch = S.Epoch, Used = false, Synchronous = false }
    S.Pending = task; S.ArmingTimer = true
    local ok, res = pcall(timerFn, delay, function()
      if task.Used then return end
      if not SameerIsValid(S) then return end
      if task.Epoch ~= S.Epoch then return end
      if S.Pending ~= task then return end
      task.Used = true; S.Pending = nil
      if S.ArmingTimer then task.Synchronous = true; return end
      if S.Active and not S.Terminal then callback(task.Epoch) end
    end)
    S.ArmingTimer = false
    if task.Synchronous then SameerHandleError(S, "WaitingReadyEvent", "SynchronousTimerUnsupported", false); return false end
    if not ok or res == false then
      task.Used = true
      SameerHandleError(S, "WaitingReadyEvent", "TimerUnavailable", false)
      return false
    end
    return true
  end
  local function SameerRetry(S, reason)
    if not SameerIsValid(S) or not S.Active then return end
    if reason then S.Error = reason; S.LastError = reason end
    S.Phase = "WaitingReadiness"
    if S.Checks >= 120 then
      SameerHandleError(S, "WaitingReadyEvent", reason or "CheckBudgetExhausted", true)
    else
      SameerArmTimer(S, 1.0, function(epoch) SameerTick(S, epoch) end)
    end
  end
  SameerTick = function(S, epoch)
    if not SameerIsValid(S) or not S.Active then return end
    if epoch ~= S.Epoch or S.Checking or S.Terminal then return end
    S.Checking = true
    local runOk, runErr = pcall(function()
      S.Checks = S.Checks + 1
      SameerRegisterHook(S)
      local ready, err = SameerCheckGameReady()
      if not ready then SameerRetry(S, err); return end
      S.Attempts = S.Attempts + 1
      S.Error = nil; S.LastError = nil
      S.Phase = "LoadingFile"
      local chunk, loadErr = SameerFindPayload(S)
      if not SameerIsValid(S) then return end
      if not chunk then SameerHandleError(S, "WaitingReadyEvent", loadErr, false); return end
      S.Phase = "Executing"; S.Executions = S.Executions + 1; S.Terminal = true
      local execOk, execErr = pcall(chunk)
      if not SameerIsValid(S) then return end
      if execOk then
        S.Loaded = true
        if _G.LunarOptionalStartupError == nil then
          SameerHandleError(S, "Loaded", nil, true)
          print("[SAMEER LOADER] SAMEER.lua Loaded Successfully!")
        else
          SameerHandleError(S, "LoadedWithStartupError", tostring(_G.LunarOptionalStartupError), true)
          print("[SAMEER LOADER] Loaded with startup error: " .. tostring(_G.LunarOptionalStartupError))
        end
        return
      end
      SameerHandleError(S, "ExecutionError", tostring(execErr), true)
      print("[SAMEER LOADER] Execution error: " .. tostring(execErr))
    end)
    S.Checking = false
    if not runOk and SameerIsValid(S) then
      SameerHandleError(S, S.Terminal and "ExecutionError" or "WaitingReadyEvent", tostring(runErr), false)
      print("[SAMEER LOADER] Tick error: " .. tostring(runErr))
    end
  end
  local function SameerWake(S, reason)
    if not SameerIsValid(S) or S.Waking or S.Terminal then return end
    S.Waking = true
    local ok, err = pcall(function()
      if S.Active or S.Checking or S.Terminal then return end
      S.Epoch = S.Epoch + 1; S.Checks = 0
      S.Error = nil; S.LastError = nil
      S.Phase = "Scheduled"; S.WakeReason = reason
      S.InFlight = true; S.Active = true
      print("[SAMEER LOADER] Wake triggered: " .. tostring(reason))
      SameerArmTimer(S, 0.05, function(epoch) SameerTick(S, epoch) end)
    end)
    S.Waking = false
    if not ok and SameerIsValid(S) then
      SameerHandleError(S, "WaitingReadyEvent", tostring(err), false)
      print("[SAMEER LOADER] Wake error: " .. tostring(err))
    end
  end
  local function SameerEntryPoint()
    local existing = _G.__MasterAhsanFileEntryBootstrap
    if type(existing) == "table" and existing.Version == 1
       and existing.Scope == SAMEER_SCOPE and type(existing.Wake) == "function" then
      _G.MasterOfflineLoader = existing
      existing.Wake("entry")
      return
    end
    local S = SameerMakeState(existing)
    S.Wake = function(reason) SameerWake(S, reason) end
    S.Wake("entry")
  end
  pcall(SameerEntryPoint)
end

return CombineClass.DeclareFeature(BRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")
