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

  // Native wrapper instance (don’t rely on companion `.instance`)
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

  override fun initAuth(config: InitConfig, callback: (Result<FinvuAuthResult>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(buildFailure("ACTIVITY_OR_SCOPE_NOT_READY", "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    val map = linkedMapOf<String, Any>(
      "appId" to (config.appId ?: ""),
      "requestId" to (config.requestId ?: "")
    )

    wrapper.initAuth(map) { nativeResult ->
      nativeResult
        .onSuccess { json -> callback(Result.success(buildSuccessFromJson(json))) }
        .onFailure { err -> callback(Result.success(buildFailureFromThrowable(err))) }
    }
  }

  override fun startAuth(phoneNumber: String, callback: (Result<FinvuAuthResult>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(buildFailure("ACTIVITY_OR_SCOPE_NOT_READY", "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    wrapper.startAuth(phoneNumber) { nativeResult ->
      nativeResult
        .onSuccess { json -> callback(Result.success(buildSuccessFromJson(json))) }
        .onFailure { err -> callback(Result.success(buildFailureFromThrowable(err))) }
    }
  }

  override fun verifyOtp(request: VerifyOtpReq, callback: (Result<FinvuAuthResult>) -> Unit) {
    val act = activity
    val sc = scope
    if (act == null || sc == null) {
      callback(Result.success(buildFailure("ACTIVITY_OR_SCOPE_NOT_READY", "Activity/Scope not attached")))
      return
    }

    wrapper.setup(this.env, act, sc)

    wrapper.verifyOtp(request.phoneNumber ?: "", request.otp) { nativeResult ->
      nativeResult
        .onSuccess { json -> callback(Result.success(buildSuccessFromJson(json))) }
        .onFailure { err -> callback(Result.success(buildFailureFromThrowable(err))) }
    }
  }

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

  /** SUCCESS mapping: JSONObject -> FinvuAuthResult(status=SUCCESS, data=FinvuAuthSuccessResponse) */
  private fun buildSuccessFromJson(json: JSONObject?): FinvuAuthResult {
    val safe = json ?: JSONObject()

    val token = safe.optString("token", null)
    val authType = safe.optString("authType", null)
    val extraMap = mutableMapOf<String, Any?>()

    // put everything else in 'extra', excluding known keys
    val exclude = setOf("token", "authType", "status", "error", "errorCode", "errorMessage")
    val keys = safe.keys()
    while (keys.hasNext()) {
      val k = keys.next()
      if (!exclude.contains(k)) extraMap[k] = safe.opt(k)
    }

    val payload = FinvuAuthSuccessResponse(
      token = token,
      authType = authType,
      extra = if (extraMap.isEmpty()) null else extraMap
    )

    return FinvuAuthResult(
      status = FinvuStatus.SUCCESS,
      data = payload,
      error = null
    )
  }

  /** FAILURE mapping: Throwable -> FinvuAuthResult(status=FAILURE, error=FinvuAuthFailureError) */
  private fun buildFailureFromThrowable(t: Throwable): FinvuAuthResult {
    return if (t is FinvuAuthException) {
      val err = FinvuAuthFailureError(
        errorCode = t.errorCode,
        errorMessage = t.errorMessage.ifBlank { t.message ?: "Authentication failed" },
        details = mapOf(
          "status" to t.status // e.g., FAILURE (string from native)
        )
      )
      FinvuAuthResult(
        status = FinvuStatus.FAILURE,
        data = null,
        error = err
      )
    } else {
      val err = FinvuAuthFailureError(
        errorCode = t.javaClass.simpleName,
        errorMessage = t.message ?: "Unknown error",
        details = mapOf("cause" to (t.cause?.toString() ?: "null"))
      )
      FinvuAuthResult(
        status = FinvuStatus.FAILURE,
        data = null,
        error = err
      )
    }
  }

  /** Local failure helper */
  private fun buildFailure(code: String, message: String): FinvuAuthResult {
    val err = FinvuAuthFailureError(
      errorCode = code,
      errorMessage = message,
      details = null
    )
    return FinvuAuthResult(
      status = FinvuStatus.FAILURE,
      data = null,
      error = err
    )
  }
}
