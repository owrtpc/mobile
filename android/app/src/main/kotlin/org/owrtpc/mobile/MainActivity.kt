package org.owrtpc.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "org.owrtpc.mobile/local_preferences",
        ).setMethodCallHandler { call, result ->
            val key = call.argument<String>("key")
            if (key == null) {
                result.error("invalid_arguments", "Missing preference key", null)
                return@setMethodCallHandler
            }
            val preferences = getSharedPreferences("owrtpc_mobile", MODE_PRIVATE)
            when (call.method) {
                "getString" -> result.success(preferences.getString(key, null))
                "setString" -> {
                    val value = call.argument<String>("value")
                    if (value == null) {
                        result.error("invalid_arguments", "Missing preference value", null)
                    } else {
                        preferences.edit().putString(key, value).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
