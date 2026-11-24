"""Korum Wasted: the GTA-like signs on death, quest hand-in and level up."""
import pathlib
import sys
import unittest

from lupa import lua51

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from client_mock import CLIENT  # noqa: E402

ADDON = pathlib.Path(__file__).resolve().parent.parent


class Wasted(unittest.TestCase):
    def setUp(self):
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        self.lua.execute("""
            NOW = 0
            GetTime = function() return NOW end
            UISpecialFrames = {}
            tinsert = table.insert
            SlashCmdList = {}
            PLAYED = {}
            PlaySoundFile = function(path) PLAYED[#PLAYED + 1] = path; return HAVE_FILES end
            PlaySound = function(kit) PLAYED[#PLAYED + 1] = "kit:" .. tostring(kit) end
            SOUNDKIT = {RAID_WARNING = 8959}
            UnitLevel = function() return 20 end
            GetLocale = function() return "ptBR" end
            function Fire(event, ...)
                for _, f in ipairs(FRAMES) do
                    if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
                end
            end
            function Advance(seconds)
                for _ = 1, math.floor(seconds * 20) do
                    NOW = NOW + 0.05
                    for _, f in ipairs(FRAMES) do
                        if f._scripts.OnUpdate and (f._shown or f == KorumWasted.Screen.driver) then f._scripts.OnUpdate(f, 0.05) end
                    end
                end
            end
            NS = {}
        """)
        for name in ("Core.lua", "Locales.lua", "Kit.lua", "Screen.lua", "Quips.lua", "Options.lua"):
            src = (ADDON / name).read_text(encoding="utf-8")
            self.lua.eval("function(src, name) assert(loadstring(src, name))('KorumWasted', NS) end")(src, name)
        self.lua.execute("Fire('ADDON_LOADED', 'KorumWasted'); Fire('PLAYER_LOGIN')")

    def state(self):
        return self.lua.eval("NS.Screen:State()")

    def test_death_grays_the_screen_and_shows_the_sign_until_alive(self):
        self.lua.execute("Fire('PLAYER_DEAD')")
        self.lua.execute("Advance(2)")
        st = self.state()
        self.assertTrue(st.gray)
        self.assertTrue(st.sign)
        self.assertEqual(st.text, "SE FODEU!")
        self.assertIn("kit:8959", list(self.lua.eval("PLAYED").values()))      # no file of yours: the game's sound
        self.lua.execute("Advance(10)")
        self.assertFalse(self.state().sign)                                       # the sign goes after its time
        self.assertTrue(self.state().gray)                                        # the gray stays while dead
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(2)")
        self.assertFalse(self.state().gray)

    def test_your_sound_file_plays_when_it_is_there(self):
        self.lua.execute("HAVE_FILES = true; Fire('QUEST_TURNED_IN', 1, 100, 50); Advance(1)")
        played = list(self.lua.eval("PLAYED").values())
        self.assertTrue(played[0].endswith("Sounds\\mission_passed.ogg"))
        self.assertEqual(self.lua.eval("NS.found.mission_passed"), ".ogg")
        st = self.state()
        self.assertEqual((st.text, st.sub), ("MISSÃO CUMPRIDA!", "RESPEITO +"))

    def test_level_up_and_the_switches(self):
        self.lua.execute("Fire('PLAYER_LEVEL_UP', 21); Advance(1)")
        st = self.state()
        self.assertEqual((st.text, st.sub), ("RESPEITO +", "NÍVEL 21"))
        self.lua.execute("Advance(6); NS.db.quest = false; Fire('QUEST_TURNED_IN', 1); Advance(1)")
        self.assertFalse(self.state().sign)

    def test_releasing_the_spirit_says_the_line_but_a_resurrection_does_not(self):
        self.lua.execute("HAVE_FILES = true; Fire('PLAYER_DEAD'); Advance(2)")
        self.lua.execute("UnitIsGhost = function() return true end; Fire('PLAYER_ALIVE'); Advance(1)")
        st = self.state()
        self.assertEqual(st.text, "Ah, merda, lá vamos nós de novo.")       # the test client is in Portuguese
        self.assertEqual(self.lua.eval("NS.L.enUS.sign_ghostText"), "Ah shit, here we go again.")
        self.assertEqual(st.sub, "- CJ")
        self.assertFalse(st.gray)
        self.assertTrue(st.sign)
        self.assertTrue(list(self.lua.eval("PLAYED").values())[-1].endswith("graveyard.ogg"))
        self.lua.execute("Advance(8); PLAYED = {}; Fire('PLAYER_DEAD'); Advance(12)")
        self.lua.execute("PLAYED = {}; UnitIsGhost = function() return false end; Fire('PLAYER_ALIVE'); Advance(1)")
        self.assertFalse(self.state().sign)                                       # resurrected on the spot: no line
        self.assertEqual(len(list(self.lua.eval("PLAYED").values())), 0)

    def test_english_by_the_game_or_by_choice_and_typed_texts_stay(self):
        self.lua.execute("NS.db.lang = 'enUS'; Fire('PLAYER_DEAD'); Advance(2)")
        self.assertEqual(self.state().text, "WASTED")
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(9); Fire('QUEST_TURNED_IN', 1); Advance(1)")
        st = self.state()
        self.assertEqual((st.text, st.sub), ("MISSION PASSED!", "RESPECT +"))
        self.assertEqual(self.lua.eval("NS.T('tab_general')"), "General")
        self.lua.execute("NS:SetSignText('deathText', 'BUSTED'); NS.db.lang = 'ptBR'")
        self.assertEqual(self.lua.eval("NS:SignText('deathText')"), "BUSTED")       # what was typed follows no language
        self.assertEqual(self.lua.eval("NS:SignText('questText')"), "MISSÃO CUMPRIDA!")
        self.lua.execute("NS:SetSignText('deathText', '')")                          # emptied: back to the default
        self.assertEqual(self.lua.eval("NS:SignText('deathText')"), "SE FODEU!")
        self.lua.execute("NS.db.questText = 'MISSÃO CUMPRIDA!'; NS:MigrateTexts()")  # a save from before the languages
        self.assertIsNone(self.lua.eval("NS.db.questText"))

    def test_a_guard_or_a_player_busts_you_and_a_wolf_wastes_you(self):
        self.lua.execute("""
            UNITS = {}
            UnitExists = function(u) return UNITS[u] ~= nil end
            UnitCanAttack = function(u) return UNITS[u] and UNITS[u].hostile or false end
            UnitIsUnit = function(a, b) return b == "player" and UNITS[a:gsub("target$", "")] ~= nil and UNITS[a:gsub("target$", "")].onMe or false end
            UnitIsPlayer = function(u) return UNITS[u] and UNITS[u].player or false end
            UnitName = function(u) return UNITS[u] and UNITS[u].name end
            function Attacker(name, player) UNITS = {nameplate3 = {name = name, hostile = true, onMe = true, player = player}} end
        """)
        self.assertNotIn("COMBAT_LOG", (ADDON / "Core.lua").read_text(encoding="utf-8").upper().replace("THE COMBAT LOG", ""))
        self.lua.execute("Attacker('Guarda de Orgrimmar'); Fire('PLAYER_REGEN_DISABLED'); Advance(1); Fire('PLAYER_DEAD'); Advance(2)")
        self.assertEqual(self.state().text, "PRESO!")
        self.assertIn("busted", " ".join(str(x) for x in self.lua.eval("PLAYED").values()))
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(9); Attacker('Lobo da Floresta'); Fire('PLAYER_DEAD'); Advance(2)")
        self.assertEqual(self.state().text, "SE FODEU!")
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(9); Attacker('Fulano', true); Fire('PLAYER_DEAD'); Advance(2)")
        self.assertEqual(self.state().text, "PRESO!")                               # a hostile player
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(9); NS.db.busted = false; Attacker('Guarda'); Fire('PLAYER_DEAD'); Advance(2)")
        self.assertEqual(self.state().text, "SE FODEU!")                            # switched off
        self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(9); NS.db.busted = true; UnitName = function() error('secret') end")
        self.lua.execute("Attacker('Guarda'); Fire('PLAYER_DEAD'); Advance(2)")      # the game hides the name: a plain death
        self.assertEqual(self.state().text, "SE FODEU!")

    def test_an_abandoned_or_failed_quest_is_a_mission_failed(self):
        self.lua.execute("ERR_QUEST_FAILED_S = '%s falhou.'")
        self.lua.execute("Fire('UI_INFO_MESSAGE', 1, 'A Caçada falhou.'); Advance(1)")
        st = self.state()
        self.assertEqual((st.text, st.sub), ("MISSÃO FRACASSADA!", "A Caçada"))
        self.lua.execute("Advance(6); Fire('UI_INFO_MESSAGE', 1, 'Outra coisa qualquer.'); Advance(1)")
        self.assertFalse(self.state().sign)
        self.lua.execute("NS:Failed('Abandonada'); Advance(1)")
        self.assertEqual(self.state().sub, "Abandonada")

    def test_busted_and_failed_play_the_death_sound_when_they_have_no_file(self):
        self.lua.execute("PlaySoundFile = function(path) PLAYED[#PLAYED + 1] = path; return path:find('wasted') ~= nil end")
        self.assertEqual(self.lua.eval("NS:Play('failed')"), "file")
        self.assertTrue(list(self.lua.eval("PLAYED").values())[-1].endswith("wasted.ogg"))
        self.assertEqual(self.lua.eval("NS.found.mission_failed"), "wasted.ogg")
        self.lua.execute("PLAYED = {}")
        self.assertEqual(self.lua.eval("NS:Play('busted')"), "file")
        self.assertNotIn("kit:8959", list(self.lua.eval("PLAYED").values()))

    def test_the_addons_own_sound_plays_when_there_is_no_file_of_yours(self):
        self.lua.execute("PlaySoundFile = function(path) PLAYED[#PLAYED + 1] = path; return path:find('default_') ~= nil end")
        self.assertEqual(self.lua.eval("NS:Play('quest')"), "included")
        self.assertTrue(list(self.lua.eval("PLAYED").values())[-1].endswith("default_mission_passed.ogg"))
        self.assertEqual(self.lua.eval("NS:Play('busted')"), "included")       # no busted, no wasted of yours: the addon's
        self.assertTrue(list(self.lua.eval("PLAYED").values())[-1].endswith("default_wasted.ogg"))
        self.assertEqual(self.lua.eval("NS.found.busted"), "included")
        for name in ("wasted", "mission_passed", "respect", "graveyard"):
            self.assertTrue((ADDON / "Sounds" / f"default_{name}.ogg").exists(), name)

    def test_nothing_of_anyone_else_is_named_in_the_addon(self):
        for path in list(ADDON.glob("*.lua")) + list(ADDON.glob("*.toc")) + list(ADDON.glob("Sounds/*.txt")):
            text = path.read_text(encoding="utf-8").lower()
            for word in ("gta", "rockstar", "grand theft", "pricedown"):
                self.assertNotIn(word, text, f"{path.name}: {word}")

    def test_each_kind_of_sign_goes_where_the_player_put_it(self):
        self.lua.execute("C_Timer = nil; NS.Screen:Quote(); Advance(1)")
        st = self.state()
        self.assertEqual((st.kind, st.x, st.y), ("caption", 0, -230))             # the usual place
        self.lua.execute("NS.Screen:SetPos('caption', 120.4, 300); NS.Screen:SetPos('card', -200, 50)")
        self.lua.execute("NS.Screen:Quote(); Advance(1)")
        st = self.state()
        self.assertEqual((st.kind, st.x, st.y), ("caption", 120, 300))
        self.lua.execute("NS.Screen:Mission(); Advance(1)")
        st = self.state()
        self.assertEqual((st.kind, st.x, st.y), ("card", -200, 50))
        self.lua.execute("NS.Screen:Wasted(true); Advance(2)")
        st = self.state()
        self.assertEqual((st.kind, st.x, st.y), ("death", 0, 40))                 # not moved: where it always was
        # the boxes: shown, nothing is said over them, and putting them away calls back
        self.lua.execute("BACK = 0; NS.Screen:Movers(true, function() BACK = BACK + 1 end)")
        self.assertFalse(self.state().sign)
        self.assertTrue(self.lua.eval("NS.Screen.movers.caption._shown"))
        self.lua.execute("UnitIsAFK = function() return true end; Fire('PLAYER_FLAGS_CHANGED', 'player'); Advance(1)")
        self.assertFalse(self.state().sign)
        self.lua.execute("NS.Screen:Movers(false)")
        self.assertEqual(self.lua.eval("BACK"), 1)
        self.assertFalse(self.lua.eval("NS.Screen.movers.caption._shown"))
        self.lua.execute("NS.Screen:ResetPos(); NS.Screen:Quote(); Advance(1)")
        self.assertEqual(self.state().y, -230)
        self.lua.execute("NS.Options:Toggle('general')")                           # the card of the places builds

    def test_a_quip_is_said_in_a_balloon_over_the_character_unless_captions_are_chosen(self):
        self.lua.execute("NS.Random = function(n) return 1 end; C_Timer = nil; UnitIsAFK = function() return true end")
        self.lua.execute("Fire('PLAYER_FLAGS_CHANGED', 'player'); Advance(1)")
        st = self.state()
        self.assertEqual(st.bubble, "Continua...")                                # the balloon, not the caption
        self.assertFalse(st.sign)
        self.assertEqual((st.kind, st.x, st.y), ("bubble", 0, 59))                      # over the head, by the zoom of the camera
        self.lua.execute("GetCameraZoom = function() return 5 end; Advance(0.2)")
        self.assertEqual(self.lua.eval("NS.Screen:HeadY()"), 126)                 # closer: the head is taller on the screen
        self.lua.execute("Advance(8)")
        self.assertFalse(self.state().bubble)                                     # it goes by itself
        self.lua.execute("NS.Screen:SetPos('bubble', 40, 200); NS.Quips:Say('afk', nil, true); Advance(1)")
        st = self.state()
        self.assertEqual((st.x, st.y), (40, 200))
        self.lua.execute("Fire('PLAYER_LEVEL_UP', 21); Advance(1)")               # a big sign takes its place
        self.assertFalse(self.state().bubble)
        self.lua.execute("NS.Options:Toggle('quips')")                            # the choice builds in the window

    def test_secret_health_in_a_fight_is_no_error_and_the_games_warning_answers(self):
        # in a fight the client hands the health as a value that cannot be compared: comparing it is an error
        self.lua.execute("NS.db.quipStyle = 'caption'; NS.Random = function(n) return 1 end; C_Timer = nil; PRINTED = 0")
        self.lua.execute("local p = print; print = function(...) PRINTED = PRINTED + 1; p(...) end")
        self.lua.execute("UnitHealth = function() return {} end; UnitHealthMax = function() return {} end")
        self.lua.execute("UnitAffectingCombat = function() return true end; LowHealthFrame = nil")
        self.lua.execute("Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertFalse(self.state().sign)
        self.assertEqual(self.lua.eval("PRINTED"), 0)
        self.lua.execute("LowHealthFrame = {IsShown = function() return true end}")
        self.lua.execute("Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertEqual(self.state().text, "Tá tudo bem.")

    def test_quips_say_a_line_of_the_moment_with_a_cooldown_and_a_switch(self):
        self.lua.execute("NS.db.quipStyle = 'caption'; NS.Random = function(n) return 1 end; C_Timer = nil")
        self.lua.execute("UnitHealth = function() return 10 end; UnitHealthMax = function() return 100 end; UnitAffectingCombat = function() return true end")
        self.lua.execute("Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertEqual(self.state().text, "Tá tudo bem.")
        self.lua.execute("Advance(6); Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertFalse(self.state().sign)                                       # the cooldown
        self.lua.execute("NOW = NOW + 200; NS.db.quipOff = {lowhp = true}; Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertFalse(self.state().sign)                                       # switched off
        self.lua.execute("NS.db.quipOff = nil; NS.db.quips = false; Fire('UNIT_HEALTH', 'player'); Advance(1)")
        self.assertFalse(self.state().sign)                                       # all of them off
        self.lua.execute("NS.db.quips = true; NS.db.lang = 'enUS'; UnitIsAFK = function() return true end")
        self.lua.execute("Fire('PLAYER_FLAGS_CHANGED', 'player'); Advance(1)")
        self.assertEqual(self.state().text, "Directed by Robert B. Weide.")   # not the first again: no line twice in a row
        self.assertEqual(len(self.lua.eval("NS.Quips.MOMENTS")), 16)
        for m in self.lua.eval("NS.Quips.MOMENTS").values():                      # every moment has lines and a name, in both
            for lang in ("enUS", "ptBR"):
                self.assertTrue(self.lua.eval(f"#NS.QUIP_LINES.{lang}.{m.id}") >= 1, m.id)
                self.assertIsNotNone(self.lua.eval(f"NS.L.{lang}.q_{m.id}"), m.id)

    def test_a_quip_never_covers_a_sign_and_three_deaths_change_the_graveyard_line(self):
        self.lua.execute("NS.db.quipStyle = 'caption'; NS.Random = function(n) return 1 end; C_Timer = nil; UnitIsAFK = function() return true end")
        self.lua.execute("Fire('PLAYER_LEVEL_UP', 21); Advance(1); Fire('PLAYER_FLAGS_CHANGED', 'player'); Advance(0.5)")
        self.assertEqual(self.state().text, "RESPEITO +")                         # the sign stays
        self.lua.execute("Advance(8)")
        for _ in range(3):
            self.lua.execute("UnitIsGhost = function() return false end; Fire('PLAYER_DEAD'); Advance(1)")
            self.lua.execute("UnitIsGhost = function() return true end; Fire('PLAYER_ALIVE'); Advance(1)")
            last = self.state().text
            self.lua.execute("Fire('PLAYER_UNGHOST'); Advance(8); NOW = NOW + 20")
        self.assertEqual(last, "Já acabou, Jéssica?")                             # the third death in ten minutes

    def test_the_lines_can_be_rewritten_and_the_zone_goes_into_the_line(self):
        self.lua.execute("NS.db.quipStyle = 'caption'; NS.Random = function(n) return 1 end")
        self.lua.execute("NS.Quips:SetLines('mount', 'Vrum!' .. string.char(10, 10) .. '  Segura peão!  ')")
        lines = list(self.lua.eval("(NS.Quips:Lines('mount'))").values())
        self.assertEqual(lines, ["Vrum!", "Segura peão!"])
        self.lua.execute("NS.Quips:SetLines('mount', '')")
        self.assertEqual(self.lua.eval("NS.Quips:Lines('mount')[1]"), "Eu sou a velocidade.")
        self.lua.execute("NS.Quips:Say('highzone', 'Tanaris', true); Advance(1)")
        self.assertEqual(self.state().text, "Não se entra simplesmente em Tanaris.")
        self.assertEqual(self.lua.eval("NS.Quips.LinkQuality('|cnIQ4:|Hitem:1::|h[X]|h|r')"), 4)
        self.assertEqual(self.lua.eval("NS.Quips.LinkQuality('|cff0070dd|Hitem:1::|h[X]|h|r')"), 3)
        self.assertIsNone(self.lua.eval("NS.Quips.LinkQuality('|cffffffff|Hitem:1::|h[X]|h|r')"))

    def test_the_window_opens(self):
        self.lua.execute("SlashCmdList.KORUMWASTED('')")
        self.assertTrue(self.lua.eval("KorumWastedOptions:IsShown()"))


if __name__ == "__main__":
    unittest.main()
