import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var localPreferencesChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "OWRTPCLocalPreferences"
    ) else {
      assertionFailure("Unable to register the local preferences channel")
      return
    }
    let channel = FlutterMethodChannel(
      name: "org.owrtpc.mobile/local_preferences",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard let arguments = call.arguments as? [String: Any],
            let key = arguments["key"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing preference key", details: nil))
        return
      }
      switch call.method {
      case "getString":
        result(UserDefaults.standard.string(forKey: key))
      case "setString":
        guard let value = arguments["value"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Missing preference value", details: nil))
          return
        }
        UserDefaults.standard.set(value, forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    localPreferencesChannel = channel
  }
}
