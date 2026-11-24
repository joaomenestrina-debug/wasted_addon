"""The zip the players download carries only what the addon uses in the game."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "ferramentas"))
import empacotar  # noqa: E402


class Pacote(unittest.TestCase):
    def test_only_runtime_files(self):
        keep, left = empacotar.files()
        names = {p.as_posix() for p in keep}
        for p in names:
            self.assertFalse(p.startswith(("tests/", "ferramentas/", ".github/", "arquivo/")), p)
            self.assertNotRegex(p, r"\.(md|txt|py|yml)$")
        self.assertNotIn("LICENSE", names)
        self.assertNotIn(".pkgmeta", names)
        for needed in ("KorumWasted.toc", "Core.lua", "Media/logo.tga", "Media/tail.tga", "Sounds/default_wasted.ogg"):
            self.assertIn(needed, names)

    def test_toc_files_are_shipped(self):
        keep, _ = empacotar.files()
        names = {p.as_posix() for p in keep}
        toc = (empacotar.ROOT / "KorumWasted.toc").read_text(encoding="utf-8").splitlines()
        for line in toc:
            line = line.strip()
            if line and not line.startswith("#"):
                self.assertIn(line.replace("\\", "/"), names)

    def test_pkgmeta_matches_the_packer(self):
        _, left = empacotar.files()
        skip = empacotar.ignored()
        for p in left:
            s = p.as_posix()
            if s.startswith(".") or s in ("LICENSE",):
                continue
            self.assertTrue(any(s == i or s.startswith(i + "/") for i in skip), f"{s} is left out of the zip but not in .pkgmeta")


if __name__ == "__main__":
    unittest.main()
