import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../mahjong/tile.dart';
import '../game/components/tile_painter.dart';

class WinOverlay extends StatefulWidget {
  final GameController controller;
  const WinOverlay({super.key, required this.controller});

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final win = widget.controller.pendingWin;
    final ws = widget.controller.pendingScore;
    if (win == null || ws == null) return const SizedBox.shrink();

    final combo = widget.controller.combo;
    final comboBonus = 1.0 + combo * 0.5;
    final totalPts = (ws.points * comboBonus).round();
    final levelColor = _levelColor(ws.levelName);

    return ColoredBox(
      color: const Color(0xFF0D1228),
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2B8F),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '✦ 和了！ ✦',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ws.levelName,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: ws.isYakuman ? 36 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (ws.han > 0 && !ws.isYakuman)
                  Text(
                    '${ws.han}翻',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                if (ws.yakuList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...ws.yakuList.map((y) => Text(
                    y,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ],
                const Divider(color: Colors.white24, height: 16),
                ...win.melds.map((g) => _MeldRow(
                  tiles: g.meld.tiles,
                  label: g.meld.isTriplet ? 'アンコ' : 'ジュンツ',
                  isTriplet: g.meld.isTriplet,
                )),
                _MeldRow(
                  tiles: [win.pairTile, win.pairTile],
                  label: '雀頭',
                  isTriplet: false,
                ),
                const Divider(color: Colors.white24, height: 16),
                if (combo > 0)
                  Text(
                    '×${comboBonus.toStringAsFixed(1)} コンボ',
                    style: const TextStyle(
                      color: Color(0xFFFFCC02),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  '+${_fmt(totalPts)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: widget.controller.confirmWin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '再　開',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    return switch (level) {
      'ダブル役満' => const Color(0xFFFF4081),
      '役満'     => const Color(0xFFFFD700),
      '三倍満'   => const Color(0xFFEF5350),
      '倍満'     => const Color(0xFFFF7043),
      '跳満'     => const Color(0xFFFFCA28),
      '満貫'     => const Color(0xFF66BB6A),
      _          => const Color(0xFF90CAF9),
    };
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── 面子行: ラベル + ミニ牌 ────────────────────────────────────────────
class _MeldRow extends StatelessWidget {
  final List<Tile> tiles;
  final String label;
  final bool isTriplet;
  const _MeldRow({required this.tiles, required this.label, required this.isTriplet});

  @override
  Widget build(BuildContext context) {
    final color = isTriplet ? const Color(0xFFEF9A9A) : const Color(0xFF90CAF9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isTriplet ? const Color(0x33EF9A9A) : const Color(0x3390CAF9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Row(
            children: tiles.map((t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _MiniTile(tile: t),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── ミニ牌ウィジェット ────────────────────────────────────────────────
class _MiniTile extends StatelessWidget {
  final Tile tile;
  const _MiniTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 36,
      child: CustomPaint(painter: _MiniTilePainter(tile)),
    );
  }
}

class _MiniTilePainter extends CustomPainter {
  final Tile tile;
  _MiniTilePainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    TilePainter.drawTile(canvas, tile, Offset.zero & size);
  }

  @override
  bool shouldRepaint(_MiniTilePainter old) => old.tile != tile;
}
