#!/usr/bin/env python3
"""ZCode Web 图标 v3（Pillow）：蓝渐变圆角方 + 白色地球（裁剪在圆内）+ 青色扫描点缀。
1024 绘制 → LANCZOS 缩到各密度。"""
import os
from PIL import Image, ImageDraw, ImageFilter

BASE = 1024
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ROOT = os.path.dirname(os.path.abspath(__file__))
CYAN = (34, 211, 238)
WHITE = (255, 255, 255)

def build():
    s = BASE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    # ① 背景圆角方 + 垂直渐变
    grad = Image.new("RGBA", (s, s))
    gd = ImageDraw.Draw(grad)
    top, bot = (59, 130, 246), (29, 78, 216)
    for y in range(s):
        t = y / s
        gd.line([(0, y), (s, y)], fill=(
            int(top[0] + (bot[0] - top[0]) * t),
            int(top[1] + (bot[1] - top[1]) * t),
            int(top[2] + (bot[2] - top[2]) * t), 255))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s, s], radius=int(s * 42 / 192), fill=255)
    img.paste(grad, (0, 0), mask)

    # ② 地球层（独立图层，圆内裁剪）
    globe = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    gd = ImageDraw.Draw(globe)
    cx, cy, r = s * 0.5, s * 0.47, s * 0.26
    lw = int(s * 10 / 192)
    gd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=lw)
    gd.ellipse([cx - r * 0.42, cy - r, cx + r * 0.42, cy + r], outline=WHITE,
               width=int(s * 7 / 192))
    gd.line([cx - r * 0.92, cy, cx + r * 0.92, cy], fill=WHITE, width=int(s * 7 / 192))
    # 圆内裁剪
    clip = Image.new("L", (s, s), 0)
    ImageDraw.Draw(clip).ellipse([cx - r - lw, cy - r - lw, cx + r + lw, cy + r + lw], fill=255)
    img.paste(globe, (0, 0), Image.composite(globe.split()[3], Image.new("L", (s, s), 0), clip))

    # ③ 青色扫描点缀：右下角小圆点 + 左上角短括角
    d = ImageDraw.Draw(img)
    dot_r = int(s * 7 / 192)
    dx, dy = s * 0.76, s * 0.76
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([dx - dot_r * 2.4, dy - dot_r * 2.4, dx + dot_r * 2.4, dy + dot_r * 2.4],
                                 fill=CYAN + (110,))
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.02))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)
    d.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r], fill=CYAN)
    # 左上括角
    arm = int(s * 0.13)
    bw = int(s * 9 / 192)
    ox, oy = int(s * 0.10), int(s * 0.10)
    d.rounded_rectangle([ox, oy, ox + arm, oy + bw], radius=bw // 2, fill=CYAN + (230,))
    d.rounded_rectangle([ox, oy, ox + bw, oy + arm], radius=bw // 2, fill=CYAN + (230,))
    return img

icon = build()
for name, px in DENSITIES.items():
    out = os.path.join(ROOT, "res", f"mipmap-{name}")
    os.makedirs(out, exist_ok=True)
    icon.resize((px, px), Image.LANCZOS).save(os.path.join(out, "ic_launcher.png"))
    print(name, px)
print("ok")
