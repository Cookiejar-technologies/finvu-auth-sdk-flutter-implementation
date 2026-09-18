import 'dart:convert';

import '../api/finvu_host.dart';
import '../models.dart' as pub;
import '../generated/native_finvu_auth_wrapper.g.dart' as pig;
import 'mapper.dart';

/// Decodes whatever JSON string the native plugin returned into a plain map,
/// blindly. This is the native Android/iOS SDK's own JSON — not a Pigeon
/// schema — so no key is checked or renamed here.
Map<String, dynamic> _decode(String raw) {
  final decoded = jsonDecode(raw);
  return decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{'value': decoded};
}

class FinvuHostImpl implements IFinvuHost {
  final pig.FinvuHostApi _api = pig.FinvuHostApi();

  @override
  Future<void> setEnvironment(pub.Environment env) => _api.setUp(toPigEnv(env));

  // ── SNA factor ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> initSNA(pub.InitConfig cfg) async =>
      _decode(await _api.initSNA(toPigInit(cfg)));

  @override
  Future<Map<String, dynamic>> startSNA(String snaLink) async =>
      _decode(await _api.startSNA(snaLink));

  // ── Device binding factor ───────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getDeviceBindingState(
    pub.DeviceBindingConfig cfg,
  ) async => _decode(await _api.getDeviceBindingState(toPigDeviceBinding(cfg)));

  @override
  Future<Map<String, dynamic>> enrollDeviceBinding(
    pub.DeviceBindingEnrollConfig cfg,
  ) async => _decode(await _api.enrollDeviceBinding(toPigDeviceBinding(cfg)));

  @override
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    pub.DeviceBindingSignConfig cfg,
  ) async =>
      _decode(await _api.signDeviceBindingChallenge(toPigDeviceBinding(cfg)));

  @override
  Future<Map<String, dynamic>> getCapabilities() async =>
      _decode(await _api.getCapabilities());

  @override
  Future<void> cleanupAll() => _api.cleanupAll();
}
