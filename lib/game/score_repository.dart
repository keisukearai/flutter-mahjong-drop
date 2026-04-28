import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_controller.dart';

class ScoreEntry {
  final int score;
  final GameMode mode;
  final DateTime date;

  const ScoreEntry({required this.score, required this.mode, required this.date});

  Map<String, dynamic> toJson() => {
        'score': score,
        'mode': mode.name,
        'date': date.toIso8601String(),
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
        score: json['score'] as int,
        mode: GameMode.values.firstWhere((m) => m.name == json['mode']),
        date: DateTime.parse(json['date'] as String),
      );
}

class ScoreRepository {
  static const _keyPrefix = 'top_scores_';
  static const _maxEntries = 10;

  static String _key(GameMode mode) => '$_keyPrefix${mode.name}';

  static Future<List<ScoreEntry>> loadTop(GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key(mode)) ?? [];
      final entries = <ScoreEntry>[];
      for (final s in raw) {
        try {
          entries.add(ScoreEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
        } catch (_) {}
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(int score, GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await loadTop(mode);
      entries.add(ScoreEntry(score: score, mode: mode, date: DateTime.now()));
      entries.sort((a, b) => b.score.compareTo(a.score));
      final top = entries.take(_maxEntries).toList();
      await prefs.setStringList(
        _key(mode),
        top.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
  }
}
