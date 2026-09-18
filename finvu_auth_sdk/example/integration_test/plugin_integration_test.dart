// Integration test for the finvu_authentication_sdk plugin.
//
// Runs inside a full Flutter application, so it exercises the real Pigeon
// channel and the host-side plugin registration, unlike a plain unit test.
//
// See https://flutter.dev/to/integration-testing

import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setEnvironment reaches the native plugin', (
    WidgetTester tester,
  ) async {
    final host = FinvuAuthSdk.host();

    // Completes only if the plugin is registered on the host platform and the
    // Pigeon channel is wired up correctly.
    await host.setEnvironment(Environment.development);

    await host.cleanupAll();
  });

  testWidgets('initSNA with an empty requestId returns a result', (
    WidgetTester tester,
  ) async {
    final host = FinvuAuthSdk.host();
    await host.setEnvironment(Environment.development);

    final result = await host.initSNA(const InitConfig(requestId: ''));

    // The bridge hands back exactly what the native SDK returned, decoded
    // into a map — no fixed schema. The native SDK decides success vs
    // failure; we only assert the bridge returns well-formed JSON (a map)
    // instead of throwing, and that a failure carries the shared error shape.
    expect(result, isA<Map<String, dynamic>>());
    if (result['error'] != null) {
      expect(result['error'], isA<Map>());
    }

    await host.cleanupAll();
  });
}
