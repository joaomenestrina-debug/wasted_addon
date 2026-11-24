"""Makes the sounds that come with Korum Wasted: original ones, synthesized here (no recording of anything else).

    python ferramentas/gerar_sons.py

Writes Sounds/default_*.ogg. The player's own files (wasted.ogg, mission_passed.ogg...) play in their
place when they are there. Needs numpy and soundfile (pip install numpy soundfile).

    default_wasted           a low hit that falls away, with a dark drone under it (death, busted, mission failed)
    default_mission_passed   a short bright fanfare (quest handed in)
    default_respect          two bells going up (level up)
    default_graveyard        three notes going down, the "oh well" of a brass (the spirit released)
"""
import os

import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Sounds")
SR = 44100


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack, release, power=1.0):
    """A rise of `attack` seconds and a fall of `release` seconds over n samples."""
    e = np.ones(n)
    a, r = int(SR * attack), int(SR * release)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if r > 0:
        e[-r:] = np.linspace(1, 0, r) ** power
    return e


def smooth(x, width):
    """A cheap low-pass: the mean of `width` samples."""
    if width <= 1:
        return x
    return np.convolve(x, np.ones(width) / width, mode="same")


def saw(freq, seconds, detune=0.0):
    x = t(seconds)
    f = freq * (1 + detune)
    return 2 * ((x * f) % 1.0) - 1


def brass(freq, seconds, bright=10):
    """A brass-like note: two saws a hair apart, softened, with a slow swell."""
    n = int(SR * seconds)
    s = (saw(freq, seconds, 0.002) + saw(freq, seconds, -0.002)) / 2
    s = smooth(s, max(2, int(SR / (freq * bright))))
    return s[:n] * env(n, 0.03, min(0.25, seconds / 2))


def bell(freq, seconds):
    x = t(seconds)
    mod = np.sin(2 * np.pi * freq * 3.01 * x) * np.exp(-x * 6) * 2.2
    return np.sin(2 * np.pi * freq * x + mod) * np.exp(-x * 3.2)


def place(track, sound, at, gain=1.0):
    i = int(SR * at)
    end = min(len(track), i + len(sound))
    track[i:end] += sound[:end - i] * gain


def echo(x, delays=((0.11, 0.35), (0.23, 0.22), (0.37, 0.12))):
    out = np.copy(x)
    for d, g in delays:
        k = int(SR * d)
        out[k:] += x[:-k] * g
    return out


def finish(x, peak=0.85):
    x = np.tanh(x * 1.2)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = int(SR * 0.02)
    x[:fade] *= np.linspace(0, 1, fade)
    x[-fade:] *= np.linspace(1, 0, fade)
    return np.stack([x, x], axis=1).astype(np.float32)


def wasted():
    seconds = 3.6
    x = t(seconds)
    track = np.zeros(len(x))
    # the hit: a tone that falls from 120 Hz to 38 Hz, driven hard
    f = 38 + 82 * np.exp(-x * 2.6)
    hit = np.tanh(np.sin(2 * np.pi * np.cumsum(f) / SR) * 3.0) * np.exp(-x * 1.5)
    track += hit * 0.9
    # the thud of the first instant
    rng = np.random.default_rng(7)
    noise = smooth(rng.standard_normal(len(x)), 40) * np.exp(-x * 14)
    track += noise * 2.2
    # a dark drone under it: a low minor second, fading
    drone = (brass(55.0, seconds, 6) + brass(58.3, seconds, 6)) * np.exp(-x * 0.9)
    track += drone * 0.45
    return finish(echo(track))


def mission_passed():
    seconds = 3.4
    track = np.zeros(int(SR * seconds))
    notes = [(392.00, 0.00, 0.16), (523.25, 0.16, 0.16), (659.25, 0.32, 0.16), (783.99, 0.48, 0.30),
             (659.25, 0.80, 0.14), (783.99, 0.94, 0.20)]
    for freq, at, dur in notes:
        place(track, brass(freq, dur + 0.08), at, 0.7)
        place(track, brass(freq / 2, dur + 0.08, 8), at, 0.4)
    for freq in (523.25, 659.25, 783.99, 1046.50, 261.63):       # the chord that holds at the end
        place(track, brass(freq, 2.0) * np.exp(-t(2.0) * 1.1), 1.16, 0.42)
    place(track, bell(1046.50, 1.6), 1.16, 0.35)
    return finish(echo(track))


def respect():
    seconds = 1.9
    track = np.zeros(int(SR * seconds))
    place(track, bell(659.25, 1.2), 0.00, 0.8)
    place(track, bell(880.00, 1.5), 0.22, 0.9)
    place(track, bell(1318.51, 1.2), 0.44, 0.5)
    return finish(echo(track))


def graveyard():
    seconds = 2.6
    track = np.zeros(int(SR * seconds))
    for freq, at, dur in ((293.66, 0.00, 0.38), (277.18, 0.42, 0.38), (261.63, 0.84, 0.40)):
        place(track, brass(freq, dur, 7), at, 0.8)
    # the last one slides down and wobbles
    dur = 1.1
    x = t(dur)
    f = 246.94 * (1 - 0.10 * x / dur) * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * x))
    phase = np.cumsum(f) / SR
    slide = smooth(2 * (phase % 1.0) - 1, 22) * env(len(x), 0.03, 0.6, 1.5)
    place(track, slide, 1.28, 0.85)
    return finish(echo(track, ((0.13, 0.25), (0.27, 0.12))))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in (("wasted", wasted), ("mission_passed", mission_passed), ("respect", respect), ("graveyard", graveyard)):
        path = os.path.join(OUT, f"default_{name}.ogg")
        data = make()
        sf.write(path, data, SR, format="OGG", subtype="VORBIS")
        print(f"{os.path.relpath(path, ROOT)}  {len(data) / SR:.1f}s  {os.path.getsize(path) // 1024} KB")


if __name__ == "__main__":
    main()
