#!/usr/bin/env python3
"""アイコン候補 A〜E（Icon Composer の .icon）。時計らしさ・ガラス・日記らしさを全部入れる。
  A page-watch  : 傾いた日記のページの上に、ガラスのストップウォッチ（10 秒の琥珀の弧と「10」）
  B pen-watch   : 万年筆が「1」、ストップウォッチが「0」
  C cover-window: 日記帳の表紙に丸いガラスの窓。窓の中に「10」と 10 秒の弧、しおりのリボン
  D hourglass   : 上下の台が閉じた日記帳の砂時計。ガラスの胴に琥珀の砂
  E pages-hand  : 重ねたガラスのページ。いちばん前のページに時計の針と 10 秒の扇、下に罫線
寸法は黄金比 φ を基準に決める。
  python3 design/candidates2/make.py && ictool で PNG に書き出す（下の export.sh）
"""
import json
import math
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT.parents[1] / "tools"))
import glyphs  # noqa: E402

PHI = glyphs.PHI
S = 1024
f = glyphs.f

INDIGO = (0.19, 0.23, 0.55)
INDIGO_D = (0.11, 0.13, 0.33)
INDIGO_L = (0.62, 0.66, 0.90)
LAV = (0.93, 0.94, 0.99)
WHITE = (1, 1, 1)
AMBER = (1.0, 0.74, 0.26)


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n{body}\n</svg>\n'


def circle(cx, cy, r):
    return f"M{f(cx - r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx + r)},{f(cy)} A{f(r)},{f(r)} 0 1 0 {f(cx - r)},{f(cy)} Z"


def disc(cx, cy, r):
    return f'<path fill="#000" d="{circle(cx, cy, r)}"/>'


def ring(cx, cy, ro, ri):
    return f'<path fill="#000" fill-rule="evenodd" d="{circle(cx, cy, ro)} {circle(cx, cy, ri)}"/>'


def pt(cx, cy, r, deg):
    a = math.radians(deg)
    return cx + r * math.cos(a), cy + r * math.sin(a)


def arc(cx, cy, ri, ro, a0, a1):
    rw = (ro - ri) / 2
    o0, o1, i0, i1 = pt(cx, cy, ro, a0), pt(cx, cy, ro, a1), pt(cx, cy, ri, a0), pt(cx, cy, ri, a1)
    return (f'<path fill="#000" d="M{f(o0[0])},{f(o0[1])} A{f(ro)},{f(ro)} 0 0 1 {f(o1[0])},{f(o1[1])} '
            f'A{f(rw)},{f(rw)} 0 0 1 {f(i1[0])},{f(i1[1])} A{f(ri)},{f(ri)} 0 0 0 {f(i0[0])},{f(i0[1])} '
            f'A{f(rw)},{f(rw)} 0 0 1 {f(o0[0])},{f(o0[1])} Z"/>')


def sector(cx, cy, r, a0, a1):
    p0, p1 = pt(cx, cy, r, a0), pt(cx, cy, r, a1)
    return f'<path fill="#000" d="M{f(cx)},{f(cy)} L{f(p0[0])},{f(p0[1])} A{f(r)},{f(r)} 0 0 1 {f(p1[0])},{f(p1[1])} Z"/>'


def rrect(x, y, w, h, r, extra=""):
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(r)}" fill="#000" {extra}/>'


def stadium(x, y, w, h):
    r = w / 2
    return (f"M{f(x)},{f(y + r)} A{f(r)},{f(r)} 0 0 1 {f(x + w)},{f(y + r)} "
            f"L{f(x + w)},{f(y + h - r)} A{f(r)},{f(r)} 0 0 1 {f(x)},{f(y + h - r)} Z")


def zero(x, top, w, h, t):
    return f'<path fill="#000" fill-rule="evenodd" d="{stadium(x, top, w, h)} {stadium(x + t, top + t, w - 2 * t, h - 2 * t)}"/>'


def ten(cx, cy, h):
    """中央に「10」。線の太さ = 高さ ÷ φ³"""
    t = h / PHI ** 3
    w0 = h / PHI
    gap = t / PHI
    total = glyphs.one_width(h, t) + gap + w0
    x1 = cx - total / 2 + glyphs.one_flag_width(h, t)
    top = cy - h / 2
    return glyphs.one(x1, top, h, t) + zero(x1 + t + gap, top, w0, h, t)


def crown(cx, ring_top, ring_w, cw):
    ch = ring_w * 0.9
    sw, sh = cw / PHI ** 2, ring_w / PHI
    return (rrect(cx - cw / 2, ring_top - sh - ch, cw, ch, ch / 2)
            + f'<rect x="{f(cx - sw / 2)}" y="{f(ring_top - sh - 2)}" width="{f(sw)}" height="{f(sh + ring_w / 2)}" fill="#000"/>')


def srgb(c):
    return "srgb:" + ",".join(f"{v:.5f}" for v in c) + ",1.00000"


def write_icon(name, bg, groups, bg_dark=None):
    """groups: [{"layers": [(name, svgbody, color, glass, opacity)], "translucency": 0〜1, "shadow": 0〜1}]（上が手前）"""
    d = OUT / f"{name}.icon"
    (d / "Assets").mkdir(parents=True, exist_ok=True)
    for old in (d / "Assets").glob("*.svg"):
        old.unlink()
    gs = []
    for g in groups:
        ls = []
        for (ln, body, col, glass, op) in g["layers"]:
            (d / "Assets" / f"{ln}.svg").write_text(svg(body))
            layer = {"glass": glass, "image-name": f"{ln}.svg", "name": ln,
                     "position": {"scale": 1, "translation-in-points": [0, 0]},
                     "fill-specializations": [{"value": {"solid": srgb(col)}},
                                              {"appearance": "dark", "value": {"solid": srgb(col)}}]}
            if op < 1:
                layer["opacity"] = op
            ls.append(layer)
        tr = g.get("translucency", 0)
        gs.append({"layers": ls,
                   "shadow": {"kind": "neutral", "opacity": g.get("shadow", 0.4)},
                   "translucency": {"enabled": tr > 0, "value": tr}})
    bgd = bg_dark or bg
    doc = {"fill-specializations": [{"value": {"automatic-gradient": srgb(bg)}},
                                    {"appearance": "dark", "value": {"automatic-gradient": srgb(bgd)}}],
           "groups": gs,
           "supported-platforms": {"circles": ["watchOS"], "squares": "shared"}}
    (d / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")


# ---------------- A：日記のページ ＋ ガラスのストップウォッチ
pw = S / PHI ** 1.25               # ページの横 560
ph = pw * PHI ** 0.5               # ページの縦
px, py = S * 0.17, S * 0.15
rot = f'transform="rotate(-9 {f(px + pw / 2)} {f(py + ph / 2)})"'
lines = "".join(rrect(px + pw * 0.14, py + ph * (0.24 + i * 0.11), pw * (0.72 if i < 3 else 0.45), pw / PHI ** 6.2, pw / PHI ** 7)
                for i in range(4))
wr = S / PHI ** 2.6                # 時計の半径 292
wcx, wcy = S * 0.60, S * 0.60
ww = wr / PHI ** 3
write_icon("A-page-watch", INDIGO, [
    {"layers": [("ten", ten(wcx, wcy, (wr - ww) * 2 / PHI), WHITE, True, 1),
                ("arc", arc(wcx, wcy, wr - ww, wr, -90, -30), AMBER, True, 1),
                ("crown", crown(wcx, wcy - wr, ww, wr / PHI ** 2), WHITE, True, 1),
                ("ring", ring(wcx, wcy, wr, wr - ww), WHITE, True, 0.55),
                ("face", disc(wcx, wcy, wr - ww), INDIGO_D, True, 0.92)],
     "translucency": 0.35, "shadow": 0.5},
    {"layers": [("lines", f"<g {rot}>{lines}</g>", INDIGO_L, False, 1),
                ("page", f"<g {rot}>{rrect(px, py, pw, ph, pw / PHI ** 5)}</g>", WHITE, True, 1)],
     "translucency": 0.2, "shadow": 0.4},
], INDIGO_D)

# ---------------- B：万年筆の「1」＋ ストップウォッチの「0」
H = S / PHI ** 1.0                 # 全体の高さ 633
r0 = H / 2 * 0.86                  # 時計の半径
t0 = r0 / PHI ** 2.6
pen_w = t0 * 1.25
gap = t0 * 1.1
total = pen_w + gap + 2 * r0
pxl = S / 2 - total / 2
ccx = pxl + pen_w + gap + r0
ccy = S / 2 + t0 * 0.8
pen_top, pen_bot = ccy - r0 - t0 * 0.2, ccy + r0
nib_h = pen_w * PHI
body = f'<path fill="#000" d="{stadium(pxl, pen_top, pen_w, pen_bot - pen_top - nib_h + pen_w / 2)}"/>'
nib_y = pen_bot - nib_h
nib = (f'<path fill="#000" d="M{f(pxl)},{f(nib_y)} L{f(pxl + pen_w)},{f(nib_y)} '
       f'Q{f(pxl + pen_w)},{f(nib_y + nib_h * 0.45)} {f(pxl + pen_w / 2)},{f(pen_bot)} '
       f'Q{f(pxl)},{f(nib_y + nib_h * 0.45)} {f(pxl)},{f(nib_y)} Z"/>')
slit = rrect(pxl + pen_w / 2 - pen_w * 0.06, nib_y + nib_h * 0.18, pen_w * 0.12, nib_h * 0.55, pen_w * 0.06) + disc(pxl + pen_w / 2, nib_y + nib_h * 0.2, pen_w * 0.11)
clip = rrect(pxl + pen_w * 0.62, pen_top + pen_w * 0.6, pen_w * 0.22, (pen_bot - pen_top) * 0.33, pen_w * 0.11)
band = rrect(pxl, pen_top + (pen_bot - pen_top) * 0.42, pen_w, pen_w * 0.18, 0)
write_icon("B-pen-watch", INDIGO, [
    {"layers": [("slit", slit, INDIGO_D, False, 1),
                ("arc", arc(ccx, ccy, r0 - t0, r0, -90, -30), AMBER, True, 1),
                ("clip", clip + band, AMBER, True, 1),
                ("nib", nib, AMBER, True, 1),
                ("crown", crown(ccx, ccy - r0, t0, r0 / PHI ** 1.6), WHITE, True, 1),
                ("pen", body, WHITE, True, 1),
                ("ring", ring(ccx, ccy, r0, r0 - t0), WHITE, True, 1)],
     "translucency": 0.25, "shadow": 0.5},
    {"layers": [("face", disc(ccx, ccy, r0 - t0 * 0.5), WHITE, True, 0.18)],
     "translucency": 0.5, "shadow": 0.2},
], INDIGO_D)

# ---------------- C：日記帳の表紙 ＋ ガラスの丸窓
bw = S / PHI ** 0.9                # 表紙の横 663
bh = bw * PHI ** 0.5
bx, by = (S - bw) / 2 + bw / PHI ** 7, (S - bh) / 2
spine = bw / PHI ** 4
wcx2, wcy2 = bx + spine + (bw - spine) / 2, by + bh / PHI ** 1.0 - bh * 0.08
wr2 = (bw - spine) / 2 / PHI ** 0.35
rib_w = spine / PHI
ribbon = (f'<path fill="#000" d="M{f(bx + bw * 0.72)},{f(by + bh - 10)} L{f(bx + bw * 0.72 + rib_w)},{f(by + bh - 10)} '
          f'L{f(bx + bw * 0.72 + rib_w)},{f(by + bh + bh / PHI ** 5)} L{f(bx + bw * 0.72 + rib_w / 2)},{f(by + bh + bh / PHI ** 5 - rib_w * 0.7)} '
          f'L{f(bx + bw * 0.72)},{f(by + bh + bh / PHI ** 5)} Z"/>')
ww2 = wr2 / PHI ** 3.5
write_icon("C-cover-window", LAV, [
    {"layers": [("ten", ten(wcx2, wcy2, (wr2 - ww2) * 2 / PHI), INDIGO, False, 1),
                ("arc", arc(wcx2, wcy2, wr2 - ww2, wr2, -90, -30), AMBER, True, 1),
                ("glass", disc(wcx2, wcy2, wr2), WHITE, True, 0.85)],
     "translucency": 0.3, "shadow": 0.45},
    {"layers": [("ribbon", ribbon, AMBER, True, 1),
                ("spine", rrect(bx, by, spine, bh, bw / PHI ** 5), INDIGO_D, False, 1),
                ("cover", rrect(bx, by, bw, bh, bw / PHI ** 5), INDIGO, True, 1),
                ("pages", rrect(bx + bw / PHI ** 6, by + bw / PHI ** 6, bw, bh, bw / PHI ** 5), WHITE, False, 1)],
     "translucency": 0, "shadow": 0.45},
], (0.12, 0.13, 0.22))

# ---------------- D：日記帳の砂時計
cw = S / PHI ** 0.85               # 台（本）の横
chh = cw / PHI ** 3.2              # 台の厚み
gx0, gx1 = (S - cw) / 2, (S + cw) / 2
top_y = S / 2 - S / PHI ** 1.65
bot_y = S / 2 + S / PHI ** 1.65
neck = cw / PHI ** 5
bulb_in = cw / PHI ** 0.4          # ガラスの胴の幅
gl0, gl1 = S / 2 - bulb_in / 2, S / 2 + bulb_in / 2
y_a, y_b = top_y + chh, bot_y - chh
ym = S / 2


def bulb(y_wide, y_neck):
    k = (y_neck - y_wide)
    return (f"M{f(gl0)},{f(y_wide)} L{f(gl1)},{f(y_wide)} "
            f"C{f(gl1)},{f(y_wide + k * 0.55)} {f(S / 2 + neck)},{f(y_neck - k * 0.2)} {f(S / 2 + neck / 2)},{f(y_neck)} "
            f"L{f(S / 2 - neck / 2)},{f(y_neck)} "
            f"C{f(S / 2 - neck)},{f(y_neck - k * 0.2)} {f(gl0)},{f(y_wide + k * 0.55)} {f(gl0)},{f(y_wide)} Z")


glass_d = f'<path fill="#000" d="{bulb(y_a, ym)}"/><path fill="#000" d="{bulb(y_b, ym)}"/>'
sand_pile = f'<path fill="#000" d="M{f(gl0 + 30)},{f(y_b)} L{f(gl1 - 30)},{f(y_b)} Q{f(S / 2)},{f(y_b - (y_b - ym) * 0.95)} {f(gl0 + 30)},{f(y_b)} Z"/>'
sand_top = f'<path fill="#000" d="M{f(S / 2 - bulb_in * 0.22)},{f(ym - (ym - y_a) * 0.38)} L{f(S / 2 + bulb_in * 0.22)},{f(ym - (ym - y_a) * 0.38)} L{f(S / 2)},{f(ym)} Z"/>'
stream = rrect(S / 2 - neck * 0.18, ym, neck * 0.36, (y_b - ym) * 0.55, neck * 0.18)


def book(y):
    return rrect(gx0, y, cw, chh, chh / PHI ** 1.5)


page_lines = "".join(rrect(gx0 + cw * 0.06, y + chh * (0.36 + 0.2 * i), cw * 0.88, chh * 0.06, 2)
                     for y in (top_y, y_b) for i in range(2))
write_icon("D-hourglass", INDIGO, [
    {"layers": [("lines", page_lines, INDIGO_L, False, 1),
                ("books", book(top_y) + book(y_b), WHITE, True, 1)],
     "translucency": 0, "shadow": 0.5},
    {"layers": [("sand", sand_pile + sand_top + stream, AMBER, True, 1),
                ("glass", glass_d, WHITE, True, 0.35)],
     "translucency": 0.45, "shadow": 0.3},
], INDIGO_D)

# ---------------- E：重ねたガラスのページ ＋ 時計の針
ew = S / PHI ** 1.0                # ページの横 633
eh = ew * PHI ** 0.5
ex, ey = (S - ew) / 2 + 22, (S - eh) / 2 + 30
er = ew / 2 / PHI ** 0.5           # 目盛りの半径（ページの幅の内側に収める）
ecx, ecy = ex + ew / 2, ey + ew / 2 + ew / PHI ** 5
hand_t = er / PHI ** 4.5
hand_end = pt(ecx, ecy, er * 0.92, -30)
hand = (glyphs._band((ecx, ecy), hand_end, hand_t) + disc(*hand_end, hand_t / 2)
        + disc(ecx, ecy, hand_t * PHI))
ticks = "".join(glyphs._band(pt(ecx, ecy, er * 0.98, a), pt(ecx, ecy, er * (0.86 if a % 90 else 0.80), a), hand_t * 0.55)
                for a in range(-90, 270, 30))
elines = "".join(rrect(ex + ew * 0.16, ey + eh * (0.80 + i * 0.075), ew * (0.68 if i == 0 else 0.42), ew / PHI ** 7.5, 3) for i in range(2))
write_icon("E-pages-hand", (0.97, 0.97, 1.0), [
    {"layers": [("hand", hand, INDIGO, True, 1),
                ("ticks", ticks + elines, INDIGO_L, False, 1),
                ("sweep", sector(ecx, ecy, er * 0.92, -90, -30), AMBER, True, 0.9),
                ("front", rrect(ex, ey, ew, eh, ew / PHI ** 5), WHITE, True, 1)],
     "translucency": 0.15, "shadow": 0.45},
    {"layers": [("mid", f'<g transform="rotate(-6 {f(S / 2)} {f(S / 2)})">{rrect(ex - 30, ey - 26, ew, eh, ew / PHI ** 5)}</g>', INDIGO_L, True, 0.8),
                ("back", f'<g transform="rotate(-12 {f(S / 2)} {f(S / 2)})">{rrect(ex - 60, ey - 50, ew, eh, ew / PHI ** 5)}</g>', INDIGO, True, 0.9)],
     "translucency": 0.5, "shadow": 0.3},
], (0.12, 0.13, 0.22))
print("ok")
