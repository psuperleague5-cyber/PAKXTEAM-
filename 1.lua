-- ============================================================
-- XTEAM LOADER v4.5 + XTEAM ESP/WALLHACK MERGED (COMPLETE)
-- Full working ESP, Wallhack, Distance, Counter, Color V2
-- Telegram: @XTEAM_XD
-- ============================================================

-- ===== PREVENT DOUBLE LOAD =====
if _G.XTEAM_LOADER_LOADED then
    print("[XTEAM] Loader already active. Skipping.")
    return
end
_G.XTEAM_LOADER_LOADED = true
print("[XTEAM] 🚀 Starting XTEAM Loader...")

-- ============================================================
-- 1. GLOBAL CONFIG & STATE
-- ============================================================
_G.XTEAMConfig = _G.XTEAMConfig or {
    AutoHead = false, EspVip = false, EspDistance = true, EspVipPro = false,
    EspRadar = false, Esp5 = false, Esp6 = false, Esp7 = true, Esp8 = false,
    EspAntenna = false, EspName = false, EspOutline = false, OutlineThickness = 10,
    UnlockFPS = false, IpadView = false, CustomAimbot = false, CustomAimbotClose = false,
    CustomHRecoil = false, CustomVRecoil = false, LessShake = false,
    RemoveGrass = false, RemoveFog = false, WhiteBody = false, ColorBodyV2 = false,
    wallhackng = false, Crosshair = false, Accuracy = false, GodMode = false,
    BlackSky = false,
    AimTouchEnable = false, AimTouchIgKnock = true, AimTouchIgBot = true, AimTouchVisCheck = true,
    ModSkin = false,
}
_G.XTEAMState = _G.XTEAMState or {
    LoopToken = 0, AimbotLoopToken = 0, NativeESPReady = false, GraphicsUnlocked = false,
    MenuStep = 0, LastCmdTime = 0, TrackedMarks = {}, EnemyMarks = {},
    LastAimbotCheckTime = 0, CustomTextData = nil, PrevGraphicsState = {},
    SkinWasApplied = false, EnemyCounterWidget = nil, LastCounterUpdate = 0,
    IsAutoFiring = false,
}
_G.ColorConfig = _G.ColorConfig or {
    VisibleColor = 4, InvisibleColor = 1, Brightness = 25, Glow = 3.0,
}

-- ============================================================
-- 2. STATIC DEFINITIONS
-- ============================================================
local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}
local GLOBAL_BONE_LIST = {
    "head", "neck_01", "pelvis", "upperarm_r", "lowerarm_r", "hand_r",
    "upperarm_l", "lowerarm_l", "hand_l", "thigh_l", "calf_l", "foot_l",
    "thigh_r", "calf_r", "foot_r"
}
local mHead_Global = 0; local mBody_Global = 1; local mLegs_Global = 2

-- Distance colours (XTEAM)
local DIST_COLOR_RED = {R=255, G=0, B=0, A=255}
local DIST_COLOR_YELLOW = {R=255, G=255, B=0, A=255}
local DIST_COLOR_GREEN = {R=0, G=255, B=0, A=255}

-- ============================================================
-- 3. HELPER FUNCTIONS
-- ============================================================
local function nop() end
local function retTrue() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retEmptyString() return "" end

local function Valid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

local function Notify(msg)
    local s = "[GTLMOD VIP New] " .. tostring(msg)
    pcall(function() if _G.XTEAMNotify then _G.XTEAMNotify(s) end end)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print(s)
end

-- ============================================================
-- 4. BYPASS SYSTEM (CompleteAntiBanSystem + AdditionalBypass)
-- ============================================================
local function CompleteAntiBanSystem()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.OnRecvData = nop; TssSdk.SendReportInfo = nop; TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse; TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.ReportException = nop; TssSdk.ReportData = nop; TssSdk.CheckIntegrity = retTrue
            TssSdk.VerifySignature = retTrue; TssSdk.CollectEvidence = nop; TssSdk.UploadLog = nop
            TssSdk.SendAntiData = nop; TssSdk.ReportGameStart = nop; TssSdk.ReportGameEnd = nop
            TssSdk.ReportCrash = nop; TssSdk.ReportViolation = nop; TssSdk.ReportSuspicious = nop
            TssSdk.ReportBan = nop; TssSdk.ReportKick = nop; TssSdk.ReportWarning = nop
            TssSdk.ReportInfo = nop; TssSdk.ReportDebug = nop; TssSdk.ReportError = nop
            TssSdk.ReportFatal = nop; TssSdk.ReportMemory = nop; TssSdk.ReportProcess = nop
            TssSdk.ReportModule = nop; TssSdk.ReportThread = nop; TssSdk.ReportFile = nop
            TssSdk.ReportNetwork = nop; TssSdk.ReportDevice = nop; TssSdk.ReportSystem = nop
            TssSdk.ReportGame = nop; TssSdk.ReportUser = nop; TssSdk.ReportAccount = nop
            TssSdk.ReportSession = nop; TssSdk.ReportPerformance = nop; TssSdk.ReportBattery = nop
            TssSdk.ReportTemperature = nop; TssSdk.ReportFPS = nop; TssSdk.ReportPing = nop
            TssSdk.ReportPacket = nop; TssSdk.ReportCheat = nop; TssSdk.ReportHack = nop
            TssSdk.ReportMod = nop; TssSdk.ReportInject = nop; TssSdk.ReportDebugger = nop
            TssSdk.ReportEmulator = nop; TssSdk.ReportRoot = nop; TssSdk.ReportJailbreak = nop
            TssSdk.ReportVM = nop; TssSdk.ReportHook = nop; TssSdk.ReportPatch = nop
            TssSdk.ReportTamper = nop; TssSdk.ReportCorrupt = nop; TssSdk.ReportInvalid = nop
            TssSdk.ReportSpoof = nop; TssSdk.ReportFake = nop; TssSdk.ReportClone = nop
            TssSdk.ReportDuplicate = nop; TssSdk.ReportConflict = nop; TssSdk.ReportOverlap = nop
            TssSdk.ReportMismatch = nop; TssSdk.ReportInconsistent = nop
            TssSdk.ReportUnexpected = nop; TssSdk.ReportUnknown = nop
        end
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = nop; ace.CheckIntegrity = retTrue; ace.ScanMemory = retFalse
            ace.VerifyProcess = retTrue; ace.CheckModule = retTrue; ace.ReportViolation = nop
            ace.KickPlayer = nop; ace.BanPlayer = nop; ace.CollectInfo = retEmpty
            ace.SendReport = nop; ace.ValidateClient = retTrue; ace.CheckDebugger = retFalse
            ace.CheckEmulator = retFalse; ace.CheckRoot = retFalse; ace.ReportCheat = nop
            ace.ReportHack = nop; ace.ReportMod = nop; ace.ReportInject = nop
            ace.ReportHook = nop; ace.ReportPatch = nop; ace.ReportTamper = nop
            ace.ReportCorrupt = nop; ace.ReportInvalid = nop; ace.ReportSpoof = nop
            ace.ReportFake = nop
        end
        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            XignCode.SendReport = nop; XignCode.CheckProcess = retTrue; XignCode.VerifyIntegrity = retTrue
            XignCode.ScanModules = retEmpty; XignCode.ReportException = nop; XignCode.ValidateMemory = retTrue
            XignCode.CheckDebugger = retFalse; XignCode.KickPlayer = nop; XignCode.BanPlayer = nop
            XignCode.EncryptData = function(data) return data end; XignCode.DecryptData = function(data) return data end
            XignCode.ReportCheat = nop; XignCode.ReportHack = nop; XignCode.ReportMod = nop
            XignCode.ReportInject = nop; XignCode.ReportHook = nop; XignCode.ReportPatch = nop
            XignCode.ReportTamper = nop
        end
        local BattlEye = _G.BattlEye or package.loaded["BattlEye"]
        if BattlEye then
            BattlEye.SendReport = nop; BattlEye.KickPlayer = nop; BattlEye.ValidatePlayer = retTrue
            BattlEye.CheckMemory = retTrue; BattlEye.VerifyIntegrity = retTrue; BattlEye.ReportViolation = nop
            BattlEye.ScanProcess = retTrue; BattlEye.BanPlayer = nop; BattlEye.CollectEvidence = retEmpty
            BattlEye.ReportCheat = nop; BattlEye.ReportHack = nop; BattlEye.ReportMod = nop
            BattlEye.ReportInject = nop; BattlEye.ReportHook = nop
        end
        local HiggsBosonComponent = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if HiggsBosonComponent then
            HiggsBosonComponent.bIsEnable = false; HiggsBosonComponent.bMHActive = false
            HiggsBosonComponent.bCallPreReplication = false
            HiggsBosonComponent.StaticShowSecurityAlertInDev = nop
            HiggsBosonComponent.CheckClientConfig = retFalse
            HiggsBosonComponent.GetSecurityInfo = retEmpty
            HiggsBosonComponent.ReportSecurityAlert = nop
            HiggsBosonComponent.ValidateClient = retTrue
            HiggsBosonComponent.CheckIntegrity = retTrue
            HiggsBosonComponent.BlackList = {}
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
            "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
            "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem",
            "GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem",
            "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem",
            "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem",
            "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
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
        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            GC.ReportAttackFlow = nop; GC.ReportSecAttackFlow = nop; GC.ReportHurtFlow = nop
            GC.ReportFireArms = nop; GC.ReportVerifyInfoFlow = nop; GC.ReportMrpcsFlow = nop
            GC.ReportPlayerBehavior = nop; GC.ReportTeammatHurt = nop; GC.ReportMisKillByTeammate = nop
            GC.ReportForbitPick = nop; GC.ReportPlayerMoveRoute = nop; GC.ReportPlayerPosition = nop
            GC.ReportVehicleMoveFlow = nop; GC.ReportSecTgameMovingFlow = nop; GC.ReportParachuteData = nop
            GC.SendTssSdkAntiDataToLobby = nop; GC.SendDSErrorLogToLobby = nop
            GC.SendDSErrorLogToLobbyOnece = nop; GC.SendDSHawkEyePatrolLogToLobby = nop
            GC.ReportEquipmentFlow = nop; GC.ReportAimFlow = nop; GC.ReportHitFlow = nop
            GC.GetWeaponReport = retEmpty; GC.GetOneWeaponReport = retEmpty
            GC.ReportHeavyWeaponBoxSpawnFlow = nop; GC.ReportHeavyWeaponBoxActivationFlow = nop
            GC.ReportHeavyWeaponBoxOpenPlayerFlow = nop; GC.ReportHeavyWeaponBoxItemFlow = nop
            GC.ReportPlayersPing = nop; GC.ReportPlayerIP = nop; GC.ReportPlayerFramePingRecord = nop
            GC.OnDSConnectionSaturated = nop; GC.ReportDSNetSaturation = nop
            GC.ReportNetContinuousSaturate = nop; GC.ReportDSNetRate = nop
            GC.SendClientStats = nop; GC.SendServerAvgTickDelta = nop; GC.ReportCircleFlow = nop
            GC.ReportDSCircleFlow = nop; GC.ReportJumpFlow = nop; GC.ReportAIStrategyInfo = nop
            GC.SendAIDeliveryInfo = nop; GC.ReportDailyTaskInfo = nop; GC.ReportMatchRoomData = nop
            GC.SendPlayerSpectatingLog = nop; GC.ReportIDCardProduceFlow = nop
            GC.ReportIDCardPickUpFlow = nop; GC.ReportIDCardDestroyFlow = nop; GC.ReportRevivalFlow = nop
            GC.ReportGameSetting = nop; GC.ReportGameSettingNew = nop; GC.ReportAntsVoiceTeamCreate = nop
            GC.ReportAntsVoiceTeamQuit = nop; GC.ReportCommonInfo = nop; GC.ReportLightweightStat = nop
            GC.SendSecTLog = nop; GC.SendDataMiningTLog = nop; GC.SendActivityTLog = nop
            GC.GetGeneralTLogData = retEmpty
            GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
                if InPlayerState then
                    local state = string.lower(tostring(InPlayerState))
                    local blocked = {"cheat","ban","kick","detected","violation","suspicious","abnormal","invalid","corrupt","tamper","modify","inject","hook","patch","spoof","fake","clone","duplicate","conflict","overlap","mismatch","inconsistent","unexpected","unknown"}
                    for _, b in ipairs(blocked) do if state:find(b) then return end end
                end
            end
            GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop
            GC.OnPlayerRPCValidateFailed = nop; GC.OnPlayerSpectateException = nop
            GC.OnShutdownAfterError = nop; GC.IsBypassed = true
        end
        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blockedPackets = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
                ["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
                ["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1,
                ["report_heavy_weapon_box_activation_flow"]=1, ["report_heavy_weapon_box_item_flow"]=1,
                ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1, ["ReportJumpFlow"]=1,
                ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1,
                ["report_all_players_address"]=1, ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1,
                ["ReportGenerateMonsterFlow"]=1, ["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1,
                ["ReportIDCardProduceFlow"]=1, ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1,
                ["ReportRevivalFlow"]=1, ["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1,
                ["ReportAntsVoiceTeamCreate"]=1, ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1,
                ["report_common_battle_info"]=1, ["report_client_scan_result"]=1, ["tss_sdk_report"]=1,
                ["report_memory_exception"]=1, ["report_avatar_exception"]=1, ["report_ui_state"]=1,
                ["report_hit_reg_fail"]=1, ["report_character_state"]=1, ["report_vehicle_exception"]=1,
                ["report_camera_exception"]=1, ["ReportPlayerControllerStateChanged"]=1,
                ["ReportAvatarFlow"]=1, ["ReportSecurityAlert"]=1, ["ReportAntiCheat"]=1,
                ["ReportSuspiciousActivity"]=1, ["ReportViolation"]=1, ["ReportBan"]=1,
                ["ReportKick"]=1, ["ReportCheat"]=1, ["ReportHack"]=1, ["ReportMod"]=1,
                ["ReportInject"]=1, ["ReportHook"]=1, ["ReportPatch"]=1, ["ReportTamper"]=1,
                ["ReportCorrupt"]=1, ["ReportInvalid"]=1, ["ReportSpoof"]=1, ["ReportFake"]=1,
                ["ReportClone"]=1, ["ReportDuplicate"]=1, ["ReportConflict"]=1, ["ReportOverlap"]=1,
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
            CrashSight.ReportException = nop; CrashSight.SetCustomData = nop; CrashSight.Log = nop
            CrashSight.UploadLog = nop; CrashSight.SendReport = nop; CrashSight.CollectInfo = retEmpty
            CrashSight.ReportCrash = nop; CrashSight.ReportError = nop; CrashSight.ReportFatal = nop
            CrashSight.ReportWarning = nop; CrashSight.ReportInfo = nop; CrashSight.ReportDebug = nop
            CrashSight.ReportMemory = nop; CrashSight.ReportPerformance = nop
        end
        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then
            TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop; TLog.Debug = nop
            TLog.Report = nop; TLog.Flush = nop; TLog.Log = nop; TLog.LogWarning = nop
            TLog.LogError = nop; TLog.LogVerbose = nop; TLog.SetLogLevel = nop
        end
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = retEmptyString; ScreenshotMaker.ReMakePicture = retEmptyString
            ScreenshotMaker.HasCaptured = retTrue; ScreenshotMaker.TakeScreenshot = nop
            ScreenshotMaker.SaveScreenshot = nop; ScreenshotMaker.CaptureScreen = nop
            ScreenshotMaker.RecordScreen = nop
        end
        local MemoryScanner = _G.MemoryScanner or package.loaded["MemoryScanner"]
        if MemoryScanner then
            MemoryScanner.StartScan = nop; MemoryScanner.StopScan = nop; MemoryScanner.GetResults = retEmpty
            MemoryScanner.ReportViolation = nop; MemoryScanner.CheckIntegrity = retTrue
            MemoryScanner.VerifyMemory = retTrue; MemoryScanner.ScanProcess = nop
            MemoryScanner.ScanModule = nop; MemoryScanner.ScanThread = nop; MemoryScanner.ScanFile = nop
            MemoryScanner.ScanNetwork = nop
        end
        local FileCheckSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("FileCheckSubsystem")
        if FileCheckSubsystem then
            FileCheckSubsystem.StartCheck = nop; FileCheckSubsystem.ReportAbnormalFile = nop
            FileCheckSubsystem.VerifyFile = retTrue; FileCheckSubsystem.CheckIntegrity = retTrue
            FileCheckSubsystem.ValidateFile = retTrue; FileCheckSubsystem.CheckFile = retTrue
            FileCheckSubsystem.VerifyHash = retTrue; FileCheckSubsystem.ValidateHash = retTrue
            FileCheckSubsystem.CheckHash = retTrue
        end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.ValidateAvatar = retTrue; AvatarUtils.CheckAvatar = retTrue
            AvatarUtils.VerifySkin = retTrue; AvatarUtils.ValidateSkin = retTrue; AvatarUtils.CheckSkin = retTrue
            AvatarUtils.VerifyWeapon = retTrue; AvatarUtils.ValidateWeapon = retTrue; AvatarUtils.CheckWeapon = retTrue
            AvatarUtils.VerifyVehicle = retTrue; AvatarUtils.ValidateVehicle = retTrue; AvatarUtils.CheckVehicle = retTrue
        end
        local ClientDataStatistcsSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ClientDataStatistcsSubsystem")
        if ClientDataStatistcsSubsystem then
            ClientDataStatistcsSubsystem.StartToCheck = nop; ClientDataStatistcsSubsystem.DelayCount = 0
            ClientDataStatistcsSubsystem.ReportPingDelay = nop; ClientDataStatistcsSubsystem.ReportStats = nop
            ClientDataStatistcsSubsystem.ReportData = nop; ClientDataStatistcsSubsystem.ReportPerformance = nop
            ClientDataStatistcsSubsystem.ReportBattery = nop; ClientDataStatistcsSubsystem.ReportTemperature = nop
            ClientDataStatistcsSubsystem.ReportFPS = nop; ClientDataStatistcsSubsystem.ReportPing = nop
            ClientDataStatistcsSubsystem.ReportNetwork = nop
        end
        local ShootVerifySubSystemClient = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ShootVerifySubSystemClient")
        if ShootVerifySubSystemClient then
            ShootVerifySubSystemClient.ReportVerifyFail = nop; ShootVerifySubSystemClient.OnVerifyFailed = nop
            ShootVerifySubSystemClient.CheckShoot = retTrue; ShootVerifySubSystemClient.ValidateHit = retTrue
            ShootVerifySubSystemClient.VerifyShoot = retTrue; ShootVerifySubSystemClient.ValidateShoot = retTrue
            ShootVerifySubSystemClient.CheckHit = retTrue; ShootVerifySubSystemClient.VerifyHit = retTrue
        end
        local AFKReportorSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AFKReportorSubsystem")
        if AFKReportorSubsystem then
            AFKReportorSubsystem.PlayerHaveAction = nop; AFKReportorSubsystem.ReportAFK = nop
            AFKReportorSubsystem.CheckAFK = retFalse; AFKReportorSubsystem.ReportAFKData = nop
            AFKReportorSubsystem.ReportIdle = nop; AFKReportorSubsystem.ReportInactive = nop
        end
        local AvatarExceptionSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AvatarExceptionSubsystem")
        if AvatarExceptionSubsystem then
            AvatarExceptionSubsystem.ReportException = nop; AvatarExceptionSubsystem.BindPlayerCharacter = nop
            AvatarExceptionSubsystem.CheckAvatarValid = retTrue; AvatarExceptionSubsystem.ValidateAvatar = retTrue
            AvatarExceptionSubsystem.ReportAvatarException = nop; AvatarExceptionSubsystem.ReportInvalidAvatar = nop
            AvatarExceptionSubsystem.ReportCorruptAvatar = nop
        end
        local RescueBtnReplayTraceSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("RescueBtnReplayTraceSubsystem")
        if RescueBtnReplayTraceSubsystem then
            RescueBtnReplayTraceSubsystem.ReportTrace = nop; RescueBtnReplayTraceSubsystem.StartTickMonitor = nop
            RescueBtnReplayTraceSubsystem.TickMonitorCheck = nop
            RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = nop
            RescueBtnReplayTraceSubsystem.ReportReplay = nop; RescueBtnReplayTraceSubsystem.ReportTraceData = nop
        end
        local GameReportSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.ReplayReportData = retFalse; GameReportSubsystem.CheckCanBugglyPostException = retFalse
            GameReportSubsystem.BugglyPostExceptionFull = retFalse; GameReportSubsystem.GetClientReplayDataReporter = nop
            GameReportSubsystem.ReportGameException = nop; GameReportSubsystem.ReportGameData = nop
            GameReportSubsystem.ReportGameStats = nop; GameReportSubsystem.ReportGamePerformance = nop
        end
        local InspectionSystemReportClientLogicSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"]
        if InspectionSystemReportClientLogicSubsystem then
            InspectionSystemReportClientLogicSubsystem.AskForInspector = nop
            InspectionSystemReportClientLogicSubsystem.ReportEnemy = nop
            InspectionSystemReportClientLogicSubsystem.KickOutOneTeam = nop
            InspectionSystemReportClientLogicSubsystem.ReportSuspicious = nop
            InspectionSystemReportClientLogicSubsystem.ReportCheat = nop
            InspectionSystemReportClientLogicSubsystem.ReportHack = nop
        end
        local ClientHawkEyePatrolSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"]
        if ClientHawkEyePatrolSubsystem then
            ClientHawkEyePatrolSubsystem._OnHawkSync = nop; ClientHawkEyePatrolSubsystem._OnHawkReportSuccess = nop
            ClientHawkEyePatrolSubsystem._StartExitGameTimer = nop; ClientHawkEyePatrolSubsystem.ReportData = nop
            ClientHawkEyePatrolSubsystem.ReportHawk = nop; ClientHawkEyePatrolSubsystem.ReportPatrol = nop
        end
        local BehaviorScoreSubsystem = package.loaded["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"]
        if BehaviorScoreSubsystem then
            BehaviorScoreSubsystem.OnHandleBehaviorScore = nop; BehaviorScoreSubsystem.AIPerceptionScore = nop
            BehaviorScoreSubsystem.ReportBehavior = nop; BehaviorScoreSubsystem.CalculateScore = function() return 100 end
            BehaviorScoreSubsystem.ReportScore = nop; BehaviorScoreSubsystem.ReportBehaviorData = nop
        end
        local AIReplaySubsystem = package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"]
        if AIReplaySubsystem then
            AIReplaySubsystem.ReportAllPlayerInfo = nop; AIReplaySubsystem.AddRecordMLAIInfo = nop
            AIReplaySubsystem.ReportAI = nop; AIReplaySubsystem.ReportAIData = nop
            AIReplaySubsystem.ReportAIPerformance = nop
        end
        local ClientBanLogic = package.loaded["client.slua.logic.ban.ClientBanLogic"]
        if ClientBanLogic then
            ClientBanLogic.OnSyncBanInfo = nop; ClientBanLogic.OnVoiceBanNotify = nop
            ClientBanLogic.CheckBan = retFalse; ClientBanLogic.IsBanned = retFalse
            ClientBanLogic.CheckBanStatus = retFalse; ClientBanLogic.GetBanInfo = retEmpty
        end
        local logic_tt_ban = package.loaded["client.slua.logic.login.logic_tt_ban"]
        if logic_tt_ban then
            logic_tt_ban.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
            logic_tt_ban.CheckIfCanCreateRole = retTrue; logic_tt_ban.CheckBan = retFalse
            logic_tt_ban.GetBanStatus = retFalse
        end
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.GetAndroidVersion = function() return "13" end
            SystemInfo.GetEMUIVersion = retEmptyString; SystemInfo.IsEmulator = retFalse
            SystemInfo.IsRooted = retFalse; SystemInfo.IsDebugged = retFalse
            SystemInfo.GetKernelVersion = function() return "Linux version 4.14.116" end
            SystemInfo.CheckKernelIntegrity = retTrue
            SystemInfo.GetDeviceID = function() return "00000000-0000-0000-0000-000000000000" end
            SystemInfo.GetDeviceName = function() return "iPhone" end; SystemInfo.GetDeviceType = function() return "Phone" end
            SystemInfo.GetManufacturer = function() return "Apple" end; SystemInfo.GetModel = function() return "iPhone14,5" end
            SystemInfo.GetOSVersion = function() return "13" end; SystemInfo.GetOSName = function() return "iOS" end
            SystemInfo.GetScreenResolution = function() return "1170x2532" end; SystemInfo.GetScreenDensity = function() return "460" end
            SystemInfo.GetRAMSize = function() return "6144" end; SystemInfo.GetStorageSize = function() return "256" end
            SystemInfo.GetBatteryLevel = function() return "100" end; SystemInfo.GetBatteryStatus = function() return "Charging" end
            SystemInfo.GetNetworkType = function() return "WiFi" end; SystemInfo.GetNetworkSpeed = function() return "100" end
            SystemInfo.GetGPSStatus = function() return "Enabled" end; SystemInfo.GetGPSLocation = function() return "0.0,0.0" end
            SystemInfo.GetCountryCode = function() return "US" end; SystemInfo.GetLanguageCode = function() return "en" end
            SystemInfo.GetTimeZone = function() return "UTC" end; SystemInfo.GetCurrentTime = function() return os.time() end
            SystemInfo.GetUptime = function() return 3600 end; SystemInfo.GetCPUUsage = function() return 10 end
            SystemInfo.GetMemoryUsage = function() return 20 end; SystemInfo.GetTemperature = function() return 25 end
            SystemInfo.GetBatteryTemperature = function() return 25 end; SystemInfo.GetCPUFrequency = function() return 2400 end
            SystemInfo.GetGPUFrequency = function() return 1200 end; SystemInfo.GetScreenBrightness = function() return 100 end
            SystemInfo.GetVolumeLevel = function() return 100 end
        end
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary then
            KismetSystemLibrary.IsDevelopment = retFalse; KismetSystemLibrary.IsShipping = retTrue
            KismetSystemLibrary.IsDebug = retFalse; KismetSystemLibrary.IsEditor = retFalse
            KismetSystemLibrary.IsGame = retTrue; KismetSystemLibrary.IsClient = retTrue
            KismetSystemLibrary.IsServer = retFalse; KismetSystemLibrary.IsStandalone = retFalse
        end
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
            CreativeModeBlueprintLibrary.VerifyContent = retTrue; CreativeModeBlueprintLibrary.ValidateContent = retTrue
            CreativeModeBlueprintLibrary.CheckContent = retTrue
        end
        _G.print = nop; _G.printf = nop; _G.log = nop; _G.warn = nop; _G.error = nop
        _G.debug = nop; _G.trace = nop; _G.info = nop; _G.verbose = nop; _G.fatal = nop
        _G.panic = nop; _G.recover = nop; _G.assert = nop
        local Logging = import("Logging")
        if Logging then
            Logging.Log = nop; Logging.LogWarning = nop; Logging.LogError = nop; Logging.LogVerbose = nop
            Logging.SetLogLevel = nop; Logging.LogInfo = nop; Logging.LogDebug = nop; Logging.LogTrace = nop
            Logging.LogFatal = nop; Logging.LogPanic = nop
        end
        local TDataMaster = _G.TDataMaster or package.loaded["libTDataMaster.so"]
        if TDataMaster then
            TDataMaster.ReportEvent = nop; TDataMaster.ReportException = nop; TDataMaster.FlushData = nop
            TDataMaster.CollectData = retEmpty; TDataMaster.SendReport = nop; TDataMaster.ReportTelemetry = nop
            TDataMaster.ReportAnalytics = nop; TDataMaster.ReportMetrics = nop; TDataMaster.ReportStatistics = nop
            TDataMaster.ReportPerformance = nop; TDataMaster.ReportBattery = nop; TDataMaster.ReportTemperature = nop
            TDataMaster.ReportFPS = nop; TDataMaster.ReportPing = nop; TDataMaster.ReportNetwork = nop
        end
        _G.TelemetryQueue = {}; _G.bTelemetryEnabled = false
        local suspiciousVars = {
            "bIsCheating","bDetected","bBanned","SuspicionScore","CheatDetected","AntiCheatFlag",
            "IsHacking","bReported","TrustScore","SecurityFlag","ViolationLevel","BanStatus",
            "bIsBan","bIsKick","bIsReported","CheatCount","ViolationCount","SecurityScore",
            "TrustLevel","bIsCheater","bIsHacker","bIsModder","bIsInjector","bIsHooker",
            "bIsPatcher","bIsTamperer","bIsCorrupter","bIsInvalid","bIsSpoofer","bIsFaker",
            "bIsCloner","bIsDuplicator","bIsConflicter","bIsOverlapper","bIsMismatcher",
            "bIsInconsistent","bIsUnexpected","bIsUnknown","bIsSuspicious","bIsAbnormal",
            "bIsCorrupt","bIsTampered","bIsModified","bIsInjected","bIsHooked","bIsPatched",
            "bIsSpoofed","bIsFaked","bIsCloned","bIsDuplicated","bIsConflicted","bIsOverlapped",
            "bIsMismatched","bIsInconsistent",
        }
        for _, var in ipairs(suspiciousVars) do _G[var] = nil end
        local MemoryProtect = import("MemoryProtect")
        if MemoryProtect then
            MemoryProtect.VirtualProtect = retTrue; MemoryProtect.IsMemoryReadable = retFalse
            MemoryProtect.IsMemoryWritable = retFalse; MemoryProtect.CheckMemory = retTrue
            MemoryProtect.ProtectMemory = retTrue; MemoryProtect.UnprotectMemory = retTrue
            MemoryProtect.ValidateMemory = retTrue; MemoryProtect.VerifyMemory = retTrue
        end
        local NetworkManager = import("NetworkManager")
        if NetworkManager then
            NetworkManager.GetNetworkStats = function() return {ping=40, loss=0, rtt=40} end
            NetworkManager.CapturePackets = nop; NetworkManager.AnalyzeTraffic = retEmpty
            NetworkManager.GetConnectionInfo = function() return "127.0.0.1:8080" end
            NetworkManager.MonitorTraffic = nop; NetworkManager.ReportTraffic = nop
            NetworkManager.ReportNetwork = nop; NetworkManager.ReportBandwidth = nop
            NetworkManager.ReportLatency = nop; NetworkManager.ReportPacketLoss = nop
        end
        local Engine = import("Engine")
        if Engine then
            Engine.GetAverageFPS = function() return 60 end; Engine.GetFrameTime = function() return 0.016 end
            Engine.IsLagging = retFalse; Engine.GetDeltaTime = function() return 0.033 end
            Engine.GetTime = function() return os.time() end; Engine.GetTimestamp = function() return os.time() end
            Engine.GetTick = function() return os.clock() end; Engine.GetSeconds = function() return os.time() end
            Engine.GetMilliseconds = function() return os.time() * 1000 end
            Engine.GetMicroseconds = function() return os.time() * 1000000 end
            Engine.GetNanoseconds = function() return os.time() * 1000000000 end
        end
        local GameTime = package.loaded["GameLua.GameCore.Data.GameTime"]
        if GameTime then
            GameTime.GetServerTime = function() return os.time() end; GameTime.GetDeltaTime = function() return 0.033 end
            GameTime.GetGameTime = function() return os.time() end; GameTime.GetRealTime = function() return os.time() end
            GameTime.GetTickTime = function() return os.clock() end; GameTime.GetFrameTime = function() return 0.016 end
        end
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
        local MemoryCleaner = import("MemoryCleaner")
        if MemoryCleaner then
            MemoryCleaner.ClearCache = nop; MemoryCleaner.FreeUnusedMemory = nop; MemoryCleaner.CompactHeap = nop
            MemoryCleaner.CleanTraces = nop; MemoryCleaner.ClearLogs = nop; MemoryCleaner.ClearTemp = nop
            MemoryCleaner.ClearCacheFiles = nop; MemoryCleaner.ClearHistory = nop; MemoryCleaner.ClearData = nop
        end
        local DebuggerDetect = _G.DebuggerDetect or package.loaded["DebuggerDetect"]
        if DebuggerDetect then
            DebuggerDetect.IsDebuggerPresent = retFalse; DebuggerDetect.CheckBreakpoint = retFalse
            DebuggerDetect.CheckTracer = retFalse; DebuggerDetect.CheckDebug = retFalse
            DebuggerDetect.CheckDebugger = retFalse; DebuggerDetect.DetectDebugger = retFalse
            DebuggerDetect.DetectBreakpoint = retFalse; DebuggerDetect.DetectTracer = retFalse
            DebuggerDetect.DetectDebug = retFalse
        end
        local EmulatorDetect = _G.EmulatorDetect or package.loaded["EmulatorDetect"]
        if EmulatorDetect then
            EmulatorDetect.IsEmulator = retFalse; EmulatorDetect.GetEmulatorType = retEmptyString
            EmulatorDetect.CheckVM = retFalse; EmulatorDetect.Detect = retFalse
            EmulatorDetect.DetectEmulator = retFalse; EmulatorDetect.DetectVM = retFalse
            EmulatorDetect.DetectVirtualMachine = retFalse; EmulatorDetect.DetectEmulatorType = retEmptyString
        end
        local jni_ac = _G.JNI and _G.JNI.AntiCheat
        if jni_ac then
            jni_ac.CheckRoot = retFalse; jni_ac.CheckEmulator = retFalse; jni_ac.CheckDebugger = retFalse
            jni_ac.CollectInfo = retEmpty; jni_ac.SendReport = nop; jni_ac.Validate = retTrue
            jni_ac.CheckRootAccess = retFalse; jni_ac.CheckEmulatorAccess = retFalse
            jni_ac.CheckDebuggerAccess = retFalse; jni_ac.CheckMemoryAccess = retTrue
            jni_ac.CheckProcessAccess = retTrue; jni_ac.CheckFileAccess = retTrue
            jni_ac.CheckNetworkAccess = retTrue; jni_ac.CheckSystemAccess = retTrue
            jni_ac.CheckDeviceAccess = retTrue; jni_ac.CheckAPIAccess = retTrue
            jni_ac.CheckSDKAccess = retTrue; jni_ac.CheckLibraryAccess = retTrue
            jni_ac.CheckFrameworkAccess = retTrue; jni_ac.CheckPackageAccess = retTrue
        end
        local PacketEncrypt = _G.PacketEncrypt or package.loaded["PacketEncrypt"]
        if PacketEncrypt then
            PacketEncrypt.Encrypt = function(data) return data end
            PacketEncrypt.Decrypt = function(data) return data end
            PacketEncrypt.VerifyChecksum = retTrue; PacketEncrypt.Validate = retTrue
            PacketEncrypt.ValidatePacket = retTrue; PacketEncrypt.VerifyPacket = retTrue
            PacketEncrypt.CheckPacket = retTrue; PacketEncrypt.EncryptPacket = function(data) return data end
            PacketEncrypt.DecryptPacket = function(data) return data end
            PacketEncrypt.ValidateChecksum = retTrue; PacketEncrypt.VerifyChecksum = retTrue
            PacketEncrypt.CheckChecksum = retTrue
        end
        local DSValidator = _G.DSValidator or package.loaded["DSValidator"]
        if DSValidator then
            DSValidator.ValidateClient = retTrue; DSValidator.CheckLatency = function() return 40 end
            DSValidator.ReportCheat = nop; DSValidator.KickPlayer = nop; DSValidator.BanPlayer = nop
            DSValidator.ValidatePlayer = retTrue; DSValidator.ValidateSession = retTrue
            DSValidator.ValidateGame = retTrue; DSValidator.ValidateSystem = retTrue
            DSValidator.ValidateDevice = retTrue; DSValidator.ValidateNetwork = retTrue
            DSValidator.ValidateMemory = retTrue; DSValidator.ValidateFile = retTrue
            DSValidator.ValidateProcess = retTrue; DSValidator.ValidateThread = retTrue
            DSValidator.ValidateModule = retTrue; DSValidator.ValidateAPI = retTrue
            DSValidator.ValidateSDK = retTrue; DSValidator.ValidateLibrary = retTrue
            DSValidator.ValidateFramework = retTrue; DSValidator.ValidatePackage = retTrue
            DSValidator.ValidateContainer = retTrue; DSValidator.ValidateComponent = retTrue
            DSValidator.ValidateObject = retTrue; DSValidator.ValidateClass = retTrue
            DSValidator.ValidateStruct = retTrue; DSValidator.ValidateEnum = retTrue
            DSValidator.ValidateInterface = retTrue; DSValidator.ValidateDelegate = retTrue
            DSValidator.ValidateEvent = retTrue; DSValidator.ValidateFunction = retTrue
            DSValidator.ValidateVariable = retTrue; DSValidator.ValidateProperty = retTrue
            DSValidator.ValidateField = retTrue; DSValidator.ValidateMethod = retTrue
            DSValidator.ValidateParameter = retTrue; DSValidator.ValidateReturn = retTrue
            DSValidator.ValidateResult = retTrue; DSValidator.ValidateOutput = retTrue
            DSValidator.ValidateInput = retTrue
        end
        local CRCChecker = _G.CRCChecker or package.loaded["CRCChecker"]
        if CRCChecker then
            CRCChecker.VerifyFile = retTrue; CRCChecker.VerifyMemory = retTrue
            CRCChecker.GenerateCRC = function() return "00000000" end
            CRCChecker.CheckIntegrity = retTrue; CRCChecker.ValidateFile = retTrue
            CRCChecker.ValidateMemory = retTrue; CRCChecker.CheckFile = retTrue
            CRCChecker.CheckMemory = retTrue; CRCChecker.VerifyCRC = retTrue
            CRCChecker.ValidateCRC = retTrue; CRCChecker.CheckCRC = retTrue
            CRCChecker.GenerateCRC32 = function() return "00000000" end
            CRCChecker.GenerateCRC64 = function() return "0000000000000000" end
            CRCChecker.GenerateMD5 = function() return "00000000000000000000000000000000" end
            CRCChecker.GenerateSHA1 = function() return "0000000000000000000000000000000000000000" end
            CRCChecker.GenerateSHA256 = function() return "0000000000000000000000000000000000000000000000000000000000000000" end
            CRCChecker.GenerateSHA512 = function() return "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" end
        end
        local SecurityCommonUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = retEmpty; SecurityCommonUtils.LogIf = retFalse
            SecurityCommonUtils.CheckSecurity = retTrue; SecurityCommonUtils.ValidatePlayer = retTrue
            SecurityCommonUtils.ValidateSession = retTrue; SecurityCommonUtils.ValidateGame = retTrue
            SecurityCommonUtils.ValidateSystem = retTrue; SecurityCommonUtils.ValidateDevice = retTrue
            SecurityCommonUtils.ValidateNetwork = retTrue; SecurityCommonUtils.ValidateMemory = retTrue
            SecurityCommonUtils.ValidateFile = retTrue; SecurityCommonUtils.ValidateProcess = retTrue
            SecurityCommonUtils.ValidateThread = retTrue; SecurityCommonUtils.ValidateModule = retTrue
            SecurityCommonUtils.ValidateAPI = retTrue; SecurityCommonUtils.ValidateSDK = retTrue
            SecurityCommonUtils.ValidateLibrary = retTrue; SecurityCommonUtils.ValidateFramework = retTrue
            SecurityCommonUtils.ValidatePackage = retTrue; SecurityCommonUtils.ValidateContainer = retTrue
            SecurityCommonUtils.ValidateComponent = retTrue; SecurityCommonUtils.ValidateObject = retTrue
            SecurityCommonUtils.ValidateClass = retTrue; SecurityCommonUtils.ValidateStruct = retTrue
            SecurityCommonUtils.ValidateEnum = retTrue; SecurityCommonUtils.ValidateInterface = retTrue
            SecurityCommonUtils.ValidateDelegate = retTrue; SecurityCommonUtils.ValidateEvent = retTrue
            SecurityCommonUtils.ValidateFunction = retTrue; SecurityCommonUtils.ValidateVariable = retTrue
            SecurityCommonUtils.ValidateProperty = retTrue; SecurityCommonUtils.ValidateField = retTrue
            SecurityCommonUtils.ValidateMethod = retTrue; SecurityCommonUtils.ValidateParameter = retTrue
            SecurityCommonUtils.ValidateReturn = retTrue; SecurityCommonUtils.ValidateResult = retTrue
            SecurityCommonUtils.ValidateOutput = retTrue; SecurityCommonUtils.ValidateInput = retTrue
        end
        local SecurityNotifyPCFeature = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
        if SecurityNotifyPCFeature then
            SecurityNotifyPCFeature.ClientRPC_SyncBanID = nop; SecurityNotifyPCFeature.ClientRPC_StrongTips = nop
            SecurityNotifyPCFeature.ClientRPC_NormalTips = nop; SecurityNotifyPCFeature.Notify = nop
            SecurityNotifyPCFeature.ShowBan = nop; SecurityNotifyPCFeature.ShowKick = nop
            SecurityNotifyPCFeature.ShowWarning = nop; SecurityNotifyPCFeature.ShowInfo = nop
            SecurityNotifyPCFeature.ShowError = nop; SecurityNotifyPCFeature.ShowFatal = nop
            SecurityNotifyPCFeature.ShowPanic = nop; SecurityNotifyPCFeature.ShowAlert = nop
            SecurityNotifyPCFeature.ShowNotification = nop; SecurityNotifyPCFeature.ShowMessage = nop
            SecurityNotifyPCFeature.ShowDialog = nop; SecurityNotifyPCFeature.ShowPopup = nop
            SecurityNotifyPCFeature.ShowToast = nop; SecurityNotifyPCFeature.ShowSnackbar = nop
            SecurityNotifyPCFeature.ShowBanner = nop; SecurityNotifyPCFeature.ShowAlertDialog = nop
            SecurityNotifyPCFeature.ShowConfirmDialog = nop; SecurityNotifyPCFeature.ShowPromptDialog = nop
            SecurityNotifyPCFeature.ShowInputDialog = nop; SecurityNotifyPCFeature.ShowSelectDialog = nop
            SecurityNotifyPCFeature.ShowProgressDialog = nop; SecurityNotifyPCFeature.ShowLoadingDialog = nop
            SecurityNotifyPCFeature.ShowSuccessDialog = nop; SecurityNotifyPCFeature.ShowFailureDialog = nop
            SecurityNotifyPCFeature.ShowErrorDialog = nop; SecurityNotifyPCFeature.ShowWarningDialog = nop
            SecurityNotifyPCFeature.ShowInfoDialog = nop
        end
        local DSActiveSubsystem = package.loaded["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"]
        if DSActiveSubsystem then
            DSActiveSubsystem.DelayKickOutPlayer = nop; DSActiveSubsystem.ActiveKickNotify = nop
            DSActiveSubsystem.CheckActive = retTrue; DSActiveSubsystem.CheckActivity = retTrue
            DSActiveSubsystem.ValidateActive = retTrue; DSActiveSubsystem.VerifyActive = retTrue
            DSActiveSubsystem.ReportActive = nop; DSActiveSubsystem.ReportActivity = nop
            DSActiveSubsystem.ReportActiveData = nop
        end
        local SpectateAndReplaySubsystem = package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"]
        if SpectateAndReplaySubsystem then
            SpectateAndReplaySubsystem.RequestGotoSpectatingImp = nop
            SpectateAndReplaySubsystem.RequestGotoSpectating = nop
            SpectateAndReplaySubsystem.ReportSpectate = nop; SpectateAndReplaySubsystem.ReportReplay = nop
            SpectateAndReplaySubsystem.ReportSpectateData = nop; SpectateAndReplaySubsystem.ReportReplayData = nop
            SpectateAndReplaySubsystem.ValidateSpectate = retTrue; SpectateAndReplaySubsystem.ValidateReplay = retTrue
            SpectateAndReplaySubsystem.CheckSpectate = retTrue; SpectateAndReplaySubsystem.CheckReplay = retTrue
        end
        local AITrackingLogSubsystem = package.loaded["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"]
        if AITrackingLogSubsystem then
            AITrackingLogSubsystem.RealLogoutTimer = nop; AITrackingLogSubsystem.LogQueue = {}
            AITrackingLogSubsystem.ReportAI = nop; AITrackingLogSubsystem.ReportAITracking = nop
            AITrackingLogSubsystem.ReportAIData = nop; AITrackingLogSubsystem.ValidateAI = retTrue
            AITrackingLogSubsystem.VerifyAI = retTrue; AITrackingLogSubsystem.CheckAI = retTrue
        end
        local TDMAFKReportorSubsystem = package.loaded["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"]
        if TDMAFKReportorSubsystem then
            TDMAFKReportorSubsystem.SendAFKTips = nop; TDMAFKReportorSubsystem.OnHandleLostConnection = nop
            TDMAFKReportorSubsystem.ReportAFK = nop; TDMAFKReportorSubsystem.ReportIdle = nop
            TDMAFKReportorSubsystem.ReportInactive = nop; TDMAFKReportorSubsystem.CheckAFK = retFalse
            TDMAFKReportorSubsystem.ValidateAFK = retFalse; TDMAFKReportorSubsystem.VerifyAFK = retFalse
        end
        local DataMgr = package.loaded["client.slua.logic.data.data_mgr"] or _G.DataMgr
        if DataMgr then
            DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = function() return 0 end
            DataMgr.ReportData = nop; DataMgr.ReportStats = nop; DataMgr.ReportMetrics = nop
            DataMgr.ReportAnalytics = nop; DataMgr.ReportTelemetry = nop; DataMgr.ReportPerformance = nop
            DataMgr.ReportBattery = nop; DataMgr.ReportTemperature = nop; DataMgr.ReportFPS = nop
            DataMgr.ReportPing = nop; DataMgr.ReportNetwork = nop; DataMgr.ReportDevice = nop
            DataMgr.ReportSystem = nop; DataMgr.ReportGame = nop; DataMgr.ReportUser = nop
            DataMgr.ReportAccount = nop; DataMgr.ReportSession = nop
        end
        _G.bIsCheating = nil; _G.bDetected = nil; _G.bBanned = nil; _G.SuspicionScore = nil
        _G.CheatDetected = nil; _G.AntiCheatFlag = nil; _G.IsHacking = nil; _G.bReported = nil
        _G.TrustScore = nil; _G.SecurityFlag = nil; _G.ViolationLevel = nil; _G.BanStatus = nil
        _G.TelemetryQueue = {}; _G.bTelemetryEnabled = false
        _G.LogQueue = {}; _G.bLoggingEnabled = false
        _G.ReportQueue = {}; _G.bReportingEnabled = false
        _G.ExceptionQueue = {}; _G.bExceptionReportingEnabled = false
        _G.CrashQueue = {}; _G.bCrashReportingEnabled = false
        _G.TraceQueue = {}; _G.bTracingEnabled = false
        print('[✓] COMPLETE ANTI-BAN SYSTEM ACTIVATED!')
        print('[✓] 100+ XTEAM Bypasses Active!')
    end)
end

local function AdditionalBypass()
    pcall(function()
        if Client then
            Client.SetTssNetworkStatus = nop; Client.GEMReportEnterLobbyEvent = nop
            Client.TPerforPlatDisconnectReport = nop; Client.IsConnected = function() return true end
            Client.GetUnrealNetworkStatus = retEmptyString; Client.MD5LuaString = function() return "BYPASSED_MD5" end
            Client.GetDSVersion = function() return "999.999.999" end; Client.IsInReplayState = retFalse
        end
        if NetManager then NetManager.ProcRespondMsg = nop; NetManager.isLogMsgAfterLogin = false; NetManager.logMsgMap = {} end
        if EventSystem then
            local oldPost = EventSystem.postEvent
            EventSystem.postEvent = function(eventType, eventID, ...)
                if eventID and type(eventID)=="string" then
                    local blocked = {"SECURITY","CHEAT","BAN","REPORT","FLAG","VIOLATION","DETECT","VERIFY","ANTI","AC_","SUSPICIOUS","ABNORMAL","MONITOR","TRACK","TELEMETRY","ANALYTICS","CRASH","DUMP"}
                    for _, be in ipairs(blocked) do if eventID:find(be) then return end end
                end
                if oldPost then oldPost(eventType, eventID, ...) end
            end
        end
        local logFuncs = {"log","log_warning","log_error","log_shipping_client","log_format","log_tree"}
        for _, funcName in ipairs(logFuncs) do
            if _G[funcName] then
                _G[funcName] = function(...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg)=="string" and (arg:find("cheat") or arg:find("security") or arg:find("ban") or arg:find("detect") or arg:find("verify") or arg:find("integrity") or arg:find("report") or arg:find("violation") or arg:find("hack") or arg:find("anti") or arg:find("ac_") or arg:find("suspicious") or arg:find("abnormal") or arg:find("monitor") or arg:find("track")) then return end
                    end
                end
            end
        end
        if LogUtil then LogUtil.SetForceLog = nop; LogUtil.SetLogTreeEnable = nop; LogUtil.SetWriteLog = nop end
        if sandbox then sandbox.LogError = nop; sandbox.LogWarning = nop end
        if ClientBanLogic then
            ClientBanLogic.ReqBanInfo = nop; ClientBanLogic.OnVoiceSwitchNotify = nop; ClientBanLogic.OnVoiceBanNotify = nop
            ClientBanLogic.OnRealTimeVoiceBanNotify = nop; ClientBanLogic.OnVoiceBanSuccess = nop
            ClientBanLogic.TryOpenVoice = function() EventSystem:postEvent(EVENTTYPE_INGAME_BAN, EVENTID_INGAME_BAN_FORBID_VOICE, false) end
            ClientBanLogic.IsVoiceReportEnable = retFalse; ClientBanLogic.OnSyncMicSuspicious = nop
            ClientBanLogic.OnSyncMicPreFilter = nop; ClientBanLogic.OnSyncBanInfo = nop
            ClientBanLogic.OnNotifyWarningTips = nop; ClientBanLogic.VoiceBanEndTime = 0
            ClientBanLogic.bEnableVoiceReport = false; ClientBanLogic.SuspiciousFlag = 0
            ClientBanLogic.Reason = ""; ClientBanLogic.IsTranslated = false
        end
        if RealTimeBan then
            RealTimeBan.Init = nop; RealTimeBan.OnPlayerWithRealTimeBan = nop; RealTimeBan.OnSyncPlayerInfo = nop
            RealTimeBan.HandleEnterGameModeFightingState = nop; RealTimeBan.ShowAlias = nop
            RealTimeBan.SetOnRankInspectorUID = nop; RealTimeBan.IsUIDOnRankInspector = retFalse
            RealTimeBan.GetUIDInspectorRank = retZero; RealTimeBan.SetInspectorBroadcastCountUID = nop
            RealTimeBan.GetUIDInspectorBroadcastCount = retZero; RealTimeBan.GetTipsIDOffset = retZero
            RealTimeBan.GetTipsIDOffsetWithUID = retZero; RealTimeBan.GetTipsIDOffsetInspector = retZero
            RealTimeBan.GMShowAlias = nop; RealTimeBan.tOnRankInspectorUIDSet = {}
            RealTimeBan.tInspectorRankUIDSet = {}; RealTimeBan.tInspectorBroadcastCountUIDSet = {}
            RealTimeBan.MaxAliasLevel = -1; RealTimeBan.CurrentAlias = nil; RealTimeBan.CurrentName = nil
            RealTimeBan.is_onrank_inspector = false; RealTimeBan.inspector_rank = -1
            RealTimeBan.bHasOldAlias = false; RealTimeBan.ShowTipsAliasConfig = {}
            RealTimeBan.DelayTime = {}; RealTimeBan.OldShowTipsAlias = 0
        end
        if BanSystem then BanSystem.CheckBan = retFalse; BanSystem.IsBanned = retFalse; BanSystem.GetBanReason = retEmptyString; BanSystem.GetBanTime = retZero end
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            console.ExecuteConsoleCommand(nil, "CheatManager.EnableCheat 1")
            console.ExecuteConsoleCommand(nil, "Net.BlockAllAntiCheat 1")
            console.ExecuteConsoleCommand(nil, "AntiCheat.DisableAll 1")
            console.ExecuteConsoleCommand(nil, "t.MaxFPS 165")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end; CMode.VerifyFileIntegrity = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        if _G.FileHashChecker then
            _G.FileHashChecker.CheckFileMD5 = retTrue; _G.FileHashChecker.VerifyAll = retTrue
            _G.FileHashChecker.GetHash = function() return "BYPASS" end
        end
        if _G.STExtraBlueprintFunctionLibrary then
            _G.STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
            _G.STExtraBlueprintFunctionLibrary.GetMD5 = function() return "BYPASS" end
            _G.STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
        end
        local DeviceID = import("DeviceID")
        if DeviceID then
            DeviceID.GetDeviceID = function() return "BYPASSED_DEVICE" end
            DeviceID.GetAndroidID = function() return "BYPASSED_ANDROID_ID" end
            DeviceID.GetIMEI = function() return "BYPASSED_IMEI" end
            DeviceID.GetMACAddress = function() return "BYPASSED_MAC" end
            DeviceID.GetUniqueDeviceID = function() return "BYPASSED_UNIQUE" end
            DeviceID.GetDeviceName = function() return "BYPASSED_DEVICE_NAME" end
            DeviceID.GetDeviceModel = function() return "BYPASSED_MODEL" end
            DeviceID.GetDeviceBrand = function() return "BYPASSED_BRAND" end
            DeviceID.GetDeviceManufacturer = function() return "BYPASSED_MANUFACTURER" end
            DeviceID.GetDeviceBoard = function() return "BYPASSED_BOARD" end
            DeviceID.GetDeviceBootloader = function() return "BYPASSED_BOOTLOADER" end
            DeviceID.GetDeviceHardware = function() return "BYPASSED_HARDWARE" end
            DeviceID.GetDeviceHost = function() return "BYPASSED_HOST" end
            DeviceID.GetDeviceFingerprint = function() return "BYPASSED_FINGERPRINT" end
            DeviceID.GetDeviceSerial = function() return "BYPASSED_SERIAL" end
        end
        local Network = import("Network")
        if Network then
            Network.GetMACAddress = function() return "BYPASSED_MAC" end
            Network.GetSSID = function() return "BYPASSED_SSID" end
            Network.GetBSSID = function() return "BYPASSED_BSSID" end
        end
        local XTEAM = package.loaded["GameLua.Mod.BaseMod.Client.Security.XTEAM"]
        if XTEAM then
            XTEAM.ForwardFeature = function() return {0,0,0,0,0} end; XTEAM.InitXTEAMLogic = nop
            if XTEAM.TimerHandle then
                local time_ticker = require("common.time_ticker")
                time_ticker.RemoveTimer(XTEAM.TimerHandle); XTEAM.TimerHandle = nil
            end
            for k, v in pairs(XTEAM) do
                if type(v)=="function" and (k:find("Init") or k:find("Start") or k:find("Check") or k:find("Scan") or k:find("Report") or k:find("Forward") or k:find("Feature") or k:find("Detect") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Analyze") or k:find("Process") or k:find("Handle")) then XTEAM[k] = nop end
            end
        end
        if _G.XTEAMLogic then _G.XTEAMLogic.ForwardFeature = nop; _G.XTEAMLogic.InitXTEAMLogic = nop end
        if RacingAntiCheatLogic then
            RacingAntiCheatLogic.HandleRacingEnter = nop; RacingAntiCheatLogic.HandleRacingStart = nop
            RacingAntiCheatLogic.HandleRacingEnd = nop; RacingAntiCheatLogic.StartDetectTimer = nop
            RacingAntiCheatLogic.StopDetectTimer = nop; RacingAntiCheatLogic.DetectVehicleFloating = nop
            RacingAntiCheatLogic.HandleFloatingCheat = nop; RacingAntiCheatLogic.SetIgnoreFloating = nop
            RacingAntiCheatLogic.HandlePlayerPassCheckBelt = nop; RacingAntiCheatLogic.HandleSpeedCheat = nop
            RacingAntiCheatLogic._CreateVehicleData = retEmpty; RacingAntiCheatLogic.vehicleDataMap = {}
            RacingAntiCheatLogic.detectTimer = nil; RacingAntiCheatLogic.config = { FloatingDistLimit = 99999, FloatingTimeLimit = 99999, CheckPassIntervalLimit = 99999 }
        end
        if login_module then
            login_module["ban-login"] = nop; login_module["idip-kick-out"] = nop; login_module.aq_ban = nop
            login_module["device-in-blacklist"] = nop; login_module.device_num_limit = nop
            login_module["register-forbidden"] = nop; login_module["low-version"] = nop
            login_module["not-in-white-list"] = nop; login_module.Login_Failed = nop; login_module.aas_ban = nop
            login_module.PakMonitorStart = nop; login_module.SetupFilenameHideKeywords = nop
            login_module.on_login_failed = nop; login_module.DelaybanLoginCancelCallback = nop
            login_module.CheckBan = retFalse; login_module.IsBanned = retFalse
        end
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local toKill = {
                "CoronaLabSubsystem","PlayerSecurityInfoSubsystem","ClientCircleFlowSubsystem",
                "ModifierExceptionSubsystem","SimulateCharacterSubsystem","ShootVerifySubSystemClient",
                "HiggsBosonComponent","ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
                "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientDataStatistcsSubsystem",
                "AFKReportorSubsystem","BehaviorScoreSubsystem","FileCheckSubsystem",
                "MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem",
                "AvatarExceptionSubsystem","GameReportSubsystem","ClientSecMrpcsFlowSubsystem",
                "MrpcsFlowSubsystem","CircleFlowSubsystem","SwiftHawkSubsystem",
                "AntiCheatSubsystem","IntegrityCheckSubsystem","SignatureVerifySubsystem",
                "MD5CheckSubsystem","PakVerifySubsystem","DNSMonitorSubsystem",
                "DeviceFingerprintSubsystem","ReplayMonitorSubsystem","TelemetrySubsystem",
                "XTEAMSubsystem","RacingAntiCheatSubsystem","ClientBanSubsystem",
                "RealTimeBanSubsystem","TLogSubsystem","ReportSubsystem",
                "SecurityMonitorSubsystem","CheatDetectionSubsystem","ViolationMonitorSubsystem",
                "SuspiciousActivitySubsystem","AbnormalBehaviorSubsystem","NetworkMonitorSubsystem",
                "AnalyticsSubsystem","CrashReportSubsystem","PerformanceMonitorSubsystem"
            }
            for _, name in ipairs(toKill) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v)=="function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat") or k:find("Monitor") or k:find("Track") or k:find("Record") or k:find("Log") or k:find("Alert") or k:find("Notify") or k:find("Ban") or k:find("Kick") or k:find("Suspend") or k:find("Flag") or k:find("Anti") or k:find("AC") or k:find("Analyze") or k:find("Process") or k:find("Handle") or k:find("Evaluate")) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                    if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                    if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
                    if sub.checkTimer then pcall(function() sub:RemoveGameTimer(sub.checkTimer) end) end
                    if sub.monitorTimer then pcall(function() sub:RemoveGameTimer(sub.monitorTimer) end) end
                    if sub.scanTimer then pcall(function() sub:RemoveGameTimer(sub.scanTimer) end) end
                end
            end
        end
        print("[BYPASS] ✅ All additional bypasses applied!")
    end)
end

-- ============================================================
-- 5. EXPIRY CHECK
-- ============================================================
local limitTime = os.time({ year = 2028, month = 8, day = 26, hour = 23, min = 59, sec = 0 })
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
    if not tm then 
        local s, r = pcall(require, "client.logic.common.TimeManager")
        if s and r then tm = r end
    end
    if tm and type(tm.GetServerTime) == "function" then
        local serverTime = tm.GetServerTime()
        if serverTime and serverTime > 1700000000 then 
            currentTime = serverTime
        end
    end
    local lastSeenTime = 0
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local data = file:read("*a")
            local savedTime = tonumber(data) or 0
            if savedTime > lastSeenTime then
                lastSeenTime = savedTime
            end
            file:close()
        end
    end
    if currentTime < lastSeenTime then
        currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(tostring(currentTime))
                file:close()
            end
        end
    end
end)
isExpired = (currentTime > limitTime)

-- ============================================================
-- 6. ULTIMATE BYPASS v3.0 INIT
-- ============================================================
local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then slua_serialize.check = retTrue; slua_serialize.verify = retTrue end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

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
            FileHashChecker.CheckFileMD5 = retTrue; FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then TssSdk.GetFileMD5 = function() return "BYPASS" end; TssSdk.VerifyFileSignature = retTrue end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then STExtra.CheckMD5 = retTrue; STExtra.GetMD5 = function() return "BYPASS" end; STExtra.VerifyFile = retTrue end
    end)
end

local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then ptlog.ReportEvent = nop; ptlog.ReportDownloadResult = nop; ptlog.ReportODPTDError = nop; ptlog.ReportSkinError = nop end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue; AvatarUtils.CheckAvatarIntegrity = retTrue; AvatarUtils.ReportInvalidAvatar = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then sub.StartCheck = nop; sub.ReportAbnormalFile = nop; sub.StopCheck = nop end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then eqEx.Report = nop; eqEx.SendException = nop end
    end)
end

local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then SMTD.MTDePicture = function() return "" end; SMTD.ReMTDePicture = function() return "" end; SMTD.HasCaptured = retTrue; SMTD.TakeScreenshot = nop end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop; TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop; TLog.Flush = nop end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then CrashSight.ReportException = nop; CrashSight.SetCustomData = nop; CrashSight.Log = nop; CrashSight.SendCrash = nop; CrashSight.ReportUserException = nop end
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GRUtils then GRUtils.BugglyPostExceptionFull = retFalse; GRUtils.CheckCanBugglyPostException = retFalse; GRUtils.ReplayReportData = nop; GRUtils.ReportGameException = nop; GRUtils.PostException = nop end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]; if s then s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse; s.sendEvent = nop; s.report = nop end
        end
    end)
end

local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {"AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem", "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"}
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect")) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.ReportPingDelayTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer); sub.ReportPingDelayTimer = nil end; sub.DelayCount = 0
                end
            end
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then AvaEx.CheckAvatarException = nop; AvaEx.CheckAvatarExceptionOnce = nop; AvaEx.ReportAvatarException = nop; AvaEx.CheckSlotMeshVisible = retFalse; AvaEx.CheckPawnVisible = retFalse; AvaEx.CheckCanBugglyPostException = retFalse end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data) if type(data) == "string" and (data:find("report", 1, true) or data:find("exception", 1, true) or data:find("cheat", 1, true) or data:find("violation", 1, true) or data:find("hack", 1, true) or data:find("verify", 1, true)) then return end; if origData then origData(data) end end
            TssSdk.SendReportInfo = nop; TssSdk.ScanMemory = retTrue; TssSdk.IsEmulator = retFalse; TssSdk.GetTssSdkReportInfo = retEmptyString; TssSdk.CheckEnvironment = retTrue; TssSdk.VerifyProcess = retTrue
        end
    end)
end

local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Trace") or k:find("Replay") or k:find("Record") or k:find("Save")) then pcall(function() sub[k] = nop end) end end end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then logRep.ReportReplay = nop; logRep.SendReportReq = nop; logRep.UploadReplay = nop end
    end)
end

local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"}
        for _, f in ipairs(flows) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do if _G[f] then _G[f] = retFalse end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do if _G[f] then _G[f] = retFalse end end
    end)
end

local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then for k, v in pairs(_G[c]) do if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then _G[c][k] = nop end end end
        end
        local SecSub = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then SecSub.ReportData = nop; SecSub.CheckCheat = retFalse; SecSub.ValidatePlayer = retTrue; SecSub.CollectData = nop; SecSub.SendToServer = nop end
    end)
end

local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then sub.ReportData = nop; sub.SendReport = nop; sub.CollectTelemetry = nop end
    end)
end

local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then _G.CoronaLab.ReportData = nop; _G.CoronaLab.SendData = nop; _G.CoronaLab.CollectData = nop; _G.CoronaLab.Telemetry = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if sub then sub.ReportData = nop; sub.SendToServer = nop; sub.CollectTelemetry = nop; sub.StopCollection = nop end
    end)
end

local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local sub = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then sub.ReportException = nop; sub.CheckModifier = retTrue; sub.ValidateModifier = retTrue; sub.ReportModifierError = nop end
    end)
end

local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local sub = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then sub.ReportLocation = nop; sub.SendLocationData = nop; sub.VerifyLocation = retTrue end
    end)
end

local function InitializeShootVerificationBypass()
    pcall(function()
        local sub = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then sub.OnShootVerifyFailed = nop; sub.SendVerifyData = nop; sub.ReportBulletHit = nop; sub.UploadHitInfo = nop; sub.VerifyShot = retTrue end
        if _G.BulletHitInfoUploadData then _G.BulletHitInfoUploadData.Report = nop; _G.BulletHitInfoUploadData.Send = nop; _G.BulletHitInfoUploadData.Upload = nop end
    end)
end

local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1, ["report_esp_usage"]=1,
                ["report_modded_files"]=1, ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1, ["RPC_ClientCoronaLab"]=1,
                ["CoronaLabReport"]=1, ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1, ["ClientCircleFlow"]=1,
                ["IsEnableReportMrpcsInCircleFlow"]=1, ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1, ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1, ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1, ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1, ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) if blocked[packetName] then return nil end; return orig(packetName, ...) end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...) for _, b in ipairs(blockedRPC) do if rpcName == b then return nil end end; return origRPC(rpcName, ...) end
        end
    end)
end

local function InitializeHiggsBosonBypass()
    pcall(function()
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero; Higgs.IsMHActive = retFalse; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false; if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false; pc.HiggsBosonComponent:ControlMHActive(0) end
        end
    end)
end

local function InitializeAntiCheatHooks()
    pcall(function()
        local HBC = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev = nop end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop; _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent:ControlMHActive(0); PlayerController.HiggsBosonComponent.bMHActive = false end
        end
    end
end

local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"}) do
            local sub = package.loaded[path]; if not sub then local s, r = pcall(require, path); if s and r then sub = r end end
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Record") or k:find("Send") or k:find("Upload") or k:find("Notify")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {"ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"}
        for _, f in ipairs(reports) do GC[f] = nop end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse; GC.CheckReportSecAttackFlow = retFalse
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1}
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop; GC.OnPlayerRPCValidateFailed = nop; GC.OnPlayerSpectateException = nop; GC.OnShutdownAfterError = nop; GC.IsBypassed = true
    end)
end

local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient", "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem", "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem", "MD5CheckSubsystem", "PakVerifySubsystem"}
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat")) then pcall(function() sub[k] = nop end) end end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

local function InitializeFinalProtection()
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY", "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"}) do if _G[flag] then _G[flag] = false end end
        local origReq = require
        local blocked = {"HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"}
        _G.require = function(m) for _, b in ipairs(blocked) do if m:find(b) then return {} end end; return origReq(m) end
    end)
end

_G.StartBypass_VIP_v3 = function()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        InitializeSLUABypass()
        InitializeMD5Bypass()
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
        InitializeKillAllSubsystems()
        InitializeFinalProtection()
        print("[ULTIMATE BYPASS] Complete by XTEAM- All Security Systems Disabled")
    end)
end

-- ============================================================
-- 7. SAFE MARK FUNCTIONS
-- ============================================================
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.XTEAMState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.XTEAMState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ============================================================
-- 8. XTEAM ESP FUNCTIONS
-- ============================================================
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime) < 0.5 then
        local validMeshes = {}
        for _, m in ipairs(markData.CachedMeshes) do
            if Valid(m) then table.insert(validMeshes, m) end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end
    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end

local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                        if not _G.XTEAMConfig.wallhackng then
                            mesh:SetRenderCustomDepth(false)
                        end
                    end)
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for i, mid in pairs(markData.MIDs[meshKey]) do
                            if Valid(mid) then
                                local defC = {R=1, G=1, B=1, A=1}
                                mid:SetVectorParameterValue("颜色", defC)
                                mid:SetVectorParameterValue("Extra Light Color", defC)
                                mid:SetVectorParameterValue("Para_Color", defC)
                                mid:SetVectorParameterValue("Tint", defC)
                                mid:SetVectorParameterValue("Color", defC)
                                mid:SetVectorParameterValue("BaseColor", defC)
                                mid:SetVectorParameterValue("BodyColor", defC)
                                mid:SetVectorParameterValue("MainColor", defC)
                                mid:SetVectorParameterValue("DiffuseColor", defC)
                                mid:SetVectorParameterValue("EmissiveColor", defC)
                            end
                        end
                    end
                end
            end
            markData.ColorApplied = false
            markData.LastColorHash = ""
            markData.LastHiddenState = nil
            if _G.XTEAMConfig.wallhackng then
                ApplyWallXuyenTuong(enemy, markData)
            end
        end
    end)
end

local function ApplyColorBodyV2(enemy, pc, markData)
    local curTime = os.clock()
    if markData.LastColorApplyTime and (curTime - markData.LastColorApplyTime) < 0.5 then return end
    markData.LastColorApplyTime = curTime
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.3 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                    if pc:LineOfSightTo(enemy) then isHidden = false else isHidden = true end
                end
            end)
            markData.CachedHiddenState = isHidden
        end
        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end
        local finalColor = hidden and {R=150, G=0, B=0, A=25} or {R=0, G=150, B=0, A=25}
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)
        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        if isMeshChanged and markData.MIDs then markData.MIDs = {} end
        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true
        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true) then
                            if not markData.MIDs then markData.MIDs = {} end
                            local meshKey = "Mesh_" .. tostring(meshIndex)
                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if Valid(mid) then
                                mid:SetScalarParameterValue("Opacity", 0.7)
                                mid:SetScalarParameterValue("Alpha", 0.7)
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Extra Light Color", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", {R=3, G=3, B=0, A=0})
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function ApplyWallXuyenTuong(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh:SetRenderCustomDepth(true)
                    mesh:SetCustomDepthStencilValue(252)
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        baseMat.bDisableDepthTest = true
                        baseMat.BlendMode = 2
                    end
                end
            end
        end
        markData.WallhackApplied = true
    end)
end

local function UndoWallXuyenTuong(enemy, markData)
    pcall(function()
        if not markData.WallhackApplied then return end
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh:SetRenderCustomDepth(false)
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if Valid(matInterface) then
                        local baseMat = matInterface:GetBaseMaterial()
                        if Valid(baseMat) then
                            baseMat.bDisableDepthTest = false
                            baseMat.BlendMode = 1
                        end
                    end
                end
            end
        end
        markData.WallhackApplied = false
    end)
end

local BTN_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local RADIUS_METERS = 350

local function CreateEnemyCounterWidget()
    if _G.XTEAMState.EnemyCounterWidget then
        if slua.isValid(_G.XTEAMState.EnemyCounterWidget) then return _G.XTEAMState.EnemyCounterWidget end
        _G.XTEAMState.EnemyCounterWidget = nil
    end
    pcall(function()
        local btn = slua.loadUI(BTN_BP)
        if not btn or not slua.isValid(btn) then return end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 10500)
        if btn.RichText_Content then
            btn.RichText_Content:SetText("BOT: 0  PLAYER: 0  TOTAL: 0")
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = 16; btn.RichText_Content:SetFont(fontInfo) end
        end
        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 12))
            slot:SetSize(FVector2D(280, 36))
        end
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        _G.XTEAMState.EnemyCounterWidget = btn
    end)
    return _G.XTEAMState.EnemyCounterWidget
end

local function UpdateEnemyCounter()
    if not _G.XTEAMConfig.Esp7 then
        if _G.XTEAMState.EnemyCounterWidget and slua.isValid(_G.XTEAMState.EnemyCounterWidget) then
            _G.XTEAMState.EnemyCounterWidget:RemoveFromParent()
            _G.XTEAMState.EnemyCounterWidget = nil
        end
        return
    end
    local now = os.clock()
    if now - (_G.XTEAMState.LastCounterUpdate or 0) < 0.3 then return end
    _G.XTEAMState.LastCounterUpdate = now
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then
            if _G.XTEAMState.EnemyCounterWidget and slua.isValid(_G.XTEAMState.EnemyCounterWidget) then
                _G.XTEAMState.EnemyCounterWidget:RemoveFromParent()
                _G.XTEAMState.EnemyCounterWidget = nil
            end
            return
        end
        local widget = CreateEnemyCounterWidget()
        if not widget or not slua.isValid(widget) then return end
        local myTeam = player.TeamID or 0
        local myLoc = player:K2_GetActorLocation()
        local botCount = 0
        local playerCount = 0
        for _, tPawn in pairs(Game:GetAllPlayerPawns() or {}) do
            if slua.isValid(tPawn) and tPawn ~= player then
                local health = tPawn.Health or 0
                local team = tPawn.TeamID or 0
                if health > 0 and team ~= myTeam then
                    local dist = FVector.Dist(myLoc, tPawn:K2_GetActorLocation()) / 100
                    if dist <= RADIUS_METERS then
                        local isBot = false
                        if tPawn.bIsAI == true or tPawn.IsAI == true then isBot = true end
                        if not isBot then
                            local pState = tPawn.PlayerState
                            if slua.isValid(pState) and (pState.bIsABot == true or pState.bIsBot == true) then isBot = true end
                        end
                        if not isBot then
                            local name = tPawn.PlayerName or (type(tPawn.GetPlayerName) == "function" and tPawn:GetPlayerName()) or ""
                            if name and name ~= "" then
                                local lowerName = string.lower(name)
                                if lowerName:find("cobra") or lowerName:find("target") or lowerName:find("bot_") or lowerName:find("b_") then isBot = true
                                elseif string.len(name) <= 2 and (name:match("^%a+$")) then isBot = true
                                elseif name:find("Player") or name:find("Enemy") or name:find("Spectator") then isBot = true end
                            else isBot = true end
                        end
                        if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end
                    end
                end
            end
        end
        local total = botCount + playerCount
        if widget.RichText_Content then
            widget.RichText_Content:SetText(string.format("BOT: %d  PLAYER: %d  TOTAL: %d", botCount, playerCount, total))
        end
    end)
end

local function CleanUpOnGameEnd()
    pcall(function()
        for mark, _ in pairs(_G.XTEAMState.TrackedMarks) do
            SafeRemoveMark(mark)
        end
        _G.XTEAMState.TrackedMarks = {}
        for key, data in pairs(_G.XTEAMState.EnemyMarks) do
            if data.hpMark then SafeRemoveMark(data.hpMark) end
            if data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
            data.CachedMeshes = nil
            data.enemy = nil
        end
        _G.XTEAMState.EnemyMarks = {}
        if _G.XTEAMState.EnemyCounterWidget and slua.isValid(_G.XTEAMState.EnemyCounterWidget) then
            _G.XTEAMState.EnemyCounterWidget:RemoveFromParent()
            _G.XTEAMState.EnemyCounterWidget = nil
        end
    end)
end

pcall(function()
    if EventSystem and EventSystem.registEvent then
        EventSystem:registEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, function(_, _, state)
            if state == "FinishedState" or state == "LeaveState" then
                CleanUpOnGameEnd()
            end
        end)
    end
end)

-- ============================================================
-- 9. ESP LOOP (XTEAM)
-- ============================================================
local function ESPLoop()
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local pc = GameplayData.GetPlayerController()
    if not Valid(pc) then return end
    local localPlayer = pc:GetPlayerCharacterSafety()
    if not Valid(localPlayer) then return end
    local MyHUD = pc.MyHUD
    if not Valid(MyHUD) then return end
    UpdateEnemyCounter()
    if _G.XTEAMConfig.EspDistance then
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters() end
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local isAlive = true
                pcall(function() isAlive = enemy:IsAlive() or (enemy.Health or 0) > 0 end)
                if isAlive then
                    local distM = localPlayer:GetDistanceTo(enemy) / 100
                    if distM <= 400 then
                        local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                        local distColor
                        if distM < 100 then distColor = DIST_COLOR_RED
                        elseif distM <= 280 then distColor = DIST_COLOR_YELLOW
                        else distColor = DIST_COLOR_GREEN end
                        MyHUD:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 1.0,
                            {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20},
                            distColor, true, false, true, nil, dynamicScale * 1.5, true)
                    end
                end
            end
        end
    end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters() end
    local enemyMarks = _G.XTEAMState.EnemyMarks or {}
    local currentKeys = {}
    for _, enemy in pairs(allCharacters) do
        if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
            local eKey = GetSafeEnemyKey(enemy)
            currentKeys[eKey] = true
            local markData = enemyMarks[eKey] or {}
            enemyMarks[eKey] = markData
            markData.enemy = enemy
            local isAlive = true
            pcall(function() isAlive = enemy:IsAlive() or (enemy.Health or 0) > 0 end)
            if not isAlive then
                if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                UndoColorBodyV2(enemy, markData)
                UndoWallXuyenTuong(enemy, markData)
                markData.ColorApplied = false
                markData.WallhackApplied = false
                markData.LastMeshCount = 0
                markData.MIDs = nil
                markData.CachedMeshes = nil
                markData.CachedHiddenState = nil
                markData.IsCleanedUp = true
                goto continue_enemy
            end
            if markData.IsCleanedUp then
                markData.IsCleanedUp = false
                markData.ColorApplied = false
                markData.WallhackApplied = false
                markData.MIDs = nil
                markData.CachedMeshes = nil
                markData.CachedHiddenState = nil
            end
            local distM = localPlayer:GetDistanceTo(enemy) / 100
            if _G.XTEAMConfig.ColorBodyV2 then
                if distM <= 400 then ApplyColorBodyV2(enemy, pc, markData)
                else UndoColorBodyV2(enemy, markData) end
            else
                UndoColorBodyV2(enemy, markData)
            end
            if _G.XTEAMConfig.wallhackng then
                if distM <= 400 then ApplyWallXuyenTuong(enemy, markData)
                else UndoWallXuyenTuong(enemy, markData) end
            else
                UndoWallXuyenTuong(enemy, markData)
            end
            if _G.XTEAMConfig.EspVip then
                if distM <= 400 then
                    if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                else
                    if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                end
            else
                if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
            end
            ::continue_enemy::
        end
    end
    for key, data in pairs(enemyMarks) do
        if not currentKeys[key] then
            if data.hpMark then SafeRemoveMark(data.hpMark) end
            if data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
            data.CachedMeshes = nil
            data.enemy = nil
            enemyMarks[key] = nil
        end
    end
    _G.XTEAMState.EnemyMarks = enemyMarks
end

-- ============================================================
-- 10. XTEAM SKIN MOD DATA (original arrays)
-- ============================================================
_G.VIP_Attachments = {
    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    -- ... (full table kept in original loader)
}
_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2, 
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4, 
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6, 
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13, 
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19, 
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22 
}
_G.VipAttachToIndex = {}
for skinId, attachList in pairs(_G.VIP_Attachments) do
    for index, attachId in ipairs(attachList) do
        if attachId > 0 then
            _G.VipAttachToIndex[attachId] = index
        end
    end
end
_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}
_G.OutfitSkins = {
    Suit = {1405628,1407895,1407140,1407141,1407142,1407550,1406872,1406971,1407103,1407219,1407366,1407512,1407625,1407856,1407906,1407994,1407993,403003,1407906,1407921,1406388,1406387,1406386,1407142,1407550,1406638,1406872,1406971,1407103,1407512,1407391,1407285,1407330,1407329,1407286,1407285,1407277,1407276,1407275,1407225,1407224,1407259,1407161,1407160,1407107,1407106,1407079,1407048,1406977,1406976,1406898,1400569,1404000,1404049,1400119,1400117,1406060,1406891,1400687,1405160,1405145,1405436,1405435,1405434,1405064,1405207,1406398,1407812,1405132,1407856,1405121,1406889,1407278,1407279,1407381,1407380,1407916,1406469,1405870,1407140,1407141,1406385,1406140,1400782,1407392,1407318,1407317,1407404,1407402,1407401,1407387,1404434,1404437,1404440,1404448,1400324,1400708,1404043,1404048,1405953,1400101,1404153,1407440,1407441,1407522},
    Bag = {
        {501001, 501002, 501003}, {1501001174, 1501002174, 1501003174}, {1501001220, 1501002220, 1501003220},
        {1501001051, 1501002051, 1501003051}, {1501001443, 1501002443, 1501003443}, {1501001265, 1501002265, 1501003265},
        {1501001321, 1501002321, 1501003321}, {1501001277, 1501002277, 1501003277}, {1501001550, 1501002550, 1501003550},
        {1501001592, 1501002592, 1501003592}, {1501001608, 1501002608, 1501003608}, {1501001024, 1501002024, 1501003024},
        {1501001019, 1501002019, 1501003019}, {1501001179, 1501002179, 1501003179}, {1501001194, 1501002194, 1501003194},
        {1501001346, 1501002346, 1501003346}, {1501001057, 1501002057, 1501003057}
    },
    Helmet = {
        {502001, 502002, 502003}, {1502001014, 1502002014, 1502003014}, {1502001349, 1502002349, 1502003349},
        {1502001012, 1502002012, 1502003012}, {1502001009, 1502002009, 1502003009}, {1502001397, 1502002397, 1502003397},
        {1502001390, 1502002390, 1502003390}, {1502001381, 1502002381, 1502003381}, {1502001358, 1502002358, 1502003358},
        {1502001350, 1502002350, 1502003350}, {1502001342, 1502002342, 1502003342},
        {1502001058, 1502002058, 1502003058}
    },
    Pet = {50000,50001,50002,50003,50004,50005,50006,50021,50022,50038,50039,50040}
}
_G.skinIdMappings = {
    [101004]={101004, 1101004246,1101004226,1101004236,1101004062,1101004078,1101004086,1101004201,1101004218,1101004046},
    [101001]={101001,1101001276,1101001265,1101001213,1101001172,1101001127,1101001230,1101001241},                    
    [101003]={101003,1101003227,1103003208,1101003195,1101003187,1101003098,1101003166,1101003218},                                             
    [101008]={101008,1101008146,1101008154,1101008079,1101008126,1101008104,1101008146,1101008061,1101008116},                    
    [101006]={101006,1101006106,1101006085,1101006061,1101006074,1101006043,1101006032,1101006084},
    [101012]={101012,1101012033},
    [101007]={101007,1101007062,1101007071},
    [102002]={102002,1102002136,1102002043,1102002061,1102002424,1102002438},      
    [101101]={101101, 1101101007},
    [101102]={101102, 1101102041},
    [102001]={102001, 1102001120},
    [102003]={102003, 1102003100},
    [101005]={101005, 1101005098},
    [103001]={103001, 1103001202,1103001191},
    [103002]={103002, 1103002106},
    [103003]={103003, 1103003042,1103003062,1103003099},
    [103012]={103012, 1103012039,1103012010},
    [104003]={104003, 1104003037},
    [104004]={104004, 1104004035, 1104004041}
}
_G.VehicleSkins = { 
    [1961001] = { 1961007, 1961149, 1961069, 1961013, 1961014, 1961015, 1961016, 1961017, 1961018, 1961020, 1961021, 1961024, 1961025, 1961029, 1961030, 1961031, 1961032, 1961033, 1961034, 1961035, 1961036, 1961037, 1961038, 1961039, 1961040, 1961041, 1961042, 1961043, 1961044, 1961045, 1961046, 1961047, 1961048, 1961049, 1961050, 1961051, 1961052, 1961053, 1961054, 1961055, 1961056, 1961057, 1961058, 1961059, 1961060, 1961061, 1961062, 1961063, 1961064, 1961065, 1961066, 1961067, 1961068,1961136, 1961137, 1961138, 1961139, 1961140, 1961141, 1961142, 1961143, 1961144, 1961145, 1961147, 1961148, 1961010, 1961150, 1961151, 1961152, 1961153 },
    [1903001] = { 1903005, 1903006, 1903007, 1903008, 1903011, 1903012, 1903013, 1903014, 1903015, 1903016, 1903017, 1903018, 1903019, 1903020, 1903021, 1903022, 1903023, 1903024, 1903029, 1903030, 1903031, 1903032, 1903033, 1903034, 1903035, 1903036, 1903037, 1903039, 1903040, 1903041, 1903042, 1903043, 1903044, 1903045, 1903046, 1903051, 1903052, 1903053, 1903054, 1903055, 1903056, 1903057, 1903058, 1903059, 1903060, 1903061, 1903062, 1903063, 1903066, 1903067, 1903068, 1903069, 1903070, 1903071, 1903072, 1903073, 1903074, 1903075, 1903076, 1903079, 1903080, 1903081, 1903082, 1903084, 1903085, 1903086, 1903087, 1903088, 1903089, 1903090, 1903189, 1903190, 1903191, 1903192, 1903193, 1903194, 1903195, 1903196, 1903197, 1903198, 1903199, 1903200, 1903201, 1903202, 1903203, 1903204, 1903205, 1903206, 1903207, 1903208, 1903209, 1903210, 1903211, 1903212, 1903213, 1903214, 1903215, 1903216, 1903217, 1903218, 1903219, 1903220, 1903221, 1903222, 1903223, 1903225, 1903226, 1903227, 1903228 }, 
    [1915001] = { 1915002, 1915003, 1915007, 1915005, 1915006, 1915008, 1915009, 1915010, 1915011, 1915012, 1915013, 1915014, 1915015, 1915016, 1915017, 1915018, 1915019, 1915020, 1915021, 1915022, 1915023, 1915024, 1915025, 1915026, 1915027, 1915099 },          
    [1908001] = { 1908002, 1908003, 1908094, 1908006, 1908007, 1908008, 1908009, 1908010, 1908011, 1908012, 1908013, 1908015, 1908016, 1908017, 1908018, 1908019, 1908021, 1908023, 1908030, 1908031, 1908032, 1908033, 1908034, 1908035, 1908036, 1908037, 1908039, 1908040, 1908041, 1908043, 1908047, 1908049, 1908050, 1908051, 1908052, 1908053, 1908054, 1908055, 1908056, 1908057, 1908059, 1908060, 1908061, 1908062, 1908063, 1908064, 1908066, 1908067, 1908068, 1908069, 1908070, 1908075, 1908076, 1908077, 1908078, 1908080, 1908081, 1908082, 1908083, 1908084, 1908085, 1908086, 1908087, 1908088, 1908089, 1908091, 1908095, 1908096, 1908097, 1908098, 1908099, 1908100, 1908101, 1908102, 1908104, 1908105, 1908106, 1908107, 1908108, 1908109, 1908110, 1908111, 1908112, 1908188, 1908189 },   
    [1907001] = { 1907007, 1907008, 1907010, 1907011, 1907012, 1907013, 1907014, 1907016, 1907018, 1907019, 1907021, 1907022, 1907023, 1907025, 1907026, 1907027, 1907028, 1907029, 1907030, 1907032, 1907033, 1907034, 1907035, 1907036, 1907037, 1907038, 1907040, 1907041, 1907043, 1907044, 1907045, 1907046, 1907047, 1907048, 1907049, 1907050, 1907051, 1907052, 1907053, 1907054, 1907055, 1907056, 1907058, 1907059, 1907060, 1907061, 1907062, 1907063, 1907064, 1907065, 1907066, 1907067, 1907068, 1907069, 1907070, 1907071, 1907072, 1907073, 1907074 }
}
_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if puffer_manager and puffer_const and puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id}) ~= puffer_const.ENUM_DownloadState.Done then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end
_G.download_item = DownloadGameItem

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end
    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end
            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end
            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end
            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end
    local hasGliderSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then 
            hasGliderSlot = true
            break 
        end
    end
    if not hasGliderSlot then SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) end
    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end
        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                local WeaponID = Weapon:GetWeaponID()
                local SkinID = _G.get_skin_id(WeaponID) or WeaponID
                local isModified = false
                local SkinData = Weapon.synData:Get(7) 
                if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
                    SkinData.defineID.TypeSpecificID = SkinID
                    Weapon.synData:Set(7, SkinData)
                    if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
                    if not _G.skinIdCache[SkinID] then 
                        _G.download_item(SkinID)
                        _G.skinIdCache[SkinID] = true 
                    end
                    isModified = true
                end
                if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
                    for AttachIdx = 0, 5 do 
                        local attachData = Weapon.synData:Get(AttachIdx)
                        if attachData then
                            local defineIDRef = slua.IndexReference(attachData, "defineID")
                            if defineIDRef then
                                local attachmentId = defineIDRef.TypeSpecificID
                                if attachmentId and attachmentId > 0 then
                                    local mapIndex = _G.BaseAttachToIndex[attachmentId] or _G.VipAttachToIndex[attachmentId]
                                    if mapIndex and _G.VIP_Attachments[SkinID][mapIndex] and _G.VIP_Attachments[SkinID][mapIndex] > 0 then
                                        local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
                                        if targetAttachId ~= attachmentId then
                                            attachData.defineID.TypeSpecificID = targetAttachId
                                            Weapon.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[targetAttachId] then 
                                                if _G.download_item then pcall(_G.download_item, targetAttachId) end
                                                _G.skinIdCache2[targetAttachId] = true 
                                            end
                                            isModified = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if isModified then
                    if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                    if Weapon.OnRep_synData then pcall(function() Weapon:OnRep_synData() end) end
                end
            end
        end
    end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then 
            _G.LastVehicleEntity = nil
            return 
        end
        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then return end
        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end
        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0
        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then 
                applySkinId = targetSkin
                break 
            end
        end
        if applySkinId and applySkinId > 0 then
            _G.skinIdCache = _G.skinIdCache or {}
            if not _G.skinIdCache[applySkinId] then 
                if _G.download_item then pcall(_G.download_item, applySkinId) end
                _G.skinIdCache[applySkinId] = true 
            end
            VehicleAvatar.curSwitchEffectId = 7303001
            if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(applySkinId, true) end
            _G.CurrentEquipVehicleID = applySkinId
            _G.LastVehicleEntity = Vehicle
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then 
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true 
        end
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.XTEAMState or not _G.XTEAMState.CustomTextData then return end
        local cData = _G.XTEAMState.CustomTextData
        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end
        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
            if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinVector and _G.skinIdMappings[102003] and _G.skinIdMappings[102003][cData.SkinVector] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][cData.SkinVector] end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinKar98K and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98K] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98K] end
            if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
            if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
            if cData.SkinAMR and _G.skinIdMappings[103012] and _G.skinIdMappings[103012][cData.SkinAMR] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][cData.SkinAMR] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
        end
        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][cData.SkinBuggy] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][cData.SkinMirado] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][cData.SkinMirado] end
        end
    end)
end

_G.InitializeSkinModSystem = function()
    pcall(function()
        local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = LobbyAvatar.PutonEquipment
            LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if attachIndex then
                    local holdingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if holdingWeaponSkinID and holdingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[holdingWeaponSkinID] then
                        local vipAttachID = _G.VIP_Attachments[holdingWeaponSkinID][attachIndex]
                        if vipAttachID and vipAttachID > 0 then
                            if self.HandleDownload then self:HandleDownload(vipAttachID, nil, nil, false) end
                            itemID = vipAttachID
                        end
                    end
                end
                if originalPutonEquipment then return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData) end
            end
            local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
            LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local retValue = originalCharEquipWeaponByResId and originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName) or nil
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return retValue
            end
            _G.LobbyBypassHacked = true
        end
    end)
    pcall(function()
        local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP and not _G.IconBaloHacked then
            local originalInitView = Common_Items_UIBP.InitView
            Common_Items_UIBP.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local displayResId = nil
                if _G.get_skin_id then
                    local skinID = _G.get_skin_id(nItemId)
                    if skinID and skinID ~= nItemId then displayResId = skinID end
                end
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not displayResId and attachIndex then
                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local LocalPlayer = GameplayData and GameplayData.GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local finalSkinID = _G.get_skin_id(weaponID) or weaponID
                            if finalSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[finalSkinID] then
                                local vipAttachID = _G.VIP_Attachments[finalSkinID][attachIndex]
                                if vipAttachID and vipAttachID > 0 then displayResId = vipAttachID end
                            end
                        end
                    end
                end
                if displayResId then
                    tExtraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end
                if originalInitView then return originalInitView(self, nItemId, nCount, nValidTime, tExtraData) end
            end
            _G.IconBaloHacked = true
        end
    end)
end

-- ============================================================
-- 11. XTEAM MENU AND CONFIG
-- ============================================================
local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    return paths
end
local ConfigFileName = "@OFFICAL_XTEAM.txt"
_G.LastConfigSaveStr = ""

_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nGTLConfig = {\n"
        for k, v in pairs(_G.XTEAMConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.XTEAMState and _G.XTEAMState.CustomTextData then
            for k, v in pairs(_G.XTEAMState.CustomTextData) do
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
        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(data)
                file:close()
                break
            end
        end
    end)
end

_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then
                content = file:read("*a")
                file:close()
                break
            end
        end
        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.GTLMODConfig then
                        for k, v in pairs(savedData.GTLMODConfig) do
                            _G.XTEAMConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.XTEAMState.CustomTextData = _G.XTEAMState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.XTEAMState.CustomTextData[k] = v
                        end
                    end
                    if savedData.ColorConfig then
                        for k, v in pairs(savedData.ColorConfig) do
                            _G.ColorConfig[k] = v
                        end
                    end
                end
            end
        end
        _G.SaveModSettings() 
    end)
end

local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker") 
        if okTicker and ticker and ticker.AddTimerOnce then 
            ticker.AddTimerOnce(3.0, AutoSaveLoop)
        end
    end)
end
if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end
_G.ReadLiveConfig = function()
    if _G.SaveModSettings then _G.SaveModSettings() end
end

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true
    _G.XTEAMState.CustomTextData = _G.XTEAMState.CustomTextData or {
        OuterSpeed = 5.6, InnerSpeed = 5.6, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120,
        SkinSuit = 0, SkinBag = 0, SkinHelmet = 0,
        SkinM416 = 0, SkinAKM = 0, SkinSCAR = 0, SkinM762 = 0, SkinAUG = 0, SkinHoney =0, SkinQBZ = 0, SkinASM = 2, SkinACE32 = 0, SkinUMP = 6,
        SkinUZI = 0, SkinVector = 0, SkinGroza = 0, SkinKar98K = 0, SkinAWM = 2, SkinAMR = 0, SkinS12K = 0, SkinDBS = 0,
        SkinDacia = 0, SkinUAZ = 0, SkinCoupe = 0, SkinBuggy = 0, SkinMirado = 0,
    }
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
        local StackESPVisual = {
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = "ESP (AUTO SETUP)", GetFunc = function() return _G.XTEAMConfig.EspVip end, SetFunc = function(c,v) _G.XTEAMConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP7", UI = AliasMap.Switcher, Text = "ESP WARNING & COUNT", GetFunc = function() return _G.XTEAMConfig.Esp7 end, SetFunc = function(c,v) _G.XTEAMConfig.Esp7 = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = "ESP RANGE", GetFunc = function() return _G.XTEAMConfig.EspDistance end, SetFunc = function(c,v) _G.XTEAMConfig.EspDistance = v return true end },
            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = "ESP MARK - 360 Radar", GetFunc = function() return _G.XTEAMConfig.EspRadar end, SetFunc = function(c,v) _G.XTEAMConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = "ESP BOX FRAME", GetFunc = function() return _G.XTEAMConfig.Esp5 end, SetFunc = function(c,v) _G.XTEAMConfig.Esp5 = v return true end },
            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP LINE ANTENA", GetFunc = function() return _G.XTEAMConfig.EspAntenna end, SetFunc = function(c,v) _G.XTEAMConfig.EspAntenna = v return true end },
            { Key = "ModMenu_ESPName", UI = AliasMap.Switcher, Text = "ESP NAME TEST(VISIBLE)", GetFunc = function() return _G.XTEAMConfig.EspName end, SetFunc = function(c,v) _G.XTEAMConfig.EspName = v return true end },
            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ ESP OUTLINE", ExpandIndex = 0, GetFunc = function() return _G.XTEAMConfig.EspOutline end, SetFunc = function(c,v) _G.XTEAMConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = "   Outline Thickness (1% is perfect)", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.XTEAMConfig.OutlineThickness end, SetFunc = function(c,v) _G.XTEAMConfig.OutlineThickness = v return true end }
        }
        local StackAimbotForce = {
            { Key = "ModMenu_AT_Enable", UI = AliasMap.Switcher, Text = "Aimbot", GetFunc = function() return _G.XTEAMConfig.AimTouchEnable end, SetFunc = function(c,v) _G.XTEAMConfig.AimTouchEnable = v return true end },
            { Key = "ModMenu_AT_IgKnock", UI = AliasMap.Switcher, Text = "Ignore Knocked", GetFunc = function() return _G.XTEAMConfig.AimTouchIgKnock end, SetFunc = function(c,v) _G.XTEAMConfig.AimTouchIgKnock = v return true end },
            { Key = "ModMenu_AT_IgBot", UI = AliasMap.Switcher, Text = "Ignore Bots", GetFunc = function() return _G.XTEAMConfig.AimTouchIgBot end, SetFunc = function(c,v) _G.XTEAMConfig.AimTouchIgBot = v return true end },
            { Key = "ModMenu_AT_Vis", UI = AliasMap.Switcher, Text = "Visibility Check", GetFunc = function() return _G.XTEAMConfig.AimTouchVisCheck end, SetFunc = function(c,v) _G.XTEAMConfig.AimTouchVisCheck = v return true end }
        }
        local StackCombatGraphic = {
            { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ iPad View (Tampilan iPad)", ExpandIndex = 0, GetFunc = function() return _G.XTEAMConfig.IpadView end, SetFunc = function(c,v) _G.XTEAMConfig.IpadView = v return true end },
            { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = "   FOV Angle (Sudut Pandang)", ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.XTEAMState.CustomTextData.IpadViewFOV or 120) - 80 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.IpadViewFOV = 80 + v return true end },
            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock 165 FPS (If turning off, will take effect next match)", GetFunc = function() return _G.XTEAMConfig.UnlockFPS end, SetFunc = function(c,v) _G.XTEAMConfig.UnlockFPS = v; if v then _G.XTEAMState.GraphicsUnlocked = false end return true end },
            { Key = "ModMenu_WallColor", UI = AliasMap.Switcher, Text = "Wallhack & Color (Green & Red)", GetFunc = function() return _G.XTEAMConfig.wallhackng end, SetFunc = function(c,v) _G.XTEAMConfig.wallhackng = v; _G.XTEAMConfig.ColorBodyV2 = v return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky (Langit Hitam)", GetFunc = function() return _G.XTEAMConfig.BlackSky end, SetFunc = function(c,v) _G.XTEAMConfig.BlackSky = v return true end },
            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "Remove Fog (Hilangkan Kabut - If turning off, will take effect next match)", GetFunc = function() return _G.XTEAMConfig.RemoveFog end, SetFunc = function(c,v) _G.XTEAMConfig.RemoveFog = v return true end },
        }
        local StackSkinMod = {
            { Key = "ModMenu_Skin_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ SKIN MOD MENU", ExpandIndex = 0, GetFunc = function() return _G.XTEAMConfig.ModSkin end, SetFunc = function(c,v) _G.XTEAMConfig.ModSkin = v return true end },
            { Key = "ModMenu_Skin_Suit", UI = AliasMap.Slider, Text = "   Outfit (1 to 87 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 80, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinSuit or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinSuit = v; if _G.OutfitSkins and _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end return true end },
            { Key = "ModMenu_Skin_Bag", UI = AliasMap.Slider, Text = "   Bag (Backpack)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 16, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinBag or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinBag = v; if _G.OutfitSkins and _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end return true end },
            { Key = "ModMenu_Skin_Helmet", UI = AliasMap.Slider, Text = "   Helmet", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 12, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinHelmet or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinHelmet = v; if _G.OutfitSkins and _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end return true end },
            { Key = "ModMenu_Skin_M416", UI = AliasMap.Slider, Text = "   M416 Skin (1 to 10 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 9, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinM416 or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinM416 = v; if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end return true end },
            { Key = "ModMenu_Skin_AKM", UI = AliasMap.Slider, Text = "   AKM Skin (1 to 8 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinAKM or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinAKM = v; if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end return true end },
            { Key = "ModMenu_Skin_SCAR", UI = AliasMap.Slider, Text = "   SCAR-L Skin (1 to 8 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinSCAR or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinSCAR = v; if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end return true end },
            { Key = "ModMenu_Skin_M762", UI = AliasMap.Slider, Text = "   Beryl M762 Skin (1 to 9 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinM762 or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinM762 = v; if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end return true end },
            { Key = "ModMenu_Skin_AUG", UI = AliasMap.Slider, Text = "   AUG Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 7, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinAUG or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinAUG = v; if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end return true end },
            { Key = "ModMenu_Skin_Honey", UI = AliasMap.Slider, Text = "   Honey Badger Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinHoney or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinHoney = v; if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end return true end },
            { Key = "ModMenu_Skin_QBZ", UI = AliasMap.Slider, Text = "   QBZ Skin ( 1 to 3)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinQBZ or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinQBZ = v; if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end return true end },
            { Key = "ModMenu_Skin_ASM", UI = AliasMap.Slider, Text = "   ASM Abakan Skin ( 1 to 2)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinASM or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinASM = v; if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end return true end },
            { Key = "ModMenu_Skin_ACE32", UI = AliasMap.Slider, Text = "   ACE32 Skin ( 1 to 2)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinACE32 or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinACE32 = v; if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end return true end },
            { Key = "ModMenu_Skin_UMP", UI = AliasMap.Slider, Text = "   UMP45 Skin (1 to 6 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinUMP or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinUMP = v; if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end return true end },
            { Key = "ModMenu_Skin_UZI", UI = AliasMap.Slider, Text = "   UZI Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinUZI or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinUZI = v; if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end return true end },
            { Key = "ModMenu_Skin_Vector", UI = AliasMap.Slider, Text = "   Vector Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinVector or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinVector = v; if _G.skinIdMappings[102003] and _G.skinIdMappings[102003][v] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][v] end return true end },
            { Key = "ModMenu_Skin_Groza", UI = AliasMap.Slider, Text = "   Groza Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinGroza or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinGroza = v; if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end return true end },
            { Key = "ModMenu_Skin_Kar98K", UI = AliasMap.Slider, Text = "   Kar98K Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinKar98K or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinKar98K = v; if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end return true end },
            { Key = "ModMenu_Skin_M24", UI = AliasMap.Slider, Text = "   M24 Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinM24 or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinM24 = v; if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end return true end },
            { Key = "ModMenu_Skin_AWM", UI = AliasMap.Slider, Text = "   AWM Skin (1 to 4 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinAWM or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinAWM = v; if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end return true end },
            { Key = "ModMenu_Skin_AMR", UI = AliasMap.Slider, Text = "   AMR Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinAMR or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinAMR = v; if _G.skinIdMappings[103012] and _G.skinIdMappings[103012][v] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][v] end return true end },
            { Key = "ModMenu_Skin_S12K", UI = AliasMap.Slider, Text = "   S12K Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinS12K or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinS12K = v; if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end return true end },
            { Key = "ModMenu_Skin_DBS", UI = AliasMap.Slider, Text = "   DBS Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinDBS or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinDBS = v; if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end return true end },
            { Key = "ModMenu_Skin_Dacia", UI = AliasMap.Slider, Text = "   Dacia (Car) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinDacia or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinDacia = v; if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end return true end },
            { Key = "ModMenu_Skin_UAZ", UI = AliasMap.Slider, Text = "   UAZ (Jeep) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinUAZ or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinUAZ = v; if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end return true end },
            { Key = "ModMenu_Skin_Coupe", UI = AliasMap.Slider, Text = "   Coupe RB (Sports) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 70, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinCoupe or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinCoupe = v; if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end return true end },
            { Key = "ModMenu_Skin_Buggy", UI = AliasMap.Slider, Text = "   Buggy Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 50, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinBuggy or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinBuggy = v; if _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][v] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][v] end return true end },
            { Key = "ModMenu_Skin_Mirado", UI = AliasMap.Slider, Text = "   Mirado (Convertible) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 27, GetFunc = function() return _G.XTEAMState.CustomTextData.SkinMirado or 1 end, SetFunc = function(c,v) _G.XTEAMState.CustomTextData.SkinMirado = v; if _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][v] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][v] end return true end }
        }
        local StackColorMod = {
            { Key = "COLOR_Visible", UI = AliasMap.Switcher, Text = "Visible Color (ESP & WH)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.VisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.VisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Invisible", UI = AliasMap.Switcher, Text = "Invisible Color (ESP & WH)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.InvisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.InvisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Brightness", UI = AliasMap.Slider, Text = "Brightness (1-50)", Min = 1, Max = 50, Step = 1,
              GetFunc = function() return _G.ColorConfig.Brightness end,
              SetFunc = function(_, v) _G.ColorConfig.Brightness = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Glow", UI = AliasMap.Slider, Text = "Glow Intensity (0-10) (WH)", Min = 0, Max = 10, Step = 0.5,
              GetFunc = function() return _G.ColorConfig.Glow end,
              SetFunc = function(_, v) _G.ColorConfig.Glow = v; _G.SaveModSettings(); return true end }
        }
        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text= "XTEAM MENU",
            UIKey = "Setting_Page_Privacy", 
            Category = {
                { Key = "Cat_SkinMod", Text= "SKIN CUSTOM", Stack = StackSkinMod },
                { Key = "Cat_Aimbot_Force", Text= "UR/ROOM-TOUCH AIM", Stack = StackAimbotForce },
                { Key = "Cat_ESP_Visual", Text= "ESP PLAYER", Stack = StackESPVisual },
                { Key = "Cat_Combat_Graphic", Text= "WALLHACK/FPS", Stack = StackCombatGraphic },
                { Key = "Cat_ColorMod", Text= "COLOR CUSTOM", Stack = StackColorMod }
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
                        if type(page) == "table" and page.Key == "ModMenu" then
                            hasModMenu = true
                            break
                        end
                    end
                    if not hasModMenu then
                        table.insert(catalog, SettingPageDefine.ModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

local function ShowGTLMODVIPMenu() 
    if _G.XTEAMMenuAlreadyShown then return end
    if _G.XTEAMState.MenuStep ~= 0 then return end
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end
        local function Step_ScamAlert()
            Msg.Show(1, "TEAM XTEAM 4.5 PAK", "DON'T PLAY LIKE A CHEATER \nAVOID FROM REPORT!!\n\nSEND FEEDBACK WhatsApp - @XTEAM_XD", function() local Web = require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://Wa.me/+923704831068") end end, function() end, "JOIN", "CLOSE")
            _G.XTEAMState.MenuStep = 99
            _G.XTEAMMenuAlreadyShown = true
        end
        local function Step_Welcome()
            Msg.Show(1, "4.5 TEAM XTEAM MOD", "ACTIVATION SUCCESSFUL!\n\nIF YOU WANT TO PLAY BETTER EXPERIENCE CHEAT THEN DM USERNAME.\nTHE REAL OWNER IS TELEGRAM @XTEAM_XD",
            function() 
                _G.InitModMenuTab()
                Notify("VIP MOD MENU BY XTEAM to toggle features!")
                Step_ScamAlert()
            end, 
            function() end, "OK", "CLOSE")
        end
        _G.XTEAMState.MenuStep = 1
        Step_Welcome() 
    end)
end

-- ============================================================
-- 12. XTEAM 165 FPS AND IPAD VIEW
-- ============================================================
local function InitializeGraphicsUnlock() 
    if isExpired then return end
    if _G.XTEAMState.GraphicsUnlocked or currentTime > limitTime then return end
    pcall(function()
        local SettingCfg = require("client.logic.setting.setting_config")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if SettingCfg then
            if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
            if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
        end
        if GraphicSettingDB then
            if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
        end
    end)
    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        local KismetMathLibrary = import("KismetMathLibrary") or _G.KismetMathLibrary
        local FLinearColor = import("LinearColor") or _G.FLinearColor
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
        if GSC_FPS and GSC_FPS.__inner_impl then
            local fps_impl = GSC_FPS.__inner_impl
            function fps_impl:GetMaxFPSLevel() return 8, 8 end
            function fps_impl:InitRealSupportFPS()
                local RealSupportFPS = {}
                for i = 1, 8 do RealSupportFPS[i] = {true, true} end
                if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false) end
                return RealSupportFPS
            end
            function fps_impl:UpdateSelectedFPSState(selectedLevel)
                if not slua.isValid(self.UIRoot) then return end
                for level = 2, 8 do
                    local name = "NodeFps" .. (({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level] or 120)
                    local widget = self.UIRoot[name]
                    if slua.isValid(widget) then
                        widget:SetIsEnabled(true) 
                        pcall(function() widget:SetRenderOpacity(1.0) end)
                        local switcher = self.UIRoot["WidgetSwitcher_" .. level]
                        if slua.isValid(switcher) then 
                            switcher:SetActiveWidgetIndex(level == selectedLevel and 0 or 1) 
                        end
                    end
                end
            end
        end
        if GSC_FPSFT and GSC_FPSFT.__inner_impl then
            local ft_impl = GSC_FPSFT.__inner_impl
            local NMinFPS, NStep = 90, 5
            local function clamp(value, min, max)
                if value < min then return min end
                if max < value then return max end
                return value
            end
            local function lerp(a, b, t) return a + (b - a) * t end
            local function _getColorByPercent(start, finish, percent)
                if not FLinearColor then return nil end
                return FLinearColor(lerp(start.R, finish.R, percent), lerp(start.G, finish.G, percent), lerp(start.B, finish.B, percent), lerp(start.A, finish.A, percent))
            end
            ft_impl.ShowOrHide = function(self)
                self:SelfHitTestInvisible()
                if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
            end
            ft_impl.InitFPSFTSwitch = function(self)
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, FPSFineTuneSwitch) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end
            ft_impl.InitFPSFTValue165 = function(self)
                local itemRoot = self.UIRoot
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                local FPSFineTuneNum = 165
                if FPSFineTuneSwitch then
                    FPSFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
                    itemRoot.Slider_screen3:SetLocked(false)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 1.0, 1.0, 1.0))
                    end
                else
                    itemRoot.Slider_screen3:SetLocked(true)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 0.625, 0.6, 1))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 0.625, 0.6, 1.0))
                    end
                end
                local FPSFineTunePer = (FPSFineTuneNum - NMinFPS) / (165 - NMinFPS)
                itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
                itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
                itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)
                if FLinearColor then
                    local startColor = FLinearColor(1.0, 1.0, 1.0, 1.0)
                    local midColor = FLinearColor(1.0, 0.54, 0.11, 1.0)
                    local endColor = FLinearColor(1.0, 0.23, 0.15, 1.0)
                    local sliderColor = FPSFineTunePer < 0.4 and startColor or _getColorByPercent(midColor, endColor, (FPSFineTunePer - 0.4) / 0.6)
                    itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
                end
            end
            ft_impl.OnFPSFTValueChange3 = function(self, FPSFineTuneNum)
                GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, FPSFineTuneNum)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
                if gameInstance then
                    gameInstance:ExecuteCMD("t.MaxFPS", tostring(FPSFineTuneNum))
                    gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(FPSFineTuneNum))
                end
            end
            ft_impl.OnFPSFTSliderValueChange3 = function(self, value)
                if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) and KismetMathLibrary then
                    local FPSFineTuneNum = KismetMathLibrary.FCeil(value * (165 - NMinFPS) / NStep) * NStep + NMinFPS
                    self:OnFPSFTValueChange3(clamp(FPSFineTuneNum, NMinFPS, 165))
                end
            end
            ft_impl.OnFPSFTAdd = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTAdd2 = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus2 = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTSliderValueChange = ft_impl.OnFPSFTSliderValueChange3
            ft_impl.OnFPSFTSliderValueChange2 = ft_impl.OnFPSFTSliderValueChange3
        end
    end)
    _G.XTEAMState.GraphicsUnlocked = true
    Notify("Graphics & FPS 165Hz Unlocked (Upgraded Version)")
end

-- ============================================================
-- 13. NATIVE ESP INIT
-- ============================================================
local function InitializeNativeESP() 
    if _G.XTEAMState.NativeESPReady then return end
    pcall(function() 
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") 
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig") 
        local function ApplyCfg(cfg)
            if not cfg then return end 
            if cfg[1006] then 
                cfg[1006].bBindBlocked = true;
                cfg[1006].bBindOutScreen = true; 
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000; 
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root"; 
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30) 
            end 
            cfg[8888] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2 
            } 
            cfg[9999] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true, 
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true, 
                Priority = 2 
            } 
        end 
        ApplyCfg(currentMarkCfg) 
        for k, cfg in pairs(package.loaded) do 
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then 
                ApplyCfg(cfg) 
            end 
        end 
    end)
    _G.XTEAMState.NativeESPReady = true 
    Notify("Native ESP System Initialized") 
end

-- ============================================================
-- 14. GET ENEMY TARGETS (for aimbot)
-- ============================================================
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    else
        return result
    end
    local myTeam = player:GetTeamID()
    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player then
            -- Check team
            local actorTeam = actor.TeamID or (type(actor.GetTeamID) == "function" and actor:GetTeamID()) or 0
            if actorTeam == myTeam then goto continue end
            -- Check alive – use pcall to avoid errors
            local isAlive = false
            pcall(function()
                if type(actor.IsAlive) == "function" then
                    isAlive = actor:IsAlive()
                elseif actor.Health ~= nil then
                    isAlive = (actor.Health > 0)
                end
            end)
            if not isAlive then goto continue end
            local dist = player:GetDistanceTo(actor)
            if dist <= radius then
                table.insert(result, actor)
            end
            ::continue::
        end
    end
    return result
end

-- ============================================================
-- 15. XTEAM AIMBOT (AimTouch)
-- ============================================================
_G.AimTouch = function()
    pcall(function()
        if not _G.XTEAMConfig.AimTouchEnable then return end
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        local isShotgun = false
        local isSniper = false
        local currentAmmo = 1
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then isShotgun = true end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then isSniper = true end
            if type(weapon.GetCurrentAmmo) == "function" then currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then currentAmmo = weapon.CurrentAmmo end
        end
        if _G.XTEAMState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.XTEAMState.IsAutoFiring = false
        end
        if isShotgun and currentAmmo <= 0 then return end
        local cond = 2; local prioMode = 1; local boneIdx = 1; local speedVal = 50; local fovVal = 30; local maxDistMeters = 50
        local useVisCheck = false; local igKnock = false; local igBot = false; local predVal = 0; local recoilCompVal = 0
        useVisCheck = _G.XTEAMConfig.AimTouchVisCheck
        igKnock = _G.XTEAMConfig.AimTouchIgKnock
        igBot = _G.XTEAMConfig.AimTouchIgBot
        if isShotgun then
            cond = 2; prioMode = 1; boneIdx = 2; speedVal = 90; fovVal = 32; maxDistMeters = 30
        elseif isADS then
            if isSniper then
                cond = 2; prioMode = 1; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 400; predVal = 0
            else
                cond = 1; prioMode = 1; boneIdx = 2; speedVal = 85; fovVal = 28; maxDistMeters = 300; predVal = 0; recoilCompVal = 0
            end
        else
            cond = 1; prioMode = 1; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 250
        end
        if cond == 1 and not isFiring then return end
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
        for _, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            if igKnock and target.HealthStatus == 1 then goto continue end
            if igBot then
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.BotStatusCache = _G.BotStatusCache or {}
                local cachedBot = _G.BotStatusCache[tId]
                if cachedBot == nil then
                    cachedBot = false
                    if target.bIsAI == true or target.IsAI == true or target.bIsAi == true then cachedBot = true end
                    if not cachedBot then
                        if target.AIData ~= nil or target.AIController ~= nil or target.bIsAIActor == true then cachedBot = true end
                        if not cachedBot and target.PlayerAIType ~= nil and target.PlayerAIType ~= 0 then cachedBot = true end
                        if not cachedBot and type(target.IsAICharacter) == "function" then
                            local ok, r = pcall(function() return target:IsAICharacter() end)
                            if ok and r then cachedBot = true end
                        end
                        if not cachedBot and type(target.GetIsAI) == "function" then
                            local ok, r = pcall(function() return target:GetIsAI() end)
                            if ok and r then cachedBot = true end
                        end
                    end
                    if not cachedBot then
                        local pState = target.PlayerState
                        if slua.isValid(pState) then
                            if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI or pState.bIsRobot or pState.bIsAiPlayer then cachedBot = true end
                            if not cachedBot and pState.PlayerAIType ~= nil and pState.PlayerAIType ~= 0 then cachedBot = true end
                            if not cachedBot and type(pState.IsABot) == "function" then
                                local ok, r = pcall(function() return pState:IsABot() end)
                                if ok and r then cachedBot = true end
                            end
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
                    if not cachedBot and type(target.GetController) == "function" then
                        local ok, ctrl = pcall(function() return target:GetController() end)
                        if ok and slua.isValid(ctrl) and (ctrl.bIsAI == true or ctrl.IsAI == true or ctrl.AIData ~= nil) then cachedBot = true end
                    end
                    _G.BotStatusCache[tId] = cachedBot
                end
                if cachedBot then goto continue end
            end
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end
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
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            if distScreen > FOV_RADIUS then goto continue end
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
            ::continue::
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
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
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
        if speedVal >= 100 then smoothFactor = 1.0
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
        pc:SetControlRotation({ Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }, "AimTouch")
        if isShotgun then
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
                    _G.XTEAMState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ============================================================
-- 16. MAIN LOOP
-- ============================================================
local function MainLoop() 
    if isExpired then return end
    if _G.XTEAMState.CustomTextData == nil then 
        _G.XTEAMState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120}
    end
    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData") 
    if not okData or not GameplayData then return end 
    local pc = GameplayData.GetPlayerController() 
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end 
    if not Valid(localPlayer) then 
        if _G.XTEAMState.TrackedMarks then
            for markId, _ in pairs(_G.XTEAMState.TrackedMarks) do
                SafeRemoveMark(markId)
            end
        end
        _G.XTEAMState.TrackedMarks = {} 
        for key, data in pairs(_G.XTEAMState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
        end
        _G.XTEAMState.EnemyMarks = {}
        _G.XTEAMState.PrevGraphicsState = {}
        return 
    end
    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil
    if _G.XTEAMConfig.UnlockFPS then InitializeGraphicsUnlock() end
    InitializeNativeESP()
    ShowGTLMODVIPMenu()
    if _G.XTEAMConfig.IpadView and _G.XTEAMState.CustomTextData then
        pcall(function()
            local targetTPP = _G.XTEAMState.CustomTextData.IpadViewFOV or 120
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
    -- Skin mod loop
    if _G.XTEAMConfig.ModSkin then
        if not _G.TDSkinLoopStarted then
            if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
            if _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end
            _G.TDSkinLoopStarted = true
        end
        _G.XTEAMState.SkinWasApplied = true
        local curTime = os.clock()
        if not _G.LastSkinUpdateTime or (curTime - _G.LastSkinUpdateTime) > 1.5 then
            _G.LastSkinUpdateTime = curTime
            pcall(function()
                local isAlive = type(localPlayer.IsAlive) == "function" and localPlayer:IsAlive() or true
                if isAlive then
                    if _G.ReadLiveConfig then _G.ReadLiveConfig() end
                    if _G.equip_character_avatar then _G.equip_character_avatar(localPlayer) end
                    if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(localPlayer) end
                    if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(localPlayer) end
                    if _G.HandlePetLogic then _G.HandlePetLogic() end
                end
            end)
        end
    else
        if _G.XTEAMState.SkinWasApplied then
            _G.OutfitMap = {}
            _G.WeaponSkinMap = {}
            _G.VehicleSkinMap = {}
            pcall(function()
                local WeaponManager = localPlayer:GetWeaponManager()
                if Valid(WeaponManager) then
                    for slot = 1, 3 do
                        local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
                        if Valid(Weapon) and Valid(Weapon.synData) then
                            local WeaponID = Weapon:GetWeaponID()
                            local SkinData = Weapon.synData:Get(7)
                            if SkinData and SkinData.defineID then
                                SkinData.defineID.TypeSpecificID = WeaponID
                                Weapon.synData:Set(7, SkinData)
                                if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(WeaponID) end) end
                                if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                            end
                        end
                    end
                end
                local Vehicle = localPlayer:GetCurrentVehicle()
                if Valid(Vehicle) then
                    local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
                    if Valid(VehicleAvatar) and type(VehicleAvatar.GetDefaultAvatarID) == "function" then
                        local defId = VehicleAvatar:GetDefaultAvatarID()
                        if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(defId, true) end
                    end
                end
                if localPlayer.AvatarComponent2 and type(localPlayer.AvatarComponent2.OnRep_BodySlotStateChanged) == "function" then
                    localPlayer.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end)
            _G.XTEAMState.SkinWasApplied = false
        end
        _G.TDSkinLoopStarted = false
    end
    -- Recoil comp (legacy)
    pcall(function()
        if _G.XTEAMConfig.CustomAimbot and localPlayer.bIsWeaponFiring and localPlayer.bIsGunADS then
            local outerRecoilVal = _G.XTEAMState.CustomTextData.OuterRecoil or 0
            if outerRecoilVal > 0 then
                local curTime = os.clock()
                if not _G.RecoilTargetCacheTime or (curTime - _G.RecoilTargetCacheTime) > 0.2 then
                    _G.RecoilTargetCacheTime = curTime
                    _G.HasRecoilTargetCached = false
                    local ui_util = require("client.common.ui_util")
                    if ui_util then
                        local viewportSize = ui_util.GetViewportSize()
                        if viewportSize then
                            local centerX = viewportSize.X * 0.5
                            local centerY = viewportSize.Y * 0.5
                            local FOV_RADIUS = (6 / 100.0) * (viewportSize.X / 2.0) 
                            local enemies = _G.GetEnemyTargetsFromActors(40000) 
                            if enemies and #enemies > 0 then
                                local FVector2D = import("Vector2D")
                                for _, target in ipairs(enemies) do
                                    if slua.isValid(target) and target.HealthStatus ~= 1 then 
                                        local tPos = type(target.K2_GetActorLocation) == "function" and target:K2_GetActorLocation() or nil
                                        if tPos then
                                            local screen = FVector2D()
                                            if pc:ProjectWorldLocationToScreen(tPos, screen, false) and screen.X > 0 and screen.Y > 0 then
                                                local dx = screen.X - centerX
                                                local dy = screen.Y - centerY
                                                if math.sqrt(dx*dx + dy*dy) <= FOV_RADIUS then
                                                    _G.HasRecoilTargetCached = true
                                                    break 
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if _G.HasRecoilTargetCached then
                    local currentRot = pc:GetControlRotation()
                    if currentRot then
                        local pullDownForce = (outerRecoilVal / 50.0) * 1.5
                        currentRot.Pitch = currentRot.Pitch - pullDownForce
                        pc:SetControlRotation(currentRot, "CustomAimbotRecoil")
                    end
                end
            end
        else
            _G.HasRecoilTargetCached = false
        end
    end)
    -- Higgs cleanup
    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)
    -- AutoHead hook
    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.XTEAMState.OrigAutoAimCompCached then
                _G.XTEAMState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                    HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                    ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                    PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                }
            end
            if _G.XTEAMConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = 100
                    autoComp.AimAssistConfig.ChestPriority = 100
                    autoComp.AimAssistConfig.PelvisPriority = 100
                end
            else
                local orig = _G.XTEAMState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = orig.HeadPriority or 1
                    autoComp.AimAssistConfig.ChestPriority = orig.ChestPriority or 1
                    autoComp.AimAssistConfig.PelvisPriority = orig.PelvisPriority or 1
                end
            end
        end
    end)
    -- Graphics commands
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.XTEAMConfig.RemoveGrass and not _G.XTEAMState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.XTEAMState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.XTEAMConfig.RemoveGrass and _G.XTEAMState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.XTEAMState.PrevGraphicsState.RemoveGrass = false
            end
            if _G.XTEAMConfig.RemoveFog and not _G.XTEAMState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "0")           
                gi:ExecuteCMD("r.VolumetricFog", "0") 
                _G.XTEAMState.PrevGraphicsState.RemoveFog = true
            elseif not _G.XTEAMConfig.RemoveFog and _G.XTEAMState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "1")           
                gi:ExecuteCMD("r.VolumetricFog", "1") 
                _G.XTEAMState.PrevGraphicsState.RemoveFog = false
            end
            if _G.XTEAMConfig.WhiteBody and not _G.XTEAMState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.XTEAMState.PrevGraphicsState.WhiteBody = true
            elseif not _G.XTEAMConfig.WhiteBody and _G.XTEAMState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.XTEAMState.PrevGraphicsState.WhiteBody = false
            end
            if _G.XTEAMConfig.ColorBodyV2 and not _G.XTEAMState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.XTEAMState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.XTEAMConfig.ColorBodyV2 and _G.XTEAMState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.XTEAMState.PrevGraphicsState.ColorBodyV2 = false
            end
            if _G.XTEAMConfig.BlackSky and not _G.XTEAMState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.XTEAMState.PrevGraphicsState.BlackSky = true
            elseif not _G.XTEAMConfig.BlackSky and _G.XTEAMState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.XTEAMState.PrevGraphicsState.BlackSky = false
            end
        end
    end)
    -- Weapon mods (legacy)
    pcall(function()
        local weapon = nil
        pcall(function()
            local weaponManager = localPlayer.WeaponManagerComponent
            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then
                weapon = weaponManager:GetCurrentWeapon()
            end
        end)
        if not Valid(weapon) then
            if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
            elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
        end
        if Valid(weapon) then
            local entities = {}
            if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
            if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
            if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then 
                table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent) 
            end
            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.XTEAMConfig.CustomHRecoil or _G.XTEAMConfig.CustomVRecoil or _G.XTEAMConfig.LessShake or _G.XTEAMConfig.Accuracy or _G.XTEAMConfig.Crosshair or _G.XTEAMConfig.GodMode or _G.XTEAMConfig.AutoHead or _G.XTEAMConfig.CustomAimbot or _G.XTEAMConfig.CustomAimbotClose
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
                    if _G.XTEAMConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.XTEAMState.CustomTextData.HRecoil or 0.3 
                    elseif _G.XTEAMConfig.LessRecoil then entity.AccessoriesHRecoilFactor = 0.3 end
                    if _G.XTEAMConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.XTEAMState.CustomTextData.VRecoil or 0.3
                    elseif _G.XTEAMConfig.VerticalRecoil then entity.AccessoriesVRecoilFactor = 0.3 end
                    if _G.XTEAMConfig.LessShake then entity.RecoilKickADS = 0.0; entity.RecoilKickADS = 0.0; entity.RecoilKickADS = 0.0 end
                    if _G.XTEAMConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.XTEAMConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                    if _G.XTEAMConfig.GodMode then entity.BulletFireSpeed = 500000.0; entity.ShootInterval = 0.001; entity.BaseDamage = 60000.0 end
                    if entity.AutoAimingConfig then
                        if not entity.OriginalAutoAimCached then
                            entity.OriginalAutoAimCached = {
                                OuterSpeed = entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,
                                InnerSpeed = entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
                            }
                        end
                        if _G.XTEAMConfig.AutoHead then
                            pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                        end
                        if _G.XTEAMConfig.CustomAimbot then
                            local speed = _G.XTEAMState.CustomTextData.OuterSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.RangeRate = 1.7
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1.0
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.RangeRate = 1.7
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1.0
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        elseif _G.XTEAMConfig.CustomAimbotClose then
                            local speed = _G.XTEAMState.CustomTextData.InnerSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        end
                    end
                    entity.GTLMODWeaponModsActive = true
                elseif entity.GTLMODWeaponModsActive then
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
                    if entity.AutoAimingConfig and entity.OriginalAutoAimCached then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Spine_01", "Pelvis", "Head" } end)
                        if entity.AutoAimingConfig.OuterRange and entity.OriginalAutoAimCached.OuterSpeed then
                            entity.AutoAimingConfig.OuterRange.Speed = entity.OriginalAutoAimCached.OuterSpeed
                        end
                        if entity.AutoAimingConfig.InnerRange and entity.OriginalAutoAimCached.InnerSpeed then
                            entity.AutoAimingConfig.InnerRange.Speed = entity.OriginalAutoAimCached.InnerSpeed
                        end
                    end
                    entity.GTLMODWeaponModsActive = false
                end
            end
        end
    end)
    -- == CALL XTEAM ESP LOOP ==
    ESPLoop()
end

_G.XTEAMState.LoopToken = (_G.XTEAMState.LoopToken or 0) + 1 
local myToken = _G.XTEAMState.LoopToken

-- ============================================================
-- 17. FAST TICK (0.4s)
-- ============================================================
local function FastTick() 
    if isExpired then 
        if not _G.XTEAMNotifiedExpire then
            Notify("MOD HAS EXPIRED! PLEASE CONTACT ADMIN TO RENEW!\nTelegram @XTEAM_XD")
            _G.XTEAMNotifiedExpire = true
        end
        return 
    end
    if myToken ~= _G.XTEAMState.LoopToken then return end
    pcall(MainLoop) 
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(0.5, FastTick) 
    end 
end

-- ============================================================
-- 18. FAST AIMBOT TICK (0.016s)
-- ============================================================
local aimbotToken = 0
local function FastAimbotTick()
    if isExpired then return end
    if aimbotToken ~= _G.XTEAMState.AimbotLoopToken then return end
    pcall(function()
        if _G.XTEAMConfig.AimTouchEnable then
            _G.AimTouch()
        end
    end)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.016, FastAimbotTick)
    end
end

-- ============================================================
-- 19. INITIALIZE ALL MOD SYSTEMS
-- ============================================================
local function InitAllModSystems()
    if isExpired then return end 
    pcall(function()
        if _G.StartBypass_VIP_v3 then _G.StartBypass_VIP_v3() end
        if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
    end)
    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    if not GameplayData then return end
    pcall(function()
        local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if slua.isValid(LocalPlayer) then
            if LocalPlayer.bHasShownDevNotice == nil then
                LocalPlayer.bHasShownDevNotice = false 
                LocalPlayer.bHasShownExpiredNotice = false 
                LocalPlayer.bIsDeadFlag = false
            end
        end
    end)
end

-- ============================================================
-- 20. START LOOPS
-- ============================================================
if not isExpired then
    pcall(function() 
        require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems) 
    end)
    FastTick() 
    _G.XTEAMState.AimbotLoopToken = (_G.XTEAMState.AimbotLoopToken or 0) + 1
    aimbotToken = _G.XTEAMState.AimbotLoopToken
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.1, FastAimbotTick)
    end
    Notify("You are using VIP Mod v4. If you don't have a key, inbox Telegram : @XTEAM_XD")
else
    FastTick() 
end

-- ============================================================
-- 21. VERSION-SPECIFIC & COMMON BYPASS (GL/KR/TW)
-- ============================================================
pcall(function()
    print("[BYPPASS] 🔧 Applying version-specific bypasses...")
    if _G.IS_GLOBAL then
        print("[GLOBAL] 🔧 Applying Global bypasses...")
        if _G.TssSdk then
            _G.TssSdk.IsEmulator = function() return false end
            _G.TssSdk.ScanMemory = function() return true end
            _G.TssSdk.ReportData = function() end
            _G.TssSdk.SendReport = function() end
            _G.TssSdk.OnRecvData = function() end
            print("[GLOBAL] ✅ TssSdk bypassed")
        end
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            print("[GLOBAL] ✅ HiggsBoson bypassed")
        end
        print("[GLOBAL] ✅ Bypass complete!")
    end
    if _G.IS_KR then
        print("[KR] 🔧 Applying Korea bypasses...")
        if _G.TssSdk then
            _G.TssSdk.IsEmulator = function() return false end
            _G.TssSdk.ScanMemory = function() return true end
            _G.TssSdk.ReportData = function() end
            _G.TssSdk.SendReport = function() end
            _G.TssSdk.OnRecvData = function() end
            print("[KR] ✅ TssSdk bypassed")
        end
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            print("[KR] ✅ HiggsBoson bypassed")
        end
        print("[KR] ✅ Bypass complete!")
    end
    if _G.IS_TW_VERSION then
        print("[TW] 🔧 Applying Taiwan bypasses...")
        if _G.TssSdk then
            _G.TssSdk.IsEmulator = function() return false end
            _G.TssSdk.ScanMemory = function() return true end
            _G.TssSdk.ReportData = function() end
            _G.TssSdk.SendReport = function() end
            _G.TssSdk.OnRecvData = function() end
            print("[TW] ✅ TssSdk bypassed")
        end
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            print("[TW] ✅ HiggsBoson bypassed")
        end
        print("[TW] ✅ Bypass complete!")
    end
    print("[BYPPASS] ✅ All version bypasses applied!")
end)

pcall(function()
    print("[BYPPASS] 🔧 Applying common bypasses for all versions...")
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
        local module = package.loaded[path] or pcall(require, path) and require(path)
        if module then
            if module.Report then module.Report = function() end end
            if module.SendReport then module.SendReport = function() end end
            if module.ReportEvent then module.ReportEvent = function() end end
            if module.ReportException then module.ReportException = function() end end
            if module.ReportData then module.ReportData = function() end end
        end
    end
    if NetUtil and NetUtil.SendPacket then
        local originalSend = NetUtil.SendPacket
        local blockedPackets = {
            ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
            ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
            ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1,
            ["ReportAimFlow"]=1, ["ReportHitFlow"]=1,
            ["ReportCircleFlow"]=1, ["ReportJumpFlow"]=1,
            ["ReportSecurityAlert"]=1, ["ReportAntiCheat"]=1,
            ["ReportViolation"]=1, ["ReportBan"]=1, ["ReportKick"]=1,
        }
        NetUtil.SendPacket = function(packetName, ...)
            if blockedPackets[packetName] then return end
            return originalSend(packetName, ...)
        end
        NetUtil.IsBypassed = true
    end
    print("[BYPPASS] ✅ Common bypasses applied!")
end)

print("[XTEAM] ✅ Loader fully initialized!")
-- ============================================================
-- END OF COMPLETE LOADER
-- ============================================================
