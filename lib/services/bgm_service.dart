import 'package:just_audio/just_audio.dart';
import '../game/game_controller.dart';

class BgmService {
  BgmService._();
  static final BgmService instance = BgmService._();

  final _player = AudioPlayer();
  GameMode? _currentMode;
  double _currentRate = 1.0;
  int _lastMinFree = 99;
  bool _isMuted = true;

  bool get isMuted => _isMuted;

  static String _assetFor(GameMode mode) => switch (mode) {
        GameMode.easy => 'assets/audio/bgm_easy.wav',
        GameMode.normal => 'assets/audio/bgm_normal.wav',
        GameMode.oni => 'assets/audio/bgm_oni.wav',
      };

  Future<void> play(GameMode mode) async {
    if (_currentMode == mode) return;
    _currentMode = mode;
    _currentRate = 1.0;
    _lastMinFree = 99;
    try {
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.5);
      await _player.setAsset(_assetFor(mode));
      await _player.setSpeed(1.0);
      if (!_isMuted) await _player.play();
    } catch (_) {}
  }

  Future<void> stop() async {
    _currentMode = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_isMuted) return;
    try {
      await _player.play();
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await pause();
    } else if (_currentMode != null) {
      await _player.play();
    }
  }

  // minFree: 0(限界)〜10(余裕) → rate: 1.5x〜1.0x
  // 変化が小さい場合や同値の場合はスキップしてスタッター防止
  Future<void> updateDanger(int minFree) async {
    if (minFree == _lastMinFree) return;
    _lastMinFree = minFree;

    const threshold = 8;
    final targetRate = minFree >= threshold
        ? 1.0
        : 1.0 + (threshold - minFree) / threshold * 0.5;

    if ((targetRate - _currentRate).abs() < 0.03) return;
    _currentRate = targetRate;
    try {
      await _player.setSpeed(targetRate);
    } catch (_) {}
  }
}
