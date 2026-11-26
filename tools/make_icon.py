#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
  python3 tools/make_icon.py          # .icon を作る
  python3 tools/make_icon.py --guide  # 黄金比の補助線を描いた SVG も書き出す（docs/icon-guide.svg）

絵柄：暗い地に、開いた本。左のページに「1」、右のページに「0」。綴じ目から赤いしおり。
寸法はすべて黄金比 φ（1.618…）から決める。
  - 見開きの幅        = アイコンの幅 ÷ φ
  - 1ページの縦       = 1ページの横 × √φ（見開き全体は 横 : 縦 ≈ φ : 1）
  - ページの反り       = ページの縦 ÷ φ⁵（綴じ目に向かって下がる）、下にのぞく紙の厚み = 縦 ÷ φ⁶
  - 「1」「0」の高さ  = ページの縦 ÷ φ、「0」の幅 = 高さ ÷ φ、線の太さ = 高さ ÷ φ³、綴じ目からのすき間 = 線 ÷ φ
  - しおりの幅         = 線の太さ ÷ φ、長さ = 反り × φ²
文字はフォントではなく図形で描く（Icon Composer は SVG の文字を描かないため）。
Icon Composer は stroke を面として扱うので、すべて塗りの図形で描く。
"""
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "JubyoNikki" / "AppIcon.icon"
(ICON / "Assets").mkdir(parents=True, exist_ok=True)

PHI = (1 + 5 ** 0.5) / 2
S = 1024

BOOK_W = S / PHI                    # 見開きの幅 633
GUTTER = BOOK_W / PHI ** 7          # 綴じ目のすき間 22
PAGE_W = (BOOK_W - GUTTER) / 2      # 1ページの横 305
PAGE_H = PAGE_W * PHI ** 0.5        # 1ページの縦 388
DIP = PAGE_H / PHI ** 5             # ページの反り 35
STACK = PAGE_H / PHI ** 6           # 下にのぞく紙の厚み 22
CX = S / 2
TOP = (S - PAGE_H - DIP - STACK) / 2  # 反りと厚みまで含めて上下中央

H = PAGE_H / PHI                    # 数字の高さ 240
W0 = H / PHI                        # 「0」の幅
T = H / PHI ** 3                    # 線の太さ
FLAG = W0 / PHI ** 2
RIBBON_W = T / PHI
RIBBON_L = DIP * PHI ** 2


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n{body}\n</svg>\n'


def f(v):
    return f"{v:.2f}"


def stadium(x, y, w, h):
    r = w / 2
    return (f"M{f(x)},{f(y + r)} A{f(r)},{f(r)} 0 0 1 {f(x + w)},{f(y + r)} "
            f"L{f(x + w)},{f(y + h - r)} A{f(r)},{f(r)} 0 0 1 {f(x)},{f(y + h - r)} Z")


def page(side, dy=0.0):
    """1ページ。side=-1 で左、+1 で右。上下の辺は綴じ目に向かってなだらかに下がる"""
    xi = CX + side * GUTTER / 2                 # 綴じ目側
    xo = CX + side * (GUTTER / 2 + PAGE_W)      # 外側
    top_i, top_o = TOP + DIP + dy, TOP + dy
    bot_i, bot_o = TOP + DIP + PAGE_H + dy, TOP + PAGE_H + dy
    r = PAGE_W / PHI ** 6                       # 外側の角の丸み

    def ctrl(y_i, y_o):
        return xi + side * PAGE_W / PHI ** 2, y_o + (y_i - y_o) * 0.15

    c1, c2 = ctrl(top_i, top_o), ctrl(bot_i, bot_o)
    return (f"M{f(xi)},{f(top_i)} Q{f(c1[0])},{f(c1[1])} {f(xo - side * r)},{f(top_o)} "
            f"Q{f(xo)},{f(top_o)} {f(xo)},{f(top_o + r)} "
            f"L{f(xo)},{f(bot_o - r)} Q{f(xo)},{f(bot_o)} {f(xo - side * r)},{f(bot_o)} "
            f"Q{f(c2[0])},{f(c2[1])} {f(xi)},{f(bot_i)} Z")


def page_center(side):
    return CX + side * (GUTTER / 2 + PAGE_W / 2), TOP + DIP / 2 + PAGE_H / 2


# 「1」と「0」は綴じ目の両側に寄せて、ひと続きの「10」として読めるようにする。
# 綴じ目からのすき間 = 線の太さ ÷ φ
SIDE_GAP = GUTTER / 2 + T / PHI
_, ly = page_center(-1)
x1 = CX - SIDE_GAP - T          # 「1」の軸の左端（軸の右端が綴じ目の手前）
top1 = ly - H / 2
flag_len = FLAG * PHI
flag_ang = 180 - math.degrees(math.atan2(1, PHI))  # 左下向き（傾き 1:φ）
one = (f'<path fill="#000" d="{stadium(x1, top1, T, H)}"/>'
       f'<rect x="{f(x1 + T / 2)}" y="{f(top1)}" width="{f(flag_len)}" height="{f(T)}" rx="{f(T / 2)}" fill="#000" '
       f'transform="rotate({f(flag_ang)} {f(x1 + T / 2)} {f(top1 + T / 2)})"/>')
# 右のページの「0」
_, ry = page_center(1)
x0, top0 = CX + SIDE_GAP, ry - H / 2
zero = (f'<path fill="#000" fill-rule="evenodd" d="{stadium(x0, top0, W0, H)} '
        f'{stadium(x0 + T, top0 + T, W0 - 2 * T, H - 2 * T)}"/>')

# しおり：綴じ目の下から垂れる。先は V 字に切る
rb_top = TOP + DIP + PAGE_H - RIBBON_L * 0.2
rb_bot = rb_top + RIBBON_L
ribbon = (f'<path fill="#000" d="M{f(CX - RIBBON_W / 2)},{f(rb_top)} L{f(CX + RIBBON_W / 2)},{f(rb_top)} '
          f'L{f(CX + RIBBON_W / 2)},{f(rb_bot)} L{f(CX)},{f(rb_bot - RIBBON_W * 0.8)} L{f(CX - RIBBON_W / 2)},{f(rb_bot)} Z"/>')

layers = {
    "digits": svg(one + zero),
    "pages": svg(f'<path fill="#000" d="{page(-1)}"/><path fill="#000" d="{page(1)}"/>'),
    "ribbon": svg(ribbon),
    "stack": svg(f'<path fill="#000" d="{page(-1, STACK)}"/><path fill="#000" d="{page(1, STACK)}"/>'
                 f'<rect x="{f(CX - GUTTER / 2 - 1)}" y="{f(TOP + DIP)}" width="{f(GUTTER + 2)}" height="{f(PAGE_H + STACK)}" fill="#000"/>'),
}
for old in (ICON / "Assets").glob("*.svg"):
    old.unlink()
for name, body in layers.items():
    (ICON / "Assets" / f"{name}.svg").write_text(body)


def srgb(rgb):
    return "srgb:" + ",".join(f"{c:.5f}" for c in rgb) + ",1.00000"


def solid(light, dark):
    return [{"value": {"solid": srgb(light)}}, {"appearance": "dark", "value": {"solid": srgb(dark)}}]


# 暗い地に白いページ、数字は地と同じ色、しおりは赤。ライトもダークも同じ配色
BG = (0.20, 0.17, 0.27)
PAPER = (1.0, 1.0, 1.0)
STACK_C = (0.72, 0.70, 0.80)
INK = (0.20, 0.17, 0.27)
RED = (1.0, 0.33, 0.30)


def layer(name, color, glass=True):
    return {"glass": glass, "image-name": f"{name}.svg", "name": name,
            "position": {"scale": 1, "translation-in-points": [0, 0]},
            "fill-specializations": solid(color, color)}


doc = {
    "fill-specializations": [
        {"value": {"automatic-gradient": srgb(BG)}},
        {"appearance": "dark", "value": {"automatic-gradient": srgb(BG)}},
    ],
    "groups": [
        {"layers": [layer("digits", INK, glass=False), layer("pages", PAPER)],
         "shadow": {"kind": "neutral", "opacity": 0.35},
         "translucency": {"enabled": False, "value": 0}},
        {"layers": [layer("ribbon", RED), layer("stack", STACK_C, glass=False)],
         "shadow": {"kind": "neutral", "opacity": 0.3},
         "translucency": {"enabled": False, "value": 0}},
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(ICON / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")

if "--guide" in sys.argv:
    g = '<g fill="none" stroke="#e0567a" stroke-width="2" stroke-dasharray="8 6">'
    g += f'<rect x="{f(CX - BOOK_W / 2)}" y="{f(TOP)}" width="{f(BOOK_W)}" height="{f(PAGE_H + DIP)}"/>'
    g += f'<rect x="{f(x0)}" y="{f(top0)}" width="{f(W0)}" height="{f(H)}"/>'
    g += '</g>'
    body = "".join(layers[k].split("\n")[1] for k in ("stack", "ribbon", "pages", "digits"))
    (ROOT / "docs" / "icon-guide.svg").write_text(svg(f'<rect width="{S}" height="{S}" fill="#fff"/><g opacity="0.25">{body}</g>{g}'))

print(f"φ={PHI:.4f} 見開き={BOOK_W:.0f} 1ページ={PAGE_W:.0f}×{PAGE_H:.0f} 反り={DIP:.0f} 数字の高さ={H:.0f} 線={T:.0f}")
