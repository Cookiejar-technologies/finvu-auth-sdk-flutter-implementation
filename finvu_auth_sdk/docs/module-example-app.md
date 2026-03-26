# Module: Example app (`example/`)

## 1) Purpose and why it exists

The `example/` Flutter app is a **manual integration test** and **developer demo** for:

- **WebView flow** — loads a hosted web app, uses `IFinvuWebViewWrapper` + JavaScript channel so the page can trigger native auth via the bridge.
- **Native flow** — uses `IFinvuNativeWrapper` from Flutter widgets (init → start auth) without embedding the web UI.

It is **not** published to pub.dev (`publish_to: 'none'` in `example/pubspec.yaml`).

## 2) Versioning

Tracks the parent plugin via **path dependency**:

```yaml
finvu_auth_sdk_flutter:
  path: ../
```

No independent semver for the example; bump only the **plugin** `pubspec.yaml` for releases.

## 3) Setup and installation

### From repo root

```bash
cd finvu_auth_sdk/example
flutter pub get
```

### Android

1. Configure GitHub Packages Maven (see [release-and-credentials.md](./release-and-credentials.md)) — replace `username` / `password` in `example/android/build.gradle.kts`.
2. `cd android && ./gradlew assembleDebug` or `flutter run`.

### iOS

1. Ensure `example/ios/Podfile` has valid `FinvuAuthenticationSDK` git/tag and you have repo access.
2. `cd ios && pod install`
3. `flutter run` from `example/`.

## 4) Architecture and folder structure

```
example/
├── pubspec.yaml
├── lib/
│   ├── main.dart                    # Home: two buttons → WebView vs Native
│   └── src/pages/
│       ├── webview_page.dart        # WebView + setupWebView + load URL
│       └── native_view_page.dart    # Init / start auth, APP_ID / REQUEST_ID
├── android/                         # Host app Gradle + Maven credentials
└── ios/                             # Runner + Podfile
```

### WebView feature (`webview_page.dart`)

- Builds `WebViewController`, `JavaScriptMode.unrestricted`.
- `FinvuAuthSdk.webViewBridge()` → `setupWebView(env: Environment.development, controller: ...)`.
- Loads `_webUrl` (currently a Firebase-hosted test URL — replace for your environment).

The **web page** must use the same JS contract as `FinvuWebViewWrapperImpl`: channel name `finvu_authentication_bridge` and JSON payloads with `method`, `callback`, etc. (see [module-flutter-lib.md](./module-flutter-lib.md)).

### Native feature (`native_view_page.dart`)

- `APP_ID` / `REQUEST_ID` — **empty placeholders**; fill with real values from your AA/backend onboarding.
- `setEnvironment(Environment.development)` in `initState`.
- Flow: **Init Auth** → on success, enable **Start Auth** with phone number.

## 5) Release process

The example is **not** released as a package. For internal QA, build APK/IPA from CI or locally; signing is debug by default in `example/android/app/build.gradle.kts` release block.

## 6) How features are developed here

| Feature | How to extend |
|---------|----------------|
| New screen | Add under `lib/src/pages/`, route from `main.dart`. |
| Test another WebView URL | Change `_webUrl` in `webview_page.dart`. |
| Test production env | Switch `Environment.development` → `Environment.production` where appropriate. |

For production hardening (SSL pinning, root detection, etc.), see [security.md](./security.md) — mostly **outside** this example.
