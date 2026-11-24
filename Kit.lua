--[[
    Korum Wasted - kit visual (cópia do kit do Korum Safe Travels)

    O mesmo desenho do Korum Leveling Guide: superfícies arredondadas (nine-slice), pílulas, interruptores com bolinha,
    barra lateral com ícones, cartões com título em maiúsculas. Mais os blocos de infográfico: barras, barra empilhada,
    colunas, cartões de número e fluxo.

    Os ícones (Media\Icons\*.tga) são brancos sobre transparente e recebem a cor na hora.
]]

local addonName, KT = ...
local Kit = {}
KT.Kit = Kit

Kit.COLORS = {
    accent = {0.25, 0.85, 0.80},
    accentBright = {0.40, 1.00, 0.95},
    accentDark = {0.15, 0.55, 0.50},
    bgDarkest = {0.025, 0.045, 0.055},
    bgDark = {0.035, 0.065, 0.078},
    bgMedium = {0.055, 0.095, 0.11},
    sidebarHover = {0.055, 0.095, 0.105},
    textBright = {1, 1, 1},
    textWhite = {0.95, 0.95, 0.97},
    textGray = {0.70, 0.71, 0.75},
    textMuted = {0.52, 0.53, 0.58},
    textDark = {0.35, 0.36, 0.40},
    success = {0.35, 0.85, 0.45},
    warning = {1.00, 0.75, 0.30},
    gold = {1.00, 0.82, 0.20},
    error = {0.95, 0.35, 0.35},
    blue = {0.35, 0.65, 0.95},
    purple = {0.70, 0.45, 0.95},
    border = {0.16, 0.28, 0.31},
}
local C = Kit.COLORS

Kit.ICON_DIR = "Interface\\AddOns\\KorumWasted\\Media\\Icons\\"
Kit.LOGO = "Interface\\AddOns\\KorumWasted\\Media\\logo"
function Kit.Icon(name) return Kit.ICON_DIR .. name end
local function Icon(name) return Kit.ICON_DIR .. name end

function Kit.Font()
    if not Kit.font then
        local f = GameFontNormal and GameFontNormal.GetFont and GameFontNormal:GetFont()
        Kit.font = f or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
    return Kit.font
end

function Kit.Text(parent, size, color, justify, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(Kit.Font(), size or 11, "")
    local c = color or C.textWhite
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function Click()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
        pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

-- 12.345 -> "12.345" (separador de milhar)
function Kit.Number(n)
    local s = string.format("%.0f", math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (out:gsub("^%.", ""))
end

-- ouro em texto curto e colorido: "12.345g 40s"
function Kit.Gold(copper)
    copper = math.floor(tonumber(copper) or 0)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then return string.format("|cffffd100%sg|r |cffc0c0c8%.0fs|r", Kit.Number(g), s) end
    if s > 0 then return string.format("|cffc0c0c8%.0fs %.0fc|r", s, c) end
    return string.format("|cffb87333%.0fc|r", c)
end

function Kit.ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return {c.r, c.g, c.b} end
    return {0.8, 0.8, 0.8}
end

-- ----------------------------------------------------------------------------
-- Fatias: um quadro arredondado a partir de uma textura 64x64 (como no Leveling)
-- ----------------------------------------------------------------------------
function Kit.NineSlice(parent, path, corner, tx, ty, layer, sublevel, rect)
    local slice = {parts = {}, corner = corner or 8, shown = true}
    rect = rect or parent
    tx, ty = tx or 0.25, ty or 0.25
    local coords = {
        {0, tx, 0, ty}, {tx, 1 - tx, 0, ty}, {1 - tx, 1, 0, ty},
        {0, tx, ty, 1 - ty}, {tx, 1 - tx, ty, 1 - ty}, {1 - tx, 1, ty, 1 - ty},
        {0, tx, 1 - ty, 1}, {tx, 1 - tx, 1 - ty, 1}, {1 - tx, 1, 1 - ty, 1},
    }
    for i = 1, 9 do
        local tex = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        tex:SetTexture(path)
        tex:SetTexCoord(coords[i][1], coords[i][2], coords[i][3], coords[i][4])
        slice.parts[i] = tex
    end
    local p = slice.parts
    p[1]:SetPoint("TOPLEFT", rect, "TOPLEFT", 0, 0)
    p[3]:SetPoint("TOPRIGHT", rect, "TOPRIGHT", 0, 0)
    p[7]:SetPoint("BOTTOMLEFT", rect, "BOTTOMLEFT", 0, 0)
    p[9]:SetPoint("BOTTOMRIGHT", rect, "BOTTOMRIGHT", 0, 0)
    p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT"); p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT")
    p[8]:SetPoint("TOPLEFT", p[7], "TOPRIGHT"); p[8]:SetPoint("BOTTOMRIGHT", p[9], "BOTTOMLEFT")
    p[4]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT"); p[4]:SetPoint("BOTTOMRIGHT", p[7], "TOPRIGHT")
    p[6]:SetPoint("TOPLEFT", p[3], "BOTTOMLEFT"); p[6]:SetPoint("BOTTOMRIGHT", p[9], "TOPRIGHT")
    p[5]:SetPoint("TOPLEFT", p[1], "BOTTOMRIGHT"); p[5]:SetPoint("BOTTOMRIGHT", p[9], "TOPLEFT")

    function slice:SetCorner(px)
        self.corner = px
        for _, i in ipairs({1, 3, 7, 9}) do self.parts[i]:SetSize(px, px) end
    end
    function slice:SetColor(r, g, b, a)
        self.color = {r, g, b, a or 1}
        for _, tex in ipairs(self.parts) do tex:SetVertexColor(r, g, b, a or 1) end
    end
    function slice:SetShown(shown)
        self.shown = shown and true or false
        for _, tex in ipairs(self.parts) do tex:SetShown(self.shown) end
    end
    slice:SetCorner(slice.corner)
    return slice
end

-- Pílula (cápsula) de uma textura 64x32: pontas redondas e meio esticado
function Kit.ThreeSlice(owner, path, layer, sublevel)
    local slice = {shown = true}
    local function Part(l, r)
        local tex = owner:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        tex:SetTexture(path)
        tex:SetTexCoord(l, r, 0, 1)
        return tex
    end
    slice.left, slice.mid, slice.right = Part(0, 0.25), Part(0.25, 0.75), Part(0.75, 1)
    slice.parts = {slice.left, slice.mid, slice.right}
    slice.left:SetPoint("TOPRIGHT", slice.mid, "TOPLEFT")
    slice.left:SetPoint("BOTTOMRIGHT", slice.mid, "BOTTOMLEFT")
    slice.right:SetPoint("TOPLEFT", slice.mid, "TOPRIGHT")
    slice.right:SetPoint("BOTTOMLEFT", slice.mid, "BOTTOMRIGHT")
    function slice:SetCapWidth(w)
        self.left:SetWidth(w)
        self.right:SetWidth(w)
    end
    function slice:SetColor(r, g, b, a)
        self.color = {r, g, b, a or 1}
        for _, tex in ipairs(self.parts) do tex:SetVertexColor(r, g, b, a or 1) end
    end
    function slice:SetShown(shown)
        self.shown = shown and true or false
        for _, tex in ipairs(self.parts) do tex:SetShown(self.shown) end
    end
    return slice
end

local function Rounded(frame, corner, r, g, b, a, outlineAlpha, sublevel)
    local surface = Kit.NineSlice(frame, Icon("card"), corner or 6, nil, nil, "BACKGROUND", sublevel or 0)
    surface:SetColor(r, g, b, a)
    local outline
    if outlineAlpha then
        outline = Kit.NineSlice(frame, Icon("border"), corner or 6, nil, nil, "BORDER", sublevel or 0)
        outline:SetColor(1, 1, 1, outlineAlpha)
    end
    return surface, outline
end
Kit.Rounded = Rounded

local function PillIn(frame, height, layer, sublevel)
    local pill = Kit.ThreeSlice(frame, Icon("pill"), layer or "BACKGROUND", sublevel or 0)
    local cap = height / 2
    pill.mid:SetPoint("TOPLEFT", frame, "TOPLEFT", cap, 0)
    pill.mid:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -cap, 0)
    pill:SetCapWidth(cap)
    return pill
end
Kit.PillIn = PillIn

local function Circle(owner, anchor, size, layer, sublevel)
    local dot = Kit.ThreeSlice(owner, Icon("pill"), layer or "ARTWORK", sublevel or 0)
    dot.mid:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    dot.mid:SetSize(0.01, size)
    dot:SetCapWidth(size / 2)
    return dot
end

-- ----------------------------------------------------------------------------
-- Barra de rolagem fina
-- ----------------------------------------------------------------------------
function Kit.ScrollBar(scrollFrame, width, color)
    width = width or 5
    color = color or C.accent
    local bar = CreateFrame("Frame", nil, scrollFrame:GetParent())
    bar:SetWidth(width)
    bar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 5, 0)
    bar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 5, 0)
    bar:EnableMouse(true)
    bar.track = bar:CreateTexture(nil, "BACKGROUND")
    bar.track:SetAllPoints()
    bar.track:SetColorTexture(1, 1, 1, 0.06)
    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetWidth(width)
    thumb:SetPoint("TOP", bar, "TOP", 0, 0)
    thumb:SetHeight(20)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    thumb.tex:SetColorTexture(color[1], color[2], color[3], 0.55)

    function bar:Refresh()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        if range <= 0.5 then
            if (scrollFrame:GetVerticalScroll() or 0) ~= 0 then scrollFrame:SetVerticalScroll(0) end
            self:Hide()
            return
        end
        self:Show()
        local current = scrollFrame:GetVerticalScroll() or 0
        if current > range then current = range; scrollFrame:SetVerticalScroll(range) end
        local trackHeight = self:GetHeight() or 0
        local view = scrollFrame:GetHeight() or 1
        local thumbHeight = math.max(16, trackHeight * view / (view + range))
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", self, "TOP", 0, -(trackHeight - thumbHeight) * (current / range))
    end
    local function ScrollBy(delta)
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local target = (scrollFrame:GetVerticalScroll() or 0) + delta
        scrollFrame:SetVerticalScroll(math.max(0, math.min(range, target)))
        bar:Refresh()
    end
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta) ScrollBy(-delta * 40) end)
    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", function(_, delta) ScrollBy(-delta * 40) end)
    scrollFrame:HookScript("OnScrollRangeChanged", function() bar:Refresh() end)
    scrollFrame:HookScript("OnVerticalScroll", function() bar:Refresh() end)
    scrollFrame:HookScript("OnSizeChanged", function() bar:Refresh() end)
    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local _, cursorY = GetCursorPosition()
        self.dragFrom = cursorY / (self:GetEffectiveScale() or 1)
        self.scrollFrom = scrollFrame:GetVerticalScroll() or 0
        self:SetScript("OnUpdate", function(s)
            if not IsMouseButtonDown("LeftButton") then s:SetScript("OnUpdate", nil) return end
            local _, y = GetCursorPosition()
            y = y / (s:GetEffectiveScale() or 1)
            local range = scrollFrame:GetVerticalScrollRange() or 0
            local free = (bar:GetHeight() or 1) - s:GetHeight()
            if free > 0 and range > 0 then
                scrollFrame:SetVerticalScroll(math.max(0, math.min(range, s.scrollFrom + (s.dragFrom - y) * range / free)))
                bar:Refresh()
            end
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    thumb:SetScript("OnEnter", function(self) self.tex:SetColorTexture(color[1], color[2], color[3], 0.95) end)
    thumb:SetScript("OnLeave", function(self) self.tex:SetColorTexture(color[1], color[2], color[3], 0.55) end)
    bar:SetAlpha(0.8)
    bar:Hide()
    return bar
end

-- ----------------------------------------------------------------------------
-- Cartão com título em maiúsculas
-- ----------------------------------------------------------------------------
Kit.CARD_PAD = 12

function Kit.Card(parent, y, width, title, contentHeight)
    local height = contentHeight + 44
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(width, height)
    card:SetPoint("TOPLEFT", 8, y)
    Rounded(card, 8, 1, 1, 1, 0.035, 0.07)
    local tick = card:CreateTexture(nil, "ARTWORK")
    tick:SetSize(2, 12)
    tick:SetPoint("TOPLEFT", 12, -12)
    tick:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.9)
    local t = Kit.Text(card, 10, C.textWhite)
    t:SetPoint("TOPLEFT", 20, -12)
    t:SetText(string.upper(title or ""))
    local line = card:CreateTexture(nil, "ARTWORK")
    line:SetTexture(Icon("divider"))
    line:SetHeight(8)
    line:SetPoint("LEFT", t, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", card, "TOPRIGHT", -12, -17)
    line:SetVertexColor(1, 1, 1, 0.18)
    card.title = t
    card.content = CreateFrame("Frame", nil, card)
    card.content:SetPoint("TOPLEFT", Kit.CARD_PAD, -36)
    card.content:SetPoint("BOTTOMRIGHT", -Kit.CARD_PAD, Kit.CARD_PAD)
    card.contentWidth = width - Kit.CARD_PAD * 2
    card.content.contentWidth = card.contentWidth
    return card, y - height - 10
end

-- ----------------------------------------------------------------------------
-- Controles
-- ----------------------------------------------------------------------------
function Kit.Toggle(parent, y, label, desc, getValue, setValue)
    local width = parent.contentWidth or 460
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, 38)
    row:SetPoint("TOPLEFT", 0, y)
    local text = Kit.Text(row, 11, C.textWhite)
    text:SetPoint("TOPLEFT", 0, -4)
    text:SetWidth(width - 70)
    text:SetText(label)
    row.label = text
    local sub = Kit.Text(row, 10, C.textMuted)
    sub:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
    sub:SetWidth(width - 70)
    sub:SetText(desc or "")
    row.desc = sub

    local track = CreateFrame("Frame", nil, row)
    track:SetSize(44, 22)
    track:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    track.pill = PillIn(track, 22, "BACKGROUND")
    local knob = CreateFrame("Frame", nil, track)
    knob:SetSize(18, 18)
    knob:SetFrameLevel(track:GetFrameLevel() + 1)
    knob.dot = Circle(knob, knob, 18, "ARTWORK")

    local hovered = false
    function row:Sync()
        local on = getValue() and true or false
        knob:ClearAllPoints()
        if on then
            track.pill:SetColor(C.accent[1], C.accent[2], C.accent[3], hovered and 1 or 0.85)
            knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
            knob.dot:SetColor(1, 1, 1, 1)
        else
            track.pill:SetColor(1, 1, 1, hovered and 0.2 or 0.12)
            knob:SetPoint("LEFT", track, "LEFT", 2, 0)
            knob.dot:SetColor(0.8, 0.81, 0.85, 1)
        end
        self.on = on
    end
    row:EnableMouse(true)
    row:SetScript("OnEnter", function() hovered = true; row:Sync() end)
    row:SetScript("OnLeave", function() hovered = false; row:Sync() end)
    row:SetScript("OnMouseUp", function()
        setValue(not getValue())
        row:Sync()
        Click()
    end)
    row.Click = function() setValue(not getValue()); row:Sync() end
    row:Sync()
    return row, y - 42
end

function Kit.Button(parent, width, height, text, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height or 24)
    local surface, outline = Rounded(btn, 6, 1, 1, 1, 0.07, 0.1)
    local label = Kit.Text(btn, 11, C.textWhite, "CENTER")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label, btn.surface, btn.outline = label, surface, outline
    btn.enabledState = true
    local function Paint(hover)
        if not btn.enabledState then
            surface:SetColor(1, 1, 1, 0.03)
            outline:SetColor(1, 1, 1, 0.05)
            label:SetTextColor(C.textDark[1], C.textDark[2], C.textDark[3])
        elseif hover or btn.accent then
            surface:SetColor(C.accent[1], C.accent[2], C.accent[3], hover and 0.28 or 0.16)
            outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.6)
            label:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3])
        else
            surface:SetColor(1, 1, 1, 0.07)
            outline:SetColor(1, 1, 1, 0.1)
            label:SetTextColor(C.textWhite[1], C.textWhite[2], C.textWhite[3])
        end
    end
    btn.Paint = Paint
    function btn:SetLabel(t) label:SetText(t) end
    function btn:SetEnabledState(on)
        self.enabledState = on and true or false
        if on then self:Enable() else self:Disable() end
        Paint(false)
    end
    function btn:SetAccent(on) self.accent = on; Paint(false) end
    btn:SetScript("OnEnter", function() Paint(true) end)
    btn:SetScript("OnLeave", function() Paint(false) end)
    btn:SetScript("OnClick", function()
        if not btn.enabledState then return end
        if onClick then onClick() end
        Click()
    end)
    Paint(false)
    return btn
end

function Kit.Input(parent, width, onEnter, numeric)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width, 24)
    box:SetAutoFocus(false)
    box:SetFont(Kit.Font(), 11, "")
    box:SetTextColor(C.textWhite[1], C.textWhite[2], C.textWhite[3])
    box:SetTextInsets(8, 8, 0, 0)
    if numeric and box.SetNumeric then box:SetNumeric(true) end
    local surface, outline = Rounded(box, 6, 0, 0, 0, 0.35, 0.12)
    box:SetScript("OnEditFocusGained", function() outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.7) end)
    box:SetScript("OnEditFocusLost", function() outline:SetColor(1, 1, 1, 0.12) end)
    box:SetScript("OnEnterPressed", function(self)
        if onEnter then onEnter(self:GetText()) end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

-- Escolha entre poucas opções, em pílulas lado a lado
function Kit.Segmented(parent, y, options, getValue, setValue)
    local width = parent.contentWidth or 460
    local gap = 6
    local w = math.floor((width - gap * (#options - 1)) / #options)
    local seg = {buttons = {}}
    for i, opt in ipairs(options) do
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(w, 26)
        b:SetPoint("TOPLEFT", (i - 1) * (w + gap), y)
        b.surface, b.outline = Rounded(b, 6, 1, 1, 1, 0.06, 0.1)
        b.label = Kit.Text(b, 10, opt.color or C.textGray, "CENTER")
        b.label:SetPoint("CENTER")
        b.label:SetText(opt.label)
        b.value = opt.value
        b:SetScript("OnClick", function()
            setValue(opt.value)
            seg:Sync()
            Click()
        end)
        seg.buttons[i] = b
    end
    function seg:Sync()
        local cur = getValue()
        for _, b in ipairs(self.buttons) do
            if b.value == cur then
                b.surface:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.22)
                b.outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
            else
                b.surface:SetColor(1, 1, 1, 0.06)
                b.outline:SetColor(1, 1, 1, 0.1)
            end
        end
    end
    seg:Sync()
    return seg, y - 34
end

-- Um menu: um botão com o valor de agora; clicar abre a lista, com uma bolinha na opção escolhida, e clicar fora a fecha.
-- options: uma lista {{value, label}, ...} ou uma função que a dá (a lista pode mudar). dd:Choose(value) escolhe sem o mouse.
local catcher
function Kit.Dropdown(parent, width, options, getValue, setValue)
    local dd = {open = false}
    local function List() return type(options) == "function" and options() or options end
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 26)
    b.surface, b.outline = Rounded(b, 6, 1, 1, 1, 0.06, 0.12)
    b.label = Kit.Text(b, 10, C.textWhite)
    b.label:SetPoint("LEFT", 10, 0)
    b.label:SetWidth(width - 30)
    b.label:SetWordWrap(false)
    b.arrow = Kit.Text(b, 10, C.accent, "RIGHT")
    b.arrow:SetPoint("RIGHT", -10, 0)
    b.arrow:SetText("v")
    dd.button = b

    local menu = CreateFrame("Frame", nil, b)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
    menu.surface = Rounded(menu, 6, C.bgDarkest[1], C.bgDarkest[2], C.bgDarkest[3], 1, 0.18)
    menu.rows = {}
    menu:Hide()
    dd.menu = menu

    local function Close()
        dd.open = false
        menu:Hide()
        if catcher then catcher:Hide() end
        b.outline:SetColor(1, 1, 1, 0.12)
    end

    function dd:Sync()
        local cur = getValue()
        local text
        for _, o in ipairs(List()) do
            if o.value == cur then text = o.label end
        end
        b.label:SetText(text or "")
    end

    function dd:Choose(value)
        setValue(value)
        Close()
        dd:Sync()
        Click()
    end

    local function Fill()
        local list = List()
        local cur = getValue()
        local w = math.max(width, 190)
        menu:SetSize(w, #list * 22 + 8)
        for i, o in ipairs(list) do
            local r = menu.rows[i]
            if not r then
                r = CreateFrame("Button", nil, menu)
                r:SetSize(w - 8, 22)
                r.dot = r:CreateTexture(nil, "ARTWORK")
                r.dot:SetSize(8, 8)
                r.dot:SetPoint("LEFT", 8, 0)
                r.dot:SetTexture(Icon("dot"))
                r.text = Kit.Text(r, 10, C.textWhite)
                r.text:SetPoint("LEFT", 24, 0)
                r.text:SetWidth(w - 40)
                r.text:SetWordWrap(false)
                r:SetScript("OnEnter", function(self) self.text:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3]) end)
                r:SetScript("OnLeave", function(self) self.text:SetTextColor(C.textWhite[1], C.textWhite[2], C.textWhite[3]) end)
                r:SetScript("OnClick", function(self) dd:Choose(self.value) end)
                menu.rows[i] = r
            end
            r:SetWidth(w - 8)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 22)
            r.value = o.value
            r.text:SetText(o.label)
            local on = o.value == cur
            r.dot:SetVertexColor(on and C.accent[1] or 0.4, on and C.accent[2] or 0.42, on and C.accent[3] or 0.45, on and 1 or 0.6)
            r:Show()
        end
        for i = #list + 1, #menu.rows do menu.rows[i]:Hide() end
    end

    function dd:Open()
        Fill()
        dd.open = true
        if not catcher then
            catcher = CreateFrame("Button", nil, UIParent)
            catcher:SetAllPoints(UIParent)
            catcher:SetFrameStrata("FULLSCREEN_DIALOG")
            catcher:SetFrameLevel(1)
            catcher:Hide()
        end
        catcher:SetScript("OnClick", Close)
        catcher:Show()
        menu:SetFrameLevel(50)
        menu:Show()
        b.outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    end
    dd.Close = Close

    b:SetScript("OnClick", function() if dd.open then Close() else dd:Open() end end)
    b:SetScript("OnEnter", function() b.surface:SetColor(1, 1, 1, 0.1) end)
    b:SetScript("OnLeave", function() b.surface:SetColor(1, 1, 1, 0.06) end)
    dd:Sync()
    return dd
end

-- Etiqueta pequena arredondada
function Kit.Chip(parent, text, color)
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(16)
    chip.pill = PillIn(chip, 16, "BACKGROUND")
    chip.text = Kit.Text(chip, 9, C.textWhite, "CENTER")
    chip.text:SetPoint("CENTER")
    function chip:Set(t, c)
        c = c or color or C.accent
        self.text:SetText(t)
        self.text:SetTextColor(c[1], c[2], c[3])
        self.pill:SetColor(c[1], c[2], c[3], 0.18)
        local w = self.text.GetStringWidth and self.text:GetStringWidth() or 0
        self:SetWidth(math.max(28, (w or 0) + 16))
    end
    chip:Set(text or "", color)
    return chip
end

function Kit.Pool(create)
    local pool = {items = {}, used = 0}
    function pool:Acquire()
        self.used = self.used + 1
        local item = self.items[self.used]
        if not item then
            item = create(self.used)
            self.items[self.used] = item
        end
        item:Show()
        return item, self.used
    end
    function pool:Reset()
        for i = 1, #self.items do self.items[i]:Hide() end
        self.used = 0
    end
    return pool
end

-- ----------------------------------------------------------------------------
-- Infográficos
-- ----------------------------------------------------------------------------

-- Barra horizontal de pílula: bar:Set(fração, {r,g,b})
function Kit.Bar(parent, width, height)
    height = height or 10
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(width, height)
    bar.track = PillIn(bar, height, "BACKGROUND")
    bar.track:SetColor(1, 1, 1, 0.08)
    bar.fill = CreateFrame("Frame", nil, bar)
    bar.fill:SetHeight(height)
    bar.fill:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.fill.pill = PillIn(bar.fill, height, "ARTWORK")
    function bar:Set(frac, color)
        frac = math.max(0, math.min(1, tonumber(frac) or 0))
        color = color or C.accent
        if frac <= 0 then self.fill:Hide() return end
        self.fill:Show()
        self.fill:SetWidth(math.max(height, width * frac))
        self.fill.pill:SetColor(color[1], color[2], color[3], 0.9)
    end
    return bar
end

-- Barra dividida em partes (prévia do envio). segments = {{value, color}, ...}
function Kit.Stacked(parent, width, height)
    height = height or 16
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(width, height)
    bar.track = PillIn(bar, height, "BACKGROUND")
    bar.track:SetColor(1, 1, 1, 0.08)
    bar.parts = {}
    function bar:Set(segments)
        local total = 0
        for _, s in ipairs(segments) do total = total + (s.value or 0) end
        for _, p in ipairs(self.parts) do p:Hide() end
        if total <= 0 then return end
        local x = 0
        local inner = width - 4
        for i, s in ipairs(segments) do
            if (s.value or 0) > 0 then
                local tex = self.parts[i]
                if not tex then
                    tex = self:CreateTexture(nil, "ARTWORK")
                    self.parts[i] = tex
                end
                local w = math.max(2, inner * s.value / total)
                tex:ClearAllPoints()
                tex:SetPoint("LEFT", self, "LEFT", 2 + x, 0)
                tex:SetSize(w, height - 4)
                tex:SetColorTexture(s.color[1], s.color[2], s.color[3], 0.92)
                tex:Show()
                x = x + w
            end
        end
    end
    return bar
end

-- Cartão de número: ícone, valor grande, legenda
function Kit.Tile(parent, width, height, iconName, color)
    color = color or C.accent
    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(width, height)
    Rounded(tile, 8, color[1], color[2], color[3], 0.09, 0.0)
    tile.surface2 = select(2, Rounded(tile, 8, 1, 1, 1, 0, 0.08))
    local icon = tile:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("TOPLEFT", 10, -10)
    icon:SetTexture(Icon(iconName))
    icon:SetVertexColor(color[1], color[2], color[3])
    tile.value = Kit.Text(tile, 15, C.textBright)
    tile.value:SetPoint("TOPLEFT", 10, -30)
    tile.value:SetPoint("RIGHT", tile, "RIGHT", -6, 0)
    tile.label = Kit.Text(tile, 9, C.textMuted)
    tile.label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    tile.label:SetPoint("RIGHT", tile, "RIGHT", -6, 0)
    function tile:Set(value, label)
        self.value:SetText(value or "")
        self.label:SetText(string.upper(label or ""))
    end
    return tile
end

-- Gráfico de colunas. chart:Set({{value=, label=, tip=}, ...}, color)
function Kit.Columns(parent, width, height, maxColumns)
    local chart = CreateFrame("Frame", nil, parent)
    chart:SetSize(width, height)
    chart.cols = {}
    local base = chart:CreateTexture(nil, "ARTWORK")
    base:SetHeight(1)
    base:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", 0, 14)
    base:SetPoint("BOTTOMRIGHT", chart, "BOTTOMRIGHT", 0, 14)
    base:SetColorTexture(1, 1, 1, 0.12)
    local slot = width / maxColumns
    for i = 1, maxColumns do
        local col = CreateFrame("Frame", nil, chart)
        col:SetSize(slot, height)
        col:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", (i - 1) * slot, 0)
        col:EnableMouse(true)
        col.bar = col:CreateTexture(nil, "ARTWORK")
        col.bar:SetWidth(math.max(4, slot - 10))
        col.bar:SetPoint("BOTTOM", col, "BOTTOM", 0, 15)
        col.text = Kit.Text(col, 8, C.textMuted, "CENTER")
        col.text:SetPoint("BOTTOM", col, "BOTTOM", 0, 2)
        col:SetScript("OnEnter", function(self)
            if self.tip then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.tip, 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        col:SetScript("OnLeave", function() GameTooltip:Hide() end)
        chart.cols[i] = col
    end
    function chart:Set(points, color)
        color = color or C.accent
        local peak = 0
        for _, p in ipairs(points) do peak = math.max(peak, p.value or 0) end
        local usable = height - 24
        for i, col in ipairs(self.cols) do
            local p = points[i]
            if p then
                col:Show()
                local h = peak > 0 and math.max(2, usable * (p.value or 0) / peak) or 2
                col.bar:SetHeight(h)
                col.bar:SetColorTexture(color[1], color[2], color[3], 0.85)
                col.text:SetText(p.label or "")
                col.tip = p.tip
            else
                col:Hide()
            end
        end
    end
    return chart
end

-- ----------------------------------------------------------------------------
-- Janela com cabeçalho, barra lateral e área rolável (igual à do Leveling)
-- ----------------------------------------------------------------------------
-- spec: name, width, height, title, subtitle, version, tabs = {{id, name, desc, icon}}, onSelect(id)
function Kit.Window(spec)
    local win = {tabs = {}, spec = spec}
    local sidebarWidth = 170
    local height = math.floor(math.min(spec.height, (UIParent:GetHeight() or 768) - 40))
    local f = CreateFrame("Frame", spec.name, UIParent)
    f:SetSize(spec.width, height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    win.frame = f

    Rounded(f, 10, C.bgDarkest[1], C.bgDarkest[2], C.bgDarkest[3], 0.97, 0.1)
    local shadow = CreateFrame("Frame", nil, f)
    shadow:SetPoint("TOPLEFT", f, "TOPLEFT", -18, 18)
    shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 18, -18)
    shadow:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    shadow:EnableMouse(false)
    Kit.NineSlice(shadow, Icon("shadow"), 32, nil, nil, "BACKGROUND", -8):SetColor(0, 0, 0, 0.6)
    if UISpecialFrames and spec.name then table.insert(UISpecialFrames, spec.name) end

    -- cabeçalho
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(52)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    local top = header:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.4)
    local bottom = header:CreateTexture(nil, "ARTWORK")
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)
    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(spec.logo or Icon("share"))
    if not spec.logo then logo:SetVertexColor(C.accent[1], C.accent[2], C.accent[3]) end
    local title = Kit.Text(header, 20, C.textWhite)
    title:SetPoint("LEFT", logo, "RIGHT", 12, 3)
    title:SetText(spec.title or "")
    local subtitle = Kit.Text(header, 10, C.textDark)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -1)
    subtitle:SetText(spec.subtitle or "")
    if spec.version then
        local badge = CreateFrame("Frame", nil, header)
        badge:SetSize(46, 16)
        badge:SetPoint("LEFT", title, "RIGHT", 8, 0)
        PillIn(badge, 16, "BACKGROUND"):SetColor(C.accent[1], C.accent[2], C.accent[3], 0.18)
        local bt = Kit.Text(badge, 9, C.gold, "CENTER")
        bt:SetPoint("CENTER")
        bt:SetText("v" .. spec.version)
    end
    local close = CreateFrame("Button", nil, header)
    close:SetSize(28, 28)
    close:SetPoint("RIGHT", -6, 0)
    local closeBg = close:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0, 0, 0, 0)
    local lines = {}
    for i, rot in ipairs({45, -45}) do
        local l = close:CreateTexture(nil, "ARTWORK")
        l:SetSize(12, 2)
        l:SetPoint("CENTER")
        l:SetColorTexture(0.5, 0.5, 0.5, 1)
        l:SetRotation(math.rad(rot))
        lines[i] = l
    end
    close:SetScript("OnEnter", function()
        closeBg:SetColorTexture(C.error[1], C.error[2], C.error[3], 0.25)
        for _, l in ipairs(lines) do l:SetColorTexture(C.error[1], C.error[2], C.error[3], 1) end
    end)
    close:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0, 0, 0, 0)
        for _, l in ipairs(lines) do l:SetColorTexture(0.5, 0.5, 0.5, 1) end
    end)
    close:SetScript("OnClick", function() f:Hide() end)

    -- barra lateral
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetWidth(sidebarWidth)
    sidebar:SetPoint("TOPLEFT", 4, -56)
    sidebar:SetPoint("BOTTOMLEFT", 4, 4)
    local edge = sidebar:CreateTexture(nil, "ARTWORK")
    edge:SetWidth(1)
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.5)
    local step = math.min(48, math.floor((height - 68) / math.max(1, #spec.tabs)))
    for i, t in ipairs(spec.tabs) do
        local tab = CreateFrame("Button", nil, sidebar)
        tab:SetSize(sidebarWidth - 8, step - 4)
        tab:SetPoint("TOPLEFT", 4, -4 - (i - 1) * step)
        tab.surface = Rounded(tab, 6, 1, 1, 1, 0)
        tab.indicator = tab:CreateTexture(nil, "ARTWORK")
        tab.indicator:SetSize(3, 26)
        tab.indicator:SetPoint("LEFT", 0, 0)
        tab.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        tab.indicator:Hide()
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetSize(16, 16)
        tab.icon:SetPoint("LEFT", 14, 0)
        tab.icon:SetTexture(Icon(t.icon))
        tab.icon:SetVertexColor(0.5, 0.5, 0.5)
        tab.name = Kit.Text(tab, 11, C.textGray)
        tab.name:SetPoint("LEFT", tab.icon, "RIGHT", 8, 3)
        tab.name:SetPoint("RIGHT", tab, "RIGHT", -4, 3)
        tab.name:SetText(t.name)
        tab.desc = Kit.Text(tab, 9, C.textDark)
        tab.desc:SetPoint("TOPLEFT", tab.name, "BOTTOMLEFT", 0, -1)
        tab.desc:SetPoint("RIGHT", tab, "RIGHT", -4, 0)
        tab.desc:SetText(t.desc or "")
        tab.id = t.id
        tab:SetScript("OnEnter", function(self)
            if win.current ~= self.id then
                self.surface:SetColor(1, 1, 1, 0.05)
                self.icon:SetVertexColor(0.8, 0.8, 0.8)
            end
        end)
        tab:SetScript("OnLeave", function(self)
            if win.current ~= self.id then
                self.surface:SetColor(1, 1, 1, 0)
                self.icon:SetVertexColor(0.5, 0.5, 0.5)
            end
        end)
        tab:SetScript("OnClick", function(self) win:Select(self.id); Click() end)
        win.tabs[t.id] = tab
    end

    -- área de conteúdo rolável
    local area = CreateFrame("Frame", nil, f)
    area:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, 0)
    area:SetPoint("BOTTOMRIGHT", -4, 4)
    local scroll = CreateFrame("ScrollFrame", nil, area)
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -16, 6)
    win.scroll = scroll
    win.scrollBar = Kit.ScrollBar(scroll, 5, C.accent)
    local content = CreateFrame("Frame", nil, scroll)
    win.contentWidth = spec.width - sidebarWidth - 38
    content:SetSize(win.contentWidth, 600)
    scroll:SetScrollChild(content)
    win.content = content

    function win:SetContentHeight(h)
        content:SetHeight(math.max(h or 0, (scroll:GetHeight() or 0)))
        self.scrollBar:Refresh()
    end

    function win:Select(id)
        self.current = id
        for tid, tab in pairs(self.tabs) do
            local active = tid == id
            tab.surface:SetColor(active and C.accent[1] or 1, active and C.accent[2] or 1, active and C.accent[3] or 1, active and 0.14 or 0)
            tab.indicator:SetShown(active)
            tab.icon:SetVertexColor(active and C.accent[1] or 0.5, active and C.accent[2] or 0.5, active and C.accent[3] or 0.5)
            tab.name:SetTextColor(active and 1 or C.textGray[1], active and 1 or C.textGray[2], active and 1 or C.textGray[3])
        end
        scroll:SetVerticalScroll(0)
        if spec.onSelect then spec.onSelect(id) end
    end

    return win
end
