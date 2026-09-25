local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Object }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Bool }
}

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local KismetSystemLibrary = import("KismetSystemLibrary")
local packageName = KismetSystemLibrary and KismetSystemLibrary.GetGameBundleId()

-- ============================================================
-- PACKAGE DETECTION
-- ============================================================
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

-- ============================================================
-- ANTI-BAN SYSTEM (SAFE)
-- ============================================================
local function CompleteAntiBanSystem()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.OnRecvData = function() end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
            TssSdk.IsEmulator = function() return false end
            TssSdk.GetTssSdkReportInfo = function() return "" end
            TssSdk.CheckIntegrity = function() return true end
            TssSdk.VerifySignature = function() return true end
            TssSdk.ReportData = function() end
            TssSdk.ReportViolation = function() end
            TssSdk.ReportCheat = function() end
            TssSdk.ReportHack = function() end
            TssSdk.ReportMod = function() end
            TssSdk.ReportInject = function() end
            TssSdk.ReportHook = function() end
            TssSdk.ReportPatch = function() end
            TssSdk.ReportTamper = function() end
        end
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = function() end
            ace.CheckIntegrity = function() return true end
            ace.ScanMemory = function() return false end
            ace.ReportCheat = function() end
            ace.ReportViolation = function() end
        end
        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            XignCode.SendReport = function() end
            XignCode.CheckProcess = function() return true end
            XignCode.VerifyIntegrity = function() return true end
            XignCode.ReportCheat = function() end
        end
        local BattlEye = _G.BattlEye or package.loaded["BattlEye"]
        if BattlEye then
            BattlEye.SendReport = function() end
            BattlEye.KickPlayer = function() end
            BattlEye.ValidatePlayer = function() return true end
        end
        local HiggsBosonComponent = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if HiggsBosonComponent then
            HiggsBosonComponent.bIsEnable = false
            HiggsBosonComponent.bMHActive = false
            HiggsBosonComponent.bCallPreReplication = false
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
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
        }
        for _, path in ipairs(reportPaths) do
            local module = package.loaded[path] or (pcall(require, path) and require(path))
            if module then
                if module.Report then module.Report = function() end end
                if module.SendReport then module.SendReport = function() end end
                if module.ReportEvent then module.ReportEvent = function() end end
                if module.ReportException then module.ReportException = function() end end
                if module.ReportData then module.ReportData = function() end end
                if module.ReportTLogEvent then module.ReportTLogEvent = function() end end
            end
        end
        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            local noop = function() end
            GC.ReportAttackFlow = noop
            GC.ReportSecAttackFlow = noop
            GC.ReportHurtFlow = noop
            GC.ReportFireArms = noop
            GC.ReportAimFlow = noop
            GC.ReportHitFlow = noop
            GC.ReportPlayerBehavior = noop
            GC.ReportTeammatHurt = noop
            GC.ReportMisKillByTeammate = noop
            GC.ReportForbitPick = noop
            GC.ReportPlayerMoveRoute = noop
            GC.ReportPlayerPosition = noop
            GC.ReportVehicleMoveFlow = noop
            GC.ReportSecTgameMovingFlow = noop
            GC.ReportParachuteData = noop
            GC.SendTssSdkAntiDataToLobby = noop
            GC.ReportEquipmentFlow = noop
            GC.ReportPlayersPing = noop
            GC.ReportPlayerIP = noop
            GC.ReportDSNetSaturation = noop
            GC.ReportNetContinuousSaturate = noop
            GC.ReportDSNetRate = noop
            GC.ReportCircleFlow = noop
            GC.ReportJumpFlow = noop
            GC.ReportMatchRoomData = noop
            GC.IsBypassed = true
        end
        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blockedPackets = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1,
                ["ReportCircleFlow"]=1, ["ReportJumpFlow"]=1,
                ["report_players_ping"]=1, ["report_player_ip"]=1,
                ["report_net_saturate"]=1, ["report_ds_netsaturate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1,
                ["report_client_scan_result"]=1, ["tss_sdk_report"]=1,
                ["report_memory_exception"]=1, ["report_avatar_exception"]=1,
                ["ReportSecurityAlert"]=1, ["ReportAntiCheat"]=1, ["ReportSuspiciousActivity"]=1,
                ["ReportViolation"]=1, ["ReportBan"]=1, ["ReportKick"]=1,
                ["ReportCheat"]=1, ["ReportHack"]=1, ["ReportMod"]=1,
                ["ReportInject"]=1, ["ReportHook"]=1, ["ReportPatch"]=1,
                ["ReportTamper"]=1, ["ReportCorrupt"]=1, ["ReportInvalid"]=1,
                ["ReportSpoof"]=1, ["ReportFake"]=1, ["ReportClone"]=1,
                ["ReportDuplicate"]=1, ["ReportConflict"]=1, ["ReportOverlap"]=1,
                ["ReportMismatch"]=1, ["ReportInconsistent"]=1, ["ReportUnexpected"]=1,
                ["ReportUnknown"]=1,
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPackets[packetName] then return end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
        local CrashSight = _G.CrashSight or package.loaded["CrashSight"]
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end
            CrashSight.Log = function() end
            CrashSight.UploadLog = function() end
            CrashSight.SendReport = function() end
        end
        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then
            TLog.Info = function() end
            TLog.Warning = function() end
            TLog.Error = function() end
            TLog.Debug = function() end
            TLog.Report = function() end
            TLog.Flush = function() end
        end
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = function() return "" end
            ScreenshotMaker.ReMakePicture = function() return "" end
            ScreenshotMaker.HasCaptured = function() return true end
        end
        local FileCheckSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("FileCheckSubsystem")
        if FileCheckSubsystem then
            FileCheckSubsystem.StartCheck = function() end
            FileCheckSubsystem.ReportAbnormalFile = function() end
            FileCheckSubsystem.VerifyFile = function() return true end
        end
        local ShootVerifySubSystemClient = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ShootVerifySubSystemClient")
        if ShootVerifySubSystemClient then
            ShootVerifySubSystemClient.ReportVerifyFail = function() end
            ShootVerifySubSystemClient.OnVerifyFailed = function() end
            ShootVerifySubSystemClient.CheckShoot = function() return true end
        end
        local AFKReportorSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AFKReportorSubsystem")
        if AFKReportorSubsystem then
            AFKReportorSubsystem.PlayerHaveAction = function() end
            AFKReportorSubsystem.ReportAFK = function() end
        end
        local AvatarExceptionSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AvatarExceptionSubsystem")
        if AvatarExceptionSubsystem then
            AvatarExceptionSubsystem.ReportException = function() end
            AvatarExceptionSubsystem.CheckAvatarValid = function() return true end
        end
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.IsEmulator = function() return false end
            SystemInfo.IsRooted = function() return false end
            SystemInfo.IsDebugged = function() return false end
        end
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
            CreativeModeBlueprintLibrary.VerifyContent = function() return true end
        end
        local TDataMaster = _G.TDataMaster or package.loaded["libTDataMaster.so"]
        if TDataMaster then
            TDataMaster.ReportEvent = function() end
            TDataMaster.ReportException = function() end
            TDataMaster.FlushData = function() end
            TDataMaster.CollectData = function() return {} end
        end
        print('[PAKxTEAM] ANTI-BAN SYSTEM ACTIVE!')
    end)
end

pcall(CompleteAntiBanSystem)

-- ============================================================
-- ADDITIONAL BYPASS LAYERS
-- ============================================================
do
    local function nop() end
    local function retFalse() return false end
    local function retTrue() return true end

    local function ClientEntryBypass()
        pcall(function()
            if Client then
                Client.SetTssNetworkStatus = nop
                Client.GEMReportEnterLobbyEvent = nop
                Client.TPerforPlatDisconnectReport = nop
                Client.IsConnected = function() return true end
            end
        end)
    end

    local function BanLogicBypass()
        pcall(function()
            if ClientBanLogic then
                ClientBanLogic.ReqBanInfo = nop
                ClientBanLogic.OnVoiceBanNotify = nop
                ClientBanLogic.OnSyncBanInfo = nop
                ClientBanLogic.IsVoiceReportEnable = retFalse
            end
            if RealTimeBan then
                RealTimeBan.Init = function() return end
                RealTimeBan.OnPlayerWithRealTimeBan = nop
                RealTimeBan.IsUIDOnRankInspector = retFalse
            end
        end)
    end

    local function MD5Bypass()
        pcall(function()
            local CMode = import("CreativeModeBlueprintLibrary")
            if CMode then
                CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
                CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
                CMode.GetContentDiffData = function() return true, "BYPASSED" end
                CMode.VerifyFileIntegrity = retTrue
            end
        end)
    end

    local function PAKxTEAMBypass()
        pcall(function()
            local PAKxTEAM = package.loaded["GameLua.Mod.BaseMod.Client.Security.PAKxTEAM"]
            if PAKxTEAM then
                PAKxTEAM.ForwardFeature = function() return {0,0,0,0,0} end
                PAKxTEAM.InitPAKxTEAMLogic = nop
            end
        end)
    end

    local function RacingAntiCheatBypass()
        pcall(function()
            if RacingAntiCheatLogic then
                RacingAntiCheatLogic.HandleRacingEnter = nop
                RacingAntiCheatLogic.HandleRacingStart = nop
                RacingAntiCheatLogic.HandleRacingEnd = nop
                RacingAntiCheatLogic.DetectVehicleFloating = nop
                RacingAntiCheatLogic.HandleFloatingCheat = nop
            end
        end)
    end

    local function KillAllSubsystems()
        pcall(function()
            local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            if SubMgr then
                local toKill = {"CoronaLabSubsystem","PlayerSecurityInfoSubsystem","ClientCircleFlowSubsystem","ModifierExceptionSubsystem","SimulateCharacterSubsystem","ShootVerifySubSystemClient","HiggsBosonComponent","ClientReportPlayerSubsystem","DSReportPlayerSubsystem","ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientDataStatistcsSubsystem","AFKReportorSubsystem","BehaviorScoreSubsystem","FileCheckSubsystem","MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem","AvatarExceptionSubsystem","GameReportSubsystem","AntiCheatSubsystem","IntegrityCheckSubsystem","SignatureVerifySubsystem","MD5CheckSubsystem","PakVerifySubsystem"}
                for _, name in ipairs(toKill) do
                    local sub = SubMgr:Get(name)
                    if sub then
                        for k, v in pairs(sub) do
                            if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow")) then pcall(function() sub[k] = nop end) end
                        end
                    end
                end
            end
        end)
    end

    pcall(ClientEntryBypass)
    pcall(BanLogicBypass)
    pcall(MD5Bypass)
    pcall(PAKxTEAMBypass)
    pcall(RacingAntiCheatBypass)
    pcall(KillAllSubsystems)
end

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
    if not _G.__MatchReady then return end
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

    if _G.PAKxTEAMState.CustomTextData == nil then
        _G.PAKxTEAMState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120}
    end
    local okData, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GD then return end
    local pc = GD.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if not Valid(localPlayer) then
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
        if GD.GetAllPlayerCharacters then allCharacters = GD.GetAllPlayerCharacters()
        elseif GD.GameCharacters then for _, char in pairs(GD.GameCharacters) do table.insert(allCharacters, char) end end

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

-- ==============================================================================
-- ============================ CLASS FUNCTIONS ================================
-- ==============================================================================

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    GameplayData.AddCharacter(self.Object)
    self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
    self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
  if not slua.isValid(uVehicle) then return end
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
  if not slua.isValid(uLastVehicle) then return end
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle) end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer() end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
    self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local EGameModeType = import("EGameModeType")
    local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  local EParachuteState = import("EParachuteState")
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
  if self.HandleOnLanded then self:HandleOnLanded(-1) end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState() end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI() end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then GameplayData.RemoveCharacter(self.Object) end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  local STExtraGameStateBase = import("STExtraGameStateBase")
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    local EGameModeType = import("EGameModeType")
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  end
  return false
end

function BRPlayerCharacterBase:BPOnRecycled() end
function BRPlayerCharacterBase:BPOnRespawned() end
function BRPlayerCharacterBase:ReceiveOnRecycle() end
function BRPlayerCharacterBase:ReceiveOnSpawn() end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation() end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  local EMovementMode = import("EMovementMode")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      local EStateType = import("EStateType")
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        local ESTEPoseState = import("ESTEPoseState")
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
    end
  end
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then return false end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then uPlayerController:DisplayGameTipWithMsgID(48532) end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then uPlayerState:AddGeneralCount(1613, 1, false) end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then self:MulticastRPC_GmPlayAction(actionId) end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then return end
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then return end
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then return end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  local loadLater = function() uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0) end
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(b)
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = b
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt) end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID) self:SetAttrValue("AreaID", AreaID, -1) end
function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end

function BRPlayerCharacterBase:DoModChangeToBT()
  if self:HasState(EPawnState.SpecialSuit) then self:TriggerEntrySkillWithID(4301101, true) end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
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
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ==============================================================================
-- ============================ CLASS WRAPPER ==================================
-- ==============================================================================

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")
