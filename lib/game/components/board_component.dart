import 'dart:ui';
import 'package:flame/components.dart';
import '../board_state.dart';
import '../win_detector.dart';
import 'tile_painter.dart';
import 'falling_tile_component.dart' show BoardLayout;

class BoardComponent extends Component with HasGameReference {
  final BoardState board;
  WinResult? highlightWin;

  BoardComponent({required this.board});

  @override
  void render(Canvas canvas) {
    final sw = game.size.x;
    final totalW = BoardLayout.cols * BoardLayout.tileW + (BoardLayout.cols - 1) * BoardLayout.gap;
    final startX = (sw - totalW) / 2;
    final boardH = BoardLayout.rows * BoardLayout.tileH + (BoardLayout.rows - 1) * BoardLayout.gap;
    canvas.drawRect(
      Rect.fromLTWH(startX, BoardLayout.boardOffsetY, totalW, boardH),
      Paint()..color = const Color(0xFF1A3D2B),
    );
    _drawEmptyCells(canvas, sw);
    _drawMeldBlocks(canvas, sw);
    _drawIndividualTiles(canvas, sw);
  }

  void _drawEmptyCells(Canvas canvas, double sw) {
    final paint = Paint()..color = const Color(0x1AFFFFFF);
    for (int r = 0; r < BoardLayout.rows; r++) {
      for (int c = 0; c < BoardLayout.cols; c++) {
        if (board.at(r, c) is EmptyCell) {
          final rect = BoardLayout.cellRect(r, c, sw);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)),
            paint,
          );
        }
      }
    }
  }

  void _drawMeldBlocks(Canvas canvas, double sw) {
    final drawn = <MeldGroup>{};
    for (int r = 0; r < BoardLayout.rows; r++) {
      for (int c = 0; c < BoardLayout.cols; c++) {
        final cell = board.at(r, c);
        if (cell is MeldPartCell && cell.index == 0 && !drawn.contains(cell.group)) {
          drawn.add(cell.group);
          final group = cell.group;
          final positions = board.positionsOf(group);
          if (positions.length != 3) continue;

          // Sort positions by (row, col) — works for all shapes
          positions.sort((a, b) {
            final rowCmp = a.$1.compareTo(b.$1);
            return rowCmp != 0 ? rowCmp : a.$2.compareTo(b.$2);
          });

          final rects = positions.map((p) => BoardLayout.cellRect(p.$1, p.$2, sw)).toList();
          final isWin = highlightWin?.melds.any((m) => identical(m, group)) ?? false;
          TilePainter.drawMeldBlock(canvas, group, rects, isWinHighlight: isWin);
        }
      }
    }
  }

  void _drawIndividualTiles(Canvas canvas, double sw) {
    for (int r = 0; r < BoardLayout.rows; r++) {
      for (int c = 0; c < BoardLayout.cols; c++) {
        final cell = board.at(r, c);
        if (cell is TileCell) {
          final rect = BoardLayout.cellRect(r, c, sw);
          final isWinPair = highlightWin?.pairPositions.contains((r, c)) ?? false;
          TilePainter.drawTile(canvas, cell.tile, rect);
          if (isWinPair) {
            // Highlight pair with golden overlay
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(8)),
              Paint()
                ..color = const Color(0x66FFD700)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5,
            );
          }
        }
      }
    }
  }
}
