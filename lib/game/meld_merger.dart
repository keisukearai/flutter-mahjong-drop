import '../mahjong/meld.dart';
import 'board_state.dart';

/// Scans the board and merges any 3-tile groups that form valid melds.
/// Returns all newly formed MeldGroups.
class MeldMerger {
  static List<MeldGroup> mergeAll(BoardState board) {
    final formed = <MeldGroup>[];
    bool changed = true;
    while (changed) {
      changed = false;
      // Horizontal scan
      for (int r = 0; r < BoardState.rows; r++) {
        for (int c = 0; c <= BoardState.cols - 3; c++) {
          final g = _tryHorizontal(board, r, c);
          if (g != null) {
            formed.add(g);
            changed = true;
          }
        }
      }
      // Vertical scan (triplet only — same tile stacked)
      for (int c = 0; c < BoardState.cols; c++) {
        for (int r = 0; r <= BoardState.rows - 3; r++) {
          final g = _tryVertical(board, r, c);
          if (g != null) {
            formed.add(g);
            changed = true;
          }
        }
      }
    }
    return formed;
  }

  static MeldGroup? _tryHorizontal(BoardState board, int row, int col) {
    final a = board.at(row, col);
    final b = board.at(row, col + 1);
    final c = board.at(row, col + 2);
    if (a is! TileCell || b is! TileCell || c is! TileCell) return null;

    final meld = Meld.tryForm(a.tile, b.tile, c.tile);
    if (meld == null) return null;

    final group = MeldGroup(meld, isHorizontal: true);
    board.cells[row][col] = MeldPartCell(group, 0);
    board.cells[row][col + 1] = MeldPartCell(group, 1);
    board.cells[row][col + 2] = MeldPartCell(group, 2);
    return group;
  }

  static MeldGroup? _tryVertical(BoardState board, int row, int col) {
    final a = board.at(row, col);
    final b = board.at(row + 1, col);
    final c = board.at(row + 2, col);
    if (a is! TileCell || b is! TileCell || c is! TileCell) return null;

    // Vertical only allows triplets (same tile)
    if (a.tile != b.tile || b.tile != c.tile) return null;
    final meld = Meld(MeldType.triplet, [a.tile, b.tile, c.tile]);

    final group = MeldGroup(meld, isHorizontal: false);
    board.cells[row][col] = MeldPartCell(group, 0);
    board.cells[row + 1][col] = MeldPartCell(group, 1);
    board.cells[row + 2][col] = MeldPartCell(group, 2);
    return group;
  }
}
