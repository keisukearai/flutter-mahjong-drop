import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';
import '../mahjong/tile.dart';
import 'game_controller.dart';
import 'components/board_component.dart';
import 'components/falling_tile_component.dart';

class MahjongGame extends FlameGame with TapCallbacks, PanDetector {
  final GameController controller;

  late final BoardComponent _board;
  FallingTileComponent? _fallingComp;
  Tile? _trackedTile;

  // Drag tracking
  double _dragAccum = 0;

  MahjongGame(this.controller);

  @override
  Color backgroundColor() => const Color(0xFF1A3D2B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _board = BoardComponent(board: controller.board);
    add(_board);
    add(_HudComponent(controller: controller));
    add(_ColumnGuideComponent(game: this));
    controller.addListener(_onControllerUpdate);
    _syncFallingTile();
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerUpdate);
    super.onRemove();
  }

  void _onControllerUpdate() {
    _syncFallingTile();
    _board.highlightWin = controller.pendingWin;
    if (controller.isPaused) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  void _syncFallingTile() {
    final tile = controller.fallingTile;
    if (tile == null) {
      _fallingComp?.removeFromParent();
      _fallingComp = null;
      _trackedTile = null;
      return;
    }
    if (identical(_trackedTile, tile)) {
      _fallingComp?.snapToColumnX(_colX(controller.fallingCol));
      return;
    }
    _fallingComp?.removeFromParent();
    _trackedTile = tile;
    _fallingComp = FallingTileComponent(
      tile: tile,
      startX: _colX(controller.fallingCol),
      controller: controller,
      getColumnX: _colX,
    );
    add(_fallingComp!);
  }

  double _colX(int col) => BoardLayout.colX(col, size.x);

  // ── Input ─────────────────────────────────────────────────────────

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!controller.isPlaying) return;
    _dragAccum += info.delta.global.x;
    final threshold = BoardLayout.tileW + BoardLayout.gap;
    while (_dragAccum > threshold) {
      controller.moveRight();
      _dragAccum -= threshold;
    }
    while (_dragAccum < -threshold) {
      controller.moveLeft();
      _dragAccum += threshold;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) => _dragAccum = 0;

  @override
  void onTapDown(TapDownEvent event) {
    if (!controller.isPlaying) return;
    final x = event.canvasPosition.x;
    final tileCenterX = _colX(controller.fallingCol);
    final halfTile = BoardLayout.tileW / 2;
    if (x < tileCenterX - halfTile) {
      controller.moveLeft();
    } else if (x > tileCenterX + halfTile) {
      controller.moveRight();
    } else {
      _fallingComp?.removeFromParent();
      _fallingComp = null;
      _trackedTile = null;
      controller.dropTile();
    }
  }
}

// ── HUD rendered inside Flame ──────────────────────────────────────
class _HudComponent extends Component with HasGameReference<MahjongGame> {
  final GameController controller;
  _HudComponent({required this.controller});

  @override
  void render(Canvas canvas) {
    final sw = game.size.x;
    // Background bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, BoardLayout.boardOffsetY),
      Paint()..color = const Color(0xCC1A237E),
    );
    _drawText(canvas, 'SCORE', const Color(0x99FFFFFF), 9, Offset(14, 6));
    _drawText(canvas, _fmt(controller.score), Colors.white, 18, Offset(14, 18));
    _drawText(canvas, '×${controller.combo}', const Color(0xFFFFD54F), 18, Offset(sw / 2 - 20, 16));
    _drawText(canvas, 'LV.${controller.level}', const Color(0xFF80CBC4), 14, Offset(sw - 150, 20));
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _drawText(Canvas canvas, String text, Color color, double size, Offset pos) {
    final p = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, height: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, pos);
  }
}

// ── Column guide dots ──────────────────────────────────────────────
class _ColumnGuideComponent extends Component {
  final MahjongGame game;
  _ColumnGuideComponent({required this.game});

  @override
  void render(Canvas canvas) {
    final sw = game.size.x;
    final paint = Paint()..color = const Color(0x22FFFFFF);
    for (int c = 0; c < BoardLayout.cols; c++) {
      final x = BoardLayout.colX(c, sw);
      canvas.drawCircle(Offset(x, BoardLayout.boardOffsetY + 10), 3, paint);
    }
  }
}
