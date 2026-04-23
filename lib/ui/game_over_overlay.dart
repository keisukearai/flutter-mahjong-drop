import 'package:flutter/material.dart';
import '../game/game_controller.dart';

class GameOverOverlay extends StatelessWidget {
  final GameController controller;
  const GameOverOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER',
                style: TextStyle(color: Color(0xFFEF5350), fontSize: 38,
                    fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 24),
            const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
            Text(
              _fmt(controller.score),
              style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900),
            ),
            Text('LV ${controller.level}   ×${controller.combo} コンボ',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 40),
            _Btn(label: 'もう一度', color: const Color(0xFF8B1A2B), onTap: controller.restart),
            const SizedBox(height: 12),
            _Btn(label: 'タイトルへ', color: const Color(0xFF2C2A22),
                onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200, height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFB53B), width: 1.5),
        ),
        child: Center(child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
