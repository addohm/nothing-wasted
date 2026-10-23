"""Draws the Nothing Wasted icon (512/400/256/128 px) and banner (1600x500) into this folder.

Needs Pillow and the Inter font (bold and semibold). Point NW_FONT_BOLD and NW_FONT_SEMI at the
font files, then run: python3 art/make_logo.py
"""
import os

from PIL import Image, ImageDraw, ImageFont, ImageChops, ImageFilter

OUT = os.path.dirname(os.path.abspath(__file__))
BOLD = os.environ.get("NW_FONT_BOLD", "Inter-Bold.ttf")
SEMI = os.environ.get("NW_FONT_SEMI", "Inter-SemiBold.ttf")
S = 2048  # draw big, downsample for smooth edges

GOLD = (242, 196, 74)
GOLD_DARK = (176, 128, 32)
NAVY_TOP = (34, 48, 98)
NAVY_BOT = (10, 14, 34)

def vgrad(w, h, top, bot):
    g = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return g.resize((w, h))

def hgrad(w, h, left, right):
    g = Image.new("RGB", (w, 1))
    for x in range(w):
        t = x / (w - 1)
        g.putpixel((x, 0), tuple(int(left[i] + (right[i] - left[i]) * t) for i in range(3)))
    return g.resize((w, h))

def icon(size=S):
    k = size / 2048
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Rounded-square badge with a night gradient.
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([int(40*k), int(40*k), size-int(40*k), size-int(40*k)], radius=int(360*k), fill=255)
    img.paste(vgrad(size, size, NAVY_TOP, NAVY_BOT), (0, 0), mask)
    d = ImageDraw.Draw(img)
    # A few stars.
    for (x, y, r) in [(560, 470, 10), (1500, 360, 8), (1720, 820, 7), (430, 980, 7), (1180, 300, 6), (1640, 1180, 6)]:
        d.ellipse([(x-r)*k, (y-r)*k, (x+r)*k, (y+r)*k], fill=(220, 228, 255, 210))
    # Crescent moon: a circle minus an offset circle.
    cx, cy, r = 900*k, 860*k, 430*k
    moon = Image.new("L", (size, size), 0)
    ImageDraw.Draw(moon).ellipse([cx-r, cy-r, cx+r, cy+r], fill=255)
    cut = Image.new("L", (size, size), 0)
    ox, oy, orr = cx+250*k, cy-170*k, 380*k
    ImageDraw.Draw(cut).ellipse([ox-orr, oy-orr, ox+orr, oy+orr], fill=255)
    moon = ImageChops.subtract(moon, cut)
    # Soft glow behind the moon.
    glow = moon.filter(ImageFilter.GaussianBlur(60*k)).point(lambda v: int(v*0.55))
    img.paste(Image.new("RGBA", (size, size), (255, 214, 110, 255)), (0, 0), glow)
    img.paste(vgrad(size, size, (255, 222, 120), GOLD_DARK), (0, 0), moon)
    d = ImageDraw.Draw(img)
    # Rising Z's.
    for (txt, fs, x, y) in [("Z", 300, 1210, 520), ("Z", 220, 1480, 330), ("Z", 160, 1680, 190)]:
        f = ImageFont.truetype(BOLD, int(fs*k))
        d.text((x*k, y*k), txt, font=f, fill=(236, 240, 255, 255))
    # The rested XP bar, filled exactly to the end.
    x0, y0, x1, y1 = 300*k, 1500*k, 1748*k, 1690*k
    d.rounded_rectangle([x0-14*k, y0-14*k, x1+14*k, y1+14*k], radius=int(60*k), fill=GOLD_DARK)
    d.rounded_rectangle([x0, y0, x1, y1], radius=int(48*k), fill=(8, 10, 24))
    fillmask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(fillmask).rounded_rectangle([x0+12*k, y0+12*k, x1-12*k, y1-12*k], radius=int(38*k), fill=255)
    img.paste(hgrad(size, size, (64, 120, 255), (150, 92, 255)), (0, 0), fillmask)
    d = ImageDraw.Draw(img)
    # XP bar notches.
    for i in range(1, 10):
        x = x0 + (x1 - x0) * i / 10
        d.line([x, y0+18*k, x, y1-18*k], fill=(20, 24, 60, 170), width=max(1, int(8*k)))
    # Shine along the top of the bar.
    d.rounded_rectangle([x0+30*k, y0+22*k, x1-30*k, y0+52*k], radius=int(14*k), fill=(255, 255, 255, 60))
    # Sparkle at the full end.
    sx, sy = x1-10*k, y0+(y1-y0)/2
    for (a, b) in [((0, -150), (0, 150)), ((-150, 0), (150, 0))]:
        d.polygon([(sx+a[0]*k, sy+a[1]*k), (sx+28*k, sy), (sx+b[0]*k, sy+b[1]*k), (sx-28*k, sy)] if a[0] == 0 else
                  [(sx+a[0]*k, sy), (sx, sy-28*k), (sx+b[0]*k, sy), (sx, sy+28*k)], fill=(255, 248, 220, 255))
    d.ellipse([sx-36*k, sy-36*k, sx+36*k, sy+36*k], fill=(255, 255, 255, 255))
    # Gold rim.
    d.rounded_rectangle([int(40*k), int(40*k), size-int(40*k), size-int(40*k)], radius=int(360*k), outline=GOLD, width=int(34*k))
    d.rounded_rectangle([int(80*k), int(80*k), size-int(80*k), size-int(80*k)], radius=int(322*k), outline=(GOLD_DARK[0], GOLD_DARK[1], GOLD_DARK[2], 200), width=int(8*k))
    return img

big = icon()
for px in (512, 400, 256, 128):
    big.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, f"nothing-wasted-icon-{px}.png"))

# Banner: icon plus the name and a tagline.
W, H = 1600, 500
banner = vgrad(W, H, NAVY_TOP, NAVY_BOT).convert("RGBA")
ic = big.resize((400, 400), Image.LANCZOS)
banner.paste(ic, (50, 50), ic)
d = ImageDraw.Draw(banner)
title = ImageFont.truetype(BOLD, 132)
tag = ImageFont.truetype(SEMI, 44)
d.text((500, 120), "Nothing Wasted", font=title, fill=GOLD)
d.text((506, 300), "Your alts are resting. Make it count.", font=tag, fill=(205, 214, 245))
d.line([(506, 293), (1530, 293)], fill=(GOLD_DARK[0], GOLD_DARK[1], GOLD_DARK[2], 255), width=3)
banner.convert("RGB").save(os.path.join(OUT, "nothing-wasted-banner.png"))

# Sanity checks on the layout (without looking at it): text inside the canvas, moon gold, bar blue.
tb = d.textbbox((500, 120), "Nothing Wasted", font=title)
print("title bbox", tb, "fits:", tb[2] < W - 40)
tg = d.textbbox((506, 300), "Your alts are resting. Make it count.", font=tag)
print("tagline bbox", tg, "fits:", tg[2] < W - 40)
i512 = Image.open(os.path.join(OUT, "nothing-wasted-icon-512.png")).convert("RGBA")
print("moon pixel", i512.getpixel((int(560/4), int(860/4))), "bar pixel", i512.getpixel((int(1000/4), int(1600/4))), "corner", i512.getpixel((2, 2)))
