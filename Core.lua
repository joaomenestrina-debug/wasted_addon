--[[
    Korum Wasted - núcleo

    Os momentos do jogo contados com letreiros de cinema, como nos jogos de mundo aberto:
        morrer             a tela fica cinza, uma faixa escura atravessa o meio e o letreiro grande aparece;
        entregar missão    "MISSÃO CUMPRIDA!" e "RESPEITO +", em dourado;
        subir de nível     "RESPEITO +" e o nível novo;
        soltar o espírito  ao aceitar ir para o cemitério, uma fala e a legenda.

    Os sons que vêm com o addon são originais (ferramentas/gerar_sons_wasted.py). Quem quiser põe os seus na pasta Sounds
    (veja Sounds/LEIA-ME.txt): eles tocam no lugar. A fonte também pode ser trocada: Fonts/sign.ttf ou sign.otf.

    Tudo se liga e desliga na janela (/wasted), que também está em Opções > AddOns.
]]

local addonName, KW = ...
_G.KorumWasted = KW
KW.DIR = "Interface\\AddOns\\KorumWasted\\"

KW.defaults = {
    death = true,          -- o letreiro ao morrer
    gray = true,           -- e a tela cinza
    quest = true,          -- missão cumprida ao entregar uma missão
    level = true,          -- respeito + ao subir de nível
    sound = true,          -- os sons (os seus, ou os do jogo)
    ghost = true,          -- a fala ao soltar o espírito (ir para o cemitério)
    busted = true,         -- "BUSTED" no lugar do letreiro da morte quando quem mata é um guarda ou um jogador
    failed = true,         -- "MISSÃO FRACASSADA" ao abandonar uma missão ou quando ela falha
    lang = "auto",         -- auto (o idioma do jogo) | enUS | ptBR
    -- deathText, deathSub, questText, respectText, levelText, ghostText, ghostSub: só quando o jogador escreve o seu
    -- (Locales.lua tem o padrão de cada idioma)
    hold = 6,              -- segundos que o letreiro da morte fica (a tela cinza fica até você soltar o espírito ou reviver)
}

-- what each moment plays, in this order: your file in Sounds/ (file), your file of the death (same), the sound that comes
-- with the addon (default_<included>.ogg), a sound of the game (kit)
KW.SOUNDS = {
    death = {file = "wasted", included = "wasted", kit = "RAID_WARNING"},
    quest = {file = "mission_passed", included = "mission_passed", kit = 888},
    level = {file = "respect", included = "respect", kit = 888},
    ghost = {file = "graveyard", included = "graveyard"},
    -- these two sound like the death: without a file of their own they play the one of the death
    busted = {file = "busted", same = "wasted", included = "wasted", kit = "RAID_WARNING"},
    failed = {file = "mission_failed", same = "wasted", included = "wasted", kit = "IG_QUEST_FAILED"},
}

local function Merge(into, from)
    for k, v in pairs(from) do
        if into[k] == nil then into[k] = v end
    end
end

local frame = CreateFrame("Frame")
local handlers = {}

function KW:On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        pcall(frame.RegisterEvent, frame, event)
    end
    table.insert(handlers[event], fn)
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if (...) == addonName then
            KorumWastedDB = KorumWastedDB or {}
            Merge(KorumWastedDB, KW.defaults)
            KW.db = KorumWastedDB
            KW:MigrateTexts()
        end
        return
    end
    for _, fn in ipairs(handlers[event] or {}) do
        local ok, err = pcall(fn, event, ...)
        -- the same error is told once, not at every event
        if not ok then
            KW.told = KW.told or {}
            local key = tostring(err)
            if not KW.told[key] then
                KW.told[key] = true
                print("|cffff5555Korum Wasted (" .. KW.T("error") .. ")|r: " .. key)
            end
        end
    end
end)
frame:RegisterEvent("ADDON_LOADED")

function KW.After(seconds, fn)
    if C_Timer and C_Timer.After then C_Timer.After(seconds, fn) else fn() end
end

function KW.Print(msg) print("|cFF40D9CEKorum Wasted|r " .. tostring(msg)) end

-- ----------------------------------------------------------------------------
-- Sons
-- ----------------------------------------------------------------------------
KW.found = {}   -- file -> true / false, as the last play said (the game does not tell if a file exists any other way)

-- Plays the sound of a moment: the .ogg or .mp3 in Sounds/, else the game's. Returns which one played ("file" / "game").
function KW:Play(moment)
    if not (self.db and self.db.sound) then return nil end
    local s = self.SOUNDS[moment]
    if not s then return nil end
    if _G.PlaySoundFile then
        for _, file in ipairs({s.file, s.same}) do
            for _, ext in ipairs({".ogg", ".mp3"}) do
                local ok, willPlay = pcall(PlaySoundFile, self.DIR .. "Sounds\\" .. file .. ext, "Master")
                if ok and willPlay then
                    self.found[s.file] = (file == s.file) and ext or (file .. ext)
                    return "file"
                end
            end
        end
    end
    -- the sound that comes with the addon
    if _G.PlaySoundFile and s.included then
        local ok, willPlay = pcall(PlaySoundFile, self.DIR .. "Sounds\\default_" .. s.included .. ".ogg", "Master")
        if ok and willPlay then
            self.found[s.file] = "included"
            return "included"
        end
    end
    self.found[s.file] = false
    local kit = type(s.kit) == "string" and _G.SOUNDKIT and _G.SOUNDKIT[s.kit] or s.kit
    if kit and _G.PlaySound then pcall(PlaySound, kit, "Master") end
    return "game"
end

-- ----------------------------------------------------------------------------
-- Os momentos
-- ----------------------------------------------------------------------------
-- Who hit last: a guard of a town or a player (or a player's pet) makes the death a "BUSTED".
-- The words a guard has in its name, in the two languages of the addon (lower case).
KW.GUARD_WORDS = {"guard", "guarda", "sentinel", "sentinela", "vigia", "watch", "patrol", "patrulh", "bruiser", "leão-de-chácara",
    "peacekeeper", "pacificador", "protector", "protetor", "enforcer", "defender", "defensor", "grunt", "grunhido", "bluffwatcher",
    "deathguard", "guardião", "guardian", "warden", "vigilante", "marshal", "xerife", "sheriff", "bouncer"}

local lastBust          -- when a guard or a player was last seen attacking the player

function KW.IsGuardName(name)
    if type(name) ~= "string" then return false end
    local low = name:lower()
    for _, word in ipairs(KW.GUARD_WORDS) do
        if low:find(word, 1, true) then return true end
    end
    return false
end

-- Who is after the player is read from the units on the screen (the target, the focus, the mouse and the nameplates): the
-- one whose own target is the player. The combat log is not used: this client keeps it from addons (asking for it got the
-- addon blocked). Everything is asked under pcall: in some places the game hides who a unit is.
local function Busting(unit)
    if not (UnitExists(unit) and UnitCanAttack(unit, "player")) then return false end
    if not UnitIsUnit(unit .. "target", "player") then return false end
    if UnitIsPlayer(unit) or (UnitPlayerControlled and UnitPlayerControlled(unit)) then return true end
    return KW.IsGuardName(UnitName(unit))
end

function KW:ScanAttackers()
    if not (self.db and self.db.busted and self.db.death) then return end
    if not (UnitExists and UnitCanAttack and UnitIsUnit and UnitIsPlayer and UnitName) then return end
    local function Look(unit)
        local ok, bust = pcall(Busting, unit)
        if ok and bust then lastBust = GetTime and GetTime() or 0 end
    end
    Look("target"); Look("focus"); Look("mouseover")
    for i = 1, 40 do Look("nameplate" .. i) end
end

-- looked at twice a second, only while in combat
local scanner = CreateFrame("Frame")
local fighting, acc = false, 0
scanner:SetScript("OnUpdate", function(_, elapsed)
    if not fighting then return end
    acc = acc + (elapsed or 0)
    if acc < 0.5 then return end
    acc = 0
    KW:ScanAttackers()
end)
KW:On("PLAYER_REGEN_DISABLED", function() fighting = true; acc = 1 end)
KW:On("PLAYER_REGEN_ENABLED", function() fighting = false end)

KW:On("PLAYER_DEAD", function()
    if not KW.db.death then return end
    KW:ScanAttackers()                       -- one last look: the killer is usually still there
    local now = GetTime and GetTime() or 0
    local bust = KW.db.busted and lastBust and now - lastBust < 8
    lastBust = nil
    fighting = false
    KW.Screen:Wasted(false, bust and true or false)
end)

-- ----------------------------------------------------------------------------
-- Missão fracassada: abandonar uma missão, ou a mensagem do jogo de que ela falhou
-- ----------------------------------------------------------------------------
local lastFail = -10
function KW:Failed(name)
    if not self.db.failed then return end
    local now = GetTime and GetTime() or 0
    if now - lastFail < 2 then return end
    lastFail = now
    self.Screen:Failed(name)
end

KW:On("PLAYER_LOGIN", function()
    if not hooksecurefunc then return end
    -- Retail and the newer clients mark the quest first (C_QuestLog.SetAbandonQuest) and keep only its id: the name comes
    -- from the id, read when it is marked (after the abandon it may be gone)
    local abandonID
    local function Abandoned()
        local name
        if _G.GetAbandonQuestName then local ok, n = pcall(GetAbandonQuestName); if ok and n ~= "" then name = n end end
        if not name and abandonID and _G.C_QuestLog and C_QuestLog.GetTitleForQuestID then
            local ok, n = pcall(C_QuestLog.GetTitleForQuestID, abandonID)
            if ok and type(n) == "string" and n ~= "" then name = n end
        end
        abandonID = nil
        KW:Failed(name)
    end
    if _G.AbandonQuest then hooksecurefunc("AbandonQuest", Abandoned) end
    if _G.C_QuestLog and C_QuestLog.SetAbandonQuest and C_QuestLog.GetAbandonQuest then
        hooksecurefunc(C_QuestLog, "SetAbandonQuest", function()
            local ok, id = pcall(C_QuestLog.GetAbandonQuest)
            if ok and type(id) == "number" and id > 0 then abandonID = id end
        end)
    end
    if _G.C_QuestLog and C_QuestLog.AbandonQuest then hooksecurefunc(C_QuestLog, "AbandonQuest", Abandoned) end
end)

-- "<quest> failed." in the client's words
local failPattern
local function FailPattern()
    if failPattern == nil then
        local fmt = _G.ERR_QUEST_FAILED_S
        if type(fmt) == "string" and fmt:find("%%%d?%$?s") then
            -- the placeholder out of the way ("%s" or "%1$s"), the magic characters escaped, then the capture in its place
            local p = fmt:gsub("%%%d?%$?s", "@@"):gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"):gsub("@@", "(.+)")
            failPattern = "^" .. p .. "$"
        else
            failPattern = false
        end
    end
    return failPattern or nil
end
KW.FailPattern = FailPattern

local function OnMessage(_, _, text)
    local pattern = FailPattern()
    if not pattern or type(text) ~= "string" then return end
    local name = text:match(pattern)
    if name then KW:Failed(name) end
end
KW:On("UI_INFO_MESSAGE", OnMessage)
KW:On("UI_ERROR_MESSAGE", OnMessage)

-- back alive, or a ghost running to the body: the gray goes. PLAYER_ALIVE comes both when the spirit is released (a ghost at
-- the graveyard) and when resurrected on the spot: only the first one gets the line
KW:On("PLAYER_ALIVE", function()
    KW.Screen:Clear()
    if UnitIsGhost and UnitIsGhost("player") then
        -- a streak of deaths or a wipe has a line of its own, in place of the usual one
        local quip = KW.Quips and KW.Quips:AfterDeath()
        if quip then
            KW.Quips:Say(quip, nil, true)
        elseif KW.db.ghost then
            KW.Screen:Quote()
        end
    end
end)
KW:On("PLAYER_UNGHOST", function() KW.Screen:Clear() end)

local lastQuest = -10
KW:On("QUEST_TURNED_IN", function()
    if not KW.db.quest then return end
    -- several hand-ins at once (a chain, the same NPC): one card
    local now = GetTime and GetTime() or 0
    if now - lastQuest < 3 then return end
    lastQuest = now
    KW.Screen:Mission()
end)

KW:On("PLAYER_LEVEL_UP", function(_, level)
    if KW.db.level then KW.Screen:Respect(level) end
end)

-- ----------------------------------------------------------------------------
-- Comando: abre a janela (o resto é um atalho)
-- ----------------------------------------------------------------------------
SLASH_KORUMWASTED1 = "/wasted"
SLASH_KORUMWASTED2 = "/kwa"
SlashCmdList.KORUMWASTED = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "morte" or msg == "death" or msg == "test" or msg == "teste" then KW.Screen:Wasted(true)
    elseif msg == "missao" or msg == "missão" or msg == "mission" or msg == "quest" then KW.Screen:Mission()
    elseif msg == "cemiterio" or msg == "cemitério" or msg == "graveyard" then KW.Screen:Quote()
    elseif msg == "busted" or msg == "preso" then KW.Screen:Wasted(true, true)
    elseif msg == "falha" or msg == "failed" or msg == "fracassada" then KW.Screen:Failed()
    elseif msg == "nivel" or msg == "nível" or msg == "level" then KW.Screen:Respect((UnitLevel and UnitLevel("player") or 1) + 1)
    else KW.Options:Toggle() end
end
