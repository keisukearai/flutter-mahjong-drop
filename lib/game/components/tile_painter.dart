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

  // Override in tests to load a CJK-capable font (e.g. 'ArialUnicode')
  static String? fontFamily;

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
    final numFs = rect.height * 0.44;
    final manFs = rect.height * 0.34;
    final gap   = rect.height * 0.01;
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
      manFs, fontWeight: FontWeight.w900,
    );
  }

  // ── Pin (筒子): decorated circle pips ────────────────────────────
  static const _pinPips = <int, List<(double, double)>>{
    1: [(0.50, 0.50)],
    2: [(0.50, 0.28), (0.50, 0.72)],
    3: [(0.27, 0.22), (0.50, 0.50), (0.73, 0.78)],
    4: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.78), (0.73, 0.78)],
    5: [(0.27, 0.22), (0.73, 0.22), (0.50, 0.50), (0.27, 0.78), (0.73, 0.78)],
    6: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.50), (0.73, 0.50), (0.27, 0.78), (0.73, 0.78)],
    7: [(0.27, 0.22), (0.50, 0.29), (0.73, 0.36), (0.27, 0.59), (0.73, 0.59), (0.27, 0.78), (0.73, 0.78)],
    8: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.41), (0.73, 0.41), (0.27, 0.59), (0.73, 0.59), (0.27, 0.78), (0.73, 0.78)],
    9: [(0.22, 0.22), (0.50, 0.22), (0.78, 0.22), (0.22, 0.50), (0.50, 0.50), (0.78, 0.50), (0.22, 0.78), (0.50, 0.78), (0.78, 0.78)],
  };

  // Pip indices that use red coloring (1-pin center only)
  static const _pinRedPips = <int, Set<int>>{
    1: {0},
  };

  // Pips where red/navy are fully inverted (red outer, navy center)
  static const _pinInvertedPips = <int, Set<int>>{
    3: {1},
    5: {2},
    6: {2, 3, 4, 5},
    7: {3, 4, 5, 6},
    9: {3, 4, 5},
  };

  static void _drawPin(Canvas canvas, Tile tile, Rect rect, double opacity) {
    final pips = _pinPips[tile.number] ?? [];
    final content = rect.deflate(2.5);
    final n = tile.number;
    final circR = math.min(content.width, content.height) /
        (n == 1 ? 2.1 : n == 2 ? 3.8 : n <= 4 ? 5.0 : n <= 6 ? 5.6 : 6.8);

    final navy  = const Color(0xFF283593).withValues(alpha: opacity);
    final cream = const Color(0xFFFFF9E6).withValues(alpha: opacity);
    final red   = const Color(0xFFBB0000).withValues(alpha: opacity);
    final redSet      = _pinRedPips[n] ?? {};
    final invertedSet = _pinInvertedPips[n] ?? {};

    for (int i = 0; i < pips.length; i++) {
      final pip = pips[i];
      final c = Offset(
        content.left + content.width * pip.$1,
        content.top + content.height * pip.$2,
      );
      _drawPinCircle(canvas, c, circR, redSet.contains(i), navy, cream, red,
          invertColors: invertedSet.contains(i));
    }
  }

  static void _drawPinCircle(Canvas canvas, Offset c, double r, bool redCenter,
      Color navy, Color cream, Color red, {bool invertColors = false}) {
    final main   = invertColors ? red : navy;
    final center = invertColors ? navy : (redCenter ? red : navy);
    // Thick outer ring
    canvas.drawCircle(c, r, Paint()..color = main);
    // Cream inner background
    canvas.drawCircle(c, r * 0.76, Paint()..color = cream);
    // 8 petal dots arranged in a ring (flower pattern)
    final petalR = r * 0.175;
    final petalD = r * 0.50;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawCircle(
        Offset(c.dx + petalD * math.cos(angle), c.dy + petalD * math.sin(angle)),
        petalR,
        Paint()..color = main,
      );
    }
    // Inner ring separator
    canvas.drawCircle(c, r * 0.29,
        Paint()..color = main..style = PaintingStyle.stroke..strokeWidth = 0.9);
    // Center dot
    canvas.drawCircle(c, r * 0.19, Paint()..color = center);
  }

  // ── Sou (索子): bamboo dumbbell pips ─────────────────────────────
  static const _souPips = <int, List<(double, double)>>{
    2: [(0.50, 0.27), (0.50, 0.73)],
    3: [(0.50, 0.25), (0.32, 0.72), (0.68, 0.72)],
    4: [(0.30, 0.27), (0.70, 0.27), (0.30, 0.73), (0.70, 0.73)],
    5: [(0.30, 0.22), (0.70, 0.22), (0.50, 0.50), (0.30, 0.78), (0.70, 0.78)],
    6: [(0.30, 0.19), (0.70, 0.19), (0.30, 0.50), (0.70, 0.50), (0.30, 0.81), (0.70, 0.81)],
    7: [(0.50, 0.16), (0.30, 0.37), (0.70, 0.37), (0.30, 0.59), (0.70, 0.59), (0.30, 0.81), (0.70, 0.81)],
    8: [(0.20, 0.18), (0.80, 0.18), (0.40, 0.36), (0.60, 0.36), (0.40, 0.64), (0.60, 0.64), (0.20, 0.82), (0.80, 0.82)],
    9: [(0.22, 0.22), (0.50, 0.22), (0.78, 0.22), (0.22, 0.50), (0.50, 0.50), (0.78, 0.50), (0.22, 0.78), (0.50, 0.78), (0.78, 0.78)],
  };

  // 5-sou center pip (index 2) is red
  static const _souRedPips = <int, Set<int>>{5: {2}, 7: {0}, 9: {1, 4, 7}};

  static void _drawSou(Canvas canvas, Tile tile, Rect rect, double opacity) {
    if (tile.number == 1) {
      _drawSou1(canvas, rect, opacity);
      return;
    }
    final pips = _souPips[tile.number] ?? [];
    final content = rect.deflate(2.5);
    final n = tile.number;
    final stickH = content.height /
        (n <= 4 ? 3.0 : n <= 6 ? 4.2 : 4.8);
    final stickW = math.min(content.width * 0.30, stickH * 0.68);
    final redSet = _souRedPips[n] ?? {};

    for (int i = 0; i < pips.length; i++) {
      final pip = pips[i];
      final cx = content.left + content.width * pip.$1;
      final cy = content.top + content.height * pip.$2;
      _drawSouSegment(canvas, Offset(cx, cy), stickW, stickH, opacity,
          isRed: redSet.contains(i));
    }
  }

  static void _drawSouSegment(Canvas canvas, Offset c, double w, double h,
      double opacity, {bool isRed = false}) {
    final outer = (isRed ? const Color(0xFF8B0000) : const Color(0xFF1B5E20))
        .withValues(alpha: opacity);
    final inner = (isRed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A))
        .withValues(alpha: opacity);
    final band  = (isRed ? const Color(0xFF4A0000) : const Color(0xFF0A2E0A))
        .withValues(alpha: opacity);

    // Dumbbell shape: two ovals overlapping slightly at center
    final oy = h * 0.26;
    final topOval = Rect.fromCenter(center: Offset(c.dx, c.dy - oy), width: w, height: h * 0.58);
    final botOval = Rect.fromCenter(center: Offset(c.dx, c.dy + oy), width: w, height: h * 0.58);

    canvas.drawOval(topOval, Paint()..color = outer);
    canvas.drawOval(botOval, Paint()..color = outer);
    // Fill any gap between ovals
    final gapTop = topOval.bottom;
    final gapBot = botOval.top;
    if (gapBot < gapTop) {
      canvas.drawRect(
        Rect.fromLTRB(c.dx - w * 0.28, gapBot, c.dx + w * 0.28, gapTop),
        Paint()..color = outer,
      );
    }

    // Inner highlights (left half of each oval)
    for (final oy2 in [c.dy - oy, c.dy + oy]) {
      final oval = Rect.fromCenter(center: Offset(c.dx, oy2), width: w, height: h * 0.58);
      canvas.drawOval(
        Rect.fromLTRB(oval.left + 1.5, oval.top + 2, oval.left + oval.width * 0.52, oval.bottom - 2),
        Paint()..color = inner,
      );
    }

    // Horizontal node band at center joint
    canvas.drawLine(
      Offset(c.dx - w * 0.46, c.dy),
      Offset(c.dx + w * 0.46, c.dy),
      Paint()..color = band..strokeWidth = 1.6,
    );
  }

  static void _drawSou1(Canvas canvas, Rect rect, double opacity) {
    final darkGreen  = const Color(0xFF1B5E20).withValues(alpha: opacity);
    final lightGreen = const Color(0xFF66BB6A).withValues(alpha: opacity);
    final red        = const Color(0xFFCC0000).withValues(alpha: opacity);
    final c = rect.center;

    // Main body oval (tall)
    final body = Rect.fromCenter(
      center: Offset(c.dx, c.dy - rect.height * 0.02),
      width: rect.width * 0.50,
      height: rect.height * 0.60,
    );
    canvas.drawOval(body, Paint()..color = darkGreen);
    // Inner lighter oval
    canvas.drawOval(body.deflate(3.5), Paint()..color = lightGreen);

    // Red center circle
    canvas.drawCircle(
      Offset(c.dx, c.dy - rect.height * 0.02),
      body.width * 0.20,
      Paint()..color = red,
    );

    // Bamboo frond lines radiating from top
    final frondPaint = Paint()
      ..color = darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final topC = Offset(c.dx, body.top + 4);
    for (int i = -2; i <= 2; i++) {
      final angle = -math.pi / 2 + i * 0.32;
      final len = rect.height * 0.18;
      canvas.drawLine(
        topC,
        Offset(topC.dx + len * math.cos(angle), topC.dy + len * math.sin(angle)),
        frondPaint,
      );
    }

    // Bird legs at bottom
    final legPaint = Paint()
      ..color = darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final legBase = Offset(c.dx, body.bottom - 2);
    canvas.drawLine(legBase, Offset(legBase.dx - 4, legBase.dy + 6), legPaint);
    canvas.drawLine(legBase, Offset(legBase.dx + 4, legBase.dy + 6), legPaint);
  }

  // ── Honor (字牌) ────────────────────────────────────────────────────
  static void _drawHonor(Canvas canvas, Tile tile, Rect rect, double opacity) {
    if (tile.honor == HonorType.haku) {
      // 白: blank tile (no character, no border)
      return;
    }
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
      rect.deflate(2), rect.height * 0.60,
      fontWeight: FontWeight.w900,
    );
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
    const gap = 1.5;

    final firstTile = group.meld.tiles.first;
    final bg = _meldBgColor(firstTile);
    final border = isWinHighlight ? const Color(0xFFFFD700) : _meldBorderColor(firstTile);
    final glowColor = isWinHighlight
        ? const Color(0x99FFD700)
        : _meldBorderColor(firstTile).withValues(alpha: 0.35);

    // Glow shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.inflate(5), const Radius.circular(16)),
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    if (group.shape == MeldShape.lShape) {
      // Draw each cell individually so the empty corner stays clear
      for (final rect in cellRects) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(10)),
          Paint()..color = bg,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(10)),
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = isWinHighlight ? 2.8 : 2.2,
        );
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer.inflate(2), const Radius.circular(14)),
        Paint()..color = bg,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer.inflate(2), const Radius.circular(14)),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isWinHighlight ? 2.8 : 2.2,
      );
    }

    for (int i = 0; i < 3; i++) {
      drawTile(canvas, group.meld.tiles[i], cellRects[i].deflate(gap));
    }

    _drawMeldBadge(canvas, outer, group.meld.type, isWinHighlight: isWinHighlight);
  }

  static Color _meldBgColor(Tile tile) {
    if (tile.isHonor) return const Color(0xFFE1BEE7);
    return switch (tile.suit) {
      TileSuit.man   => const Color(0xFFFFCDD2),
      TileSuit.pin   => const Color(0xFFBBDEFB),
      TileSuit.sou   => const Color(0xFFC8E6C9),
      TileSuit.honor => const Color(0xFFE1BEE7),
    };
  }

  static Color _meldBorderColor(Tile tile) {
    if (tile.isHonor) return const Color(0xFF7B1FA2);
    return switch (tile.suit) {
      TileSuit.man   => const Color(0xFFE53935),
      TileSuit.pin   => const Color(0xFF1E88E5),
      TileSuit.sou   => const Color(0xFF43A047),
      TileSuit.honor => const Color(0xFF7B1FA2),
    };
  }

  static void _drawMeldBadge(Canvas canvas, Rect outer, MeldType type, {bool isWinHighlight = false}) {
    final badgeColor = isWinHighlight
        ? const Color(0xFFFFD700)
        : (type == MeldType.triplet ? const Color(0xFFE53935) : const Color(0xFF1E88E5));
    final center = Offset(outer.right - 7, outer.top + 7);
    canvas.drawCircle(center, 6,
        Paint()..color = badgeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(center, 6, Paint()..color = badgeColor);
    canvas.drawCircle(center, 6,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final label = type == MeldType.triplet ? '刻' : '順';
    _drawCenteredText(canvas, label, Colors.white,
        Rect.fromCenter(center: center, width: 12, height: 12), 8,
        fontWeight: FontWeight.w900);
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
      text: TextSpan(text: text, style: TextStyle(
        color: color, fontSize: fontSize,
        fontWeight: fontWeight, height: 1.0,
        fontFamily: fontFamily,
      )),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    final metrics = p.computeLineMetrics();
    final dy = metrics.isNotEmpty
        ? rect.center.dy - metrics.first.ascent / 2
        : rect.top + (rect.height - p.height) / 2 + fontSize * 0.06;
    p.paint(canvas, Offset(
      rect.left + (rect.width - p.width) / 2,
      dy,
    ));
  }
}
