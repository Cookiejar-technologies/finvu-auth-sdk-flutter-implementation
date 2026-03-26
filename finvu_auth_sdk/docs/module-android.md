# Module: Android (`android/`)

## 1) Purpose and why it exists

The Android folder is a **Flutter plugin module** that:

1. Registers with the Flutter engine (`FinvuAuthSdkPlugin`).
2. Implements the **Pigeon-generated** `FinvuHostApi` Kotlin interface.
3. Delegates all authentication work to the **native Finvu Android Authentication SDK** published as Maven coordinates `com.finvu.android:finvuauthenticationsdk`.

The plugin **does not** re-implement AA crypto, OTP, or network logic — it **bridges** Flutter ↔ `FinvuAuthenticationNativeWrapper` from the AAR.

## 2) Versioning

- **Gradle module version:** `android/build.gradle` → `version = "1.0-SNAPSHOT"` (align with plugin release strategy; many teams set this to match `pubspec.yaml` for traceability).
- **Transitive native SDK:** `implementation("com.finvu.android:finvuauthenticationsdk:1.0.3")` — bump when the native team releases a new AAR.

## 3) Setup and installation

### For apps consuming this Flutter plugin (development)

**1) GitHub Packages Maven** — the example app uses:

- **URL:** `https://maven.pkg.github.com/Cookiejar-technologies/finvu-auth-sdk-android`
- **Credentials:**
  - `username` = **GitHub username** (or org bot user)
  - `password` = **Personal Access Token (PAT)** with `read:packages` (classic PAT) or fine-grained token with packages read for that repository

Configured in the **host or example** Gradle `repositories` block (see `example/android/build.gradle.kts`).

**Never commit real PATs.** Use:

- `~/.gradle/gradle.properties` (`gpr.user`, `gpr.key`), or
- CI secrets, or
- Environment variables referenced from Gradle

and replace the placeholder `username` / `password` in the example before building.

### For publishing **this** Flutter plugin’s Android artifact

If you ship the Flutter plugin to pub/git only, consumers still need Maven access to **finvuauthenticationsdk**, not necessarily to this plugin’s `android/` AAR separately — the dependency is declared inside `android/build.gradle`.

## 4) Architecture and folder structure

```
android/
├── build.gradle                 # Library plugin, Kotlin, finvuauthenticationsdk dependency
├── settings.gradle
└── src/
    ├── main/kotlin/com/finvu/finvu_auth_sdk/
    │   ├── FinvuAuthSdkPlugin.kt       # FlutterPlugin + ActivityAware + FinvuHostApi
    │   └── generated/
    │       └── NativeFinvuAuthWrapper.g.kt   # Pigeon-generated — do not edit by hand
    └── test/kotlin/.../FinvuAuthSdkPluginTest.kt
```

### Runtime flow

1. `onAttachedToEngine` → `FinvuHostApi.setUp(..., this)`.
2. `onAttachedToActivity` → stores `Activity`, calls `maybeSetupWrapper()`.
3. `setUp(env)` maps Pigeon `Environment` → `FinvuAuthEnvironment` and configures the wrapper.
4. `initAuth` / `startAuth` / `verifyOtp` call `wrapper.setup(env, activity, scope)` then the corresponding `FinvuAuthenticationNativeWrapper` methods; JSON results map to `FinvuAuthResult`.
5. `cleanupAll` → `wrapper.onDestroy()` and scope reset.

### Imports from the native AAR (illustrative)

- `com.finvu.android.authenticationwrapper.FinvuAuthenticationNativeWrapper`
- `com.finvu.android.authenticationwrapper.models.FinvuAuthException`
- `com.finvu.android.authenticationwrapper.utils.FinvuAuthEnvironment`

Those classes belong to the **published SDK**, not this repo. Deeper modules (**core**, **client**, **internal**, **sanauth**) live **inside** that SDK or sibling Android repo — see [native-sdks-android-ios.md](./native-sdks-android-ios.md).

## 5) Release process

- **Flutter plugin:** Version in `pubspec.yaml` + publish flow in [release-and-credentials.md](./release-and-credentials.md).
- **Native AAR** (`finvuauthenticationsdk`): Released separately by the Android SDK team to GitHub Packages; this plugin only bumps the `implementation(...)` version when instructed.

## 6) Credentials and files (cheat sheet)

| Item | Where |
|------|--------|
| Maven URL | `example/android/build.gradle.kts` → `repositories { maven { url = ... } }` |
| Username/password | Replace placeholders or wire to `gradle.properties` / env |
| Min SDK | Plugin `defaultConfig.minSdk = 21`; example app may use higher (e.g. 25) |

See [onboarding-new-developer.md](./onboarding-new-developer.md) for a full walkthrough.
