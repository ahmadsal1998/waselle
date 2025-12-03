import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup method channel for TestFlight detection after window is ready
    if let controller = window?.rootViewController as? FlutterViewController {
      setupTestFlightChannel(controller: controller)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Setup method channel if not already set up (fallback)
    if let controller = window?.rootViewController as? FlutterViewController {
      setupTestFlightChannel(controller: controller)
    }
    super.applicationDidBecomeActive(application)
  }
  
  /// Setup method channel for TestFlight detection
  private func setupTestFlightChannel(controller: FlutterViewController) {
    let testFlightChannel = FlutterMethodChannel(
      name: "com.wassle.userapp/testflight",
      binaryMessenger: controller.binaryMessenger
    )
    
    testFlightChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "isTestFlight" {
        result(self.isRunningInTestFlight())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  /// Detects if the app is running from TestFlight
  /// TestFlight apps have a receipt URL containing "sandbox"
  private func isRunningInTestFlight() -> Bool {
    // Check if app receipt exists and is from sandbox (TestFlight)
    guard let receiptURL = Bundle.main.appStoreReceiptURL else {
      return false
    }
    
    // TestFlight receipts are in the sandbox environment
    return receiptURL.path.contains("sandboxReceipt")
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
