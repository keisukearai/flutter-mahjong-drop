import 'package:flutter/material.dart';
import '../mahjong/tile.dart';
import '../game/components/tile_painter.dart';

class TilePreviewScreen extends StatelessWidget {
  const TilePreviewScreen({super.key});

  static List<Tile> get _allTiles => [
        ...List.generate(9, (i) => Tile.number(TileSuit.man, i + 1)),
        ...List.generate(9, (i) => Tile.number(TileSuit.pin, i + 1)),
        ...List.generate(9, (i) => Tile.number(TileSuit.sou, i + 1)),
        ...HonorType.values.map((h) => Tile.honor(h)),
      ];

  @override
  Widget build(BuildContext context) {
    final tiles = _allTiles;
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A2A),
      appBar: AppBar(
        title: const Text('牌一覧プレビュー'),
        backgroundColor: const Color(0xFF0D2518),
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          childAspectRatio: 0.72,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return Column(
            children: [
              Expanded(
                child: CustomPaint(painter: _SingleTilePainter(tile)),
              ),
              const SizedBox(height: 2),
              Text(
                tile.isHonor ? tile.label : '${tile.number}${tile.suitStr}',
                style: const TextStyle(color: Colors.white70, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SingleTilePainter extends CustomPainter {
  final Tile tile;
  const _SingleTilePainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    TilePainter.drawTile(canvas, tile, Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(_SingleTilePainter old) => old.tile != tile;
}
