# Module: Pigeon contract (`pigeons/native_finvu_auth_wrapper.dart`)

## 1) Purpose and why it exists

[Pigeon](https://pub.dev/packages/pigeon) generates **type-safe** platform channel code for Dart, Kotlin, and Swift from a single schema file. It exists to:

- Avoid hand-written `MethodChannel` string typos.
- Keep **Dart / Android / iOS** method signatures in sync.

The input file is `pigeons/native_finvu_auth_wrapper.dart` (path may be `pigeons/` at repo root — adjust if your tree uses only `pigeons/native_finvu_auth_wrapper.dart`).

## 2) Versioning

- **Pigeon package** version is in `pubspec.yaml` under `dev_dependencies` / `dependencies` (`pigeon: ^26.0.1`).
- **Generated API versioning** is implicit: when you change the Pigeon file, you bump the **plugin** semver if the change is breaking for Dart or native callers.

## 3) Setup and regeneration

From the **package root** (`finvu_auth_sdk/`):

```bash
dart run pigeon --input pigeons/native_finvu_auth_wrapper.dart
```

Paths for Dart/Kotlin/Swift are taken from `@ConfigurePigeon(PigeonOptions(...))` inside that file — you do not pass `--dart_out` manually unless you remove the annotation.

**Outputs** (configured in `@ConfigurePigeon`):

| Output | Path |
|--------|------|
| Dart | `lib/src/generated/native_finvu_auth_wrapper.g.dart` |
| Kotlin | `android/src/main/kotlin/.../generated/NativeFinvuAuthWrapper.g.kt` |
| Swift | `ios/Classes/generated/NativeFinvuAuthWrapper.g.swift` |

After regeneration:

1. Run `dart analyze` / `flutter analyze`.
2. Fix `FinvuAuthSdkPlugin.kt` / `FinvuAuthSdkPlugin.swift` if interface names or signatures changed.
3. Update `lib/src/impl/mapper.dart` if models changed.

## 4) Architecture: what’s in the schema

- **DTOs:** `InitConfig`, `VerifyOtpReq`, `FinvuAuthResult`, success/error types, enums `Environment`, `FinvuStatus`, etc.
- **`@HostApi()` `FinvuHostApi`:** Methods invoked **from Dart** → **native**. This plugin implements the host API on Android and iOS.

### Changing the API safely

- **Additive:** New optional fields or new methods → usually **minor** bump.
- **Removing/renaming** fields or methods → **major** bump; update all three platforms and any WebView JSON contract if applicable.

## 5) Release process

Pigeon is a **build-time** tool; nothing separate to publish. The generated `.g.dart` / `.g.kt` / `.g.swift` files are **committed** so consumers don’t need to run Pigeon.

## 6) Troubleshooting

- **Kotlin `errorClassName`:** `KotlinOptions` in `@ConfigurePigeon` — match your Pigeon version’s docs.
- **Swift compile errors after upgrade:** Re-run codegen and compare `FinvuHostApi` protocol changes.
