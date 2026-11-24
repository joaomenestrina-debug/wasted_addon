--[[
    Korum Wasted - a tela

    Três peças, todas sem pegar o mouse (nada atrapalha clicar na janela de soltar o espírito):
        o cinza      uma camada sobre o mundo, abaixo da interface (o mundo fica cinza, as janelas não);
        a faixa      a tarja escura atrás do letreiro da morte;
        o letreiro   o texto grande, que entra crescendo e some devagar.

    Uma animação de cada vez: a nova toma o lugar da que estava (uma missão entregue logo após reviver, por exemplo).
]]

local addonName, KW = ...
local S = {}
KW.Screen = S

local RED = {0.80, 0.07, 0.07}
local GOLD = {1, 0.80, 0.20}
local BLUE = {0.22, 0.48, 0.95}
local WHITE = {1, 1, 1}
local GAME_FONT = "Fonts\\FRIZQT__.TTF"

local gray, band, sign
local anim                 -- {t, steps...}: what is under way

-- the player's own font for the signs when there is one in Fonts/ (sign.ttf or sign.otf), else the game's
local function SetFont(fs, size)
    for _, ext in ipairs({".ttf", ".otf"}) do
        local ok, set = pcall(fs.SetFont, fs, KW.DIR .. "Fonts\\sign" .. ext, size, "OUTLINE")
        local now = ok and set ~= false and fs:GetFont()
        if type(now) == "string" and now:lower():find("sign" .. ext, 1, true) then
            S.font = "sign" .. ext
            return
        end
    end
    S.font = nil
    fs:SetFont(GAME_FONT, size, "THICKOUTLINE")
end

local function Build()
    if sign then return end
    -- the world goes gray: a layer under every window
    gray = CreateFrame("Frame", "KorumWastedGray", UIParent)
    gray:SetAllPoints(UIParent)
    gray:SetFrameStrata("BACKGROUND")
    gray:SetFrameLevel(0)
    gray:EnableMouse(false)
    gray.fill = gray:CreateTexture(nil, "BACKGROUND")
    gray.fill:SetAllPoints(gray)
    gray.fill:SetColorTexture(0.42, 0.42, 0.42, 1)
    gray:SetAlpha(0)
    gray:Hide()

    -- the dark band across the middle
    band = CreateFrame("Frame", "KorumWastedBand", UIParent)
    band:SetPoint("LEFT", UIParent, "LEFT")
    band:SetPoint("RIGHT", UIParent, "RIGHT")
    band:SetHeight(150)
    band:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    band:SetFrameStrata("HIGH")
    band:EnableMouse(false)
    band.fill = band:CreateTexture(nil, "BACKGROUND")
    band.fill:SetAllPoints(band)
    band.fill:SetColorTexture(0, 0, 0, 0.55)
    band:SetAlpha(0)
    band:Hide()

    -- the big words
    sign = CreateFrame("Frame", "KorumWastedSign", UIParent)
    sign:SetSize(10, 10)
    sign:SetFrameStrata("HIGH")
    sign:SetFrameLevel(20)
    sign:EnableMouse(false)
    sign.text = sign:CreateFontString(nil, "OVERLAY")
    sign.text:SetPoint("CENTER", sign, "CENTER", 0, 0)
    sign.text:SetShadowOffset(4, -4)
    sign.text:SetShadowColor(0, 0, 0, 1)
    sign.sub = sign:CreateFontString(nil, "OVERLAY")
    sign.sub:SetPoint("TOP", sign.text, "BOTTOM", 0, -10)
    sign.sub:SetShadowOffset(3, -3)
    sign.sub:SetShadowColor(0, 0, 0, 1)
    sign:SetAlpha(0)
    sign:Hide()

    -- one driver for every animation
    sign:SetScript("OnUpdate", function(_, elapsed) S:Step(elapsed or 0) end)
    S.driver = CreateFrame("Frame")
    S.driver:SetScript("OnUpdate", function(_, elapsed) if anim and not sign:IsShown() then S:Step(elapsed or 0) end end)
end

local function Paint(fs, color) fs:SetTextColor(color[1], color[2], color[3], 1) end

-- ----------------------------------------------------------------------------
-- Where each kind of sign goes: an offset from the middle of the screen. The player may move the three of them
-- (db.pos[kind] = {x, y}); without that, the places below.
--     death     the sign of the death (and the dark band behind it)
--     card      mission passed, mission failed, level up
--     caption   the line of the graveyard, and the quips when they are captions
--     bubble    the quips as a speech balloon: its tail ends here (over the head of the character, by default)
-- ----------------------------------------------------------------------------
S.KINDS = {"death", "card", "caption", "bubble"}
S.DEFAULT_POS = {death = {0, 40}, card = {0, 170}, caption = {0, -230}, bubble = {0, 120}}

function S:Pos(kind)
    local own = KW.db and KW.db.pos and KW.db.pos[kind]
    local def = S.DEFAULT_POS[kind]
    if type(own) == "table" and tonumber(own[1]) and tonumber(own[2]) then return tonumber(own[1]), tonumber(own[2]), true end
    if kind == "bubble" then return 0, S:HeadY(), false end
    return def[1], def[2], false
end

-- Where the top of the character's head is on the screen, above the middle. The game does not tell where the character
-- is drawn, but its camera turns around the character's head: the head stays near the middle of the screen, and what is
-- above it (the top of the head, the name) is higher the closer the camera is. So the height comes from the zoom.
function S:HeadY()
    local zoom
    if _G.GetCameraZoom then
        local ok, z = pcall(GetCameraZoom)
        if ok and type(z) == "number" then zoom = z end
    end
    zoom = math.max(3, zoom or 15)
    return math.floor(26 + 500 / zoom + 0.5)   -- 26: the tail ends above the name over the character, not on it
end

function S:SetPos(kind, x, y)
    if not (S.DEFAULT_POS[kind] and KW.db) then return end
    KW.db.pos = KW.db.pos or {}
    KW.db.pos[kind] = {math.floor((tonumber(x) or 0) + 0.5), math.floor((tonumber(y) or 0) + 0.5)}
end

function S:ResetPos()
    if KW.db then KW.db.pos = nil end
    if S.movers then S:PlaceMovers() end
end

-- the sign at the place of its kind, with a scale, so it can grow in place
local function Place(kind, scale)
    local x, y = S:Pos(kind)
    sign:SetScale(scale)
    sign:ClearAllPoints()
    sign:SetPoint("CENTER", UIParent, "CENTER", x / scale, y / scale)
    S.at = {kind = kind, x = x, y = y}
end

-- the band crosses the whole screen at the height of the sign of the death
local function PlaceBand()
    local _, y = S:Pos("death")
    band:ClearAllPoints()
    band:SetPoint("LEFT", UIParent, "LEFT", 0, y)
    band:SetPoint("RIGHT", UIParent, "RIGHT", 0, y)
end

-- ----------------------------------------------------------------------------
-- Moving them: three boxes on the screen, one per kind, dragged with the mouse; a small bar ends it.
-- ----------------------------------------------------------------------------
local MOVER_COLOR = {death = RED, card = GOLD, caption = BLUE, bubble = WHITE}

function S:PlaceMovers()
    for kind, m in pairs(S.movers or {}) do
        local x, y = S:Pos(kind)
        m:ClearAllPoints()
        m:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
end

local function BuildMovers()
    if S.movers then return end
    S.movers = {}
    for _, kind in ipairs(S.KINDS) do
        local m = CreateFrame("Frame", nil, UIParent)
        m:SetSize(430, 74)
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        m:SetMovable(true)
        m:EnableMouse(true)
        m:SetClampedToScreen(true)
        m:RegisterForDrag("LeftButton")
        local c = MOVER_COLOR[kind]
        m.fill = m:CreateTexture(nil, "BACKGROUND")
        m.fill:SetAllPoints(m)
        m.fill:SetColorTexture(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.85)
        m.edge = m:CreateTexture(nil, "BORDER")
        m.edge:SetPoint("TOPLEFT"); m.edge:SetPoint("TOPRIGHT")
        m.edge:SetHeight(3)
        m.edge:SetColorTexture(c[1], c[2], c[3], 1)
        m.label = m:CreateFontString(nil, "OVERLAY")
        m.label:SetFont(GAME_FONT, 14, "OUTLINE")
        m.label:SetPoint("LEFT", 12, 0); m.label:SetPoint("RIGHT", -12, 0)
        m.label:SetJustifyH("CENTER")
        m.label:SetWordWrap(true)
        m:SetScript("OnDragStart", function(self) self:StartMoving() end)
        m:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local x, y = self:GetCenter()
            local ux, uy = UIParent:GetCenter()
            if x and y and ux and uy then S:SetPos(kind, x - ux, y - uy) end
            S:PlaceMovers()
        end)
        m:Hide()
        S.movers[kind] = m
    end
    -- the bar that ends it
    local bar = CreateFrame("Frame", nil, UIParent)
    bar:SetSize(560, 86)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -40)
    bar:SetFrameStrata("FULLSCREEN_DIALOG")
    bar:SetFrameLevel(50)
    bar:EnableMouse(true)
    bar.fill = bar:CreateTexture(nil, "BACKGROUND")
    bar.fill:SetAllPoints(bar)
    bar.fill:SetColorTexture(0.05, 0.06, 0.08, 0.94)
    bar.hint = bar:CreateFontString(nil, "OVERLAY")
    bar.hint:SetFont(GAME_FONT, 12, "")
    bar.hint:SetPoint("TOPLEFT", 14, -10); bar.hint:SetPoint("TOPRIGHT", -14, -10)
    bar.hint:SetJustifyH("CENTER")
    bar.hint:SetWordWrap(true)
    local Kit = KW.Kit
    bar.done = Kit.Button(bar, 150, 26, "", function() S:Movers(false) end)
    bar.done:SetPoint("BOTTOMRIGHT", bar, "BOTTOM", -4, 10)
    bar.done:SetAccent(true)
    bar.reset = Kit.Button(bar, 190, 26, "", function() S:ResetPos() end)
    bar.reset:SetPoint("BOTTOMLEFT", bar, "BOTTOM", 4, 10)
    bar:Hide()
    S.moverBar = bar
end

-- show or hide the boxes. after: called when they are put away (the window comes back).
function S:Movers(show, after)
    if show then
        Build()
        BuildMovers()
        if anim then anim = nil end
        sign:Hide(); band:Hide(); gray:Hide()
        S:HideBubble()
        S.afterMove = after
        for kind, m in pairs(S.movers) do
            m.label:SetText(KW.T("mover_" .. kind))
            m:Show()
        end
        S.moverBar.hint:SetText(KW.T("moverHint"))
        S.moverBar.done:SetLabel(KW.T("moverDone"))
        S.moverBar.reset:SetLabel(KW.T("posReset"))
        S.moverBar:Show()
        S:PlaceMovers()
        S.moving = true
    elseif S.movers then
        for _, m in pairs(S.movers) do m:Hide() end
        S.moverBar:Hide()
        S.moving = false
        local fn = S.afterMove
        S.afterMove = nil
        if fn then fn() end
    end
end

local function Ease(x) return 1 - (1 - x) * (1 - x) end

-- ----------------------------------------------------------------------------
-- The animations: a list of timed steps, each with a function of its progress (0 to 1)
-- ----------------------------------------------------------------------------
function S:Step(elapsed)
    if not anim then return end
    anim.t = anim.t + elapsed
    local done = true
    for _, st in ipairs(anim.steps) do
        local p = (anim.t - st.at) / math.max(st.len, 0.001)
        if p < 0 then
            done = false
        elseif p <= 1 or not st.fired then
            st.fn(math.min(1, math.max(0, p)))
            st.fired = p >= 1
            if p < 1 then done = false end
        end
    end
    if done then
        local after = anim.after
        anim = nil
        if after then after() end
    end
end

local function Run(steps, after)
    anim = {t = 0, steps = steps, after = after}
end

-- ----------------------------------------------------------------------------
-- Morte
-- ----------------------------------------------------------------------------
-- test: the gray goes away by itself (nobody died)
-- busted: a guard or a player did it: the blue sign and its sound in place of the red one
function S:Wasted(test, busted)
    Build()
    S:HideBubble()
    local db = KW.db
    SetFont(sign.text, 92)
    SetFont(sign.sub, 26)
    sign.text:SetWidth(0)
    Paint(sign.text, busted and BLUE or RED)
    Paint(sign.sub, WHITE)
    sign.text:SetText(KW:SignText(busted and "bustedText" or "deathText"))
    sign.sub:SetText(busted and "" or KW:SignText("deathSub"))
    sign:SetAlpha(0); band:SetAlpha(0)
    PlaceBand()
    sign:Show(); band:Show()
    if db.gray then gray:SetAlpha(0); gray:Show() end
    local hold = tonumber(db.hold) or 6
    local played = false
    Run({
        {at = 0, len = 1.4, fn = function(p) if db.gray then gray:SetAlpha(0.55 * Ease(p)) end end},
        {at = 0.9, len = 0.35, fn = function(p)
            if not played then played = true; KW:Play(busted and "busted" or "death") end
            band:SetAlpha(Ease(p))
            sign:SetAlpha(Ease(p))
            Place("death", 1.35 - 0.35 * Ease(p))
        end},
        {at = 0.9 + 0.35 + hold, len = 1.0, fn = function(p)
            sign:SetAlpha(1 - p)
            band:SetAlpha(1 - p)
        end},
    }, function()
        sign:Hide(); band:Hide()
        if test then S:FadeGray() end
    end)
end

function S:FadeGray()
    if not (gray and gray:IsShown()) then return end
    local from = gray:GetAlpha() or 0.55
    Run({{at = 0, len = 0.8, fn = function(p) gray:SetAlpha(from * (1 - p)) end}}, function() gray:Hide() end)
end

-- alive again (or a ghost): everything goes
function S:Clear()
    if not gray then return end
    if sign:IsShown() then
        anim = nil
        sign:Hide(); band:Hide()
    end
    S:FadeGray()
end

-- ----------------------------------------------------------------------------
-- Missão cumprida, respeito
-- ----------------------------------------------------------------------------
local function Card(title, sub, moment, titleColor)
    Build()
    S:HideBubble()
    if gray:IsShown() and not anim then gray:Hide() end
    SetFont(sign.text, 64)
    SetFont(sign.sub, 34)
    sign.text:SetWidth(0)
    Paint(sign.text, titleColor)
    Paint(sign.sub, WHITE)
    sign.text:SetText(title or "")
    sign.sub:SetText(sub or "")
    band:Hide()
    sign:SetAlpha(0)
    sign:Show()
    local played = false
    Run({
        {at = 0, len = 0.3, fn = function(p)
            if not played then played = true; KW:Play(moment) end
            sign:SetAlpha(Ease(p))
            Place("card", 1.2 - 0.2 * Ease(p))
        end},
        {at = 4.3, len = 0.7, fn = function(p) sign:SetAlpha(1 - p) end},
    }, function() sign:Hide() end)
end

function S:Mission()
    local db = KW.db
    Card(KW:SignText("questText"), KW:SignText("respectText"), "quest", GOLD)
end

-- a quest abandoned or failed: the red sign, with the name of the quest under it when the game tells it
function S:Failed(name)
    Card(KW:SignText("failedText"), type(name) == "string" and name or "", "failed", RED)
end

function S:Respect(level)
    local db = KW.db
    local fmt = KW:SignText("levelText")
    local ok, sub = pcall(string.format, fmt, tonumber(level) or 0)       -- a text typed without %d is shown as it is
    Card(KW:SignText("respectText"), (fmt ~= "" and (ok and sub or fmt)) or "", "level", GOLD)
end

-- The line said when the spirit is released: a caption low on the screen, like the subtitles of the game
function S:Quote()
    self:Caption(KW:SignText("ghostText"), KW:SignText("ghostSub"), "ghost")
end

-- A caption low on the screen: a line, an optional credit under it, and the sound of the moment. A long line wraps: it is
-- never cut.
function S:Caption(text, sub, moment)
    Build()
    gray:Hide()                 -- the fade of the gray would be cut by this animation: it goes at once
    SetFont(sign.text, 30)
    SetFont(sign.sub, 20)
    Paint(sign.text, WHITE)
    Paint(sign.sub, GOLD)
    sign.text:SetWidth(math.min(900, (UIParent:GetWidth() or 1000) * 0.8))
    sign.text:SetJustifyH("CENTER")
    sign.text:SetText(text or "")
    sign.sub:SetText(sub or "")
    band:Hide()
    sign:SetAlpha(0)
    sign:Show()
    local played = false
    Run({
        {at = 0.4, len = 0.3, fn = function(p)
            if not played then played = true; if moment then KW:Play(moment) end end
            sign:SetAlpha(Ease(p))
            Place("caption", 1)
        end},
        {at = 4.2, len = 0.8, fn = function(p) sign:SetAlpha(1 - p) end},
    }, function() sign:Hide() end)
end

-- ----------------------------------------------------------------------------
-- The speech balloon: a quip said by the character. A white balloon with a tail, drawn here (nothing is sent to the chat,
-- nobody else sees it). The game does not tell where the character is on the screen: the balloon goes to its own place,
-- over the head by default, and the player may drag it like the signs.
-- ----------------------------------------------------------------------------
local bubble

local function BuildBubble()
    if bubble then return end
    bubble = CreateFrame("Frame", "KorumWastedBubble", UIParent)
    bubble:SetSize(200, 50)
    bubble:SetFrameStrata("HIGH")
    bubble:SetFrameLevel(10)
    bubble:EnableMouse(false)
    local _, outline = KW.Kit.Rounded(bubble, 10, 1, 1, 1, 0.97, 0.9)
    if outline and outline.SetColor then outline:SetColor(0, 0, 0, 0.85) end
    bubble.tail = bubble:CreateTexture(nil, "ARTWORK")
    bubble.tail:SetTexture(KW.DIR .. "Media\\tail")
    bubble.tail:SetSize(22, 18)
    bubble.tail:SetPoint("TOP", bubble, "BOTTOM", 0, 3)
    bubble.text = bubble:CreateFontString(nil, "OVERLAY")
    bubble.text:SetFont(GAME_FONT, 15, "")
    bubble.text:SetTextColor(0.07, 0.07, 0.09, 1)
    bubble.text:SetPoint("CENTER", bubble, "CENTER", 0, 0)
    bubble.text:SetJustifyH("CENTER")
    bubble.text:SetWordWrap(true)
    bubble:SetAlpha(0)
    bubble:Hide()
    bubble:SetScript("OnUpdate", function(self, elapsed)
        self.t = (self.t or 0) + (elapsed or 0)
        local t, hold = self.t, self.hold or 4
        -- not put somewhere by the player: it follows the head as the camera moves closer or away
        local x, y, own = S:Pos("bubble")
        if not own and y ~= self.y then
            self.y = y
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", UIParent, "CENTER", x, y + 15)
        end
        if t < 0.2 then
            self:SetAlpha(Ease(t / 0.2))
        elseif t < 0.2 + hold then
            self:SetAlpha(1)
        elseif t < 0.7 + hold then
            self:SetAlpha(1 - (t - 0.2 - hold) / 0.5)
        else
            self:Hide()
        end
    end)
end

-- A long line wraps (never cut); the balloon takes the size of the words, and stays longer for a longer line.
function S:Bubble(text, moment)
    BuildBubble()
    text = tostring(text or "")
    local fs = bubble.text
    fs:SetWidth(0)
    fs:SetText(text)
    local w = math.min(300, math.max(40, tonumber(fs:GetStringWidth()) or 200))
    fs:SetWidth(w + 2)
    local h = math.max(16, tonumber(fs:GetStringHeight()) or 16)
    -- whole, even sizes: the balloon centred on a pixel, no seam between its pieces
    bubble:SetSize(2 * math.ceil((w + 30) / 2), 2 * math.ceil((h + 22) / 2))
    local x, y = S:Pos("bubble")
    bubble:ClearAllPoints()
    bubble:SetPoint("BOTTOM", UIParent, "CENTER", x, y + 15)
    bubble.t = 0
    bubble.y = y
    bubble.hold = math.min(7, 3 + #text * 0.04)
    bubble.said = text
    bubble:SetAlpha(0)
    bubble:Show()
    S.at = {kind = "bubble", x = x, y = y}
    if moment then KW:Play(moment) end
end

function S:HideBubble()
    if bubble then bubble:Hide() end
end

-- Is a sign on the screen? (a quip does not cover it)
function S:Busy()
    return sign ~= nil and sign:IsShown() and true or false
end

-- for the tests: what is on the screen
function S:State()
    return {gray = gray and gray:IsShown() or false, sign = sign and sign:IsShown() or false,
        text = sign and sign.text:GetText(), sub = sign and sign.sub:GetText(),
        kind = S.at and S.at.kind, x = S.at and S.at.x, y = S.at and S.at.y,
        bubble = bubble and bubble:IsShown() and bubble.said or false}
end
