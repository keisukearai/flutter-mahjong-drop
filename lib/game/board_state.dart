import '../mahjong/tile.dart';
import '../mahjong/meld.dart';

/// A logical meld group formed on the board (3 cells that merged).
class MeldGroup {
  final Meld meld;
  // orientation: horizontal or vertical
  final bool isHorizontal;
  MeldGroup(this.meld, {required this.isHorizontal});
}

sealed class BoardCell {
  const BoardCell();
}

class EmptyCell extends BoardCell {
  const EmptyCell();
}

class TileCell extends BoardCell {
  final Tile tile;
  const TileCell(this.tile);
}

/// One of the 3 cells in a formed meld block.
class MeldPartCell extends BoardCell {
  final MeldGroup group;
  final int index; // 0,1,2
  const MeldPartCell(this.group, this.index);
}

class BoardState {
  static const int cols = 7;
  static const int rows = 11;

  // cells[row][col] — row 0 = top of screen, row rows-1 = bottom
  final List<List<BoardCell>> cells;

  BoardState()
      : cells = List.generate(
          rows,
          (_) => List.generate(cols, (_) => const EmptyCell()),
        );

  BoardCell at(int row, int col) => cells[row][col];

  bool isEmpty(int row, int col) => cells[row][col] is EmptyCell;

  /// Row where a newly dropped tile lands in [col]. Returns -1 if column full.
  int landingRow(int col) {
    for (int row = 0; row < rows; row++) {
      if (cells[row][col] is! EmptyCell) return row - 1;
    }
    return rows - 1;
  }

  bool isColumnFull(int col) => landingRow(col) < 0;

  bool get isBoardFull => List.generate(cols, (c) => c).every(isColumnFull);

  /// Place a tile. Returns false if column is full.
  bool placeTile(Tile tile, int col) {
    final row = landingRow(col);
    if (row < 0) return false;
    cells[row][col] = TileCell(tile);
    return true;
  }

  /// Remove cells at positions and return how many were removed.
  void clearCells(List<(int, int)> positions) {
    for (final (r, c) in positions) {
      cells[r][c] = const EmptyCell();
    }
  }

  /// After clearCells: drop tiles down in each column (gravity).
  void applyGravity() {
    for (int col = 0; col < cols; col++) {
      final stack = <BoardCell>[];
      for (int row = rows - 1; row >= 0; row--) {
        if (cells[row][col] is! EmptyCell) stack.add(cells[row][col]);
      }
      for (int row = rows - 1; row >= 0; row--) {
        final idx = rows - 1 - row;
        cells[row][col] = idx < stack.length ? stack[idx] : const EmptyCell();
      }
    }
  }

  /// All unique meld groups currently on the board.
  List<MeldGroup> get meldGroups {
    final seen = <MeldGroup>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        if (cell is MeldPartCell) seen.add(cell.group);
      }
    }
    return seen.toList();
  }

  /// All individual (non-meld) tiles on the board.
  List<Tile> get individualTiles {
    final result = <Tile>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        if (cell is TileCell) result.add(cell.tile);
      }
    }
    return result;
  }

  /// Positions of all cells belonging to [group].
  List<(int, int)> positionsOf(MeldGroup group) {
    final result = <(int, int)>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        if (cell is MeldPartCell && identical(cell.group, group)) {
          result.add((r, c));
        }
      }
    }
    return result;
  }
}
