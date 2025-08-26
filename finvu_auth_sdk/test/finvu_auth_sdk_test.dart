import 'package:flutter_test/flutter_test.dart';
import 'package:finvu_auth_sdk/finvu_auth_sdk.dart';
import 'package:finvu_auth_sdk/finvu_auth_sdk_platform_interface.dart';
import 'package:finvu_auth_sdk/finvu_auth_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFinvuAuthSdkPlatform
    with MockPlatformInterfaceMixin
    implements FinvuAuthSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FinvuAuthSdkPlatform initialPlatform = FinvuAuthSdkPlatform.instance;

  test('$MethodChannelFinvuAuthSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFinvuAuthSdk>());
  });

  test('getPlatformVersion', () async {
    FinvuAuthSdk finvuAuthSdkPlugin = FinvuAuthSdk();
    MockFinvuAuthSdkPlatform fakePlatform = MockFinvuAuthSdkPlatform();
    FinvuAuthSdkPlatform.instance = fakePlatform;

    expect(await finvuAuthSdkPlugin.getPlatformVersion(), '42');
  });
}
