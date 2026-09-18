package com.finvu.finvu_auth_sdk

import android.app.Activity
import android.content.Context
import androidx.annotation.MainThread
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.json.JSONObject

// Native wrapper dependency (from your AAR)
import com.finvu.android.authenticationwrapper.FinvuAuthenticationNativeWrapper
import com.finvu.android.authenticationwrapper.models.FinvuAuthException
import com.finvu.android.authenticationwrapper.utils.FinvuAuthEnvironment

/**
 * Bridges Pigeon <-> Native wrapper (Android).
 *
 * Implements the generated FinvuHostApi interface from Pigeon.
 *
 * Every method below hands back exactly the JSON the native
 * [FinvuAuthenticationNativeWrapper] produced, as a string — no field
 * allow-list, no reshaping. This mirrors the React Native module
 * (`FinvuAuthSdkRnModule.kt`), which does the same
 * `result.getOrNull()?.toString()` passthrough on success. The only shape
 * this plugin imposes is the small `{"error": {...}}` envelope on failure —
 * copied from that same RN module, since a thrown exception has no JSON form
 * of its own and something has to serialize it. That keeps RN, Android and
 * iOS all failing the same way.
 */
class FinvuAuthSdkPlugin :
  FlutterPlugin,
  ActivityAware,
  FinvuHostApi {

  // Flutter context/activity
  private lateinit var appContext: Context
  private var activity: Activity? = null

  // Coroutine scope for native calls
  private var scope: CoroutineScope? = null

  // Environment for the wrapper (default to PRODUCTION)
  private var env: FinvuAuthEnvironment = FinvuAuthEnvironment.PRODUCTION

  // Native wrapper instance (don't rely on companion `.instance`)
  private val wrapper: FinvuAuthenticationNativeWrapper by lazy {
    FinvuAuthenticationNativeWrapper()
  }

  /* -------------------- FlutterPlugin -------------------- */

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    // Register Pigeon handlers
    FinvuHostApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    FinvuHostApi.setUp(binding.binaryMessenger, null)
    scope?.cancel()
    scope = null
  }

  /* -------------------- ActivityAware -------------------- */

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    maybeSetupWrapper()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    maybeSetupWrapper()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  /* -------------------- Pigeon: FinvuHostApi -------------------- */

  // NOTE: generated method name is setUp(env), not setEnvironment
  override fun setUp(env: Environment) {
    this.env = when (env) {
      Environment.DEVELOPMENT -> FinvuAuthEnvironment.DEVELOPMENT
      Environment.PRODUCTION -> FinvuAuthEnvironment.PRODUCTION
    }
    maybeSetupWrapper()
  }

  override fun initSNA(config: InitConfig, callback: (Result<String>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(errorJsonString(code = "ACTIVITY_OR_SCOPE_NOT_READY", message = "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    val map = linkedMapOf<String, Any>(
      "requestId" to (config.requestId ?: ""),
      "entityId" to (config.entityId ?: "")
    )

    wrapper.initSNA(map) { nativeResult -> resolve(nativeResult, callback) }
  }

  override fun startSNA(snaLink: String, callback: (Result<String>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(errorJsonString(code = "ACTIVITY_OR_SCOPE_NOT_READY", message = "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    wrapper.startSNA(snaLink) { nativeResult -> resolve(nativeResult, callback) }
  }

  /* -------------------- Pigeon: device binding -------------------- */

  override fun getDeviceBindingState(
    config: DeviceBindingConfig,
    callback: (Result<String>) -> Unit,
  ) {
    withWrapper(callback) {
      wrapper.getDeviceBindingState(config.toMap()) { nativeResult -> resolve(nativeResult, callback) }
    }
  }

  override fun enrollDeviceBinding(
    config: DeviceBindingConfig,
    callback: (Result<String>) -> Unit,
  ) {
    withWrapper(callback) {
      wrapper.enrollDeviceBinding(config.toMap()) { nativeResult -> resolve(nativeResult, callback) }
    }
  }

  override fun signDeviceBindingChallenge(
    config: DeviceBindingConfig,
    callback: (Result<String>) -> Unit,
  ) {
    withWrapper(callback) { act ->
      // The biometric prompt must be raised from the main thread.
      act.runOnUiThread {
        wrapper.signDeviceBindingChallenge(config.toMap()) { nativeResult -> resolve(nativeResult, callback) }
      }
    }
  }

  override fun getCapabilities(): String = wrapper.getCapabilities().toString()

  override fun cleanupAll() {
    try {
      wrapper.onDestroy()
    } catch (_: Throwable) {
      // ignore
    }
    scope?.cancel()
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  }

  /* -------------------- Helpers -------------------- */

  @MainThread
  private fun maybeSetupWrapper() {
    val act = activity
    val sc = scope
    if (act != null && sc != null) {
      wrapper.setup(this.env, act, sc)
    }
  }

  /**
   * Turns a native `Result<JSONObject>` into the string the Dart side gets:
   * the JSON verbatim on success, the shared error envelope on failure.
   */
  private fun resolve(result: Result<JSONObject>, callback: (Result<String>) -> Unit) {
    result
      .onSuccess { json -> callback(Result.success(json?.toString() ?: "{}")) }
      .onFailure { err -> callback(Result.success(errorJsonStringFrom(err))) }
  }

  /**
   * Ensures the wrapper is set up before a device binding call, reporting the
   * failure through the callback rather than dropping it.
   */
  private fun withWrapper(
    callback: (Result<String>) -> Unit,
    block: (Activity) -> Unit,
  ) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(errorJsonString(code = "ACTIVITY_OR_SCOPE_NOT_READY", message = "Activity/Scope not attached")))
      return
    }
    wrapper.setup(this.env, act, sc)
    block(act)
  }

  /** Only non-blank values are forwarded, so the native side applies its own defaults. */
  private fun DeviceBindingConfig.toMap(): MutableMap<String, Any> {
    val map = linkedMapOf<String, Any>()
    userId?.takeIf { it.isNotBlank() }?.let { map["userId"] = it }
    entityId?.takeIf { it.isNotBlank() }?.let { map["entityId"] = it }
    challenge?.takeIf { it.isNotBlank() }?.let { map["challenge"] = it }
    attestationChallenge?.takeIf { it.isNotBlank() }
      ?.let { map["attestationChallenge"] = it }
    promptTitle?.takeIf { it.isNotBlank() }?.let { map["promptTitle"] = it }
    promptSubtitle?.takeIf { it.isNotBlank() }?.let { map["promptSubtitle"] = it }
    return map
  }

  /**
   * Mirrors `FinvuAuthSdkRnModule.errorJsonString` exactly, so RN, Android and
   * iOS all report failures in the same shape.
   */
  private fun errorJsonString(status: String = "FAILURE", code: String, message: String): String {
    return JSONObject().apply {
      put("error", JSONObject().apply {
        put("status", status)
        put("errorCode", code)
        put("errorMessage", message)
      })
    }.toString()
  }

  /** Mirrors the RN module's `(exceptionOrNull() as? FinvuAuthException)` handling. */
  private fun errorJsonStringFrom(t: Throwable): String {
    val error = t as? FinvuAuthException
    return errorJsonString(
      status = error?.status ?: "FAILURE",
      code = error?.errorCode ?: "UNKNOWN_ERROR",
      message = error?.errorMessage ?: "Unknown error occurred."
    )
  }
}
