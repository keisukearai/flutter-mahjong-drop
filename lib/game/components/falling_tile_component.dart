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

  static const double tileW = BoardLayout.tileW;
  static const double tileH = BoardLayout.tileH;

  bool _landed = false;
  bool _squishing = false;

  FallingTileComponent({
    required this.tile,
    required double startX,
    required this.controller,
    required this.getColumnX,
  }) : super(
          position: Vector2(startX - tileW / 2, -tileH),
          size: Vector2(tileW, tileH),
          anchor: Anchor.topLeft,
        );

  void snapToColumnX(double cx) {
    position.x = cx - tileW / 2;
  }

  double get _landingY {
    final row = controller.board.landingRow(controller.fallingCol);
    if (row < 0) return BoardLayout.boardOffsetY;
    return BoardLayout.boardOffsetY + row * (tileH + BoardLayout.gap);
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
    final rect = Rect.fromLTWH(0, 0, tileW, tileH);
    TilePainter.drawTile(canvas, tile, rect, isFalling: true);
  }
}

/// Shared layout constants used by all game components.
class BoardLayout {
  static const double tileW = 46.0;
  static const double tileH = 58.0;
  static const double gap = 3.0;
  static const double boardOffsetY = 54.0;

  static double colX(int col, double screenW) {
    final totalW = cols * tileW + (cols - 1) * gap;
    final startX = (screenW - totalW) / 2;
    return startX + col * (tileW + gap) + tileW / 2;
  }

  static int get cols => 7;
  static int get rows => 11;

  static Rect cellRect(int row, int col, double screenW) {
    final cx = colX(col, screenW);
    final y = boardOffsetY + row * (tileH + gap);
    return Rect.fromLTWH(cx - tileW / 2, y, tileW, tileH);
  }
}
