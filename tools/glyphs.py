"""アイコンの数字の形（make_icon.py と design/candidates から使う）。
Icon Composer は stroke を面として扱うので、太い線は「四角の帯 + 丸」の塗りで描く。"""
import math

PHI = (1 + 5 ** 0.5) / 2
FLAG_ANGLE = math.atan2(1, PHI ** 0.5)  # 「1」の旗の傾き（1 : √φ）


def f(v):
    return f"{v:.2f}"


def _band(p, q, t):
    """p から q への太さ t の帯（端は平ら）"""
    dx, dy = q[0] - p[0], q[1] - p[1]
    n = math.hypot(dx, dy)
    nx, ny = -dy / n * t / 2, dx / n * t / 2
    pts = [(p[0] + nx, p[1] + ny), (q[0] + nx, q[1] + ny), (q[0] - nx, q[1] - ny), (p[0] - nx, p[1] - ny)]
    return '<path fill="#000" d="M' + " L".join(f"{f(x)},{f(y)}" for x, y in pts) + ' Z"/>'


def _dot(c, r):
    return f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" fill="#000"/>'


def one_flag_width(h, t):
    """「1」の旗が軸から左へ出る長さ（線の中心どうし）"""
    return h / PHI ** 2.5 * math.cos(FLAG_ANGLE)


def one(x, top, h, t):
    """「1」を一筆で：旗の先 → 軸の上 → 軸の下。x は軸の左端。角と両端は丸い（丸いペン先）"""
    r = t / 2
    p1 = (x + r, top + r)                         # 軸の上（旗との角）
    p2 = (x + r, top + h - r)                     # 軸の下
    flag = h / PHI ** 2.5                         # 旗の長さ
    p0 = (p1[0] - flag * math.cos(FLAG_ANGLE), p1[1] + flag * math.sin(FLAG_ANGLE))
    return _band(p0, p1, t) + _band(p1, p2, t) + _dot(p0, r) + _dot(p1, r) + _dot(p2, r)


def one_width(h, t):
    """「1」全体の横幅（旗の先の丸から軸の右端まで）"""
    return one_flag_width(h, t) + t
