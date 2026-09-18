// Widget test for the example app's home screen.

import 'package:finvu_auth_sdk_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home page shows both demo entry points', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinvuDemoApp());

    expect(find.text('Choose a flow'), findsOneWidget);
    expect(find.text('Load WebView'), findsOneWidget);
    expect(find.text('Load Native View'), findsOneWidget);
  });
}
