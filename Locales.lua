--[[
    Korum Wasted - the words, in English and in Brazilian Portuguese

    KW.T(key, ...) gives the text in the language chosen in the window (db.lang: "auto" follows the game's language).
    The signs have a default per language (the "sign_" keys); what the player types in the window takes their place.
]]

local addonName, KW = ...

local L = {}
KW.L = L

L.enUS = {
    -- the signs
    sign_deathText = "WASTED", sign_deathSub = "", sign_questText = "MISSION PASSED!", sign_respectText = "RESPECT +",
    sign_levelText = "LEVEL %d", sign_ghostText = "Ah shit, here we go again.", sign_ghostSub = "- CJ",
    sign_bustedText = "BUSTED", sign_failedText = "MISSION FAILED!",
    busted = "Busted", bustedD = "A blue sign when a guard or a player kills you",
    failed = "Mission failed", failedD = "When a quest is abandoned, or the game says it failed",
    test_busted = "Busted", test_failed = "Mission failed", m_busted = "Busted", m_failed = "Mission failed",
    f_bustedText = "Killed by a guard or a player", f_bustedTextD = "The blue sign",
    f_failedText = "Quest abandoned or failed", f_failedTextD = "The red sign, with the quest's name under it",
    -- the quips
    tab_quips = "Quips", tab_quipsD = "Lines for the moments",
    quipBubble = "Speech balloon", quipCaption = "Caption on the screen",
    mover_bubble = "The speech balloon of the quips\n(it follows the head of your character by itself; drag me only to fix it somewhere)",
    card_quips = "Quips", quips = "Quips", quipsD = "Your character says well-known lines at moments of the game",
    card_moments = "Moments", quipTest = "Try", quipEdit = "Edit",
    quipEditTitle = "Lines of: %s", quipEditHint = "One line each. Empty goes back to the lines of the addon. %s is the zone, where there is one.",
    quipSave = "Save", quipDefault = "Addon's lines", quipCancel = "Cancel", quipOwn = "your lines",
    q_lowhp = "Low health in a fight", q_deaths = "Three deaths in ten minutes", q_partydeath = "Someone of the group dies",
    q_wipe = "The whole group dead", q_revive = "Resurrected on the spot", q_breath = "Breath running out",
    q_fall = "A long fall", q_loot = "A rare item or better", q_spend = "An expensive purchase or repair",
    q_bagsfull = "Bags full", q_login = "Logging in", q_dungeon = "Walking into a dungeon",
    q_highzone = "A zone above your level", q_hearth = "Using the hearthstone", q_mount = "Mounting up (one time in four)",
    q_afk = "Going away (AFK)",
    -- the window
    subtitle = "Your character knows all the memes",
    tab_general = "General", tab_generalD = "What shows up",
    tab_texts = "Texts", tab_textsD = "What the signs say",
    tab_sounds = "Sounds", tab_soundsD = "Your files",
    card_pos = "Where the signs go", posHint = "Drag each kind of sign to where you want it on the screen.",
    posMove = "Move the signs", posReset = "Back to the usual places",
    mover_death = "The sign of the death\n(drag me)", mover_card = "Mission passed, mission failed, level up\n(drag me)",
    mover_caption = "The line of the graveyard and the quips as captions\n(drag me)",
    moverHint = "Drag the boxes to where each sign should appear. The dark band follows the height of the death sign.",
    moverDone = "Done",
    card_death = "On death", card_quests = "Quests and level", card_sound = "Sound", card_test = "Try it", card_lang = "Language",
    death = "Sign", deathD = "The big words in the middle of the screen, with the dark band behind",
    gray = "Gray screen", grayD = "The world goes gray until you release the spirit or come back; the windows do not",
    ghost = "Line on the way to the graveyard", ghostD = "When you release the spirit: a line and its caption",
    quest = "Mission passed", questD = "When a quest is handed in: the golden sign and the respect line",
    level = "Respect + on level up", levelD = "With the new level under it",
    sound = "Sounds", soundD = "The addon's own sounds, or your files in the Sounds folder",
    lang_auto = "Game's language", lang_en = "English", lang_pt = "Português",
    test_death = "Death", test_quest = "Mission passed", test_level = "Level up", test_ghost = "Graveyard",
    card_texts = "What each sign says",
    f_deathText = "On death", f_deathTextD = "The red sign",
    f_deathSub = "Line under it (death)", f_deathSubD = "Optional, in white",
    f_ghostText = "On the way to the graveyard", f_ghostTextD = "The caption of the line",
    f_ghostSub = "Credit of the line", f_ghostSubD = "Under the caption",
    f_questText = "Quest handed in", f_questTextD = "The golden sign",
    f_respectText = "Respect", f_respectTextD = "Under the mission, and the title on level up",
    f_levelText = "Level", f_levelTextD = "%d becomes the new level",
    f_hold = "Seconds of the death sign", f_holdD = "From 1 to 30",
    textsNote = "Enter keeps the text; an empty box goes back to the default. Try it with the buttons in General.",
    card_files = "Your files", card_howto = "How to use your own sounds",
    m_death = "Death", m_ghost = "Graveyard", m_quest = "Mission passed", m_level = "Level up",
    orMp3 = "(or .mp3)", play = "Play",
    notYet = "not played yet", yourFile = "your file (%s)", sameFile = "the same as the death (%s)", gameSound = "game sound (file not found)", included = "the addon's own sound",
    noSound = "file not found (no sound)",
    howto = "1. Put the .ogg or .mp3 files in Interface\\AddOns\\KorumWasted\\Sounds, with the names above.\n"
        .. "2. Close and open the game: it only sees new files when it starts (a /reload is not enough).\n"
        .. "3. Click Play: the line says whether your file or the addon's own sound played.\n\n"
        .. "Your own font for the signs (optional): Fonts\\sign.ttf or sign.otf. Only use sounds and fonts you have "
        .. "the right to use.",
    fontLine = "Font of the signs: %s", fontGame = "the game's (shown here after the first sign)",
    openWindow = "Open the window", panelDesc = "Your character knows all the memes.",
    error = "error",
}

L.ptBR = {
    sign_deathText = "SE FODEU!", sign_deathSub = "", sign_questText = "MISSÃO CUMPRIDA!", sign_respectText = "RESPEITO +",
    sign_levelText = "NÍVEL %d", sign_ghostText = "Ah, merda, lá vamos nós de novo.", sign_ghostSub = "- CJ",
    sign_bustedText = "PRESO!", sign_failedText = "MISSÃO FRACASSADA!",
    tab_quips = "Falas", tab_quipsD = "Frases para os momentos",
    quipBubble = "Balão de fala", quipCaption = "Legenda na tela",
    mover_bubble = "O balão das falas\n(acompanha a cabeça do personagem sozinho; arraste só para fixar num lugar)",
    card_quips = "Falas", quips = "Falas", quipsD = "O seu personagem solta frases conhecidas em momentos do jogo",
    card_moments = "Momentos", quipTest = "Testar", quipEdit = "Editar",
    quipEditTitle = "Frases de: %s", quipEditHint = "Uma por linha. Vazio volta às frases do addon. %s é a zona, onde houver.",
    quipSave = "Guardar", quipDefault = "Frases do addon", quipCancel = "Cancelar", quipOwn = "suas frases",
    q_lowhp = "Vida baixa em combate", q_deaths = "Três mortes em dez minutos", q_partydeath = "Alguém do grupo morre",
    q_wipe = "O grupo inteiro morto", q_revive = "Ressuscitado no lugar", q_breath = "Fôlego acabando",
    q_fall = "Queda longa", q_loot = "Item raro ou melhor", q_spend = "Compra ou conserto caro",
    q_bagsfull = "Bolsas cheias", q_login = "Ao entrar no jogo", q_dungeon = "Ao entrar em masmorra",
    q_highzone = "Zona acima do seu nível", q_hearth = "Ao usar a pedra de regresso", q_mount = "Ao montar (uma vez em quatro)",
    q_afk = "Ao ficar ausente (AFK)",
    busted = "Preso", bustedD = "Letreiro azul quando quem mata você é um guarda ou um jogador",
    failed = "Missão fracassada", failedD = "Ao abandonar uma missão, ou quando o jogo diz que ela falhou",
    test_busted = "Preso", test_failed = "Missão fracassada", m_busted = "Preso", m_failed = "Missão fracassada",
    f_bustedText = "Morto por guarda ou jogador", f_bustedTextD = "O letreiro azul",
    f_failedText = "Missão abandonada ou falhada", f_failedTextD = "O letreiro vermelho, com o nome da missão embaixo",
    subtitle = "O seu personagem sabe todos os memes",
    tab_general = "Geral", tab_generalD = "O que aparece",
    tab_texts = "Textos", tab_textsD = "O que os letreiros dizem",
    tab_sounds = "Sons", tab_soundsD = "Os seus arquivos",
    card_pos = "Onde os letreiros aparecem", posHint = "Arraste cada tipo de letreiro para onde quiser na tela.",
    posMove = "Mover os letreiros", posReset = "Voltar aos lugares de sempre",
    mover_death = "O letreiro da morte\n(arraste)", mover_card = "Missão cumprida, missão fracassada, subir de nível\n(arraste)",
    mover_caption = "A fala do cemitério e as falas em legenda\n(arraste)",
    moverHint = "Arraste as caixas para onde cada letreiro deve aparecer. A faixa escura acompanha a altura do letreiro da morte.",
    moverDone = "Concluir",
    card_death = "Ao morrer", card_quests = "Missões e nível", card_sound = "Som", card_test = "Testar", card_lang = "Idioma",
    death = "Letreiro", deathD = "O texto grande no meio da tela, com a faixa escura atrás",
    gray = "Tela cinza", grayD = "O mundo fica cinza até você soltar o espírito ou reviver; as janelas não",
    ghost = "Fala ao ir para o cemitério", ghostD = "Ao soltar o espírito: uma fala e a legenda embaixo",
    quest = "Missão cumprida", questD = "Ao entregar uma missão: o letreiro dourado e a linha do respeito",
    level = "Respeito + ao subir de nível", levelD = "Com o nível novo embaixo",
    sound = "Sons", soundD = "Os sons do próprio addon, ou os seus arquivos da pasta Sounds",
    lang_auto = "Idioma do jogo", lang_en = "English", lang_pt = "Português",
    test_death = "Morte", test_quest = "Missão cumprida", test_level = "Subir de nível", test_ghost = "Cemitério",
    card_texts = "O que cada letreiro diz",
    f_deathText = "Ao morrer", f_deathTextD = "O letreiro vermelho",
    f_deathSub = "Linha embaixo (morte)", f_deathSubD = "Opcional, em branco",
    f_ghostText = "Ao ir para o cemitério", f_ghostTextD = "A legenda da fala",
    f_ghostSub = "Crédito da fala", f_ghostSubD = "Embaixo da legenda",
    f_questText = "Missão entregue", f_questTextD = "O letreiro dourado",
    f_respectText = "Respeito", f_respectTextD = "Embaixo da missão, e o título ao subir de nível",
    f_levelText = "Nível", f_levelTextD = "%d é trocado pelo nível novo",
    f_hold = "Segundos do letreiro da morte", f_holdD = "De 1 a 30",
    textsNote = "Enter guarda o texto; a caixa vazia volta ao padrão. Use os botões de testar, em Geral, para ver como fica.",
    card_files = "Os seus arquivos", card_howto = "Como usar os seus sons",
    m_death = "Morte", m_ghost = "Ir para o cemitério", m_quest = "Missão cumprida", m_level = "Subir de nível",
    orMp3 = "(ou .mp3)", play = "Tocar",
    notYet = "ainda não tocou", yourFile = "seu arquivo (%s)", sameFile = "o mesmo da morte (%s)", gameSound = "som do jogo (arquivo não achado)", included = "som do próprio addon",
    noSound = "arquivo não achado (fica sem som)",
    howto = "1. Ponha os arquivos .ogg ou .mp3 na pasta Interface\\AddOns\\KorumWasted\\Sounds, com os nomes acima.\n"
        .. "2. Feche e abra o jogo: ele só enxerga arquivos novos ao iniciar (um /reload não basta).\n"
        .. "3. Clique em Tocar: a linha diz se tocou o seu arquivo ou o som do próprio addon.\n\n"
        .. "A sua fonte para os letreiros (opcional): Fonts\\sign.ttf ou sign.otf. Use só sons e fontes que você "
        .. "tem o direito de usar.",
    fontLine = "Fonte dos letreiros: %s", fontGame = "a do jogo (aparece aqui depois do primeiro letreiro)",
    openWindow = "Abrir a janela", panelDesc = "O seu personagem sabe todos os memes.",
    error = "erro",
}

-- ----------------------------------------------------------------------------
-- The quips: the lines of each moment, per language
-- ----------------------------------------------------------------------------
KW.QUIP_LINES = {}
KW.QUIP_LINES.enUS = {
    lowhp = {"This is fine.", "I'm in danger.", "Emotional damage!", "Bro is cooked.", "Not like this.", "It's joever.", "Lock in. LOCK IN."},
    deaths = {"Why are we still here? Just to suffer?", "Task failed successfully.", "Skill issue.", "-1000 aura.", "It's so over.", "We're cooked.", "You died. Again."},
    partydeath = {"Press F to pay respects.", "F.", "Rest in pepperoni.", "Bro got cooked.", "Oof.", "Another one bites the dust."},
    wipe = {"Mission failed. We'll get 'em next time.", "It's joever.", "GG, go next.", "Well, that escalated quickly.", "Sad violin noises.", "Everything is fine. Nothing is ruined."},
    revive = {"Not today.", "I lived.", "We're so back.", "I'm back, baby!", "Built different.", "+1000 aura.", "Main character energy."},
    breath = {"I have no idea what I'm doing.", "Just keep swimming.", "Glub glub.", "Should have been a fish."},
    fall = {"Parkour!", "I believe I can fly.", "Yeet!", "To infinity and beyond!", "Bombardiro crocodilo!", "Gravity always wins."},
    loot = {"Stonks.", "It's free real estate.", "Sheesh!", "Big W.", "+1000 aura.", "Let him cook.", "Jackpot!"},
    spend = {"Shut up and take my money!", "Not stonks.", "Emotional damage.", "My wallet is crying.", "Bankruptcy speedrun.", "Broke era begins."},
    bagsfull = {"It ain't much, but it's honest work.", "I can stop anytime.", "Do I need all this? Yes.", "Hoarder era.", "Inventory management is my passion."},
    login = {"Hello there.", "Lock in.", "I'm back, baby!", "We're so back.", "Wake up, it's grinding time.", "Main character has entered the chat."},
    dungeon = {"Leeroy Jenkins!", "Brace yourselves.", "Let him cook.", "Lock in.", "This is where the fun begins.", "Tung tung tung sahur!"},
    highzone = {"One does not simply walk into %s.", "Bro thinks he can survive in %s.", "%s? Skill issue incoming.", "I'm not supposed to be in %s, am I?", "%s looks friendly. Surely."},
    hearth = {"Ight, imma head out.", "Peace out.", "I'm out.", "Home, sweet home.", "Gotta go, bye!"},
    mount = {"I am speed.", "Gotta go fast!", "Kachow!", "Vroom vroom.", "Tralalero tralala!", "Ride or die."},
    afk = {"To be continued...", "Directed by Robert B. Weide.", "Brb, touching grass.", "Just a chill guy.", "NPC mode on.", "6 7."},
}
KW.QUIP_LINES.ptBR = {
    lowhp = {"Tá tudo bem.", "Deu ruim.", "Calma, calabreso!", "Dano emocional!", "Ihhh, rapaz...", "Socorro!", "Tô morrendo, mas tô bem."},
    deaths = {"Já acabou, Jéssica?", "Errou feio, errou rude.", "Errou!", "Que fase...", "Sem condições.", "-1000 de aura.", "Paciência, né."},
    partydeath = {"Aperte F para prestar respeito.", "Eita, Giovana.", "F.", "Oloco, meu!", "Já era.", "Vai com Deus, guerreiro."},
    wipe = {"Missão falhou. Na próxima a gente pega.", "Que fase...", "Inacreditável.", "GG, próxima.", "Acabou pra nós.", "Rapaz... não foi dessa vez."},
    revive = {"Hoje não.", "Receba!", "Voltamos!", "O pai tá on.", "+1000 de aura.", "Hoje não, morte.", "Ressuscitei, bebê!"},
    breath = {"Não sei o que estou fazendo.", "Continue a nadar.", "Glub glub.", "Devia ter nascido peixe."},
    fall = {"Parkour!", "Confia.", "Ai, minha coluna!", "Lá vou eu!", "Bombardiro crocodilo!", "A gravidade venceu."},
    loot = {"Stonks.", "É os guri.", "Sou rica!", "Ai, que delícia!", "Chama!", "+1000 de aura.", "Hoje é dia de festa."},
    spend = {"Cala a boca e pega meu dinheiro!", "Not stonks.", "Cadê o dinheiro que tava aqui?", "Dano emocional.", "Tô liso.", "Vou ter que vender um rim."},
    bagsfull = {"Não é muito, mas é trabalho honesto.", "Não cabe mais nada.", "Vai que precisa, né?", "Acumuladora? Eu? Imagina.", "É tudo útil, juro."},
    login = {"Olá.", "Acorda, Pedrinho!", "O pai tá on!", "Voltei, meu povo!", "Bora, bora!", "Chegou quem faltava."},
    dungeon = {"Leeroy Jenkins!", "Taca-lhe pau, Marcos!", "Bora, Bill!", "Agora é sério.", "Vai dar bom. Confia.", "Tung tung tung sahur!"},
    highzone = {"Não se entra simplesmente em %s.", "Que isso, meu filho, calma! Isso aqui é %s!", "Acho que eu não devia estar em %s.", "Sabe de nada, inocente. Isto é %s.", "%s parece tranquilo. Parece."},
    hearth = {"Fui.", "Só os loucos sabem.", "Partiu casa!", "Tchau, tchau!", "Vazei."},
    mount = {"Eu sou a velocidade.", "Sai da frente!", "Vrum vrum!", "Kachow!", "Tralalero tralalá!", "Pisa fundo!"},
    afk = {"Continua...", "Senhor? Senhor?", "Já volto.", "Fui tocar grama.", "Modo NPC.", "6 7."},
}

-- the keys of the signs the player may rewrite
KW.SIGN_KEYS = {"deathText", "deathSub", "questText", "respectText", "levelText", "ghostText", "ghostSub", "bustedText", "failedText"}

function KW.Lang()
    local chosen = KW.db and KW.db.lang
    if chosen == "enUS" or chosen == "ptBR" then return chosen end
    return (GetLocale and GetLocale() == "ptBR") and "ptBR" or "enUS"
end

function KW.T(key, ...)
    local text = L[KW.Lang()][key] or L.enUS[key] or key
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end

-- what a sign says: what the player wrote, else the default of the language
function KW:SignText(key)
    local own = self.db and self.db[key]
    if own ~= nil then return own end
    return L[KW.Lang()]["sign_" .. key] or ""
end

-- a text typed in the window: kept only when it is not the default (so the default follows the language)
function KW:SetSignText(key, text)
    text = text or ""
    if text == "" and key ~= "deathSub" and key ~= "ghostSub" then text = nil end
    if text == L[KW.Lang()]["sign_" .. key] then text = nil end
    self.db[key] = text
end

-- saves from before the languages kept the Portuguese defaults as if typed: they become "the default" again
function KW:MigrateTexts()
    for _, key in ipairs(KW.SIGN_KEYS) do
        local v = self.db[key]
        if v ~= nil and (v == L.ptBR["sign_" .. key] or v == L.enUS["sign_" .. key]) then self.db[key] = nil end
    end
end
