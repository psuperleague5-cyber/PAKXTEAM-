-- ============================================================
-- FINAL ESP BUILD — PAKxTEAM Snaplines + PAKxTEAM ESP + AIMBOT
-- ============================================================

if _G.XTEAM_LOADER_LOADED then return end
_G.XTEAM_LOADER_LOADED = true

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
        if PlayerMapMarker._timersPC == pc and PlayerMapMarker._timersAttached then return end
        PlayerMapMarker._timersPC = pc
        PlayerMapMarker._timersAttached = true

        pcall(function() pc:AddGameTimer(PlayerMapMarker.nUpdateInterval or 0.5, true, function() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.ScanAndUpdate() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._LightUpdateInterval or 0.02, true, function() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.UpdateESPLight() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._DistanceUpdateInterval or 0.1, true, function() if PlayerMapMarker.bActive and PlayerMapMarker.bUseScreenESP and PlayerMapMarker.bShowDistance then pcall(function() PlayerMapMarker.UpdateESPDistances() end) end end) end)
    end)
end

function PlayerMapMarker.Start()
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
-- SECTION 3.5 — ESP V1 (PAKxTEAM/Botmater engine, from USMAN.lua)
-- Independent engine, toggle via menu
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
-- SECTION 3.7 — AIMBOT ENGINE (Per-Mode Config)
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

if not _G.XTEAMConfig.AimModes then
    _G.XTEAMConfig.AimModes = {
        Hipfire = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=3, Condition=1, Speed=50, FOV=21 },
        Shotgun = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=1, Condition=2, Speed=25, FOV=15 },
        Scope   = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=3, Condition=1, Speed=55, FOV=20 },
        Sniper  = { Enable=false, IgKnock=true, IgBot=true, VisCheck=true, Priority=1, Bone=1, Condition=2, Speed=60, FOV=20 },
    }
end
_G.XTEAMConfig.AimTouchEnable = true

-- 3.7.A — Enemy Target Collector
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

-- 3.7.B — AimTouch (per-mode)
_G.AimTouch = function()
    pcall(function()
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
        if isShotgun then maxDistMeters = 30
        elseif isADS and isSniper then maxDistMeters = 400
        elseif isADS then maxDistMeters = 300
        else maxDistMeters = 250 end
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

-- 3.7.C — Weapon Patch (AutoHead + Legacy CustomAimbot)
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

-- 3.7.D — AutoAimComp Patch (character-level AutoHead)
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

-- 3.7.E — Ticks
local function FastAimbotTick()
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

if not _G.__AIMBOT_INSTALLED then
    _G.__AIMBOT_INSTALLED = true
    pcall(_G.__AimbotStart)
end

print("[AIMBOT] Per-mode engine installed")

-- ============================================================
-- SECTION 4 — Orchestration
-- ============================================================
function _G.NewFreshRuntimeTick()
    -- PAKxTEAM snaplines only (sync enabled state)
    _G.Mod_ESP_Enabled = _G.Mod_ESP_ShowSnapline or false

    if _G.PlayerMapMarker then
        _G.PlayerMapMarker.bUseSnapLines = _G.Mod_ESP_ShowSnapline or false
        _G.PlayerMapMarker.bShowDistance = false
        if _G.Mod_ESP_Enabled then
            if not _G.PlayerMapMarker.bActive then pcall(_G.PlayerMapMarker.Start) end
        elseif _G.PlayerMapMarker.bActive then
            pcall(_G.PlayerMapMarker.Stop)
        end
    end
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
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and pc:GetCurPawn()
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
-- SECTION 6 — Menu + AIMBOT SUBMENU
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
        bg_aim_btn      = FLinearColor(0.85, 0.70, 1.0, 0.65),
        bg_tab_active   = FLinearColor(0.20, 0.55, 0.95, 0.95),
        bg_tab_idle     = FLinearColor(0.70, 0.70, 0.70, 0.55),
        text_black      = FLinearColor(0,0,0,1),
        text_blue       = FLinearColor(0.0, 0.35, 0.85, 1.0),
        text_purple     = FLinearColor(0.45, 0.10, 0.75, 1.0),
        text_light      = FLinearColor(1,1,1,1),
        toggle_on       = FLinearColor(0.20, 0.85, 0.30, 1.0),
        toggle_off      = FLinearColor(0.60, 0.60, 0.60, 1.0),
        toggle_knob     = FLinearColor(1,1,1,1),
        close_btn       = FLinearColor(0.9, 0.2, 0.2, 1.0),
        transparent     = FLinearColor(0,0,0,0.01),
        border_blue     = FLinearColor(0.0, 0.35, 0.85, 0.6),
        btn_minus       = FLinearColor(0.9, 0.3, 0.3, 1.0),
        btn_plus        = FLinearColor(0.2, 0.8, 0.3, 1.0),
        btn_back        = FLinearColor(0.45, 0.45, 0.55, 1.0),
    }

    local M_W, M_H = 520, 590
    local AIM_W, AIM_H = 520, 620
    local ROW_H, SLIDER_ROW_H = 44, 50
    local HEADER_H, SECTION_H = 70, 32
    local AIM_ROW_H = 42

    local SNAPLINE_COLORS = {
        {name="Yellow",r=1,g=0.85,b=0}, {name="Red",r=1,g=0.1,b=0.1},
        {name="Green",r=0.1,g=1,b=0.2}, {name="Cyan",r=0,g=1,b=1},
        {name="Blue",r=0.2,g=0.4,b=1},  {name="Purple",r=0.7,g=0.2,b=1},
        {name="Pink",r=1,g=0.4,b=0.7},  {name="Orange",r=1,g=0.5,b=0},
        {name="White",r=1,g=1,b=1},     {name="Magenta",r=1,g=0,b=1},
    }
    if not _G.SnapLineColorIndex then _G.SnapLineColorIndex = 1 end
    local function ApplySnapLineColor()
        pcall(function()
            local cfg = SNAPLINE_COLORS[_G.SnapLineColorIndex] or SNAPLINE_COLORS[1]
            local FLC = import("LinearColor")
            if FLC then _G.SnapLineCustomColor = FLC(cfg.r, cfg.g, cfg.b, 1.0) end
        end)
    end
    ApplySnapLineColor()

    _G.Mod_ESP_ShowSnapline = true
    _G.Mod_ESP_Enabled = true
    if _G.g_Botmater_VIPShotESP then _G.g_Botmater_VIPShotESP.Enabled = true end
    if _G.g_Botmater_ESPOptions then
        _G.g_Botmater_ESPOptions.Name = true
        _G.g_Botmater_ESPOptions.Health = true
        _G.g_Botmater_ESPOptions.Distance = true
        _G.g_Botmater_ESPOptions.EnemyCounter = true
    end

    local FeatureMap = {
        ESP_Line   = "_G.Mod_ESP_ShowSnapline",
        V1_Master  = "_G.g_Botmater_VIPShotESP.Enabled",
        V1_Name    = "_G.g_Botmater_ESPOptions.Name",
        V1_Health  = "_G.g_Botmater_ESPOptions.Health",
        V1_Distance= "_G.g_Botmater_ESPOptions.Distance",
        V1_Counter = "_G.g_Botmater_ESPOptions.EnemyCounter",
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
            if _G.g_Botmater_VIPShotESP then _G.g_Botmater_VIPShotESP.Enabled = value end return
        elseif key == "V1_Name" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Name = value end return
        elseif key == "V1_Health" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Health = value end return
        elseif key == "V1_Distance" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.Distance = value end return
        elseif key == "V1_Counter" then
            if _G.g_Botmater_ESPOptions then _G.g_Botmater_ESPOptions.EnemyCounter = value end return
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
                    if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive then pcall(_G.PlayerMapMarker.Start) end
                else
                    if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then pcall(_G.PlayerMapMarker.Stop) end
                end
            end
        end)
    end
    for cfgKey, _ in pairs(FeatureMap) do GetFeatureState(cfgKey) end

    local parentCanvas = nil
    local bgPanel, aimPanel = nil, nil
    local allWidgets, aimWidgets = {}, {}
    local toggleRows = {}
    local floatItem = nil
    local isMenuOpen, isAimOpen = false, false
    local menuBuilt, aimBuilt = false, false

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

    local function MakeToggleRowInto(parent, list, rowList, label, x, y, w, h, toggleKey, isZebra)
        local state = GetFeatureState(toggleKey)
        local rowData = { key = toggleKey }
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5, 16, C.text_black, 300, 0, 0.5)
        local toggleW, toggleH = 48, 24
        local toggleX = x + w - toggleW - 16
        local toggleY = y + h * 0.5 - toggleH * 0.5
        local knobSize = toggleH - 4
        rowData.toggleX, rowData.toggleY, rowData.toggleW, rowData.knobSize = toggleX, toggleY, toggleW, knobSize
        rowData.track = LayerInto(parent, list, toggleX, toggleY, toggleW, toggleH, state and C.toggle_on or C.toggle_off, 300)
        local knobX = state and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
        pcall(function()
            local k = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if k and slua.isValid(k) then
                k:SetBrushColor(C.toggle_knob)
                k:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local slot = parent:AddChildToCanvas(k)
                if slot then slot:SetAutoSize(false) slot:SetPosition(FVector2D(knobX, toggleY + 2)) slot:SetSize(FVector2D(knobSize, knobSize)) slot:SetZOrder(301) end
                rowData.knob = k
                rowData.knobSlot = slot
                table.insert(list, k)
            end
        end)
        rowData.btn = MakeBtnInto(parent, list, x, y, w, h, 900, function()
            local newState = not GetFeatureState(toggleKey)
            ApplyFeature(toggleKey, newState)
            UpdateToggleRow(rowData)
        end)
        table.insert(rowList, rowData)
        return rowData
    end

    local function MakeSliderRowInto(parent, list, rowList, label, x, y, w, h, getTextFn, onMinus, onPlus, isZebra)
        local rowData = { key = label, isSlider = true }
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_slider_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5 - 8, 15, C.text_black, 300, 0, 0.5)
        rowData.valueText = TextInto(parent, list, getTextFn(), x + 16, y + h * 0.5 + 10, 13, C.text_blue, 300, 0, 0.5)
        local function RefreshText()
            if rowData.valueText and IsValid(rowData.valueText) then
                pcall(function() rowData.valueText:SetText(getTextFn()) end)
            end
        end
        local btnW, btnH = 40, 36
        local btnY = y + h * 0.5 - btnH * 0.5
        local minusX = x + w - 100
        local plusX = x + w - 52
        LayerInto(parent, list, minusX, btnY, btnW, btnH, C.btn_minus, 299)
        TextInto(parent, list, "-", minusX + btnW * 0.5, btnY + btnH * 0.5, 26, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, minusX, btnY, btnW, btnH, 900, function() onMinus() RefreshText() end)
        LayerInto(parent, list, plusX, btnY, btnW, btnH, C.btn_plus, 299)
        TextInto(parent, list, "+", plusX + btnW * 0.5, btnY + btnH * 0.5, 24, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, plusX, btnY, btnW, btnH, 900, function() onPlus() RefreshText() end)
        table.insert(rowList, rowData)
        return rowData
    end

    local function SectionHeaderInto(parent, list, txt, x, y, w, colText)
        LayerInto(parent, list, x, y, w, SECTION_H, C.bg_section, 250)
        TextInto(parent, list, txt, x + w * 0.5, y + SECTION_H * 0.5, 15, colText or C.text_blue, 300, 0.5, 0.5)
    end

    local function MakeConfigToggle(parent, list, cfgTable, field, label, x, y, w, h, isZebra)
        local state = cfgTable[field] == true
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5, 16, C.text_black, 300, 0, 0.5)
        local toggleW, toggleH = 48, 24
        local toggleX = x + w - toggleW - 16
        local toggleY = y + h * 0.5 - toggleH * 0.5
        local knobSize = toggleH - 4
        local track = LayerInto(parent, list, toggleX, toggleY, toggleW, toggleH, state and C.toggle_on or C.toggle_off, 300)
        local knob = nil
        local knobSlot = nil
        pcall(function()
            knob = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
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
            cfgTable[field] = not (cfgTable[field] == true)
            local st = cfgTable[field] == true
            pcall(function() track:SetBrushColor(st and C.toggle_on or C.toggle_off) end)
            if knobSlot then
                pcall(function()
                    local kx = st and (toggleX + toggleW - knobSize - 2) or (toggleX + 2)
                    knobSlot:SetPosition(FVector2D(kx, toggleY + 2))
                end)
            end
        end)
    end

    local function MakeConfigSlider(parent, list, cfgTable, field, label, minV, maxV, stepV, fmtFn, x, y, w, h, isZebra)
        LayerInto(parent, list, x, y, w, h, isZebra and C.bg_row_alt or C.bg_slider_row, 200)
        TextInto(parent, list, label, x + 16, y + h * 0.5 - 8, 15, C.text_black, 300, 0, 0.5)
        local valText = TextInto(parent, list, fmtFn(cfgTable[field]), x + 16, y + h * 0.5 + 10, 13, C.text_blue, 300, 0, 0.5)
        local function refresh()
            if valText and IsValid(valText) then
                pcall(function() valText:SetText(fmtFn(cfgTable[field])) end)
            end
        end
        local btnW, btnH = 40, 36
        local btnY = y + h * 0.5 - btnH * 0.5
        local minusX = x + w - 100
        local plusX = x + w - 52
        LayerInto(parent, list, minusX, btnY, btnW, btnH, C.btn_minus, 299)
        TextInto(parent, list, "-", minusX + btnW * 0.5, btnY + btnH * 0.5, 26, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, minusX, btnY, btnW, btnH, 900, function()
            local v = (tonumber(cfgTable[field]) or minV) - stepV
            if v < minV then v = minV end
            cfgTable[field] = v
            refresh()
        end)
        LayerInto(parent, list, plusX, btnY, btnW, btnH, C.btn_plus, 299)
        TextInto(parent, list, "+", plusX + btnW * 0.5, btnY + btnH * 0.5, 24, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(parent, list, plusX, btnY, btnW, btnH, 900, function()
            local v = (tonumber(cfgTable[field]) or minV) + stepV
            if v > maxV then v = maxV end
            cfgTable[field] = v
            refresh()
        end)
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
                    slot:SetAutoSize(false) slot:SetZOrder(10000)
                    local anchored = false
                    pcall(function() slot:SetAnchors({Minimum=FVector2D(1,0),Maximum=FVector2D(1,0)}) anchored=true end)
                    if anchored then slot:SetAlignment(FVector2D(1,0)) slot:SetPosition(FVector2D(-20,20))
                    else slot:SetAlignment(FVector2D(0,0)) slot:SetPosition(FVector2D(1920 - M_W - 20, 20)) end
                    slot:SetSize(FVector2D(M_W, M_H))
                end
            end
        end)
        if not bgPanel or not slua.isValid(bgPanel) then return end

        LayerInto(bgPanel, allWidgets, 0,0, M_W,M_H, C.bg_panel, 1)
        LayerInto(bgPanel, allWidgets, 0,0, M_W,2, C.border_blue, 2)
        LayerInto(bgPanel, allWidgets, 0,M_H-2, M_W,2, C.border_blue, 2)
        LayerInto(bgPanel, allWidgets, 0,0, 2,M_H, C.border_blue, 2)
        LayerInto(bgPanel, allWidgets, M_W-2,0, 2,M_H, C.border_blue, 2)
        LayerInto(bgPanel, allWidgets, 2,2, M_W-4, HEADER_H-4, C.bg_header, 3)
        TextInto(bgPanel, allWidgets, "(+923211154129) COMBAT VERSION", M_W*0.5, HEADER_H*0.5, 24, C.text_black, 400, 0.5, 0.5)
        LayerInto(bgPanel, allWidgets, 20,18, 12,12, FLinearColor(1,0.4,0.4), 5)
        LayerInto(bgPanel, allWidgets, 40,18, 12,12, FLinearColor(1,0.8,0.2), 5)
        LayerInto(bgPanel, allWidgets, 60,18, 12,12, FLinearColor(0.2,0.9,0.2), 5)

        MakeBtnInto(bgPanel, allWidgets, M_W-40,20, 30,30, 900, function()
            isMenuOpen=false isAimOpen=false
            if bgPanel and IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        end)
        TextInto(bgPanel, allWidgets, "X", M_W-25, 35, 20, C.close_btn, 400, 0.5, 0.5)

        local contentX = 12
        local contentW = M_W - 24
        local y = HEADER_H + 10

        SectionHeaderInto(bgPanel, allWidgets, "SNAPLINES (PAKxTEAM)", contentX, y, contentW)
        y = y + SECTION_H + 4
        MakeToggleRowInto(bgPanel, allWidgets, toggleRows, "ESP LINE", contentX, y, contentW, ROW_H, "ESP_Line", false)
        y = y + ROW_H + 4
        MakeSliderRowInto(bgPanel, allWidgets, toggleRows, "SNAPLINE COLOR", contentX, y, contentW, SLIDER_ROW_H,
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
            end, true)
        y = y + SLIDER_ROW_H + 10

        LayerInto(bgPanel, allWidgets, contentX, y, contentW, ROW_H, C.bg_aim_btn, 200)
        TextInto(bgPanel, allWidgets, "AIMBOT SETTINGS(use default) For safety", contentX + 16, y + ROW_H * 0.5, 16, C.text_purple, 300, 0, 0.5)
        TextInto(bgPanel, allWidgets, ">", contentX + contentW - 24, y + ROW_H * 0.5, 22, C.text_purple, 400, 0.5, 0.5)
        MakeBtnInto(bgPanel, allWidgets, contentX, y, contentW, ROW_H, 900, function()
            if not aimBuilt then BuildAimMenu() end
            isMenuOpen=false isAimOpen=true
            if bgPanel and IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
        end)
        y = y + ROW_H + 10

        SectionHeaderInto(bgPanel, allWidgets, "PAKxTEAM ESP", contentX, y, contentW)
        y = y + SECTION_H + 4
        local v1Options = {
            {label="V1 MASTER ENABLE", key="V1_Master"},
            {label="V1 NAME TAG", key="V1_Name"},
            {label="V1 HEALTH BAR", key="V1_Health"},
            {label="V1 DISTANCE", key="V1_Distance"},
            {label="V1 ENEMY COUNTER", key="V1_Counter"},
        }
        for i, opt in ipairs(v1Options) do
            MakeToggleRowInto(bgPanel, allWidgets, toggleRows, opt.label, contentX, y, contentW, ROW_H, opt.key, i%2==0)
            y = y + ROW_H + 4
        end
        LayerInto(bgPanel, allWidgets, 2, M_H-32, M_W-4, 30, C.bg_header, 5)
        TextInto(bgPanel, allWidgets, "DEVELOPER - https://t.me/Nehaowner", M_W*0.5, M_H-15, 12, C.text_blue, 400, 0.5, 0.5)
        menuBuilt = true
        isMenuOpen = true
    end

    local AIM_MODES = {"Hipfire", "Shotgun", "Scope", "Sniper"}
    local TAB_LABELS = {Hipfire="HIPFIRE", Shotgun="SHOTGUN", Scope="SCOPE", Sniper="SNIPER"}
    local PRIORITY_NAMES = {[1]="Crosshair",[2]="Distance",[3]="Health",[4]="HP%"}
    local BONE_NAMES = {[1]="Head",[2]="Neck",[3]="Chest",[4]="Pelvis"}
    local CONDITION_NAMES = {[1]="Hold Fire",[2]="Always"}

    function BuildAimMenu()
        if aimBuilt and aimPanel and IsValid(aimPanel) then
            pcall(function() aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
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
                    slot:SetAutoSize(false) slot:SetZOrder(10001)
                    local anchored = false
                    pcall(function() slot:SetAnchors({Minimum=FVector2D(1,0),Maximum=FVector2D(1,0)}) anchored=true end)
                    if anchored then slot:SetAlignment(FVector2D(1,0)) slot:SetPosition(FVector2D(-20,20))
                    else slot:SetAlignment(FVector2D(0,0)) slot:SetPosition(FVector2D(1920 - AIM_W - 20, 20)) end
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
            isAimOpen=false isMenuOpen=true
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if bgPanel and IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
        end)
        LayerInto(aimPanel, aimWidgets, 20,24, 60,22, C.btn_back, 350)
        TextInto(aimPanel, aimWidgets, "< BACK", 50, 35, 14, C.text_light, 400, 0.5, 0.5)
        MakeBtnInto(aimPanel, aimWidgets, AIM_W-40,20, 30,30, 900, function()
            isAimOpen=false isMenuOpen=false
            if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            if bgPanel and IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        end)
        TextInto(aimPanel, aimWidgets, "X", AIM_W-25, 35, 20, C.close_btn, 400, 0.5, 0.5)

        local contentX = 12
        local contentW = AIM_W - 24
        local tabY = HEADER_H + 8
        local tabW = (contentW - 12) / 4
        local tabH = 34
        local tabButtons = {}
        local tabPanels = {}

        local function SwitchAimTab(mode)
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
            MakeBtnInto(aimPanel, aimWidgets, tx, tabY, tabW, tabH, 900, function() SwitchAimTab(mode) end)
            tabButtons[mode] = { bg = bg, label = label }
        end

        for _, mode in ipairs(AIM_MODES) do
            local cfg = _G.XTEAMConfig.AimModes[mode]
            local tp = tabPanels[mode]
            if tp and slua.isValid(tp) then
                local x, w, y = contentX, contentW, 0

                MakeConfigToggle(tp, aimWidgets, cfg, "Enable", "Enable", x, y, w, AIM_ROW_H, false)
                y = y + AIM_ROW_H + 4
                MakeConfigToggle(tp, aimWidgets, cfg, "IgKnock", "Ignore Knocked", x, y, w, AIM_ROW_H, true)
                y = y + AIM_ROW_H + 4
                MakeConfigToggle(tp, aimWidgets, cfg, "IgBot", "Ignore Bots", x, y, w, AIM_ROW_H, false)
                y = y + AIM_ROW_H + 4
                MakeConfigToggle(tp, aimWidgets, cfg, "VisCheck", "Visibility Check", x, y, w, AIM_ROW_H, true)
                y = y + AIM_ROW_H + 4

                MakeConfigSlider(tp, aimWidgets, cfg, "Priority", "Priority", 1, 4, 1,
                    function(v) return "Value: " .. (PRIORITY_NAMES[v] or "?") .. " (" .. v .. "/4)" end,
                    x, y, w, AIM_ROW_H, false)
                y = y + AIM_ROW_H + 4

                MakeConfigSlider(tp, aimWidgets, cfg, "Bone", "Bone", 1, 4, 1,
                    function(v) return "Value: " .. (BONE_NAMES[v] or "?") .. " (" .. v .. "/4)" end,
                    x, y, w, AIM_ROW_H, true)
                y = y + AIM_ROW_H + 4

                MakeConfigSlider(tp, aimWidgets, cfg, "Condition", "Condition", 1, 2, 1,
                    function(v) return "Value: " .. (CONDITION_NAMES[v] or "?") .. " (" .. v .. "/2)" end,
                    x, y, w, AIM_ROW_H, false)
                y = y + AIM_ROW_H + 4

                MakeConfigSlider(tp, aimWidgets, cfg, "Speed", "Speed", 1, 100, 5,
                    function(v) return "Value: " .. v end,
                    x, y, w, AIM_ROW_H, true)
                y = y + AIM_ROW_H + 4

                MakeConfigSlider(tp, aimWidgets, cfg, "FOV", "FOV", 1, 100, 1,
                    function(v) return "Value: " .. v end,
                    x, y, w, AIM_ROW_H, false)
            end
        end

        LayerInto(aimPanel, aimWidgets, 2, AIM_H-32, AIM_W-4, 30, C.bg_header, 5)
        TextInto(aimPanel, aimWidgets, "Tabs switch per weapon mode", AIM_W*0.5, AIM_H-15, 12, C.text_purple, 400, 0.5, 0.5)

        aimBuilt = true
        isAimOpen = true
        SwitchAimTab("Hipfire")
    end

    local function CreateFloat()
        if floatItem and floatItem.btn and IsValid(floatItem.btn) then return end
        floatItem = nil
        pcall(function()
            local canvas = GetCanvas()
            if not canvas then return end
            floatItem = {}
            local fX, fY, fW, fH = 20, 15, 110, 45
            floatItem.s8 = LayerInto(canvas, nil, fX, fY, fW, fH, FLinearColor(0.96, 0.96, 0.96, 0.75), 11902)
            LayerInto(canvas, nil, fX, fY, fW, 4, C.border_blue, 11903)
            LayerInto(canvas, nil, fX, fY, fW, 2, C.border_blue, 11904)
            LayerInto(canvas, nil, fX, fY + fH - 2, fW, 2, C.border_blue, 11904)
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
                                    if isAimOpen then
                                        isAimOpen = false isMenuOpen = false
                                        if aimPanel and IsValid(aimPanel) then aimPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                        if bgPanel and IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                        return
                                    end
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

print("[FINAL ESP+AIM] Per-mode aimbot submenu ready")
