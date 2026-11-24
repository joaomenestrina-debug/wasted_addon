--[[
    Korum Wasted - quips

    Short captions for moments of the game, picked at random from a list of well-known lines: low health, a streak of deaths,
    a rare item, a dungeon, the hearthstone... Each moment has its own switch, a minimum time between two captions, and for
    the common ones (mounting up) a chance instead of every time. A caption never covers a big sign: it is dropped.

    The lines of each moment come from Locales.lua (KW.QUIP_LINES, per language); the player may write their own in the window
    (db.quipLines[id], one per line), and then those are used whatever the language. A sound file named quip_<id> in Sounds/
    plays with the caption when it is there (none comes with the addon).

    Nothing here reads the combat log (this client keeps it from addons): only the player's own state and the game's events.
]]

local addonName, KW = ...
local Q = {}
KW.Quips = Q

-- id, seconds between two captions of it, chance (nil = always)
Q.MOMENTS = {
    {id = "lowhp", cooldown = 120},
    {id = "deaths", cooldown = 300},
    {id = "partydeath", cooldown = 60},
    {id = "wipe", cooldown = 120},
    {id = "revive", cooldown = 60},
    {id = "breath", cooldown = 120},
    {id = "fall", cooldown = 60},
    {id = "loot", cooldown = 60},
    {id = "spend", cooldown = 300},
    {id = "bagsfull", cooldown = 300},
    {id = "login", cooldown = 0},
    {id = "dungeon", cooldown = 120},
    {id = "highzone", cooldown = 300},
    {id = "hearth", cooldown = 60},
    {id = "mount", cooldown = 300, chance = 0.25},
    {id = "afk", cooldown = 120},
}
local BY_ID = {}
for _, m in ipairs(Q.MOMENTS) do BY_ID[m.id] = m end

local function Now() return GetTime and GetTime() or 0 end
local last = {}

function Q:Enabled(id)
    local db = KW.db
    if not (db and db.quips ~= false) then return false end
    return not (db.quipOff and db.quipOff[id])
end

-- the lines of a moment: the player's own, else the ones of the language
function Q:Lines(id)
    local own = KW.db and KW.db.quipLines and KW.db.quipLines[id]
    if type(own) == "table" and #own > 0 then return own, true end
    local lang = KW.QUIP_LINES[KW.Lang()] or KW.QUIP_LINES.enUS
    return lang[id] or KW.QUIP_LINES.enUS[id] or {}, false
end

function Q:SetLines(id, text)
    local db = KW.db
    db.quipLines = db.quipLines or {}
    local lines = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then lines[#lines + 1] = line end
    end
    db.quipLines[id] = #lines > 0 and lines or nil
end

local pick = 0
local function Pick(lines)
    if #lines == 0 then return nil end
    local roll = (KW.Random or math.random)(#lines)
    -- not the same one twice in a row, when there is another
    if #lines > 1 and roll == pick then roll = roll % #lines + 1 end
    pick = roll
    return lines[roll]
end

-- Says a line of the moment, when it may. force: the test button (no cooldown, no chance). arg: what "%s" becomes.
function Q:Say(id, arg, force)
    local m = BY_ID[id]
    if not m or not KW.db then return false end
    if not force then
        if not self:Enabled(id) then return false end
        if last[id] and Now() - last[id] < m.cooldown then return false end
        if m.chance and (KW.Roll or math.random)() > m.chance then return false end
        if KW.Screen:Busy() or KW.Screen.moving then return false end
    end
    local line = Pick((self:Lines(id)))
    if not line then return false end
    if line:find("%%s") then
        local ok, done = pcall(string.format, line, tostring(arg or "..."))
        line = ok and done or line
    end
    last[id] = Now()
    -- said by the character in a balloon, or as a caption low on the screen
    if KW.db.quipStyle == "caption" then
        KW.Screen:Caption(line, "", "quip_" .. id)
    else
        KW.Screen:Bubble(line, "quip_" .. id)
    end
    return true
end

-- every moment may have a sound of the player's own
for _, m in ipairs(Q.MOMENTS) do KW.SOUNDS["quip_" .. m.id] = {file = "quip_" .. m.id} end

-- ----------------------------------------------------------------------------
-- The moments
-- ----------------------------------------------------------------------------
local function Safe(fn, ...)
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    return nil
end

-- low health in a fight
KW:On("UNIT_HEALTH", function(_, unit)
    if unit == "player" then
        if Q.LowHealth() then Q:Say("lowhp") end
        return
    end
    -- someone of the group died (in a fight the game may hide who and how: then nothing is said)
    if type(unit) == "string" and (unit:find("^party%d") or unit:find("^raid%d")) then pcall(Q.CheckGroup, Q, unit) end
end)

-- Is the player low on health, in a fight? In a fight this client hands the health as a secret number: it cannot be
-- compared, and trying is an error. Then the answer is the game's own low-health warning (the red edge of the screen).
local function HealthLow()
    local hp, max = UnitHealth("player"), UnitHealthMax("player")
    return max > 0 and hp > 0 and hp / max < 0.2
end
function Q.LowHealth()
    local okFight, fight = pcall(function() return UnitAffectingCombat("player") and true or false end)
    if not (okFight and fight) then return false end
    local ok, low = pcall(HealthLow)
    if ok then return low and true or false end
    local warn = _G.LowHealthFrame
    local okShown, shown = pcall(function() return warn and warn:IsShown() and true or false end)
    return okShown and shown or false
end

local deadMates = {}
function Q:CheckGroup(unit)
    local guid = Safe(UnitGUID, unit)
    if type(guid) ~= "string" then return end
    local dead = Safe(UnitIsDeadOrGhost, unit) and true or false
    if dead and not deadMates[guid] then
        deadMates[guid] = true
        if not (UnitIsUnit and Safe(UnitIsUnit, unit, "player")) then self:Say("partydeath") end
    elseif not dead then
        deadMates[guid] = nil
    end
end

-- Is the whole group dead (and is there a group)?
function Q:Wiped()
    local n = (GetNumGroupMembers and Safe(GetNumGroupMembers)) or 0
    if type(n) ~= "number" or n < 2 then return false end
    local raid = IsInRaid and Safe(IsInRaid)
    for i = 1, raid and n or (n - 1) do
        local unit = (raid and "raid" or "party") .. i
        if Safe(UnitExists, unit) and not Safe(UnitIsDeadOrGhost, unit) then return false end
    end
    return true
end

-- deaths: three in ten minutes. The caption waits for the graveyard (the big sign is on the screen when dying):
-- KW asks Q:AfterDeath() what to say there in place of the usual line.
local deaths = {}
local pending
KW:On("PLAYER_DEAD", function()
    local now = Now()
    deaths[#deaths + 1] = now
    while deaths[1] and now - deaths[1] > 600 do table.remove(deaths, 1) end
    local okWipe, wiped = pcall(Q.Wiped, Q)
    if okWipe and wiped then pending = "wipe"
    elseif #deaths >= 3 then pending = "deaths"; deaths = {}
    else pending = nil end
    Q.wasDead = true
end)

-- The moment to say at the graveyard in place of the usual line, or nil. Consumed.
function Q:AfterDeath()
    local id = pending
    pending = nil
    if id and self:Enabled(id) and not (last[id] and Now() - last[id] < BY_ID[id].cooldown) then return id end
    return nil
end

-- back on the spot (resurrected, not by walking as a ghost)
KW:On("PLAYER_ALIVE", function()
    if not Q.wasDead then return end
    if UnitIsGhost and Safe(UnitIsGhost, "player") then return end
    Q.wasDead = false
    pending = nil
    KW.After(1.2, function() Q:Say("revive") end)
end)
KW:On("PLAYER_UNGHOST", function() Q.wasDead = false end)

-- breath running out: asked a while after going under
KW:On("MIRROR_TIMER_START", function(_, timer, value)
    if timer ~= "BREATH" or type(value) ~= "number" then return end
    local wait = math.max(2, value / 1000 * 0.6)
    KW.After(wait, function()
        local under = (IsSubmerged and Safe(IsSubmerged)) or (IsSwimming and Safe(IsSwimming))
        local left = GetMirrorTimerProgress and Safe(GetMirrorTimerProgress, "BREATH")
        if under and (type(left) ~= "number" or left > 0) then Q:Say("breath") end
    end)
end)

-- a long fall, mounting up: looked at a few times a second
local watcher = CreateFrame("Frame")
local acc, falling, said = 0, 0, false
watcher:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 0.25 then return end
    local step = acc
    acc = 0
    if IsFalling and Safe(IsFalling) and not (IsFlying and Safe(IsFlying)) then
        falling = falling + step
        if falling >= 2 and not said then said = true; Q:Say("fall") end
    else
        falling, said = 0, false
    end
end)
Q.watcher = watcher

-- a rare item or better: the quality is in the link ("|cnIQ3:" in the new links, the colour in the old ones)
local COLOR_QUALITY = {["0070dd"] = 3, ["a335ee"] = 4, ["ff8000"] = 5}
function Q.LinkQuality(text)
    if type(text) ~= "string" then return nil end
    local q = text:match("|cnIQ(%d):")
    if q then return tonumber(q) end
    local hex = text:match("|c%x%x(%x%x%x%x%x%x)|Hitem:")
    return hex and COLOR_QUALITY[hex:lower()] or nil
end

KW:On("CHAT_MSG_LOOT", function(_, text, _, _, _, who, _, _, _, _, _, _, guid)
    local q = Q.LinkQuality(text)
    if not q or q < 3 then return end
    local me, myName = Safe(UnitGUID, "player"), Safe(UnitName, "player")
    local mine = (type(guid) == "string" and guid == me) or (type(who) == "string" and myName and who:match("^[^-]+") == myName)
    if mine then Q:Say("loot") end
end)

-- an expensive purchase or repair: the gold drops a lot at once, with a merchant or a trainer open
local money
KW:On("PLAYER_MONEY", function()
    local now = GetMoney and Safe(GetMoney)
    if type(now) ~= "number" then return end
    local before = money
    money = now
    if not before or now >= before then return end
    local spent = before - now
    local shop = (_G.MerchantFrame and MerchantFrame:IsShown()) or (_G.ClassTrainerFrame and ClassTrainerFrame:IsShown())
    if shop and spent >= 5000 and spent >= before * 0.05 then Q:Say("spend") end
end)

KW:On("UI_ERROR_MESSAGE", function(_, _, text)
    if type(text) == "string" and (text == _G.ERR_INV_FULL or text == _G.INVENTORY_FULL) then Q:Say("bagsfull") end
end)

-- logging in, walking into a dungeon
local inside
KW:On("PLAYER_ENTERING_WORLD", function(_, initial)
    money = GetMoney and Safe(GetMoney) or money
    local inInstance, kind = false, nil
    if IsInInstance then inInstance, kind = Safe(IsInInstance) end
    local dungeon = inInstance and (kind == "party" or kind == "raid") or false
    if initial then
        KW.After(6, function() Q:Say("login") end)
    elseif dungeon and inside == false then
        KW.After(2, function() Q:Say("dungeon") end)
    end
    inside = dungeon
end)

-- a zone well above the character's level
KW:On("ZONE_CHANGED_NEW_AREA", function()
    if not (_G.C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapLevels) then return end
    local map = Safe(C_Map.GetBestMapForUnit, "player")
    if not map then return end
    local low = Safe(C_Map.GetMapLevels, map)
    local level = UnitLevel and Safe(UnitLevel, "player")
    if type(low) == "number" and type(level) == "number" and low >= level + 4 then
        Q:Say("highzone", (GetRealZoneText and Safe(GetRealZoneText)) or "")
    end
end)

-- the hearthstone
local HEARTH = {[8690] = true}
KW:On("UNIT_SPELLCAST_START", function(_, unit, _, spell)
    if unit == "player" and type(spell) == "number" and HEARTH[spell] then Q:Say("hearth") end
end)

KW:On("PLAYER_MOUNT_DISPLAY_CHANGED", function()
    if IsMounted and Safe(IsMounted) then Q:Say("mount") end
end)

local wasAfk = false
KW:On("PLAYER_FLAGS_CHANGED", function(_, unit)
    if unit ~= "player" or not UnitIsAFK then return end
    local afk = Safe(UnitIsAFK, "player") and true or false
    if afk and not wasAfk then Q:Say("afk") end
    wasAfk = afk
end)
