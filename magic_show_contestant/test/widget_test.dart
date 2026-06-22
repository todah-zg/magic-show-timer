import 'package:flutter_test/flutter_test.dart';
import 'package:magic_show_contestant/main.dart';

void main() {
  testWidgets('app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MagicShowApp());
    // MagicShowApp renders a loading spinner while SharedPreferences loads.
    expect(find.byType(MagicShowApp), findsOneWidget);
  });
}
