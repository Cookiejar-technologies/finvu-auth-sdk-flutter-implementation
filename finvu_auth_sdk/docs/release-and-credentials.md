# Release process, URLs, and credentials

## Versioning (single checklist)

1. **`pubspec.yaml`** — `version: X.Y.Z`
2. **`CHANGELOG.md`** — new section for `X.Y.Z`
3. **`ios/finvu_auth_sdk_flutter.podspec`** — `s.version = 'X.Y.Z'`
4. **`android/build.gradle`** — `version = "X.Y.Z"` (recommended alignment)
5. **Native compatibility** — note which `finvuauthenticationsdk` version and Pod **tag** were tested

Run `flutter analyze` and test `example/` on Android + iOS.

---

## Publishing the Flutter package (`pub.dev` or private)

### pub.dev (public)

```bash
cd finvu_auth_sdk   # package root
flutter pub publish --dry-run
flutter pub publish
```

Requires:

- Verified publisher on pub.dev
- `pubspec.yaml` `homepage` / `repository` valid

### Git dependency (private)

Many teams host on GitHub and depend via:

```yaml
dependencies:
  finvu_auth_sdk_flutter:
    git:
      url: https://github.com/Cookiejar-technologies/finvu-auth-sdk-flutter-implementation.git
      path: finvu_auth_sdk
      ref: vX.Y.Z   # tag
```

Tag the repo after release.

---

## Android: Maven (GitHub Packages)

**URL (from this repo’s example):**

`https://maven.pkg.github.com/Cookiejar-technologies/finvu-auth-sdk-android`

**Credentials:**

| Field | Value |
|-------|--------|
| `username` | GitHub username or `x-access-token` (see GitHub docs) |
| `password` | PAT with **`read:packages`** (minimum for consumers) |

**Publishing** the AAR (native SDK team):

- PAT with **`write:packages`**
- Gradle `maven-publish` to the same GitHub Packages URL

**Files in this repo:**

- `example/android/build.gradle.kts` — `repositories { maven { ... } }` (placeholders for local dev)
- Plugin `android/build.gradle` — depends on `com.finvu.android:finvuauthenticationsdk`

---

## iOS: CocoaPods (`FinvuAuthenticationSDK`)

**Source (example Podfile):**

- Repository: `https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git`
- Tag: e.g. `1.0.1`

**Credentials:** Git access (HTTPS with credential helper or SSH key).

**Publishing:** Tag the iOS SDK repo; optionally push to a private spec repo if your org uses one.

---

## What URLs to bookmark

| Resource | URL |
|----------|-----|
| Flutter implementation repo | `https://github.com/Cookiejar-technologies/finvu-auth-sdk-flutter-implementation` |
| Android Maven (GitHub Packages) | `https://maven.pkg.github.com/Cookiejar-technologies/finvu-auth-sdk-android` |
| iOS SDK git | `https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios` |

(Adjust if your org renames or moves repos.)

---

## CI secrets (recommended names)

| Secret | Use |
|--------|-----|
| `GITHUB_PACKAGES_USER` | Maven username |
| `GITHUB_PACKAGES_TOKEN` | PAT with `read:packages` |
| `COCOAPODS_GITHUB_TOKEN` or SSH key | `pod install` for private iOS SDK |

Never echo tokens in build logs.
