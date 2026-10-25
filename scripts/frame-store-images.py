#!/usr/bin/env python3
"""Frames raw simulator screenshots into App Store images.

Usage: scripts/frame-store-images.py [--raw DIR] [--out DIR] [--only SET ...]

For every set folder in --raw (iphone-6.9, iphone-6.1, ipad-13) and every
shot in docs/app-store/screenshots/frames.json it writes <out>/<set>/<shot>.png at the
set's exact App Store size, RGB with no alpha: a velvet gradient, the headline in
Playfair Display (parchment, one gold word at most), and the screenshot in a device
bezel that bleeds off the bottom edge. Sample data only; no Academy marks.
"""
import argparse, json, pathlib, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "OscarsTracker/OscarsTracker/Resources/Fonts/PlayfairDisplay.ttf"
SIZES = {"iphone-6.9": (1320, 2868), "iphone-6.1": (1206, 2622), "ipad-13": (2064, 2752), "duo-outer": (1398, 2034)}
VELVET, INK, PARCHMENT, GOLD = (142, 42, 53), (13, 13, 13), (242, 230, 194), (212, 168, 47)


def gradient(w, h):
    mid = (62, 20, 28)
    img = Image.new("RGB", (w, h), INK)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        a, b, k = (VELVET, mid, t / 0.55) if t < 0.55 else (mid, INK, (t - 0.55) / 0.45)
        draw.line([(0, y), (w, y)], fill=tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3)))
    return img


def wrap(draw, text, width, font):
    lines, cur = [], ""
    for word in text.split():
        trial = (cur + " " + word).strip()
        if draw.textlength(trial, font=font) <= width * 0.86:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    lines.append(cur)
    return lines


def frame(raw_path, size, text, gold, out_path):
    w, h = size
    canvas = gradient(w, h)
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(FONT), int(w * 0.088))
    font.set_variation_by_name("Bold")
    y = int(h * 0.055)
    for line in wrap(draw, text, w, font):
        x = (w - draw.textlength(line, font=font)) / 2
        for word in line.split():
            draw.text((x, y), word, font=font, fill=GOLD if word in gold else PARCHMENT)
            x += draw.textlength(word + " ", font=font)
        y += int(font.size * 1.18)
    shot = Image.open(raw_path).convert("RGB")
    target_w = int(w * 0.80)
    shot = shot.resize((target_w, int(shot.height * target_w / shot.width)), Image.LANCZOS)
    bezel, radius = int(w * 0.012), int(target_w * 0.085)
    phone = Image.new("RGBA", (target_w + 2 * bezel, shot.height + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(phone).rounded_rectangle(
        (0, 0, phone.width - 1, phone.height - 1), radius + bezel, fill=(8, 8, 8, 255), outline=(70, 66, 58, 255), width=3)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width - 1, shot.height - 1), radius, fill=255)
    phone.paste(shot, (bezel, bezel), mask)
    canvas.paste(phone, ((w - phone.width) // 2, y + int(h * 0.025)), phone)  # bleeds off the bottom edge
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, "PNG")  # canvas is RGB, so no alpha channel


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=str(ROOT / "docs/app-store/screenshots/raw"))
    ap.add_argument("--out", default=str(ROOT / "docs/app-store/screenshots/draft"))
    ap.add_argument("--only", nargs="*", help="set names, e.g. iphone-6.9")
    a = ap.parse_args()
    frames = json.load(open(ROOT / "docs/app-store/screenshots/frames.json"))["frames"]
    made = 0
    for name, size in SIZES.items():
        if a.only and name not in a.only:
            continue
        for f in frames:
            raw = pathlib.Path(a.raw) / name / f"{f['shot']}.png"
            if raw.exists():
                frame(raw, size, f["headline"], f["gold"], pathlib.Path(a.out) / name / f"{f['shot']}.png")
                made += 1
    print(f"framed {made} images into {a.out}")
    if not made:
        sys.exit("nothing framed: capture first with scripts/capture-store-screenshots.sh")


main()
