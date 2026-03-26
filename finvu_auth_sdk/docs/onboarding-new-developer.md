# Onboarding: new developer (Flutter SDK + example app)

## 1) Clone and prerequisites

```bash
git clone https://github.com/Cookiejar-technologies/finvu-auth-sdk-flutter-implementation.git
cd finvu-auth-sdk-flutter-implementation/finvu_auth_sdk
flutter pub get
```

Install **Flutter** (Dart `^3.8.1`), **Android Studio** / **Xcode** as needed.

---

## 2) Android: PAT + GitHub username (required for `finvuauthenticationsdk`)

The **native** AAR is on **GitHub Packages**. Maven needs credentials.

### Option A — edit example (quick local test)

Open `example/android/build.gradle.kts` and replace:

```kotlin
credentials {
    username = "username"
    password = "password"
}
```

With:

- `username` = your **GitHub username** (or `x-access-token` per [GitHub docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-gradle-registry))
- `password` = a **Personal Access Token** with scope **`read:packages`** (classic) or fine-grained token with packages read.

### Option B — `gradle.properties` (recommended)

In `~/.gradle/gradle.properties` (or `example/android/gradle.properties` — **do not commit secrets**):

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=ghp_xxxxxxxx
```

Then in `build.gradle.kts` use `project.findProperty("gpr.user")` etc. (your team should add this small Gradle snippet if not present).

### Verify

```bash
cd example
flutter build apk --debug
```

If resolution fails, Gradle will report **401 Unauthorized** — fix PAT scopes.

---

## 3) iOS: Pod install + git access

```bash
cd example/ios
pod install
cd ..
flutter run -d ios
```

Requires read access to `https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git` at the **tag** in `Podfile`.

If HTTPS fails, switch Podfile to SSH:

```ruby
pod 'FinvuAuthenticationSDK',
    :git => 'git@github.com:Cookiejar-technologies/finvu-auth-sdk-ios.git',
    :tag => '1.0.1'
```

---

## 4) Run the example app

```bash
cd finvu_auth_sdk/example
flutter run
```

- **WebView** — uses a demo URL; ensure network allows it.
- **Native** — set `APP_ID` and `REQUEST_ID` in `native_view_page.dart` for real backend tests.

---

## 5) Making changes to the Flutter plugin

1. Create a branch from `dev` (or your default).
2. Edit Dart under `lib/`; for API changes, edit `pigeons/native_finvu_auth_wrapper.dart` and regenerate (see [module-pigeon.md](./module-pigeon.md)).
3. Update Android/iOS plugin implementations if Pigeon changed.
4. `flutter analyze` and manual test on both platforms.

---

## 6) Publishing / updating the package name

**Package name** (Dart) is:

`name: finvu_auth_sdk_flutter` in `pubspec.yaml`

Changing it is **breaking** for all consumers. Only do it with a **major** version and a migration note.

**To publish an update:**

1. Bump version in `pubspec.yaml` + `CHANGELOG.md` + podspec + Android `version`.
2. `flutter pub publish --dry-run` then `flutter pub publish`.

**Consumers** update:

```yaml
finvu_auth_sdk_flutter: ^NEW_VERSION
```

---

## React Native SDK (not in this repo)

This workspace contains **Flutter** only. A **React Native** Finvu SDK would:

- Use the same **Android AAR** and **iOS Pod** (or direct framework embedding).
- Bridge with **TurboModules** / **legacy NativeModules** instead of Pigeon.

**There is no RN package or `package.json` in this repository.** If your org creates `finvu-auth-sdk-react-native`, copy the **credential** and **Maven/Pod** sections from this doc into that repo’s README and link to the same native artifacts.

---

## Quick reference: files that touch credentials

| File | Purpose |
|------|---------|
| `example/android/build.gradle.kts` | Maven `url` + `credentials` for GitHub Packages |
| `android/build.gradle` | Declares `com.finvu.android:finvuauthenticationsdk` coordinate |
| `example/ios/Podfile` | `FinvuAuthenticationSDK` git + tag |

---

## Login / publish summary

| Target | Login / auth |
|--------|----------------|
| **GitHub Packages (Maven)** | GitHub PAT (`read:packages` consumer, `write:packages` publisher) |
| **iOS SDK git** | GitHub SSH key or HTTPS credential helper |
| **pub.dev** | `dart pub token` / Google account for publisher |

---

## Getting help

- **Pigeon / Dart API** — this repo’s `docs/` + `CHANGELOG.md`.
- **Native crashes / auth errors** — native SDK logs; Android Logcat / Xcode console.
- **Submodule layout (core/internal/sanauth)** — see [native-sdks-android-ios.md](./native-sdks-android-ios.md).
