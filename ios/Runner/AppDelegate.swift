import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerNativeFeedAdPlatformView()
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerNativeFeedAdPlatformView()
  }

  private func registerNativeFeedAdPlatformView() {
    guard let registrar = registrar(forPlugin: "NativeFeedAdPlugin") else { return }
    registrar.register(NativeFeedAdPlatformViewFactory(), withId: "dgu_feed_native_ad")
  }
}
