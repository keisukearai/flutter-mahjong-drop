import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong_drop_v2/mahjong/tile.dart';
import 'package:mahjong_drop_v2/game/components/tile_painter.dart';

Future<void> _loadCjkFont() async {
  const path = '/Library/Fonts/Arial Unicode.ttf';
  final file = File(path);
  if (!file.existsSync()) return;
  final data = file.readAsBytesSync();
  final loader = FontLoader('ArialUnicode')
    ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(data))));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadCjkFont();
    TilePainter.fontFamily = 'ArialUnicode';
  });

  testWidgets('tile sheet', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(700, 450);

    final rows = [
      (
        'man',
        List.generate(9, (i) => Tile.number(TileSuit.man, i + 1)),
      ),
      (
        'pin',
        List.generate(9, (i) => Tile.number(TileSuit.pin, i + 1)),
      ),
      (
        'sou',
        List.generate(9, (i) => Tile.number(TileSuit.sou, i + 1)),
      ),
      (
        'honor',
        HonorType.values.map((h) => Tile.honor(h)).toList(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF4CAF50),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows.map((row) {
                final (label, tiles) = row;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...tiles.map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 56,
                            height: 80,
                            child: CustomPaint(painter: _TilePainter(tile)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/all_tiles.png'),
    );
  });
}

class _TilePainter extends CustomPainter {
  final Tile tile;
  const _TilePainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    TilePainter.drawTile(
      canvas,
      tile,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
