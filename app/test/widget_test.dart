import 'package:flutter_test/flutter_test.dart';
import 'package:lowkey_app/main.dart';

void main() {
  testWidgets('App starts with username screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LowkeyApp(hasUsername: false));
    await tester.pumpAndSettle();

    // Username screen should show 'lowkey' title and 'Get Started' button
    expect(find.text('lowkey'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
