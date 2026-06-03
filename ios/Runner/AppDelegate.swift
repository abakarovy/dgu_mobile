import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Yandex native feed ads — отключено (см. YandexAdsConfig.kGloballyDisabled).
  // private func registerNativeFeedAdPlatformView() {
  //   guard let registrar = registrar(forPlugin: "NativeFeedAdPlugin") else { return }
  //   registrar.register(NativeFeedAdPlatformViewFactory(), withId: "dgu_feed_native_ad")
  // }
}
