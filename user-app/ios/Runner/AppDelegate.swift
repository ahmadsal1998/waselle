import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL callbacks for Firebase Phone Auth
  // Firebase Auth will handle these URLs automatically through the parent class
  // The onUnknownRoute handler in main.dart will gracefully handle any URLs
  // that Flutter tries to route, preventing "Failed to handle route information" warnings
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Pass URL to parent class which handles Firebase Auth callbacks
    return super.application(app, open: url, options: options)
  }
}
