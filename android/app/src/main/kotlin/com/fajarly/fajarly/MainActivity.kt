package com.fajarly.fajarly

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles three responsibilities for the alarm flow:
 *
 * 1. FLAG_SECURE toggle while the ringing screen is up — blocks screenshots
 *    and scrubs the camera preview from the recent-apps thumbnail so the
 *    user can't fake a scan from a cached image.
 *
 * 2. Window flags that let the alarm activity draw over the lock screen and
 *    dismiss an insecure keyguard automatically.
 *
 * 3. `bringToFront` — relaunch ourselves to the front when Flutter detects
 *    the user pressing Home / swiping away while an alarm is ringing. This
 *    is the best-effort Android equivalent of "you cannot minimize this."
 */
class MainActivity : FlutterActivity() {
    private val channelName = "fajarly/secure"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over the lock screen + turn the display on when launched by a
        // full-screen intent. On O_MR1+ the modern API calls are preferred.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        runOnUiThread {
                            if (enabled) {
                                window.setFlags(
                                    WindowManager.LayoutParams.FLAG_SECURE,
                                    WindowManager.LayoutParams.FLAG_SECURE
                                )
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(null)
                    }
                    "dismissKeyguard" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                            km.requestDismissKeyguard(this, null)
                        } else {
                            @Suppress("DEPRECATION")
                            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
                        }
                        result.success(null)
                    }
                    "bringToFront" -> {
                        val intent = Intent(this, MainActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                    or Intent.FLAG_ACTIVITY_SINGLE_TOP
                                    or Intent.FLAG_ACTIVITY_NEW_TASK
                            )
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
