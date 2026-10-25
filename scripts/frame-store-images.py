#!/usr/bin/env python3
"""Frames raw simulator screenshots into App Store images.

Usage: scripts/frame-store-images.py [--raw DIR] [--out DIR] [--only SET ...] [--creative]

For every set folder in --raw (iphone-6.9, iphone-6.1, ipad-13) and every
shot in docs/app-store/screenshots/frames.json it writes <out>/<set>/<shot>.png at the
set's exact App Store size, RGB with no alpha: a velvet gradient, the headline in
Playfair Display (parchment, one gold word at most), and the screenshot in a device
bezel that bleeds off the bottom edge. Sample data only; no Academy marks.

--creative also makes the iOS 27 creative asset into docs/app-store/creative/:
one universal asset (16:9, 5244 x 2950, PNG) that fills both the product page
header and search results, from the iphone-6.9 raw shots. The size is Apple's
creative assets specifications; the safe area is the art-safe area of Apple's
universal template (1402 x 962 at x 1921, y 660), and all focal art stays inside it.
"""
import argparse, json, pathlib, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "OscarsTracker/OscarsTracker/Resources/Fonts/PlayfairDisplay.ttf"
LOGO = ROOT / "OscarsTracker/OscarsTracker/Resources/Assets.xcassets/BrandLogo.imageset/BrandLogo.png"
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


def playfair(size):
    font = ImageFont.truetype(str(FONT), size)
    font.set_variation_by_name("Bold")
    return font


def device(raw, target_w, outer_w):
    """The screenshot in a rounded black bezel, as an RGBA image."""
    shot = raw.convert("RGB")
    shot = shot.resize((target_w, int(shot.height * target_w / shot.width)), Image.LANCZOS)
    bezel, radius = int(outer_w * 0.012), int(target_w * 0.085)
    phone = Image.new("RGBA", (target_w + 2 * bezel, shot.height + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(phone).rounded_rectangle(
        (0, 0, phone.width - 1, phone.height - 1), radius + bezel, fill=(8, 8, 8, 255), outline=(70, 66, 58, 255), width=3)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width - 1, shot.height - 1), radius, fill=255)
    phone.paste(shot, (bezel, bezel), mask)
    return phone


def frame(raw_path, size, text, gold, out_path):
    w, h = size
    canvas = gradient(w, h)
    draw = ImageDraw.Draw(canvas)
    font = playfair(int(w * 0.088))
    y = int(h * 0.055)
    for line in wrap(draw, text, w, font):
        x = (w - draw.textlength(line, font=font)) / 2
        for word in line.split():
            draw.text((x, y), word, font=font, fill=GOLD if word in gold else PARCHMENT)
            x += draw.textlength(word + " ", font=font)
        y += int(font.size * 1.18)
    phone = device(Image.open(raw_path), int(w * 0.80), w)
    canvas.paste(phone, ((w - phone.width) // 2, y + int(h * 0.025)), phone)  # bleeds off the bottom edge
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, "PNG")  # canvas is RGB, so no alpha channel


# Creative assets (iOS 27): one universal asset fills both the product page
# header and search results. Safe area is (left, top, right, bottom).
UNIVERSAL_SIZE, UNIVERSAL_SAFE = (5244, 2950), (1921, 660, 3323, 1622)
UNIVERSAL_LINES = ["Track every nominee.", "Beat your friends."]


def spotlight(w, h, centre):
    """Ink edges, velvet in a soft pool of light around the centre."""
    glow = Image.radial_gradient("L").resize((w, int(h * 1.6)), Image.BILINEAR)
    mask = Image.new("L", (w, h), 255)
    mask.paste(glow, (centre[0] - glow.width // 2, centre[1] - glow.height // 2))
    mask = mask.point(lambda v: int(255 * (v / 255) ** 0.65 * 0.94))
    return Image.composite(Image.new("RGB", (w, h), INK), Image.new("RGB", (w, h), VELVET), mask)


def universal(raw_dir, out_path, wordmark=False):
    """Brand and purpose in the safe area: the logo (or the name) and the promise
    on the left, the real Films tab on the right. Outside it, only velvet, so
    every crop (wide header, 3:2 search tile) reads the same."""
    w, h = UNIVERSAL_SIZE
    l, t, r, b = UNIVERSAL_SAFE
    canvas = spotlight(w, h, ((l + r) // 2, (t + b) // 2))
    draw = ImageDraw.Draw(canvas)
    phone = device(Image.open(raw_dir / "01-films.png"), 390, 1320)
    assert phone.height <= b - t, "phone runs out of the safe area"
    px = r - phone.width
    canvas.paste(phone, (px, t + (b - t - phone.height) // 2), phone)
    col_l, col_r = l, px - 60
    cx = (col_l + col_r) // 2
    font = playfair(92)
    for line in UNIVERSAL_LINES:
        assert draw.textlength(line, font=font) <= col_r - col_l, "line runs out of its column"
    if wordmark:
        name = playfair(118)
        mark_h = int(name.size * 1.3)
    else:
        mark_h = 300
    gap = 56
    block = mark_h + gap + len(UNIVERSAL_LINES) * int(font.size * 1.2)
    y = t + (b - t - block) // 2
    if wordmark:
        draw.text((cx - draw.textlength("Oscars Tracker", font=name) / 2, y), "Oscars Tracker", font=name, fill=GOLD)
    else:
        logo = Image.open(LOGO).convert("RGBA").resize((mark_h, mark_h), Image.LANCZOS)
        canvas.paste(logo, (cx - mark_h // 2, y), logo)
    y = y + mark_h + gap
    for line in UNIVERSAL_LINES:
        draw.text((cx - draw.textlength(line, font=font) / 2, y), line, font=font, fill=PARCHMENT)
        y += int(font.size * 1.2)
    assert y <= b + font.size * 0.25, "text runs below the safe area"
    save(canvas, out_path)


def save(canvas, out_path):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, "PNG")  # RGB, so no alpha channel


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=str(ROOT / "docs/app-store/screenshots/raw"))
    ap.add_argument("--out", default=str(ROOT / "docs/app-store/screenshots/draft"))
    ap.add_argument("--only", nargs="*", help="set names, e.g. iphone-6.9")
    ap.add_argument("--creative", action="store_true", help="also make the universal header and search results asset")
    a = ap.parse_args()
    if a.creative:
        out = ROOT / "docs/app-store/creative"
        raw = pathlib.Path(a.raw) / "iphone-6.9"
        universal(raw, out / "universal.png")
        universal(raw, out / "universal-wordmark.png", wordmark=True)
        print(f"made the universal creative asset in {out}")
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
