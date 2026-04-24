import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/game_controller.dart';
import '../game/mahjong_game.dart';
import 'win_overlay.dart';
import 'game_over_overlay.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, this.mode = GameMode.normal});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _ctrl;
  late final MahjongGame _game;

  @override
  void initState() {
    super.initState();
    _ctrl = GameController(mode: widget.mode);
    _game = MahjongGame(_ctrl);
    _ctrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_rebuild);
    _ctrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _confirmBack(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0D0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFCFB53B), width: 1.5),
        ),
        title: const Text('トップに戻る',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('ゲームを終了してトップに戻りますか？',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFFCFB53B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB53B),
              foregroundColor: const Color(0xFF1A0808),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('戻る', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget(game: _game),
            if (_ctrl.status == GameStatus.playing)
              Positioned(
                top: 6,
                right: 50,
                child: _PauseButton(
                  isPaused: _ctrl.isPaused,
                  onTap: _ctrl.togglePause,
                ),
              ),
            Positioned(
              top: 6,
              right: 8,
              child: _HomeButton(onTap: () => _confirmBack(context)),
            ),
            if (_ctrl.status == GameStatus.winAnimation)
              WinOverlay(controller: _ctrl),
            if (_ctrl.status == GameStatus.gameOver)
              GameOverOverlay(controller: _ctrl),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onTap;
  const _PauseButton({required this.isPaused, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xCC1A237E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1),
        ),
        child: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xCC1A237E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1),
        ),
        child: const Icon(Icons.home, color: Colors.white70, size: 20),
      ),
    );
  }
}
