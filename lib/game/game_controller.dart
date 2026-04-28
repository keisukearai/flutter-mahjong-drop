import 'dart:math';
import 'package:flutter/foundation.dart';
import '../mahjong/tile.dart';
import 'board_state.dart';
import 'meld_merger.dart';
import 'win_detector.dart';

enum GameStatus { playing, winAnimation, gameOver }

enum GameMode { easy, normal, oni }

class GameEvent {
  final List<MeldGroup> newMelds;
  final WinResult? win;
  const GameEvent({this.newMelds = const [], this.win});
}

class GameController extends ChangeNotifier {
  static const int numCols = BoardState.cols;

  final _random = Random();

  final BoardState board = BoardState();

  Tile? fallingTile;
  int fallingCol = numCols ~/ 2;

  int score = 0;
  int combo = 0;
  int level = 1;
  GameStatus status = GameStatus.playing;
  bool isPaused = false;

  List<String> completedYaku = [];

  final GameMode mode;

  List<Tile> nextTiles = [];

  bool isTenpai = false;

  // Last event for animations
  GameEvent lastEvent = const GameEvent();
  WinResult? pendingWin;
  WinScore? pendingScore;

  GameController({this.mode = GameMode.normal}) {
    _init();
  }

  void _init() {
    // Reset board
    for (int r = 0; r < BoardState.rows; r++) {
      for (int c = 0; c < BoardState.cols; c++) {
        board.cells[r][c] = const EmptyCell();
      }
    }
    score = 0;
    combo = 0;
    level = 1;
    status = GameStatus.playing;
    isPaused = false;
    isTenpai = false;
    lastEvent = const GameEvent();
    pendingWin = null;
    pendingScore = null;
    completedYaku = [];
    nextTiles = List.generate(3, (_) => _pickTile());
    _spawnNext();
  }

  // easy:   字牌のみ
  // normal: 萬子1/9・筒子全部・索子1/9・字牌（索子2-8なし・フェーズなし）
  // oni:    スコアフェーズ解放で全牌（旧sanmaモード）
  //   Phase 1 (score <  5000): man 1/9, pin 1-3/7-9, honors  — no sou
  //   Phase 2 (score < 15000): + pin 4-6, sou 1-3/7-9
  //   Phase 3 (score >= 15000): + sou 4-6 (full sou)
  Tile _pickTile() {
    if (mode == GameMode.easy) {
      final h = HonorType.values[_random.nextInt(HonorType.values.length)];
      return Tile.honor(h);
    }

    if (mode == GameMode.normal) {
      final pool = <Tile>[];
      for (final n in [1, 9]) { pool.add(Tile.number(TileSuit.man, n)); }
      for (int n = 1; n <= 9; n++) { pool.add(Tile.number(TileSuit.pin, n)); }
      for (final n in [1, 9]) { pool.add(Tile.number(TileSuit.sou, n)); }
      for (final h in HonorType.values) { pool.add(Tile.honor(h)); }
      return pool[_random.nextInt(pool.length)];
    }

    // oni: phase-based full tile set
    final pool = <Tile>[];
    for (final n in [1, 9]) { pool.add(Tile.number(TileSuit.man, n)); }
    for (final n in [1, 2, 3, 7, 8, 9]) { pool.add(Tile.number(TileSuit.pin, n)); }
    if (score >= 5000) {
      for (final n in [4, 5, 6]) { pool.add(Tile.number(TileSuit.pin, n)); }
      for (final n in [1, 2, 3, 7, 8, 9]) { pool.add(Tile.number(TileSuit.sou, n)); }
    }
    if (score >= 15000) {
      for (final n in [4, 5, 6]) { pool.add(Tile.number(TileSuit.sou, n)); }
    }
    for (final h in HonorType.values) { pool.add(Tile.honor(h)); }

    return pool[_random.nextInt(pool.length)];
  }

  void _spawnNext() {
    fallingTile = nextTiles.removeAt(0);
    nextTiles.add(_pickTile());
    fallingCol = numCols ~/ 2;
    notifyListeners();
  }

  int get minFreeRows {
    int minFree = BoardState.rows - 1;
    for (int c = 0; c < BoardState.cols; c++) {
      final lr = board.landingRow(c);
      final free = lr < 0 ? 0 : lr;
      if (free < minFree) minFree = free;
    }
    return minFree;
  }

  double get fallSpeed {
    final baseSpeed = (160.0 + level * 20.0).clamp(0.0, 500.0);

    // Find the minimum free rows across all columns (most crowded column)
    final minFree = minFreeRows;

    // No change when board is mostly empty (minFree >= 8).
    // Linear slowdown to 30% as the tallest stack approaches the top.
    const int slowThreshold = 8;
    const double minMultiplier = 0.3;
    final multiplier = minFree >= slowThreshold
        ? 1.0
        : minMultiplier + (1.0 - minMultiplier) * (minFree / slowThreshold);

    return baseSpeed * multiplier;
  }

  bool get isPlaying => status == GameStatus.playing && !isPaused;

  void togglePause() {
    if (status != GameStatus.playing) return;
    isPaused = !isPaused;
    notifyListeners();
  }

  void moveLeft() {
    if (fallingCol > 0 && isPlaying) {
      fallingCol--;
      lastEvent = const GameEvent();
      notifyListeners();
    }
  }

  void moveRight() {
    if (fallingCol < numCols - 1 && isPlaying) {
      fallingCol++;
      lastEvent = const GameEvent();
      notifyListeners();
    }
  }

  void dropTile() {
    final tile = fallingTile;
    if (tile == null || !isPlaying) return;

    if (board.isColumnFull(fallingCol)) {
      status = GameStatus.gameOver;
      notifyListeners();
      return;
    }

    fallingTile = null;
    board.placeTile(tile, fallingCol);

    final newMelds = MeldMerger.mergeAll(board);
    final win = WinDetector.detect(board);

    lastEvent = GameEvent(newMelds: newMelds, win: win);

    if (win != null) {
      isTenpai = false;
      pendingWin = win;
      pendingScore = WinDetector.computeScore(win);
      status = GameStatus.winAnimation;
      notifyListeners();
      // 次の牌は confirmWin() 後に spawn
    } else {
      isTenpai = WinDetector.isTenpai(board);
      notifyListeners();
      _spawnNext();
    }
  }

  void confirmWin() {
    final win = pendingWin;
    if (win == null) return;

    // Collect all positions to remove
    final toRemove = <(int, int)>[];
    for (final group in win.melds) {
      toRemove.addAll(board.positionsOf(group));
    }
    toRemove.addAll(win.pairPositions);

    board.clearCells(toRemove);
    board.applyGravity();

    final pts = pendingScore?.points ?? 500;
    final comboBonus = 1.0 + combo * 0.5;
    score += (pts * comboBonus).round();
    combo++;
    level = (score ~/ 12000) + 1;

    if (pendingScore != null) {
      for (final y in pendingScore!.yakuList) {
        if (!completedYaku.contains(y)) completedYaku.add(y);
      }
    }

    pendingWin = null;
    pendingScore = null;
    isTenpai = false;
    status = GameStatus.playing;
    _spawnNext();
  }

  void restart() {
    _init();
    notifyListeners();
  }
}
