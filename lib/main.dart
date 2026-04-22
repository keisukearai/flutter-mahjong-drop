import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/title_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MahjongDropApp());
}

class MahjongDropApp extends StatelessWidget {
  const MahjongDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '麻雀ドロップ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3D2B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}
