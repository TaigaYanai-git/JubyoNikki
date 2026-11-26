#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
  python3 tools/make_icon.py          # .icon を作る
  python3 tools/make_icon.py --guide  # 黄金比の補助線を描いた SVG も書き出す（docs/icon-guide.svg）

絵柄：紺の表紙の日記帳に、白く「10」と書いてある。左に背表紙、右に赤いゴムバンド、右下に紙の厚み。
寸法はすべて黄金比 φ（1.618…）から決める。
  - 日記帳の縦       = アイコンの幅 ÷ √φ、横 = 縦 ÷ φ（黄金長方形）
  - 背表紙の幅       = 横 ÷ φ⁴、ゴムバンドと紙の厚み = 横 ÷ φ⁶、角の丸み = 横 ÷ φ⁵
  - 「10」の幅       = 背表紙とバンドの間の面の幅 ÷ √φ、「0」の幅 = 高さ ÷ φ、線の太さ = 高さ ÷ φ³、すき間 = 線 ÷ φ
  - 「10」の中心     = 表紙を上下 1 : φ に分ける線の上
文字はフォントではなく図形で描く（Icon Composer は SVG の文字を描かないため）。
Icon Composer は stroke を面として扱うので、すべて塗りの図形（evenodd）で描く。
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

# 日記帳（表紙）：縦 : 横 = φ : 1（黄金長方形）
BOOK_H = S / PHI ** 0.5             # 805
BOOK_W = BOOK_H / PHI               # 497
BOOK_R = BOOK_W / PHI ** 5          # 角の丸み 45
SPINE = BOOK_W / PHI ** 4           # 背表紙の幅 73
BAND = BOOK_W / PHI ** 6            # ゴムバンドの幅 28
PAGE = BOOK_W / PHI ** 6            # 紙の厚み（右と下にのぞく） 28
# 紙の厚みまで含めて中央に置く
BX = (S - BOOK_W - PAGE) / 2
BY = (S - BOOK_H - PAGE) / 2
BAND_X = BX + BOOK_W - SPINE / PHI  # バンドは右端から 背表紙の幅 ÷ φ だけ内側

# 表紙の「10」：高さ = 表紙の幅 ÷ φ、中心は表紙を上下 1 : φ に分ける線の上（ノートの題を書く位置）
FACE_W = BOOK_W - SPINE - SPINE / PHI - BAND   # 背表紙とバンドの間の面の幅
# 「10」全体の幅（旗 + 線 + すき間 + 0 の幅 = 高さ × (1/φ³ + 1/φ³ + 1/φ⁴ + 1/φ)）を 面の幅 ÷ √φ にする
H = FACE_W / PHI ** 0.5 / (2 / PHI ** 3 + 1 / PHI ** 4 + 1 / PHI)
W0 = H / PHI                        # 「0」の幅
T = H / PHI ** 3                    # 線の太さ
GAP = T / PHI
FLAG = W0 / PHI ** 2
FACE_X0 = BX + SPINE                # 背表紙とバンドの間の面
FACE_X1 = BAND_X  # ここまでが表紙の面
CX = (FACE_X0 + FACE_X1) / 2
CY = BY + BOOK_H / PHI ** 2

def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n{body}\n</svg>\n'


def f(v):
    return f"{v:.2f}"


def circle_path(cx, cy, r):
    return f"M{f(cx - r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx + r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx - r)},{f(cy)} Z"


def stadium(x, y, w, h):
    """縦長の角丸（半円の端）の長方形"""
    r = w / 2
    return (f"M{f(x)},{f(y + r)} A{f(r)},{f(r)} 0 0 1 {f(x + w)},{f(y + r)} "
            f"L{f(x + w)},{f(y + h - r)} A{f(r)},{f(r)} 0 0 1 {f(x)},{f(y + h - r)} Z")


def pt(r, deg):
    a = math.radians(deg)
    return CX + r * math.cos(a), CY + r * math.sin(a)


def arc_band(r_in, r_out, a0, a1):
    """端が丸い弧の帯（a0→a1 度、SVG の角度で -90 が真上）"""
    rm, rw = (r_in + r_out) / 2, (r_out - r_in) / 2
    o0, o1 = pt(r_out, a0), pt(r_out, a1)
    i0, i1 = pt(r_in, a0), pt(r_in, a1)
    large = 1 if a1 - a0 > 180 else 0
    return (f"M{f(o0[0])},{f(o0[1])} A{f(r_out)},{f(r_out)} 0 {large} 1 {f(o1[0])},{f(o1[1])} "
            f"A{f(rw)},{f(rw)} 0 0 1 {f(i1[0])},{f(i1[1])} "
            f"A{f(r_in)},{f(r_in)} 0 {large} 0 {f(i0[0])},{f(i0[1])} "
            f"A{f(rw)},{f(rw)} 0 0 1 {f(o0[0])},{f(o0[1])} Z")


# 「10」の配置：「1」は旗の先から軸の右端まで、「0」は幅 W0。表紙の面の中央に置く
one_w = FLAG + T
total_w = one_w + GAP + W0
x1 = CX - total_w / 2 + FLAG
x0 = x1 + T + GAP
top = CY - H / 2

flag_len = FLAG * PHI
flag_ang = 180 - math.degrees(math.atan2(1, PHI))  # 左下向き（傾き 1:φ）
one = (f'<path fill="#000" d="{stadium(x1, top, T, H)}"/>'
       f'<rect x="{f(x1 + T / 2)}" y="{f(top)}" width="{f(flag_len)}" height="{f(T)}" rx="{f(T / 2)}" fill="#000" '
       f'transform="rotate({f(flag_ang)} {f(x1 + T / 2)} {f(top + T / 2)})"/>')
zero = (f'<path fill="#000" fill-rule="evenodd" d="{stadium(x0, top, W0, H)} '
        f'{stadium(x0 + T, top + T, W0 - 2 * T, H - 2 * T)}"/>')


def rrect(x, y, w, h, r):
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(r)}" fill="#000"/>'


layers = {
    "digits": svg(one + zero),
    "band": svg(f'<rect x="{f(BAND_X)}" y="{f(BY - 6)}" width="{f(BAND)}" height="{f(BOOK_H + 12)}" rx="{f(BAND / 3)}" fill="#000"/>'),
    "spine": svg(f'<path fill="#000" d="M{f(BX + BOOK_R)},{f(BY)} L{f(BX + SPINE)},{f(BY)} L{f(BX + SPINE)},{f(BY + BOOK_H)} '
                 f'L{f(BX + BOOK_R)},{f(BY + BOOK_H)} A{f(BOOK_R)},{f(BOOK_R)} 0 0 1 {f(BX)},{f(BY + BOOK_H - BOOK_R)} '
                 f'L{f(BX)},{f(BY + BOOK_R)} A{f(BOOK_R)},{f(BOOK_R)} 0 0 1 {f(BX + BOOK_R)},{f(BY)} Z"/>'),
    "cover": svg(rrect(BX, BY, BOOK_W, BOOK_H, BOOK_R)),
    "pages": svg(rrect(BX + PAGE, BY + PAGE, BOOK_W, BOOK_H, BOOK_R)),
}
for old in (ICON / "Assets").glob("*.svg"):
    old.unlink()
for name, body in layers.items():
    (ICON / "Assets" / f"{name}.svg").write_text(body)


def srgb(rgb):
    return "srgb:" + ",".join(f"{c:.5f}" for c in rgb) + ",1.00000"


def solid(light, dark):
    return [{"value": {"solid": srgb(light)}}, {"appearance": "dark", "value": {"solid": srgb(dark)}}]


# 背景は明るい紙色、日記帳は濃い紺の表紙に白い「10」、赤いゴムバンド
BG = (0.96, 0.94, 0.90)
BG_DARK = (0.16, 0.14, 0.20)
NAVY = (0.16, 0.17, 0.30)
SPINE_C = (0.11, 0.12, 0.22)
WHITE = (1.0, 1.0, 1.0)
RED = (0.88, 0.27, 0.25)
PAPER = (0.99, 0.97, 0.92)


def layer(name, light, dark=None, glass=True):
    return {"glass": glass, "image-name": f"{name}.svg", "name": name,
            "position": {"scale": 1, "translation-in-points": [0, 0]},
            "fill-specializations": solid(light, dark or light)}


doc = {
    "fill-specializations": [
        {"value": {"automatic-gradient": srgb(BG)}},
        {"appearance": "dark", "value": {"automatic-gradient": srgb(BG_DARK)}},
    ],
    "groups": [
        {"layers": [layer("digits", WHITE), layer("band", RED)],
         "shadow": {"kind": "neutral", "opacity": 0.35},
         "translucency": {"enabled": False, "value": 0}},
        {"layers": [layer("spine", SPINE_C, glass=False), layer("cover", NAVY),
                    layer("pages", PAPER, glass=False)],
         "shadow": {"kind": "neutral", "opacity": 0.45},
         "translucency": {"enabled": False, "value": 0}},
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(ICON / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")

if "--guide" in sys.argv:
    g = '<g fill="none" stroke="#e0567a" stroke-width="2" stroke-dasharray="8 6">'
    g += f'<rect x="{f(BX)}" y="{f(BY)}" width="{f(BOOK_W)}" height="{f(BOOK_H)}"/>'
    g += f'<line x1="{f(BX)}" y1="{f(CY)}" x2="{f(BX + BOOK_W)}" y2="{f(CY)}"/>'
    g += f'<rect x="{f(x0)}" y="{f(top)}" width="{f(W0)}" height="{f(H)}"/>'
    g += '</g>'
    body = "".join(layers[k].split("\n")[1] for k in ("pages", "cover", "spine", "band", "digits"))
    (ROOT / "docs" / "icon-guide.svg").write_text(svg(f'<rect width="{S}" height="{S}" fill="#fff"/><g opacity="0.25">{body}</g>{g}'))

print(f"φ={PHI:.4f} 日記帳={BOOK_W:.0f}×{BOOK_H:.0f} 背表紙={SPINE:.0f} 数字の高さ={H:.0f} 0の幅={W0:.0f} 線={T:.0f}")
