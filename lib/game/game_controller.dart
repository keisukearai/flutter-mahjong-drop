import 'dart:math';
import 'package:flutter/foundation.dart';
import '../mahjong/tile.dart';
import 'board_state.dart';
import 'meld_merger.dart';
import 'win_detector.dart';

enum GameStatus { playing, winAnimation, gameOver }

enum GameMode { sanma, easy }

class GameEvent {
  final List<MeldGroup> newMelds;
  final WinResult? win;
  const GameEvent({this.newMelds = const [], this.win});
}

class GameController extends ChangeNotifier {
  static const int numCols = BoardState.cols;

  final _random = Random();
  List<Tile> _bag = [];

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

  // Last event for animations
  GameEvent lastEvent = const GameEvent();
  WinResult? pendingWin;
  WinScore? pendingScore;

  GameController({this.mode = GameMode.sanma}) {
    _init();
  }

  void _init() {
    // Reset board
    for (int r = 0; r < BoardState.rows; r++) {
      for (int c = 0; c < BoardState.cols; c++) {
        board.cells[r][c] = const EmptyCell();
      }
    }
    _bag = _buildBag()..shuffle(_random);
    score = 0;
    combo = 0;
    level = 1;
    status = GameStatus.playing;
    isPaused = false;
    lastEvent = const GameEvent();
    pendingWin = null;
    pendingScore = null;
    completedYaku = [];
    _spawnNext();
  }

  List<Tile> _buildBag() {
    final bag = <Tile>[];
    if (mode == GameMode.easy) {
      // 字牌のみ: 東南西北白發中
      for (final h in HonorType.values) {
        for (int i = 0; i < 4; i++) { bag.add(Tile.honor(h)); }
      }
    } else {
      // 三人麻雀: 萬子は1と9のみ、筒子・索子は1〜9、字牌あり
      for (int n in [1, 9]) {
        for (int i = 0; i < 4; i++) { bag.add(Tile.number(TileSuit.man, n)); }
      }
      for (final suit in [TileSuit.pin, TileSuit.sou]) {
        for (int n = 1; n <= 9; n++) {
          for (int i = 0; i < 4; i++) { bag.add(Tile.number(suit, n)); }
        }
      }
      for (final h in HonorType.values) {
        for (int i = 0; i < 4; i++) { bag.add(Tile.honor(h)); }
      }
    }
    return bag;
  }

  void _spawnNext() {
    if (_bag.isEmpty) _bag = _buildBag()..shuffle(_random);
    fallingTile = _bag.removeLast();
    fallingCol = numCols ~/ 2;
    notifyListeners();
  }

  double get fallSpeed => (160.0 + level * 20.0).clamp(0.0, 500.0);

  bool get isPlaying => status == GameStatus.playing && !isPaused;

  void togglePause() {
    if (status != GameStatus.playing) return;
    isPaused = !isPaused;
    notifyListeners();
  }

  void moveLeft() {
    if (fallingCol > 0 && isPlaying) {
      fallingCol--;
      notifyListeners();
    }
  }

  void moveRight() {
    if (fallingCol < numCols - 1 && isPlaying) {
      fallingCol++;
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
      pendingWin = win;
      pendingScore = WinDetector.computeScore(win);
      status = GameStatus.winAnimation;
      notifyListeners();
      // 次の牌は confirmWin() 後に spawn
    } else {
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
    status = GameStatus.playing;
    _spawnNext();
  }

  void restart() {
    _init();
    notifyListeners();
  }
}
