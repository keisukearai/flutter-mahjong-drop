import 'dart:math';
import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../game/components/tile_painter.dart';
import '../mahjong/tile.dart';
import 'game_screen.dart';
import 'score_history_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2B1A), Color(0xFF1A3D2B), Color(0xFF2E6B47)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _TitleText(),
              const SizedBox(height: 10),
              const Text(
                '牌を落として面子を作ろう！',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const Spacer(flex: 2),
              const _TilePreviewRow(),
              const SizedBox(height: 8),
              const _MeldArrow(),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _ModeButton(
                      label: '簡 単 モ ー ド',
                      subtitle: '字牌のみ',
                      color: const Color(0xFF1A3A6E),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(mode: GameMode.easy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ModeButton(
                      label: '通 常 モ ー ド',
                      subtitle: '索子2〜8なし',
                      color: const Color(0xFF2B6E1A),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(mode: GameMode.normal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ModeButton(
                      label: '鬼 モ ー ド',
                      subtitle: '全牌登場',
                      color: const Color(0xFF7A1010),
                      isOni: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(mode: GameMode.oni),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _HistoryButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScoreHistoryScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '三人麻雀',
          style: TextStyle(
            color: Color(0xFF80CBC4),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(1, 2))],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '麻雀\nドロップ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1.05,
            shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(2, 4))],
          ),
        ),
      ],
    );
  }
}

class _TilePreviewRow extends StatefulWidget {
  const _TilePreviewRow();
  @override
  State<_TilePreviewRow> createState() => _TilePreviewRowState();
}

class _TilePreviewRowState extends State<_TilePreviewRow> {
  late final List<Tile> _tiles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    const winds = [HonorType.east, HonorType.south, HonorType.west, HonorType.north];
    const dragons = [HonorType.haku, HonorType.hatsu, HonorType.chun];
    _tiles = [
      Tile.number(TileSuit.man, [1, 9][rng.nextInt(2)]),
      Tile.number(TileSuit.sou, rng.nextInt(9) + 1),
      Tile.number(TileSuit.pin, rng.nextInt(9) + 1),
      Tile.honor(winds[rng.nextInt(winds.length)]),
      Tile.honor(dragons[rng.nextInt(dragons.length)]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _tiles.map((t) => _PreviewTile(tile: t)).toList(),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final Tile tile;
  const _PreviewTile({required this.tile});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 6, offset: const Offset(2, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CustomPaint(painter: _TileCanvasPainter(tile)),
      ),
    );
  }
}

class _TileCanvasPainter extends CustomPainter {
  final Tile tile;
  _TileCanvasPainter(this.tile);
  @override
  void paint(Canvas canvas, Size size) =>
      TilePainter.drawTile(canvas, tile, Offset.zero & size);
  @override
  bool shouldRepaint(_TileCanvasPainter old) => old.tile != tile;
}

class _MeldArrow extends StatelessWidget {
  const _MeldArrow();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E6B47),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCFB53B), width: 1.5),
          ),
          child: const Row(children: [
            Text('アンコ', style: TextStyle(color: Color(0xFFEF9A9A), fontSize: 13, fontWeight: FontWeight.bold)),
            Text('（同3枚）', style: TextStyle(color: Colors.white54, fontSize: 11)),
            SizedBox(width: 6),
            Text('ジュンツ', style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13, fontWeight: FontWeight.bold)),
            Text('（連続3枚）', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      ],
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Color(0xFFCFB53B), size: 18),
            SizedBox(width: 8),
            Text(
              'ハイスコア',
              style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isOni;
  const _ModeButton({required this.label, required this.subtitle, required this.color, required this.onTap, this.isOni = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = isOni ? const Color(0xFFFF6B35) : const Color(0xFFCFB53B);
    final gradientColors = isOni
        ? [const Color(0xFFBF3030), const Color(0xFF4A0A0A)]
        : [Color.lerp(color, Colors.white, 0.10)!, Color.lerp(color, Colors.black, 0.25)!];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isOni ? 2.0 : 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
            if (isOni) BoxShadow(color: const Color(0xFFFF4500).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(children: [
          Text(
            label,
            style: TextStyle(
              color: isOni ? const Color(0xFFFFD54F) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: isOni ? const Color(0xFFFFAB91) : Colors.white70, fontSize: 12),
          ),
        ]),
          ),
        ),
      ),
    );
  }
}
