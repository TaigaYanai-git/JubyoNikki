#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
  python3 tools/make_icon.py          # .icon を作る
  python3 tools/make_icon.py --guide  # 黄金比の補助線を描いた SVG も書き出す（docs/icon-guide.svg）

絵柄：ストップウォッチの文字盤に「10」。外枠の 1/6（＝60 秒盤の 10 秒）だけ濃く塗る。
寸法はすべて黄金比 φ から決める（φ = 1.618…）。
  - 外枠の直径      = アイコンの幅 ÷ φ
  - 外枠の太さ      = 外枠の半径 ÷ φ⁴
  - 「10」の高さ    = 外枠の内径 ÷ φ
  - 「0」の幅       = 「10」の高さ ÷ φ（φ の長方形）
  - 数字の線の太さ  = 「10」の高さ ÷ φ³
  - 「1」と「0」の間 = 線の太さ ÷ φ
  - 竜頭の幅        = 外枠の半径 ÷ φ²、高さ = 外枠の太さ
文字はフォントではなく図形で描く（Icon Composer は SVG の文字を描かないため）。
Icon Composer は stroke を面として扱うので、輪や数字はすべて塗りの図形（evenodd）で描く。
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

R_OUT = S / PHI / 2                 # 316.4
W_RING = R_OUT / PHI ** 4           # 46.2
R_IN = R_OUT - W_RING
CROWN_W = R_OUT / PHI ** 2          # 120.9
CROWN_H = W_RING
STEM_W = CROWN_W / PHI ** 2
STEM_H = W_RING / PHI
# 竜頭まで含めた全体の高さの中心をアイコンの中心にそろえる
TOTAL_H = CROWN_H + STEM_H + 2 * R_OUT
CX = S / 2
CY = S / 2 + (TOTAL_H / 2 - R_OUT)

H = 2 * R_IN / PHI                  # 「10」の高さ
W0 = H / PHI                        # 「0」の幅
T = H / PHI ** 3                    # 線の太さ
GAP = T / PHI
FLAG = W0 / PHI ** 2                # 「1」の旗の横の長さ
ARC = 60                            # 10 秒（60 秒盤の 1/6）


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


# 「10」の配置：「1」は旗の先から軸の右端まで、「0」は幅 W0。全体を中央に置く
one_w = FLAG + T
total_w = one_w + GAP + W0
x1 = CX - total_w / 2 + FLAG        # 「1」の軸の左端
x0 = x1 + T + GAP                   # 「0」の左端
top = CY - H / 2

# 「1」：軸と、左下へ伸びる旗（軸の上端から 角度 atan(1/φ) で下がる、端の丸い棒）
flag_len = FLAG * PHI
flag_ang = 180 - math.degrees(math.atan2(1, PHI))  # 左下向き（傾き 1:φ）
one = (f'<path fill="#000" d="{stadium(x1, top, T, H)}"/>'
       f'<rect x="{f(x1 + T / 2)}" y="{f(top)}" width="{f(flag_len)}" height="{f(T)}" rx="{f(T / 2)}" fill="#000" '
       f'transform="rotate({f(flag_ang)} {f(x1 + T / 2)} {f(top + T / 2)})"/>')
zero = (f'<path fill="#000" fill-rule="evenodd" d="{stadium(x0, top, W0, H)} '
        f'{stadium(x0 + T, top + T, W0 - 2 * T, H - 2 * T)}"/>')

layers = {
    "digits": svg(one + zero),
    "progress": svg(f'<path fill="#000" d="{arc_band(R_IN, R_OUT, -90, -90 + ARC)}"/>'),
    "ring": svg(f'<path fill="#000" fill-rule="evenodd" d="{circle_path(CX, CY, R_OUT)} {circle_path(CX, CY, R_IN)}"/>'),
    "crown": svg(
        f'<rect x="{f(CX - CROWN_W / 2)}" y="{f(CY - R_OUT - STEM_H - CROWN_H)}" width="{f(CROWN_W)}" height="{f(CROWN_H)}" rx="{f(CROWN_H / 2)}" fill="#000"/>'
        f'<rect x="{f(CX - STEM_W / 2)}" y="{f(CY - R_OUT - STEM_H - 2)}" width="{f(STEM_W)}" height="{f(STEM_H + W_RING / 2)}" fill="#000"/>'),
}
for old in (ICON / "Assets").glob("*.svg"):
    old.unlink()
for name, body in layers.items():
    (ICON / "Assets" / f"{name}.svg").write_text(body)


def srgb(rgb):
    return "srgb:" + ",".join(f"{c:.5f}" for c in rgb) + ",1.00000"


def solid(light, dark):
    return [{"value": {"solid": srgb(light)}}, {"appearance": "dark", "value": {"solid": srgb(dark)}}]


INK = (0.18, 0.145, 0.25)      # Our Music の文字色 #2E2540
PAPER = (0.93, 0.90, 0.97)
TRACK = (0.86, 0.82, 0.95)     # 外枠の残り（淡いラベンダー）
TRACK_DARK = (0.30, 0.26, 0.40)


def layer(name, light, dark, glass=True):
    return {"glass": glass, "image-name": f"{name}.svg", "name": name,
            "position": {"scale": 1, "translation-in-points": [0, 0]},
            "fill-specializations": solid(light, dark)}


doc = {
    "fill-specializations": [
        {"value": {"automatic-gradient": "srgb:1.00000,1.00000,1.00000,1.00000"}},
        {"appearance": "dark", "value": {"automatic-gradient": "srgb:0.16000,0.14000,0.21000,1.00000"}},
    ],
    "groups": [
        {"layers": [layer("digits", INK, PAPER)],
         "shadow": {"kind": "neutral", "opacity": 0.5},
         "translucency": {"enabled": True, "value": 0.4}},
        {"layers": [layer("progress", INK, PAPER), layer("crown", INK, PAPER),
                    layer("ring", TRACK, TRACK_DARK, glass=False)],
         "shadow": {"kind": "neutral", "opacity": 0.4},
         "translucency": {"enabled": True, "value": 0.5}},
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(ICON / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")

if "--guide" in sys.argv:
    g = '<g fill="none" stroke="#e0567a" stroke-width="2" stroke-dasharray="8 6">'
    g += f'<circle cx="{f(CX)}" cy="{f(CY)}" r="{f(R_OUT)}"/><circle cx="{f(CX)}" cy="{f(CY)}" r="{f(R_IN)}"/>'
    g += f'<rect x="{f(x0)}" y="{f(top)}" width="{f(W0)}" height="{f(H)}"/>'
    g += f'<rect x="{f(x1 - FLAG)}" y="{f(top)}" width="{f(total_w)}" height="{f(H)}"/>'
    g += '</g>'
    body = "".join(layers[k].split("\n")[1] for k in ("ring", "progress", "crown", "digits"))
    (ROOT / "docs" / "icon-guide.svg").write_text(svg(f'<rect width="{S}" height="{S}" fill="#fff"/><g opacity="0.25">{body}</g>{g}'))

print(f"φ={PHI:.4f} 外枠直径={2 * R_OUT:.1f} 太さ={W_RING:.1f} 数字の高さ={H:.1f} 0の幅={W0:.1f} 線={T:.1f}")
