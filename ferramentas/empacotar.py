"""Monta o zip do Korum Wasted para o jogador: só o que o addon precisa para funcionar.

    python ferramentas/empacotar.py     -> arquivo/publicar/KorumWasted-<versão>.zip

Parte dos arquivos do git (nada pessoal entra: sons e letras do usuário são ignorados pelo git) e deixa de fora o que
o .pkgmeta ignora (o mesmo que o CurseForge deixa de fora), os arquivos que começam com ponto, os textos (.md, .txt) e
os ícones que nenhum código usa.
"""
import pathlib
import re
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = "KorumWasted"
OUT_DIR = ROOT / "arquivo" / "publicar"
DEV_SUFFIXES = {".md", ".txt", ".py", ".yml", ".bak", ".psd", ".xcf"}


def tracked():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
    return [pathlib.PurePosixPath(line) for line in out.stdout.splitlines() if line]


def ignored():
    """The paths under `ignore:` in .pkgmeta."""
    names, inside = [], False
    for line in (ROOT / ".pkgmeta").read_text(encoding="utf-8").splitlines():
        if re.match(r"^\S", line):
            inside = line.startswith("ignore:")
        elif inside and line.strip().startswith("- "):
            names.append(line.strip()[2:].strip())
    return names


def left_out(rel, skip, code):
    if any(part.startswith(".") for part in rel.parts) or rel.suffix.lower() in DEV_SUFFIXES:
        return True
    if any(rel.as_posix() == s or rel.as_posix().startswith(s.rstrip("/") + "/") for s in skip):
        return True
    return rel.parts[:2] == ("Media", "Icons") and f'"{rel.stem}"' not in code


def files():
    """(kept, left out): the git files that go to the player, and the ones that stay out."""
    paths = tracked()
    code = "\n".join((ROOT / p).read_text(encoding="utf-8") for p in paths if p.suffix in (".lua", ".toc")
                     and len(p.parts) == 1)
    skip = ignored()
    keep = [p for p in paths if not left_out(p, skip, code)]
    return keep, [p for p in paths if p not in keep]


def main():
    keep, left = files()
    version = re.search(r"^## Version:\s*(\S+)", (ROOT / f"{ADDON}.toc").read_text(encoding="utf-8"), re.M).group(1)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{ADDON}-{version}.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for p in keep:
            z.write(ROOT / p, f"{ADDON}/{p.as_posix()}")
    print(f"{out.relative_to(ROOT)}: {len(keep)} arquivos")
    for p in left:
        print("  fora:", p.as_posix())


if __name__ == "__main__":
    sys.exit(main())
