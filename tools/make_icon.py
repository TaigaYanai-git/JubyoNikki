#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
絵柄：ストップウォッチ。針が鉛筆になっていて、0 から 10 秒（60 秒盤の 1/6）を塗りつぶした扇を指す。
  python3 tools/make_icon.py
"""
import json, math
from pathlib import Path

ICON = Path(__file__).resolve().parent.parent / "JubyoNikki" / "AppIcon.icon"
(ICON / "Assets").mkdir(parents=True, exist_ok=True)

CX, CY = 512, 560          # 文字盤の中心（竜頭の分だけ下げる）
R_RING, W_RING = 300, 64    # 外枠の半径と太さ
R_WEDGE = 236               # 10 秒の扇
ANGLE = -90 + 60            # 10 秒の位置（SVG の角度。-90 が真上）


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
            + body + "\n</svg>\n")


def pt(r, deg):
    a = math.radians(deg)
    return CX + r * math.cos(a), CY + r * math.sin(a)


def donut(ro, ri):
    """外径 ro・内径 ri の輪（Icon Composer は stroke の円を面として読むので、面で描く）"""
    def circ(r):
        return (f"M{CX - r},{CY} A{r},{r} 0 1 0 {CX + r},{CY} A{r},{r} 0 1 0 {CX - r},{CY} Z")
    return circ(ro) + " " + circ(ri)


layers = {}
# 外枠と竜頭
layers["ring"] = svg(
    f'<path fill-rule="evenodd" fill="#000" d="{donut(R_RING + W_RING / 2, R_RING - W_RING / 2)}"/>'
    f'<rect x="{CX-58}" y="{CY-R_RING-W_RING/2-78}" width="116" height="56" rx="20" fill="#000"/>'
    f'<rect x="{CX-24}" y="{CY-R_RING-W_RING/2-30}" width="48" height="40" fill="#000"/>')
# 10 秒の扇
x0, y0 = pt(R_WEDGE, -90)
x1, y1 = pt(R_WEDGE, ANGLE)
layers["wedge"] = svg(
    f'<path d="M{CX},{CY} L{x0:.1f},{y0:.1f} A{R_WEDGE},{R_WEDGE} 0 0 1 {x1:.1f},{y1:.1f} Z" fill="#000"/>')
# 鉛筆の針（右向きに描いて 10 秒の向きへ回す）。軸と芯は別のレイヤー
rot = f'transform="rotate({ANGLE} {CX} {CY})"'
L0, L1, TIP, HW = -60, 168, 254, 36
layers["pencil"] = svg(
    f'<g {rot}>'
    f'<rect x="{CX+L0}" y="{CY-HW}" width="{L1-L0}" height="{HW*2}" rx="14" fill="#000"/>'
    f'<circle cx="{CX}" cy="{CY}" r="40" fill="#000"/>'
    f'</g>')
layers["tip"] = svg(
    f'<g {rot}>'
    f'<path d="M{CX+L1+8},{CY-HW} L{CX+TIP},{CY} L{CX+L1+8},{CY+HW} Z" fill="#000" stroke="#000" stroke-width="6" stroke-linejoin="round"/>'
    f'<path d="M{CX+TIP-34},{CY-HW*0.4} L{CX+TIP},{CY} L{CX+TIP-34},{CY+HW*0.4} Z" fill="#000" fill-opacity="0"/>'
    f'</g>')
layers["lead"] = svg(
    f'<g {rot}>'
    f'<path d="M{CX+TIP-30},{CY-HW*0.36} L{CX+TIP+2},{CY} L{CX+TIP-30},{CY+HW*0.36} Z" fill="#000" stroke="#000" stroke-width="6" stroke-linejoin="round"/>'
    f'</g>')

for name, body in layers.items():
    (ICON / "Assets" / f"{name}.svg").write_text(body)


def srgb(rgb):
    return "srgb:" + ",".join(f"{c:.5f}" for c in rgb) + ",1.00000"


def solid(rgb, dark=None):
    return [{"value": {"solid": srgb(rgb)}}, {"appearance": "dark", "value": {"solid": srgb(dark or rgb)}}]


INK = (0.13, 0.12, 0.16)
LAV = (0.80, 0.74, 0.93)   # Our Music の淡いラベンダー寄り
GRAY = (0.93, 0.80, 0.62)   # 削った木の色


PAPER = (0.93, 0.91, 0.97)  # ダークのときの輪と鉛筆


def layer(name, color, glass=True, dark=None):
    return {"glass": glass, "image-name": f"{name}.svg", "name": name,
            "position": {"scale": 1, "translation-in-points": [0, 0]},
            "fill-specializations": solid(color, dark)}


doc = {
    "fill-specializations": [
        {"value": {"automatic-gradient": "srgb:1.00000,1.00000,1.00000,1.00000"}},
        {"appearance": "dark", "value": {"automatic-gradient": "srgb:0.16000,0.14000,0.21000,1.00000"}},
    ],
    "groups": [
        {"layers": [layer("lead", INK, glass=False), layer("tip", GRAY), layer("pencil", INK, dark=PAPER)],
         "shadow": {"kind": "neutral", "opacity": 0.5},
         "translucency": {"enabled": True, "value": 0.4}},
        {"layers": [layer("ring", INK, dark=PAPER), layer("wedge", LAV, glass=False)],
         "shadow": {"kind": "neutral", "opacity": 0.4},
         "translucency": {"enabled": True, "value": 0.5}},
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(ICON / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")
print("wrote", ICON)
