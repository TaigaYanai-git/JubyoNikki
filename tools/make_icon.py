#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
  python3 tools/make_icon.py          # .icon を作る
  python3 tools/make_icon.py --guide  # 黄金比の補助線を描いた SVG も書き出す（docs/icon-guide.svg）

絵柄：日めくりの1枚。白いページの上にインディゴの帯、大きな「10」、右下の角がめくれている。
平らな面だけで描く（ガラスの効果は使わない）。前のタイマーの版は design/candidates/make_icon_timer.py。
寸法はすべて黄金比 φ（1.618…）から決める。
  - ページの一辺       = アイコンの幅 ÷ √φ、角の丸み = 一辺 ÷ φ⁵
  - 上の帯の高さ       = 一辺 ÷ φ³
  - 「10」の高さ       = 帯の下の高さ ÷ φ、線の太さ = 高さ ÷ φ³、「0」の幅 = 高さ ÷ φ
  - めくれた角の大きさ = 一辺 ÷ φ⁴
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import glyphs  # noqa: E402

ICON = ROOT / "JubyoNikki" / "AppIcon.icon"
(ICON / "Assets").mkdir(parents=True, exist_ok=True)

PHI = glyphs.PHI
S = 1024
f = glyphs.f

P = S / PHI ** 0.5                  # ページの一辺 805
R = P / PHI ** 5                    # 角の丸み 73
BAND = P / PHI ** 3                 # 上の帯 190
FOLD = P / PHI ** 4                 # めくれた角 117
X0 = (S - P) / 2
Y0 = (S - P) / 2
X1, Y1 = X0 + P, Y0 + P

H = (P - BAND) / PHI                # 「10」の高さ 380
T = H / PHI ** 3                    # 線の太さ
W0 = H / PHI                        # 「0」の幅
GAP = T / PHI
total_w = glyphs.one_width(H, T) + GAP + W0
x1 = S / 2 - total_w / 2 + glyphs.one_flag_width(H, T)   # 「1」の軸の左端
top = Y0 + BAND + (P - BAND - H) / 2                      # 帯の下の中央


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n{body}\n</svg>\n'


def page_path():
    """角の丸い正方形。右下だけ斜めに切り落とす（めくれた角）"""
    return (f"M{f(X0 + R)},{f(Y0)} L{f(X1 - R)},{f(Y0)} Q{f(X1)},{f(Y0)} {f(X1)},{f(Y0 + R)} "
            f"L{f(X1)},{f(Y1 - FOLD)} L{f(X1 - FOLD)},{f(Y1)} "
            f"L{f(X0 + R)},{f(Y1)} Q{f(X0)},{f(Y1)} {f(X0)},{f(Y1 - R)} "
            f"L{f(X0)},{f(Y0 + R)} Q{f(X0)},{f(Y0)} {f(X0 + R)},{f(Y0)} Z")


band = (f"M{f(X0)},{f(Y0 + BAND)} L{f(X0)},{f(Y0 + R)} Q{f(X0)},{f(Y0)} {f(X0 + R)},{f(Y0)} "
        f"L{f(X1 - R)},{f(Y0)} Q{f(X1)},{f(Y0)} {f(X1)},{f(Y0 + R)} L{f(X1)},{f(Y0 + BAND)} Z")
# めくれた角：切り落とした線を折り目にして、内側へ折り返した三角
fold = f"M{f(X1)},{f(Y1 - FOLD)} L{f(X1 - FOLD)},{f(Y1 - FOLD)} L{f(X1 - FOLD)},{f(Y1)} Z"
x0 = x1 + T + GAP


def stadium(x, y, w, h):
    r = w / 2
    return (f"M{f(x)},{f(y + r)} A{f(r)},{f(r)} 0 0 1 {f(x + w)},{f(y + r)} "
            f"L{f(x + w)},{f(y + h - r)} A{f(r)},{f(r)} 0 0 1 {f(x)},{f(y + h - r)} Z")


digits = glyphs.one(x1, top, H, T) + (
    f'<path fill="#000" fill-rule="evenodd" d="{stadium(x0, top, W0, H)} {stadium(x0 + T, top + T, W0 - 2 * T, H - 2 * T)}"/>')

layers = {
    "digits": svg(digits),
    "fold": svg(f'<path fill="#000" d="{fold}"/>'),
    "band": svg(f'<path fill="#000" d="{band}"/>'),
    "page": svg(f'<path fill="#000" d="{page_path()}"/>'),
}
for old in (ICON / "Assets").glob("*.svg"):
    old.unlink()
for name, body in layers.items():
    (ICON / "Assets" / f"{name}.svg").write_text(body)


def srgb(c):
    return "srgb:" + ",".join(f"{v:.5f}" for v in c) + ",1.00000"


INDIGO = (0.19, 0.23, 0.55)     # #303B8C（アプリのテーマカラーの初期値と同じ）
FOLD_C = (0.80, 0.83, 0.95)     # めくれた裏側（淡いインディゴ）
WHITE = (1, 1, 1)
BG = (0.93, 0.94, 0.98)         # ページの外（ごく淡い青みの灰色）
BG_DARK = (0.12, 0.13, 0.22)


def layer(name, c, dark=None):
    return {"glass": False, "image-name": f"{name}.svg", "name": name,
            "position": {"scale": 1, "translation-in-points": [0, 0]},
            "fill-specializations": [{"value": {"solid": srgb(c)}},
                                     {"appearance": "dark", "value": {"solid": srgb(dark or c)}}]}


doc = {
    "fill-specializations": [{"value": {"automatic-gradient": srgb(BG)}},
                             {"appearance": "dark", "value": {"automatic-gradient": srgb(BG_DARK)}}],
    "groups": [
        {"layers": [layer("digits", INDIGO), layer("fold", FOLD_C), layer("band", INDIGO), layer("page", WHITE)],
         "shadow": {"kind": "neutral", "opacity": 0.25},
         "translucency": {"enabled": False, "value": 0}},
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(ICON / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")

if "--guide" in sys.argv:
    g = '<g fill="none" stroke="#e0567a" stroke-width="2" stroke-dasharray="8 6">'
    g += f'<rect x="{f(X0)}" y="{f(Y0)}" width="{f(P)}" height="{f(P)}"/>'
    g += f'<line x1="{f(X0)}" y1="{f(Y0 + BAND)}" x2="{f(X1)}" y2="{f(Y0 + BAND)}"/>'
    g += f'<rect x="{f(x0)}" y="{f(top)}" width="{f(W0)}" height="{f(H)}"/>'
    g += '</g>'
    body = "".join(layers[k].split("\n")[1] for k in ("page", "band", "fold", "digits"))
    (ROOT / "docs" / "icon-guide.svg").write_text(svg(f'<rect width="{S}" height="{S}" fill="#fff"/><g opacity="0.25">{body}</g>{g}'))

print(f"φ={PHI:.4f} ページ={P:.0f} 帯={BAND:.0f} 角={FOLD:.0f} 数字の高さ={H:.0f} 線={T:.0f}")
