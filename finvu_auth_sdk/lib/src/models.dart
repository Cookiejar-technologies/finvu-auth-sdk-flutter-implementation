// Public enums the app will use
enum Environment { production, development }

// Convenience input DTOs
class InitConfig {
  final String requestId;
  final String? entityId;
  const InitConfig({required this.requestId, this.entityId});
}

// NOTE: There is deliberately no typed response model here (no
// FinvuAuthResult, FinvuStatus, DeviceBindingResult, FinvuCapabilities, etc.).
// Every call in IFinvuHost / IFinvuNativeWrapper returns a plain
// `Map<String, dynamic>` decoded straight from the native Android/iOS SDK's
// own JSON, unfiltered — exactly like the React Native bridge, which hands
// the app whatever JSON.parse(nativeString) produces with no fixed schema.
// A previous version of this file declared success/failure classes with
// fields (statusCode, authType, token, requestId, userId, timestamp) that
// neither native SDK actually returns, while real fields (mcc, mnc,
// httpStatusCode) were dropped into a catch-all `extra` map — inconsistently
// between Android and iOS. Do not reintroduce that pattern; read whatever key
// the native SDK actually documents directly off the returned map instead.
