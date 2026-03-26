# Finvu Auth SDK (Flutter) — documentation index

This folder contains **module-by-module** documentation for the `finvu_auth_sdk` package (`finvu_auth_sdk_flutter` on pub).

| Document | What it covers |
|----------|----------------|
| [module-flutter-lib.md](./module-flutter-lib.md) | Dart `lib/` — public API, implementations, factory |
| [module-android.md](./module-android.md) | Android Gradle plugin + Kotlin bridge to native AAR |
| [module-ios.md](./module-ios.md) | iOS CocoaPods plugin + Swift bridge to native SDK |
| [module-pigeon.md](./module-pigeon.md) | Pigeon contract, codegen, how to change the API safely |
| [module-example-app.md](./module-example-app.md) | `example/` app — WebView vs native flows, local testing |
| [feature-webview-js-bridge.md](./feature-webview-js-bridge.md) | WebView + `finvu_authentication_bridge` feature |
| [feature-native-auth-flow.md](./feature-native-auth-flow.md) | Native Flutter UI auth flow feature |
| [native-sdks-android-ios.md](./native-sdks-android-ios.md) | **External** Android/iOS authentication SDKs (AAR + Pod), submodule concepts (core / client / internal / sanauth) |
| [security.md](./security.md) | What this repo does vs what native SDKs must do; WebView/JS bridge risks |
| [release-and-credentials.md](./release-and-credentials.md) | Versioning, Maven GitHub Packages, iOS Pod git tag, `pub publish` |
| [onboarding-new-developer.md](./onboarding-new-developer.md) | End-to-end setup: PAT, GitHub username, running example, publishing |

**Repository scope:** This repo is the **Flutter plugin** only. There is **no React Native** package in this workspace; RN would be a separate bridge repo that also depends on the same native artifacts. See [onboarding-new-developer.md](./onboarding-new-developer.md#react-native-sdk-not-in-this-repo).
