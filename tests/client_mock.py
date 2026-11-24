"""The parts of the game client the tests need (frames, fonts, textures), in Lua."""

CLIENT = r"""
local Frame = {}
Frame.__index = function(t, k)
    local v = rawget(Frame, k)
    if v ~= nil then return v end
    if type(k) == "string" and k:match("^%u") then return function() return nil end end
    return nil
end
function Frame:IsShown() return self._shown or false end
function Frame:GetFrameLevel() return 1 end
function Frame:Show() self._shown = true end
function Frame:Hide() self._shown = false end
function Frame:SetShown(v) self._shown = v and true or false end
function Frame:SetText(t) self._text = t end
function Frame:GetText() return self._text end
function Frame:SetScript(k, fn) self._scripts[k] = fn end
function Frame:RegisterEvent(e) self._events[e] = true end
function Frame:CreateTexture() return NewFrame() end
function Frame:CreateFontString() return NewFrame() end
function NewFrame() return setmetatable({_scripts = {}, _events = {}}, Frame) end
FRAMES = {}
function CreateFrame(kind, name, parent)
    local f = NewFrame(); f._parent = parent
    if name then _G[name] = f end
    FRAMES[#FRAMES + 1] = f
    return f
end
local function EditBox() local b = NewFrame(); b.SetText = function(s, t) s.text = t end; return b end
SendMailNameEditBox, SendMailSubjectEditBox, SendMailMailButton, SendMailMoney = EditBox(), EditBox(), NewFrame(), NewFrame()
SendMailMailButton.IsEnabled = function() return true end
function MoneyInputFrame_SetCopper(frame, c) MAILMONEY = c end
function PlayerClick() C_SendMail.SendMail(SendMailNameEditBox.text, SendMailSubjectEditBox.text, "") end
UIParent = NewFrame(); GameTooltip = NewFrame(); Minimap = NewFrame(); MailFrame = NewFrame(); SendMailFrame = NewFrame()
SlashCmdList = {}
PRINTS = {}
function print(...) local t = {}; for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end; PRINTS[#PRINTS + 1] = table.concat(t, " ") end
function time() return 1000 end
function date() return "01/01 00:00" end
function UnitName() return ME_NAME end
function GetNormalizedRealmName() return "Forever" end
function UnitClass() return "Mago", "MAGE" end
function UnitLevel() return 30 end
function UnitFactionGroup() return "Horde" end
function GetRealZoneText() return "Durotar" end
function GetSubZoneText() return "Orgrimmar" end
function GetBindLocation() return "Orgrimmar" end
function GetMoney() return MONEY end
RAID_CLASS_COLORS = {MAGE = {r = 0.25, g = 0.78, b = 0.92}}
NUM_BAG_SLOTS = 4
ATTACHMENTS_MAX_SEND = 12
ATTACHMENTS_MAX_RECEIVE = 16
C_CurrencyInfo = {GetCoinTextureString = function(c) return string.format("%.0fc", c) end}
ME_NAME = "Alt"
MONEY = 500000

-- timers: manual
TIMERS = {}
CLOCK, DUE = 0, {}
C_Timer = {After = function(s, fn) DUE[fn] = CLOCK + (s or 0); TIMERS[#TIMERS + 1] = fn end}
AUTOCLICK = true
function RunTimers(limit)
    local n = 0
    while #TIMERS > 0 and n < (limit or 200) do
        local best = 1
        for i = 2, #TIMERS do if (DUE[TIMERS[i]] or CLOCK) < (DUE[TIMERS[best]] or CLOCK) then best = i end end
        local fn = table.remove(TIMERS, best); CLOCK = math.max(CLOCK, DUE[fn] or CLOCK); n = n + 1; fn()
        -- the player clicks Send when the addon asks for it
        if AUTOCLICK and NS and NS.Mail and NS.Mail.state and NS.Mail.state.waiting and NS.Mail.state.index and not PLAYER_CLICKED_FOR_BATCH_DONE then
            local st = NS.Mail.state
            if st.askedKey ~= st.index .. ":" .. (st.generationAsk or 0) then
                st.askedKey = st.index .. ":" .. (st.generationAsk or 0)
                PlayerClick()
            end
        end
    end
    return n
end

-- item database
ITEMDB = {}
function Fire(event, ...)
    for _, f in ipairs(FRAMES) do
        if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
    end
end

-- bags
BAGS = {}
LOCKED = {}
local function link(id) return "|cffffffff|Hitem:" .. id .. "::::::::|h[" .. ITEMDB[id].name .. "]|h|r" end
C_Container = {
    GetContainerNumSlots = function(bag) return BAGS[bag] and 16 or 0 end,
    GetContainerNumFreeSlots = function(bag)
        local free = 0
        if BAGS[bag] then for s = 1, 16 do if not BAGS[bag][s] then free = free + 1 end end end
        return free, 0
    end,
    GetContainerItemInfo = function(bag, slot)
        local it = BAGS[bag] and BAGS[bag][slot]
        if not it then return nil end
        return {iconFileID = 1, stackCount = it.count, isLocked = it.locked or false, quality = ITEMDB[it.id].quality,
            hyperlink = link(it.id), itemID = it.id, isBound = it.bound or false}
    end,
    UseContainerItem = function(bag, slot)
        if NO_USE then return end
        local it = BAGS[bag][slot]
        if not it or not MAIL_OPEN then return end
        for i = 1, 12 do
            if not ATTACH[i] then ATTACH[i] = {bag = bag, slot = slot}; return end
        end
    end,
    PickupContainerItem = function(bag, slot) CURSOR = {bag = bag, slot = slot} end,
}
C_Item = {GetItemInfoInstant = function(id) local d = ITEMDB[id]; return id, "t", "s", "", 1, d.class, 0 end}

-- send mail
ATTACH = {}
SENT = {}
MAILMONEY = 0
C_SendMail = {
    GetSendMailItem = function(i)
        local a = ATTACH[i]
        if not a then return nil end
        local it = BAGS[a.bag][a.slot]
        return ITEMDB[it.id].name, it.id, 1, it.count
    end,
    ClickSendMailItemButton = function(i, clear)
        if i and clear then ATTACH[i] = nil return end
        if CURSOR then
            for k = 1, 12 do if not ATTACH[k] then ATTACH[k] = CURSOR; CURSOR = nil; return end end
        end
    end,
    SetSendMailMoney = function(c) MAILMONEY = c end,
    SetSendMailCOD = function(c) end,
    SendMail = function(to, subject, body)
        local items = {}
        for i = 1, 12 do
            local a = ATTACH[i]
            if a then
                local it = BAGS[a.bag][a.slot]
                items[#items + 1] = it.id
                BAGS[a.bag][a.slot] = nil
            end
        end
        SENT[#SENT + 1] = {to = to, subject = subject, items = items, money = MAILMONEY}
        MONEY = MONEY - MAILMONEY - 30
        ATTACH = {}; MAILMONEY = 0
        if not FAIL_SEND then TIMERS[#TIMERS + 1] = function() Fire("MAIL_SEND_SUCCESS") end end
    end,
}

-- inbox
INBOX = {}
C_Mail = {
    GetInboxNumItems = function() return #INBOX end,
    GetInboxHeaderInfo = function(i)
        local m = INBOX[i]
        local n = 0; for _ in pairs(m.att) do n = n + 1 end
        return "", "", "Sender", "Subject", m.money, m.cod or 0, 30, n
    end,
    GetInboxItem = function(i, a)
        local at = INBOX[i] and INBOX[i].att[a]
        if not at then return nil end
        return ITEMDB[at.id].name, at.id, 1, at.count
    end,
    GetInboxItemLink = function(i, a)
        local at = INBOX[i] and INBOX[i].att[a]
        return at and link(at.id) or nil
    end,
    TakeInboxMoney = function(i)
        MONEY = MONEY + INBOX[i].money; INBOX[i].money = 0
        TIMERS[#TIMERS + 1] = function() CleanInbox(); Fire("MAIL_INBOX_UPDATE") end
    end,
    TakeInboxItem = function(i, a)
        local at = INBOX[i].att[a]
        local placed = false
        for bag = 0, 4 do
            if BAGS[bag] and not placed then
                for s = 1, 16 do
                    if not BAGS[bag][s] and not placed then BAGS[bag][s] = {id = at.id, count = at.count}; placed = true end
                end
            end
        end
        INBOX[i].att[a] = nil
        TIMERS[#TIMERS + 1] = function() CleanInbox(); Fire("MAIL_INBOX_UPDATE") end
    end,
}
function CleanInbox()
    for i = #INBOX, 1, -1 do
        local m = INBOX[i]
        local n = 0; for _ in pairs(m.att) do n = n + 1 end
        if m.money == 0 and n == 0 and not m.keep then table.remove(INBOX, i) end
    end
end

StaticPopupDialogs = {}
POPUP = nil
function StaticPopup_Show(name, text) POPUP = {name = name, text = text} end
function Accept() StaticPopupDialogs[POPUP.name].OnAccept() end

function NewChar(name) ME_NAME = name; BAGS = {}; for b = 0, 4 do BAGS[b] = {} end end
"""
