do

local __MasterAhsanEntryPCallOk, __MasterAhsanEntryPCallErr = pcall(function()

    local ScopePath, Existing = "master-file:Android/data/<package>/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/@PAKxTEAM.lua", _G.__MasterAhsanFileEntryBootstrap

    if type(Existing) == "table" and Existing.Version == 1 and Existing.Scope == ScopePath and type(Existing.Wake) == "function" then
        _G.MasterOfflineLoader = Existing
        Existing.Wake("entry")
        return
    end

    local Bootstrap = {
        Version = 1,
        Scope = ScopePath,
        Generation = (type(Existing) == "table" and tonumber(Existing.Generation) or 0) + 1,
        Epoch = 0,
        Checks = 0,
        Attempts = 0,
        Executions = 0,
        Active = false,
        Phase = "WaitingEntry",
        pending = false,
        loaded = false,
        HookAttempts = setmetatable({}, { __mode = "k" }),
    }

    _G.__MasterAhsanFileEntryBootstrap = Bootstrap
    _G.MasterOfflineLoader = Bootstrap

    local function IsCurrent()
        return _G.__MasterAhsanFileEntryBootstrap == Bootstrap
    end

    local function SafeIndex(obj, key)
        if obj == nil then return nil end
        local ok, val = pcall(function() return obj[key] end)
        if not ok then return nil end
        return val
    end

    local function Finalize(phase, err)
        Bootstrap.pending = false
        Bootstrap.Active = false
        if Bootstrap.Pending then Bootstrap.Pending.Used = true end
        Bootstrap.Pending = nil
        Bootstrap.error = err
        Bootstrap.LastError = err
        Bootstrap.Phase = phase
        Bootstrap.loaded = Bootstrap.Loaded == true
    end

    local function GetTicker()
        local ok, ticker = pcall(require, "common.time_ticker")
        if not ok then return nil end
        return SafeIndex(ticker, "AddTimerOnce")
    end

    local function IsSluaValid(obj)
        local isValid = SafeIndex(_G.slua, "isValid")
        if obj ~= nil and type(isValid) == "function" then
            local ok, res = pcall(isValid, obj)
            return ok and res == true
        end
        return false
    end

    local function IsReady()
        if not _G.Client then return false, "ClientNotReady" end
        if not GetTicker() then return false, "TickerUnavailable" end

        local ok, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or GameplayData == nil or GameplayData == false then
            return false, "GameplayDataUnavailable"
        end

        if type(SafeIndex(_G.slua, "isValid")) ~= "function" then
            return false, "SluaUnavailable"
        end

        local GetPlayerCharacter = SafeIndex(GameplayData, "GetPlayerCharacter")
        local GetPlayerController = SafeIndex(GameplayData, "GetPlayerController")

        if type(GetPlayerCharacter) ~= "function" or type(GetPlayerController) ~= "function" then
            return false, "PlayerAccessUnavailable"
        end

        local okC, char = pcall(GetPlayerCharacter)
        local okP, pc = pcall(GetPlayerController)

        if not okC or not IsSluaValid(char) then return false, "PlayerNotReady" end
        if not okP or not IsSluaValid(pc) then return false, "ControllerNotReady" end

        if type(SafeIndex(_G.CGame, "NewObjectFromPath")) ~= "function" then
            return false, "WidgetFactoryUnavailable"
        end

        if SafeIndex(_G.UEnums, "ESlateVisibility") == nil then
            return false, "VisibilityEnumUnavailable"
        end

        local okUI, InGameUITools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local GetMainControlBaseUI = okUI and SafeIndex(InGameUITools, "GetMainControlBaseUI") or nil

        if type(GetMainControlBaseUI) ~= "function" then
            return false, "InGameUIUnavailable"
        end

        local okM, mainUI = pcall(GetMainControlBaseUI)
        if not okM or not IsSluaValid(mainUI) then
            return false, "MainControlUnavailable"
        end

        if IsSluaValid(SafeIndex(mainUI, "CanvasPanel_0")) or IsSluaValid(SafeIndex(mainUI, "CanvasPanel_42")) then
            return true
        end

        return false, "CanvasUnavailable"
    end

    local function LoadFile()
        local open = SafeIndex(_G.io, "open")
        if type(open) ~= "function" then return nil, "FileIOUnavailable" end

        local ok, file, err = pcall(open, "/proc/self/cmdline", "rb")
        if not ok then return nil, "PackageReadError: " .. tostring(file) end
        if not file then return nil, "PackageReadError: " .. tostring(err) end

        local okRead, data = pcall(function() return file:read("*a") end)
        pcall(function() file:close() end)

        if not okRead then return nil, "PackageReadError: " .. tostring(data) end

        local pkg = nil
        if type(data) == "string" then pkg = data:match("^[^%z:]+") end

        if not (pkg and pkg:match("^[%w_]+%.[%w_%.]+$")) then
            return nil, "Package unavailable"
        end

        Bootstrap.Package = pkg
        Bootstrap.Path = "/storage/emulated/0/Android/data/" .. pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/@PAKxTEAM.lua"
        Bootstrap.path = Bootstrap.Path

        local loadfile = _G.loadfile
        if type(loadfile) ~= "function" then return nil, "LoadFileUnavailable" end

        local okL, chunk, loadErr = pcall(loadfile, Bootstrap.Path)
        if not okL then return nil, "FileLoadError: " .. tostring(chunk) end
        if type(chunk) == "function" then return chunk end

        return nil, "FileLoadError: " .. tostring(loadErr)
    end

    local function HookReadyEvents()
        local eventSystem = _G.EventSystem
        local register = SafeIndex(eventSystem, "registEvent")
        local eventType = _G.EVENTTYPE_INGAME
        local eventId = _G.EVENTID_INGAME_CONTROLLER_BEGINPLAY_FINISH

        if type(register) == "function" and eventType ~= nil and eventId ~= nil then
            if Bootstrap.HookAttempts[eventSystem] then return end
            Bootstrap.HookAttempts[eventSystem] = true

            local ok = pcall(register, eventSystem, eventType, eventId, function()
                if IsCurrent() then Bootstrap.Wake("controller_beginplay") end
            end)

            Bootstrap.HookPhase = ok and "Registered" or "RegistrationFailed"
            return
        end

        Bootstrap.HookPhase = "WaitingEventSystem"
    end

    local CheckNow

    local function ScheduleCheck(delay)
        if not (IsCurrent() and Bootstrap.Active and not Bootstrap.Pending) then return false end

        local tickerAdd = GetTicker()
        if not tickerAdd then
            Finalize("WaitingReadyEvent", "TickerUnavailable")
            return false
        end

        local token = { Epoch = Bootstrap.Epoch, Used = false }
        Bootstrap.Pending = token
        Bootstrap.ArmingTimer = true

        local ok, res = pcall(tickerAdd, delay, function()
            if token.Used or not IsCurrent() or token.Epoch ~= Bootstrap.Epoch or Bootstrap.Pending ~= token then return end

            token.Used = true
            Bootstrap.Pending = nil

            if Bootstrap.ArmingTimer then
                token.Synchronous = true
                return
            end

            if Bootstrap.Active then CheckNow(token.Epoch) end
        end)

        Bootstrap.ArmingTimer = false

        if token.Synchronous then
            Finalize("WaitingReadyEvent", "SynchronousTimerUnsupported")
            return false
        end

        if not ok or res == false then
            token.Used = true
            Finalize("WaitingReadyEvent", "TimerUnavailable")
            return false
        end

        return true
    end

    local function RetryLater(err)
        if not (IsCurrent() and Bootstrap.Active) then return end

        if err then
            Bootstrap.error = err
            Bootstrap.LastError = err
        end

        if Bootstrap.Checks >= 120 then
            Finalize("WaitingReadyEvent", err or "CheckBudgetExhausted")
        else
            ScheduleCheck(1.0)
        end
    end

    CheckNow = function(epoch)
        if not (IsCurrent() and Bootstrap.Active) then return end
        if epoch ~= Bootstrap.Epoch or Bootstrap.Checking or Bootstrap.Terminal then return end

        Bootstrap.Checking = true

        local ok, err = pcall(function()
            Bootstrap.Checks = Bootstrap.Checks + 1
            HookReadyEvents()

            local ready, reason = IsReady()
            if not ready then
                Bootstrap.Phase = "WaitingReadiness"
                RetryLater(reason)
                return
            end

            Bootstrap.Attempts = Bootstrap.Attempts + 1
            Bootstrap.error = nil
            Bootstrap.LastError = nil
            Bootstrap.Phase = "LoadingFile"

            local chunk, loadErr = LoadFile()
            if not IsCurrent() then return end

            if not chunk then
                Finalize("WaitingReadyEvent", loadErr)
                return
            end

            Bootstrap.Phase = "Executing"
            Bootstrap.Executions = Bootstrap.Executions + 1
            Bootstrap.Terminal = true

            local execOk, execErr = pcall(chunk)
            if not IsCurrent() then return end

            if execOk then
                Bootstrap.Loaded = true

                if _G.LunarOptionalStartupError == nil then
                    Finalize("Loaded", nil)
                else
                    Finalize("LoadedWithStartupError", tostring(_G.LunarOptionalStartupError))
                end

                return
            end

            Finalize("ExecutionError", tostring(execErr))
        end)

        Bootstrap.Checking = false

        if not ok and IsCurrent() then
            Finalize(Bootstrap.Terminal and "ExecutionError" or "WaitingReadyEvent", tostring(err))
        end
    end

    function Bootstrap.Wake(reason)
        if not (IsCurrent() and not Bootstrap.Waking and not Bootstrap.Terminal) then return end

        Bootstrap.Waking = true

        local ok, err = pcall(function()
            HookReadyEvents()

            if Bootstrap.Active or Bootstrap.Checking or Bootstrap.Terminal then return end

            Bootstrap.Epoch = Bootstrap.Epoch + 1
            Bootstrap.Checks = 0
            Bootstrap.error = nil
            Bootstrap.LastError = nil
            Bootstrap.Phase = "Scheduled"
            Bootstrap.WakeReason = reason
            Bootstrap.pending = true
            Bootstrap.Active = true

            ScheduleCheck(0.05)
        end)

        Bootstrap.Waking = false

        if not ok and IsCurrent() then
            Finalize("WaitingReadyEvent", tostring(err))
        end
    end

    Bootstrap.Wake("entry")

end)

if not __MasterAhsanEntryPCallOk then
    _G.__MasterAhsanOfflineInjectorError = tostring(__MasterAhsanEntryPCallErr)
end

end
