# Fajarly Pro

<p align="center">
  <img src="assets/branding/logo.png" alt="Fajarly Pro logo" width="200"/>
</p>

<p align="center">
  <b>A smart alarm that makes you physically get out of bed.</b><br/>
  To stop the alarm, you have to scan a real-world barcode or QR code.
</p>

---

## What it does

Fajarly Pro is an Android alarm app built for people who snooze through regular alarms. When the alarm fires it launches a full-screen scanner over the lock screen — the only way to dismiss it is to point your camera at a pre-registered barcode or QR code. Tape the code to your bathroom mirror, stick it on the kettle, or point it at the barcode on your shampoo bottle. No scan, no silence.

### Features

- **Barcode or QR unlock** — any product barcode (EAN-13, UPC, Code 128, etc.) or any QR code
- **Generate your own codes** — print a QR or Code 128 and stick it where you need to walk to
- **Full-screen ringing** — opens over the lock screen, dismisses the keyguard, blocks the back button, and re-launches itself when minimized
- **Snooze with penalty** — each snooze adds one scan to the unlock requirement; "Escalating" difficulty doubles it
- **Streak tracking** — consecutive-day streak, best streak, fastest-scan time, 30-day heatmap
- **Custom recurrence** — per-weekday schedules, one-shots, labels
- **Anti-cheat** — FLAG_SECURE blocks screenshots and scrubs the camera preview from recents
- **Offline-first** — no login, no network, all local storage via Hive
- **Light / dark theme** — picks up system default, override in Settings

---

## Screenshots

> Drop screenshots here once you capture them on a real device. Recommended: home, ringing screen, generator, streaks.

---

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| State / DI | `flutter_riverpod` | Compile-safe, no `BuildContext` coupling, clean `AsyncValue` |
| Routing | `go_router` | Declarative, deep-link ready |
| Alarm engine | `alarm` | Handles full-screen intent, foreground service, boot reschedule |
| Scanning | `mobile_scanner` | Fast MLKit wrapper, supports all barcode formats |
| Local storage | `hive_ce` | Maintained Hive fork, no SQL overhead |
| QR + barcode render | `qr_flutter` + `barcode_widget` | Generates + renders both |
| Notifications | `flutter_local_notifications` | Alarm package uses this internally |

**Architecture:** clean, feature-first. Every feature has `domain/` (entities + use cases, pure Dart, zero Flutter imports), `data/` (Hive models, repositories, platform-service wrappers), and `presentation/` (Riverpod providers + widgets). Features never import each other — shared stuff goes through `core/`.

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── router/
│   ├── theme/
│   ├── services/      # method channel wrappers (secure screen, etc.)
│   └── utils/
└── features/
    ├── alarm/         # the heart — entities, scheduler, ringing screen
    ├── scanner/       # barcode/QR capture + match-code use case
    ├── qr_generator/  # QR + Code 128 + EAN-13 generation
    ├── onboarding/    # first-run flow + permission requests
    ├── streaks/       # wake-up history, stats, heatmap
    └── settings/      # theme, snooze duration, OEM autostart
```

---

## Getting started

### Prerequisites

- Flutter 3.22 or newer ([install guide](https://docs.flutter.dev/get-started/install))
- A real Android device (API 24 / Android 7.0 or newer)
- An IDE with Flutter support (VS Code, Android Studio, IntelliJ)

Emulators work for UI testing but **don't** faithfully reproduce Doze mode, full-screen intents, or OEM kill behavior — always test alarm reliability on a real device.

### Clone and run

```bash
git clone <this repo>
cd fajarly

# Drop an alarm tone (any short loopable mp3)
# → assets/audio/alarm.mp3

# Generate launcher icons + native splash from the logo
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Run on a connected device
flutter run
```

### Build a release APK

```bash
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Install the `arm64-v8a` variant on any modern phone. A universal APK (`flutter build apk --release`) also works but is ~2× larger.

> Release builds are signed with the **debug** keystore by default. That's fine for sideload testing. Before publishing to Play, set up a real keystore and configure `android/app/build.gradle.kts` per the [Flutter signing docs](https://docs.flutter.dev/deployment/android#signing-the-app).

---

## Android configuration notes

Most of this is already done in the repo — this section documents the why, in case you fork.

### Required permissions

- `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` — Android 12+ alarm clocks
- `USE_FULL_SCREEN_INTENT` — launches the ringing screen over the lock screen
- `POST_NOTIFICATIONS` — Android 13+ notification runtime permission
- `CAMERA`, `VIBRATE`, `WAKE_LOCK` — scanner, ring feedback, keep-screen-on
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — alarm audio while ringing
- `RECEIVE_BOOT_COMPLETED` — reschedule alarms after reboot
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — prompt user to whitelist the app
- `DISABLE_KEYGUARD` — dismiss insecure lock screen when alarm fires

### Build config highlights

```kotlin
// android/app/build.gradle.kts
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // flutter_local_notifications needs this
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        minSdk = 24
        multiDexEnabled = true
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### OEM quirks

Xiaomi, Oppo, Vivo, Huawei, and Samsung aggressively kill background apps. The onboarding flow detects the manufacturer and deep-links to the autostart settings page; see [`lib/core/utils/oem_autostart.dart`](lib/core/utils/oem_autostart.dart). If you see "alarm didn't fire" bug reports from a specific ROM, add the new component name to that map.

---

## Known limitations

- **Force-stop is unstoppable.** No Android app can schedule alarms past the user (or OEM memory manager) force-stopping the process, without being a Device Owner. This is a platform limitation, not a bug. The alarm package posts a "will not fire if killed" warning notification to mitigate.
- **iOS is not supported.** iOS doesn't allow reliable background alarm scheduling for terminated apps without Apple's approval for `UNNotificationCriticalAlert`. Android-first was a deliberate choice.
- **Emulator reliability is poor.** Always test on a physical device.
- **Adaptive launcher icon crops text.** The current logo includes the "Fajarly" wordmark, which gets clipped inside the circular/rounded-square mask. For a cleaner launcher icon, export a square icon-only variant and use it as `adaptive_icon_foreground` in `pubspec.yaml`.

---

## Troubleshooting

**Alarm doesn't fire when phone is locked.** In order of likelihood:
1. Grant **exact alarm** permission: Settings → Apps → Fajarly Pro → Alarms & reminders
2. Grant **full-screen intent**: Settings → Apps → Fajarly Pro → Notifications → Appear on top
3. Disable **battery optimization**: Settings → Apps → Fajarly Pro → Battery → Unrestricted
4. On Xiaomi/Oppo/Vivo, enable **Autostart** (onboarding slide 4 deep-links here)
5. Verify `assets/audio/alarm.mp3` exists

**Build fails with "core library desugaring" error.** `android/app/build.gradle.kts` needs `isCoreLibraryDesugaringEnabled = true` and the `desugar_jdk_libs` dependency. See the build config highlights above.

**Kotlin incremental cache errors on Windows.** If your project and pub cache live on different drives (e.g., project on `D:`, pub cache on `C:`), Kotlin's incremental compiler gets confused. `android/gradle.properties` sets `kotlin.incremental=false` to work around it.

---

## License

MIT. See `LICENSE` if you add one.
