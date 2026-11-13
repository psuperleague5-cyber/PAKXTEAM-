-- ==============================================================================
-- 1.lua - REALZAYKO VIP (LIMPIO - SIN ESP V2)
-- ==============================================================================
-- Funcionalidades: Marca, Distancia (con colores), Contador (BOT/PLAYER mejorado),
-- ColorBody V2, Wallhack, Aimbot V2.
-- Corregido el problema de que wallhack/color dejen de funcionar al revivir.
-- ==============================================================================

local function Notify(msg)
    local s = "[REALZAYKO] " .. tostring(msg)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=0, G=1, B=0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print(s)
end

-- ==============================================================================
-- COLORES PARA DISTANCIA
-- ==============================================================================
local DIST_COLOR_RED = {R=255, G=0, B=0, A=255}       -- < 100m
local DIST_COLOR_YELLOW = {R=255, G=255, B=0, A=255}   -- 100-280m
local DIST_COLOR_GREEN = {R=0, G=255, B=0, A=255}      -- > 280m

-- ==============================================================================
-- CONFIGURACIÓN GLOBAL
-- ==============================================================================
_G.REALZAYKOConfig = _G.REALZAYKOConfig or {
    EspVip = false,
    EspDistance = false,
    Esp7_SoLuong = true,
    ColorBodyV2 = false,
    WallXuyenTuong = false,
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

_G.REALZAYKOState = _G.REALZAYKOState or {
    LoopToken = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    EnemyCounterWidget = nil,
    LastCounterUpdate = 0,
    LastAimTime = 0,
    CustomTextData = {
        AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1,
        AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
        AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1,
        AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
        AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1,
        AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300,
        AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2,
        AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400,
        AimTouchSniperPred = 0,
    },
}

-- ==============================================================================
-- BYPASS (SIMPLIFICADO)
-- ==============================================================================
local function nop() return true end
local function retTrue() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end

local function InitializeBypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.VerifyFileIntegrity = retTrue
        end
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            if Higgs.ControlMHActive then Higgs.ControlMHActive = nop end
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false end
        end
    end)
    Notify("Bypass activado")
end

-- ==============================================================================
-- HOOKS DE REPORTES (SIMPLIFICADOS)
-- ==============================================================================
local function InstallHooks()
    pcall(function()
        local GC = _G.GameplayCallbacks
        if GC and GC.OnDSPlayerStateChanged then
            local orig = GC.OnDSPlayerStateChanged
            GC.OnDSPlayerStateChanged = function(UID, state, ...)
                local blocked = { cheatdetected = true, violationdetected = true }
                if blocked[string.lower(tostring(state))] then
                    state = "Logout"
                end
                return orig(UID, state, ...)
            end
        end
        if GC and GC.SendTssSdkAntiDataToLobby then
            local orig = GC.SendTssSdkAntiDataToLobby
            GC.SendTssSdkAntiDataToLobby = function(...) return orig(..., "", 0, ...) end
        end
        if Client.GEMReportSubEvent then
            local orig = Client.GEMReportSubEvent
            Client.GEMReportSubEvent = function(hud, eventName, ...)
                local blocked = { PufferEvent = true, GRomeLinkEvent = true, NetProxyEvent = true }
                if blocked[eventName] then return end
                return orig(hud, eventName, ...)
            end
        end
        Notify("Hooks instalados")
    end)
end

-- ==============================================================================
-- UTILIDADES
-- ==============================================================================
local function Valid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

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

local function GetEnemyTargetsFromActors(radius)
    local result = {}
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
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

-- ==============================================================================
-- CONFIGURACIÓN Y MENÚ
-- ==============================================================================
local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    return paths
end

local ConfigFileName = "REALZAYKO_settings.txt"
_G.LastConfigSaveStr = ""

_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nREALZAYKOConfig = {\n"
        for k, v in pairs(_G.REALZAYKOConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.REALZAYKOState and _G.REALZAYKOState.CustomTextData then
            for k, v in pairs(_G.REALZAYKOState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
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
                    if savedData.REALZAYKOConfig then
                        for k, v in pairs(savedData.REALZAYKOConfig) do
                            _G.REALZAYKOConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.REALZAYKOState.CustomTextData = _G.REALZAYKOState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.REALZAYKOState.CustomTextData[k] = v
                        end
                    end
                end
            end
        end
        _G.SaveModSettings()
    end)
end

_G.LoadModSettings()
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

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    if SettingPageDefine.ModMenu then return end

    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    local StackESP = {
        { Key = "ESP1", UI = AliasMap.Switcher, Text = "Marca de enemigo (RedBox)", GetFunc = function() return _G.REALZAYKOConfig.EspVip end, SetFunc = function(_,v) _G.REALZAYKOConfig.EspVip = v return true end },
        { Key = "ESP2", UI = AliasMap.Switcher, Text = "Distancia en metros", GetFunc = function() return _G.REALZAYKOConfig.EspDistance end, SetFunc = function(_,v) _G.REALZAYKOConfig.EspDistance = v return true end },
        { Key = "ESP7_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Contador de enemigos (Widget)", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.Esp7_SoLuong end, SetFunc = function(_,v) _G.REALZAYKOConfig.Esp7_SoLuong = v return true end },
        { Key = "ESP7_SoLuong", UI = AliasMap.Switcher, Text = "   Mostrar contador BOT / PLAYER", ExpandHandle = "ESP7_Ex", GetFunc = function() return _G.REALZAYKOConfig.Esp7_SoLuong end, SetFunc = function(_,v) _G.REALZAYKOConfig.Esp7_SoLuong = v return true end },
        { Key = "ColorBodyV2", UI = AliasMap.Switcher, Text = "Color V2 (Rojo/Verde)", GetFunc = function() return _G.REALZAYKOConfig.ColorBodyV2 end, SetFunc = function(_,v) _G.REALZAYKOConfig.ColorBodyV2 = v return true end },
        { Key = "WallXuyenTuong", UI = AliasMap.Switcher, Text = "Wallhack solo (sin color)", GetFunc = function() return _G.REALZAYKOConfig.WallXuyenTuong end, SetFunc = function(_,v) _G.REALZAYKOConfig.WallXuyenTuong = v return true end },
    }

    local StackAimbotV2 = {
        { Key = "AT_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Activar AimTouch", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.AimTouchEnable end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchEnable = v return true end },
        -- Hipfire
        { Key = "AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Hipfire", ExpandHandle = "AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.AimTouchHipfire end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchHipfire = v return true end },
        { Key = "AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = "      Ignorar knock", ExpandHandle = "AT_Hip_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchHipIgKnock end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchHipIgKnock = v return true end },
        { Key = "AT_Hip_IgBot", UI = AliasMap.Switcher, Text = "      Ignorar bots", ExpandHandle = "AT_Hip_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchHipIgBot end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchHipIgBot = v return true end },
        { Key = "AT_Hip_Vis", UI = AliasMap.Switcher, Text = "      Check línea de visión", ExpandHandle = "AT_Hip_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchHipVisCheck end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchHipVisCheck = v return true end },
        { Key = "AT_Hip_Prio", UI = AliasMap.Slider, Text = "      Prioridad (1:Cruz 2:Dist 3:HP)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchHipPrio = val return true end },
        { Key = "AT_Hip_Bone", UI = AliasMap.Slider, Text = "      Hueso (1:Cabeza 2:Pecho 3:Estómago 4:Cadera)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchHipBone = val return true end },
        { Key = "AT_Hip_Cond", UI = AliasMap.Slider, Text = "      Disparo (1:Solo al disparar, 2:Siempre)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>2 then val=2 end; _G.REALZAYKOState.CustomTextData.AimTouchHipCond = val return true end },
        { Key = "AT_Hip_Spd", UI = AliasMap.Slider, Text = "      Velocidad (1-100)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchHipSpeed = v return true end },
        { Key = "AT_Hip_FOV", UI = AliasMap.Slider, Text = "      FOV (1-100)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchHipFOV = v return true end },
        { Key = "AT_Hip_Dist", UI = AliasMap.Slider, Text = "      Distancia (1-500m)", ExpandHandle = "AT_Hip_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return math.floor((_G.REALZAYKOState.CustomTextData.AimTouchHipDist or 250)/5) end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchHipDist = v*5 return true end },
        -- Shotgun
        { Key = "AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Shotgun", ExpandHandle = "AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.AimTouchSG end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSG = v return true end },
        { Key = "AT_SG_Auto", UI = AliasMap.Switcher, Text = "      Disparo automático", ExpandHandle = "AT_SG_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSGAutoFire end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSGAutoFire = v return true end },
        { Key = "AT_SG_IgKnock", UI = AliasMap.Switcher, Text = "      Ignorar knock", ExpandHandle = "AT_SG_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSGIgKnock end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSGIgKnock = v return true end },
        { Key = "AT_SG_IgBot", UI = AliasMap.Switcher, Text = "      Ignorar bots", ExpandHandle = "AT_SG_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSGIgBot end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSGIgBot = v return true end },
        { Key = "AT_SG_Vis", UI = AliasMap.Switcher, Text = "      Check línea de visión", ExpandHandle = "AT_SG_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSGVisCheck end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSGVisCheck = v return true end },
        { Key = "AT_SG_Prio", UI = AliasMap.Slider, Text = "      Prioridad", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchSGPrio = val return true end },
        { Key = "AT_SG_Bone", UI = AliasMap.Slider, Text = "      Hueso", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchSGBone = val return true end },
        { Key = "AT_SG_Cond", UI = AliasMap.Slider, Text = "      Disparo", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>2 then val=2 end; _G.REALZAYKOState.CustomTextData.AimTouchSGCond = val return true end },
        { Key = "AT_SG_Spd", UI = AliasMap.Slider, Text = "      Velocidad", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSGSpeed = v return true end },
        { Key = "AT_SG_FOV", UI = AliasMap.Slider, Text = "      FOV", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSGFOV = v return true end },
        { Key = "AT_SG_Dist", UI = AliasMap.Slider, Text = "      Distancia", ExpandHandle = "AT_SG_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSGDist = v return true end },
        -- Scope
        { Key = "AT_Scope_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Scope (AR/SMG)", ExpandHandle = "AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.AimTouchScopeAll end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchScopeAll = v return true end },
        { Key = "AT_Scope_IgKnock", UI = AliasMap.Switcher, Text = "      Ignorar knock", ExpandHandle = "AT_Scope_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchScopeIgKnock end, SetFunc = function(_,v) _REALZAYKOenConfig.AimTouchScopeIgKnock = v return true end },
        { Key = "AT_Scope_IgBot", UI = AliasMap.Switcher, Text = "      Ignorar bots", ExpandHandle = "AT_Scope_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchScopeIgBot end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchScopeIgBot = v return true end },
        { Key = "AT_Scope_Vis", UI = AliasMap.Switcher, Text = "      Check línea de visión", ExpandHandle = "AT_Scope_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchScopeVisCheck end, SetFunc = function(_,v) _G.REALZAYKOREALZAYKOConfig.AimTouchScopeVisCheck = v return true end },
        { Key = "AT_Scope_Prio", UI = AliasMap.Slider, Text = "      Prioridad", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchScopePrio = val return true end },
        { Key = "AT_Scope_Bone", UI = AliasMap.Slider, Text = "      Hueso", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchScopeBone = val return true end },
        { Key = "AT_Scope_Cond", UI = AliasMap.Slider, Text = "      Disparo", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>2 then val=2 end; _G.REALZAYKOState.CustomTextData.AimTouchScopeCond = val return true end },
        { Key = "AT_Scope_Spd", UI = AliasMap.Slider, Text = "      Velocidad", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchScopeSpeed = v return true end },
        { Key = "AT_Scope_FOV", UI = AliasMap.Slider, Text = "      FOV", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchScopeFOV = v return true end },
        { Key = "AT_Scope_Dist", UI = AliasMap.Slider, Text = "      Distancia", ExpandHandle = "AT_Scope_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return math.floor((_G.REALZAYKOState.CustomTextData.AimTouchScopeDist or 300)/5) end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchScopeDist = v*5 return true end },
        { Key = "AT_Scope_Pred", UI = AliasMap.Slider, Text = "      Predicción", ExpandHandle = "AT_Scope_Ex", MinValue = 0, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchScopePred = v return true end },
        { Key = "AT_Scope_Recoil", UI = AliasMap.Slider, Text = "      Compensación retroceso", ExpandHandle = "AT_Scope_Ex", MinValue = 0, MaxValue = 50, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchScopeRecoil = v return true end },
        -- Sniper
        { Key = "AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Sniper", ExpandHandle = "AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.REALZAYKOConfig.AimTouchScopeSniper end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchScopeSniper = v return true end },
        { Key = "AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = "      Ignorar knock", ExpandHandle = "AT_Sniper_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSniperIgKnock end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSniperIgKnock = v return true end },
        { Key = "AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = "      Ignorar bots", ExpandHandle = "AT_Sniper_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSniperIgBot end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSniperIgBot = v return true end },
        { Key = "AT_Sniper_Vis", UI = AliasMap.Switcher, Text = "      Check línea de visión", ExpandHandle = "AT_Sniper_Ex", GetFunc = function() return _G.REALZAYKOConfig.AimTouchSniperVisCheck end, SetFunc = function(_,v) _G.REALZAYKOConfig.AimTouchSniperVisCheck = v return true end },
        { Key = "AT_Sniper_Prio", UI = AliasMap.Slider, Text = "      Prioridad", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchSniperPrio = val return true end },
        { Key = "AT_Sniper_Bone", UI = AliasMap.Slider, Text = "      Hueso", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>4 then val=4 end; _G.REALZAYKOState.CustomTextData.AimTouchSniperBone = val return true end },
        { Key = "AT_Sniper_Cond", UI = AliasMap.Slider, Text = "      Disparo", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(_,v) local val = math.floor(v+0.5); if val<1 then val=1 end; if val>2 then val=2 end; _G.REALZAYKOState.CustomTextData.AimTouchSniperCond = val return true end },
        { Key = "AT_Sniper_Spd", UI = AliasMap.Slider, Text = "      Velocidad", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSniperSpeed = v return true end },
        { Key = "AT_Sniper_FOV", UI = AliasMap.Slider, Text = "      FOV", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSniperFOV = v return true end },
        { Key = "AT_Sniper_Dist", UI = AliasMap.Slider, Text = "      Distancia", ExpandHandle = "AT_Sniper_Ex", MinValue = 1, MaxValue = 100, GetFunc = function() return math.floor((_G.REALZAYKOState.CustomTextData.AimTouchSniperDist or 400)/5) end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSniperDist = v*5 return true end },
        { Key = "AT_Sniper_Pred", UI = AliasMap.Slider, Text = "      Predicción", ExpandHandle = "AT_Sniper_Ex", MinValue = 0, MaxValue = 100, GetFunc = function() return _G.REALZAYKOState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(_,v) _G.REALZAYKOState.CustomTextData.AimTouchSniperPred = v return true end },
    }

    SettingPageDefine.ModMenu = {
        Key = "ModMenu",
        Text = "REALZAYKO VIP (LIMPIO)",
        UIKey = "Setting_Page_Privacy",
        Category = {
            { Key = "Cat_ESP", Text = "VISUALES (ESP)", Stack = StackESP },
            { Key = "Cat_AimbotV2", Text = "AIMBOT V2", Stack = StackAimbotV2 },
        }
    }

    table.insert(SettingCatalog, 1, SettingPageDefine.ModMenu)

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName and string.find(string.lower(config.keyName), "setting_main") then
                local catalog = args[1]
                if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                    local has = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then has = true break end
                    end
                    if not has then table.insert(catalog, 1, SettingPageDefine.ModMenu) end
                end
            end
            return old_ShowUI(config, table.unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ==============================================================================
-- WIDGET CONTADOR (con detección mejorada de BOTs)
-- ==============================================================================
local BTN_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local RADIUS_METERS = 350

local function CreateEnemyCounterWidget()
    if _G.REALZAYKOState.EnemyCounterWidget then
        if slua.isValid(_G.REALZAYKOState.EnemyCounterWidget) then return _G.REALZAYKOState.EnemyCounterWidget end
        _G.REALZAYKOState.EnemyCounterWidget = nil
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
        _G.REALZAYKOState.EnemyCounterWidget = btn
    end)
    return _G.REALZAYKOState.EnemyCounterWidget
end

-- ==============================================================================
-- VERSIÓN MEJORADA DEL CONTADOR (detecta bots correctamente)
-- ==============================================================================
local function UpdateEnemyCounter()
    if not _G.REALZAYKOConfig.Esp7_SoLuong then
        if _G.REALZAYKOState.EnemyCounterWidget and slua.isValid(_G.REALZAYKOState.EnemyCounterWidget) then
            _G.REALZAYKOState.EnemyCounterWidget:RemoveFromParent()
            _G.REALZAYKOState.EnemyCounterWidget = nil
        end
        return
    end
    local now = os.clock()
    if now - _G.REALZAYKOState.LastCounterUpdate < 0.3 then return end
    _G.REALZAYKOState.LastCounterUpdate = now
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then
            if _G.REALZAYKOState.EnemyCounterWidget and slua.isValid(_G.REALZAYKOState.EnemyCounterWidget) then
                _G.REALZAYKOState.EnemyCounterWidget:RemoveFromParent()
                _G.REALZAYKOState.EnemyCounterWidget = nil
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
                        -- ====================================================
                        -- DETECCIÓN MEJORADA DE BOTS
                        -- ====================================================
                        local isBot = false

                        -- 1. Bandera bIsAI / IsAI
                        if tPawn.bIsAI == true or tPawn.IsAI == true then
                            isBot = true
                        end

                        -- 2. PlayerState
                        if not isBot then
                            local pState = tPawn.PlayerState
                            if slua.isValid(pState) then
                                if pState.bIsABot == true or pState.bIsBot == true then
                                    isBot = true
                                end
                                if not isBot and type(pState.IsBot) == "function" and pState:IsBot() then
                                    isBot = true
                                end
                            end
                        end

                        -- 3. Nombre (método más fiable)
                        if not isBot then
                            local name = tPawn.PlayerName or (type(tPawn.GetPlayerName) == "function" and tPawn:GetPlayerName()) or ""
                            if name and name ~= "" then
                                local lowerName = string.lower(name)
                                -- Patrones típicos de bots
                                if lowerName:find("cobra") or lowerName:find("target") or lowerName:find("bot_") or lowerName:find("b_") then
                                    isBot = true
                                elseif string.len(name) <= 2 and (name:match("^%a+$")) then
                                    -- Nombres muy cortos (ej: "AI", "B1", "X") suelen ser bots
                                    isBot = true
                                elseif name:find("Player") or name:find("Enemy") or name:find("Spectator") then
                                    isBot = true
                                end
                            else
                                -- Si no tiene nombre, es casi seguro un bot
                                isBot = true
                            end
                        end

                        -- 4. Si el equipo es 0 y el nombre es genérico, es bot
                        if not isBot and team == 0 then
                            local name = tPawn.PlayerName or ""
                            if name == "" or name == "Player" or name == "Enemy" then
                                isBot = true
                            end
                        end

                        -- ====================================================
                        if isBot then
                            botCount = botCount + 1
                        else
                            playerCount = playerCount + 1
                        end
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

-- ==============================================================================
-- COLOR BODY V2
-- ==============================================================================
local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                        if not _G.REALZAYKOConfig.WallXuyenTuong then
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
            if _G.REALZAYKOConfig.WallXuyenTuong then
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

-- ==============================================================================
-- WALLHACK
-- ==============================================================================
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

-- ==============================================================================
-- MARCA (RedBox)
-- ==============================================================================
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.REALZAYKOState.TrackedMarks[mark] = true end
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
    _G.REALZAYKOState.TrackedMarks[mark] = nil
end

-- ==============================================================================
-- ESP LOOP PRINCIPAL (con limpieza de caché al morir/revivir)
-- ==============================================================================
local function ESPLoop()
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local pc = GameplayData.GetPlayerController()
    if not Valid(pc) then return end
    local localPlayer = pc:GetPlayerCharacterSafety()
    if not Valid(localPlayer) then return end
    local MyHUD = pc.MyHUD
    if not Valid(MyHUD) then return end

    UpdateEnemyCounter()

    -- Distancia (con colores)
    if _G.REALZAYKOConfig.EspDistance then
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
                        if distM < 100 then
                            distColor = DIST_COLOR_RED
                        elseif distM <= 280 then
                            distColor = DIST_COLOR_YELLOW
                        else
                            distColor = DIST_COLOR_GREEN
                        end
                        MyHUD:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06,
                            {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20},
                            distColor, true, false, true, nil, dynamicScale * 1.5, true)
                    end
                end
            end
        end
    end

    -- Marca, Color V2, Wallhack
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters() end
    local enemyMarks = _G.REALZAYKOState.EnemyMarks or {}
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

            -- Color V2
            if _G.REALZAYKOConfig.ColorBodyV2 then
                if distM <= 400 then
                    ApplyColorBodyV2(enemy, pc, markData)
                else
                    UndoColorBodyV2(enemy, markData)
                end
            else
                UndoColorBodyV2(enemy, markData)
            end

            -- Wallhack
            if _G.REALZAYKOConfig.WallXuyenTuong then
                if distM <= 400 then
                    ApplyWallXuyenTuong(enemy, markData)
                else
                    UndoWallXuyenTuong(enemy, markData)
                end
            else
                UndoWallXuyenTuong(enemy, markData)
            end

            -- Marca
            if _G.REALZAYKOConfig.EspVip then
                if distM <= 400 then
                    if markData.hpMark == nil then
                        markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                    end
                else
                    if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                end
            else
                if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
            end

            ::continue_enemy::
        end
    end

    -- Limpiar enemigos que ya no existen
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
    _G.REALZAYKOState.EnemyMarks = enemyMarks
end

-- ==============================================================================
-- LIMPIEZA AL FINALIZAR PARTIDA
-- ==============================================================================
local function CleanUpOnGameEnd()
    pcall(function()
        for mark, _ in pairs(_G.REALZAYKOState.TrackedMarks) do
            SafeRemoveMark(mark)
        end
        _G.REALZAYKOState.TrackedMarks = {}
        for key, data in pairs(_G.REALZAYKOState.EnemyMarks) do
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
        _G.REALZAYKOState.EnemyMarks = {}
        if _G.REALZAYKOState.EnemyCounterWidget and slua.isValid(_G.REALZAYKOState.EnemyCounterWidget) then
            _G.REALZAYKOState.EnemyCounterWidget:RemoveFromParent()
            _G.REALZAYKOState.EnemyCounterWidget = nil
        end
        Notify("Caché limpiado")
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

-- ==============================================================================
-- AIMBOT V2 (AimTouch) - COMPLETO
-- ==============================================================================
_G.AimTouch = function()
    pcall(function()
        if not _G.REALZAYKOConfig.AimTouchEnable then return end
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        if not isFiring and not isADS then return end

        local now = os.clock()
        if _G.REALZAYKOState.LastAimTime and (now - _G.REALZAYKOState.LastAimTime) < 0.05 then return end
        _G.REALZAYKOState.LastAimTime = now

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
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                isShotgun = true
            end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end
            if type(weapon.GetCurrentAmmo) == "function" then currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then currentAmmo = weapon.CurrentAmmo end
        end

        if _G.REALZAYKOState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.REALZAYKOState.IsAutoFiring = false
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

        if isShotgun and _G.REALZAYKOConfig.AimTouchSG then
            cond = _G.REALZAYKOState.CustomTextData.AimTouchSGCond or 1
            if _G.REALZAYKOConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.REALZAYKOState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.REALZAYKOState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.REALZAYKOState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.REALZAYKOState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.REALZAYKOState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.REALZAYKOConfig.AimTouchSGVisCheck
            igKnock = _G.REALZAYKOConfig.AimTouchSGIgKnock
            igBot = _G.REALZAYKOConfig.AimTouchSGIgBot
        elseif isADS then
            if isSniper and _G.REALZAYKOConfig.AimTouchScopeSniper then
                cond = _G.REALZAYKOState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.REALZAYKOState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.REALZAYKOState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.REALZAYKOState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.REALZAYKOState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.REALZAYKOState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.REALZAYKOConfig.AimTouchSniperVisCheck
                igKnock = _G.REALZAYKOConfig.AimTouchSniperIgKnock
                igBot = _G.REALZAYKOConfig.AimTouchSniperIgBot
                predVal = _G.REALZAYKOState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.REALZAYKOConfig.AimTouchScopeAll then
                cond = _G.REALZAYKOState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.REALZAYKOState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.REALZAYKOState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.REALZAYKOState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.REALZAYKOState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.REALZAYKOState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.REALZAYKOConfig.AimTouchScopeVisCheck
                igKnock = _G.REALZAYKOConfig.AimTouchScopeIgKnock
                igBot = _G.REALZAYKOConfig.AimTouchScopeIgBot
                predVal = _G.REALZAYKOState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.REALZAYKOState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.REALZAYKOConfig.AimTouchHipfire then return end
            cond = _G.REALZAYKOState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.REALZAYKOState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.REALZAYKOState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.REALZAYKOState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.REALZAYKOState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.REALZAYKOState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.REALZAYKOConfig.AimTouchHipVisCheck
            igKnock = _G.REALZAYKOConfig.AimTouchHipIgKnock
            igBot = _G.REALZAYKOConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100
        local enemies = GetEnemyTargetsFromActors(currentMaxDist)
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
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end

            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.REALZAYKOState.AimTouchVisCache = _G.REALZAYKOState.AimTouchVisCache or {}
                if not _G.REALZAYKOState.AimTouchVisCache[tId] or (curTime - _G.REALZAYKOState.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.REALZAYKOState.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.REALZAYKOState.AimTouchVisCache[tId].hidden then goto continue end
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

        if isShotgun and _G.REALZAYKOConfig.AimTouchSGAutoFire then
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
                    _G.REALZAYKOState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ==============================================================================
-- BUCLE PRINCIPAL
-- ==============================================================================
_G.REALZAYKOState.LoopToken = (_G.REALZAYKOState.LoopToken or 0) + 1
local myToken = _G.REALZAYKOState.LoopToken

local function MainLoop()
    if myToken ~= _G.REALZAYKOState.LoopToken then return end
    pcall(function()
        ESPLoop()
        if _G.REALZAYKOConfig.AimTouchEnable then
            _G.AimTouch()
        end
    end)
end

local function FastTick()
    if myToken ~= _G.REALZAYKOState.LoopToken then return end
    pcall(MainLoop)
    local ok, ticker = pcall(require, "common.time_ticker")
    if ok and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.05, FastTick)
    end
end

-- ==============================================================================
-- INICIALIZACIÓN
-- ==============================================================================
local function Init()
    InitializeBypass()
    InstallHooks()
    _G.InitModMenuTab()
    FastTick()
    Notify("REALZAYKO VIP Mod cargado (versión estable sin ESP V2).")
end

local ok, ticker = pcall(require, "common.time_ticker")
if ok and ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(0.5, Init)
else
    local function manualStart()
        local start = os.clock()
        while os.clock() - start < 0.5 do end
        Init()
    end
    pcall(manualStart)
end

Notify("REALZAYKO VIP Mod listo. Revisa Ajustes.")
