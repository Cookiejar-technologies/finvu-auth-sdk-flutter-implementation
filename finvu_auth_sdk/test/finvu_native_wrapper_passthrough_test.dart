import 'dart:convert';

import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records exactly what the native wrapper hands to the host, and returns a
/// canned native response, so the tests can check nothing is changed either way.
class _RecordingHost implements IFinvuHost {
  final calls = <String, String>{};
  Map<String, dynamic> response = const {};

  @override
  Future<Map<String, dynamic>> getDeviceBindingState(String configJson) async {
    calls['getDeviceBindingState'] = configJson;
    return response;
  }

  @override
  Future<Map<String, dynamic>> enrollDeviceBinding(String configJson) async {
    calls['enrollDeviceBinding'] = configJson;
    return response;
  }

  @override
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    String configJson,
  ) async {
    calls['signDeviceBindingChallenge'] = configJson;
    return response;
  }

  @override
  Future<Map<String, dynamic>> getCapabilities() async => response;

  @override
  Future<void> setEnvironment(Environment env) async {}

  @override
  Future<Map<String, dynamic>> initSNA(InitConfig cfg) async => response;

  @override
  Future<Map<String, dynamic>> startSNA(String snaLink) async => response;

  @override
  Future<void> cleanupAll() async {}
}

void main() {
  late _RecordingHost host;
  late IFinvuNativeWrapper wrapper;

  setUp(() {
    host = _RecordingHost();
    wrapper = FinvuAuthSdk.nativeWrapper(host);
  });

  test(
    'sign config reaches native unchanged, including arrays, nulls and unknown keys',
    () async {
      final config = <String, dynamic>{
        'allowedKeyIds': ['k1', 'k2'],
        'challenge': 'abc',
        'requestId': null,
        'someFutureKey': {'nested': 1},
      };
      await wrapper.signDeviceBindingChallenge(config);
      expect(jsonDecode(host.calls['signDeviceBindingChallenge']!), config);
    },
  );

  test('enroll and state configs reach native unchanged', () async {
    final enroll = <String, dynamic>{
      'attestationChallenge': 'n',
      'promptTitle': 'T',
    };
    final state = <String, dynamic>{'keyId': 'k1'};
    await wrapper.enrollDeviceBinding(enroll);
    await wrapper.getDeviceBindingState(state);
    expect(jsonDecode(host.calls['enrollDeviceBinding']!), enroll);
    expect(jsonDecode(host.calls['getDeviceBindingState']!), state);
  });

  test(
    'an empty config is forwarded as an empty object, not dropped',
    () async {
      await wrapper.getDeviceBindingState({});
      expect(host.calls['getDeviceBindingState'], '{}');
    },
  );

  test('native responses come back unchanged, success and failure', () async {
    host.response = {
      'status': 'SUCCESS',
      'keyId': 'k1',
      'extra': [1, 2],
    };
    expect(await wrapper.enrollDeviceBinding({}), host.response);

    host.response = {
      'status': 'FAILURE',
      'errorCode': 'X',
      'errorMessage': 'y',
    };
    expect(await wrapper.signDeviceBindingChallenge({}), host.response);
    expect(await wrapper.getCapabilities(), host.response);
  });
}
