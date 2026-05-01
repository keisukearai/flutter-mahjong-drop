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
  /// individual tiles. Returns null otherwise.
  static WinResult? detect(BoardState board) {
    final melds = board.meldGroups;
    if (melds.length < 4) return null;

    final individuals = _collectIndividualTilePositions(board);

    for (final entry in individuals.entries) {
      if (entry.value.length < 2) continue;
      return WinResult(
        melds: melds.take(4).toList(),
        pairTile: entry.key,
        pairPositions: entry.value.take(2).toList(),
      );
    }
    return null;
  }

  /// Returns true when the board is in tenpai:
  /// - 4+ melds formed (waiting for any pair to complete the hand), or
  /// - 3+ melds formed and a pair already exists (waiting for 4th meld).
  static bool isTenpai(BoardState board) {
    if (detect(board) != null) return false;

    final melds = board.meldGroups;
    final individuals = _collectIndividualTilePositions(board);

    if (melds.length >= 4) {
      // 4メルド以上あれば雀頭待ちでテンパイ（個別牌がなくても次のペアで和了できる）
      return true;
    }

    if (melds.length >= 3) {
      return individuals.values.any((p) => p.length >= 2);
    }

    return false;
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

    // 字一色 (役満): 全牌が字牌かつ同種刻子の重複なし
    if (allTiles.every((t) => t.isHonor)) {
      final seen = <Tile>{};
      final noDuplicate = melds
          .where((g) => g.meld.isTriplet)
          .every((g) => seen.add(g.meld.tiles.first));
      if (noDuplicate) {
        yakumanCount++;
        yaku.add('字一色');
      }
    }

    // 三元牌の刻子を種別ごとに集計（重複カウント）
    final dragonTripletCounts = <HonorType, int>{};
    for (final g in melds.where((g) => g.meld.isTriplet && g.meld.tiles.first.isDragon)) {
      final h = g.meld.tiles.first.honor!;
      dragonTripletCounts[h] = (dragonTripletCounts[h] ?? 0) + 1;
    }

    // 大三元 (役満): 白・発・中がそれぞれちょうど1つずつの刻子（重複不可）
    if (dragonTripletCounts[HonorType.haku] == 1 &&
        dragonTripletCounts[HonorType.hatsu] == 1 &&
        dragonTripletCounts[HonorType.chun] == 1) {
      yakumanCount++;
      yaku.add('大三元');
    }

    // 風牌の刻子を種別ごとに集計（重複カウント）
    const windTypes = [HonorType.east, HonorType.south, HonorType.west, HonorType.north];
    final windTripletCounts = <HonorType, int>{};
    for (final g in melds.where((g) => g.meld.isTriplet && g.meld.tiles.first.isHonor &&
        !g.meld.tiles.first.isDragon)) {
      final h = g.meld.tiles.first.honor!;
      windTripletCounts[h] = (windTripletCounts[h] ?? 0) + 1;
    }

    // 大四喜 (役満): 四種の風牌すべてがちょうど1つずつの刻子
    if (windTypes.every((w) => windTripletCounts[w] == 1)) {
      yakumanCount++;
      yaku.add('大四喜');
    } else {
      // 小四喜 (役満): 三種の風牌が刻子（重複なし）かつ残り一種が雀頭
      final pairHonor = result.pairTile.honor;
      if (pairHonor != null && windTypes.contains(pairHonor)) {
        if (windTripletCounts[pairHonor] == null &&
            windTypes.where((w) => w != pairHonor).every((w) => windTripletCounts[w] == 1)) {
          yakumanCount++;
          yaku.add('小四喜');
        }
      }
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

      // 三元牌各1翻 (白・發・中)：同一種が複数あっても1翻のみ
      for (final honor in dragonTripletCounts.keys) {
        final name = honor == HonorType.haku
            ? '白'
            : honor == HonorType.hatsu
                ? '發'
                : '中';
        han += 1;
        yaku.add('$name 1翻');
      }

      // 断么九 (1翻): 2〜8の数牌のみ
      if (allTiles.every((t) => t.isSimple)) {
        han += 1;
        yaku.add('断么九 1翻');
      }

      // つも (1翻): 他に役がない場合の基本和了
      if (han == 0) {
        han += 1;
        yaku.add('自摸和 1翻');
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
