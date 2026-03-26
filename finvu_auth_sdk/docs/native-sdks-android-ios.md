# Native authentication SDKs (Android & iOS) — modules **core**, **client**, **internal**, **sanauth**

## Important: source location

This **Flutter plugin repository** does **not** contain Gradle modules named `core`, `client`, `internal`, or `sanauth` as source folders. Those names typically refer to **layers inside** the proprietary **Finvu Android / iOS SDK repositories** that produce:

| Artifact | How this Flutter repo consumes it |
|----------|-------------------------------------|
| **Android** `com.finvu.android:finvuauthenticationsdk` | `android/build.gradle` → `implementation("com.finvu.android:finvuauthenticationsdk:…")` |
| **iOS** `FinvuAuthenticationSDK` | `pod 'FinvuAuthenticationSDK'` from git `finvu-auth-sdk-ios` |

The Flutter plugin only sees **public** entry types such as:

- **Android:** `com.finvu.android.authenticationwrapper.FinvuAuthenticationNativeWrapper`, `FinvuAuthException`, `FinvuAuthEnvironment`
- **iOS:** `FinvuAuthenticationNativeWrapper` (from `import FinvuAuthenticationSDK`)

**Action for maintainers:** Keep an internal README inside `finvu-auth-sdk-android` and `finvu-auth-sdk-ios` that maps **module name → responsibility**. The table below is a **logical** template; replace descriptions with your org’s exact definitions.

---

## 1) Purpose of each submodule (template — verify in native repos)

| Submodule | Typical purpose | Why it exists |
|-----------|-----------------|---------------|
| **core** | Domain models, environment config, crypto primitives, shared errors | Single source of truth for auth state machine and secure constants |
| **client** | HTTP/WebSocket clients to Finvu/AA APIs, request signing | Isolates networking from UI and from low-level crypto |
| **internal** | Implementation details not meant for public API (helpers, internal DTOs) | Hides churn from external consumers |
| **sanauth** (or similarly named) | **Sandbox** / non-production auth endpoints, test harness hooks | Safe development without touching production data |

> **Note:** The exact name **sanauth** might differ (e.g. `sandbox`, `debug`). Confirm in the Android/iOS repos.

---

## 2) Versioning

- **Android AAR:** Version in GitHub Packages (Maven) — e.g. `1.0.3` in this plugin’s Gradle.
- **iOS:** Git **tag** on `finvu-auth-sdk-ios` (e.g. `1.0.1` in the example Podfile).

Flutter plugin version (`pubspec.yaml`) is **independent** but should be tested against **known good** native versions; document compatibility in `CHANGELOG.md`.

---

## 3) Setup (native SDK development — not Flutter)

Performed in the **Android/iOS SDK repos**, not here:

- **Android:** Publish to `https://maven.pkg.github.com/Cookiejar-technologies/finvu-auth-sdk-android` with Gradle `maven-publish` + PAT with `write:packages`.
- **iOS:** Tag release on `finvu-auth-sdk-ios`; optionally publish to a private spec repo.

---

## 4) Architecture (how Flutter fits)

```
┌─────────────────────────────────────────────────────────┐
│  Flutter app (Dart)                                      │
│  IFinvuHost / WebView / Native wrappers                  │
└──────────────────────────┬──────────────────────────────┘
                           │ Pigeon
┌──────────────────────────▼──────────────────────────────┐
│  Plugin (Kotlin / Swift)  FinvuAuthSdkPlugin            │
└──────────────────────────┬──────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────┐
│  FinvuAuthenticationNativeWrapper  (AAR / XCFramework)   │
│  ← core / client / internal / sanauth live HERE (native) │
└───────────────────────────────────────────────────────────┘
```

---

## 5) Release process (native)

Owned by the **native SDK teams**. Flutter plugin release: bump `finvuauthenticationsdk` and/or Pod **tag** only after QA on a staging app.

---

## 6) What to tell a new developer

1. **Flutter-only work:** Clone this repo; follow [onboarding-new-developer.md](./onboarding-new-developer.md).
2. **Bug in auth/crypto/network:** Likely **native SDK** — reproduce from example app, then open issue in Android/iOS repo with logs.
3. **Submodule map:** Ask for internal Confluence/README in `Cookiejar-technologies/finvu-auth-sdk-android` and `finvu-auth-sdk-ios`.
