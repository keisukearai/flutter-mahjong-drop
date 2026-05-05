"""
麻雀牌の画像を生成するスクリプト。
tile_painter.dart のロジックを Python/Pillow で再現。
"""
import math
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

OUT_DIR = Path(__file__).parent / "tile_images"
OUT_DIR.mkdir(exist_ok=True)

W, H = 192, 268  # 高解像度で描画し最後に 1/2 縮小

CREAM        = (255, 249, 230)
CREAM_SHADOW = (160, 144, 96)
DARK_GREEN   = (27, 94, 32)
MID_GREEN    = (46, 125, 50)
LIGHT_GREEN  = (102, 187, 106)
RED          = (204, 0, 0)
DARK_RED     = (139, 0, 0)
BLACK        = (17, 17, 17)
NAVY         = (40, 53, 147)
BAND         = (10, 46, 10)

# ─── フォント ─────────────────────────────────────────────────────────
FONT_PATH = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"

def _font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size)

# ─── 牌ベース ─────────────────────────────────────────────────────────
def make_tile_base(img: Image.Image) -> ImageDraw.ImageDraw:
    draw = ImageDraw.Draw(img)
    r = int(W * 0.20)
    # shadow
    draw.rounded_rectangle([1, 3, W - 1, H + 2], radius=r,
                            fill=(120, 90, 20, 80))
    # cream body
    draw.rounded_rectangle([0, 0, W - 1, H - 1], radius=r, fill=CREAM)
    # border
    draw.rounded_rectangle([0, 0, W - 1, H - 1], radius=r,
                            outline=CREAM_SHADOW, width=1)
    return draw

# ─── 萬子 ─────────────────────────────────────────────────────────────
KANJI_NUM = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九']

def draw_man(draw: ImageDraw.ImageDraw, n: int):
    nfs = int(H * 0.42)
    mfs = int(H * 0.32)
    gap = int(H * 0.01)
    total = nfs + gap + mfs
    top = (H - total) // 2

    fn = _font(nfs)
    fm = _font(mfs)

    # 数字
    bbox = draw.textbbox((0, 0), KANJI_NUM[n], font=fn)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2, top), KANJI_NUM[n], fill=BLACK, font=fn)
    # 萬
    bbox2 = draw.textbbox((0, 0), "萬", font=fm)
    tw2 = bbox2[2] - bbox2[0]
    draw.text(((W - tw2) // 2, top + nfs + gap), "萬", fill=RED, font=fm)

# ─── 筒子 ─────────────────────────────────────────────────────────────
PIN_PIPS = {
    1: [(0.50, 0.50)],
    2: [(0.50, 0.28), (0.50, 0.72)],
    3: [(0.27, 0.22), (0.50, 0.50), (0.73, 0.78)],
    4: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.78), (0.73, 0.78)],
    5: [(0.27, 0.22), (0.73, 0.22), (0.50, 0.50), (0.27, 0.78), (0.73, 0.78)],
    6: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.50), (0.73, 0.50), (0.27, 0.78), (0.73, 0.78)],
    7: [(0.27, 0.22), (0.50, 0.29), (0.73, 0.36), (0.27, 0.59), (0.73, 0.59), (0.27, 0.78), (0.73, 0.78)],
    8: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.41), (0.73, 0.41), (0.27, 0.59), (0.73, 0.59), (0.27, 0.78), (0.73, 0.78)],
    9: [(0.22, 0.22), (0.50, 0.22), (0.78, 0.22), (0.22, 0.50), (0.50, 0.50), (0.78, 0.50), (0.22, 0.78), (0.50, 0.78), (0.78, 0.78)],
}
PIN_RED      = {1: {0}}
PIN_INVERTED = {3: {1}, 5: {2}, 6: {2,3,4,5}, 7: {3,4,5,6}, 9: {3,4,5}}

def _pin_circle(draw, cx, cy, r, red_center, inverted):
    outer  = (187, 0, 0) if inverted else NAVY
    inner  = NAVY if inverted else (RED if red_center else NAVY)
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=outer)
    ir = r * 0.76
    draw.ellipse([cx-ir, cy-ir, cx+ir, cy+ir], fill=CREAM)
    pr = r * 0.175
    pd = r * 0.50
    for i in range(8):
        a = i * math.pi / 4
        px = cx + pd * math.cos(a)
        py = cy + pd * math.sin(a)
        draw.ellipse([px-pr, py-pr, px+pr, py+pr], fill=outer)
    cr2 = r * 0.19
    draw.ellipse([cx-cr2, cy-cr2, cx+cr2, cy+cr2], fill=inner)

def draw_pin(draw: ImageDraw.ImageDraw, n: int):
    pips = PIN_PIPS[n]
    r = min(W, H) / (2.1 if n==1 else 3.8 if n==2 else 5.0 if n<=4 else 5.6 if n<=6 else 6.8)
    red_s = PIN_RED.get(n, set())
    inv_s = PIN_INVERTED.get(n, set())
    for i, (px, py) in enumerate(pips):
        _pin_circle(draw, W*px, H*py, r, i in red_s, i in inv_s)

# ─── 索子 2〜9 ────────────────────────────────────────────────────────
SOU_PIPS = {
    2: [(0.50, 0.27), (0.50, 0.73)],
    3: [(0.50, 0.25), (0.32, 0.72), (0.68, 0.72)],
    4: [(0.30, 0.27), (0.70, 0.27), (0.30, 0.73), (0.70, 0.73)],
    5: [(0.30, 0.22), (0.70, 0.22), (0.50, 0.50), (0.30, 0.78), (0.70, 0.78)],
    6: [(0.30, 0.19), (0.70, 0.19), (0.30, 0.50), (0.70, 0.50), (0.30, 0.81), (0.70, 0.81)],
    7: [(0.50, 0.16), (0.30, 0.37), (0.70, 0.37), (0.30, 0.59), (0.70, 0.59), (0.30, 0.81), (0.70, 0.81)],
    8: [(0.15, 0.20), (0.38, 0.35), (0.62, 0.35), (0.85, 0.20),
        (0.15, 0.80), (0.38, 0.65), (0.62, 0.65), (0.85, 0.80)],
    9: [(0.22, 0.22), (0.50, 0.22), (0.78, 0.22), (0.22, 0.50), (0.50, 0.50), (0.78, 0.50), (0.22, 0.78), (0.50, 0.78), (0.78, 0.78)],
}
SOU_RED = {5: {2}, 7: {0}, 9: {1, 4, 7}}

def _sou_segment(draw, cx, cy, sw, sh, is_red=False):
    outer = DARK_RED if is_red else DARK_GREEN
    inner = (239, 83, 80) if is_red else LIGHT_GREEN
    oy = sh * 0.26
    for dy in [-oy, oy]:
        x0 = cx - sw/2; y0 = cy + dy - sh*0.29
        x1 = cx + sw/2; y1 = cy + dy + sh*0.29
        draw.ellipse([x0, y0, x1, y1], fill=outer)
        draw.ellipse([x0+2, y0+2, x0+(x1-x0)*0.52, y1-2], fill=inner)
    # fill gap
    ty1 = cy - oy + sh*0.29
    by0 = cy + oy - sh*0.29
    if by0 < ty1:
        draw.rectangle([cx-sw*0.28, by0, cx+sw*0.28, ty1], fill=outer)
    draw.line([cx-sw*0.46, cy, cx+sw*0.46, cy], fill=BAND, width=2)

def draw_sou_n(draw: ImageDraw.ImageDraw, n: int):
    pips = SOU_PIPS[n]
    nh = H / (3.0 if n<=4 else 4.2 if n<=6 else 4.8)
    nw = min(W * 0.30, nh * 0.68)
    red_s = SOU_RED.get(n, set())
    for i, (px, py) in enumerate(pips):
        _sou_segment(draw, W*px, H*py, nw, nh, is_red=(i in red_s))

# ─── 索子 1（孔雀デザイン） ────────────────────────────────────────────
def draw_sou1(draw: ImageDraw.ImageDraw):
    """
    参考画像に忠実な一索:
    ・丸はリング（白抜き、太アウトライン）
    ・放射線は丸クラスター全体の背後から扇状
    ・左翼=大きな曲線アーク、右翼=横線ブロック
    ・体・頭=白地に緑ドット
    ・赤トサカ＋赤脚
    """
    cx = W // 2

    # ═══ 丸リングクラスター（2-3-4-4 の4行） ═══
    ring_r   = int(W * 0.075)      # リング外径
    ring_in  = int(ring_r * 0.54)  # リング内径（白抜き）
    step     = ring_r * 2 + 4
    rows     = [2, 3, 4, 4]       # 4行にして鳥スペースを増やす

    cluster_top = int(H * 0.09)   # クラスター上端（上余白）
    cluster_cx  = cx              # 中央

    dot_positions = []
    for ri, count in enumerate(rows):
        row_y  = cluster_top + ring_r + ri * step
        row_x0 = cluster_cx - (count - 1) * step / 2
        for ci in range(count):
            dot_positions.append((row_x0 + ci * step, row_y))

    cluster_bottom = cluster_top + len(rows) * step + ring_r

    # ═══ 放射状の葉（クラスターの背後） ═══
    fan_ox  = cluster_cx
    fan_oy  = cluster_top + int((cluster_bottom - cluster_top) * 0.65)
    n_lines = 34
    line_len = int(H * 0.42)
    a_start = math.radians(-176)
    a_end   = math.radians(-4)

    for i in range(n_lines):
        t = i / (n_lines - 1)
        a = a_start + (a_end - a_start) * t
        ex = int(fan_ox + line_len * math.cos(a))
        ey = int(fan_oy + line_len * math.sin(a))
        draw.line([fan_ox, fan_oy, ex, ey], fill=DARK_GREEN, width=2)

    # ═══ 丸リングを前景に描画 ═══
    for (dx, dy) in dot_positions:
        draw.ellipse([dx-ring_r, dy-ring_r, dx+ring_r, dy+ring_r], fill=DARK_GREEN)
        draw.ellipse([dx-ring_in, dy-ring_in, dx+ring_in, dy+ring_in], fill=CREAM)

    # ═══ 鳥エリア ═══
    bird_top = cluster_bottom + int(H * 0.03)
    bird_h   = H - bird_top - int(H * 0.08)   # 下余白を追加

    # 主要サイズを固定
    body_r  = int(W * 0.140)   # 体の半径
    head_r  = int(W * 0.090)   # 頭の半径
    body_cx = cx               # 体は中央
    body_cy = bird_top + int(bird_h * 0.46)
    head_cx = body_cx - int(W * 0.07)
    head_cy = body_cy - body_r + int(head_r * 0.30)

    # 翼の共通パラメータ
    wing_y0 = bird_top + int(bird_h * 0.04)
    wing_y1 = bird_top + int(bird_h * 0.86)
    lw_x1   = body_cx - body_r + int(W * 0.02)   # 左翼の右端（体の左）
    lw_x0   = int(W * 0.09)                       # 左翼の最左端（左余白）
    rw_x0   = body_cx + body_r - int(W * 0.02)   # 右翼の左端
    rw_x1   = int(W * 0.91)                       # 右翼の最右端（右余白）
    n_wing  = 12

    def _wing_lines(x_inner, x_outer, y0, y1, is_left):
        """D形翼: x_inner=体側の直線端, x_outer=翼の最遠端"""
        cy = (y0 + y1) / 2
        ry = (y1 - y0) / 2
        rx = abs(x_outer - x_inner)
        # 外弧（楕円の半周）
        if is_left:
            # 左翼: 楕円中心=(x_inner, cy), 左半分
            bb = [x_inner - rx * 2, cy - ry, x_inner, cy + ry]
            draw.arc(bb, start=90, end=270, fill=DARK_GREEN, width=5)
        else:
            # 右翼: 楕円中心=(x_inner, cy), 右半分
            bb = [x_inner, cy - ry, x_inner + rx * 2, cy + ry]
            draw.arc(bb, start=270, end=90, fill=DARK_GREEN, width=5)
        # 上下の直線縁
        draw.line([x_inner, int(y0), x_inner, int(y1)], fill=DARK_GREEN, width=4)
        # 内部コード線
        for i in range(n_wing):
            t  = i / (n_wing - 1)
            wy = int(y0 + (y1 - y0) * t)
            dy = wy - cy
            if abs(dy) <= ry:
                chord_dist = rx * math.sqrt(max(0.0, 1.0 - (dy / ry) ** 2))
                wx = x_inner - chord_dist if is_left else x_inner + chord_dist
                draw.line([int(wx), wy, x_inner, wy], fill=DARK_GREEN, width=3)

    _wing_lines(lw_x1, lw_x0, wing_y0, wing_y1, is_left=True)
    _wing_lines(rw_x0, rw_x1, wing_y0, wing_y1, is_left=False)

    # ── 体（白地・緑ドット） ─────────────────────────────────────────
    draw.ellipse([body_cx-body_r, body_cy-body_r,
                  body_cx+body_r, body_cy+body_r],
                 fill=CREAM, outline=DARK_GREEN, width=5)
    for dot_a in range(0, 360, 40):
        a   = math.radians(dot_a)
        ddx = body_cx + int(body_r * 0.58 * math.cos(a))
        ddy = body_cy + int(body_r * 0.58 * math.sin(a))
        dr  = max(3, int(body_r * 0.13))
        draw.ellipse([ddx-dr, ddy-dr, ddx+dr, ddy+dr], fill=DARK_GREEN)

    # ── 頭（白地・緑ドット、体の左上） ───────────────────────────────
    draw.ellipse([head_cx-head_r, head_cy-head_r,
                  head_cx+head_r, head_cy+head_r],
                 fill=CREAM, outline=DARK_GREEN, width=4)
    for dot_a in range(0, 360, 60):
        a   = math.radians(dot_a)
        ddx = head_cx + int(head_r * 0.50 * math.cos(a))
        ddy = head_cy + int(head_r * 0.50 * math.sin(a))
        dr2 = max(2, int(head_r * 0.18))
        draw.ellipse([ddx-dr2, ddy-dr2, ddx+dr2, ddy+dr2], fill=DARK_GREEN)

    # くちばし（左向き）
    beak_pts = [
        (head_cx - head_r,                  head_cy - int(H*0.005)),
        (head_cx - head_r - int(W*0.085),   head_cy - int(H*0.018)),
        (head_cx - head_r - int(W*0.055),   head_cy + int(H*0.012)),
    ]
    draw.polygon(beak_pts, fill=DARK_GREEN)

    # ── 赤いトサカ（頸の左から左上へ 5 本） ─────────────────────────
    neck_x = head_cx - int(head_r * 0.45)
    neck_y = head_cy + int(head_r * 0.55)
    for i in range(5):
        bx = neck_x - i * 5
        by = neck_y + i * 6
        tx = bx - int(W * 0.14) - i * 4
        ty = by - int(H * 0.10) - i * 3
        draw.line([bx, by, tx, ty], fill=RED, width=4)

    # ── 脚（赤・Y 字、体の真下） ─────────────────────────────────────
    leg_y0 = body_cy + body_r + int(H * 0.010)
    for lx in [body_cx - int(W * 0.11), body_cx + int(W * 0.04)]:
        leg_y1 = min(H - int(H * 0.07), leg_y0 + int(H * 0.08))  # 下余白
        draw.line([lx, leg_y0, lx, leg_y1], fill=RED, width=5)
        for da in [-60, -5, 50]:
            a  = math.radians(da)
            ex = int(lx + int(W * 0.10) * math.cos(a))
            ey = int(leg_y1 + int(H * 0.040) * math.sin(a))
            draw.line([lx, leg_y1, ex, ey], fill=RED, width=4)

# ─── 字牌 ─────────────────────────────────────────────────────────────
HONOR_COLOR = {
    "東": BLACK, "南": BLACK, "西": BLACK, "北": BLACK,
    "白": None,
    "發": (26, 110, 26),
    "中": RED,
}

def draw_honor(draw: ImageDraw.ImageDraw, label: str):
    if label == "白":
        return
    color = HONOR_COLOR.get(label, BLACK)
    fs = int(H * 0.56)
    font = _font(fs)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]; th = bbox[3] - bbox[1]
    draw.text(((W - tw) // 2, (H - th) // 2 - 2), label, fill=color, font=font)

# ─── 全牌シート ───────────────────────────────────────────────────────
# シート上に貼り付けるときの縮小サイズ
TW, TH = W // 2, H // 2   # 96×134

def gen_all_tiles_sheet():
    HONORS = ["東", "南", "西", "北", "白", "發", "中"]

    pad     = 10
    label_h = 16
    cell_w  = TW + pad
    cell_h  = TH + label_h + pad
    cols    = 9
    rows_n  = 4

    sheet_w = cols * cell_w + pad
    sheet_h = rows_n * cell_h + pad
    sheet   = Image.new("RGB", (sheet_w, sheet_h), (30, 58, 42))
    sdraw   = ImageDraw.Draw(sheet)
    lf      = _font(13)

    def paste(tile_img, col, row, label, highlight=False):
        # 高解像度→縮小
        small = tile_img.resize((TW, TH), Image.LANCZOS)
        x = pad + col * cell_w
        y = pad + row * cell_h
        sheet.paste(small, (x, y), small)
        color = (255, 255, 0) if highlight else (220, 220, 220)
        if highlight:
            sdraw.rectangle([x-2, y-2, x+TW+2, y+TH+2], outline=(255, 255, 0), width=2)
        bbox = sdraw.textbbox((0, 0), label, font=lf)
        tw = bbox[2] - bbox[0]
        sdraw.text((x + (TW - tw) // 2, y + TH + 3), label, fill=color, font=lf)

    def make(draw_fn):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = make_tile_base(img)
        draw_fn(d)
        return img

    # 萬子
    for i in range(1, 10):
        paste(make(lambda d, n=i: draw_man(d, n)), i-1, 0, f"{i}萬")

    # 筒子
    for i in range(1, 10):
        paste(make(lambda d, n=i: draw_pin(d, n)), i-1, 1, f"{i}筒")

    # 索子
    for i in range(1, 10):
        is_sou1 = (i == 1)
        img = make(lambda d: draw_sou1(d)) if is_sou1 else \
              make(lambda d, n=i: draw_sou_n(d, n))
        paste(img, i-1, 2, f"{i}索", highlight=is_sou1)

    # 字牌
    for col, label in enumerate(HONORS):
        paste(make(lambda d, lb=label: draw_honor(d, lb)), col, 3, label)

    path = OUT_DIR / "all_tiles.png"
    sheet.save(path)
    print(f"  saved: {path}")

# ─── 1索単体（プレビュー用 3倍） ─────────────────────────────────────
def gen_sou1_large():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = make_tile_base(img)
    draw_sou1(d)
    # 高解像度画像をそのまま保存（既に 192×268）
    path = OUT_DIR / "sou1_large.png"
    img.save(path)
    print(f"  saved: {path}")

if __name__ == "__main__":
    print("=== 全牌シート ===")
    gen_all_tiles_sheet()
    print("=== 1索 大 ===")
    gen_sou1_large()
    print(f"\n出力先: {OUT_DIR}")
