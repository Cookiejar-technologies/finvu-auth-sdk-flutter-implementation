import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finvu_auth_sdk/finvu_auth_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFinvuAuthSdk platform = MethodChannelFinvuAuthSdk();
  const MethodChannel channel = MethodChannel('finvu_auth_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
