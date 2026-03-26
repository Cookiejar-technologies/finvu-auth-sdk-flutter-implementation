# Feature: Native (Flutter UI) auth flow

## Purpose

Uses **`IFinvuNativeWrapper`** so Flutter widgets call `initAuth` → `startAuth` → (optionally) `verifyOtp` **directly**, with no WebView.

## Where it lives

- API: `lib/src/api/finvu_native_wrapper.dart`
- Implementation: `lib/src/impl/finvu_native_wrapper_impl.dart` (delegates to `IFinvuHost`)
- Example: `example/lib/src/pages/native_view_page.dart`

## How to develop / change

1. Set real **`APP_ID`** / **`REQUEST_ID`** in the example (or pass from your app config).
2. Call `setEnvironment` before other methods.
3. On navigation away, call `cleanupAll()` (see example `dispose` / `WillPopScope`).

## Platform behavior

All heavy lifting is in **native** `FinvuAuthenticationNativeWrapper` (Android/iOS). Flutter only forwards parameters and displays results.
