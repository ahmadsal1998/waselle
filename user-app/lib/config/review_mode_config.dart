/// Configuration for Review Mode activation.
/// 
/// Review Mode is automatically controlled via:
/// 1. Runtime detection (primary): Detects TestFlight at runtime via iOS method channel
/// 2. Compile-time detection (fallback): Uses --dart-define=TESTFLIGHT=true flag
/// 
/// No manual code changes needed - it's determined automatically.
/// 
/// Build Methods:
/// - Xcode/TestFlight: Runtime detection automatically activates Review Mode
/// - Flutter CLI: Use --dart-define=TESTFLIGHT=true → Review Mode ON (fallback)
/// - App Store: Review Mode automatically OFF (not TestFlight)
class ReviewModeConfig {
  /// Detects if this is a TestFlight build via compile-time environment variable.
  /// 
  /// This is used as a fallback when runtime detection is not available.
  /// Primary detection is done at runtime via iOS method channel in ReviewModeService.
  /// 
  /// Compile-time detection (fallback):
  /// - TestFlight builds: --dart-define=TESTFLIGHT=true → Review Mode enabled
  /// - App Store releases: No TESTFLIGHT define → Review Mode automatically disabled
  /// 
  /// This ensures Review Mode is ONLY active in TestFlight builds for Apple reviewers,
  /// and automatically disabled in public App Store releases without manual intervention.
  static const bool isTestFlight = bool.fromEnvironment(
    'TESTFLIGHT',
    defaultValue: false,
  );
  
  /// Enables Review Mode for TestFlight builds (compile-time fallback).
  /// 
  /// Note: Primary detection is done at runtime in ReviewModeService.
  /// This is used as a fallback when runtime detection is not available.
  /// 
  /// Result:
  /// - TestFlight build (runtime or compile-time) → Review Mode automatically ON
  /// - App Store release → Review Mode automatically OFF
  static bool get enableTestFlightReviewMode => isTestFlight;
  
  /// Enable Review Mode for debug builds (development only).
  /// 
  /// Set via compile-time environment variable for local testing:
  /// --dart-define=ENABLE_DEBUG_REVIEW_MODE=true
  /// 
  /// Has no effect in release builds.
  static const bool enableDebugReviewMode = bool.fromEnvironment(
    'ENABLE_DEBUG_REVIEW_MODE',
    defaultValue: false,
  );
}

