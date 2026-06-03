package ru.dgu.college.dgu_mobile.android

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()

// Регистрация нативной рекламы Yandex (включить вместе с yandex_mobileads в pubspec):
// override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//     super.configureFlutterEngine(flutterEngine)
//     flutterEngine.platformViewsController.registry.registerViewFactory(
//         "dgu_feed_native_ad",
//         NewsNativeAdPlatformViewFactory(),
//     )
// }
