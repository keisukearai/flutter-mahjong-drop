import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../game/score_repository.dart';

class ScoreHistoryScreen extends StatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _modes = [GameMode.easy, GameMode.normal, GameMode.oni];
  final _modeLabels = ['簡単', '通常', '鬼'];
  final _scores = <GameMode, List<ScoreEntry>>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _modes.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    for (final mode in _modes) {
      _scores[mode] = await ScoreRepository.loadTop(mode);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B1A),
        foregroundColor: const Color(0xFFFFD54F),
        title: const Text(
          'ハイスコア',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFCFB53B),
          labelColor: const Color(0xFFFFD54F),
          unselectedLabelColor: Colors.white38,
          tabs: _modeLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFCFB53B)))
          : TabBarView(
              controller: _tab,
              children: _modes
                  .map((mode) => _ScoreList(entries: _scores[mode] ?? []))
                  .toList(),
            ),
    );
  }
}

class _ScoreList extends StatelessWidget {
  final List<ScoreEntry> entries;
  const _ScoreList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'まだ記録がありません',
          style: TextStyle(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      itemCount: entries.length,
      itemBuilder: (context, i) => _ScoreRow(rank: i + 1, entry: entries[i]),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final ScoreEntry entry;
  const _ScoreRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Colors.white38,
    };

    final dateStr =
        '${entry.date.month}/${entry.date.day}  ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';

    final scoreStr = entry.score
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3D2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.6) : Colors.white12,
          width: rank <= 3 ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontSize: rank <= 3 ? 18 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scoreStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
