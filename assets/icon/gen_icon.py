"""Generate app icon: 3 falling mahjong tiles on dark background."""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
FONT_PATH = '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc'
OUT = 'app_icon.png'

BG_TOP    = (10, 15, 25)
BG_BOTTOM = (4,  8, 14)

TILE_FACE  = (248, 244, 236)
TILE_EDGE  = (200, 185, 165)
INNER_BORDER = (195, 175, 145)

TILES = [
    # (cx, cy, w, h, rot_deg, char, char_color, font_size)
    (600, 270, 200, 258, -11, '七', (25,  48, 100), 120),  # back
    (510, 500, 214, 274,  +6, '發', (30, 120,  50),  38),  # middle (big char)
    (420, 730, 226, 290,  -4, '中', (180, 25,  25),  38),  # front
]

FONT_SIZE_MIDDLE = 145
FONT_SIZE_FRONT  = 155


def draw_background(img: Image.Image):
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / SIZE
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))


def draw_speed_lines(img: Image.Image):
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    color = (207, 181, 59, 25)
    xs = [150, 280, 400, 560, 700, 840]
    for x in xs:
        draw.line([(x - 60, 0), (x + 40, SIZE)], fill=color, width=2)
    img.paste(Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB'), (0, 0))


def make_tile(w: int, h: int, char: str, char_color: tuple, font_size: int) -> Image.Image:
    pad = 40
    tile = Image.new('RGBA', (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)

    # Shadow
    shadow_off = 12
    draw.rounded_rectangle(
        [pad + shadow_off, pad + shadow_off, pad + w + shadow_off, pad + h + shadow_off],
        radius=18,
        fill=(0, 0, 0, 160),
    )

    # Tile body
    draw.rounded_rectangle(
        [pad, pad, pad + w, pad + h],
        radius=18,
        fill=TILE_FACE,
        outline=TILE_EDGE,
        width=3,
    )

    # Inner border
    margin = 12
    draw.rounded_rectangle(
        [pad + margin, pad + margin, pad + w - margin, pad + h - margin],
        radius=10,
        fill=None,
        outline=INNER_BORDER,
        width=2,
    )

    # Character (None = blank haku tile)
    if char is not None:
        try:
            font = ImageFont.truetype(FONT_PATH, font_size)
        except Exception:
            font = ImageFont.load_default()

        cx = pad + w // 2
        cy = pad + h // 2
        bbox = draw.textbbox((0, 0), char, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text(
            (cx - tw // 2 - bbox[0], cy - th // 2 - bbox[1]),
            char,
            font=font,
            fill=char_color,
        )

    return tile


def composite_tile(base: Image.Image, tile_img: Image.Image, cx: int, cy: int, angle: float):
    rotated = tile_img.rotate(-angle, expand=True, resample=Image.BICUBIC)
    rx, ry = rotated.size
    paste_x = cx - rx // 2
    paste_y = cy - ry // 2
    base.paste(rotated, (paste_x, paste_y), rotated.split()[3])


def main():
    img = Image.new('RGB', (SIZE, SIZE), BG_TOP)
    draw_background(img)
    draw_speed_lines(img)

    base = img.convert('RGBA')

    tile_configs = [
        (600, 270, 200, 258, -11, None, None, 0),
        (510, 500, 214, 274,  +6, '發', (30, 120,  50), 145),
        (420, 730, 226, 290,  -4, '中', (180, 25,  25), 155),
    ]

    for (cx, cy, w, h, rot, char, color, fsize) in tile_configs:
        tile = make_tile(w, h, char, color, fsize)
        composite_tile(base, tile, cx, cy, rot)

    final = base.convert('RGB')
    final.save(OUT, 'PNG')
    print(f'Saved {OUT}')


if __name__ == '__main__':
    main()
