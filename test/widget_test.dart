import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong_drop_v2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MahjongDropApp());
    expect(find.text('は じ め る'), findsOneWidget);
  });
}
