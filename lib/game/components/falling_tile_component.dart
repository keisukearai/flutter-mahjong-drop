import 'dart:math' as math;
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
  // ドラッグ中に着地した場合、列を同期してから drop するコールバック
  final void Function(int col) syncCol;

  bool _landed = false;
  bool _squishing = false;
  double _targetX = 0;

  // 直接追従ドラッグ用
  bool _isDragging = false;
  int _visualCol = 0;
  double _dragStartFingerX = 0;
  double _dragStartTileX = 0;

  // 解析的キネマティクス用
  double _elapsed = 0;
  double _startY = 0;
  double _startVY = 0;
  double _cachedLandingY = double.infinity;

  FallingTileComponent({
    required this.tile,
    required double startX,
    required this.controller,
    required this.getColumnX,
    required this.syncCol,
  }) : super(
          position: Vector2(startX - BoardLayout.tileW / 2, -BoardLayout.tileH),
          size: Vector2(BoardLayout.tileW, BoardLayout.tileH),
          anchor: Anchor.topLeft,
        ) {
    _targetX = startX - BoardLayout.tileW / 2;
    _startY = -BoardLayout.tileH;
    _startVY = controller.fallSpeed * 0.3;
    _visualCol = controller.fallingCol;
  }

  void snapToColumnX(double cx) {
    _targetX = cx - BoardLayout.tileW / 2;
    _cachedLandingY = double.infinity;
  }

  /// ドラッグ開始：現在の牌位置と指位置を記録
  void startDrag(double fingerX) {
    _isDragging = true;
    _dragStartFingerX = fingerX;
    _dragStartTileX = position.x; // 現在の左端位置を起点にする
  }

  /// スワイプ中：開始時からの相対移動量を牌に反映（感度2倍）
  void setDragX(double fingerX) {
    if (!_isDragging) return;
    final deltaX = fingerX - _dragStartFingerX;
    final newTileX = _dragStartTileX + deltaX * 1.5;
    // ボード端でクランプ（左右の列中心 ± 半牌）
    final leftBound = getColumnX(0) - BoardLayout.tileW / 2;
    final rightBound = getColumnX(BoardLayout.cols - 1) - BoardLayout.tileW / 2;
    _targetX = newTileX.clamp(leftBound, rightBound);
    final newCol = _nearestColumn(_targetX + BoardLayout.tileW / 2);
    if (newCol != _visualCol) {
      _visualCol = newCol;
      _cachedLandingY = double.infinity;
    }
  }

  /// スワイプ終了：列スナップモードに戻す
  void endDrag() {
    _isDragging = false;
    _cachedLandingY = double.infinity;
  }

  bool get isDragging => _isDragging;
  int get nearestColumn => _visualCol;

  int _nearestColumn(double fingerX) {
    int best = 0;
    double bestDist = double.infinity;
    for (int c = 0; c < BoardLayout.cols; c++) {
      final dist = (fingerX - getColumnX(c)).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = c;
      }
    }
    return best;
  }

  double get _landingY {
    if (_isDragging) {
      // ドラッグ中はビジュアル列を使い、キャッシュしない
      final row = controller.board.landingRow(_visualCol);
      return row < 0
          ? BoardLayout.boardOffsetY
          : BoardLayout.boardOffsetY + row * (BoardLayout.tileH + BoardLayout.gap);
    }
    if (_cachedLandingY != double.infinity) return _cachedLandingY;
    final row = controller.board.landingRow(controller.fallingCol);
    _cachedLandingY = row < 0
        ? BoardLayout.boardOffsetY
        : BoardLayout.boardOffsetY + row * (BoardLayout.tileH + BoardLayout.gap);
    return _cachedLandingY;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    // 水平移動
    // ドラッグ中は指に直接追従、終了後は指数 lerp で列スナップ（係数を下げてなめらか）
    final dx = _targetX - position.x;
    if (_isDragging) {
      position.x = _targetX;
    } else if (dx.abs() > 0.5) {
      position.x += dx * (1.0 - math.exp(-14.0 * dt)); // 22.0 → 14.0 でなめらかなスナップ
    } else {
      position.x = _targetX;
    }

    // 垂直：解析的キネマティクスで位置を直接計算
    _elapsed += dt;
    final maxSpeed = controller.fallSpeed;
    final accel = maxSpeed * 6.0;
    final tMax = (maxSpeed - _startVY) / accel;

    if (_elapsed <= tMax) {
      position.y = _startY + _startVY * _elapsed + 0.5 * accel * _elapsed * _elapsed;
    } else {
      final yAtTMax = _startY + _startVY * tMax + 0.5 * accel * tMax * tMax;
      position.y = yAtTMax + maxSpeed * (_elapsed - tMax);
    }

    final targetY = _landingY;
    if (position.y >= targetY) {
      position.y = targetY;
      _landed = true;
      _doSquish();
      if (_isDragging) {
        // ドラッグ中に着地：コントローラーの列をビジュアル列に合わせてから落下
        _isDragging = false;
        syncCol(_visualCol);
      }
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
