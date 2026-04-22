import 'dart:math' as math;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';
import '../../mahjong/tile.dart';
import '../../mahjong/meld.dart';
import '../board_state.dart';

class TilePainter {
  static const double radius = 11.0;
  static const Color _cream = Color(0xFFFFF9E6);
  static const Color _creamShadow = Color(0xFFA09060);

  // ── individual tile ──────────────────────────────────────────────
  static void drawTile(
    Canvas canvas,
    Tile tile,
    Rect rect, {
    double opacity = 1.0,
    bool isFalling = false,
  }) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    if (isFalling) {
      canvas.drawRRect(
        rr.shift(const Offset(0, 8)),
        Paint()
          ..color = Color.fromARGB((100 * opacity).round(), 0, 0, 0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    } else {
      // 3-D relief: darker bottom edge
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 2.5)).inflate(0.5),
          const Radius.circular(radius),
        ),
        Paint()..color = Color.fromARGB((90 * opacity).round(), 120, 90, 20),
      );
    }

    // Cream background
    canvas.drawRRect(rr, Paint()..color = _cream.withValues(alpha: opacity));

    // Highlight gradient top-left
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55 * opacity),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(rect),
    );

    // Border
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _creamShadow.withValues(alpha: 0.55 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    _drawContent(canvas, tile, rect, opacity);
  }

  static void _drawContent(Canvas canvas, Tile tile, Rect rect, double opacity) {
    if (tile.isHonor) {
      _drawHonor(canvas, tile, rect, opacity);
    } else if (tile.suit == TileSuit.man) {
      _drawMan(canvas, tile, rect, opacity);
    } else if (tile.suit == TileSuit.pin) {
      _drawPin(canvas, tile, rect, opacity);
    } else {
      _drawSou(canvas, tile, rect, opacity);
    }
  }

  // ── Man (萬子): 漢数字 + 萬 ────────────────────────────────────────
  static const _kanjiNum = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  static void _drawMan(Canvas canvas, Tile tile, Rect rect, double opacity) {
    final black = const Color(0xFF111111).withValues(alpha: opacity);
    final red   = const Color(0xFFBB0000).withValues(alpha: opacity);
    final numFs = rect.height * 0.38;
    final manFs = rect.height * 0.30;
    final gap   = rect.height * 0.04;
    final totalH = numFs + gap + manFs;
    final blockTop = rect.top + (rect.height - totalH) / 2;

    _drawCenteredText(
      canvas, _kanjiNum[tile.number], black,
      Rect.fromLTWH(rect.left, blockTop, rect.width, numFs),
      numFs, fontWeight: FontWeight.w900,
    );
    _drawCenteredText(
      canvas, '萬', red,
      Rect.fromLTWH(rect.left, blockTop + numFs + gap, rect.width, manFs),
      manFs, fontWeight: FontWeight.w700,
    );
  }

  // ── Pin (筒子): circle pip patterns ──────────────────────────────
  static const _pinPips = <int, List<(double, double)>>{
    1: [(0.50, 0.50)],
    2: [(0.50, 0.27), (0.50, 0.73)],
    3: [(0.50, 0.20), (0.50, 0.50), (0.50, 0.80)],
    4: [(0.30, 0.28), (0.70, 0.28), (0.30, 0.72), (0.70, 0.72)],
    5: [(0.30, 0.22), (0.70, 0.22), (0.50, 0.50), (0.30, 0.78), (0.70, 0.78)],
    6: [(0.30, 0.20), (0.70, 0.20), (0.30, 0.50), (0.70, 0.50), (0.30, 0.80), (0.70, 0.80)],
    7: [(0.50, 0.13), (0.30, 0.33), (0.70, 0.33), (0.30, 0.54), (0.70, 0.54), (0.30, 0.75), (0.70, 0.75)],
    8: [(0.30, 0.13), (0.70, 0.13), (0.30, 0.38), (0.70, 0.38), (0.30, 0.62), (0.70, 0.62), (0.30, 0.87), (0.70, 0.87)],
    9: [(0.25, 0.17), (0.50, 0.17), (0.75, 0.17), (0.25, 0.50), (0.50, 0.50), (0.75, 0.50), (0.25, 0.83), (0.50, 0.83), (0.75, 0.83)],
  };

  static void _drawPin(Canvas canvas, Tile tile, Rect rect, double opacity) {
    final pips = _pinPips[tile.number] ?? [];
    final content = rect.deflate(3.0);
    final n = tile.number;
    final circR = math.min(content.width, content.height) /
        (n <= 2 ? 3.2 : n <= 4 ? 4.4 : n <= 6 ? 5.6 : 6.8);

    final border = const Color(0xFF0D47A1).withValues(alpha: opacity);
    final fill   = const Color(0xFFBBDEFB).withValues(alpha: opacity);
    final center = const Color(0xFF1565C0).withValues(alpha: opacity);
    final shine  = Colors.white.withValues(alpha: 0.78 * opacity);

    for (final pip in pips) {
      final cx = content.left + content.width * pip.$1;
      final cy = content.top + content.height * pip.$2;
      final c = Offset(cx, cy);

      canvas.drawCircle(c, circR, Paint()..color = border);
      canvas.drawCircle(c, circR - 1.6, Paint()..color = fill);
      canvas.drawCircle(c, math.max(1.2, circR * 0.30), Paint()..color = center);
      // Shiny highlight spot (top-left)
      canvas.drawCircle(
        Offset(c.dx - circR * 0.27, c.dy - circR * 0.30),
        circR * 0.22,
        Paint()..color = shine,
      );
    }
  }

  // ── Sou (索子): bamboo segments ───────────────────────────────────
  static const _souPips = <int, List<(double, double)>>{
    // 1-sou uses special bird rendering below
    2: [(0.50, 0.28), (0.50, 0.72)],
    3: [(0.50, 0.20), (0.50, 0.50), (0.50, 0.80)],
    4: [(0.30, 0.28), (0.70, 0.28), (0.30, 0.72), (0.70, 0.72)],
    5: [(0.30, 0.22), (0.70, 0.22), (0.50, 0.50), (0.30, 0.78), (0.70, 0.78)],
    6: [(0.30, 0.20), (0.70, 0.20), (0.30, 0.50), (0.70, 0.50), (0.30, 0.80), (0.70, 0.80)],
    7: [(0.50, 0.12), (0.30, 0.33), (0.70, 0.33), (0.30, 0.55), (0.70, 0.55), (0.30, 0.76), (0.70, 0.76)],
    8: [(0.30, 0.13), (0.70, 0.13), (0.30, 0.38), (0.70, 0.38), (0.30, 0.62), (0.70, 0.62), (0.30, 0.87), (0.70, 0.87)],
    9: [(0.25, 0.17), (0.50, 0.17), (0.75, 0.17), (0.25, 0.50), (0.50, 0.50), (0.75, 0.50), (0.25, 0.83), (0.50, 0.83), (0.75, 0.83)],
  };

  static void _drawSou(Canvas canvas, Tile tile, Rect rect, double opacity) {
    if (tile.number == 1) {
      _drawSou1(canvas, rect, opacity);
      return;
    }
    final pips = _souPips[tile.number] ?? [];
    final content = rect.deflate(3.0);
    final n = tile.number;
    final stickH = content.height /
        (n <= 3 ? 3.2 : n <= 6 ? 4.3 : 5.5);
    final stickW = math.min(content.width * 0.34, stickH * 0.62);

    final green      = const Color(0xFF2E7D32).withValues(alpha: opacity);
    final lightGreen = const Color(0xFF81C784).withValues(alpha: opacity);
    final gold       = const Color(0xFFFDD835).withValues(alpha: 0.9 * opacity);

    for (final pip in pips) {
      final cx = content.left + content.width * pip.$1;
      final cy = content.top + content.height * pip.$2;

      final seg = Rect.fromCenter(center: Offset(cx, cy), width: stickW, height: stickH);
      final rr = RRect.fromRectAndRadius(seg, Radius.circular(stickW * 0.48));
      canvas.drawRRect(rr, Paint()..color = green);

      // Lighter highlight strip (left side)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(seg.left + 1, seg.top + 2, seg.left + stickW * 0.42, seg.bottom - 2),
          Radius.circular(stickW * 0.44),
        ),
        Paint()..color = lightGreen,
      );

      // Gold node band
      canvas.drawLine(
        Offset(seg.left + 1.5, cy),
        Offset(seg.right - 1.5, cy),
        Paint()..color = gold..strokeWidth = 1.6,
      );
    }
  }

  static void _drawSou1(Canvas canvas, Rect rect, double opacity) {
    // 1-sou: a single large bamboo bead with bird-like shape
    final green = const Color(0xFF1A6E1A).withValues(alpha: opacity);
    final lightGreen = const Color(0xFF3EA83E).withValues(alpha: opacity);
    final red = const Color(0xFFCC0000).withValues(alpha: opacity);
    final c = rect.center;

    // Outer oval (body)
    final outer = Rect.fromCenter(
      center: Offset(c.dx, c.dy - rect.height * 0.03),
      width: rect.width * 0.52,
      height: rect.height * 0.56,
    );
    canvas.drawOval(outer, Paint()..color = green);

    // Inner lighter oval
    canvas.drawOval(
      outer.deflate(4),
      Paint()..color = lightGreen,
    );

    // Center circle (red)
    canvas.drawCircle(
      Offset(c.dx, c.dy - rect.height * 0.03),
      outer.width * 0.18,
      Paint()..color = red,
    );

    // Wings hint (two small arcs on sides)
    final wingPaint = Paint()..color = green..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx - outer.width * 0.4, c.dy - rect.height * 0.03), width: outer.width * 0.4, height: outer.height * 0.5),
      -math.pi / 3, math.pi * 0.8, false, wingPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx + outer.width * 0.4, c.dy - rect.height * 0.03), width: outer.width * 0.4, height: outer.height * 0.5),
      -math.pi * 2 / 3, -math.pi * 0.8, false, wingPaint,
    );
  }

  // ── Honor (字牌) ────────────────────────────────────────────────────
  static void _drawHonor(Canvas canvas, Tile tile, Rect rect, double opacity) {
    if (tile.honor == HonorType.haku) {
      // 白: green rectangular border (no character)
      final green = const Color(0xFF1A6E1A).withValues(alpha: opacity);
      canvas.drawRect(rect.deflate(4.5), Paint()..color = green..style = PaintingStyle.stroke..strokeWidth = 2.2);
      canvas.drawRect(rect.deflate(7.0), Paint()..color = green..style = PaintingStyle.stroke..strokeWidth = 0.8);
    } else {
      final (text, color) = switch (tile.honor!) {
        HonorType.hatsu => ('發', const Color(0xFF1A6E1A)),
        HonorType.chun  => ('中', const Color(0xFFBB0000)),
        HonorType.east  => ('東', const Color(0xFF111111)),
        HonorType.south => ('南', const Color(0xFF111111)),
        HonorType.west  => ('西', const Color(0xFF111111)),
        HonorType.north => ('北', const Color(0xFF111111)),
        _               => ('',   const Color(0xFF111111)),
      };
      _drawCenteredText(
        canvas, text, color.withValues(alpha: opacity),
        rect, rect.height * 0.52,
        fontWeight: FontWeight.w900,
      );
    }
  }

  // ── meld block ───────────────────────────────────────────────────
  static void drawMeldBlock(
    Canvas canvas,
    MeldGroup group,
    List<Rect> cellRects,
    {bool isWinHighlight = false}
  ) {
    if (cellRects.length != 3) return;
    final outer = _boundingRect(cellRects);
    const gap = 2.0;

    if (isWinHighlight) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer.inflate(4), const Radius.circular(16)),
        Paint()
          ..color = const Color(0x88FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Suit-tinted background band
    final firstTile = group.meld.tiles.first;
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.inflate(1.5), const Radius.circular(14)),
      Paint()..color = firstTile.bgColor.withValues(alpha: 0.85),
    );

    // Gold border
    final borderColor = isWinHighlight ? const Color(0xFFFFD700) : const Color(0xFFCFB53B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.inflate(1.5), const Radius.circular(14)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWinHighlight ? 2.5 : 1.8,
    );

    for (int i = 0; i < 3; i++) {
      drawTile(canvas, group.meld.tiles[i], cellRects[i].deflate(gap));
    }

    _drawMeldBadge(canvas, outer, group.meld.type);
  }

  static void _drawMeldBadge(Canvas canvas, Rect outer, MeldType type) {
    final dotColor = type == MeldType.triplet
        ? const Color(0xFFE53935)
        : const Color(0xFF1E88E5);
    canvas.drawCircle(Offset(outer.right - 5, outer.top + 5), 4, Paint()..color = dotColor);
    canvas.drawCircle(Offset(outer.right - 5, outer.top + 5), 4,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }

  // ── helpers ──────────────────────────────────────────────────────
  static Rect _boundingRect(List<Rect> rects) {
    double l = rects[0].left, t = rects[0].top, r = rects[0].right, b = rects[0].bottom;
    for (final rc in rects) {
      l = math.min(l, rc.left); t = math.min(t, rc.top);
      r = math.max(r, rc.right); b = math.max(b, rc.bottom);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  static void _drawCenteredText(
    Canvas canvas, String text, Color color, Rect rect, double fontSize,
    {FontWeight fontWeight = FontWeight.bold}
  ) {
    final p = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, height: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    p.paint(canvas, Offset(
      rect.left + (rect.width - p.width) / 2,
      rect.top + (rect.height - p.height) / 2 + fontSize * 0.06,
    ));
  }
}
