import '../mahjong/tile.dart';
import 'board_state.dart';

class WinScore {
  final bool isYakuman;
  final int han;
  final int points;
  final String levelName;
  final List<String> yakuList;

  const WinScore({
    required this.isYakuman,
    required this.han,
    required this.points,
    required this.levelName,
    required this.yakuList,
  });
}

class WinResult {
  final List<MeldGroup> melds; // 4 melds
  final Tile pairTile;
  final List<(int, int)> pairPositions; // 2 cells

  const WinResult({
    required this.melds,
    required this.pairTile,
    required this.pairPositions,
  });

  List<(int, int)> get allPositions {
    final result = <(int, int)>[];
    // We'll compute meld positions from the board externally
    return result;
  }
}

class WinDetector {
  /// Returns a WinResult if the board contains ≥4 meld blocks + a pair of
  /// individual tiles, and each tile type is used at most 4 times (standard
  /// mahjong rule). Returns null otherwise.
  static WinResult? detect(BoardState board) {
    final melds = board.meldGroups;
    if (melds.length < 4) return null;

    final individuals = _collectIndividualTilePositions(board);

    // Try each candidate pair, then find 4 melds that keep tile counts ≤ 4.
    for (final entry in individuals.entries) {
      if (entry.value.length < 2) continue;
      final pairTile = entry.key;
      final selected = _selectValidMelds(melds, pairTile);
      if (selected != null) {
        return WinResult(
          melds: selected,
          pairTile: pairTile,
          pairPositions: entry.value.take(2).toList(),
        );
      }
    }
    return null;
  }

  /// Returns 4 melds whose tile counts, combined with the pair, do not exceed
  /// 4 per tile type. Returns null if no such combination exists.
  static List<MeldGroup>? _selectValidMelds(List<MeldGroup> melds, Tile pairTile) {
    for (final combo in _combinations(melds, 4)) {
      if (_isValidHand(combo, pairTile)) return combo;
    }
    return null;
  }

  static bool _isValidHand(List<MeldGroup> melds, Tile pairTile) {
    final count = <Tile, int>{};
    for (final g in melds) {
      for (final t in g.meld.tiles) {
        count[t] = (count[t] ?? 0) + 1;
      }
    }
    count[pairTile] = (count[pairTile] ?? 0) + 2;
    return count.values.every((c) => c <= 4);
  }

  static Iterable<List<T>> _combinations<T>(List<T> list, int k) sync* {
    if (k == 0) { yield []; return; }
    if (list.length < k) return;
    for (int i = 0; i <= list.length - k; i++) {
      for (final rest in _combinations(list.sublist(i + 1), k - 1)) {
        yield [list[i], ...rest];
      }
    }
  }

  static Map<Tile, List<(int, int)>> _collectIndividualTilePositions(BoardState board) {
    final map = <Tile, List<(int, int)>>{};
    for (int r = 0; r < BoardState.rows; r++) {
      for (int c = 0; c < BoardState.cols; c++) {
        final cell = board.at(r, c);
        if (cell is TileCell) {
          map.putIfAbsent(cell.tile, () => []).add((r, c));
        }
      }
    }
    return map;
  }

  /// Compute yaku, han count, and score for a given win result.
  static WinScore computeScore(WinResult result) {
    final melds = result.melds;
    final allTiles = [
      ...melds.expand((g) => g.meld.tiles),
      result.pairTile,
      result.pairTile,
    ];

    int yakumanCount = 0;
    int han = 0;
    final yaku = <String>[];

    // 字一色 (役満): 全牌が字牌
    if (allTiles.every((t) => t.isHonor)) {
      yakumanCount++;
      yaku.add('字一色');
    }

    // 大三元 (役満): 三元牌3種すべてが刻子
    final dragonTriplets = melds.where((g) =>
        g.meld.isTriplet && g.meld.tiles.first.isDragon).length;
    if (dragonTriplets >= 3) {
      yakumanCount++;
      yaku.add('大三元');
    }

    if (yakumanCount == 0) {
      final hasHonor = allTiles.any((t) => t.isHonor);
      final nonHonorSuits = allTiles
          .where((t) => !t.isHonor)
          .map((t) => t.suit)
          .toSet();

      // 清一色 (6翻)
      if (!hasHonor && nonHonorSuits.length == 1) {
        han += 6;
        yaku.add('清一色 6翻');
      } else if (nonHonorSuits.length == 1 && nonHonorSuits.isNotEmpty) {
        // 混一色 (3翻)
        han += 3;
        yaku.add('混一色 3翻');
      }

      // 対々和 (2翻)
      if (melds.every((g) => g.meld.isTriplet)) {
        han += 2;
        yaku.add('対々和 2翻');
      }

      // 三元牌各1翻 (白・發・中)
      for (final g in melds) {
        if (g.meld.isTriplet && g.meld.tiles.first.isDragon) {
          final h = g.meld.tiles.first.honor!;
          final name = h == HonorType.haku
              ? '白'
              : h == HonorType.hatsu
                  ? '發'
                  : '中';
          han += 1;
          yaku.add('$name 1翻');
        }
      }

      // 断么九 (1翻): 2〜8の数牌のみ
      if (allTiles.every((t) => t.isSimple)) {
        han += 1;
        yaku.add('断么九 1翻');
      }
    }

    if (yakumanCount > 0) {
      final pts = 32000 * yakumanCount;
      final level = yakumanCount >= 2 ? 'ダブル役満' : '役満';
      return WinScore(
        isYakuman: true,
        han: 13 * yakumanCount,
        points: pts,
        levelName: level,
        yakuList: yaku,
      );
    }

    final (pts, level) = switch (han) {
      >= 11 => (32000, '役満'),
      >= 8  => (24000, '三倍満'),
      >= 6  => (16000, '倍満'),
      5     => (12000, '跳満'),
      >= 3  => (8000, '満貫'),
      2     => (2000, '2翻'),
      1     => (1000, '1翻'),
      _     => (500, '和了'),
    };

    return WinScore(
      isYakuman: false,
      han: han,
      points: pts,
      levelName: level,
      yakuList: yaku,
    );
  }
}
