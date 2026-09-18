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
// passthrough on success. The only shape this plugin imposes is the small
// `{"error": {...}}` envelope on failure — copied from that same RN module,
// since a thrown FinvuAuthException has no JSON form of its own and
// something has to serialize it. That keeps RN, Android and iOS all failing
// the same way.

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

    FinvuAuthenticationNativeWrapper.shared.initSNA(config: dict) { result in
      completion(.success(Self.jsonString(from: result)))
    }
  }

  func startSNA(snaLink: String, completion: @escaping (Result<String, Error>) -> Void) {
    FinvuAuthenticationNativeWrapper.shared.startSNA(snaUrl: snaLink) { result in
      completion(.success(Self.jsonString(from: result)))
    }
  }

  // MARK: - Device binding

  func getDeviceBindingState(
    config: DeviceBindingConfig,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    FinvuAuthenticationNativeWrapper.shared
      .getDeviceBindingState(config: config.toDictionary()) { result in
        completion(.success(Self.jsonString(from: result)))
      }
  }

  func enrollDeviceBinding(
    config: DeviceBindingConfig,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    FinvuAuthenticationNativeWrapper.shared
      .enrollDeviceBinding(config: config.toDictionary()) { result in
        completion(.success(Self.jsonString(from: result)))
      }
  }

  func signDeviceBindingChallenge(
    config: DeviceBindingConfig,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    // The biometric prompt must be raised from the main thread.
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared
        .signDeviceBindingChallenge(config: config.toDictionary()) { result in
          completion(.success(Self.jsonString(from: result)))
        }
    }
  }

  func getCapabilities() throws -> String {
    Self.jsonString(fromDict: FinvuAuthenticationNativeWrapper.shared.getCapabilities())
  }

  func cleanupAll() throws {
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.cleanupAll()
    }
  }

  // MARK: - Helpers

  /// Serializes a native result to the string the Dart side gets: the native
  /// dictionary verbatim on success, or the shared error envelope on failure
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

  /// Mirrors `FinvuAuthSdkRnModule.errorJsonString` exactly, so RN, Android and
  /// iOS all report failures in the same shape.
  private static func errorJsonString(status: String = "FAILURE", code: String, message: String) -> String {
    return jsonString(fromDict: [
      "error": [
        "status": status,
        "errorCode": code,
        "errorMessage": message,
      ]
    ])
  }
}

// MARK: - Pigeon config → native dictionary

private extension DeviceBindingConfig {
  /// Only non-empty values are forwarded, so the native side applies its own defaults.
  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [:]
    if let userId, !userId.isEmpty { dict["userId"] = userId }
    if let entityId, !entityId.isEmpty { dict["entityId"] = entityId }
    if let challenge, !challenge.isEmpty { dict["challenge"] = challenge }
    if let attestationChallenge, !attestationChallenge.isEmpty {
      dict["attestationChallenge"] = attestationChallenge
    }
    if let promptTitle, !promptTitle.isEmpty { dict["promptTitle"] = promptTitle }
    if let promptSubtitle, !promptSubtitle.isEmpty {
      dict["promptSubtitle"] = promptSubtitle
    }
    return dict
  }
}
