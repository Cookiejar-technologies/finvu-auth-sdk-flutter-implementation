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
 * `result.getOrNull()?.toString()` passthrough on success. On failure this
 * plugin returns the same flat `{"status", "errorCode", "errorMessage"}`
 * object the native SDK and the RN module use, since a thrown exception has
 * no JSON form of its own and something has to serialize it. That keeps RN,
 * Flutter, Android and iOS all failing the same way.
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

    wrapper.initAuth(map) { nativeResult -> resolve(nativeResult, callback) }
  }

  override fun startSNA(snaLink: String, callback: (Result<String>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(errorJsonString(code = "ACTIVITY_OR_SCOPE_NOT_READY", message = "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    wrapper.startAuth(snaLink) { nativeResult -> resolve(nativeResult, callback) }
  }

  /* -------------------- Device binding factor -------------------- */

  /**
   * Reports whether `keyId` from a previous enroll is still usable. Local only,
   * so it may be called before [initSNA].
   */
  override fun getDeviceBindingState(configJson: String, callback: (Result<String>) -> Unit) {
    withConfig(configJson, "DEVICE_BINDING_STATE_ERROR", callback) { map ->
      wrapper.getDeviceBindingState(map) { nativeResult -> resolve(nativeResult, callback) }
    }
  }

  /**
   * Prompts for the device lock, then creates a fresh key pair and returns its
   * keyId and public key. Pigeon delivers host calls on the main thread, which
   * is where the native SDK must show its BiometricPrompt.
   */
  override fun enrollDeviceBinding(configJson: String, callback: (Result<String>) -> Unit) {
    withConfig(configJson, "DEVICE_BINDING_ENROLL_ERROR", callback) { map ->
      wrapper.enrollDeviceBinding(map) { nativeResult -> resolve(nativeResult, callback) }
    }
  }

  /** Signs a server-issued challenge after a device-lock prompt. */
  override fun signDeviceBindingChallenge(configJson: String, callback: (Result<String>) -> Unit) {
    withConfig(configJson, "DEVICE_BINDING_SIGN_ERROR", callback) { map ->
      wrapper.signDeviceBindingChallenge(map) { nativeResult -> resolve(nativeResult, callback) }
    }
  }

  /** Describes what this native SDK build supports. */
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
   * Parses the call's JSON config into the map the native SDK expects, after
   * making sure the wrapper has the current activity. A bad config or a
   * missing activity is reported to Dart as a failure, never thrown.
   */
  private fun withConfig(
    configJson: String,
    errorCode: String,
    callback: (Result<String>) -> Unit,
    block: (MutableMap<String, Any>) -> Unit,
  ) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(errorJsonString(code = "ACTIVITY_OR_SCOPE_NOT_READY", message = "Activity/Scope not attached")))
      return
    }
    val map = try {
      val json = JSONObject(configJson)
      json.keys().asSequence().associateWith { key -> json.get(key) }.toMutableMap()
    } catch (e: Exception) {
      callback(Result.success(errorJsonString(code = errorCode, message = e.message ?: "Invalid config JSON")))
      return
    }
    wrapper.setup(this.env, act, sc)
    block(map)
  }

  /**
   * Turns a native `Result<JSONObject>` into the string the Dart side gets:
   * the JSON verbatim on success, the flat error object on failure.
   */
  private fun resolve(result: Result<JSONObject>, callback: (Result<String>) -> Unit) {
    result
      .onSuccess { json -> callback(Result.success(json?.toString() ?: "{}")) }
      .onFailure { err -> callback(Result.success(errorJsonStringFrom(err))) }
  }

  /**
   * Mirrors `FinvuAuthSdkRnModule.errorJsonString` exactly: the same flat
   * `{status, errorCode, errorMessage}` shape the native SDK returns.
   */
  private fun errorJsonString(status: String = "FAILURE", code: String, message: String): String {
    return JSONObject().apply {
      put("status", status)
      put("errorCode", code)
      put("errorMessage", message)
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
