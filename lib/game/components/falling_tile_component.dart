import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import '../../mahjong/tile.dart';
import '../game_controller.dart';
import 'tile_painter.dart';

class FallingTileComponent extends PositionComponent {
  final Tile tile;
  final GameController controller;
  final double Function(int col) getColumnX;

  bool _landed = false;
  bool _squishing = false;

  FallingTileComponent({
    required this.tile,
    required double startX,
    required this.controller,
    required this.getColumnX,
  }) : super(
          position: Vector2(startX - BoardLayout.tileW / 2, -BoardLayout.tileH),
          size: Vector2(BoardLayout.tileW, BoardLayout.tileH),
          anchor: Anchor.topLeft,
        );

  void snapToColumnX(double cx) {
    position.x = cx - BoardLayout.tileW / 2;
  }

  double get _landingY {
    final row = controller.board.landingRow(controller.fallingCol);
    if (row < 0) return BoardLayout.boardOffsetY;
    return BoardLayout.boardOffsetY + row * (BoardLayout.tileH + BoardLayout.gap);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    position.y += controller.fallSpeed * dt;
    final targetY = _landingY;
    if (position.y >= targetY) {
      position.y = targetY;
      _landed = true;
      _doSquish();
      controller.dropTile();
    }
  }

  void _doSquish() {
    if (_squishing) return;
    _squishing = true;
    add(ScaleEffect.to(
      Vector2(1.15, 0.75),
      EffectController(duration: 0.07),
      onComplete: () => add(ScaleEffect.to(
        Vector2(1.0, 1.0),
        EffectController(duration: 0.12, curve: Curves.easeOut),
      )),
    ));
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, BoardLayout.tileW, BoardLayout.tileH);
    TilePainter.drawTile(canvas, tile, rect, isFalling: true);
  }
}

/// Shared layout constants used by all game components.
class BoardLayout {
  static double tileW = 46.0;
  static double tileH = 58.0;
  static const double gap = 3.0;
  static const double hudHeight = 90.0;
  static const double nextStripY = 90.0;
  static const double nextStripHeight = 40.0;
  static const double boardOffsetY = 130.0;
  static const int _cols = 7;
  static const int _rows = 11;

  /// Call once in MahjongGame.onLoad() to scale tiles to fit the screen.
  static void init(double screenW, double screenH) {
    const hPad = 12.0;
    const vPad = 12.0;

    final availW = screenW - 2 * hPad;
    final availH = screenH - boardOffsetY - vPad;

    final wByWidth = (availW - (_cols - 1) * gap) / _cols;
    final hByWidth = wByWidth * (58.0 / 46.0);

    final hByHeight = (availH - (_rows - 1) * gap) / _rows;
    final wByHeight = hByHeight * (46.0 / 58.0);

    final totalBoardH = _rows * hByWidth + (_rows - 1) * gap;
    if (totalBoardH <= availH) {
      tileW = wByWidth;
      tileH = hByWidth;
    } else {
      tileW = wByHeight;
      tileH = hByHeight;
    }
  }

  static double colX(int col, double screenW) {
    final totalW = _cols * tileW + (_cols - 1) * gap;
    final startX = (screenW - totalW) / 2;
    return startX + col * (tileW + gap) + tileW / 2;
  }

  static int get cols => _cols;
  static int get rows => _rows;

  static Rect cellRect(int row, int col, double screenW) {
    final cx = colX(col, screenW);
    final y = boardOffsetY + row * (tileH + gap);
    return Rect.fromLTWH(cx - tileW / 2, y, tileW, tileH);
  }
}
