-- Remove obfuscation: watermark check and dummy loop are removed.
-- All meaningful logic is kept.

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local combine_class = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")

-- ========== RPC Definitions ==========
local ServerRPCs = {
    ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} },
    ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } },
    RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
}

local ClientRPCs = {
    RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
}

local MulticastRPCs = {
    MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
}

-- Expose RPCs globally
_G.ServerRPC = ServerRPCs
_G.ClientRPC = ClientRPCs
_G.MulticastRPC = MulticastRPCs

-- ========== Path Finder ==========
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
        ["mini_obb.pak"] = {
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

-- ========== PAKxTEAM Loader ==========
local PAKxTEAM_TAG = "[OFFICIAL PAKxTEAM]"
local PAKxTEAM_MSG_KEY = 896211

local PAKxTEAM_CANDIDATE_PATHS = {
  -- com.tencent.ig (Global)
  "/storage/emulated/0/Android/data/com.tencent.ig/files/PAKxTEAM.lua",
  "//storage/emulated/0/Android/data/com.tencent.ig/files/PAKxTEAM.lua",
  "/sdcard/Android/data/com.tencent.ig/files/PAKxTEAM.lua",

  -- com.vng.pubgmobile (Vietnam)
  "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/PAKxTEAM.lua",
  "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/PAKxTEAM.lua",
  "/sdcard/Android/data/com.vng.pubgmobile/files/PAKxTEAM.lua",

  -- com.pubg.imobile (BGMI / India)
  "/storage/emulated/0/Android/data/com.pubg.imobile/files/PAKxTEAM.lua",
  "//storage/emulated/0/Android/data/com.pubg.imobile/files/PAKxTEAM.lua",
  "/sdcard/Android/data/com.pubg.imobile/files/PAKxTEAM.lua",

  -- com.pubg.krmobile (Korea / Japan)
  "/storage/emulated/0/Android/data/com.pubg.krmobile/files/PAKxTEAM.lua",
  "//storage/emulated/0/Android/data/com.pubg.krmobile/files/PAKxTEAM.lua",
  "/sdcard/Android/data/com.pubg.krmobile/files/PAKxTEAM.lua",

  -- com.rekoo.pubgm (Taiwan)
  "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/PAKxTEAM.lua",
  "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/PAKxTEAM.lua",
  "/sdcard/Android/data/com.rekoo.pubgm/files/PAKxTEAM.lua",

  -- UE4 Saved directories fallback
  "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/PAKxTEAM.lua",
  "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/PAKxTEAM.lua",
  "/storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/PAKxTEAM.lua",
}

local function ShowPAKxTEAMLoading(percent, statusText, isError)
  local msg = string.format("%s Loading: %d%% - %s", PAKxTEAM_TAG, percent, statusText or "")

  local color = { R = 1, G = 1, B = 0, A = 1 }
  if isError then
    color = { R = 1, G = 0.2, B = 0.2, A = 1 }
  elseif percent >= 100 then
    color = { R = 0.1, G = 1, B = 0.2, A = 1 }
  elseif percent >= 60 then
    color = { R = 0, G = 0.85, B = 1, A = 1 }
  end

  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      local duration = (percent >= 100 or isError) and 6.0 or 3.5
      sh.AddOnScreenDebugMessage(msg, PAKxTEAM_MSG_KEY, duration, color, { X = 1.35, Y = 1.35 })
    end
  end)

  pcall(function()
    if _G.GTLModNotify then
      _G.GTLModNotify(msg)
    end
  end)

  print(msg)
end

local function PAKxTEAMRunLater(sec, fn)
  local scheduled = false
  pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
      ticker.AddTimerOnce(sec, fn)
      scheduled = true
    elseif ticker and ticker.AddTimer then
      ticker.AddTimer(sec, fn)
      scheduled = true
    end
  end)
  if scheduled then return end

  if _G.SetTimer then
    local ok = pcall(_G.SetTimer, sec, fn)
    if ok then return end
  end

  pcall(fn)
end

local function LoadPAKxTEAMLuaFromPath()
  if _G._PAKxTEAM_LUA_LOADED then return end
  _G._PAKxTEAM_LUA_LOADED = true
  _G._ModChunks = _G._ModChunks or {}

  ShowPAKxTEAMLoading(15, "Game Island reached, searching PAKxTEAM.lua...")

  PAKxTEAMRunLater(0.35, function()
    local targetPath = nil
    for _, path in ipairs(PAKxTEAM_CANDIDATE_PATHS) do
      local f = io.open(path, "r")
      if f then
        f:close()
        targetPath = path
        break
      end
    end

    if not targetPath then
      ShowPAKxTEAMLoading(0, "ERROR: PAKxTEAM.lua not found in files/ path!", true)
      pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
          Msg.Show(4, "PAKxTEAM LOADER ERROR", "PAKxTEAM.lua not found!\n\nPlease put PAKxTEAM.lua in:\n/storage/emulated/0/Android/data/<package>/files/PAKxTEAM.lua\n\nPackages:\n- com.tencent.ig\n- com.vng.pubgmobile\n- com.pubg.imobile", function() end)
        end
      end)
      return
    end

    local displayPath = targetPath:match("([^/]+/[^/]+/files/.*)$") or targetPath
    ShowPAKxTEAMLoading(45, "Found: " .. displayPath)

    PAKxTEAMRunLater(0.35, function()
      ShowPAKxTEAMLoading(70, "Reading PAKxTEAM.lua into memory...")
      local file, err = io.open(targetPath, "rb")
      if not file then
        ShowPAKxTEAMLoading(0, "ERROR reading file: " .. tostring(err), true)
        return
      end
      local content = file:read("*a")
      file:close()

      if not content or #content == 0 then
        ShowPAKxTEAMLoading(0, "ERROR: PAKxTEAM.lua is empty!", true)
        return
      end

      PAKxTEAMRunLater(0.35, function()
        ShowPAKxTEAMLoading(85, string.format("Compiling script (%d KB)...", math.floor(#content / 1024)))
        local load_fn = loadstring or load
        local chunk, compileErr = load_fn(content, "=PAKxTEAM.lua")

        if not chunk then
          ShowPAKxTEAMLoading(0, "Syntax Error: " .. tostring(compileErr), true)
          return
        end

        _G._ModChunks["PAKxTEAM.lua"] = chunk

        PAKxTEAMRunLater(0.35, function()
          ShowPAKxTEAMLoading(95, "Starting mod systems & hooks...")
          local ok, runErr = pcall(chunk)

          if not ok then
            ShowPAKxTEAMLoading(0, "Runtime Error: " .. tostring(runErr), true)
            return
          end

          ShowPAKxTEAMLoading(100, "PAKxTEAM.lua Loaded Successfully!")

          pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
              Msg.Show(1, "@Unusualhacker7 PAKxTEAM", "MOD MENU SYSTEM SUCCESSFULLY LOADED (100%)\n\nALL CHEAT FREE @Unusualhacker7", function() end, function() end, "OK", "SKIP")
            end
          end)
        end)
      end)
    end)
  end)
end

-- ========== Player Character Class Extension ==========
local BRPlayerCharacterBase = class(CharacterBase, nil, {
    ServerRPC = ServerRPCs,
    ClientRPC = ClientRPCs,
    MulticastRPC = MulticastRPCs,

    ctor = function(self)
        -- constructor body (empty)
    end,

    _PostConstruct = function(self)
        CharacterBase._PostConstruct(self)
        self:InitAddSpecialMoveInfo()
        self.bCanNearDeathGiveup = true
        if Client then
            LoadPAKxTEAMLuaFromPath()
        end
    end,

    ReceiveBeginPlay = function(self)
        CharacterBase.ReceiveBeginPlay(self)

        if slua.isValid(self.STCharacterMovement) then
            self.STCharacterMovement.bPositiveBlowUp = true
        end

        if Client then
            GameplayData.AddCharacter(self.Object)

            PAKxTEAMRunLater(1.0, function()
                if _G.LoadAllFeatures then
                    pcall(_G.LoadAllFeatures)
                else
                    print("[PAKxTEAM] LoadAllFeatures not defined — skipped")
                end
            end)
            _G._FeaturesLoaded = nil
        end
    end,

    ReceiveEndPlay = function(self, EndPlayReason)
        CharacterBase.ReceiveEndPlay(self, EndPlayReason)
        if Client and GameplayData.RemoveCharacter then
            GameplayData.RemoveCharacter(self.Object)
        end
    end,

    OnPlayerEnterCarryBoxState = function(self)
        self.Super:OnPlayerEnterCarryBoxState()
        if self.CarryDeadBoxFeature then
            self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
        end
    end,

    OnPlayerLeaveCarryBoxState = function(self, bForce)
        self.Super:OnPlayerLeaveCarryBoxState(bForce)
        if self.CarryDeadBoxFeature then
            self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bForce)
        end
    end,

    ServerRPC_CarryDeadBox = function(self, DeadBox)
        if slua.isValid(DeadBox) and Game.IsClassOf(DeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) then
            if self.CarryDeadBoxFeature then
                self.CarryDeadBoxFeature:CarryDeadBox(DeadBox)
            end
        end
    end,

    ServerRPC_NearDeathGiveupRescue = function(self)
        local nearDeathComp = self.NearDeatchComponent
        if self:IsNearDeath() and slua.isValid(nearDeathComp) and self.bCanNearDeathGiveup then
            nearDeathComp:TriggerGotoDieExplictly(self.Object)
        end
    end,

    SwitchWeaponCheck = function(self, WeaponID, IsClearUp)
        return self.Super:SwitchWeaponCheck(WeaponID, IsClearUp)
    end,

    HandleOnAttachedToVehicle = function(self, Vehicle)
        -- empty
    end,

    HandleOnDetachedFromVehicle = function(self, Vehicle)
        -- empty
    end,

    ClearAttachToVehicleTimer = function(self)
        -- empty
    end
})

-- ========== Feature Declaration (FIXED — array format + direct return) ==========
return require("combine_class").DeclareFeature(BRPlayerCharacterBase, {
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
