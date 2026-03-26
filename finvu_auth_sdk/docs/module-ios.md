# Module: iOS (`ios/`)

## 1) Purpose and why it exists

The iOS folder provides a **Flutter plugin** that:

1. Registers `FinvuAuthSdkPlugin` with the Flutter engine.
2. Wires Pigeon’s `FinvuHostApiSetup` to a Swift implementation class.
3. Delegates authentication to **`FinvuAuthenticationNativeWrapper`** from the **`FinvuAuthenticationSDK`** CocoaPod.

Same idea as Android: **thin bridge**, business logic lives in the native SDK.

## 2) Versioning

- **`finvu_auth_sdk_flutter.podspec`** → `s.version` should stay aligned with `pubspec.yaml` for releases.
- **Native SDK:** The example app pins the pod via **git + tag** (see below). Bump when the iOS SDK team releases a new tag.

## 3) Setup and installation

### Pod dependency

The **plugin** declares:

```ruby
s.dependency 'FinvuAuthenticationSDK'
```

The **example app** (and consuming apps) must resolve where that pod comes from. In this repo’s `example/ios/Podfile`:

```ruby
pod 'FinvuAuthenticationSDK',
    :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git',
    :tag => '1.0.1'
```

**Requirements:**

- Git access to `https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios`
- Xcode / CocoaPods toolchain; `platform :ios, '16.0'` minimum in the example

**SSH vs HTTPS:** Teams often use SSH URLs if CI uses deploy keys; update the Podfile accordingly.

### Publishing the Flutter plugin

Consumers need either:

- The same git/tag pod source in their app Podfile, or
- A published podspec on a private CocoaPods spec repo (if the org publishes that way)

Document whichever pattern your org standardizes.

## 4) Architecture and folder structure

```
ios/
├── finvu_auth_sdk_flutter.podspec
├── Resources/
│   └── PrivacyInfo.xcprivacy     # Privacy manifest (enable in podspec if required)
└── Classes/
    ├── FinvuAuthSdkPlugin.swift      # Registers Pigeon API
    └── generated/
        └── NativeFinvuAuthWrapper.g.swift   # Pigeon-generated
```

### `FinvuHostApiImpl` behavior (summary)

- Resolves the key window’s `rootViewController` for `setUp`.
- Maps `Environment` → `FinvuAuthEnvironment` (production vs development).
- Calls `FinvuAuthenticationNativeWrapper.shared` for `initAuth`, `startAuth`, `verifyOtp`, `cleanupAll`.
- Maps dictionary / `FinvuAuthException` results into Pigeon `FinvuAuthResult`.

## 5) Release process

1. Bump `pubspec.yaml` and `finvu_auth_sdk_flutter.podspec` version.
2. Ensure **FinvuAuthenticationSDK** tag in consumer Podfiles matches a tested native release.
3. Publish Flutter package per [release-and-credentials.md](./release-and-credentials.md).

## 6) Credentials / access

- **GitHub:** Read access to `finvu-auth-sdk-ios` for `pod install` (PAT in URL is deprecated; prefer SSH agent or `cocoapods-downloader` with credentials in CI).

See [onboarding-new-developer.md](./onboarding-new-developer.md) for `pod install` from a clean clone.
