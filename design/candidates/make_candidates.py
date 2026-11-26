#!/usr/bin/env python3
"""アイコン候補を3つ作る（Icon Composer の .icon）。どれも寸法は黄金比 φ から。
  A  白い地：今のタイマーをライトに（淡い外枠・琥珀の 10 秒の弧・インディゴの「10」）
  C  「1」＋ストップウォッチの「0」：0 がそのままタイマーになっている（インディゴの地）
  （B の赤い地はやめた。インディゴの地のタイマーは本体のアイコン tools/make_icon.py）
  python3 design/candidates/make_candidates.py
"""
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import glyphs

OUT = Path(__file__).resolve().parent
PHI = (1 + 5 ** 0.5) / 2
S = 1024


def f(v):
    return f"{v:.2f}"


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n{body}\n</svg>\n'


def circle(cx, cy, r):
    return f"M{f(cx - r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx + r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx - r)},{f(cy)} Z"


def ring(cx, cy, ro, ri):
    return f'<path fill="#000" fill-rule="evenodd" d="{circle(cx, cy, ro)} {circle(cx, cy, ri)}"/>'


def arc(cx, cy, ri, ro, a0, a1):
    def pt(r, d):
        a = math.radians(d)
        return cx + r * math.cos(a), cy + r * math.sin(a)
    rw = (ro - ri) / 2
    o0, o1, i0, i1 = pt(ro, a0), pt(ro, a1), pt(ri, a0), pt(ri, a1)
    return (f'<path fill="#000" d="M{f(o0[0])},{f(o0[1])} A{f(ro)},{f(ro)} 0 0 1 {f(o1[0])},{f(o1[1])} '
            f'A{f(rw)},{f(rw)} 0 0 1 {f(i1[0])},{f(i1[1])} A{f(ri)},{f(ri)} 0 0 0 {f(i0[0])},{f(i0[1])} '
            f'A{f(rw)},{f(rw)} 0 0 1 {f(o0[0])},{f(o0[1])} Z"/>')


def stadium(x, y, w, h):
    r = w / 2
    return (f"M{f(x)},{f(y + r)} A{f(r)},{f(r)} 0 0 1 {f(x + w)},{f(y + r)} "
            f"L{f(x + w)},{f(y + h - r)} A{f(r)},{f(r)} 0 0 1 {f(x)},{f(y + h - r)} Z")


def zero(x, top, w, h, t):
    return f'<path fill="#000" fill-rule="evenodd" d="{stadium(x, top, w, h)} {stadium(x + t, top + t, w - 2 * t, h - 2 * t)}"/>'


def crown(cx, ring_top, w_ring, cw, ch, sw, sh):
    return (f'<rect x="{f(cx - cw / 2)}" y="{f(ring_top - sh - ch)}" width="{f(cw)}" height="{f(ch)}" rx="{f(ch / 2)}" fill="#000"/>'
            f'<rect x="{f(cx - sw / 2)}" y="{f(ring_top - sh - 2)}" width="{f(sw)}" height="{f(sh + w_ring / 2)}" fill="#000"/>')


def srgb(c):
    return "srgb:" + ",".join(f"{v:.5f}" for v in c) + ",1.00000"


def write_icon(name, bg, groups, layers):
    d = OUT / f"{name}.icon"
    (d / "Assets").mkdir(parents=True, exist_ok=True)
    for old in (d / "Assets").glob("*.svg"):
        old.unlink()
    for k, body in layers.items():
        (d / "Assets" / f"{k}.svg").write_text(svg(body))

    def layer(k, c, glass=True):
        v = srgb(c)
        return {"glass": glass, "image-name": f"{k}.svg", "name": k,
                "position": {"scale": 1, "translation-in-points": [0, 0]},
                "fill-specializations": [{"value": {"solid": v}}, {"appearance": "dark", "value": {"solid": v}}]}

    doc = {
        "fill-specializations": [{"value": {"automatic-gradient": srgb(bg)}},
                                 {"appearance": "dark", "value": {"automatic-gradient": srgb(bg)}}],
        "groups": [{"layers": [layer(*l) for l in g],
                    "shadow": {"kind": "neutral", "opacity": 0.3},
                    "translucency": {"enabled": False, "value": 0}} for g in groups],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }
    (d / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")


INDIGO = (0.19, 0.23, 0.55)
WHITE = (1, 1, 1)
AMBER = (1.0, 0.76, 0.27)

# ---- A と B：今のタイマーと同じ構図（外枠の直径 = 幅 ÷ φ、太さ = 半径 ÷ φ³、「10」の高さ = 内径 ÷ φ）
R_OUT = S / PHI / 2
W = R_OUT / PHI ** 3
R_IN = R_OUT - W
CW, CH = R_OUT / PHI ** 2, W
SW, SH = CW / PHI ** 2, W / PHI
CX = S / 2
CY = S / 2 + ((CH + SH + 2 * R_OUT) / 2 - R_OUT)
H = 2 * R_IN / PHI
W0, T = H / PHI, H / PHI ** 3
GAP, FLAG = T / PHI, glyphs.one_flag_width(H, T)
tw = FLAG + T + GAP + W0
x1 = CX - tw / 2 + FLAG
timer_layers = {
    "digits": glyphs.one(x1, CY - H / 2, H, T) + zero(x1 + T + GAP, CY - H / 2, W0, H, T),
    "progress": arc(CX, CY, R_IN, R_OUT, -90, -30),
    "crown": crown(CX, CY - R_OUT, W, CW, CH, SW, SH),
    "ring": ring(CX, CY, R_OUT, R_IN),
}
write_icon("A-white", (0.98, 0.98, 1.0),
           [[("digits", INDIGO)], [("progress", AMBER), ("crown", INDIGO), ("ring", (0.86, 0.88, 0.97), False)]],
           timer_layers)

# ---- C：「1」＋ストップウォッチの「0」
D = S / PHI ** 1.5                  # 0（ストップウォッチ）の直径 = 1 の高さ
Tc = D / PHI ** 3.5                 # 線の太さ（外枠の太さも同じ）
FLAGc = glyphs.one_flag_width(D, Tc)
GAPc = Tc / PHI
twc = FLAGc + Tc + GAPc + D
x1c = S / 2 - twc / 2 + FLAGc
cxc = x1c + Tc + GAPc + D / 2
crown_h = Tc + Tc / PHI
cyc = S / 2 + crown_h / 2
Rc = D / 2
c_layers = {
    "one": glyphs.one(x1c, cyc - D / 2, D, Tc),
    "progress": arc(cxc, cyc, Rc - Tc, Rc, -90, -30),
    "crown": crown(cxc, cyc - Rc, Tc, D / PHI ** 2.5, Tc, D / PHI ** 4.5, Tc / PHI),
    "ring": ring(cxc, cyc, Rc, Rc - Tc),
}
write_icon("C-one-watch", INDIGO,
           [[("one", WHITE), ("progress", AMBER), ("crown", WHITE)], [("ring", WHITE, True)]],
           c_layers)
print("ok")
