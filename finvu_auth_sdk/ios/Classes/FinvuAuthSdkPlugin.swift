import Flutter
import UIKit
import FinvuAuthenticationSDK

public class FinvuAuthSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    FinvuHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: FinvuHostApiImpl())
  }
}

// MARK: - FinvuHostApi implementation

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
    let mappedEnv: FinvuAuthEnvironment = (env == .production) ? .production : .development

    guard let vc = currentRootViewController() else {
      throw FlutterError(code: "NO_VIEW_CONTROLLER",
                         message: "RootViewController not available",
                         details: nil) as! any Error
    }

    // make sure setup happens on main
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.setup(
        viewController: vc,
        environment: mappedEnv
      )
    }
  }

  func initAuth(config: InitConfig, completion: @escaping (Result<FinvuAuthResult, Error>) -> Void) {
    let dict: [String: Any] = [
      "appId": config.appId ?? "",
      "requestId": config.requestId ?? ""
    ]

    FinvuAuthenticationNativeWrapper.shared.initAuth(config: dict) { result in
      switch result {
      case .success(let payload):
        completion(.success(self.successResult(from: payload)))
      case .failure(let err):
        completion(.success(self.failureResult(from: err)))
      }
    }
  }

  func startAuth(phoneNumber: String, completion: @escaping (Result<FinvuAuthResult, Error>) -> Void) {
    FinvuAuthenticationNativeWrapper.shared.startAuth(phoneNumber: phoneNumber) { result in
      switch result {
      case .success(let payload):
        completion(.success(self.successResult(from: payload)))
      case .failure(let err):
        completion(.success(self.failureResult(from: err)))
      }
    }
  }

  func verifyOtp(request: VerifyOtpReq, completion: @escaping (Result<FinvuAuthResult, Error>) -> Void) {
    FinvuAuthenticationNativeWrapper.shared.verifyOtp(
      phoneNumber: request.phoneNumber ?? "",
      otp: request.otp ?? ""
    ) { result in
      switch result {
      case .success(let payload):
        completion(.success(self.successResult(from: payload)))
      case .failure(let err):
        completion(.success(self.failureResult(from: err)))
      }
    }
  }

  func cleanupAll() throws {
    DispatchQueue.main.async {
      FinvuAuthenticationNativeWrapper.shared.cleanupAll()
    }
  }

  // MARK: - Helpers to adapt native wrapper <-> Pigeon types

  private func successResult(from dict: [String: Any]) -> FinvuAuthResult {
    let success = FinvuAuthSuccessResponse(
      token: dict["token"] as? String,
      authType: dict["authType"] as? String,
      extra: dict  // include everything for flexibility
    )
    return FinvuAuthResult(status: .success, data: success, error: nil)
  }

  private func failureResult(from err: FinvuAuthException) -> FinvuAuthResult {
    let error = FinvuAuthFailureError(
      errorCode: err.errorCode,
      errorMessage: err.errorMessage,
      details: [:]
    )
    return FinvuAuthResult(status: .failure, data: nil, error: error)
  }
}
