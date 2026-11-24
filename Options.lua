--[[
    Korum Wasted - the window

    The window in the Korum standard (Kit.lua): header, sidebar and cards. It opens with /wasted or in Options > AddOns.

        General   what is on (switches), the language and the buttons to try each sign
        Texts     what each sign says, and for how long the one of the death stays
        Sounds    whether each sound played your file or the game's, and where the files go

    Every word comes from Locales.lua (English and Brazilian Portuguese); changing the language builds the screens again.
]]

local addonName, KW = ...
local Kit = KW.Kit
local C = Kit.COLORS
local T = KW.T
local O = {}
KW.Options = O

local WIDTH, HEIGHT = 680, 790
local TAB_IDS = {"general", "quips", "texts", "sounds"}
local TAB_ICON = {general = "settings", quips = "share", texts = "note", sounds = "info"}

local function Screen(win)
    local s = {frame = CreateFrame("Frame", nil, win.content), syncs = {}}
    s.frame:SetPoint("TOPLEFT")
    s.frame:SetSize(win.contentWidth, 10)
    s.frame:Hide()
    return s
end

local function Flag(key)
    return function() return KW.db[key] and true or false end, function(v) KW.db[key] = v and true or false end
end

-- ----------------------------------------------------------------------------
-- General
-- ----------------------------------------------------------------------------
local function BuildGeneral(win, CW)
    local s = Screen(win)
    local y = -8
    local card
    local function Toggle(c, at, key)
        local get, set = Flag(key)
        s.syncs[#s.syncs + 1] = Kit.Toggle(c.content, at, T(key), T(key .. "D"), get, set)
    end
    card, y = Kit.Card(s.frame, y, CW, T("card_test"), 62)
    local tests = {
        {"test_death", function() KW.Screen:Wasted(true) end},
        {"test_busted", function() KW.Screen:Wasted(true, true) end},
        {"test_ghost", function() KW.Screen:Quote() end},
        {"test_quest", function() KW.Screen:Mission() end},
        {"test_failed", function() KW.Screen:Failed() end},
        {"test_level", function() KW.Screen:Respect((UnitLevel and UnitLevel("player") or 1) + 1) end},
    }
    local bw = math.floor((card.contentWidth - 16) / 3)
    for i, t in ipairs(tests) do
        local b = Kit.Button(card.content, bw, 26, T(t[1]), t[2])
        b:SetPoint("TOPLEFT", ((i - 1) % 3) * (bw + 8), -math.floor((i - 1) / 3) * 32)
        if i == 1 then b:SetAccent(true) end
    end

    -- where the signs go: the window steps aside, three boxes are dragged on the screen, and it comes back
    card, y = Kit.Card(s.frame, y, CW, T("card_pos"), 62)
    local posHint = Kit.Text(card.content, 10, C.textMuted)
    posHint:SetPoint("TOPLEFT", 0, 0)
    posHint:SetWidth(card.contentWidth)
    posHint:SetWordWrap(true)
    posHint:SetText(T("posHint"))
    local half = math.floor((card.contentWidth - 8) / 2)
    local move = Kit.Button(card.content, half, 26, T("posMove"), function()
        O.frame:Hide()
        KW.Screen:Movers(true, function() O:Toggle("general") end)
    end)
    move:SetPoint("TOPLEFT", 0, -32)
    move:SetAccent(true)
    local reset = Kit.Button(card.content, half, 26, T("posReset"), function() KW.Screen:ResetPos() end)
    reset:SetPoint("TOPLEFT", half + 8, -32)

    card, y = Kit.Card(s.frame, y, CW, T("card_death"), 4 * 42)
    Toggle(card, 0, "death")
    Toggle(card, -42, "busted")
    Toggle(card, -84, "gray")
    Toggle(card, -126, "ghost")

    card, y = Kit.Card(s.frame, y, CW, T("card_quests"), 3 * 42)
    Toggle(card, 0, "quest")
    Toggle(card, -42, "failed")
    Toggle(card, -84, "level")

    card, y = Kit.Card(s.frame, y, CW, T("card_sound"), 42)
    Toggle(card, 0, "sound")

    card, y = Kit.Card(s.frame, y, CW, T("card_lang"), 30)
    s.syncs[#s.syncs + 1] = Kit.Segmented(card.content, 0,
        {{value = "auto", label = T("lang_auto")}, {value = "enUS", label = T("lang_en")}, {value = "ptBR", label = T("lang_pt")}},
        function() return KW.db.lang or "auto" end,
        function(v) KW.db.lang = v; O:Relabel() end)

    s.height = math.abs(y) + 8
    return s
end

-- ----------------------------------------------------------------------------
-- Texts
-- ----------------------------------------------------------------------------
local FIELDS = {"deathText", "deathSub", "bustedText", "ghostText", "ghostSub", "questText", "failedText", "respectText", "levelText", "hold"}

local function BuildTexts(win, CW)
    local s = Screen(win)
    local y = -8
    local card
    card, y = Kit.Card(s.frame, y, CW, T("card_texts"), #FIELDS * 42)
    for i, key in ipairs(FIELDS) do
        local at = -(i - 1) * 42
        local label = Kit.Text(card.content, 11, C.textWhite)
        label:SetPoint("TOPLEFT", 0, at - 4)
        label:SetText(T("f_" .. key))
        local hint = Kit.Text(card.content, 10, C.textMuted)
        hint:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        hint:SetText(T("f_" .. key .. "D"))
        local box
        local function Show()
            box:SetText(key == "hold" and tostring(KW.db.hold or 6) or KW:SignText(key))
        end
        local function Save(text)
            if key == "hold" then
                KW.db.hold = math.max(1, math.min(30, tonumber(text) or 6))
            else
                KW:SetSignText(key, text)
            end
            Show()
        end
        box = Kit.Input(card.content, key == "hold" and 70 or 220, Save, key == "hold")
        box:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, at - 6)
        if box.SetMaxLetters then box:SetMaxLetters(40) end
        box:HookScript("OnEditFocusLost", function(self) Save(self:GetText()) end)
        box.Sync = Show
        s.syncs[#s.syncs + 1] = box
    end
    local note = Kit.Text(s.frame, 10, C.textMuted)
    note:SetPoint("TOPLEFT", 16, y - 2)
    note:SetWidth(CW - 16)
    note:SetText(T("textsNote"))
    s.height = math.abs(y) + 30
    return s
end

-- ----------------------------------------------------------------------------
-- Sounds
-- ----------------------------------------------------------------------------
local MOMENTS = {"death", "busted", "ghost", "quest", "failed", "level"}

local function BuildSounds(win, CW)
    local s = Screen(win)
    local y = -8
    local card
    card, y = Kit.Card(s.frame, y, CW, T("card_files"), #MOMENTS * 42)
    s.rows = {}
    for i, moment in ipairs(MOMENTS) do
        local at = -(i - 1) * 42
        local file = KW.SOUNDS[moment].file
        local label = Kit.Text(card.content, 11, C.textWhite)
        label:SetPoint("TOPLEFT", 0, at - 4)
        label:SetText(T("m_" .. moment))
        local name = Kit.Text(card.content, 10, C.textMuted)
        name:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        name:SetText("Sounds\\" .. file .. ".ogg  " .. T("orMp3"))
        local play = Kit.Button(card.content, 64, 24, T("play"), function() KW:Play(moment); O:Refresh() end)
        play:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, at - 6)
        local chip = Kit.Text(card.content, 10, C.textGray, "RIGHT")
        chip:SetPoint("RIGHT", play, "LEFT", -12, 0)
        s.rows[i] = {file = file, chip = chip, silent = KW.SOUNDS[moment].kit == nil}
    end
    card, y = Kit.Card(s.frame, y, CW, T("card_howto"), 112)
    local help = Kit.Text(card.content, 10, C.textGray)
    help:SetPoint("TOPLEFT", 0, 0)
    help:SetWidth(card.contentWidth)
    help:SetWordWrap(true)
    help:SetSpacing(3)
    help:SetText(T("howto"))
    s.fontLine = Kit.Text(s.frame, 10, C.textMuted)
    s.fontLine:SetPoint("TOPLEFT", 16, y - 2)
    function s:Refresh()
        local font = KW.Screen.font
        self.fontLine:SetText(T("fontLine", font or T("fontGame")))
        for _, row in ipairs(self.rows) do
            local state = KW.found[row.file]
            if state == nil then
                row.chip:SetText(T("notYet"))
                row.chip:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
            elseif state then
                if state == "included" then
                    row.chip:SetText(T("included"))
                    row.chip:SetTextColor(C.textGray[1], C.textGray[2], C.textGray[3])
                else
                    row.chip:SetText(T(state:sub(1, 1) == "." and "yourFile" or "sameFile", state))
                    row.chip:SetTextColor(C.success[1], C.success[2], C.success[3])
                end
            else
                row.chip:SetText(T(row.silent and "noSound" or "gameSound"))
                row.chip:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
            end
        end
    end
    s.height = math.abs(y) + 30
    return s
end

-- ----------------------------------------------------------------------------
-- Quips
-- ----------------------------------------------------------------------------
-- The box where the lines of a moment are written, one per line. It opens over the window.
local function Editor()
    if O.editor then return O.editor end
    local f = CreateFrame("Frame", nil, O.frame)
    f:SetAllPoints(O.frame)
    f:SetFrameLevel(O.frame:GetFrameLevel() + 60)
    f:EnableMouse(true)
    f.dim = f:CreateTexture(nil, "BACKGROUND")
    f.dim:SetAllPoints(f)
    f.dim:SetColorTexture(0, 0, 0, 0.6)
    local card = CreateFrame("Frame", nil, f)
    card:SetSize(500, 330)
    card:SetPoint("CENTER")
    Kit.Rounded(card, 10, C.bgDark[1], C.bgDark[2], C.bgDark[3], 1, 0.14)
    f.title = Kit.Text(card, 14, C.textWhite)
    f.title:SetPoint("TOPLEFT", 16, -14)
    f.title:SetWidth(468)
    f.hint = Kit.Text(card, 10, C.textMuted)
    f.hint:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -6)
    f.hint:SetWidth(468)
    f.hint:SetWordWrap(true)
    local area = CreateFrame("Frame", nil, card)
    area:SetPoint("TOPLEFT", 16, -72)
    area:SetPoint("BOTTOMRIGHT", -16, 52)
    Kit.Rounded(area, 6, 0, 0, 0, 0.35, 0.12)
    local box = CreateFrame("EditBox", nil, area)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFont(Kit.Font(), 12, "")
    box:SetTextColor(C.textWhite[1], C.textWhite[2], C.textWhite[3])
    box:SetPoint("TOPLEFT", 8, -8)
    box:SetPoint("BOTTOMRIGHT", -8, 8)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    f.box = box
    local save = Kit.Button(card, 110, 26, "", function()
        KW.Quips:SetLines(f.id, box:GetText())
        f:Hide()
        O:Refresh()
    end)
    save:SetPoint("BOTTOMRIGHT", -16, 14)
    save:SetAccent(true)
    local default = Kit.Button(card, 150, 26, "", function()
        KW.Quips:SetLines(f.id, "")
        f:Hide()
        O:Refresh()
    end)
    default:SetPoint("RIGHT", save, "LEFT", -8, 0)
    local cancel = Kit.Button(card, 100, 26, "", function() f:Hide() end)
    cancel:SetPoint("RIGHT", default, "LEFT", -8, 0)
    f.save, f.default, f.cancel = save, default, cancel
    f:Hide()
    O.editor = f
    return f
end

function O:EditQuip(id)
    local f = Editor()
    f.id = id
    f.title:SetText(T("quipEditTitle", T("q_" .. id)))
    f.hint:SetText(T("quipEditHint"))
    f.save:SetLabel(T("quipSave")); f.default:SetLabel(T("quipDefault")); f.cancel:SetLabel(T("quipCancel"))
    f.box:SetText(table.concat((KW.Quips:Lines(id)), "\n"))
    f:Show()
    f.box:SetFocus()
end

local function BuildQuips(win, CW)
    local s = Screen(win)
    local Q = KW.Quips
    local y = -8
    local card
    card, y = Kit.Card(s.frame, y, CW, T("card_quips"), 42 + 38)
    s.syncs[#s.syncs + 1] = Kit.Toggle(card.content, 0, T("quips"), T("quipsD"),
        function() return KW.db.quips ~= false end, function(v) KW.db.quips = v and true or false end)
    -- how they are shown: a balloon over the character, or a caption low on the screen
    s.syncs[#s.syncs + 1] = Kit.Segmented(card.content, -46,
        {{value = "bubble", label = T("quipBubble")}, {value = "caption", label = T("quipCaption")}},
        function() return KW.db.quipStyle == "caption" and "caption" or "bubble" end,
        function(v) KW.db.quipStyle = v end)

    card, y = Kit.Card(s.frame, y, CW, T("card_moments"), #Q.MOMENTS * 42)
    s.rows = {}
    for i, m in ipairs(Q.MOMENTS) do
        local id = m.id
        local row = Kit.Toggle(card.content, -(i - 1) * 42, T("q_" .. id), "",
            function() return not (KW.db.quipOff and KW.db.quipOff[id]) end,
            function(v) KW.db.quipOff = KW.db.quipOff or {}; KW.db.quipOff[id] = (not v) and true or nil end)
        -- two buttons before the switch; the texts end before them, and wrap rather than be cut
        local edit = Kit.Button(row, 62, 24, T("quipEdit"), function() O:EditQuip(id) end)
        edit:SetPoint("RIGHT", row, "RIGHT", -56, 0)
        local test = Kit.Button(row, 62, 24, T("quipTest"), function() Q:Say(id, GetRealZoneText and GetRealZoneText() or nil, true) end)
        test:SetPoint("RIGHT", edit, "LEFT", -6, 0)
        local room = (card.contentWidth or 460) - 56 - 62 - 6 - 62 - 14
        row.label:SetWidth(room)
        row.desc:SetWidth(room)
        row.desc:SetWordWrap(false)
        row.id = id
        s.rows[i] = row
        s.syncs[#s.syncs + 1] = row
    end
    function s:Refresh()
        for _, row in ipairs(self.rows) do
            local lines, own = Q:Lines(row.id)
            local sample = lines[1] or ""
            if #lines > 1 then sample = sample .. "  +" .. (#lines - 1) end
            row.desc:SetText((own and ("|cFF65D9D0" .. T("quipOwn") .. "|r  ") or "") .. sample)
        end
    end
    s.height = math.abs(y) + 8
    return s
end

local BUILDERS = {general = BuildGeneral, quips = BuildQuips, texts = BuildTexts, sounds = BuildSounds}

-- ----------------------------------------------------------------------------
-- The window
-- ----------------------------------------------------------------------------
function O:Create()
    if self.win then return end
    local Meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local tabs = {}
    for _, id in ipairs(TAB_IDS) do
        tabs[#tabs + 1] = {id = id, name = T("tab_" .. id), desc = T("tab_" .. id .. "D"), icon = TAB_ICON[id]}
    end
    local win = Kit.Window({
        name = "KorumWastedOptions", width = WIDTH, height = HEIGHT,
        title = "|cFF65D9D0Korum|r |cFFFFFFFFWasted|r", subtitle = T("subtitle"),
        version = (Meta and Meta(addonName, "Version")) or "0.1.0", logo = Kit.LOGO, tabs = tabs,
        onSelect = function(id) O:OnSelect(id) end,
    })
    self.win = win
    self.frame = win.frame
    self.frame:SetFrameStrata("FULLSCREEN_DIALOG")        -- above the game's options window, which may be open under it
    self.screens = {}
    self.cardWidth = win.contentWidth - 16
end

function O:OnSelect(id)
    self.view = id
    if self.editor then self.editor:Hide() end
    for _, s in pairs(self.screens) do s.frame:Hide() end
    local s = self.screens[id]
    if not s then
        s = BUILDERS[id](self.win, self.cardWidth)
        self.screens[id] = s
    end
    s.frame:SetHeight(s.height or 300)
    s.frame:Show()
    self.win:SetContentHeight(s.height or 300)
    self:Refresh()
end

function O:Refresh()
    local s = self.screens and self.screens[self.view]
    if not s then return end
    for _, c in ipairs(s.syncs) do c:Sync() end
    if s.Refresh then s:Refresh() end
end

-- the language changed: the screens are written again in it, and the names of the tabs
function O:Relabel()
    if not self.win then return end
    for _, s in pairs(self.screens) do s.frame:Hide() end
    self.screens = {}
    for _, id in ipairs(TAB_IDS) do
        local tab = self.win.tabs[id]
        if tab then
            tab.name:SetText(T("tab_" .. id))
            tab.desc:SetText(T("tab_" .. id .. "D"))
        end
    end
    self.win:Select(self.view or "general")
end

function O:Toggle(view)
    self:Create()
    if self.frame:IsShown() and not view then
        self.frame:Hide()
        return
    end
    self.frame:Show()
    self.win:Select(view or self.view or "general")
end

-- In Options > AddOns: a page with the button that opens the window
KW:On("PLAYER_LOGIN", function()
    if not (_G.Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local panel = CreateFrame("Frame")
    panel.name = "Korum Wasted"
    local t = Kit.Text(panel, 16, C.accent)
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText("Korum Wasted")
    local d = Kit.Text(panel, 12, C.textGray)
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetText(T("panelDesc"))
    local b = Kit.Button(panel, 160, 26, T("openWindow"), function()
        -- the game's options window is not closed from here: closing it is an action only the game's own interface may
        -- take (the addon was blocked for it). This window just opens above it.
        O:Toggle("general")
    end)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    b:SetAccent(true)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Korum Wasted")
    Settings.RegisterAddOnCategory(category)
end)
