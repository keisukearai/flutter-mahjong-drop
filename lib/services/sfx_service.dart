import 'package:audioplayers/audioplayers.dart';

class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  AudioPlayer? _gameOverPlayer;

  DateTime? _lastMeld;

  Future<void> playWin() => _playOnce('audio/sfx_win.wav');
  Future<void> playTenpai() => _playOnce('audio/sfx_tenpai.wav');

  Future<void> playMeld() {
    final now = DateTime.now();
    if (_lastMeld != null && now.difference(_lastMeld!) < const Duration(milliseconds: 350)) {
      return Future.value();
    }
    _lastMeld = now;
    return _playOnce('audio/sfx_meld.wav');
  }

  Future<void> playGameOver() async {
    _gameOverPlayer = AudioPlayer();
    await _gameOverPlayer!.setReleaseMode(ReleaseMode.loop);
    await _gameOverPlayer!.setVolume(0.9);
    await _gameOverPlayer!.play(AssetSource('audio/sfx_gameover.wav'));
  }

  Future<void> stopGameOver() async {
    await _gameOverPlayer?.stop();
    await _gameOverPlayer?.dispose();
    _gameOverPlayer = null;
  }

  Future<void> _playOnce(String asset) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.release);
    await player.setVolume(0.9);
    await player.play(AssetSource(asset));
    player.onPlayerComplete.listen((_) => player.dispose());
  }
}
