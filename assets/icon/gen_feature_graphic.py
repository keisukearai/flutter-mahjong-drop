"""Generate Google Play feature graphic: 1024x500px."""
from PIL import Image, ImageDraw, ImageFont
import math

W, H = 1024, 500
FONT_PATH = '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc'
FONT_PATH_LIGHT = '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc'
OUT = 'feature_graphic.png'

BG_TOP    = (10, 15, 25)
BG_BOTTOM = (4,  8, 14)
TILE_FACE  = (248, 244, 236)
TILE_EDGE  = (200, 185, 165)
INNER_BORDER = (195, 175, 145)


def draw_background(img: Image.Image):
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))


def draw_speed_lines(img: Image.Image):
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    color = (207, 181, 59, 20)
    xs = [80, 160, 260, 370, 470, 560]
    for x in xs:
        draw.line([(x - 30, 0), (x + 20, H)], fill=color, width=2)
    img.paste(Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB'), (0, 0))


def make_tile(w: int, h: int, char, char_color, font_size: int) -> Image.Image:
    pad = 30
    tile = Image.new('RGBA', (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)

    draw.rounded_rectangle(
        [pad + 10, pad + 10, pad + w + 10, pad + h + 10],
        radius=14, fill=(0, 0, 0, 140),
    )
    draw.rounded_rectangle(
        [pad, pad, pad + w, pad + h],
        radius=14, fill=TILE_FACE, outline=TILE_EDGE, width=3,
    )
    margin = 10
    draw.rounded_rectangle(
        [pad + margin, pad + margin, pad + w - margin, pad + h - margin],
        radius=8, fill=None, outline=INNER_BORDER, width=2,
    )

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
            char, font=font, fill=char_color,
        )
    return tile


def composite_tile(base: Image.Image, tile_img: Image.Image, cx: int, cy: int, angle: float):
    rotated = tile_img.rotate(-angle, expand=True, resample=Image.BICUBIC)
    rx, ry = rotated.size
    base.paste(rotated, (cx - rx // 2, cy - ry // 2), rotated.split()[3])


def main():
    img = Image.new('RGB', (W, H), BG_TOP)
    draw_background(img)
    draw_speed_lines(img)
    base = img.convert('RGBA')

    # Left side: 3 tiles cascading diagonally
    tile_configs = [
        # (cx, cy, w, h, rot_deg, char, color, font_size)
        (200, 120, 110, 142, -10, None,  None,           0),   # blank (back)
        (260, 255, 118, 152,  +6, '發',  (30, 120, 50), 80),   # middle
        (195, 390, 124, 160,  -4, '中',  (180, 25, 25), 85),   # front
    ]
    for (cx, cy, w, h, rot, char, color, fsize) in tile_configs:
        tile = make_tile(w, h, char, color, fsize)
        composite_tile(base, tile, cx, cy, rot)

    # Right side: title text
    draw2 = ImageDraw.Draw(base)

    title = '麻雀ドロップ'
    subtitle = 'Mahjong Drop'
    tagline = '落ちゲー × 麻雀　シンプル＆爽快'

    title_x = 430
    title_y_start = 130

    try:
        font_title    = ImageFont.truetype(FONT_PATH, 78)
        font_subtitle = ImageFont.truetype(FONT_PATH_LIGHT, 32)
        font_tag      = ImageFont.truetype(FONT_PATH_LIGHT, 26)
    except Exception:
        font_title = font_subtitle = font_tag = ImageFont.load_default()

    # Title shadow
    draw2.text((title_x + 3, title_y_start + 3), title, font=font_title, fill=(0, 0, 0, 180))
    # Title
    draw2.text((title_x, title_y_start), title, font=font_title, fill=(248, 244, 236, 255))

    # Subtitle
    sub_y = title_y_start + 95
    draw2.text((title_x + 2, sub_y + 2), subtitle, font=font_subtitle, fill=(0, 0, 0, 140))
    draw2.text((title_x, sub_y), subtitle, font=font_subtitle, fill=(207, 181, 59, 230))

    # Separator line
    sep_y = sub_y + 50
    draw2.line([(title_x, sep_y), (title_x + 440, sep_y)], fill=(207, 181, 59, 80), width=1)

    # Tagline
    draw2.text((title_x, sep_y + 18), tagline, font=font_tag, fill=(180, 175, 165, 200))

    final = base.convert('RGB')
    final.save(OUT, 'PNG')
    print(f'Saved {OUT}  ({W}x{H}px)')


if __name__ == '__main__':
    main()
