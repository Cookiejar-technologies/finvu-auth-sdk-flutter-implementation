# Security: Flutter plugin, WebView bridge, and native SDKs

## What this repository actually implements

| Layer | Security relevance |
|-------|-------------------|
| **Dart (`lib/`)** | No secrets storage; passes `appId`, `requestId`, phone, OTP to native via Pigeon. Tokens returned in **Dart memory** — treat like any sensitive string (don’t log in production). |
| **WebView bridge** | Registers `JavaScriptChannel` `finvu_authentication_bridge`. **Any script in the loaded page** (same origin or XSS if vulnerable) could theoretically send messages — **trust model = trust the loaded URL**. |
| **Android / iOS plugins** | Thin glue; **no** root/jailbreak checks in this repo’s source. |
| **Native AAR / Pod** | **Where** TLS, certificate pinning, attestation, root detection, obfuscation, etc. **would** live — **not visible in this Flutter repo**. |

## Root detection / jailbreak

- **Not implemented** in the Dart or plugin Kotlin/Swift files in this repository.
- If your product requires it, confirm with the **FinvuAuthenticationSDK** teams whether it is enforced inside the native SDK and **which** APIs (Play Integrity, SafetyNet legacy, iOS `DeviceCheck`, etc.).
- **Flutter app** can add separate packages (e.g. community root/jailbreak plugins) but that is **orthogonal** to this plugin unless you explicitly block calls to `IFinvuHost` when compromised.

## Reverse engineering

- **Dart code** is compiled to kernel/bytecode; use **Flutter release builds**, **obfuscation** (`--obfuscate` + `--split-debug-info`), and **minification** for Android/iOS release as per Flutter docs.
- **Native SDK** should ship **ProGuard/R8** rules (Android) and **bitcode stripping / symbol hiding** as appropriate — maintained by native SDK, not this repo.

## WebView-specific risks

1. **JavaScript `unrestricted`** on untrusted URLs is dangerous; the example uses a demo URL for testing only.
2. **Bridge contract** (`finvu_authentication_bridge`) exposes auth flows to JS — only load **your** trusted HTML or domains you control.
3. **Mixed content / HTTPS** — enforce HTTPS on the web app.

## SSL / certificate pinning

- Not visible in Flutter plugin code; pinning (if any) is expected in **native** networking layers. Validate with native SDK documentation.

## Other measures (checklist for integrators)

- [ ] Use **production** `Environment` only in release builds.
- [ ] Do **not** log tokens, OTP, or phone numbers.
- [ ] Store tokens in **platform secure storage** (e.g. `flutter_secure_storage`) if required by your app architecture — this plugin does not do that for you.
- [ ] Keep **Android** `minSdk` / `targetSdk` and **iOS** deployment target aligned with security requirements.

## Summary

**This Flutter package is a bridge.** Anti‑tampering, root detection, jailbreak detection, and anti‑reverse‑engineering for the **core Finvu auth** stack must be documented and implemented in **`finvuauthenticationsdk` / `FinvuAuthenticationSDK`** — update [native-sdks-android-ios.md](./native-sdks-android-ios.md) when your internal security team publishes a formal threat model.
