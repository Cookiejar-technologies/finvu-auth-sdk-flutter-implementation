import 'dart:convert';

import '../api/finvu_host.dart' show IFinvuHost;
import '../api/finvu_native_wrapper.dart';
import '../models.dart';

class FinvuNativeWrapperImpl implements IFinvuNativeWrapper {
  final IFinvuHost _host;
  FinvuNativeWrapperImpl(this._host);

  @override
  Future<void> setEnvironment(Environment env) => _host.setEnvironment(env);

  // ── SNA factor ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> initSNA(InitConfig cfg) => _host.initSNA(cfg);

  @override
  Future<Map<String, dynamic>> startSNA(String snaLink) =>
      _host.startSNA(snaLink);

  @override
  Future<Map<String, dynamic>> initAuth(InitConfig cfg) => initSNA(cfg);

  @override
  Future<Map<String, dynamic>> startAuth(String snaLink) => startSNA(snaLink);

  // ── Device binding factor ───────────────────────────────────────────────
  //
  // The config map is JSON-encoded and handed to the native SDK unchanged,
  // like RN's JSON.stringify(config).

  @override
  Future<Map<String, dynamic>> getDeviceBindingState(
    Map<String, dynamic> config,
  ) => _host.getDeviceBindingState(jsonEncode(config));

  @override
  Future<Map<String, dynamic>> enrollDeviceBinding(
    Map<String, dynamic> config,
  ) => _host.enrollDeviceBinding(jsonEncode(config));

  @override
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    Map<String, dynamic> config,
  ) => _host.signDeviceBindingChallenge(jsonEncode(config));

  @override
  Future<Map<String, dynamic>> getCapabilities() => _host.getCapabilities();

  @override
  Future<void> cleanupAll() => _host.cleanupAll();
}
