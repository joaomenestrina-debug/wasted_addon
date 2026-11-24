"""Gera o logo do Korum Wasted no desenho dos outros logos Korum (disco escuro, brilho no alto, aro turquesa) com o
símbolo do addon: um balão de fala com um ponto de exclamação vermelho.

    python ferramentas/gerar_logo.py      -> Media/logo.tga (64x64) e arquivo/publicar/logo-400.png
"""
import os

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUT_TGA = os.path.join(ROOT, "Media", "logo.tga")
OUT_PNG = os.path.join(ROOT, "arquivo", "publicar", "logo-400.png")

TEAL = (64, 230, 214)
TEAL_DIM = (38, 150, 142)
RED = (214, 30, 30)
WHITE = (240, 244, 246)


def draw(n):
    """The logo drawn at n x n pixels (64 units across)."""
    u = n / 64

    def disc_mask(radius):
        m = Image.new("L", (n, n), 0)
        c = n / 2
        ImageDraw.Draw(m).ellipse((c - radius, c - radius, c + radius, c + radius), fill=255)
        return m

    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    c = n / 2
    outer = 31.2 * u
    ring = 2.1 * u
    grad = Image.new("RGBA", (n, n))
    gd = ImageDraw.Draw(grad)
    for y in range(n):
        t = y / n
        gd.line((0, y, n, y), fill=(int(24 - 14 * t), int(44 - 24 * t), int(52 - 28 * t), 255))
    img.paste(grad, (0, 0), disc_mask(outer))
    gloss = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse((c - 24 * u, 4 * u, c + 24 * u, 34 * u), fill=(255, 255, 255, 26))
    gloss = gloss.filter(ImageFilter.GaussianBlur(2 * u))
    clip = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    clip.paste(gloss, (0, 0), disc_mask(outer - ring))
    img.alpha_composite(clip)

    d = ImageDraw.Draw(img)
    d.ellipse((c - outer, c - outer, c + outer, c + outer), outline=TEAL + (255,), width=max(1, int(ring)))
    inner = outer - 5 * u
    d.ellipse((c - inner, c - inner, c + inner, c + inner), outline=TEAL_DIM + (90,), width=max(1, int(0.8 * u)))

    # the speech balloon: a rounded box and its tail, white, with a teal glow
    bx0, by0, bx1, by1 = 14 * u, 16 * u, 50 * u, 40 * u
    tail = [(22 * u, by1 - 1 * u), (31 * u, by1 - 1 * u), (19 * u, 49 * u)]
    glow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    g2 = ImageDraw.Draw(glow)
    g2.rounded_rectangle((bx0, by0, bx1, by1), radius=7 * u, fill=TEAL + (90,))
    g2.polygon(tail, fill=TEAL + (90,))
    glow = glow.filter(ImageFilter.GaussianBlur(2.5 * u))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((bx0, by0, bx1, by1), radius=7 * u, fill=WHITE + (255,))
    d.polygon(tail, fill=WHITE + (255,))

    # the red exclamation mark
    mx = (bx0 + bx1) / 2
    d.polygon([(mx - 3.0 * u, 19.5 * u), (mx + 3.0 * u, 19.5 * u), (mx + 1.6 * u, 31.5 * u), (mx - 1.6 * u, 31.5 * u)],
              fill=RED + (255,))
    d.ellipse((mx - 2.2 * u, 33.2 * u, mx + 2.2 * u, 37.6 * u), fill=RED + (255,))
    return img


def main():
    draw(64 * 8).resize((64, 64), Image.LANCZOS).save(OUT_TGA, format="TGA", rle=False)
    os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
    big = draw(400 * 4).resize((400, 400), Image.LANCZOS)
    bg = Image.new("RGBA", (400, 400), (10, 13, 16, 255))
    bg.alpha_composite(big)
    bg.convert("RGB").save(OUT_PNG)
    print("ok:", os.path.normpath(OUT_TGA), os.path.normpath(OUT_PNG))


if __name__ == "__main__":
    main()
