local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

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
