if _G.XTEAM_LOADER_LOADED then return end
_G.XTEAM_LOADER_LOADED = true

local NADEEM_TAG = "[OFFICIAL NADEEM]"
local NADEEM_MSG_KEY = 896211

local NADEEM_CANDIDATE_PATHS = {
  -- com.tencent.ig (Global)
  "/storage/emulated/0/Android/data/com.tencent.ig/files/NADEEM.lua",
  "//storage/emulated/0/Android/data/com.tencent.ig/files/NADEEM.lua",
  "/sdcard/Android/data/com.tencent.ig/files/NADEEM.lua",
  "/storage/emulated/0/Android/data/com.tencent.ig/files/nadeem.lua",

  -- com.vng.pubgmobile (Vietnam)
  "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/NADEEM.lua",
  "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/NADEEM.lua",
  "/sdcard/Android/data/com.vng.pubgmobile/files/NADEEM.lua",
  "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/nadeem.lua",

  -- com.pubg.imobile (BGMI / India)
  "/storage/emulated/0/Android/data/com.pubg.imobile/files/NADEEM.lua",
  "//storage/emulated/0/Android/data/com.pubg.imobile/files/NADEEM.lua",
  "/sdcard/Android/data/com.pubg.imobile/files/NADEEM.lua",
  "/storage/emulated/0/Android/data/com.pubg.imobile/files/nadeem.lua",

  -- com.pubg.krmobile (Korea / Japan)
  "/storage/emulated/0/Android/data/com.pubg.krmobile/files/NADEEM.lua",
  "//storage/emulated/0/Android/data/com.pubg.krmobile/files/NADEEM.lua",
  "/sdcard/Android/data/com.pubg.krmobile/files/NADEEM.lua",

  -- com.rekoo.pubgm (Taiwan)
  "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/NADEEM.lua",
  "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/NADEEM.lua",
  "/sdcard/Android/data/com.rekoo.pubgm/files/NADEEM.lua",

  -- UE4 Saved directories fallback
  "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/NADEEM.lua",
  "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/NADEEM.lua",
  "/storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/NADEEM.lua",
}

local function ShowNadeemLoading(percent, statusText, isError)
  local msg = string.format("%s Loading: %d%% - %s", NADEEM_TAG, percent, statusText or "")
  
  local color = { R = 1, G = 1, B = 0, A = 1 } -- Yellow
  if isError then
    color = { R = 1, G = 0.2, B = 0.2, A = 1 } -- Red
  elseif percent >= 100 then
    color = { R = 0.1, G = 1, B = 0.2, A = 1 } -- Bright Green
  elseif percent >= 60 then
    color = { R = 0, G = 0.85, B = 1, A = 1 } -- Cyan
  end

  -- 1. On-Screen Debug Message (In-place update using fixed key)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      local duration = (percent >= 100 or isError) and 6.0 or 3.5
      sh.AddOnScreenDebugMessage(msg, NADEEM_MSG_KEY, duration, color, { X = 1.35, Y = 1.35 })
    end
  end)

  -- 2. GTLModNotify
  pcall(function()
    if _G.GTLModNotify then
      _G.GTLModNotify(msg)
    end
  end)

  print(msg)
end

local function NadeemRunLater(sec, fn)
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

local function LoadNadeemLuaFromPath()
  if _G._NADEEM_LUA_LOADED then return end
  _G._NADEEM_LUA_LOADED = true
  _G._ModChunks = _G._ModChunks or {}

  -- Step 1: 15% - Spawned on Game Island
  ShowNadeemLoading(15, "Game Island reached, searching NADEEM.lua...")

  NadeemRunLater(0.35, function()
    -- Step 2: Search candidate paths
    local targetPath = nil
    for _, path in ipairs(NADEEM_CANDIDATE_PATHS) do
      local f = io.open(path, "r")
      if f then
        f:close()
        targetPath = path
        break
      end
    end

    if not targetPath then
      ShowNadeemLoading(0, "ERROR: NADEEM.lua not found in files/ path!", true)
      pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
          Msg.Show(4, "NADEEM LOADER ERROR", "NADEEM.lua not found!\n\nPlease put NADEEM.lua in:\n/storage/emulated/0/Android/data/<package>/files/NADEEM.lua\n\nPackages:\n- com.tencent.ig\n- com.vng.pubgmobile\n- com.pubg.imobile", function() end)
        end
      end)
      return
    end

    local displayPath = targetPath:match("([^/]+/[^/]+/files/.*)$") or targetPath
    ShowNadeemLoading(45, "Found: " .. displayPath)

    NadeemRunLater(0.35, function()
      -- Step 3: 70% - Read file from storage
      ShowNadeemLoading(70, "Reading NADEEM.lua into memory...")
      local file, err = io.open(targetPath, "rb")
      if not file then
        ShowNadeemLoading(0, "ERROR reading file: " .. tostring(err), true)
        return
      end
      local content = file:read("*a")
      file:close()

      if not content or #content == 0 then
        ShowNadeemLoading(0, "ERROR: NADEEM.lua is empty!", true)
        return
      end

      NadeemRunLater(0.35, function()
        -- Step 4: 85% - Compile chunk
        ShowNadeemLoading(85, string.format("Compiling script (%d KB)...", math.floor(#content / 1024)))
        local load_fn = loadstring or load
        local chunk, compileErr = load_fn(content, "=NADEEM.lua")

        if not chunk then
          ShowNadeemLoading(0, "Syntax Error: " .. tostring(compileErr), true)
          return
        end

        _G._ModChunks["NADEEM.lua"] = chunk

        NadeemRunLater(0.35, function()
          -- Step 5: 95% - Execute chunk
          ShowNadeemLoading(95, "Starting mod systems & hooks...")
          local ok, runErr = pcall(chunk)

          if not ok then
            ShowNadeemLoading(0, "Runtime Error: " .. tostring(runErr), true)
            return
          end

          -- Step 6: 100% - Successfully Loaded!
          ShowNadeemLoading(100, "NADEEM.lua Loaded Successfully!")

          -- Welcome Popup
          pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
              Msg.Show(1, "OFFICIAL NADEEM", "MOD MENU SYSTEM SUCCESSFULLY LOADED (100%)\n\nWelcome to Game Island!", function() end, function() end, "OK", "SKIP")
            end
          end)
        end)
      end)
    end)
  end)
end
