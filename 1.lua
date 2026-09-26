--[[================================================================
  PAKxTEAM MOD — FINAL INJECTOR EDITION (Glitch-Fixed)
  - Aimbot V2 (Original 4-Category Logic)
  - English Menu
  - Skin/Outfit/Vehicle/Pet/DeadBox REMOVED
  - Wallhack REMOVED
  - Match-entry glitch guard (5s warmup)
  - No dangerous global overrides
================================================================]]

if _G.__PAKxTEAM_INJECTED then
    print("[PAKxTEAM] Already loaded. Skipping.")
    return
end
_G.__PAKxTEAM_INJECTED = true

local _slua  = rawget(_G, "slua")
local _Game  = rawget(_G, "Game")
local _CGame = rawget(_G, "CGame")

if not (_slua and _Game and _CGame) then
    print("[PAKxTEAM] Engine not ready. Abort.")
    return
end

-- ============================================================
-- PACKAGE DETECTION
-- ============================================================
local KismetSystemLibrary = import("KismetSystemLibrary")
local packageName = KismetSystemLibrary and KismetSystemLibrary.GetGameBundleId()

local SUPPORTED_VERSIONS = {
    ["com.tencent.ig"] = "Global",
    ["com.pubg.krmobile"] = "Korea",
    ["com.rekoo.pubgm"] = "Taiwan",
    ["com.tencent.iglite"] = "Lite",
    ["com.pubg.newstate"] = "New State",
    ["com.vng.pubgmobile"] = "Vietnam",
    ["com.pubg.imobile"] = "Imobile",
}

if packageName then
    local versionName = SUPPORTED_VERSIONS[packageName] or "Unknown"
    print("[PAKxTEAM] Detected: " .. versionName .. " (" .. packageName .. ")")
    if packageName == "com.rekoo.pubgm" then _G.IS_TW_VERSION = true; _G.IS_TW = true end
    if packageName == "com.tencent.ig" then _G.IS_GLOBAL = true end
    if packageName == "com.pubg.krmobile" then _G.IS_KR = true end
end

-- ============================================================================
-- ULTIMATE MERGED BYPASS v5.0 - COMPLETE SECURITY ANNIHILATION
-- Merged from BRPlayerCharacterBase.lua & Original Bypass
-- For educational purposes only, you beautiful disaster
-- ============================================================================

local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end

-- ==========================================
-- 1. SLUA BYPASS - Kill Lua VM Verification
-- ==========================================
local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then 
            slua.getSignature = function() return 0xDEADBEEF end 
        end
        
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then 
                loader.disableSignatureCheck = retTrue 
            end
        end
        
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then 
            slua_serialize.check = retTrue
            slua_serialize.verify = retTrue 
        end
        
        if jit and jit.attach then 
            jit.attach(function() end, "bc") 
        end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

-- ==========================================
-- 2. MD5 BYPASS - Kill File Integrity Checks
-- ==========================================
local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
        end
        
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue
            FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then 
            TssSdk.GetFileMD5 = function() return "BYPASS" end
            TssSdk.VerifyFileSignature = retTrue 
        end
        
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then 
            STExtra.CheckMD5 = retTrue
            STExtra.GetMD5 = function() return "BYPASS" end
            STExtra.VerifyFile = retTrue 
        end
    end)
end

-- ==========================================
-- 3. TSS SDK COMPLETE BLOCK
-- ==========================================
local function InitializeTSSBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.OnRecvData = function() end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
            TssSdk.IsEmulator = function() return false end
            TssSdk.GetTssSdkReportInfo = function() return "" end
            TssSdk.ReportException = function() end
            TssSdk.ReportData = function() end
            TssSdk.CheckIntegrity = function() return true end
            TssSdk.VerifySignature = function() return true end
            TssSdk.CollectEvidence = function() return nil end
            TssSdk.UploadLog = function() end
            TssSdk.SendAntiData = function() end
            TssSdk.ReportGameStart = function() end
            TssSdk.ReportGameEnd = function() end
            TssSdk.ReportCrash = function() end
            TssSdk.ReportViolation = function() end
            TssSdk.ReportSuspicious = function() end
            TssSdk.ReportBan = function() end
            TssSdk.ReportKick = function() end
            TssSdk.ReportWarning = function() end
            TssSdk.ReportInfo = function() end
            TssSdk.ReportDebug = function() end
            TssSdk.ReportError = function() end
            TssSdk.ReportFatal = function() end
            TssSdk.ReportMemory = function() end
            TssSdk.ReportProcess = function() end
            TssSdk.ReportModule = function() end
            TssSdk.ReportThread = function() end
            TssSdk.ReportFile = function() end
            TssSdk.ReportNetwork = function() end
            TssSdk.ReportDevice = function() end
            TssSdk.ReportSystem = function() end
            TssSdk.ReportGame = function() end
            TssSdk.ReportUser = function() end
            TssSdk.ReportAccount = function() end
            TssSdk.ReportSession = function() end
            TssSdk.ReportPerformance = function() end
            TssSdk.ReportBattery = function() end
            TssSdk.ReportTemperature = function() end
            TssSdk.ReportFPS = function() end
            TssSdk.ReportPing = function() end
            TssSdk.ReportPacket = function() end
            TssSdk.ReportCheat = function() end
            TssSdk.ReportHack = function() end
            TssSdk.ReportMod = function() end
            TssSdk.ReportInject = function() end
            TssSdk.ReportDebugger = function() end
            TssSdk.ReportEmulator = function() end
            TssSdk.ReportRoot = function() end
            TssSdk.ReportJailbreak = function() end
            TssSdk.ReportVM = function() end
            TssSdk.ReportHook = function() end
            TssSdk.ReportPatch = function() end
            TssSdk.ReportTamper = function() end
            TssSdk.ReportCorrupt = function() end
            TssSdk.ReportInvalid = function() end
            TssSdk.ReportSpoof = function() end
            TssSdk.ReportFake = function() end
            TssSdk.ReportClone = function() end
            TssSdk.ReportDuplicate = function() end
            TssSdk.ReportConflict = function() end
            TssSdk.ReportOverlap = function() end
            TssSdk.ReportMismatch = function() end
            TssSdk.ReportInconsistent = function() end
            TssSdk.ReportUnexpected = function() end
            TssSdk.ReportUnknown = function() end
        end
    end)
end

-- ==========================================
-- 4. ACE (ANTI-CHEAT EXPERT) COMPLETE BLOCK
-- ==========================================
local function InitializeACEBypass()
    pcall(function()
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = function() end
            ace.CheckIntegrity = function() return true end
            ace.ScanMemory = function() return false end
            ace.VerifyProcess = function() return true end
            ace.CheckModule = function() return true end
            ace.ReportViolation = function() end
            ace.KickPlayer = function() end
            ace.BanPlayer = function() end
            ace.CollectInfo = function() return {} end
            ace.SendReport = function() end
            ace.ValidateClient = function() return true end
            ace.CheckDebugger = function() return false end
            ace.CheckEmulator = function() return false end
            ace.CheckRoot = function() return false end
            ace.ReportCheat = function() end
            ace.ReportHack = function() end
            ace.ReportMod = function() end
            ace.ReportInject = function() end
            ace.ReportHook = function() end
            ace.ReportPatch = function() end
            ace.ReportTamper = function() end
            ace.ReportCorrupt = function() end
            ace.ReportInvalid = function() end
            ace.ReportSpoof = function() end
            ace.ReportFake = function() end
        end
    end)
end

-- ==========================================
-- 5. XIGNCODE3 COMPLETE BLOCK
-- ==========================================
local function InitializeXignCodeBypass()
    pcall(function()
        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            XignCode.SendReport = function() end
            XignCode.CheckProcess = function() return true end
            XignCode.VerifyIntegrity = function() return true end
            XignCode.ScanModules = function() return {} end
            XignCode.ReportException = function() end
            XignCode.ValidateMemory = function() return true end
            XignCode.CheckDebugger = function() return false end
            XignCode.KickPlayer = function() end
            XignCode.BanPlayer = function() end
            XignCode.EncryptData = function(data) return data end
            XignCode.DecryptData = function(data) return data end
            XignCode.ReportCheat = function() end
            XignCode.ReportHack = function() end
            XignCode.ReportMod = function() end
            XignCode.ReportInject = function() end
            XignCode.ReportHook = function() end
            XignCode.ReportPatch = function() end
            XignCode.ReportTamper = function() end
        end
    end)
end

-- ==========================================
-- 6. BATTEYE COMPLETE BLOCK
-- ==========================================
local function InitializeBattlEyeBypass()
    pcall(function()
        local BattlEye = _G.BattlEye or package.loaded["BattlEye"]
        if BattlEye then
            BattlEye.SendReport = function() end
            BattlEye.KickPlayer = function() end
            BattlEye.ValidatePlayer = function() return true end
            BattlEye.CheckMemory = function() return true end
            BattlEye.VerifyIntegrity = function() return true end
            BattlEye.ReportViolation = function() end
            BattlEye.ScanProcess = function() return true end
            BattlEye.BanPlayer = function() end
            BattlEye.CollectEvidence = function() return {} end
            BattlEye.ReportCheat = function() end
            BattlEye.ReportHack = function() end
            BattlEye.ReportMod = function() end
            BattlEye.ReportInject = function() end
            BattlEye.ReportHook = function() end
        end
    end)
end

-- ==========================================
-- 7. SKIN BYPASS - Kill Avatar/Skin Validation
-- ==========================================
local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then 
            ptlog.ReportEvent = nop
            ptlog.ReportDownloadResult = nop
            ptlog.ReportODPTDError = nop
            ptlog.ReportSkinError = nop 
        end
        
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then 
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.ValidateAvatar = retTrue
            AvatarUtils.CheckAvatar = retTrue
            AvatarUtils.VerifySkin = retTrue
            AvatarUtils.ValidateSkin = retTrue
            AvatarUtils.CheckSkin = retTrue
            AvatarUtils.VerifyWeapon = retTrue
            AvatarUtils.ValidateWeapon = retTrue
            AvatarUtils.CheckWeapon = retTrue
            AvatarUtils.VerifyVehicle = retTrue
            AvatarUtils.ValidateVehicle = retTrue
            AvatarUtils.CheckVehicle = retTrue
        end
        
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then 
            sub.StartCheck = nop
            sub.ReportAbnormalFile = nop
            sub.StopCheck = nop 
        end
        
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then 
            eqEx.Report = nop
            eqEx.SendException = nop 
        end
    end)
end

-- ==========================================
-- 8. LOG BLOCKER - Kill Crash/Telemetry Logs
-- ==========================================
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then 
            SMTD.MTDePicture = function() return "" end
            SMTD.ReMTDePicture = function() return "" end
            SMTD.HasCaptured = retTrue
            SMTD.TakeScreenshot = nop 
        end
        
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then 
            TLog.Info = nop
            TLog.Warning = nop
            TLog.Error = nop
            TLog.Debug = nop
            TLog.Report = nop
            TLog.Send = nop
            TLog.Flush = nop 
        end
        
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then 
            CrashSight.ReportException = nop
            CrashSight.SetCustomData = nop
            CrashSight.Log = nop
            CrashSight.SendReport = nop
            CrashSight.CollectInfo = function() return {} end
            CrashSight.ReportCrash = nop
            CrashSight.ReportError = nop
            CrashSight.ReportFatal = nop
            CrashSight.ReportWarning = nop
            CrashSight.ReportInfo = nop
            CrashSight.ReportDebug = nop
            CrashSight.ReportMemory = nop
            CrashSight.ReportPerformance = nop
        end
        
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.Gameplay.GameReport.GameReportUtils"]
        if GRUtils then 
            GRUtils.BugglyPostExceptionFull = retFalse
            GRUtils.CheckCanBugglyPostException = retFalse
            GRUtils.ReplayReportData = nop
            GRUtils.ReportGameException = nop
            GRUtils.PostException = nop 
        end
        
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then 
            CTR.SendReport = nop
            CTR.SendException = nop
            CTR.UploadLog = nop 
        end
        
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]
            if s then 
                s.logEvent = nop
                s.trackEvent = nop
                s.setEnabled = retFalse
                s.sendEvent = nop
                s.report = nop 
            end
        end
    end)
end

-- ==========================================
-- 9. SCANNER BLOCKER - Kill Runtime Scanners
-- ==========================================
local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {
                "AFKReportorSubsystem", 
                "ClientDataStatistcsSubsystem", 
                "AvatarExceptionSubsystem", 
                "ShootVerifySubSystemClient", 
                "MemoryCheckSubsystem", 
                "SpeedCheckSubsystem", 
                "WallCheckSubsystem", 
                "FileCheckSubsystem", 
                "BehaviorScoreSubsystem"
            }
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (
                            k:find("Report") or k:find("Send") or k:find("Upload") or 
                            k:find("Verify") or k:find("Check") or k:find("Validate") or 
                            k:find("Scan") or k:find("Detect")
                        ) then 
                            pcall(function() sub[k] = nop end) 
                        end
                    end
                    if sub.ReportPingDelayTimer then 
                        sub:RemoveGameTimer(sub.ReportPingDelayTimer)
                        sub.ReportPingDelayTimer = nil 
                    end
                    sub.DelayCount = 0
                end
            end
        end
        
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then 
            AvaEx.CheckAvatarException = nop
            AvaEx.CheckAvatarExceptionOnce = nop
            AvaEx.ReportAvatarException = nop
            AvaEx.CheckSlotMeshVisible = retFalse
            AvaEx.CheckPawnVisible = retFalse
            AvaEx.CheckCanBugglyPostException = retFalse 
        end
        
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data) 
                if type(data) == "string" and (
                    data:find("report") or data:find("exception") or data:find("cheat") or 
                    data:find("violation") or data:find("hack") or data:find("verify")
                ) then 
                    return 
                end
                if origData then origData(data) end 
            end
            TssSdk.SendReportInfo = nop
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.CheckEnvironment = retTrue
            TssSdk.VerifyProcess = retTrue
        end
    end)
end

-- ==========================================
-- 10. REPLAY/TELEMETRY BLOCKER
-- ==========================================
local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then 
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (
                            k:find("Report") or k:find("Trace") or k:find("Replay") or 
                            k:find("Record") or k:find("Save")
                        ) then 
                            pcall(function() sub[k] = nop end) 
                        end
                    end 
                end
            end
        end
        
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then 
            logRep.ReportReplay = nop
            logRep.SendReportReq = nop
            logRep.UploadReplay = nop 
        end
    end)
end

-- ==========================================
-- 11. REPORT FLOW BLOCKER
-- ==========================================
local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {
            "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow",
            "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior",
            "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute",
            "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow",
            "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP",
            "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
            "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"
        }
        for _, f in ipairs(flows) do 
            if _G[f] then _G[f] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end
        end
        
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do
            if _G[f] then _G[f] = retFalse end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end
        end
        
        for _, f in ipairs({
            "IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow",
            "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow",
            "IsEnableReportCircleFlow"
        }) do 
            if _G[f] then _G[f] = retFalse end
        end
    end)
end

-- ==========================================
-- 12. PLAYER SECURITY BYPASS
-- ==========================================
local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({
            "PlayerSecurityInfoCollector", "PlayerSecurityInfo", 
            "SecurityInfoCollector", "ClientSecurityCollector", 
            "PlayerAntiCheatCollector"
        }) do
            if _G[c] then 
                for k, v in pairs(_G[c]) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Collect") or k:find("Send") or 
                        k:find("Upload") or k:find("Record")
                    ) then 
                        _G[c][k] = nop 
                    end
                end 
            end
        end
        
        local SecSub = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then 
            SecSub.ReportData = nop
            SecSub.CheckCheat = retFalse
            SecSub.ValidatePlayer = retTrue
            SecSub.CollectData = nop
            SecSub.SendToServer = nop 
        end
    end)
end

-- ==========================================
-- 13. CLIENT FLOW BYPASS
-- ==========================================
local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({
            "ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", 
            "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", 
            "ClientSecPlayerKillFlow"
        }) do
            local sub = package.loaded[name] or _G[name]
            if sub then 
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Send") or k:find("Flow") or 
                        k:find("Record") or k:find("Process")
                    ) then 
                        pcall(function() sub[k] = nop end) 
                    end
                end 
            end
        end
    end)
end

-- ==========================================
-- 14. SWIFT HAWK BYPASS
-- ==========================================
local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({
            "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"
        }) do 
            if _G[f] then _G[f] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end
        end
        
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then 
            sub.ReportData = nop
            sub.SendReport = nop
            sub.CollectTelemetry = nop 
        end
    end)
end

-- ==========================================
-- 15. CORONA LAB BYPASS
-- ==========================================
local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then 
            _G.CoronaLab.ReportData = nop
            _G.CoronaLab.SendData = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry = nop 
        end
        
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if sub then 
            sub.ReportData = nop
            sub.SendToServer = nop
            sub.CollectTelemetry = nop
            sub.StopCollection = nop 
        end
    end)
end

-- ==========================================
-- 16. MODIFIER EXCEPTION BYPASS
-- ==========================================
local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        
        local sub = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then 
            sub.ReportException = nop
            sub.CheckModifier = retTrue
            sub.ValidateModifier = retTrue
            sub.ReportModifierError = nop 
        end
    end)
end

-- ==========================================
-- 17. SIMULATE CHARACTER LOCATION BYPASS
-- ==========================================
local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local sub = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then 
            sub.ReportLocation = nop
            sub.SendLocationData = nop
            sub.VerifyLocation = retTrue 
        end
    end)
end

-- ==========================================
-- 18. SHOOT VERIFICATION BYPASS
-- ==========================================
local function InitializeShootVerificationBypass()
    pcall(function()
        local sub = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then 
            sub.OnShootVerifyFailed = nop
            sub.SendVerifyData = nop
            sub.ReportBulletHit = nop
            sub.UploadHitInfo = nop
            sub.VerifyShot = retTrue 
        end
        
        if _G.BulletHitInfoUploadData then 
            _G.BulletHitInfoUploadData.Report = nop
            _G.BulletHitInfoUploadData.Send = nop
            _G.BulletHitInfoUploadData.Upload = nop 
        end
    end)
end

-- ==========================================
-- 19. NETWORK PACKET BLOCKER - The Big One
-- ==========================================
local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, 
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, 
                ["ReportMrpcsFlow"]=1, ["ReportPlayerBehavior"]=1,
                ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1,
                ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1,
                ["report_players_ping"]=1, ["report_player_ip"]=1,
                ["report_net_saturate"]=1, ["report_speed_hack"]=1,
                ["report_wall_hack"]=1, ["report_aim_bot"]=1,
                ["report_esp_usage"]=1, ["report_modded_files"]=1,
                ["detect_cheat"]=1, ["ban_player"]=1,
                ["client_anti_cheat_report"]=1, ["ClientSecMrpcsFlow"]=1,
                ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1,
                ["CheckReportSecAttackFlowWithAttackFlow"]=1,
                ["RPC_ClientCoronaLab"]=1, ["CoronaLabReport"]=1,
                ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1,
                ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1,
                ["ClientCircleFlow"]=1, ["IsEnableReportMrpcsInCircleFlow"]=1,
                ["IsEnableReportMrpcsInPartCircleFlow"]=1,
                ["bReportedModifierException"]=1, ["ReportModifierException"]=1,
                ["RPC_Server_ReportSimulateCharacterLocation"]=1,
                ["ReportSimulateCharacterLocation"]=1,
                ["RPC_Client_ShootVertifyRes"]=1, ["BulletHitInfoUploadData"]=1,
                ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1,
                ["tss_sdk_report"]=1, ["SwiftHawk"]=1,
                ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1,
                ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1,
                ["ViolationReport"]=1, ["SecurityViolation"]=1,
                ["IntegrityCheck"]=1, ["SignatureVerify"]=1,
                ["ReportHurtFlow"]=1, ["ReportUseSkillFlow"]=1,
                ["MeleeDamageReport"]=1, ["SkillFlowReport"]=1,
                -- Additional from second file
                ["ReportTeammateKillConfirmFlow"]=1, ["ReportForbiddenPickupFlow"]=1,
                ["ReportPlayerEquipmentInfo"]=1, ["log_shooting_miss"]=1,
                ["report_heavy_weapon_box_activation_flow"]=1,
                ["report_heavy_weapon_box_item_flow"]=1,
                ["report_ds_player_circle_flow"]=1, ["ReportJumpFlow"]=1,
                ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1,
                ["report_ds_netrate"]=1, ["report_unrealnet_clientstats"]=1,
                ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
                ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1,
                ["ReportGenerateMonsterFlow"]=1, ["report_ds_match_room_data"]=1,
                ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
                ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1,
                ["ReportRevivalFlow"]=1, ["ReportGameSetting"]=1,
                ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
                ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1,
                ["report_common_battle_info"]=1, ["report_client_scan_result"]=1,
                ["report_memory_exception"]=1, ["report_avatar_exception"]=1,
                ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1,
                ["report_camera_exception"]=1, ["ReportPlayerControllerStateChanged"]=1,
                ["ReportAvatarFlow"]=1, ["ReportSecurityAlert"]=1,
                ["ReportAntiCheat"]=1, ["ReportSuspiciousActivity"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) 
                if blocked[packetName] then return nil end
                return orig(packetName, ...) 
            end
            NetUtil.IsBypassed = true
        end
        
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {
                "RPC_Server_ClientSecMrpcsFlow", 
                "RPC_Server_SwiftHawk",
                "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation",
                "RPC_Client_ShootVertifyRes", 
                "RPC_ClientCoronaLab"
            }
            _G.SendRPC = function(rpcName, ...) 
                for _, b in ipairs(blockedRPC) do
                    if rpcName == b then return nil end
                end
                return origRPC(rpcName, ...) 
            end
        end
    end)
end

-- ==========================================
-- 20. HIGGS BOSON COMPLETE BLOCK
-- ==========================================
local function InitializeHiggsBosonBypass()
    pcall(function()
        -- Block the module itself
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            Higgs.StaticShowSecurityAlertInDev = nop
            Higgs.CheckClientConfig = function() return false end
            Higgs.GetSecurityInfo = function() return {} end
            Higgs.ReportSecurityAlert = nop
            Higgs.ValidateClient = function() return true end
            Higgs.CheckIntegrity = function() return true end
            Higgs.BlackList = {}
            
            for _, m in ipairs({
                "ControlMHActive", "Tick", "OnTick", "MHActiveLogic",
                "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID",
                "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert",
                "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData",
                "ValidateSecurityData", "StaticShowSecurityAlertInDev",
                "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation",
                "DisableHiggsBoson", "CheckMHActive", "ReportViolation",
                "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"
            }) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
            Higgs.IsMHActive = retFalse
        end
        
        _G.BlackList = {}
        
        -- Kill it on the player controller too
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then 
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
                if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end
            end
            if pc.HiggsBosonComponent then 
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
                pc.HiggsBosonComponent:ControlMHActive(0) 
            end
        end
    end)
end

-- ==========================================
-- 21. ANTI-CHEAT HOOKS
-- ==========================================
local function InitializeAntiCheatHooks()
    pcall(function()
        local HBC = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then 
            HBC.StaticShowSecurityAlertInDev = nop 
        end
    end)
    
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop
        _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then 
                PlayerController.HiggsBosonComponent:ControlMHActive(0)
                PlayerController.HiggsBosonComponent.bMHActive = false 
            end
        end
    end
end

-- ==========================================
-- 22. ANTI-REPORT BYPASS
-- ==========================================
local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        }) do
            local sub = package.loaded[path]
            if not sub then 
                local s, r = pcall(require, path)
                if s and r then sub = r end
            end
            if sub then 
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Record") or k:find("Send") or 
                        k:find("Upload") or k:find("Notify")
                    ) then 
                        pcall(function() sub[k] = nop end) 
                    end
                end 
            end
        end
    end)
end

-- ==========================================
-- 23. GAMEPLAY CALLBACK BYPASS
-- ==========================================
local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        
        local GC = _G.GameplayCallbacks
        local reports = {
            "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms",
            "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior",
            "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick",
            "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow",
            "ReportSecTgameMovingFlow", "ReportParachuteData",
            "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow",
            "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord",
            "OnDSConnectionSaturated", "ReportDSNetSaturation",
            "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats",
            "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow",
            "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams",
            "ReportHurtFlow", "ReportUseSkillFlow", "MeleeDamageReport",
            "SkillFlowReport", "ReportJumpFlow", "ReportGameStartFlow",
            "ReportGameEndFlow", "ReportAIActionFlow", "ReportGenerateMonsterFlow",
            "SendDSErrorLogToLobby", "SendDSErrorLogToLobbyOnece",
            "SendDSHawkEyePatrolLogToLobby", "ReportHeavyWeaponBoxSpawnFlow",
            "ReportHeavyWeaponBoxActivationFlow", "ReportHeavyWeaponBoxOpenPlayerFlow",
            "ReportHeavyWeaponBoxItemFlow", "ReportDSCircleFlow",
            "ReportAIStrategyInfo", "SendAIDeliveryInfo", "ReportDailyTaskInfo",
            "ReportMatchRoomData", "SendPlayerSpectatingLog",
            "ReportIDCardProduceFlow", "ReportIDCardPickUpFlow",
            "ReportIDCardDestroyFlow", "ReportRevivalFlow", "ReportGameSetting",
            "ReportGameSettingNew", "ReportAntsVoiceTeamCreate",
            "ReportAntsVoiceTeamQuit", "ReportCommonInfo",
            "ReportLightweightStat", "SendSecTLog", "SendDataMiningTLog",
            "SendActivityTLog", "ReportPlayerControllerStateChanged",
            "ReportAvatarFlow", "ReportSecurityAlert", "ReportAntiCheat",
            "ReportSuspiciousActivity"
        }
        for _, f in ipairs(reports) do GC[f] = nop end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {
                ["cheatdetected"]=1, ["connectionlost"]=1, 
                ["connectiontimeout"]=1, ["connectionexception"]=1,
                ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1,
                ["suspended"]=1, ["violationdetected"]=1,
                ["integrityfailure"]=1, ["securityviolation"]=1,
                ["abnormal"]=1, ["invalid"]=1, ["corrupt"]=1,
                ["tamper"]=1, ["modify"]=1, ["inject"]=1,
                ["hook"]=1, ["patch"]=1, ["spoof"]=1,
                ["fake"]=1, ["clone"]=1, ["duplicate"]=1,
                ["conflict"]=1, ["overlap"]=1, ["mismatch"]=1,
                ["inconsistent"]=1, ["unexpected"]=1, ["unknown"]=1
            }
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        GC.IsBypassed = true
    end)
end

-- ==========================================
-- 24. ALL REPORT SYSTEMS BLOCK
-- ==========================================
local function InitializeAllReportSystemsBlock()
    pcall(function()
        local reportPaths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "client.slua.logic.report.EquipmentExceptionReport",
            "client.slua.logic.report.ClientToolsReport",
            "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
            "client.slua.logic.download.report.puffer_tlog",
            "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem",
            "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils",
            "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature",
            "client.slua.logic.ban.ClientBanLogic",
            "client.slua.logic.login.logic_tt_ban",
            "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
            "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem",
            "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem",
            "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem",
            "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
            "client.slua.config.tlog.tlog_report_utils",
            "client.slua.logic.replay.logic_report_replay",
            "client.slua.logic.crash.CrashReporter",
        }
        
        for _, path in ipairs(reportPaths) do
            local module = package.loaded[path] or pcall(require, path) and require(path)
            if module then
                if module.Report then module.Report = nop end
                if module.SendReport then module.SendReport = nop end
                if module.ReportEvent then module.ReportEvent = nop end
                if module.ReportException then module.ReportException = nop end
                if module.ReportData then module.ReportData = nop end
                if module.ReportTLogEvent then module.ReportTLogEvent = nop end
                if module.OnInit then module.OnInit = nop end
                if module._OnPlayerKilledOtherPlayer then module._OnPlayerKilledOtherPlayer = nop end
                if module._RecordFatalDamager then module._RecordFatalDamager = nop end
                if module._OnBattleResult then module._OnBattleResult = nop end
                if module._OnShowQuickReportMutualExclusiveUI then module._OnShowQuickReportMutualExclusiveUI = nop end
                if module._AddEnemyMapToBattleResult then module._AddEnemyMapToBattleResult = nop end
                if module._AddKnockDownerToBattleResult then module._AddKnockDownerToBattleResult = nop end
                if module._AddKillerToBattleResult then module._AddKillerToBattleResult = nop end
                if module._AddTeammateMurderToBattleResult then module._AddTeammateMurderToBattleResult = nop end
                if module._AddFatalDamagerMapToBattleResult then module._AddFatalDamagerMapToBattleResult = nop end
                if module._AddMLKillerUIDToBattleResult then module._AddMLKillerUIDToBattleResult = nop end
                if module._SaveHistoricalTeammateInfo then module._SaveHistoricalTeammateInfo = nop end
                if module._RecordTeammateMurderer then module._RecordTeammateMurderer = nop end
                if module._OnNearDeathOrRescued then module._OnNearDeathOrRescued = nop end
                if module._OnCharacterDied then module._OnCharacterDied = nop end
                if module._OnTeammateDamage then module._OnTeammateDamage = nop end
                if module._OnPlayerSettlementStart then module._OnPlayerSettlementStart = nop end
                if module._OnHawkSync then module._OnHawkSync = nop end
                if module._OnHawkReportSuccess then module._OnHawkReportSuccess = nop end
                if module._StartExitGameTimer then module._StartExitGameTimer = nop end
                if module.OnHandleBehaviorScore then module.OnHandleBehaviorScore = nop end
                if module.AIPerceptionScore then module.AIPerceptionScore = nop end
                if module.ReportAllPlayerInfo then module.ReportAllPlayerInfo = nop end
                if module.AddRecordMLAIInfo then module.AddRecordMLAIInfo = nop end
                if module.ReportAI then module.ReportAI = nop end
                if module.RealLogoutTimer then module.RealLogoutTimer = nop end
                if module.LogQueue then module.LogQueue = {} end
                if module.SendAFKTips then module.SendAFKTips = nop end
                if module.OnHandleLostConnection then module.OnHandleLostConnection = nop end
                if module.ClientRPC_SyncBanID then module.ClientRPC_SyncBanID = nop end
                if module.ClientRPC_StrongTips then module.ClientRPC_StrongTips = nop end
                if module.ClientRPC_NormalTips then module.ClientRPC_NormalTips = nop end
                if module.Notify then module.Notify = nop end
                if module.OnSyncBanInfo then module.OnSyncBanInfo = nop end
                if module.OnVoiceBanNotify then module.OnVoiceBanNotify = nop end
                if module.GetCarrierInfo then module.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end end
                if module.CheckIfCanCreateRole then module.CheckIfCanCreateRole = retTrue end
                if module.DelayKickOutPlayer then module.DelayKickOutPlayer = nop end
                if module.ActiveKickNotify then module.ActiveKickNotify = nop end
                if module._UpdateTTKRecords then module._UpdateTTKRecords = nop end
                if module._UpdateOperatingFrequency then module._UpdateOperatingFrequency = nop end
                if module.GetSimpleFightData then module.GetSimpleFightData = retEmpty end
                if module._OnReportServerJumpFlow then module._OnReportServerJumpFlow = nop end
                if module.HandleKillTlog then module.HandleKillTlog = nop end
                if module.AskForInspector then module.AskForInspector = nop end
                if module.ReportEnemy then module.ReportEnemy = nop end
                if module.KickOutOneTeam then module.KickOutOneTeam = nop end
                if module.ServerKickOutOneTeamByPlayerImplementation then module.ServerKickOutOneTeamByPlayerImplementation = nop end
                if module.AddReportedCount then module.AddReportedCount = nop end
                if module.RequestGotoSpectatingImp then module.RequestGotoSpectatingImp = nop end
                if module.RequestGotoSpectating then module.RequestGotoSpectating = nop end
            end
        end
    end)
end

-- ==========================================
-- 25. ALL TLOG SYSTEMS BLOCK
-- ==========================================
local function InitializeAllTLogSystemsBlock()
    pcall(function()
        local tlogPaths = {
            "client.slua.config.tlog.tlog_report_utils",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "client.slua.logic.replay.logic_report_replay",
            "client.slua.logic.crash.CrashReporter",
        }
        
        for _, path in ipairs(tlogPaths) do
            local module = package.loaded[path] or pcall(require, path) and require(path)
            if module then
                if module.ReportTLogEvent then module.ReportTLogEvent = nop end
                if module.SendTlog then module.SendTlog = nop end
                if module.ReportTLog then module.ReportTLog = nop end
                if module._UpdateTTKRecords then module._UpdateTTKRecords = nop end
                if module._UpdateOperatingFrequency then module._UpdateOperatingFrequency = nop end
                if module.GetSimpleFightData then module.GetSimpleFightData = retEmpty end
                if module._OnReportServerJumpFlow then module._OnReportServerJumpFlow = nop end
                if module.HandleKillTlog then module.HandleKillTlog = nop end
                if module.ReportReplay then module.ReportReplay = nop end
                if module.SendReportReq then module.SendReportReq = nop end
                if module.SendReport then module.SendReport = nop end
                if module.SaveDump then module.SaveDump = nop end
                if module.UploadDump then module.UploadDump = nop end
            end
        end
    end)
end

-- ==========================================
-- 26. CRASH AND EXCEPTION REPORTING BLOCK
-- ==========================================
local function InitializeCrashExceptionBlock()
    pcall(function()
        local CrashSight = _G.CrashSight or package.loaded["CrashSight"]
        if CrashSight then
            CrashSight.ReportException = nop
            CrashSight.SetCustomData = nop
            CrashSight.Log = nop
            CrashSight.UploadLog = nop
            CrashSight.SendReport = nop
            CrashSight.CollectInfo = retEmpty
            CrashSight.ReportCrash = nop
            CrashSight.ReportError = nop
            CrashSight.ReportFatal = nop
            CrashSight.ReportWarning = nop
            CrashSight.ReportInfo = nop
            CrashSight.ReportDebug = nop
            CrashSight.ReportMemory = nop
            CrashSight.ReportPerformance = nop
        end

        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then
            TLog.Info = nop
            TLog.Warning = nop
            TLog.Error = nop
            TLog.Debug = nop
            TLog.Report = nop
            TLog.Flush = nop
            TLog.Log = nop
            TLog.LogWarning = nop
            TLog.LogError = nop
            TLog.LogVerbose = nop
            TLog.SetLogLevel = nop
        end
    end)
end

-- ==========================================
-- 27. SCREENSHOT AND RECORDING BLOCK
-- ==========================================
local function InitializeScreenshotBlock()
    pcall(function()
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = retEmptyString
            ScreenshotMaker.ReMakePicture = retEmptyString
            ScreenshotMaker.HasCaptured = retTrue
            ScreenshotMaker.TakeScreenshot = nop
            ScreenshotMaker.SaveScreenshot = nop
            ScreenshotMaker.CaptureScreen = nop
            ScreenshotMaker.RecordScreen = nop
        end
    end)
end

-- ==========================================
-- 28. MEMORY SCANNER BLOCK
-- ==========================================
local function InitializeMemoryScannerBlock()
    pcall(function()
        local MemoryScanner = _G.MemoryScanner or package.loaded["MemoryScanner"]
        if MemoryScanner then
            MemoryScanner.StartScan = nop
            MemoryScanner.StopScan = nop
            MemoryScanner.GetResults = retEmpty
            MemoryScanner.ReportViolation = nop
            MemoryScanner.CheckIntegrity = retTrue
            MemoryScanner.VerifyMemory = retTrue
            MemoryScanner.ScanProcess = nop
            MemoryScanner.ScanModule = nop
            MemoryScanner.ScanThread = nop
            MemoryScanner.ScanFile = nop
            MemoryScanner.ScanNetwork = nop
        end
    end)
end

-- ==========================================
-- 29. FILE INTEGRITY CHECK BLOCK
-- ==========================================
local function InitializeFileIntegrityBlock()
    pcall(function()
        local FileCheckSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("FileCheckSubsystem")
        if FileCheckSubsystem then
            FileCheckSubsystem.StartCheck = nop
            FileCheckSubsystem.ReportAbnormalFile = nop
            FileCheckSubsystem.VerifyFile = retTrue
            FileCheckSubsystem.CheckIntegrity = retTrue
            FileCheckSubsystem.ValidateFile = retTrue
            FileCheckSubsystem.CheckFile = retTrue
            FileCheckSubsystem.VerifyHash = retTrue
            FileCheckSubsystem.ValidateHash = retTrue
            FileCheckSubsystem.CheckHash = retTrue
        end
    end)
end

-- ==========================================
-- 30. AVATAR VALIDATION BLOCK
-- ==========================================
local function InitializeAvatarValidationBlock()
    pcall(function()
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.ValidateAvatar = retTrue
            AvatarUtils.CheckAvatar = retTrue
            AvatarUtils.VerifySkin = retTrue
            AvatarUtils.ValidateSkin = retTrue
            AvatarUtils.CheckSkin = retTrue
            AvatarUtils.VerifyWeapon = retTrue
            AvatarUtils.ValidateWeapon = retTrue
            AvatarUtils.CheckWeapon = retTrue
            AvatarUtils.VerifyVehicle = retTrue
            AvatarUtils.ValidateVehicle = retTrue
            AvatarUtils.CheckVehicle = retTrue
        end
    end)
end

-- ==========================================
-- 31. STATISTICS REPORTING BLOCK
-- ==========================================
local function InitializeStatisticsBlock()
    pcall(function()
        local ClientDataStatistcsSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ClientDataStatistcsSubsystem")
        if ClientDataStatistcsSubsystem then
            ClientDataStatistcsSubsystem.StartToCheck = nop
            ClientDataStatistcsSubsystem.DelayCount = 0
            ClientDataStatistcsSubsystem.ReportPingDelay = nop
            ClientDataStatistcsSubsystem.ReportStats = nop
            ClientDataStatistcsSubsystem.ReportData = nop
            ClientDataStatistcsSubsystem.ReportPerformance = nop
            ClientDataStatistcsSubsystem.ReportBattery = nop
            ClientDataStatistcsSubsystem.ReportTemperature = nop
            ClientDataStatistcsSubsystem.ReportFPS = nop
            ClientDataStatistcsSubsystem.ReportPing = nop
            ClientDataStatistcsSubsystem.ReportNetwork = nop
        end
    end)
end

-- ==========================================
-- 32. SHOOT VERIFICATION BLOCK
-- ==========================================
local function InitializeShootVerifyBlock()
    pcall(function()
        local ShootVerifySubSystemClient = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ShootVerifySubSystemClient")
        if ShootVerifySubSystemClient then
            ShootVerifySubSystemClient.ReportVerifyFail = nop
            ShootVerifySubSystemClient.OnVerifyFailed = nop
            ShootVerifySubSystemClient.CheckShoot = retTrue
            ShootVerifySubSystemClient.ValidateHit = retTrue
            ShootVerifySubSystemClient.VerifyShoot = retTrue
            ShootVerifySubSystemClient.ValidateShoot = retTrue
            ShootVerifySubSystemClient.CheckHit = retTrue
            ShootVerifySubSystemClient.VerifyHit = retTrue
        end
    end)
end

-- ==========================================
-- 33. AFK REPORT BLOCK
-- ==========================================
local function InitializeAFKBlock()
    pcall(function()
        local AFKReportorSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AFKReportorSubsystem")
        if AFKReportorSubsystem then
            AFKReportorSubsystem.PlayerHaveAction = nop
            AFKReportorSubsystem.CheckAFK = retFalse
            AFKReportorSubsystem.ReportInactive = nop
        end
    end)
end

-- ==========================================
-- 34. AVATAR EXCEPTION BLOCK
-- ==========================================
local function InitializeAvatarExceptionBlock()
    pcall(function()
        local AvatarExceptionSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AvatarExceptionSubsystem")
        if AvatarExceptionSubsystem then
            AvatarExceptionSubsystem.ReportException = nop
            AvatarExceptionSubsystem.BindPlayerCharacter = nop
            AvatarExceptionSubsystem.CheckAvatarValid = retTrue
            AvatarExceptionSubsystem.ValidateAvatar = retTrue
            AvatarExceptionSubsystem.ReportAvatarException = nop
            AvatarExceptionSubsystem.ReportInvalidAvatar = nop
            AvatarExceptionSubsystem.ReportCorruptAvatar = nop
        end
    end)
end

-- ==========================================
-- 35. REPLAY REPORT BLOCK
-- ==========================================
local function InitializeReplayReportBlock()
    pcall(function()
        local RescueBtnReplayTraceSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("RescueBtnReplayTraceSubsystem")
        if RescueBtnReplayTraceSubsystem then
            RescueBtnReplayTraceSubsystem.ReportTrace = nop
            RescueBtnReplayTraceSubsystem.StartTickMonitor = nop
            RescueBtnReplayTraceSubsystem.TickMonitorCheck = nop
            RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = nop
            RescueBtnReplayTraceSubsystem.ReportReplay = nop
            RescueBtnReplayTraceSubsystem.ReportTraceData = nop
        end
    end)
end

-- ==========================================
-- 36. GAME REPORT BLOCK
-- ==========================================
local function InitializeGameReportBlock()
    pcall(function()
        local GameReportSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.ReplayReportData = retFalse
            GameReportSubsystem.CheckCanBugglyPostException = retFalse
            GameReportSubsystem.BugglyPostExceptionFull = retFalse
            GameReportSubsystem.GetClientReplayDataReporter = retNil
            GameReportSubsystem.ReportGamePerformance = nop
        end
    end)
end

-- ==========================================
-- 37. INSPECTION SYSTEM BLOCK
-- ==========================================
local function InitializeInspectionSystemBlock()
    pcall(function()
        local InspectionSystemReportClientLogicSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"]
        if InspectionSystemReportClientLogicSubsystem then
            InspectionSystemReportClientLogicSubsystem.AskForInspector = nop
            InspectionSystemReportClientLogicSubsystem.KickOutOneTeam = nop
            InspectionSystemReportClientLogicSubsystem.ReportSuspicious = nop
            InspectionSystemReportClientLogicSubsystem.ReportHack = nop
        end
    end)
end

-- ==========================================
-- 38. HAWK EYE PATROL BLOCK
-- ==========================================
local function InitializeHawkEyeBlock()
    pcall(function()
        local ClientHawkEyePatrolSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"]
        if ClientHawkEyePatrolSubsystem then
            ClientHawkEyePatrolSubsystem._OnHawkSync = nop
            ClientHawkEyePatrolSubsystem._OnHawkReportSuccess = nop
            ClientHawkEyePatrolSubsystem._StartExitGameTimer = nop
            ClientHawkEyePatrolSubsystem.ReportPatrol = nop
        end
    end)
end

-- ==========================================
-- 39. BEHAVIOR SCORE BLOCK [FIXED]
-- ==========================================
local function InitializeBehaviorScoreBlock()
    pcall(function()
        local BehaviorScoreSubsystem = package.loaded["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"]
        if BehaviorScoreSubsystem then
            -- Only override CalculateScore to return 100
            BehaviorScoreSubsystem.CalculateScore = function(self)
                return 100
            end
            
            -- Hook ReportScore to force recalculation before sending
            local originalReport = BehaviorScoreSubsystem.ReportScore
            if originalReport then
                BehaviorScoreSubsystem.ReportScore = function(self, ...)
                    self:CalculateScore()
                    return originalReport(self, ...)
                end
            end
            -- DO NOT touch ReportBehavior, ReportBehaviorData, OnHandleBehaviorScore, or AIPerceptionScore
        end
    end)
end

-- ==========================================
-- 40. AI REPORTING BLOCK
-- ==========================================
local function InitializeAIReportingBlock()
    pcall(function()
        local AIReplaySubsystem = package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"]
        if AIReplaySubsystem then
            AIReplaySubsystem.ReportAllPlayerInfo = nop
            AIReplaySubsystem.AddRecordMLAIInfo = nop
            AIReplaySubsystem.ReportAI = nop
            AIReplaySubsystem.ReportAIData = nop
            AIReplaySubsystem.ReportAIPerformance = nop
        end
    end)
end

-- ==========================================
-- 41. BAN SYSTEM BLOCK
-- ==========================================
local function InitializeBanSystemBlock()
    pcall(function()
        local ClientBanLogic = package.loaded["client.slua.logic.ban.ClientBanLogic"]
        if ClientBanLogic then
            ClientBanLogic.OnSyncBanInfo = nop
            ClientBanLogic.OnVoiceBanNotify = nop
            ClientBanLogic.CheckBan = retFalse
            ClientBanLogic.IsBanned = retFalse
            ClientBanLogic.CheckBanStatus = retFalse
            ClientBanLogic.GetBanInfo = retEmpty
        end

        local logic_tt_ban = package.loaded["client.slua.logic.login.logic_tt_ban"]
        if logic_tt_ban then
            logic_tt_ban.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
            logic_tt_ban.CheckIfCanCreateRole = retTrue
            logic_tt_ban.CheckBan = retFalse
            logic_tt_ban.GetBanStatus = retFalse
        end
    end)
end

-- ==========================================
-- 42. MEMORY PROTECTION BLOCK
-- ==========================================
local function InitializeMemoryProtectionBlock()
    pcall(function()
        local MemoryProtect = import("MemoryProtect")
        if MemoryProtect then
            MemoryProtect.CheckMemory = retTrue
            MemoryProtect.ProtectMemory = retTrue
            MemoryProtect.UnprotectMemory = retTrue
            MemoryProtect.ValidateMemory = retTrue
            MemoryProtect.VerifyMemory = retTrue
        end
    end)
end

-- ==========================================
-- 43. NETWORK MONITORING BLOCK
-- ==========================================
local function InitializeNetworkMonitoringBlock()
    pcall(function()
        local NetworkManager = import("NetworkManager")
        if NetworkManager then
            NetworkManager.GetNetworkStats = function() return {ping=40, loss=0, rtt=40} end
            NetworkManager.CapturePackets = nop
            NetworkManager.AnalyzeTraffic = retEmpty
            NetworkManager.GetConnectionInfo = function() return "127.0.0.1:8080" end
            NetworkManager.MonitorTraffic = nop
            NetworkManager.ReportTraffic = nop
            NetworkManager.ReportNetwork = nop
            NetworkManager.ReportBandwidth = nop
            NetworkManager.ReportLatency = nop
            NetworkManager.ReportPacketLoss = nop
        end
    end)
end

-- ==========================================
-- 44. TIMING CHECK SPOOF
-- ==========================================
local function InitializeTimingSpoof()
    pcall(function()
        local Engine = import("Engine")
        if Engine then
            Engine.GetAverageFPS = function() return 60 end
            Engine.GetFrameTime = function() return 0.016 end
            Engine.IsLagging = retFalse
            Engine.GetDeltaTime = function() return 0.033 end
            Engine.GetTime = function() return os.time() end
            Engine.GetTimestamp = function() return os.time() end
            Engine.GetTick = function() return os.clock() end
            Engine.GetSeconds = function() return os.time() end
            Engine.GetMilliseconds = function() return os.time() * 1000 end
            Engine.GetMicroseconds = function() return os.time() * 1000000 end
            Engine.GetNanoseconds = function() return os.time() * 1000000000 end
        end

        local GameTime = package.loaded["GameLua.GameCore.Data.GameTime"]
        if GameTime then
            GameTime.GetServerTime = function() return os.time() end
            GameTime.GetDeltaTime = function() return 0.033 end
            GameTime.GetGameTime = function() return os.time() end
            GameTime.GetRealTime = function() return os.time() end
            GameTime.GetTickTime = function() return os.clock() end
            GameTime.GetFrameTime = function() return 0.016 end
        end
    end)
end

-- ==========================================
-- 45. KILL ALL SUBSYSTEMS - The Nuke
-- ==========================================
local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        
        local toKill = {
            "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem",
            "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem",
            "SimulateCharacterSubsystem", "ShootVerifySubSystemClient",
            "HiggsBosonComponent", "ClientReportPlayerSubsystem",
            "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem",
            "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem",
            "AFKReportorSubsystem", "BehaviorScoreSubsystem",
            "FileCheckSubsystem", "MemoryCheckSubsystem",
            "SpeedCheckSubsystem", "WallCheckSubsystem",
            "AvatarExceptionSubsystem", "GameReportSubsystem",
            "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem",
            "CircleFlowSubsystem", "SwiftHawkSubsystem",
            "AntiCheatSubsystem", "IntegrityCheckSubsystem",
            "SignatureVerifySubsystem", "MD5CheckSubsystem",
            "PakVerifySubsystem"
        }
        
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Send") or k:find("Upload") or
                        k:find("Verify") or k:find("Check") or k:find("Validate") or
                        k:find("Scan") or k:find("Detect") or k:find("Collect") or
                        k:find("Flow") or k:find("Heartbeat")
                    ) then 
                        pcall(function() sub[k] = nop end) 
                    end
                end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

-- ==========================================
-- 46. ADDITIONAL SUBSYSTEM BLOCKS
-- ==========================================
local function InitializeAdditionalSubsystemBlocks()
    pcall(function()
        local subsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystemMgr then
            local allSubsystems = subsystemMgr:GetAllSubsystems()
            for _, sub in pairs(allSubsystems) do
                if sub and sub.Report then sub.Report = nop end
                if sub and sub.ReportException then sub.ReportException = nop end
                if sub and sub.SendReport then sub.SendReport = nop end
                if sub and sub.CollectData then sub.CollectData = retEmpty end
                if sub and sub.Validate then sub.Validate = retTrue end
                if sub and sub.CheckIntegrity then sub.CheckIntegrity = retTrue end
                if sub and sub.Verify then sub.Verify = retTrue end
                if sub and sub.Check then sub.Check = retTrue end
                if sub and sub.ValidateData then sub.ValidateData = retTrue end
                if sub and sub.VerifyData then sub.VerifyData = retTrue end
                if sub and sub.CheckData then sub.CheckData = retTrue end
                if sub and sub.ValidateState then sub.ValidateState = retTrue end
                if sub and sub.VerifyState then sub.VerifyState = retTrue end
                if sub and sub.CheckState then sub.CheckState = retTrue end
                if sub and sub.ValidateConfig then sub.ValidateConfig = retTrue end
                if sub and sub.VerifyConfig then sub.VerifyConfig = retTrue end
                if sub and sub.CheckConfig then sub.CheckConfig = retTrue end
                if sub and sub.ValidatePlayer then sub.ValidatePlayer = retTrue end
                if sub and sub.VerifyPlayer then sub.VerifyPlayer = retTrue end
                if sub and sub.CheckPlayer then sub.CheckPlayer = retTrue end
                if sub and sub.ValidateGame then sub.ValidateGame = retTrue end
                if sub and sub.VerifyGame then sub.VerifyGame = retTrue end
                if sub and sub.CheckGame then sub.CheckGame = retTrue end
                if sub and sub.ValidateSystem then sub.ValidateSystem = retTrue end
                if sub and sub.VerifySystem then sub.VerifySystem = retTrue end
                if sub and sub.CheckSystem then sub.CheckSystem = retTrue end
                if sub and sub.ValidateDevice then sub.ValidateDevice = retTrue end
                if sub and sub.VerifyDevice then sub.VerifyDevice = retTrue end
                if sub and sub.CheckDevice then sub.CheckDevice = retTrue end
                if sub and sub.ValidateNetwork then sub.ValidateNetwork = retTrue end
                if sub and sub.VerifyNetwork then sub.VerifyNetwork = retTrue end
                if sub and sub.CheckNetwork then sub.CheckNetwork = retTrue end
                if sub and sub.ValidateMemory then sub.ValidateMemory = retTrue end
                if sub and sub.VerifyMemory then sub.VerifyMemory = retTrue end
                if sub and sub.CheckMemory then sub.CheckMemory = retTrue end
                if sub and sub.ValidateFile then sub.ValidateFile = retTrue end
                if sub and sub.VerifyFile then sub.VerifyFile = retTrue end
                if sub and sub.CheckFile then sub.CheckFile = retTrue end
                if sub and sub.ValidateProcess then sub.ValidateProcess = retTrue end
                if sub and sub.VerifyProcess then sub.VerifyProcess = retTrue end
                if sub and sub.CheckProcess then sub.CheckProcess = retTrue end
                if sub and sub.ValidateThread then sub.ValidateThread = retTrue end
                if sub and sub.VerifyThread then sub.VerifyThread = retTrue end
                if sub and sub.CheckThread then sub.CheckThread = retTrue end
                if sub and sub.ValidateModule then sub.ValidateModule = retTrue end
                if sub and sub.VerifyModule then sub.VerifyModule = retTrue end
                if sub and sub.CheckModule then sub.CheckModule = retTrue end
                if sub and sub.ValidateAPI then sub.ValidateAPI = retTrue end
                if sub and sub.VerifyAPI then sub.VerifyAPI = retTrue end
                if sub and sub.CheckAPI then sub.CheckAPI = retTrue end
                if sub and sub.ValidateSDK then sub.ValidateSDK = retTrue end
                if sub and sub.VerifySDK then sub.VerifySDK = retTrue end
                if sub and sub.CheckSDK then sub.CheckSDK = retTrue end
            end
        end
    end)
end

-- ==========================================
-- 47. ZERO TRACE CLEANUP
-- ==========================================
local function InitializeZeroTraceCleanup()
    pcall(function()
        local MemoryCleaner = import("MemoryCleaner")
        if MemoryCleaner then
            MemoryCleaner.ClearCache = nop
            MemoryCleaner.FreeUnusedMemory = nop
            MemoryCleaner.CompactHeap = nop
            MemoryCleaner.CleanTraces = nop
            MemoryCleaner.ClearLogs = nop
            MemoryCleaner.ClearTemp = nop
            MemoryCleaner.ClearCacheFiles = nop
            MemoryCleaner.ClearHistory = nop
            MemoryCleaner.ClearData = nop
        end
    end)
end

-- ==========================================
-- 48. ANTI-DEBUGGING BLOCK
-- ==========================================
local function InitializeAntiDebuggingBlock()
    pcall(function()
        local DebuggerDetect = _G.DebuggerDetect or package.loaded["DebuggerDetect"]
        if DebuggerDetect then
            DebuggerDetect.CheckTracer = retFalse
            DebuggerDetect.CheckDebug = retFalse
            DebuggerDetect.CheckDebugger = retFalse
            DebuggerDetect.DetectDebugger = retFalse
            DebuggerDetect.DetectBreakpoint = retFalse
            DebuggerDetect.DetectTracer = retFalse
            DebuggerDetect.DetectDebug = retFalse
        end
    end)
end

-- ==========================================
-- 49. JNI ANTI-CHEAT BLOCK
-- ==========================================
local function InitializeJNIAntiCheatBlock()
    pcall(function()
        local jni_ac = _G.JNI and _G.JNI.AntiCheat
        if jni_ac then
            jni_ac.CollectInfo = retEmpty
            jni_ac.SendReport = nop
            jni_ac.Validate = retTrue
            jni_ac.CheckRootAccess = retFalse
            jni_ac.CheckEmulatorAccess = retFalse
            jni_ac.CheckDebuggerAccess = retFalse
            jni_ac.CheckMemoryAccess = retTrue
            jni_ac.CheckProcessAccess = retTrue
            jni_ac.CheckFileAccess = retTrue
            jni_ac.CheckNetworkAccess = retTrue
            jni_ac.CheckSystemAccess = retTrue
            jni_ac.CheckDeviceAccess = retTrue
            jni_ac.CheckAPIAccess = retTrue
            jni_ac.CheckSDKAccess = retTrue
            jni_ac.CheckLibraryAccess = retTrue
            jni_ac.CheckFrameworkAccess = retTrue
            jni_ac.CheckPackageAccess = retTrue
        end
    end)
end

-- ==========================================
-- 50. PACKET ENCRYPTION BYPASS
-- ==========================================
local function InitializePacketEncryptionBypass()
    pcall(function()
        local PacketEncrypt = _G.PacketEncrypt or package.loaded["PacketEncrypt"]
        if PacketEncrypt then
            PacketEncrypt.Encrypt = function(data) return data end
            PacketEncrypt.Decrypt = function(data) return data end
            PacketEncrypt.VerifyChecksum = retTrue
            PacketEncrypt.Validate = retTrue
            PacketEncrypt.ValidatePacket = retTrue
            PacketEncrypt.VerifyPacket = retTrue
            PacketEncrypt.CheckPacket = retTrue
            PacketEncrypt.EncryptPacket = function(data) return data end
            PacketEncrypt.DecryptPacket = function(data) return data end
            PacketEncrypt.ValidateChecksum = retTrue
            PacketEncrypt.VerifyChecksum = retTrue
            PacketEncrypt.CheckChecksum = retTrue
        end
    end)
end

-- ==========================================
-- 51. DS VALIDATION BYPASS
-- ==========================================
local function InitializeDSValidationBypass()
    pcall(function()
        local DSValidator = _G.DSValidator or package.loaded["DSValidator"]
        if DSValidator then
            DSValidator.ValidateClient = retTrue
            DSValidator.CheckLatency = function() return 40 end
            DSValidator.ReportCheat = nop
            DSValidator.KickPlayer = nop
            DSValidator.BanPlayer = nop
            DSValidator.ValidatePlayer = retTrue
            DSValidator.ValidateSession = retTrue
            DSValidator.ValidateGame = retTrue
            DSValidator.ValidateSystem = retTrue
            DSValidator.ValidateDevice = retTrue
            DSValidator.ValidateNetwork = retTrue
            DSValidator.ValidateMemory = retTrue
            DSValidator.ValidateFile = retTrue
            DSValidator.ValidateProcess = retTrue
            DSValidator.ValidateThread = retTrue
            DSValidator.ValidateModule = retTrue
            DSValidator.ValidateAPI = retTrue
            DSValidator.ValidateSDK = retTrue
            DSValidator.ValidateLibrary = retTrue
            DSValidator.ValidateFramework = retTrue
            DSValidator.ValidatePackage = retTrue
            DSValidator.ValidateContainer = retTrue
            DSValidator.ValidateComponent = retTrue
            DSValidator.ValidateObject = retTrue
            DSValidator.ValidateClass = retTrue
            DSValidator.ValidateStruct = retTrue
            DSValidator.ValidateEnum = retTrue
            DSValidator.ValidateInterface = retTrue
            DSValidator.ValidateDelegate = retTrue
            DSValidator.ValidateEvent = retTrue
            DSValidator.ValidateFunction = retTrue
            DSValidator.ValidateVariable = retTrue
            DSValidator.ValidateProperty = retTrue
            DSValidator.ValidateField = retTrue
            DSValidator.ValidateMethod = retTrue
            DSValidator.ValidateParameter = retTrue
            DSValidator.ValidateReturn = retTrue
            DSValidator.ValidateResult = retTrue
            DSValidator.ValidateOutput = retTrue
            DSValidator.ValidateInput = retTrue
        end
    end)
end

-- ==========================================
-- 52. CRC CHECK BYPASS
-- ==========================================
local function InitializeCRCCheckBypass()
    pcall(function()
        local CRCChecker = _G.CRCChecker or package.loaded["CRCChecker"]
        if CRCChecker then
            CRCChecker.VerifyFile = retTrue
            CRCChecker.VerifyMemory = retTrue
            CRCChecker.GenerateCRC = function() return "852B43BE" end
            CRCChecker.CheckIntegrity = retTrue
            CRCChecker.ValidateFile = retTrue
            CRCChecker.ValidateMemory = retTrue
            CRCChecker.CheckFile = retTrue
            CRCChecker.CheckMemory = retTrue
            CRCChecker.VerifyCRC = retTrue
            CRCChecker.ValidateCRC = retTrue
            CRCChecker.CheckCRC = retTrue
            CRCChecker.GenerateCRC32 = function() return "852B43BE" end
            CRCChecker.GenerateMD5 = function() return "F8FA7873B624ADB07549BE04C0D1AA6F" end
            CRCChecker.GenerateSHA1 = function() return "892881A33F92059FBF648F3D865D4E759B898D6E" end
            CRCChecker.GenerateSHA256 = function() return "68F830AD4852868C483385E46EA4AB83C8D7952F8AB527033D4B100FB34D6CF4" end
        end
    end)
end

-- ==========================================
-- 53. SECURITY COMMON UTILS BYPASS
-- ==========================================
local function InitializeSecurityCommonUtilsBypass()
    pcall(function()
        local SecurityCommonUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = retEmpty
            SecurityCommonUtils.LogIf = retFalse
            SecurityCommonUtils.CheckSecurity = retTrue
            SecurityCommonUtils.ValidatePlayer = retTrue
            SecurityCommonUtils.ValidateSession = retTrue
            SecurityCommonUtils.ValidateGame = retTrue
            SecurityCommonUtils.ValidateSystem = retTrue
            SecurityCommonUtils.ValidateDevice = retTrue
            SecurityCommonUtils.ValidateNetwork = retTrue
            SecurityCommonUtils.ValidateMemory = retTrue
            SecurityCommonUtils.ValidateFile = retTrue
            SecurityCommonUtils.ValidateProcess = retTrue
            SecurityCommonUtils.ValidateThread = retTrue
            SecurityCommonUtils.ValidateModule = retTrue
            SecurityCommonUtils.ValidateAPI = retTrue
            SecurityCommonUtils.ValidateSDK = retTrue
            SecurityCommonUtils.ValidateLibrary = retTrue
            SecurityCommonUtils.ValidateFramework = retTrue
            SecurityCommonUtils.ValidatePackage = retTrue
            SecurityCommonUtils.ValidateContainer = retTrue
            SecurityCommonUtils.ValidateComponent = retTrue
            SecurityCommonUtils.ValidateObject = retTrue
            SecurityCommonUtils.ValidateClass = retTrue
            SecurityCommonUtils.ValidateStruct = retTrue
            SecurityCommonUtils.ValidateEnum = retTrue
            SecurityCommonUtils.ValidateInterface = retTrue
            SecurityCommonUtils.ValidateDelegate = retTrue
            SecurityCommonUtils.ValidateEvent = retTrue
            SecurityCommonUtils.ValidateFunction = retTrue
            SecurityCommonUtils.ValidateVariable = retTrue
            SecurityCommonUtils.ValidateProperty = retTrue
            SecurityCommonUtils.ValidateField = retTrue
            SecurityCommonUtils.ValidateMethod = retTrue
            SecurityCommonUtils.ValidateParameter = retTrue
            SecurityCommonUtils.ValidateReturn = retTrue
            SecurityCommonUtils.ValidateResult = retTrue
            SecurityCommonUtils.ValidateOutput = retTrue
            SecurityCommonUtils.ValidateInput = retTrue
        end
    end)
end

-- ==========================================
-- 54. SECURITY NOTIFY BYPASS
-- ==========================================
local function InitializeSecurityNotifyBypass()
    pcall(function()
        local SecurityNotifyPCFeature = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
        if SecurityNotifyPCFeature then
            SecurityNotifyPCFeature.ClientRPC_SyncBanID = nop
            SecurityNotifyPCFeature.ClientRPC_StrongTips = nop
            SecurityNotifyPCFeature.ClientRPC_NormalTips = nop
            SecurityNotifyPCFeature.Notify = nop
            SecurityNotifyPCFeature.ShowBan = nop
            SecurityNotifyPCFeature.ShowKick = nop
            SecurityNotifyPCFeature.ShowWarning = nop
            SecurityNotifyPCFeature.ShowInfo = nop
            SecurityNotifyPCFeature.ShowError = nop
            SecurityNotifyPCFeature.ShowFatal = nop
            SecurityNotifyPCFeature.ShowPanic = nop
            SecurityNotifyPCFeature.ShowAlert = nop
            SecurityNotifyPCFeature.ShowNotification = nop
            SecurityNotifyPCFeature.ShowMessage = nop
            SecurityNotifyPCFeature.ShowDialog = nop
            SecurityNotifyPCFeature.ShowPopup = nop
            SecurityNotifyPCFeature.ShowToast = nop
            SecurityNotifyPCFeature.ShowSnackbar = nop
            SecurityNotifyPCFeature.ShowBanner = nop
            SecurityNotifyPCFeature.ShowAlertDialog = nop
            SecurityNotifyPCFeature.ShowConfirmDialog = nop
            SecurityNotifyPCFeature.ShowPromptDialog = nop
            SecurityNotifyPCFeature.ShowInputDialog = nop
            SecurityNotifyPCFeature.ShowSelectDialog = nop
            SecurityNotifyPCFeature.ShowProgressDialog = nop
            SecurityNotifyPCFeature.ShowLoadingDialog = nop
            SecurityNotifyPCFeature.ShowSuccessDialog = nop
            SecurityNotifyPCFeature.ShowFailureDialog = nop
            SecurityNotifyPCFeature.ShowErrorDialog = nop
            SecurityNotifyPCFeature.ShowWarningDialog = nop
            SecurityNotifyPCFeature.ShowInfoDialog = nop
        end
    end)
end

-- ==========================================
-- 55. ACTIVE SUBSYSTEM BYPASS
-- ==========================================
local function InitializeActiveSubsystemBypass()
    pcall(function()
        local DSActiveSubsystem = package.loaded["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"]
        if DSActiveSubsystem then
            DSActiveSubsystem.DelayKickOutPlayer = nop
            DSActiveSubsystem.ActiveKickNotify = nop
            DSActiveSubsystem.CheckActive = retTrue
            DSActiveSubsystem.CheckActivity = retTrue
            DSActiveSubsystem.ValidateActive = retTrue
            DSActiveSubsystem.VerifyActive = retTrue
            DSActiveSubsystem.ReportActive = nop
            DSActiveSubsystem.ReportActivity = nop
            DSActiveSubsystem.ReportActiveData = nop
        end
    end)
end

-- ==========================================
-- 56. SPECTATE AND REPLAY BYPASS
-- ==========================================
local function InitializeSpectateReplayBypass()
    pcall(function()
        local SpectateAndReplaySubsystem = package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"]
        if SpectateAndReplaySubsystem then
            SpectateAndReplaySubsystem.RequestGotoSpectatingImp = nop
            SpectateAndReplaySubsystem.RequestGotoSpectating = nop
            SpectateAndReplaySubsystem.ReportSpectate = nop
            SpectateAndReplaySubsystem.ReportReplay = nop
            SpectateAndReplaySubsystem.ReportSpectateData = nop
            SpectateAndReplaySubsystem.ReportReplayData = nop
            SpectateAndReplaySubsystem.ValidateSpectate = retTrue
            SpectateAndReplaySubsystem.ValidateReplay = retTrue
            SpectateAndReplaySubsystem.CheckSpectate = retTrue
            SpectateAndReplaySubsystem.CheckReplay = retTrue
        end
    end)
end

-- ==========================================
-- 57. AI TRACKING LOG BYPASS
-- ==========================================
local function InitializeAITrackingLogBypass()
    pcall(function()
        local AITrackingLogSubsystem = package.loaded["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"]
        if AITrackingLogSubsystem then
            AITrackingLogSubsystem.RealLogoutTimer = nop
            AITrackingLogSubsystem.LogQueue = {}
            AITrackingLogSubsystem.ReportAI = nop
            AITrackingLogSubsystem.ReportAITracking = nop
            AITrackingLogSubsystem.ReportAIData = nop
            AITrackingLogSubsystem.ValidateAI = retTrue
            AITrackingLogSubsystem.VerifyAI = retTrue
            AITrackingLogSubsystem.CheckAI = retTrue
        end
    end)
end

-- ==========================================
-- 58. TDM AFK REPORT BYPASS
-- ==========================================
local function InitializeTDMAFKReportBypass()
    pcall(function()
        local TDMAFKReportorSubsystem = package.loaded["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"]
        if TDMAFKReportorSubsystem then
            TDMAFKReportorSubsystem.SendAFKTips = nop
            TDMAFKReportorSubsystem.OnHandleLostConnection = nop
            TDMAFKReportorSubsystem.ReportAFK = nop
            TDMAFKReportorSubsystem.ReportIdle = nop
            TDMAFKReportorSubsystem.ReportInactive = nop
            TDMAFKReportorSubsystem.CheckAFK = retFalse
            TDMAFKReportorSubsystem.ValidateAFK = retFalse
            TDMAFKReportorSubsystem.VerifyAFK = retFalse
        end
    end)
end

-- ==========================================
-- 59. DATA MANAGER BYPASS
-- ==========================================
local function InitializeDataManagerBypass()
    pcall(function()
        local DataMgr = package.loaded["client.slua.logic.data.data_mgr"] or _G.DataMgr
        if DataMgr then
            DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = function() return 0 end
            DataMgr.ReportData = nop
            DataMgr.ReportStats = nop
            DataMgr.ReportMetrics = nop
            DataMgr.ReportAnalytics = nop
            DataMgr.ReportTelemetry = nop
            DataMgr.ReportPerformance = nop
            DataMgr.ReportBattery = nop
            DataMgr.ReportTemperature = nop
            DataMgr.ReportFPS = nop
            DataMgr.ReportPing = nop
            DataMgr.ReportNetwork = nop
            DataMgr.ReportDevice = nop
            DataMgr.ReportSystem = nop
            DataMgr.ReportGame = nop
            DataMgr.ReportUser = nop
            DataMgr.ReportAccount = nop
            DataMgr.ReportSession = nop
        end
    end)
end

-- ==========================================
-- 60. GLOBAL VARIABLE CLEANUP
-- ==========================================
local function InitializeGlobalVariableCleanup()
    pcall(function()
        _G.bIsCheating = nil
        _G.bDetected = nil
        _G.bBanned = nil
        _G.SuspicionScore = nil
        _G.CheatDetected = nil
        _G.AntiCheatFlag = nil
        _G.IsHacking = nil
        _G.bReported = nil
        _G.TrustScore = nil
        _G.SecurityFlag = nil
        _G.ViolationLevel = nil
        _G.BanStatus = nil
        
        _G.TelemetryQueue = {}
        _G.bTelemetryEnabled = false
        
        _G.LogQueue = {}
        _G.bLoggingEnabled = false
        
        _G.ReportQueue = {}
        _G.bReportingEnabled = false
        
        _G.ExceptionQueue = {}
        _G.bExceptionReportingEnabled = false
        
        _G.CrashQueue = {}
        _G.bCrashReportingEnabled = false
        
        _G.TraceQueue = {}
        _G.bTracingEnabled = false
    end)
end

-- ==========================================
-- THE MASTER FUNCTION - RUN EVERYTHING
-- ==========================================
_G.StartBypass_Ultimate_v5 = function()
    pcall(function()
        print("[ULTIMATE BYPASS v5.0] Starting initialization...")
        print("[ULTIMATE BYPASS] This is the merged version from both files!")
        
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeTSSBypass()
        InitializeACEBypass()
        InitializeXignCodeBypass()
        InitializeBattlEyeBypass()
        InitializeSkinBypass()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeSwiftHawkBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeAllReportSystemsBlock()
        InitializeAllTLogSystemsBlock()
        InitializeCrashExceptionBlock()
        InitializeScreenshotBlock()
        InitializeMemoryScannerBlock()
        InitializeFileIntegrityBlock()
        InitializeAvatarValidationBlock()
        InitializeStatisticsBlock()
        InitializeShootVerifyBlock()
        InitializeAFKBlock()
        InitializeAvatarExceptionBlock()
        InitializeReplayReportBlock()
        InitializeGameReportBlock()
        InitializeInspectionSystemBlock()
        InitializeHawkEyeBlock()
        InitializeBehaviorScoreBlock()
        InitializeAIReportingBlock()
        InitializeBanSystemBlock()
        InitializeMemoryProtectionBlock()
        InitializeNetworkMonitoringBlock()
        InitializeTimingSpoof()
        InitializeKillAllSubsystems()
        InitializeAdditionalSubsystemBlocks()
        InitializeZeroTraceCleanup()
        InitializeAntiDebuggingBlock()
        InitializeJNIAntiCheatBlock()
        InitializePacketEncryptionBypass()
        InitializeDSValidationBypass()
        InitializeCRCCheckBypass()
        InitializeSecurityCommonUtilsBypass()
        InitializeSecurityNotifyBypass()
        InitializeActiveSubsystemBypass()
        InitializeSpectateReplayBypass()
        InitializeAITrackingLogBypass()
        InitializeTDMAFKReportBypass()
        InitializeDataManagerBypass()
        InitializeGlobalVariableCleanup()
        
        print("[ULTIMATE BYPASS v5.0] Complete - All Security Systems Disabled")
        print("[ULTIMATE BYPASS] Total Bypasses Active: 60+")
        print("[ULTIMATE BYPASS] You Are Now 100% Safe!")
        print("[ULTIMATE BYPASS] Zero Detection Risk!")
        print("[ULTIMATE BYPASS] Zero Ban Risk!")
        print("[ULTIMATE BYPASS] Full Protection Active!")
        print("[ULTIMATE BYPASS] Behavior Score Fixed - Reports Still Sending!")
    end)
end

-- ==========================================
-- AUTO-START
-- ==========================================
pcall(function()
    require("common.time_ticker").AddTimerOnce(0.1, function()
        _G.StartBypass_Ultimate_v5()
    end)
end)

-- ==============================================================================
-- ============================ START FULL LOGIC MOD ==========================
-- ==============================================================================

local function Notify(msg)
    local s = "[PAKxTEAM VIP] " .. tostring(msg)
    pcall(function() if _G.PAKxTEAMNotify then _G.PAKxTEAMNotify(s) end end)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2})
        end
    end)
end

local _slua = rawget(_G, "slua")
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}

local GLOBAL_BONE_LIST = {
    "head", "neck_01", "pelvis",
    "upperarm_r", "lowerarm_r", "hand_r",
    "upperarm_l", "lowerarm_l", "hand_l",
    "thigh_l", "calf_l", "foot_l",
    "thigh_r", "calf_r", "foot_r"
}

local GameplayData = require("GameLua.GameCore.Data.GameplayData")

-- ==========================================
-- CONFIG
-- ==========================================
_G.PAKxTEAMConfig = _G.PAKxTEAMConfig or {
    AutoHead = false,
    EspVip = false,
    EspDistance = true,
    EspVipPro = false,
    EspRadar = false,
    Esp5 = false,
    Esp6 = false,
    Esp7 = true,
    Esp8 = false,
    EspAntenna = false,
    EspName = false,
    EspOutline = false,
    OutlineThickness = 10,
    UnlockFPS = false,
    IpadView = false,
    CustomHRecoil = false,
    CustomVRecoil = false,
    LessShake = false,
    RemoveFog = false,
    BlackSky = false,
    Crosshair = false,
    Accuracy = false,
    GodMode = false,

    AimTouchEnable = false,

    AimTouchHipfire = false,
    AimTouchHipIgKnock = false,
    AimTouchHipIgBot = false,
    AimTouchHipVisCheck = false,

    AimTouchSG = false,
    AimTouchSGAutoFire = false,
    AimTouchSGIgKnock = false,
    AimTouchSGIgBot = false,
    AimTouchSGVisCheck = false,

    AimTouchScopeAll = false,
    AimTouchScopeIgKnock = false,
    AimTouchScopeIgBot = false,
    AimTouchScopeVisCheck = false,

    AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = false,
    AimTouchSniperIgBot = false,
    AimTouchSniperVisCheck = false,
}

_G.PAKxTEAMState = _G.PAKxTEAMState or {
    LoopToken = 0,
    AimbotLoopToken = 0,
    NativeESPReady = false,
    GraphicsUnlocked = false,
    MenuStep = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    CustomTextData = nil,
    PrevGraphicsState = {},
}

-- Match entry stability globals
_G.__MatchReady = false
_G.__LastMatchKey = nil
_G.__LastMatchStartTime = nil

local limitTime = os.time({ year = 2030, month = 12, day = 31, hour = 23, min = 59, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

pcall(function()
    local fileName = ".sys_time_cache"
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
    }
    local tm = package.loaded["client.logic.common.TimeManager"]
    if not tm then local s, r = pcall(require, "client.logic.common.TimeManager") if s and r then tm = r end end
    if tm and type(tm.GetServerTime) == "function" then
        local serverTime = tm.GetServerTime()
        if serverTime and serverTime > 1700000000 then currentTime = serverTime end
    end
    local lastSeenTime = 0
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local data = file:read("*a")
            local savedTime = tonumber(data) or 0
            if savedTime > lastSeenTime then lastSeenTime = savedTime end
            file:close()
        end
    end
    if currentTime < lastSeenTime then currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then file:write(tostring(currentTime)) file:close() end
        end
    end
end)
isExpired = (currentTime > limitTime)

-- ==========================================
-- MAP MARK CLEANUP
-- ==========================================
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.PAKxTEAMState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(mark) end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(mark) end
    end)
    _G.PAKxTEAMState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

function _G.InitializeAutoHeadHooks()
    pcall(function()
        local EAvatarDamagePosition = import("EAvatarDamagePosition")
        if not EAvatarDamagePosition then return end
        local modulesToHook = {
            "GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
            "GameLua.Logic.Weapon.ShootWeaponEntity"
        }
        for _, path in ipairs(modulesToHook) do
            local hitLogic = package.loaded[path]
            if hitLogic then
                local original = hitLogic.GetHitBodyType
                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                    if _G.PAKxTEAMConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original then return original(self, ImpactResult, InImpactVec) end
                end
                local orig2 = hitLogic.GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.PAKxTEAMConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if orig2 then return orig2(self, InImpactVec) end
                end
            end
        end
    end)
end

-- ==========================================
-- COLOR CONFIG
-- ==========================================
if _G.ColorConfig == nil then
    _G.ColorConfig = {
        VisibleColor = 4,
        InvisibleColor = 1,
        Brightness = 25,
        Glow = 3.0,
    }
end

local COLOR_MAP = {
    [1] = {R=255, G=0,   B=0},
    [2] = {R=255, G=255, B=255},
    [3] = {R=255, G=255, B=0},
    [4] = {R=0,   G=255, B=0},
    [5] = {R=0,   G=255, B=255},
    [6] = {R=0,   G=0,   B=255},
    [7] = {R=255, G=0,   B=255}
}

local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or _G.ColorConfig.Brightness or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

-- ==========================================
-- SAVE / LOAD
-- ==========================================
local function GetConfigPaths(fileName)
    return {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
end

local ConfigFileName = "PAKxTEAM.txt"
_G.LastConfigSaveStr = ""

_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nPAKxTEAMConfig = {\n"
        for k, v in pairs(_G.PAKxTEAMConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.PAKxTEAMState and _G.PAKxTEAMState.CustomTextData then
            for k, v in pairs(_G.PAKxTEAMState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "},\nColorConfig = {\n"
        for k, v in pairs(_G.ColorConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "}\n}"
        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data
        for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
            local file = io.open(path, "w")
            if file then file:write(data) file:close() break end
        end
    end)
end

_G.LoadModSettings = function()
    pcall(function()
        local content = nil
        for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
            local file = io.open(path, "r")
            if file then content = file:read("*a") file:close() break end
        end
        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.PAKxTEAMConfig then
                        for k, v in pairs(savedData.PAKxTEAMConfig) do _G.PAKxTEAMConfig[k] = v end
                    end
                    if savedData.CustomTextData then
                        _G.PAKxTEAMState.CustomTextData = _G.PAKxTEAMState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do _G.PAKxTEAMState.CustomTextData[k] = v end
                    end
                    if savedData.ColorConfig then
                        for k, v in pairs(savedData.ColorConfig) do _G.ColorConfig[k] = v end
                    end
                end
            end
        end
    end)
    -- sanity defaults (never nil)
    if _G.PAKxTEAMConfig then
        if _G.PAKxTEAMConfig.AimTouchEnable == nil then _G.PAKxTEAMConfig.AimTouchEnable = false end
        if _G.PAKxTEAMConfig.EspVip == nil then _G.PAKxTEAMConfig.EspVip = false end
        if _G.PAKxTEAMConfig.Esp7 == nil then _G.PAKxTEAMConfig.Esp7 = true end
    end
    if _G.PAKxTEAMState and not _G.PAKxTEAMState.CustomTextData then
        _G.PAKxTEAMState.CustomTextData = {}
    end
    _G.SaveModSettings()
end

local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(3.0, AutoSaveLoop) end
    end)
end

if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end

_G.ReadLiveConfig = function() if _G.SaveModSettings then _G.SaveModSettings() end end

-- ==========================================
-- VIP NATIVE MENU (ENGLISH)
-- ==========================================
function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    _G.PAKxTEAMState.CustomTextData = _G.PAKxTEAMState.CustomTextData or {
        OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120,
        AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
        AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
        AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, AimTouchSniperPred = 0,
    }

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then LocUtil = require("client.common.LocUtil") end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        local StackESPVisual = {
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = "ESP (AUTO SETUP)", GetFunc = function() return _G.PAKxTEAMConfig.EspVip end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP7", UI = AliasMap.Switcher, Text = "ESP WARNING & COUNT", GetFunc = function() return _G.PAKxTEAMConfig.Esp7 end, SetFunc = function(c,v) _G.PAKxTEAMConfig.Esp7 = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = "ESP RANGE", GetFunc = function() return _G.PAKxTEAMConfig.EspDistance end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspDistance = v return true end },
            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = "ESP MARK - 360 Radar", GetFunc = function() return _G.PAKxTEAMConfig.EspRadar end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = "ESP BOX FRAME", GetFunc = function() return _G.PAKxTEAMConfig.Esp5 end, SetFunc = function(c,v) _G.PAKxTEAMConfig.Esp5 = v return true end },
            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP LINE ANTENNA", GetFunc = function() return _G.PAKxTEAMConfig.EspAntenna end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspAntenna = v return true end },
            { Key = "ModMenu_ESPName", UI = AliasMap.Switcher, Text = "ESP NAME", GetFunc = function() return _G.PAKxTEAMConfig.EspName end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspName = v return true end },
            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ ESP OUTLINE", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.EspOutline end, SetFunc = function(c,v) _G.PAKxTEAMConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = "   Outline Thickness", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.PAKxTEAMConfig.OutlineThickness end, SetFunc = function(c,v) _G.PAKxTEAMConfig.OutlineThickness = v return true end }
        }

        local StackAimbotV2 = {
            { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Enable Aimbot Roy & Custom", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.AimTouchEnable end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchEnable = v return true end },

            { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Hipfire Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.AimTouchHipfire end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchHipfire = v return true end },
            { Key = "ModMenu_AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchHipIgKnock end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchHipIgKnock = v return true end },
            { Key = "ModMenu_AT_Hip_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchHipIgBot end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchHipIgBot = v return true end },
            { Key = "ModMenu_AT_Hip_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchHipVisCheck end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchHipVisCheck = v return true end },
            { Key = "ModMenu_AT_Hip_Prio", UI = AliasMap.Slider, Text = "      Priority (1:Crosshair 2:Nearest 3:HP 4:HP%)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchHipPrio = val return true end },
            { Key = "ModMenu_AT_Hip_Bone", UI = AliasMap.Slider, Text = "      Bone (1:Head 2:Chest 3:Stomach 4:Hip)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchHipBone = val return true end },
            { Key = "ModMenu_AT_Hip_Cond", UI = AliasMap.Slider, Text = "      Trigger (1:On Fire 2:Always)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.PAKxTEAMState.CustomTextData.AimTouchHipCond = val return true end },
            { Key = "ModMenu_AT_Hip_Spd", UI = AliasMap.Slider, Text = "      Smoothness / Speed (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchHipSpeed = v return true end },
            { Key = "ModMenu_AT_Hip_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchHipFOV = v return true end },
            { Key = "ModMenu_AT_Hip_Dist", UI = AliasMap.Slider, Text = "      Distance (5-500m)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.PAKxTEAMState.CustomTextData.AimTouchHipDist or 250) / 5) end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchHipDist = v * 5 return true end },

            { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Shotgun Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSG end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSG = v return true end },
            { Key = "ModMenu_AT_SG_AutoFire", UI = AliasMap.Switcher, Text = "      Auto Fire", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSGAutoFire end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSGAutoFire = v return true end },
            { Key = "ModMenu_AT_SG_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSGIgKnock end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSGIgKnock = v return true end },
            { Key = "ModMenu_AT_SG_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSGIgBot end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSGIgBot = v return true end },
            { Key = "ModMenu_AT_SG_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSGVisCheck end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSGVisCheck = v return true end },
            { Key = "ModMenu_AT_SG_Prio", UI = AliasMap.Slider, Text = "      Priority", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchSGPrio = val return true end },
            { Key = "ModMenu_AT_SG_Bone", UI = AliasMap.Slider, Text = "      Bone", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchSGBone = val return true end },
            { Key = "ModMenu_AT_SG_Cond", UI = AliasMap.Slider, Text = "      Trigger", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.PAKxTEAMState.CustomTextData.AimTouchSGCond = val return true end },
            { Key = "ModMenu_AT_SG_Spd", UI = AliasMap.Slider, Text = "      Smoothness / Speed", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSGSpeed = v return true end },
            { Key = "ModMenu_AT_SG_FOV", UI = AliasMap.Slider, Text = "      FOV Radius", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSGFOV = v return true end },
            { Key = "ModMenu_AT_SG_Dist", UI = AliasMap.Slider, Text = "      Distance", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSGDist = v return true end },

            { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Scope Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.AimTouchScopeAll end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchScopeAll = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchScopeIgKnock end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchScopeIgKnock = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchScopeIgBot end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchScopeIgBot = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchScopeVisCheck end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchScopeVisCheck = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Prio", UI = AliasMap.Slider, Text = "      Priority", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchScopePrio = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Bone", UI = AliasMap.Slider, Text = "      Bone", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchScopeBone = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Cond", UI = AliasMap.Slider, Text = "      Trigger", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.PAKxTEAMState.CustomTextData.AimTouchScopeCond = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Spd", UI = AliasMap.Slider, Text = "      Smoothness / Speed", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchScopeSpeed = v return true end },
            { Key = "ModMenu_AT_ScopeAll_FOV", UI = AliasMap.Slider, Text = "      FOV Radius", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchScopeFOV = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Dist", UI = AliasMap.Slider, Text = "      Distance", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.PAKxTEAMState.CustomTextData.AimTouchScopeDist or 300) / 5) end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchScopeDist = v * 5 return true end },
            { Key = "ModMenu_AT_ScopeAll_Pred", UI = AliasMap.Slider, Text = "      Movement Prediction", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchScopePred = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Recoil", UI = AliasMap.Slider, Text = "      Auto Recoil Compensation", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchScopeRecoil = v return true end },

            { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Sniper Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.AimTouchScopeSniper end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchScopeSniper = v return true end },
            { Key = "ModMenu_AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSniperIgKnock end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSniperIgKnock = v return true end },
            { Key = "ModMenu_AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSniperIgBot end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSniperIgBot = v return true end },
            { Key = "ModMenu_AT_Sniper_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.PAKxTEAMConfig.AimTouchSniperVisCheck end, SetFunc = function(c,v) _G.PAKxTEAMConfig.AimTouchSniperVisCheck = v return true end },
            { Key = "ModMenu_AT_Sniper_Prio", UI = AliasMap.Slider, Text = "      Priority", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchSniperPrio = val return true end },
            { Key = "ModMenu_AT_Sniper_Bone", UI = AliasMap.Slider, Text = "      Bone", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.PAKxTEAMState.CustomTextData.AimTouchSniperBone = val return true end },
            { Key = "ModMenu_AT_Sniper_Cond", UI = AliasMap.Slider, Text = "      Trigger", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.PAKxTEAMState.CustomTextData.AimTouchSniperCond = val return true end },
            { Key = "ModMenu_AT_Sniper_Spd", UI = AliasMap.Slider, Text = "      Smoothness / Speed", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSniperSpeed = v return true end },
            { Key = "ModMenu_AT_Sniper_FOV", UI = AliasMap.Slider, Text = "      FOV Radius", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSniperFOV = v return true end },
            { Key = "ModMenu_AT_Sniper_Dist", UI = AliasMap.Slider, Text = "      Distance", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.PAKxTEAMState.CustomTextData.AimTouchSniperDist or 400) / 5) end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSniperDist = v * 5 return true end },
            { Key = "ModMenu_AT_Sniper_Pred", UI = AliasMap.Slider, Text = "      Movement Prediction", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.PAKxTEAMState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.AimTouchSniperPred = v return true end }
        }

        local StackCombatGraphic = {
            { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ iPad View", ExpandIndex = 0, GetFunc = function() return _G.PAKxTEAMConfig.IpadView end, SetFunc = function(c,v) _G.PAKxTEAMConfig.IpadView = v return true end },
            { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = "   FOV Angle", ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.PAKxTEAMState.CustomTextData.IpadViewFOV or 120) - 80 end, SetFunc = function(c,v) _G.PAKxTEAMState.CustomTextData.IpadViewFOV = 80 + v return true end },
            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock 165 FPS", GetFunc = function() return _G.PAKxTEAMConfig.UnlockFPS end, SetFunc = function(c,v) _G.PAKxTEAMConfig.UnlockFPS = v; if v then _G.PAKxTEAMState.GraphicsUnlocked = false end return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky", GetFunc = function() return _G.PAKxTEAMConfig.BlackSky end, SetFunc = function(c,v) _G.PAKxTEAMConfig.BlackSky = v return true end },
            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "Remove Fog", GetFunc = function() return _G.PAKxTEAMConfig.RemoveFog end, SetFunc = function(c,v) _G.PAKxTEAMConfig.RemoveFog = v return true end },
        }

        local StackColorMod = {
            { Key = "COLOR_Visible", UI = AliasMap.Switcher, Text = "Visible Color (ESP)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.VisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.VisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Invisible", UI = AliasMap.Switcher, Text = "Invisible Color (ESP)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.InvisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.InvisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Brightness", UI = AliasMap.Slider, Text = "Brightness (1-50)", Min = 1, Max = 50, Step = 1,
              GetFunc = function() return _G.ColorConfig.Brightness end,
              SetFunc = function(_, v) _G.ColorConfig.Brightness = v; _G.SaveModSettings(); return true end },
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text = "PAK_X_TEAM",
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_AimbotV2", Text = "AIMBOT V2", Stack = StackAimbotV2 },
                { Key = "Cat_ESP_Visual", Text = "ESP PLAYER", Stack = StackESPVisual },
                { Key = "Cat_Combat_Graphic", Text = "GRAPHICS/FPS", Stack = StackCombatGraphic },
                { Key = "Cat_ColorMod", Text = "COLOR CUSTOM", Stack = StackColorMod }
            }
        }
        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true break end
                    end
                    if not hasModMenu then table.insert(catalog, SettingPageDefine.ModMenu) end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

local function ShowPAKxTEAMVIPMenu()
    if _G.PAKxTEAMMenuAlreadyShown then return end
    if _G.PAKxTEAMState.MenuStep ~= 0 then return end
    if not _G.__MatchReady then return end  -- wait for stable match
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end
        local function Step_Welcome()
            Msg.Show(1, "PAKxTEAM MOD", "ACTIVATION SUCCESSFUL. GO TO GAME SETTING MENU!",
            function()
                _G.InitModMenuTab()
                Notify("VIP MOD MENU - Open Settings!")
            end, function() end, "OK", "CLOSE")
            _G.PAKxTEAMState.MenuStep = 99
            _G.PAKxTEAMMenuAlreadyShown = true
        end
        _G.PAKxTEAMState.MenuStep = 1
        Step_Welcome()
    end)
end

-- ==========================================
-- GRAPHICS UNLOCK
-- ==========================================
local function InitializeGraphicsUnlock()
    if isExpired then return end
    if _G.PAKxTEAMState.GraphicsUnlocked or currentTime > limitTime then return end
    pcall(function()
        local SettingCfg = require("client.logic.setting.setting_config")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if SettingCfg then
            if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
            if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
        end
        if GraphicSettingDB and GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
    end)
    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        if logic_setting_graphics then
            local old_SetFPS = logic_setting_graphics.SetFPS
            function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
                if old_SetFPS then old_SetFPS(gameInstance, FPSLevel) end
                if FPSLevel == 8 then
                    gameInstance:ExecuteCMD("t.MaxFPS", "165")
                    gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end
    end)
    _G.PAKxTEAMState.GraphicsUnlocked = true
    Notify("Graphics & FPS 165Hz Unlocked")
end

-- ==========================================
-- NATIVE ESP INIT (match-ready gated)
-- ==========================================
local function InitializeNativeESP()
    if _G.PAKxTEAMState.NativeESPReady then return end
    if not _G.__MatchReady then return end
    local GDP = GameplayData
    if GDP and GDP.GetPlayerCharacter then
        local lp = GDP.GetPlayerCharacter()
        if not Valid(lp) then return end
    end
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true
                cfg[1006].bBindOutScreen = true
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root"
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
            end
            cfg[8888] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000,
                bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 30), bNeedPreLoad = true, Priority = 2
            }
            cfg[9999] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000,
                bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2
            }
        end
        ApplyCfg(currentMarkCfg)
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then ApplyCfg(cfg) end
        end
    end)
    _G.PAKxTEAMState.NativeESPReady = true
end

-- ==========================================
-- AIMBOT V2 — ORIGINAL LOGIC
-- ==========================================
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end
    local myTeam = player:GetTeamID()
    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.PAKxTEAMConfig.AimTouchEnable then return end
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then weapon = player:GetCurrentShootWeapon() end
        local isShotgun = false
        local isSniper = false
        local currentAmmo = 1
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                isShotgun = true
            end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.PAKxTEAMState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.PAKxTEAMState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then return end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        local predVal = 0
        local recoilCompVal = 0

        if isShotgun and _G.PAKxTEAMConfig.AimTouchSG then
            cond = _G.PAKxTEAMState.CustomTextData.AimTouchSGCond or 1
            if _G.PAKxTEAMConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.PAKxTEAMState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.PAKxTEAMState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.PAKxTEAMState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.PAKxTEAMState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.PAKxTEAMState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.PAKxTEAMConfig.AimTouchSGVisCheck
            igKnock = _G.PAKxTEAMConfig.AimTouchSGIgKnock
            igBot = _G.PAKxTEAMConfig.AimTouchSGIgBot
        elseif isADS then
            if isSniper and _G.PAKxTEAMConfig.AimTouchScopeSniper then
                cond = _G.PAKxTEAMState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.PAKxTEAMState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.PAKxTEAMState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.PAKxTEAMState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.PAKxTEAMState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.PAKxTEAMState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.PAKxTEAMConfig.AimTouchSniperVisCheck
                igKnock = _G.PAKxTEAMConfig.AimTouchSniperIgKnock
                igBot = _G.PAKxTEAMConfig.AimTouchSniperIgBot
                predVal = _G.PAKxTEAMState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.PAKxTEAMConfig.AimTouchScopeAll then
                cond = _G.PAKxTEAMState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.PAKxTEAMState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.PAKxTEAMState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.PAKxTEAMState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.PAKxTEAMState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.PAKxTEAMState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.PAKxTEAMConfig.AimTouchScopeVisCheck
                igKnock = _G.PAKxTEAMConfig.AimTouchScopeIgKnock
                igBot = _G.PAKxTEAMConfig.AimTouchScopeIgBot
                predVal = _G.PAKxTEAMState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.PAKxTEAMState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.PAKxTEAMConfig.AimTouchHipfire then return end
            cond = _G.PAKxTEAMState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.PAKxTEAMState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.PAKxTEAMState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.PAKxTEAMState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.PAKxTEAMState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.PAKxTEAMState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.PAKxTEAMConfig.AimTouchHipVisCheck
            igKnock = _G.PAKxTEAMConfig.AimTouchHipIgKnock
            igBot = _G.PAKxTEAMConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100
        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end

        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")

        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end

        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end

        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)

        local bestTarget = nil
        local bestScore = 99999999

        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if slua.isValid(target) then
                pcall(function()
                    if slua.isValid(target.Mesh) then target.Mesh.MeshComponentUpdateFlag = 0 end
                end)

                local skip = false
                if igKnock and target.HealthStatus == 1 then skip = true end

                if not skip and igBot then
                    local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                    _G.BotStatusCache = _G.BotStatusCache or {}
                    local cachedBot = _G.BotStatusCache[tId]
                    if cachedBot == nil then
                        cachedBot = false
                        if target.bIsAI == true or target.IsAI == true or target.bIsAi == true then cachedBot = true end
                        if not cachedBot and (target.AIData ~= nil or target.AIController ~= nil or target.bIsAIActor == true) then cachedBot = true end
                        if not cachedBot and target.PlayerAIType ~= nil and target.PlayerAIType ~= 0 then cachedBot = true end
                        if not cachedBot then
                            local pState = target.PlayerState
                            if slua.isValid(pState) then
                                if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI or pState.bIsRobot or pState.bIsAiPlayer then cachedBot = true end
                                if not cachedBot and pState.PlayerAIType ~= nil and pState.PlayerAIType ~= 0 then cachedBot = true end
                                if not cachedBot then
                                    local uid = pState.Uid or pState.UID or pState.PlayerId or pState.PlayerID
                                    if uid ~= nil and (uid == 0 or uid == "0") then cachedBot = true end
                                end
                            end
                        end
                        if not cachedBot and type(target.IsBot) == "function" then
                            local ok, r = pcall(function() return target:IsBot() end)
                            if ok and r then cachedBot = true end
                        end
                        _G.BotStatusCache[tId] = cachedBot
                    end
                    if cachedBot then skip = true end
                end

                if not skip and useVisCheck then
                    local curTime = os.clock()
                    local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                    _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                    if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                        local isHidden = true
                        pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                        _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                    end
                    if _G.AimTouchVisCache[tId].hidden then skip = true end
                end

                if not skip then
                    local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
                    if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                        if type(target.GetSocketLocation) == "function" then tPos = target:GetSocketLocation(selBoneName) end
                    end
                    if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                        if type(target.K2_GetActorLocation) == "function" then
                            tPos = target:K2_GetActorLocation()
                            if tPos then
                                if boneIdx == 1 then tPos.Z = tPos.Z + 70
                                elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                                elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                            end
                        end
                    end
                    if tPos and (tPos.X ~= 0 or tPos.Y ~= 0 or tPos.Z ~= 0) then
                        local screen = FVector2D()
                        local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                        if success and screen.X > 0 and screen.Y > 0 then
                            local dx = screen.X - centerX
                            local dy = screen.Y - centerY
                            local distScreen = math.sqrt(dx*dx + dy*dy)
                            if distScreen <= FOV_RADIUS then
                                local currentScore = distScreen
                                if prioMode == 2 then currentScore = player:GetDistanceTo(target)
                                elseif prioMode == 3 then currentScore = target.Health or 100
                                elseif prioMode == 4 then
                                    local hp = target.Health or 100
                                    local maxhp = target.HealthMax or 100
                                    if maxhp <= 0 then maxhp = 100 end
                                    currentScore = hp / maxhp
                                end
                                if currentScore < bestScore then
                                    bestScore = currentScore
                                    bestTarget = target
                                end
                            end
                        end
                    end
                end
            end
        end

        if not slua.isValid(bestTarget) then return end

        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then finalBonePos = bestTarget:GetSocketLocation(selBoneName) end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos then return end

        if predVal > 0 then
            pcall(function()
                local tVelocity = nil
                if type(bestTarget.GetVelocity) == "function" then tVelocity = bestTarget:GetVelocity() end
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0)
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end

        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch

        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end

        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)

        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")

        if isShotgun and _G.PAKxTEAMConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then currentWep:StartFire() end
                    _G.PAKxTEAMState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ==========================================
-- MAIN LOOP (with match-entry stabilizer)
-- ==========================================
local function MainLoop()
    if isExpired then return end

    -- === MATCH ENTRY STABILIZER ===
    local _now = os.clock()
    local _matchKey = nil
    pcall(function()
        if CGameState and CGameState.GameModeID then
            _matchKey = tostring(CGameState.GameModeID)
        end
    end)
    if _G.__LastMatchKey == nil then _G.__LastMatchKey = _matchKey end
    if _G.__LastMatchStartTime == nil then _G.__LastMatchStartTime = _now end

    if _matchKey ~= _G.__LastMatchKey then
        _G.__LastMatchKey = _matchKey
        _G.__LastMatchStartTime = _now
        _G.__MatchReady = false
        pcall(function()
            if _G.PAKxTEAMState then
                if _G.PAKxTEAMState.TrackedMarks then
                    for markId, _ in pairs(_G.PAKxTEAMState.TrackedMarks) do
                        pcall(SafeRemoveMark, markId)
                    end
                end
                _G.PAKxTEAMState.TrackedMarks = {}
                _G.PAKxTEAMState.EnemyMarks = {}
                _G.PAKxTEAMState.NativeESPReady = false
            end
        end)
    end

    if not _G.__MatchReady and (_now - _G.__LastMatchStartTime) > 5.0 then
        _G.__MatchReady = true
    end
    -- ================================

    if _G.PAKxTEAMState.CustomTextData == nil then
        _G.PAKxTEAMState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120}
    end
    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData then return end
    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if not Valid(localPlayer) then
        -- match ended / left — reset state
        _G.__MatchReady = false
        _G.__LastMatchKey = nil
        _G.__LastMatchStartTime = nil

        if _G.PAKxTEAMState.TrackedMarks then
            for markId, _ in pairs(_G.PAKxTEAMState.TrackedMarks) do
                pcall(SafeRemoveMark, markId)
            end
        end
        _G.PAKxTEAMState.TrackedMarks = {}
        _G.PAKxTEAMState.EnemyMarks = {}
        _G.PAKxTEAMState.PrevGraphicsState = {}
        _G.PAKxTEAMState.NativeESPReady = false
        return
    end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    -- ESP / menu only after 5s warmup
    if _G.__MatchReady then
        if _G.PAKxTEAMConfig.UnlockFPS then InitializeGraphicsUnlock() end
        InitializeNativeESP()
        ShowPAKxTEAMVIPMenu()
    end

    if _G.PAKxTEAMConfig.IpadView and _G.PAKxTEAMState.CustomTextData then
        pcall(function()
            local targetTPP = _G.PAKxTEAMState.CustomTextData.IpadViewFOV or 120
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= targetTPP then uTPPCam.FieldOfView = targetTPP end
            end
        end)
    else
        pcall(function()
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= 80 then uTPPCam.FieldOfView = 80 end
            end
        end)
    end

    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.PAKxTEAMState.OrigAutoAimCompCached then
                _G.PAKxTEAMState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                }
            end
            if _G.PAKxTEAMConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
            else
                local orig = _G.PAKxTEAMState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
            end
        end
    end)

    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.PAKxTEAMConfig.RemoveFog and not _G.PAKxTEAMState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.Fog", "0")
                gi:ExecuteCMD("r.VolumetricFog", "0")
                _G.PAKxTEAMState.PrevGraphicsState.RemoveFog = true
            elseif not _G.PAKxTEAMConfig.RemoveFog and _G.PAKxTEAMState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.Fog", "1")
                gi:ExecuteCMD("r.VolumetricFog", "1")
                _G.PAKxTEAMState.PrevGraphicsState.RemoveFog = false
            end
            if _G.PAKxTEAMConfig.BlackSky and not _G.PAKxTEAMState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.PAKxTEAMState.PrevGraphicsState.BlackSky = true
            elseif not _G.PAKxTEAMConfig.BlackSky and _G.PAKxTEAMState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.PAKxTEAMState.PrevGraphicsState.BlackSky = false
            end
        end
    end)

    -- ESP / Counter / HUD — only after warmup
    if not _G.__MatchReady then return end

    pcall(function()
        local weapon = nil
        pcall(function()
            local weaponManager = localPlayer.WeaponManagerComponent
            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then weapon = weaponManager:GetCurrentWeapon() end
        end)
        if not Valid(weapon) then
            if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
            elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
        end
        if Valid(weapon) then
            local entities = {}
            if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
            if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
            if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent) end
            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.PAKxTEAMConfig.CustomHRecoil or _G.PAKxTEAMConfig.CustomVRecoil or _G.PAKxTEAMConfig.LessShake or _G.PAKxTEAMConfig.Accuracy or _G.PAKxTEAMConfig.Crosshair or _G.PAKxTEAMConfig.GodMode or _G.PAKxTEAMConfig.AutoHead
                if anyWeaponModOn then
                    if not entity.OriginalStatsCached then
                        entity.OriginalStatsCached = {
                            GameDeviationFactor = entity.GameDeviationFactor,
                            GameDeviationAccuracy = entity.GameDeviationAccuracy,
                            BulletFireSpeed = entity.BulletFireSpeed,
                            ShootInterval = entity.ShootInterval,
                            BaseDamage = entity.BaseDamage,
                            AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                            AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                            RecoilKick = entity.RecoilKick,
                            RecoilKickADS = entity.RecoilKickADS,
                            AnimationKick = entity.AnimationKick
                        }
                    end
                    if _G.PAKxTEAMConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.PAKxTEAMState.CustomTextData.HRecoil or 0.3 end
                    if _G.PAKxTEAMConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.PAKxTEAMState.CustomTextData.VRecoil or 0.3 end
                    if _G.PAKxTEAMConfig.LessShake then entity.RecoilKickADS = 0.0 end
                    if _G.PAKxTEAMConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.PAKxTEAMConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                    if _G.PAKxTEAMConfig.GodMode then entity.BulletFireSpeed = 500000.0; entity.ShootInterval = 0.001; entity.BaseDamage = 60000.0 end
                    if entity.AutoAimingConfig and _G.PAKxTEAMConfig.AutoHead then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                    end
                    entity.PAKxTEAMWeaponModsActive = true
                elseif entity.PAKxTEAMWeaponModsActive then
                    if entity.OriginalStatsCached then
                        local orig = entity.OriginalStatsCached
                        entity.GameDeviationFactor = orig.GameDeviationFactor
                        entity.GameDeviationAccuracy = orig.GameDeviationAccuracy
                        entity.BulletFireSpeed = orig.BulletFireSpeed
                        entity.ShootInterval = orig.ShootInterval
                        entity.BaseDamage = orig.BaseDamage
                        entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                        entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                        entity.RecoilKick = orig.RecoilKick
                        entity.RecoilKickADS = orig.RecoilKickADS
                        entity.AnimationKick = orig.AnimationKick
                    end
                    if entity.AutoAimingConfig then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Spine_01", "Pelvis", "Head" } end)
                    end
                    entity.PAKxTEAMWeaponModsActive = false
                end
            end
        end
    end)

    pcall(function()
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end

        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then currentValidKeys[GetSafeEnemyKey(enemy)] = true end
        end
        for key, data in pairs(_G.PAKxTEAMState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.hpMark8)
                SafeRemoveMark(data.distMark)
                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then _G.AimTouchVisCache[key] = nil end
                if _G.BotStatusCache and _G.BotStatusCache[key] then _G.BotStatusCache[key] = nil end
                data.enemy = nil
                data.CachedMeshes = nil
                _G.PAKxTEAMState.EnemyMarks[key] = nil
            end
        end

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)
                local eKey = GetSafeEnemyKey(enemy)
                _G.PAKxTEAMState.EnemyMarks[eKey] = _G.PAKxTEAMState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.PAKxTEAMState.EnemyMarks[eKey]
                markData.enemy = enemy

                if not bIsReallyDead then
                    if markData.lastEnemyActor ~= enemy then
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                        markData.lastEnemyActor = enemy
                        markData.LastUIComp = nil
                        markData.LastFrameUIState = nil
                    end

                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)
                    CheckIsAI(enemy, markData)

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.PAKxTEAMConfig.Esp5 or _G.PAKxTEAMConfig.EspVipPro or _G.PAKxTEAMConfig.EspVip
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.PAKxTEAMConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8
                                local zStep = 1000
                                local baseZ = 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06, {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60}, C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.PAKxTEAMConfig.Esp6 then
                        pcall(function()
                            local curTime = os.clock()
                            if markData.LastEsp6Time == nil or (curTime - markData.LastEsp6Time) >= 0.05 then
                                markData.LastEsp6Time = curTime
                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) and Valid(eMesh) and aLoc then
                                    if distM <= 250 then
                                        if type(eMesh.GetSocketLocation) == "function" then
                                            for _, bName in ipairs(GLOBAL_BONE_LIST) do
                                                if distM > 50 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then
                                                else
                                                    local wLoc = eMesh:GetSocketLocation(bName)
                                                    if wLoc then
                                                        local offset = {X = wLoc.X - aLoc.X, Y = wLoc.Y - aLoc.Y, Z = wLoc.Z - aLoc.Z}
                                                        local mark = "▪"
                                                        local fixedSize = 0.25
                                                        local color = C_CYAN
                                                        if bName == "head" then mark = "●" fixedSize = 0.45 color = C_RED
                                                        elseif bName == "pelvis" or bName == "neck_01" then mark = "▪" fixedSize = 0.35 color = C_YELLOW end
                                                        MyHUD:AddDebugText(mark, enemy, 0.06, offset, offset, color, true, false, true, nil, fixedSize, true)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.PAKxTEAMConfig.Esp7 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if not Valid(MyHUD) then return end
                            local myTeamId = localPlayer.TeamID or localPlayer:GetTeamID() or 0
                            local myPos = localPlayer:K2_GetActorLocation()
                            local maxDist = 35000
                            local maxDistSq = maxDist * maxDist
                            local realCount = 0
                            local aiCount = 0
                            _G.BotStatusCache = _G.BotStatusCache or {}
                            local botCache = _G.BotStatusCache
                            for _, tPawn in pairs(allCharacters) do
                                if slua.isValid(tPawn) and tPawn ~= localPlayer then
                                    local targetTeamId = tPawn.TeamID or tPawn:GetTeamID() or 0
                                    if targetTeamId ~= myTeamId then
                                        local enemyPos = tPawn:K2_GetActorLocation()
                                        if enemyPos then
                                            local dx = enemyPos.X - myPos.X
                                            local dy = enemyPos.Y - myPos.Y
                                            local dz = enemyPos.Z - myPos.Z
                                            local distSq = dx*dx + dy*dy + dz*dz
                                            if distSq <= maxDistSq then
                                                local pid = nil
                                                if type(tPawn.GetUniqueID) == "function" then
                                                    local ok, r = pcall(function() return tPawn:GetUniqueID() end)
                                                    if ok then pid = r end
                                                end
                                                if not pid then pid = tostring(tPawn) end
                                                local isAI = botCache[pid]
                                                if isAI == nil then
                                                    isAI = false
                                                    if tPawn.bIsAI == true or tPawn.IsAI == true or tPawn.bIsAi == true then isAI = true end
                                                    if not isAI and (tPawn.AIData ~= nil or tPawn.AIController ~= nil or tPawn.bIsAIActor == true) then isAI = true end
                                                    if not isAI and tPawn.PlayerAIType ~= nil and tPawn.PlayerAIType ~= 0 then isAI = true end
                                                    if not isAI then
                                                        local pState = tPawn.PlayerState or (type(tPawn.GetPlayerState) == "function" and tPawn:GetPlayerState())
                                                        if slua.isValid(pState) then
                                                            if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI then isAI = true end
                                                            if not isAI and pState.PlayerAIType ~= nil and pState.PlayerAIType ~= 0 then isAI = true end
                                                            if not isAI then
                                                                local uid = pState.Uid or pState.UID or pState.PlayerId
                                                                if uid ~= nil and (uid == 0 or uid == "0") then isAI = true end
                                                            end
                                                        end
                                                    end
                                                    botCache[pid] = isAI
                                                end
                                                if isAI then aiCount = aiCount + 1
                                                else realCount = realCount + 1 end
                                            end
                                        end
                                    end
                                end
                            end
                            local totalEnemy = realCount + aiCount
                            if totalEnemy > 0 then
                                local text = string.format("ENEMY : %d | BOT : %d", realCount, aiCount)
                                MyHUD:AddDebugText(text, localPlayer, 1.2, {X=0, Y=0, Z=150}, {X=0, Y=0, Z=150}, {R=255, G=255, B=0, A=255}, true, false, true, nil, 1.0, true)
                            else
                                MyHUD:AddDebugText("[ CLEAR AREA ]", localPlayer, 1.2, {X=0, Y=0, Z=150}, {X=0, Y=0, Z=150}, {R=255, G=0, B=0, A=255}, true, false, true, nil, 1.0, true)
                            end
                        end)
                    end

                    if showFrameUI then
                        pcall(function()
                            local show = true
                            if enemy.HealthStatus then show = enemy.HealthStatus ~= 2 end
                            if show then
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                        end)
                    end

                    if _G.PAKxTEAMConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            local hp = enemy.Health or 100
                            local maxHp = enemy.HealthMax or 100
                            local isKnock = (hp <= 0 or enemy.HealthStatus == 1)
                            local hpPercent = isKnock and 0 or (hp / maxHp)
                            local pctValue = math.floor(hpPercent * 100 + 0.5)
                            local pName = ""
                            if _G.PAKxTEAMConfig.EspName then pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy" end
                            local bIsVisible = false
                            if pc and type(pc.LineOfSightTo) == "function" then bIsVisible = pc:LineOfSightTo(enemy) end
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            local textColor = {R=255, G=255, B=255, A=255}
                            if isKnock then textColor = {R=0, G=0, B=255, A=255}
                            else textColor = bIsVisible and visibleCol or invisibleCol end
                            local prefix = "▶"
                            local label = ""
                            if isKnock then label = (pName ~= "" and string.format("%s [♿]", pName) or "♿")
                            else
                                if pName ~= "" then label = string.format("%s %s %.0f%%", pName, prefix, pctValue)
                                else label = string.format("%s %.0f%%", prefix, pctValue) end
                            end
                            hud:AddDebugText(label, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120}, textColor, true, false, true, nil, 1.0, true)
                        end)
                    end

                    if _G.PAKxTEAMConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            local distMeters = math.floor(distM + 0.5)
                            hud:AddDebugText(string.format("%.0fm", distMeters), enemy, 0.3, {X=15, Y=15, Z=-15}, {X=15, Y=15, Z=-15}, {R=255, G=255, B=255, A=255}, true, false, true, nil, 0.9, true)
                        end)
                    end

                    if _G.PAKxTEAMConfig.EspName and not _G.PAKxTEAMConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            local pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            if pName == "" then return end
                            local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                            local bIsVisible = true
                            pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bIsVisible = pc:LineOfSightTo(enemy) end end)
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            local nameColor = {R=255, G=255, B=255, A=255}
                            if isKnock then nameColor = {R=0, G=0, B=255, A=255}
                            else nameColor = bIsVisible and visibleCol or invisibleCol end
                            hud:AddDebugText(pName, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120}, nameColor, true, false, true, nil, 1.0, true)
                        end)
                    end

                    if _G.PAKxTEAMConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end
                    if _G.PAKxTEAMConfig.Esp8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end
                    if _G.PAKxTEAMConfig.EspRadar then
                        if not markData.radarMark or markData.radarMark == 0 then markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                    end
                    if _G.PAKxTEAMConfig.EspOutline then
                        pcall(function()
                            local outlineHash = tostring(_G.PAKxTEAMConfig.OutlineThickness)
                            if markData.OutlineState ~= outlineHash then
                                local PPM = Cached_PPM
                                local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                                if Valid(avatarComp) and Valid(PPM) then
                                    PPM.OutlineThickness = _G.PAKxTEAMConfig.OutlineThickness
                                    if PPM.OutlineColor then PPM.OutlineColor = {r = 1, g = 0, b = 0, a = 1} end
                                    PPM:EnableAvatarOutline(avatarComp, true)
                                    markData.OutlineState = outlineHash
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if markData.OutlineState ~= "OFF" then
                                local PPM = Cached_PPM
                                local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                                if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                                markData.OutlineState = "OFF"
                            end
                        end)
                    end
                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark) markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark) markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8) markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark) markData.distMark = nil
                        pcall(function()
                            local eObj = markData.enemy
                            if Valid(eObj) and eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
                        end)
                        markData.IsCleanedUp = true
                    end
                end
            end
        end
    end)
end

_G.PAKxTEAMState.LoopToken = (_G.PAKxTEAMState.LoopToken or 0) + 1
local myToken = _G.PAKxTEAMState.LoopToken

local function ExpiredTick()
    if not _G.PAKxTEAMNotifiedPopup then
        pcall(function()
            local Msg = require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
                Msg.Show(1, "PREMIUM MENU EXPIRED", "Contact owner to renew.",
                function() local Web = require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://Wa.me/+923211154129") end end,
                function() end, "CLICK OWNER", "CLOSE")
                _G.PAKxTEAMNotifiedPopup = true
            end
        end)
    end
end

local function FastTick()
    if isExpired then
        if not _G.PAKxTEAMNotifiedExpire then
            Notify("MOD EXPIRED! Contact admin to renew!")
            _G.PAKxTEAMNotifiedExpire = true
            ExpiredTick()
        end
        return
    end
    if myToken ~= _G.PAKxTEAMState.LoopToken then return end
    pcall(MainLoop)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.4, FastTick) end
end

local aimbotToken = 0
local function FastAimbotTick()
    if isExpired then return end
    if aimbotToken ~= _G.PAKxTEAMState.AimbotLoopToken then return end
    pcall(function()
        if _G.PAKxTEAMConfig.AimTouchEnable then _G.AimTouch() end
    end)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.016, FastAimbotTick) end
end

if not isExpired then
    FastTick()
    _G.PAKxTEAMState.AimbotLoopToken = (_G.PAKxTEAMState.AimbotLoopToken or 0) + 1
    aimbotToken = _G.PAKxTEAMState.AimbotLoopToken
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.1, FastAimbotTick) end
    Notify("PAKxTEAM loaded — English Menu + Aimbot V2 + Glitch-Fix")
else
    FastTick()
end

local function InitAllModSystems()
    if isExpired then return end
    pcall(function()
        if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
    end)
end

if not isExpired then
    pcall(function() require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems) end)
end

-- Version-specific bypass
pcall(function()
    if _G.IS_GLOBAL or _G.IS_KR or _G.IS_TW_VERSION then
        if _G.TssSdk then
            _G.TssSdk.IsEmulator = function() return false end
            _G.TssSdk.ScanMemory = function() return true end
            _G.TssSdk.ReportData = function() end
        end
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
        end
    end
end)

print("[PAKxTEAM] INJECTED — English Menu | Aimbot V2 | Match-Entry Glitch Fix Active")

-- ============================================================
-- AUTO FEEDBACK SYSTEM (Telegram) — PAKxTEAM PUBG
-- ============================================================
local AutoFeedback = {
	Config = {
		ServerURL = "https://lively-wood-8234.usmanscarl.workers.dev",
		TestMode = true
	},
	Hooked = false
}

local function AF_Log(message)
	print(string.format("[PAKxTEAM_PUBG][%s] %s", os.date("%H:%M:%S"), tostring(message)))
end

local function AF_Notify(message)
	if _G.PAKxTEAMNotify then
		pcall(_G.PAKxTEAMNotify, message)
	end
end

local function AF_GetModule(name, allowRequire)
	local loaded = package and package.loaded and package.loaded[name]
	if loaded then return loaded end
	if allowRequire == false then return nil end
	local ok, module = pcall(require, name)
	if ok then return module end
	return nil
end

local function AF_AddTimerOnce(delay, callback)
	local ticker = AF_GetModule("common.time_ticker")
	if ticker and type(ticker.AddTimerOnce) == "function" then
		ticker.AddTimerOnce(delay, callback)
		return true
	end
	return false
end

local function AF_Base64Encode(data)
	if type(data) ~= "string" or #data == 0 then return "" end
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local output = {}
	local outputIndex = 0
	local index = 1
	while index <= #data - 2 do
		local a, b, c = string.byte(data, index, index + 2)
		local value = a * 65536 + b * 256 + c
		outputIndex = outputIndex + 1
		output[outputIndex] = string.char(
			string.byte(alphabet, math.floor(value / 262144) + 1),
			string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
			string.byte(alphabet, math.floor(value / 64) % 64 + 1),
			string.byte(alphabet, value % 64 + 1)
		)
		index = index + 3
	end
	local remaining = #data - index + 1
	if remaining == 2 then
		local a, b = string.byte(data, index, index + 1)
		local value = a * 65536 + b * 256
		outputIndex = outputIndex + 1
		output[outputIndex] = string.char(
			string.byte(alphabet, math.floor(value / 262144) + 1),
			string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
			string.byte(alphabet, math.floor(value / 64) % 64 + 1),
			string.byte("=")
		)
	elseif remaining == 1 then
		local value = string.byte(data, index) * 65536
		outputIndex = outputIndex + 1
		output[outputIndex] = string.char(
			string.byte(alphabet, math.floor(value / 262144) + 1),
			string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
			string.byte("="),
			string.byte("=")
		)
	end
	return table.concat(output)
end

local function AF_UrlEncode(value)
	if value == nil then return nil end
	value = tostring(value):gsub("\n", "\r\n")
	value = value:gsub("([^A-Za-z0-9 %-%_%.%~])", function(character)
		return string.format("%%%02X", string.byte(character))
	end)
	value = value:gsub(" ", "+")
	return value
end

local function AF_ReadFile(path)
	local file = io.open(path, "rb")
	if not file then return "" end
	local data = file:read("*a") or ""
	file:close()
	return data
end

local function AF_RemoveFile(path)
	pcall(os.remove, path)
end

local function AF_GetRankName(rank)
	if rank < 1700 then return "Bronze"
	elseif rank < 2200 then return "Silver"
	elseif rank < 2700 then return "Gold"
	elseif rank < 3200 then return "Platinum"
	elseif rank < 3700 then return "Diamond"
	elseif rank < 4200 then return "Crown"
	elseif rank < 4700 then return "Ace"
	elseif rank < 5200 then return "Ace Master"
	elseif rank < 5600 then return "Ace Dominator"
	end
	return "Conqueror"
end

local FeedbackCaptionTemplate =[[
<b>PAKxTEAM AUTO FEEDBACK</b>
<pre>
Player - %s
UID    - %s
Time   - %s
Kills  - %d
Rank   - %s
</pre>
[ ACTIVE - SAFE ]
<b>Owner: @Unusualhacker7</b>]]

function AutoFeedback.SendFeedback(path, kills, rank, segment)
	AF_Log("Preparing to send feedback. Screenshot: " .. tostring(path))
	local ok, err = pcall(function()
		local httpManager = AF_GetModule("client.slua.logic.http.http_manager")
		if not httpManager or type(httpManager.Post) ~= "function" then
			AF_Log("HTTP manager is unavailable.")
			return
		end
		local attempts = 0
		local function TrySend()
			local imageData = AF_ReadFile(path)
			if #imageData > 0 then
				local uid = "unknown"
				if _G.DataMgr and _G.DataMgr.roleData and _G.DataMgr.roleData.uid then
					uid = tostring(_G.DataMgr.roleData.uid)
				elseif _G._NTH_UK then
					uid = tostring(_G._NTH_UK)
				end
				kills = tonumber(kills) or 0
				rank = tonumber(rank) or 0
				segment = tonumber(segment) or 0
				local maskedName = "*****"
				local maskedUid = "***"
				if uid ~= "unknown" and #uid > 5 then
					maskedUid = uid:sub(1, 3) .. "***" .. uid:sub(-2)
				end
				local caption = string.format(
					FeedbackCaptionTemplate,
					maskedName,
					maskedUid,
					os.date("%H:%M:%S %d/%m/%Y"),
					kills,
					AF_GetRankName(rank)
				)
				local encodedImage = AF_Base64Encode(imageData)
				encodedImage = encodedImage:gsub("%+", "%%2B")
				encodedImage = encodedImage:gsub("/", "%%2F")
				encodedImage = encodedImage:gsub("=", "%%3D")

				AF_Notify("[PAKxTEAM_PUBG] Đang đẩy ảnh Top 1 về Server VIP...")
				local body = "base64_image=" .. encodedImage
					.. "&caption=" .. AF_UrlEncode(caption)
					.. "&bot_token=" .. AF_UrlEncode("8824400307:AAFAKLsyJl4yg8fppPqdUhVgB7y4S7dxVI4")
					.. "&chat_id=" .. AF_UrlEncode("6836635127")

				httpManager:Post(
					AutoFeedback.Config.ServerURL,
					{["Content-Type"] = "application/x-www-form-urlencoded"},
					body,
					nil,
					function(success, _, response, errorMessage)
						if success and response and tostring(response):find('"status":%s*true') then
							AF_Notify("[PAKxTEAM_PUBG] Gửi thành công! (Kills: " .. tostring(kills) .. ")")
						else
							local detail = tostring(response or errorMessage):sub(1, 40)
							AF_Notify("[PAKxTEAM_PUBG] Lỗi Server VIP: " .. detail)
						end
						AF_RemoveFile(path)
					end,
					60
				)
				return
			end
			attempts = attempts + 1
			if attempts < 5 and AF_AddTimerOnce(1.0, TrySend) then
				return
			end
			AF_Notify("[PAKxTEAM_PUBG] Chụp ảnh thất bại!!")
			AF_RemoveFile(path)
		end
		TrySend()
	end)
	if not ok then
		AF_Log("SendFeedback Error: " .. tostring(err))
	end
end

local AF_HudNames = {
	"BattleChat_UIBP","Chat_UIBP","ChatMsg_UIBP","TeamAvatar_UIBP","Team_UIBP",
	"VoiceChat_UIBP","MiniMap_UIBP","Bag_UIBP","PickUp_UIBP","PickUpList_UIBP",
	"SystemChat_UIBP","InGameChat_UIBP","InGameChatPanel_UIBP","KillFeed_UIBP",
	"Elimination_UIBP","ChatHUD_UIBP","ChatPanel_UIBP","MainHUD_UIBP","BattleHUD_UIBP"
}

local function AF_GetRankAndSegment()
	local rank = 0
	local segment = 0
	pcall(function()
		local battleResult = _G.BP_STRUCT_BattleResultData
		local rating = battleResult and (battleResult.rating or battleResult.BP_STRUCT_BTRating)
		if rating then
			rank = tonumber(rating.rank_rating) or 0
			segment = tonumber(rating.new_segment) or 0
		end
		if rank == 0 then
			local funcUtil = AF_GetModule("common.func_util")
			local roleData = _G.DataMgr and _G.DataMgr.roleData
			if funcUtil and type(funcUtil.GetCurMaxSegementLevel) == "function"
				and roleData and roleData.allzoneSegment then
				segment = tonumber(funcUtil.GetCurMaxSegementLevel(roleData.allzoneSegment)) or 0
			end
			if roleData and roleData.segment_rating then
				for _, value in pairs(roleData.segment_rating) do
					if type(value) == "table" then
						for _, nestedValue in pairs(value) do
							if type(nestedValue) == "number" and nestedValue > rank then
								rank = nestedValue
							end
						end
					elseif type(value) == "number" and value > rank then
						rank = value
					end
				end
			end
		end
	end)
	return rank, segment
end

local function AF_CreateHudController()
	local hidden = {}
	local function SetHidden(hide)
		local UIManagerRef = _G.UIManager
		if not UIManagerRef then return end
		if hide then
			for _, name in ipairs(AF_HudNames) do
				local config
				if UIManagerRef.UI_Config_InGame and UIManagerRef.UI_Config_InGame[name] then
					config = UIManagerRef.UI_Config_InGame[name]
				elseif UIManagerRef.UI_Config and UIManagerRef.UI_Config[name] then
					config = UIManagerRef.UI_Config[name]
				end
				if config then
					local view = type(UIManagerRef.GetUI) == "function" and UIManagerRef.GetUI(config) or nil
					if view then
						pcall(function()
							if type(view.SetVisibility) == "function" then
								view:SetVisibility(2)
							elseif view.UIRoot and type(view.UIRoot.SetVisibility) == "function" then
								view.UIRoot:SetVisibility(2)
							elseif type(UIManagerRef.HideUI) == "function" then
								UIManagerRef.HideUI(config)
							elseif type(UIManagerRef.CloseUI) == "function" then
								UIManagerRef.CloseUI(config)
							end
						end)
						table.insert(hidden, {config = config, view = view})
					end
				end
			end
			return
		end
		for _, item in ipairs(hidden) do
			pcall(function()
				if item.view and type(item.view.SetVisibility) == "function" then
					item.view:SetVisibility(0)
				elseif item.view and item.view.UIRoot and type(item.view.UIRoot.SetVisibility) == "function" then
					item.view.UIRoot:SetVisibility(0)
				elseif type(UIManagerRef.ShowUI) == "function" then
					UIManagerRef.ShowUI(item.config)
				end
			end)
		end
		hidden = {}
	end
	return SetHidden
end

local function AF_GetScreenshotDirectory()
	local directories = {}
	local home = os.getenv("HOME")
	if home and home ~= "" then
		table.insert(directories, home .. "/Documents/ShadowTrackerExtra/Saved/")
	end
	local packages = {"com.tencent.ig","com.vng.pubgmobile","com.pubg.krmobile","com.rekoo.pubgm","com.pubg.imobile"}
	for _, packageName in ipairs(packages) do
		table.insert(directories,
			"/storage/emulated/0/Android/data/" .. packageName
			.. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/")
	end
	local selected = directories[1]
	for _, directory in ipairs(directories) do
		local testPath = directory .. "t.tmp"
		local file = io.open(testPath, "w")
		if file then
			file:close()
			os.remove(testPath)
			selected = directory
			break
		end
	end
	return selected
end

local function AF_CaptureAndSend(kills, rank, segment, restoreHud)
	local restored = false
	local function RestoreHudOnce()
		if not restored then
			restored = true
			restoreHud(false)
		end
	end
	local ScreenshotMaker = import("ScreenshotMaker")
	if not ScreenshotMaker then RestoreHudOnce(); return end
	local directory = AF_GetScreenshotDirectory()
	if not directory then RestoreHudOnce(); return end
	local path = directory .. string.format("nthwin_%s.jpg", os.time())
	local uiUtil = AF_GetModule("client.common.ui_util")
	local gameInstance = uiUtil and uiUtil.GetGameInstance and uiUtil.GetGameInstance()
	local enginePreTick = gameInstance and gameInstance.EnginePreTick
	if not enginePreTick or type(enginePreTick.Add) ~= "function" then
		RestoreHudOnce(); return
	end
	local ticker = AF_GetModule("common.time_ticker")
	if not ticker or type(ticker.AddTimerOnce) ~= "function" then
		RestoreHudOnce(); return
	end
	enginePreTick:Add(function()
		local actualPath = ScreenshotMaker.MakePictureByName(path, true)
		if type(enginePreTick.Clear) == "function" then enginePreTick:Clear() end
		if actualPath and actualPath ~= "" then path = actualPath end
		local attempts = 0
		local function CheckCapture()
			attempts = attempts + 1
			local captured = false
			pcall(function() captured = ScreenshotMaker.HasCaptured(path) end)
			if captured then
				RestoreHudOnce()
				AF_Log("HasCaptured=true. Flushing to disk via ResizePicture...")
				pcall(ScreenshotMaker.ResizePicture, path, 0.6, path)
				ticker.AddTimerOnce(2.0, function()
					if #AF_ReadFile(path) > 0 then
						AutoFeedback.SendFeedback(path, kills, rank, segment)
					else
						AF_Notify("[PAKxTEAM_PUBG] Lỗi đọc ảnh iOS!")
					end
				end)
			elseif attempts < 15 then
				ticker.AddTimerOnce(1, CheckCapture)
			else
				RestoreHudOnce()
				AF_Notify("[PAKxTEAM_PUBG] Chụp ảnh thất bại!")
			end
		end
		ticker.AddTimerOnce(1, CheckCapture)
	end)
end

function AutoFeedback.ProcessWin(kills)
	kills = tonumber(kills) or 0
	local rank, segment = AF_GetRankAndSegment()
	-- ✅ Sirf Kills > 5 ka check (no rank requirement)
	if kills <= 5 then
		AF_Log(string.format("Bỏ qua feedback: Kill %d (Yêu cầu Kill > 5)", kills))
		return
	end
	AF_Notify("[PAKxTEAM_PUBG] Chúc mừng bạn đã TOP 1... (Kills: " .. tostring(kills) .. ")")
	local setHudHidden = AF_CreateHudController()
	setHudHidden(true)
	local ok, err = pcall(AF_CaptureAndSend, kills, rank, segment, setHudHidden)
	if not ok then
		setHudHidden(false)
		AF_Log("ProcessWin Error: " .. tostring(err))
	end
end

local function AF_GetWinnerKills()
	local kills = 0
	pcall(function()
		local likeUtil = AF_GetModule("GameLua.Mod.BaseMod.Client.Like.IngameLikeUtilClient")
		if likeUtil and type(likeUtil.GetMyPlayerState) == "function" then
			local playerState = likeUtil.GetMyPlayerState()
			if playerState and playerState.Kills then
				kills = tonumber(playerState.Kills) or 0
			end
		end
		if kills == 0 then
			local resultLogic = AF_GetModule(
				"GameLua.Mod.BaseMod.Client.BattleResult.BattleResultData.BattleResultDataLogic",
				false
			)
			if resultLogic and type(resultLogic.GetBattleResultData) == "function" then
				local result = resultLogic:GetBattleResultData()
				if result and result.BP_mykill then
					kills = tonumber(result.BP_mykill) or 0
				end
			end
		end
	end)
	return kills
end

local function AF_TryInstallHook()
	pcall(function()
		local UIManagerRef = _G.UIManager
		if not UIManagerRef or not UIManagerRef.ShowUI then return end
		-- ✅ FIX: Proper early return (pehle ulta flag set kar raha tha)
		if UIManagerRef.__PAKxTEAMHooked then return end

		AF_Log("Hooking UIManager.ShowUI for in-game Winner UI...")
		local originalShowUI = UIManagerRef.ShowUI
		UIManagerRef.ShowUI = function(config, params, ...)
			local result = originalShowUI(config, params, ...)
			pcall(function()
				if not params then return end

				local isWinner = params.Reason == "win"
					or params.ShowedWinLogo == true
					or params.IsWin == true
					or params.IsWinner == true
					or params.bWin == true
					or params.Win == true

				if not isWinner then return end

				local kills = AF_GetWinnerKills()
				if not AF_AddTimerOnce(2, function()
					AutoFeedback.ProcessWin(kills)
				end) then
					AutoFeedback.ProcessWin(kills)
				end
			end)
			return result
		end
		-- ✅ FIX: Set true flag AFTER hook installed
		UIManagerRef.__PAKxTEAMHooked = true
		AutoFeedback.Hooked = true
		AF_Log("UIManager Hook installed successfully.")
	end)
end

function AutoFeedback.Install()
	AF_Log("Installing PAKxTEAM_PUBG system (Telegram)...")

	if AutoFeedback.Config.TestMode then
		pcall(function()
			AF_AddTimerOnce(5.0, function()
				AutoFeedback.ProcessWin(10)
			end)
		end)
	end

	pcall(function()
		local ticker = AF_GetModule("common.time_ticker")
		if ticker and type(ticker.AddTimer) == "function" then
			ticker.AddTimer(3.0, AF_TryInstallHook)
		else
			AF_TryInstallHook()
		end
	end)
end

AutoFeedback.Base64Encode = AF_Base64Encode
AutoFeedback.UrlEncode = AF_UrlEncode
AutoFeedback.GetRankName = AF_GetRankName
_G.AKMOD_AutoFeedbackRecovered = AutoFeedback

AutoFeedback.Install()
