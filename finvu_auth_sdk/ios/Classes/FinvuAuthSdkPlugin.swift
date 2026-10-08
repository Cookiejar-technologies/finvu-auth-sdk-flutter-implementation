import Flutter
import UIKit
import FinvuAuthenticationSDK

public class FinvuAuthSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    FinvuHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: FinvuHostApiImpl())
  }
}

// MARK: - FinvuHostApi implementation
//
// Every method below hands back exactly the JSON the native
// FinvuAuthenticationSDK produced, serialized as a string — no field
// allow-list, no reshaping. This mirrors the React Native module
// (`FinvuAuthSdkRnModule.swift`), which does the same JSONSerialization
// passthrough on success. On failure it returns the same flat
// `{"status", "errorCode", "errorMessage"}` object the native SDK and the RN
// module use, since a thrown FinvuAuthException has no JSON form of its own
// and something has to serialize it. That keeps RN, Flutter, Android and iOS
// all failing the same way.

final class FinvuHostApiImpl: FinvuHostApi {

  // Resolve a view controller safely on iOS 13+
  private func currentRootViewController() -> UIViewController? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
  }

  func setUp(env: Environment) throws {
    let mappedEnv: FinvuAuthenticationSDK.FinvuAuthEnvironment = (env == .production) ? .production : .development

    guard let vc = currentRootViewController() else {
      // FlutterError does not conform to Swift's Error protocol, so it cannot be
      // thrown here. Pigeon generates PigeonError for exactly this purpose.
      throw PigeonError(code: "NO_VIEW_CONTROLLER",
                        message: "RootViewController not available",
                        details: nil)
    }

    // make sure setup happens on main
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.setup(
        viewController: vc,
        environment: mappedEnv
      )
    }
  }

  func initSNA(config: InitConfig, completion: @escaping (Result<String, Error>) -> Void) {
    let dict: [String: Any] = [
      "requestId": config.requestId ?? "",
      "entityId": config.entityId ?? ""
    ]

    FinvuAuthenticationNativeWrapper.shared.initAuth(config: dict) { result in
      completion(.success(Self.jsonString(from: result)))
    }
  }

  func startSNA(snaLink: String, completion: @escaping (Result<String, Error>) -> Void) {
    FinvuAuthenticationNativeWrapper.shared.startAuth(snaUrl: snaLink) { result in
      completion(.success(Self.jsonString(from: result)))
    }
  }

  // MARK: - Device binding factor

  /// Reports whether `keyId` from a previous enroll is still usable. Local only,
  /// so it may be called before `initSNA`.
  func getDeviceBindingState(configJson: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let config = Self.parseConfig(configJson, errorCode: "DEVICE_BINDING_STATE_ERROR", completion: completion) else { return }
    FinvuAuthenticationNativeWrapper.shared.getDeviceBindingState(config: config) { result in
      completion(.success(Self.jsonString(from: result)))
    }
  }

  /// Prompts for the device lock, then creates a fresh key pair and returns its
  /// keyId and public key. The prompt must be raised from the main thread.
  func enrollDeviceBinding(configJson: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let config = Self.parseConfig(configJson, errorCode: "DEVICE_BINDING_ENROLL_ERROR", completion: completion) else { return }
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.enrollDeviceBinding(config: config) { result in
        completion(.success(Self.jsonString(from: result)))
      }
    }
  }

  /// Signs a server-issued challenge after a device-lock prompt.
  func signDeviceBindingChallenge(configJson: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let config = Self.parseConfig(configJson, errorCode: "DEVICE_BINDING_SIGN_ERROR", completion: completion) else { return }
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.signDeviceBindingChallenge(config: config) { result in
        completion(.success(Self.jsonString(from: result)))
      }
    }
  }

  /// Describes what this native SDK build supports.
  func getCapabilities() throws -> String {
    return Self.jsonString(fromDict: FinvuAuthenticationNativeWrapper.shared.getCapabilities())
  }

  func cleanupAll() throws {
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.cleanupAll()
    }
  }

  // MARK: - Helpers

  /// Parses the call's JSON config, reporting a bad config to Dart as a failure.
  private static func parseConfig(_ configJson: String,
                                  errorCode: String,
                                  completion: @escaping (Result<String, Error>) -> Void) -> [String: Any]? {
    guard let data = configJson.data(using: .utf8),
          let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      completion(.success(errorJsonString(code: errorCode, message: "Invalid config JSON")))
      return nil
    }
    return config
  }

  /// Serializes a native result to the string the Dart side gets: the native
  /// dictionary verbatim on success, or the flat error object on failure
  /// (a thrown FinvuAuthException has no JSON form of its own).
  private static func jsonString(from result: Result<[String: Any], FinvuAuthException>) -> String {
    switch result {
    case .success(let dict):
      return jsonString(fromDict: dict)
    case .failure(let err):
      return errorJsonString(status: err.status, code: err.errorCode ?? "UNKNOWN_ERROR", message: err.errorMessage)
    }
  }

  private static func jsonString(fromDict dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
          let jsonString = String(data: data, encoding: .utf8) else {
      return "{}"
    }
    return jsonString
  }

  /// Mirrors `FinvuAuthSdkRnModule.errorJsonString` exactly: the same flat
  /// `{status, errorCode, errorMessage}` shape the native SDK returns.
  private static func errorJsonString(status: String = "FAILURE", code: String, message: String) -> String {
    return jsonString(fromDict: [
      "status": status,
      "errorCode": code,
      "errorMessage": message,
    ])
  }
}
