import '../models.dart';

/// Thin seam over the Pigeon channel. Both factors funnel through here so the
/// wrappers stay free of platform-channel detail.
///
/// Every call hands back exactly what the native Android/iOS SDK returned,
/// JSON-decoded and otherwise untouched — no field allow-list, no reshaping.
/// This mirrors the React Native bridge, which does the same (`JSON.parse` on
/// whatever the native module resolves with) rather than mapping onto a fixed
/// schema. On failure the map carries a single `error` key
/// (`{"status", "errorCode", "errorMessage"}`), matching RN's own error shape.
abstract class IFinvuHost {
  Future<void> setEnvironment(Environment env);

  // SNA factor.
  Future<Map<String, dynamic>> initSNA(InitConfig cfg);
  Future<Map<String, dynamic>> startSNA(String snaLink);

  // Device binding factor.
  Future<Map<String, dynamic>> getDeviceBindingState(DeviceBindingConfig cfg);
  Future<Map<String, dynamic>> enrollDeviceBinding(
    DeviceBindingEnrollConfig cfg,
  );
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    DeviceBindingSignConfig cfg,
  );

  Future<Map<String, dynamic>> getCapabilities();

  Future<void> cleanupAll();
}
