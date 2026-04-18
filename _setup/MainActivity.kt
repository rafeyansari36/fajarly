package com.fajarly.fajarly

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "fajarly/secure"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
                    "setSecure" -> handleSetSecure(call.arguments as? Boolean ?: false, result)
                    "dismissKeyguard" -> handleDismissKeyguard(result)
                    "bringToFront" -> handleBringToFront(result)

                    // Diagnostics — check permission state
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
                    "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                    "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))

                    // Deep-link to the relevant Android Settings page
                    "openFullScreenIntentSettings" -> openFullScreenIntentSettings(result)
                    "openExactAlarmSettings" -> openExactAlarmSettings(result)
                    "openNotificationSettings" -> openNotificationSettings(result)
                    "openBatteryOptimizationSettings" -> openBatteryOptimizationSettings(result)
                    "openOverlaySettings" -> openOverlaySettings(result)
                    "openOemPermissionEditor" -> openOemPermissionEditor(result)
                    "openAppSettings" -> openAppSettings(result)

                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSetSecure(enabled: Boolean, result: MethodChannel.Result) {
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

    private fun handleDismissKeyguard(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
        result.success(null)
    }

    private fun handleBringToFront(result: MethodChannel.Result) {
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

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.canUseFullScreenIntent()
    }

    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openFullScreenIntentSettings(result: MethodChannel.Result) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:$packageName")
            }
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        }
        safeStart(intent, result)
    }

    private fun openExactAlarmSettings(result: MethodChannel.Result) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:$packageName")
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }
        safeStart(intent, result)
    }

    private fun openNotificationSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        safeStart(intent, result)
    }

    private fun openBatteryOptimizationSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
        }
        safeStart(intent, result)
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
        safeStart(intent, result)
    }

    private fun openOverlaySettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
            data = Uri.parse("package:$packageName")
        }
        safeStart(intent, result)
    }

    /**
     * Xiaomi / MIUI exposes a separate "Display pop-up windows while running
     * in background" toggle that doesn't map to SYSTEM_ALERT_WINDOW. It lives
     * in the MIUI permission editor activity. Similar OEM-specific editors
     * exist on Oppo / Vivo but with different component names — try the
     * known ones in order and fall through to app details if none launch.
     */
    private fun openOemPermissionEditor(result: MethodChannel.Result) {
        val candidates = listOf(
            // ─── OxygenOS / ColorOS (OnePlus, Oppo, Realme) ────────────
            // OxygenOS 13+ / ColorOS 13+ uses the "oplus" package namespace.
            Intent().apply {
                setClassName(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.floatwindow.FloatWindowListActivity"
                )
            },
            Intent().apply {
                setClassName(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.PermissionTopActivity"
                )
            },
            // Older ColorOS / OxygenOS (< 13)
            Intent().apply {
                setClassName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.floatwindow.FloatWindowListActivity"
                )
            },
            Intent().apply {
                setClassName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.sysfloatwindow.FloatWindowListActivity"
                )
            },
            Intent().apply {
                setClassName(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.floatwindow.FloatWindowListActivity"
                )
            },

            // ─── HyperOS / MIUI (Xiaomi / Redmi / Poco) ────────────────
            // Implicit action — lets the resolver pick the right editor
            // regardless of MIUI / HyperOS version.
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                putExtra("extra_pkgname", packageName)
            },
            Intent("miui.intent.action.APP_PERMISSIONS_EDITOR").apply {
                putExtra("extra_pkgname", packageName)
            },
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.PermissionsEditorActivity"
                )
                putExtra("extra_pkgname", packageName)
            },
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.AppPermissionsEditorActivity"
                )
                putExtra("extra_pkgname", packageName)
            },

            // ─── FuntouchOS / OriginOS (Vivo / iQOO) ───────────────────
            Intent().apply {
                setClassName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity"
                )
                putExtra("packagename", packageName)
            },
            Intent().apply {
                setClassName(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.FloatWindowManager"
                )
            },

            // ─── Magic OS / EMUI (Honor / Huawei) ──────────────────────
            Intent().apply {
                setClassName(
                    "com.huawei.systemmanager",
                    "com.huawei.permissionmanager.ui.MainActivity"
                )
            },
            Intent().apply {
                setClassName(
                    "com.huawei.systemmanager",
                    "com.huawei.notificationmanager.ui.NotificationManagmentActivity"
                )
            },

            // ─── One UI (Samsung) ──────────────────────────────────────
            // Samsung mostly routes through AOSP; this activity exists on
            // some older One UI builds for the app-level settings screen.
            Intent().apply {
                setClassName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"
                )
            }
        )

        for (intent in candidates) {
            try {
                // resolveActivity returns null when no matching activity exists —
                // cheaper than catching ActivityNotFoundException on every miss.
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success(true)
                    return
                }
            } catch (_: Exception) {
                continue
            }
        }
        // Last resort: AOSP overlay permission screen. Every modern ROM has
        // this at minimum; it's the same permission, just via the generic
        // Android settings UI instead of the OEM one.
        openOverlaySettings(result)
    }

    private fun safeStart(intent: Intent, result: MethodChannel.Result) {
        try {
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            // Fallback to generic app details if the specific screen doesn't exist on this ROM.
            try {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                )
                result.success(true)
            } catch (e2: Exception) {
                result.success(false)
            }
        }
    }
}
