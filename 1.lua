do
    if _G.__AIMBOT_SDAT_LOADED then return end
    _G.__AIMBOT_SDAT_LOADED = true

    -- ============================================================
    -- 1. CONFIG + STATE
    -- ============================================================
    if not _G.XTEAMConfig then _G.XTEAMConfig = {} end
    if not _G.XTEAMState then _G.XTEAMState = {} end
    if not _G.XTEAMState.CustomTextData then _G.XTEAMState.CustomTextData = {} end

    if _G.XTEAMConfig.AutoHead == nil then _G.XTEAMConfig.AutoHead = false end
    if _G.XTEAMConfig.CustomAimbot == nil then _G.XTEAMConfig.CustomAimbot = false end
    if _G.XTEAMConfig.CustomAimbotClose == nil then _G.XTEAMConfig.CustomAimbotClose = false end
    if _G.XTEAMState.CustomTextData.OuterSpeed == nil then _G.XTEAMState.CustomTextData.OuterSpeed = 5.6 end
    if _G.XTEAMState.CustomTextData.InnerSpeed == nil then _G.XTEAMState.CustomTextData.InnerSpeed = 5.6 end
    if _G.XTEAMState.IsAutoFiring == nil then _G.XTEAMState.IsAutoFiring = false end
    if _G.XTEAMState.AimbotLoopToken == nil then _G.XTEAMState.AimbotLoopToken = 0 end
    if _G.XTEAMState.OrigAutoAimCompCached == nil then _G.XTEAMState.OrigAutoAimCompCached = nil end
    if _G.XTEAMState.Profile == nil then _G.XTEAMState.Profile = "Low" end
    if _G.XTEAMState.AutoProfile == nil then _G.XTEAMState.AutoProfile = true end
    if _G.XTEAMState.ManualLevel == nil then _G.XTEAMState.ManualLevel = 0 end
    if _G.XTEAMState.WarnedTweak == nil then _G.XTEAMState.WarnedTweak = false end

    if not _G.XTEAMConfig.AimModes then
        _G.XTEAMConfig.AimModes = {
            Hipfire = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=3, Condition=1, Speed=50, FOV=21, MaxDist=250 },
            Shotgun = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=1, Condition=2, Speed=25, FOV=15, MaxDist=30 },
            Scope   = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=3, Condition=1, Speed=55, FOV=20, MaxDist=300 },
            Sniper  = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=1, Condition=2, Speed=60, FOV=20, MaxDist=400 },
        }
    end
    _G.XTEAMConfig.AimTouchEnable = true

    -- ============================================================
    -- 2. PROFILES + LEVEL DETECTION
    -- ============================================================
    local HumanAimProfiles = {
        Low = {
            FOV = 12, Speed = 30, Bone = 3, Priority = 1, MaxDist = 150,
            VisCheck = true, IgBot = false, IgKnock = true, Condition = 1,
        },
        Medium = {
            FOV = 18, Speed = 50, Bone = 1, Priority = 1, MaxDist = 250,
            VisCheck = true, IgBot = false, IgKnock = true, Condition = 1,
        },
        Pro = {
            FOV = 25, Speed = 70, Bone = 1, Priority = 1, MaxDist = 350,
            VisCheck = true, IgBot = true, IgKnock = true, Condition = 2,
        },
    }
    _G.HumanAimProfiles = HumanAimProfiles

    local function getAccountLevel()
        local level = 0
        local function pick(v)
            if type(v) == "number" and v > 0 and v < 200 then level = v return true end
            if type(v) == "string" then
                local n = tonumber(v:match("%d+"))
                if n and n > 0 and n < 200 then level = n return true end
            end
            return false
        end
        pcall(function()
            local GDP = require("GameLua.GameCore.Data.GameplayData")
            if not GDP then return end

            if GDP.GetPlayerLevel and pick(GDP.GetPlayerLevel()) then return end

            local okGS, GS = pcall(require, "client.common.game_status")
            if okGS and GS and GS.GetPlayerLevel and pick(GS.GetPlayerLevel()) then return end

            local ps = nil
            if GDP.GetMyPlayerState then ps = GDP.GetMyPlayerState() end
            if not (slua and slua.isValid and slua.isValid(ps)) and GDP.GetPlayerCharacter then
                local c = GDP.GetPlayerCharacter()
                if slua and slua.isValid and slua.isValid(c) then ps = c.PlayerState end
            end
            if slua and slua.isValid and slua.isValid(ps) then
                if pick(ps.PlayerLevel) then return end
                if pick(ps.PlayerLevelDisplay) then return end
                if pick(ps.Level) then return end
                if pick(ps.UserLevel) then return end
            end

            if slua_GameFrontendHUD then
                if slua_GameFrontendHUD.GetPlayerLevel and pick(slua_GameFrontendHUD:GetPlayerLevel()) then return end
                local pc = slua_GameFrontendHUD:GetPlayerController()
                if slua and slua.isValid and slua.isValid(pc) then
                    if pick(pc.PlayerLevel) then return end
                    local ps2 = pc.PlayerState
                    if slua and slua.isValid and slua.isValid(ps2) then
                        if pick(ps2.PlayerLevel) then return end
                        if pick(ps2.Level) then return end
                    end
                end
            end

            local okPI, PI = pcall(require, "client.common.player_info")
            if okPI and PI and PI.GetPlayerLevel and pick(PI.GetPlayerLevel()) then return end
        end)
        return level
    end
    _G.GetAccountLevel = getAccountLevel

    local function getEffectiveLevel()
        if _G.XTEAMState.ManualLevel and _G.XTEAMState.ManualLevel > 0 then
            return _G.XTEAMState.ManualLevel, true
        end
        return getAccountLevel(), false
    end
    _G.GetEffectiveLevel = getEffectiveLevel

    local function getRecommendedProfile(level)
        if level >= 60 then return "Pro"
        elseif level >= 30 then return "Medium"
        else return "Low" end
    end
    _G.GetRecommendedProfile = getRecommendedProfile

    local function applyProfile(name)
        local p = HumanAimProfiles[name]
        if not p then return end
        for _, modeCfg in pairs(_G.XTEAMConfig.AimModes) do
            modeCfg.FOV = p.FOV
            modeCfg.Speed = p.Speed
            modeCfg.Bone = p.Bone
            modeCfg.Priority = p.Priority
            modeCfg.VisCheck = p.VisCheck
            modeCfg.IgBot = p.IgBot
            modeCfg.IgKnock = p.IgKnock
            modeCfg.Condition = p.Condition
            modeCfg.MaxDist = p.MaxDist or modeCfg.MaxDist or 250
        end
        _G.XTEAMState.Profile = name
    end
    _G.ApplyAimProfile = applyProfile

    -- ═══ Profile persistence ═══
    local PROFILE_FILES = {
        "/storage/emulated/0/Android/data/com.tencent.ig/files/_s.profile",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/_s.profile",
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/_s.profile",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/_s.profile",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/_s.profile",
    }
    local function saveProfile()
        pcall(function()
            local data = tostring(_G.XTEAMState.Profile or "Low") .. "|"
                .. tostring(_G.XTEAMState.AutoProfile and 1 or 0) .. "|"
                .. tostring(_G.XTEAMState.ManualLevel or 0)
            for _, p in ipairs(PROFILE_FILES) do
                local f = io.open(p, "w")
                if f then f:write(data) f:close() break end
            end
        end)
    end
    local function loadProfile()
        pcall(function()
            for _, p in ipairs(PROFILE_FILES) do
                local f = io.open(p, "r")
                if f then
                    local data = f:read("*a")
                    f:close()
                    local name, auto, manual = data:match("^(%a+)|(%d)|(%d+)")
                    if name and HumanAimProfiles[name] then
                        _G.XTEAMState.Profile = name
                        _G.XTEAMState.AutoProfile = (auto == "1")
                        _G.XTEAMState.ManualLevel = tonumber(manual) or 0
                    end
                    break
                end
            end
        end)
    end
    loadProfile()
    _G.SaveAimProfile = saveProfile

    -- ═══ Auto-apply on load ═══
    pcall(function()
        if _G.XTEAMState.AutoProfile then
            local lvl = getEffectiveLevel()
            local rec = getRecommendedProfile(lvl)
            applyProfile(rec)
        else
            applyProfile(_G.XTEAMState.Profile or "Low")
        end
    end)

    -- ============================================================
    -- 3. AIMBOT ENGINE
    -- ============================================================
    if not _G.__AIMBOT_INSTALLED then
        _G.__AIMBOT_INSTALLED = true

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
                    local actorTeam = actor.TeamID or (type(actor.GetTeamID) == "function" and actor:GetTeamID()) or 0
                    if actorTeam == myTeam then goto continue end
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

        _G.AimTouch = function()
            pcall(function()
                -- 🛑 LEVEL LOCK ENGINE 🛑
                local currentLvl = getEffectiveLevel()
                if currentLvl <= 0 then return end

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
                local isShotgun, isSniper, currentAmmo = false, false, 1
                if slua.isValid(weapon) then
                    local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
                    local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
                    if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then isShotgun = true end
                    if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then isSniper = true end
                    if type(weapon.GetCurrentAmmo) == "function" then currentAmmo = weapon:GetCurrentAmmo()
                    elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
                    elseif weapon.CurrentAmmo ~= nil then currentAmmo = weapon.CurrentAmmo end
                end
                local modeKey
                if isShotgun then modeKey = "Shotgun"
                elseif isADS and isSniper then modeKey = "Sniper"
                elseif isADS then modeKey = "Scope"
                else modeKey = "Hipfire" end
                local cfg = _G.XTEAMConfig.AimModes and _G.XTEAMConfig.AimModes[modeKey]
                if not cfg or cfg.Enable ~= true then return end
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
                local cond = cfg.Condition or 2
                local prioMode = cfg.Priority or 1
                local boneIdx = cfg.Bone or 1
                local speedVal = cfg.Speed or 85
                local fovVal = cfg.FOV or 28
                local useVisCheck = cfg.VisCheck == true
                local igKnock = cfg.IgKnock == true
                local igBot = cfg.IgBot == true
                local maxDistMeters
                if isShotgun then maxDistMeters = cfg.MaxDist or 30
                elseif isADS and isSniper then maxDistMeters = cfg.MaxDist or 400
                elseif isADS then maxDistMeters = cfg.MaxDist or 300
                else maxDistMeters = cfg.MaxDist or 250 end
                local predVal = 0
                local recoilCompVal = 0
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

        local function AimbotWeaponPatch()
            pcall(function()
                local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                local localPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
                if not slua.isValid(localPlayer) then return end
                local weapon = nil
                pcall(function()
                    local weaponManager = localPlayer.WeaponManagerComponent
                    if slua.isValid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then
                        weapon = weaponManager:GetCurrentWeapon()
                    end
                end)
                if not slua.isValid(weapon) then
                    if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
                    elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
                end
                if not slua.isValid(weapon) then return end
                local entities = {}
                if slua.isValid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
                if slua.isValid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
                if slua.isValid(weapon.ShootWeaponComponent) and slua.isValid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then
                    table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
                end
                for _, entity in ipairs(entities) do
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
                end
            end)
        end

        local function AimbotAutoAimCompPatch()
            pcall(function()
                local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                local localPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
                if not slua.isValid(localPlayer) then return end
                local autoComp = localPlayer.AutoAimComp
                if not slua.isValid(autoComp) then return end
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
                    if orig then
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
        end

        local function FastAimbotTick()
            pcall(function()
                if _G.XTEAMConfig.AimTouchEnable then _G.AimTouch() end
            end)
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(0.016, FastAimbotTick)
            end
        end

        local function AimbotWeaponPatchTick()
            pcall(AimbotWeaponPatch)
            pcall(AimbotAutoAimCompPatch)
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(0.5, AimbotWeaponPatchTick)
            end
        end

        _G.__AimbotStart = function()
            _G.XTEAMState.AimbotLoopToken = (_G.XTEAMState.AimbotLoopToken or 0) + 1
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(0.1, FastAimbotTick)
                ticker.AddTimerOnce(1.0, AimbotWeaponPatchTick)
            end
        end

        pcall(_G.__AimbotStart)
        print("[_s.dat] Aimbot engine installed")
    else
        print("[_s.dat] Aimbot engine already present (skipping engine install)")
    end

    -- ============================================================
    -- 4. UI SYSTEM
    -- ============================================================
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
        bg_aim_btn      = FLinearColor(0.85, 0.70, 1.0, 0.65),
        bg_tab_active   = FLinearColor(0.20, 0.55, 0.95, 0.95),
        bg_tab_idle     = FLinearColor(0.70, 0.70, 0.70, 0.55),
        text_black      = FLinearColor(0,0,0,1),
        text_blue       = FLinearColor(0.0, 0.35, 0.85, 1.0),
        text_purple     = FLinearColor(0.45, 0.10, 0.75, 1.0),
        text_light      = FLinearColor(1,1,1,1),
        text_dim        = FLinearColor(0.55, 0.55, 0.55, 1.0),
        text_red        = FLinearColor(1, 0.2, 0.2, 1.0),
        toggle_on       = FLinearColor(0.20, 0.85, 0.30, 1.0),
        toggle_off      = FLinearColor(0.60, 0.60, 0.60, 1.0),
        toggle_knob     = FLinearColor(1,1,1,1),
        close_btn       = FLinearColor(0.9, 0.2, 0.2, 1.0),
        transparent     = FLinearColor(0,0,0,0.01),
        border_blue     = FLinearColor(0.0, 0.35, 0.85, 0.6),
        btn_minus       = FLinearColor(0.9, 0.3, 0.3, 1.0),
        btn_plus        = FLinearColor(0.2, 0.8, 0.3, 1.0),
        btn_back        = FLinearColor(0.45, 0.45, 0.55, 1.0),
        btn_manual      = FLinearColor(0.55, 0.35, 0.75, 0.92),
        bg_popup        = FLinearColor(0.05, 0.05, 0.05, 1.0), -- SOLID DARK
    }

    local AIM_W, AIM_H = 520, 620
    local DROP_W, DROP_H = 180, 60
    local HEADER_H = 70
    local AIM_ROW_H = 34

    local parentCanvas = nil
    local aimPanel = nil
    local aimWidgets = {}
    local dropPanel, dropWidgets = nil, {}
    local floatItem = nil
    local isDropOpen, isAimOpen = false, false
    local aimBuilt = false
    local popupPanel = nil

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

    local function LayerInto(parent, list, x, y, w, h, color, z)
        local b = nil
        pcall(function()
            b = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if b and slua.isValid(b) then
                b:SetBrushColor(color)
                b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(b)
                if slot then slot:SetAutoSize(false) slot:SetPosition(FVector2D(x,y)) slot:SetSize(FVector2D(w,h)) slot:SetZOrder(z or 0) end
            end
        end)
        if list then table.insert(list, b) end
        return b
    end

    local function TextInto(parent, list, txt, x, y, size, color, z, aX, aY)
        local t = nil
        pcall(function()
            t = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
            if t and slua.isValid(t) then
                t:SetText(txt)
                if FSlateColor then t:SetColorAndOpacity(FSlateColor(color)) else t:SetColorAndOpacity(color) end
                if t.Font then local f = t.Font f.Size = size t.Font = f end
                t:SetRenderTransformPivot(FVector2D(aX or 0.5, aY or 0.5))
                t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(t)
                if slot then
                    slot:SetAutoSize(true) slot:SetAlignment(FVector2D(aX or 0.5, aY or 0.5))
                    slot:SetPosition(FVector2D(x, y)) slot:SetZOrder(z or 100)
                end
            end
        end)
        if list then table.insert(list, t) end
        return t
    end

    local function MakeBtnInto(parent, list, x, y, w, h, z, onClick)
        local btn = nil
        pcall(function()
            btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if btn and slua.isValid(btn) then
                pcall(function() btn:SetColorAndOpacity(C.transparent) end)
                pcall(function() btn:SetBackgroundColor(C.transparent) end)
                pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
                local slot = parent:AddChildToCanvas(btn)
                if slot then slot:SetAutoSize(false) slot:SetPosition(FVector2D(x,y)) slot:SetSize(FVector2D(w,h)) slot:SetZOrder(z or 900) end
                if onClick then pcall(function() if btn.OnClicked then btn.OnClicked:Add(function() pcall(onClick) end) end end) end
            end
        end)
        if list then table.insert(list, btn) end
        return btn
    end

    -- ═══ POPUP SYSTEM ═══
    local function ShowPopup(message, onOk)
        local canvas = GetCanvas()
        if not canvas then return end
        if popupPanel and IsValid(popupPanel) then popupPanel:RemoveFromParent() end
        
        local PW, PH = 540, 180
        popupPanel = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
        if not popupPanel or not slua.isValid(popupPanel) then return end

        local slot = canvas:AddChildToCanvas(popupPanel)
        if slot then
            slot:SetAutoSize(false)
            slot:SetZOrder(20000)
            local anc = slot:GetAnchors()
            anc.Minimum = FVector2D(0.5, 0.5)
            anc.Maximum = FVector2D(0.5, 0.5)
            slot:SetAnchors(anc)
            slot:SetAlignment(FVector2D(0.5, 0.5))
            slot:SetPosition(FVector2D(0, 0))
            slot:SetSize(FVector2D(PW, PH))
        end

        -- Solid Background
        local bg = CGame:NewObjectFromPath("/Script/UMG.Border", popupPanel)
        if bg and slua.isValid(bg) then
            bg:SetBrushColor(C.bg_popup)
            bg:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            local bgSlot = popupPanel:AddChildToCanvas(bg)
            if bgSlot then
                bgSlot:SetAutoSize(false)
                bgSlot:SetPosition(FVector2D(0, 0))
                bgSlot:SetSize(FVector2D(PW, PH))
                bgSlot:SetZOrder(1)
            end
        end
        
        -- Borders
        LayerInto(popupPanel, nil, 0, 0, PW, 3, C.text_blue, 2)
        LayerInto(popupPanel, nil, 0, PH-3, PW, 3, C.text_blue, 2)
        LayerInto(popupPanel, nil, 0, 0, 3, PH, C.text_blue, 2)
        LayerInto(popupPanel, nil, PW-3, 0, 3, PH, C.text_blue, 2)
        
        -- Text block (Fixed Wrapping)
        local textBlock = CGame:NewObjectFromPath("/Script/UMG.TextBlock", popupPanel)
        if textBlock and slua.isValid(textBlock) then
            textBlock:SetText(message)
            if FSlateColor then textBlock:SetColorAndOpacity(FSlateColor(C.text_light)) else textBlock:SetColorAndOpacity(C.text_light) end
            if textBlock.Font then local f = textBlock.Font f.Size = 15 textBlock.Font = f end
            textBlock:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            
            pcall(function() textBlock:SetAutoWrapText(true) end)
            pcall(function() textBlock:SetWrapTextAt(PW - 30) end)
            pcall(function() textBlock:SetJustification(1) end)
            
            local textSlot = popupPanel:AddChildToCanvas(textBlock)
            if textSlot then
                textSlot:SetAutoSize(false)
                textSlot:SetPosition(FVector2D(15, 25))
                textSlot:SetSize(FVector2D(PW - 30, PH - 90))
                textSlot:SetZOrder(10)
                textSlot:SetAlignment(FVector2D(0, 0))
            end
        end
        
        -- OK Button
        LayerInto(popupPanel, nil, (PW - 120)/2, PH - 60, 120, 36, C.btn_plus, 10)
        TextInto(popupPanel, nil, "OK", PW/2, PH - 42, 16, C.text_light, 11, 0.5, 0.5)
        MakeBtnInto(popupPanel, nil, (PW - 120)/2, PH - 60, 120, 36, 900, function()
            if popupPanel and IsValid(popupPanel) then
                popupPanel:RemoveFromParent()
                popupPanel = nil
            end
            if onOk then onOk() end
        end)
    end

    local function CheckLevelLocked()
        local lvl = getEffectiveLevel()
        if lvl <= 0 then
            ShowPopup("First enter account level\nin the box above!", nil)
            return true
        end
        return false
    end

    local function MakeConfigToggle(parent, list, cfgTable, field, label, x, y, w, h, isZebra)
        local state = cfgTable[field] == true
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5, 15, C.text_black, 300, 0, 0.5)
        local toggleW, toggleH = 44, 22
        local toggleX = x + w - toggleW - 16
        local toggleY = y + h * 0.5 - toggleH * 0.5
        local knobSize = toggleH - 4
        local track = LayerInto(parent, list, toggleX, toggleY, toggleW, toggleH, state and C.toggle_on or C.toggle_off, 300)
        local knobSlot = nil
        pcall(function()
            local knob = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if knob and slua.isValid(knob) then
                knob:SetBrushColor(C.toggle_knob)
                knob:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                knobSlot = parent:AddChildToCanvas(knob)
                if knobSlot then
                    local kx = state and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
                    knobSlot:SetAutoSize(false)
                    knobSlot:SetPosition(FVector2D(kx, toggleY + 2))
                    knobSlot:SetSize(FVector2D(knobSize, knobSize))
                    knobSlot:SetZOrder(301)
                end
                table.insert(list, knob)
            end
        end)
        MakeBtnInto(parent, list, x, y, w, h, 900, function()
            if CheckLevelLocked() then return end
            if not _G.XTEAMState.WarnedTweak then
                _G.XTEAMState.WarnedTweak = true
                ShowPopup("Warning: Your account can get banned\nif you change default settings!", function()
                    cfgTable[field] = not (cfgTable[field] == true)
                    local st = cfgTable[field] == true
                    pcall(function() track:SetBrushColor(st and C.toggle_on or C.toggle_off) end)
                    if knobSlot then
                        pcall(function()
                            local kx = st and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
                            knobSlot:SetPosition(FVector2D(kx, toggleY + 2))
                        end)
                    end
                    _G.XTEAMState.AutoProfile = false
                    saveProfile()
                end)
                return
            end
            cfgTable[field] = not (cfgTable[field] == true)
            local st = cfgTable[field] == true
            pcall(function() track:SetBrushColor(st and C.toggle_on or C.toggle_off) end)
            if knobSlot then
                pcall(function()
                    local kx = st and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
                    knobSlot:SetPosition(FVector2D(kx, toggleY + 2))
                end)
            end
            _G.XTEAMState.AutoProfile = false
            saveProfile()
        end)
    end

    local function MakeConfigSlider(parent, list, cfgTable, field, label, minV, maxV, stepV, fmtFn, x, y, w, h, isZebra)
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_slider_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5 - 7, 14, C.text_black, 300, 0, 0.5)
        local valText = TextInto(parent, list, fmtFn(cfgTable[field]), x + 16, y + h * 0.5 + 9, 12, C.text_blue, 300, 0, 0.5)
        local function refresh()
            if valText and IsValid(valText) then
                pcall(function() valText:SetText(fmtFn(cfgTable[field])) end)
            end
        end
        local btnW, btnH = 36, 26
        local btnY = y + h * 0.5 - btnH * 0.5
        local minusX = x + w - 94
        local plusX = x + w - 50

        local function doTweak(delta)
            if CheckLevelLocked() then return end
            local applyChange = function()
                local v = (tonumber(cfgTable[field]) or minV) + delta
                if v < minV then v = minV end
                if v > maxV then v = maxV end
                cfgTable[field] = v
                refresh()
                _G.XTEAMState.AutoProfile = false
                saveProfile()
            end
            if not _G.XTEAMState.WarnedTweak then
                _G.XTEAMState.WarnedTweak = true
                ShowPopup("Warning: Your account can get banned\nif you change default settings!", applyChange)
                return
            end
            applyChange()
        end

        LayerInto(parent, list, minusX, btnY, btnW, btnH, C.btn_minus, 299)
        TextInto(parent, list, "-", minusX + btnW * 0.5, btnY + btnH * 0.5, 20, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, minusX, btnY, btnW, btnH, 900, function() doTweak(-stepV) end)

        LayerInto(parent, list, plusX, btnY, btnW, btnH, C.btn_plus, 299)
        TextInto(parent, list, "+", plusX + btnW * 0.5, btnY + btnH * 0.5, 20, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, plusX, btnY, btnW, btnH, 900, function() doTweak(stepV) end)
    end

    local BuildAimMenu
    local BuildDropdown

    -- ---------- DROPDOWN ----------
    BuildDropdown = function()
        if dropPanel and IsValid(dropPanel) then
            dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            isDropOpen = true
            return
        end
        local canvas = GetCanvas()
        if not canvas then return end
        dropWidgets = {}
        pcall(function()
            dropPanel = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
            if dropPanel and slua.isValid(dropPanel) then
                local slot = canvas:AddChildToCanvas(dropPanel)
                if slot then
                    slot:SetAutoSize(false) slot:SetZOrder(10500)
                    slot:SetPosition(FVector2D(20, 120))
                    slot:SetSize(FVector2D(DROP_W, DROP_H))
                end
            end
        end)
        if not dropPanel or not slua.isValid(dropPanel) then return end

        LayerInto(dropPanel, dropWidgets, 0, 0, DROP_W, DROP_H, C.bg_panel, 1)
        LayerInto(dropPanel, dropWidgets, 0, 0, DROP_W, 2, C.border_blue, 2)
        LayerInto(dropPanel, dropWidgets, 0, DROP_H-2, DROP_W, 2, C.border_blue, 2)
        LayerInto(dropPanel, dropWidgets, 0, 0, 2, DROP_H, C.border_blue, 2)
        LayerInto(dropPanel, dropWidgets, DROP_W-2, 0, 2, DROP_H, C.border_blue, 2)

        LayerInto(dropPanel, dropWidgets, 4, 4, DROP_W-8, DROP_H-8, C.bg_aim_btn, 200)
        TextInto(dropPanel, dropWidgets, "AIMBOT", 16, DROP_H*0.5, 17, C.text_purple, 300, 0, 0.5)
        TextInto(dropPanel, dropWidgets, ">", DROP_W-24, DROP_H*0.5, 22, C.text_purple, 400, 0.5, 0.5)

        MakeBtnInto(dropPanel, dropWidgets, 4, 4, DROP_W-8, DROP_H-8, 900, function()
            isDropOpen = false
            if dropPanel and IsValid(dropPanel) then dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if not aimBuilt then BuildAimMenu() end
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
            isAimOpen = true
        end)
        isDropOpen = true
    end

    -- ---------- AIMBOT PANEL ----------
    local SwitchAimTab
    local AIM_MODES = {"Hipfire", "Shotgun", "Scope", "Sniper"}
    local TAB_LABELS = {Hipfire="HIPFIRE", Shotgun="SHOTGUN", Scope="SCOPE", Sniper="SNIPER"}
    local PRIORITY_NAMES = {[1]="Crosshair",[2]="Distance",[3]="Health",[4]="HP%"}
    local BONE_NAMES = {[1]="Head",[2]="Neck",[3]="Chest",[4]="Pelvis"}
    local CONDITION_NAMES = {[1]="Hold Fire",[2]="Always"}

    BuildAimMenu = function()
        if aimBuilt and (not aimPanel or not IsValid(aimPanel)) then
            aimBuilt = false
            aimPanel = nil
            aimWidgets = {}
            isAimOpen = false
        end
        if aimBuilt and aimPanel and IsValid(aimPanel) then
            pcall(function() aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            isAimOpen = true
            return
        end
        local canvas = GetCanvas()
        if not canvas then return end
        aimWidgets = {}
        pcall(function()
            aimPanel = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
            if aimPanel and slua.isValid(aimPanel) then
                local slot = canvas:AddChildToCanvas(aimPanel)
                if slot then
                    slot:SetAutoSize(false) slot:SetZOrder(10501)
                    slot:SetPosition(FVector2D(220, 10))
                    slot:SetSize(FVector2D(AIM_W, AIM_H))
                end
            end
        end)
        if not aimPanel or not slua.isValid(aimPanel) then return end

        LayerInto(aimPanel, aimWidgets, 0,0, AIM_W,AIM_H, C.bg_panel, 1)
        LayerInto(aimPanel, aimWidgets, 0,0, AIM_W,2, C.border_blue, 2)
        LayerInto(aimPanel, aimWidgets, 0,AIM_H-2, AIM_W,2, C.border_blue, 2)
        LayerInto(aimPanel, aimWidgets, 0,0, 2,AIM_H, C.border_blue, 2)
        LayerInto(aimPanel, aimWidgets, AIM_W-2,0, 2,AIM_H, C.border_blue, 2)
        LayerInto(aimPanel, aimWidgets, 2,2, AIM_W-4, HEADER_H-4, C.bg_header, 3)
        TextInto(aimPanel, aimWidgets, "AIMBOT CONFIG", AIM_W*0.5, HEADER_H*0.5, 22, C.text_purple, 400, 0.5, 0.5)

        MakeBtnInto(aimPanel, aimWidgets, 20,20, 60,30, 900, function()
            isAimOpen = false
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if not dropPanel or not IsValid(dropPanel) then
                BuildDropdown()
            else
                dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                isDropOpen = true
            end
        end)
        LayerInto(aimPanel, aimWidgets, 20,24, 60,22, C.btn_back, 350)
        TextInto(aimPanel, aimWidgets, "< BACK", 50, 35, 14, C.text_light, 400, 0.5, 0.5)

        MakeBtnInto(aimPanel, aimWidgets, AIM_W-40,20, 30,30, 900, function()
            isAimOpen = false
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if dropPanel and IsValid(dropPanel) then dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            isDropOpen = false
        end)
        TextInto(aimPanel, aimWidgets, "X", AIM_W-25, 35, 20, C.close_btn, 400, 0.5, 0.5)

        -- ═══ LEVEL INFO + INPUT ROW ═══
        local autoLvl = getAccountLevel()
        local manualLvl = _G.XTEAMState.ManualLevel or 0
        local effLvl = manualLvl > 0 and manualLvl or autoLvl
        local recProfile = getRecommendedProfile(effLvl)
        local infoY = HEADER_H + 4

        LayerInto(aimPanel, aimWidgets, 2, infoY, AIM_W - 4, 32, C.bg_section, 4)
        local lvlSource = manualLvl > 0 and "MANUAL" or (autoLvl > 0 and "AUTO" or "UNKNOWN")
        local lvlStr = effLvl > 0 and tostring(effLvl) or "?"
        
        local infoText = "LVL " .. lvlStr .. " (" .. lvlSource .. ") | REC: " .. string.upper(recProfile)
        TextInto(aimPanel, aimWidgets, infoText, 12, infoY + 16, 13, C.text_blue, 5, 0, 0.5)

        -- Text Input Box & SET Button
        local inputBox = nil
        pcall(function()
            inputBox = CGame:NewObjectFromPath("/Script/UMG.EditableTextBox", aimPanel)
            if inputBox and slua.isValid(inputBox) then
                inputBox:SetText(manualLvl > 0 and tostring(manualLvl) or "")
                inputBox:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                if inputBox.SetHintText then inputBox:SetHintText("Type Lvl") end
                if inputBox.Font then local f = inputBox.Font f.Size = 15 inputBox.Font = f end
                local slot = aimPanel:AddChildToCanvas(inputBox)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(FVector2D(AIM_W - 156, infoY + 3))
                    slot:SetSize(FVector2D(100, 26))
                    slot:SetZOrder(50)
                end
            end
        end)

        local function applyManualLevel()
            local txt = ""
            if inputBox and slua.isValid(inputBox) then
                pcall(function() txt = inputBox:GetText() end)
            end
            if txt == "" then
                _G.XTEAMState.ManualLevel = 0
                _G.XTEAMState.AutoProfile = true
                local rec = getRecommendedProfile(autoLvl)
                applyProfile(rec)
                saveProfile()
                if aimPanel and IsValid(aimPanel) then aimPanel:RemoveFromParent() end
                aimBuilt = false; aimPanel = nil; aimWidgets = {}
                BuildAimMenu()
                return
            end
            local num = tonumber(txt)
            if num and num > 0 then
                _G.XTEAMState.ManualLevel = math.max(1, math.min(200, num))
                _G.XTEAMState.AutoProfile = true
                local rec = getRecommendedProfile(_G.XTEAMState.ManualLevel)
                applyProfile(rec)
                saveProfile()
                if aimPanel and IsValid(aimPanel) then aimPanel:RemoveFromParent() end
                aimBuilt = false; aimPanel = nil; aimWidgets = {}
                BuildAimMenu()
            end
        end

        -- SET Button
        LayerInto(aimPanel, aimWidgets, AIM_W - 50, infoY + 3, 44, 26, C.btn_plus, 6)
        TextInto(aimPanel, aimWidgets, "SET", AIM_W - 28, infoY + 16, 12, C.text_light, 7, 0.5, 0.5)
        MakeBtnInto(aimPanel, aimWidgets, AIM_W - 50, infoY + 3, 44, 26, 900, applyManualLevel)
        
        if inputBox then
            pcall(function()
                if inputBox.OnTextCommitted then
                    inputBox.OnTextCommitted:Add(function() applyManualLevel() end)
                end
            end)
        end

        -- ═══ PROFILE SELECTOR ═══
        local profY = infoY + 36 -- shifted down
        local profH = 38
        local profGap = 8
        local profW = (AIM_W - 24 - profGap * 2) / 3
        local profMeta = {
            Low    = {label = "LOW   Lv 1-30",  color = FLinearColor(0.18, 0.70, 0.30, 0.92)},
            Medium = {label = "MED   Lv 30-60", color = FLinearColor(0.85, 0.62, 0.15, 0.92)},
            Pro    = {label = "PRO   Lv 60+",   color = FLinearColor(0.82, 0.20, 0.28, 0.92)},
        }
        local profileOrder = {"Low", "Medium", "Pro"}

        local function rebuildMenu()
            pcall(function()
                if aimPanel and IsValid(aimPanel) then aimPanel:RemoveFromParent() end
            end)
            aimBuilt = false
            aimPanel = nil
            aimWidgets = {}
            isAimOpen = false
            BuildAimMenu()
        end

        for i, pname in ipairs(profileOrder) do
            local meta = profMeta[pname]
            local bx = 12 + (i - 1) * (profW + profGap)
            local isCurrent = (_G.XTEAMState.Profile == pname)
            LayerInto(aimPanel, aimWidgets, bx, profY, profW, profH,
                isCurrent and C.bg_tab_active or meta.color, 310)
            TextInto(aimPanel, aimWidgets, meta.label, bx + profW * 0.5, profY + profH * 0.5,
                13, C.text_light, 400, 0.5, 0.5)
            MakeBtnInto(aimPanel, aimWidgets, bx, profY, profW, profH, 900, function()
                if CheckLevelLocked() then return end
                _G.XTEAMState.AutoProfile = false
                applyProfile(pname)
                saveProfile()
                rebuildMenu()
            end)
        end

        -- ═══ TABS ═══
        local contentX = 12
        local contentW = AIM_W - 24
        local tabY = profY + profH + 8
        local tabW = (contentW - 12) / 4
        local tabH = 34
        local tabButtons = {}
        local tabPanels = {}

        SwitchAimTab = function(mode)
            for k, tp in pairs(tabPanels) do
                pcall(function()
                    if tp and slua.isValid(tp) then
                        tp:SetWidgetVisibility(k == mode and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
                    end
                end)
            end
            for k, btn in pairs(tabButtons) do
                pcall(function()
                    btn.bg:SetBrushColor(k == mode and C.bg_tab_active or C.bg_tab_idle)
                    local col = (k == mode) and C.text_light or C.text_black
                    if FSlateColor then btn.label:SetColorAndOpacity(FSlateColor(col)) else btn.label:SetColorAndOpacity(col) end
                end)
            end
        end

        local rowYStart = tabY + tabH + 10
        for _, mode in ipairs(AIM_MODES) do
            local tp = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", aimPanel)
            if tp and slua.isValid(tp) then
                local slot = aimPanel:AddChildToCanvas(tp)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(FVector2D(0, rowYStart))
                    slot:SetSize(FVector2D(AIM_W, AIM_H - rowYStart - 32))
                    slot:SetZOrder(200)
                end
                tabPanels[mode] = tp
                tp:SetWidgetVisibility(mode == "Hipfire" and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
            end
        end

        for i, mode in ipairs(AIM_MODES) do
            local tx = contentX + (i-1)*(tabW+4)
            local bg = LayerInto(aimPanel, aimWidgets, tx, tabY, tabW, tabH, C.bg_tab_idle, 310)
            local label = TextInto(aimPanel, aimWidgets, TAB_LABELS[mode], tx + tabW*0.5, tabY + tabH*0.5, 13, C.text_black, 400, 0.5, 0.5)
            MakeBtnInto(aimPanel, aimWidgets, tx, tabY, tabW, tabH, 900, function()
                if CheckLevelLocked() then return end
                SwitchAimTab(mode)
            end)
            tabButtons[mode] = { bg = bg, label = label }
        end

        for _, mode in ipairs(AIM_MODES) do
            local cfg = _G.XTEAMConfig.AimModes[mode]
            local tp = tabPanels[mode]
            if tp and slua.isValid(tp) then
                local x, w, y = contentX, contentW, 0
                MakeConfigToggle(tp, aimWidgets, cfg, "Enable", "Enable", x, y, w, AIM_ROW_H, false); y = y + AIM_ROW_H + 3
                MakeConfigToggle(tp, aimWidgets, cfg, "IgKnock", "Ignore Knocked", x, y, w, AIM_ROW_H, true); y = y + AIM_ROW_H + 3
                MakeConfigToggle(tp, aimWidgets, cfg, "IgBot", "Ignore Bots", x, y, w, AIM_ROW_H, false); y = y + AIM_ROW_H + 3
                MakeConfigToggle(tp, aimWidgets, cfg, "VisCheck", "Visibility Check", x, y, w, AIM_ROW_H, true); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "Priority", "Priority", 1, 4, 1,
                    function(v) return "Value: " .. (PRIORITY_NAMES[v] or "?") .. " (" .. v .. "/4)" end,
                    x, y, w, AIM_ROW_H, false); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "Bone", "Bone", 1, 4, 1,
                    function(v) return "Value: " .. (BONE_NAMES[v] or "?") .. " (" .. v .. "/4)" end,
                    x, y, w, AIM_ROW_H, true); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "Condition", "Condition", 1, 2, 1,
                    function(v) return "Value: " .. (CONDITION_NAMES[v] or "?") .. " (" .. v .. "/2)" end,
                    x, y, w, AIM_ROW_H, false); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "Speed", "Speed", 1, 100, 5,
                    function(v) return "Value: " .. v end,
                    x, y, w, AIM_ROW_H, true); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "FOV", "FOV", 1, 100, 1,
                    function(v) return "Value: " .. v end,
                    x, y, w, AIM_ROW_H, false); y = y + AIM_ROW_H + 3
                MakeConfigSlider(tp, aimWidgets, cfg, "MaxDist", "Max Distance", 10, 500, 10,
                    function(v) return "Value: " .. v .. " m" end,
                    x, y, w, AIM_ROW_H, true)
            end
        end

        LayerInto(aimPanel, aimWidgets, 2, AIM_H-30, AIM_W-4, 28, C.bg_header, 5)
        TextInto(aimPanel, aimWidgets, "Profile = baseline  |  Tabs = fine-tune", AIM_W*0.5, AIM_H-15, 12, C.text_purple, 400, 0.5, 0.5)
        aimBuilt = true
        isAimOpen = true
        SwitchAimTab("Hipfire")
    end

    -- ---------- MENU FLOAT ----------
    local function CreateFloat()
        if floatItem and floatItem.btn and IsValid(floatItem.btn) then return end
        floatItem = nil
        pcall(function()
            local canvas = GetCanvas()
            if not canvas then return end
            floatItem = {}
            local fX, fY, fW, fH = 20, 70, 110, 45
            floatItem.s8 = LayerInto(canvas, nil, fX, fY, fW, fH, FLinearColor(0.96, 0.96, 0.96, 0.75), 11902)
            LayerInto(canvas, nil, fX, fY, fW, 4, C.border_blue, 11903)
            LayerInto(canvas, nil, fX, fY, fW, 2, C.border_blue, 11904)
            LayerInto(canvas, nil, fX, fY + fH - 2, fW, 2, C.border_blue, 11904)
            pcall(function()
                floatItem.text = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                if floatItem.text and slua.isValid(floatItem.text) then
                    floatItem.text:SetText("MENU")
                    if FSlateColor then floatItem.text:SetColorAndOpacity(FSlateColor(C.text_purple))
                    else floatItem.text:SetColorAndOpacity(C.text_purple) end
                    if floatItem.text.Font then local f = floatItem.text.Font f.Size = 20 floatItem.text.Font = f end
                    floatItem.text:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    local slot = canvas:AddChildToCanvas(floatItem.text)
                    if slot then
                        slot:SetAutoSize(true) slot:SetAlignment(FVector2D(0.5, 0.5))
                        slot:SetPosition(FVector2D(fX + fW * 0.5, fY + fH * 0.5)) slot:SetZOrder(12001)
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
                        slot:SetAutoSize(false) slot:SetPosition(FVector2D(fX, fY)) slot:SetSize(FVector2D(fW, fH)) slot:SetZOrder(12002)
                    end
                    pcall(function()
                        if floatItem.btn.OnClicked then
                            floatItem.btn.OnClicked:Add(function()
                                pcall(function()
                                    if popupPanel and IsValid(popupPanel) then
                                        popupPanel:RemoveFromParent() popupPanel = nil
                                    end
                                    if isAimOpen then
                                        isAimOpen = false
                                        if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                        isDropOpen = false
                                        if dropPanel and IsValid(dropPanel) then dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                        return
                                    end
                                    isDropOpen = not isDropOpen
                                    if isDropOpen then
                                        if dropPanel and IsValid(dropPanel) then
                                            dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                        else
                                            BuildDropdown()
                                        end
                                    else
                                        if dropPanel and IsValid(dropPanel) then
                                            dropPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
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

    -- ---------- AUTO LEVEL TICKER ----------
    local function LevelAutoTicker()
        pcall(function()
            if not _G.XTEAMState.AutoProfile then return end

            local lvl = getEffectiveLevel()
            if lvl > 0 then
                local rec = getRecommendedProfile(lvl)
                if rec ~= _G.XTEAMState.Profile then
                    applyProfile(rec)
                    saveProfile()
                    if aimBuilt and aimPanel and IsValid(aimPanel) then
                        pcall(function() aimPanel:RemoveFromParent() end)
                        aimBuilt = false; aimPanel = nil; aimWidgets = {}
                        BuildAimMenu()
                    end
                end
            end
        end)
        local ok, ticker = pcall(require, "common.time_ticker")
        if ok and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(5.0, LevelAutoTicker)
        end
    end
    LevelAutoTicker()

    -- ---------- WATCHDOG ----------
    local function Watchdog()
        pcall(function()
            if not floatItem or not floatItem.btn or not IsValid(floatItem.btn) then
                floatItem = nil
                isDropOpen = false
                isAimOpen = false
                CreateFloat()
            end
            if dropPanel and not IsValid(dropPanel) then
                dropPanel = nil
                dropWidgets = {}
                isDropOpen = false
            end
            if aimBuilt and (not aimPanel or not IsValid(aimPanel)) then
                aimBuilt = false
                aimPanel = nil
                aimWidgets = {}
                isAimOpen = false
            end
            if popupPanel and not IsValid(popupPanel) then
                popupPanel = nil
            end
        end)
        local ok, ticker = pcall(require, "common.time_ticker")
        if ok and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.5, Watchdog)
        end
    end

    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and IsValid(pc) then CreateFloat() end
    end)
    Watchdog()

    print("[_s.dat] Aimbot + Profiles FINAL loaded")
end
