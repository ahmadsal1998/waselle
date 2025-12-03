import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/review_mode_config.dart';

/// Service to detect and manage Review Mode for Apple App Store reviewers.
/// Review Mode automatically activates when running in TestFlight or when
/// an Apple reviewer account is detected. It remains completely hidden from
/// regular users in production builds.
class ReviewModeService {
  static const String _reviewModeKey = '_review_mode_active';
  static const MethodChannel _testFlightChannel = MethodChannel('com.wassle.userapp/testflight');
  static bool? _cachedReviewMode;
  static bool? _cachedTestFlightStatus;
  static bool _isInitialized = false;

  /// Checks if the app is running in TestFlight (runtime detection).
  /// This works for builds uploaded through Xcode/TestFlight.
  static Future<bool> _isRunningInTestFlight() async {
    if (_cachedTestFlightStatus != null) {
      return _cachedTestFlightStatus!;
    }

    if (!Platform.isIOS) {
      _cachedTestFlightStatus = false;
      return false;
    }

    try {
      final result = await _testFlightChannel.invokeMethod<bool>('isTestFlight');
      _cachedTestFlightStatus = result ?? false;
      return _cachedTestFlightStatus!;
    } catch (e) {
      // If method channel fails, fall back to compile-time detection
      if (kDebugMode) {
        debugPrint('⚠️ TestFlight detection failed: $e, falling back to compile-time detection');
      }
      _cachedTestFlightStatus = ReviewModeConfig.enableTestFlightReviewMode;
      return _cachedTestFlightStatus!;
    }
  }

  /// Checks if Review Mode should be activated.
  /// 
  /// Review Mode is automatically enabled when:
  /// - Running in TestFlight (detected at runtime via iOS method channel)
  /// - OR compile-time flag TESTFLIGHT=true is set (fallback)
  /// 
  /// Review Mode is NEVER enabled in production App Store releases.
  /// No manual intervention needed - it's determined at runtime/build time.
  static Future<bool> isReviewModeActive() async {
    if (_cachedReviewMode != null) {
      return _cachedReviewMode!;
    }

    // In release/production builds, check for TestFlight (runtime detection)
    if (kReleaseMode) {
      // First try runtime detection (works for Xcode builds)
      final isTestFlight = await _isRunningInTestFlight();
      
      if (Platform.isIOS && isTestFlight) {
        _cachedReviewMode = true;
        _isInitialized = true;
        if (kDebugMode) {
          debugPrint('🍎 Review Mode: Activated (TestFlight detected at runtime)');
        }
        return true;
      }
      
      // Fallback: Check compile-time flag (for Flutter CLI builds)
      if (Platform.isIOS && ReviewModeConfig.enableTestFlightReviewMode) {
        _cachedReviewMode = true;
        _isInitialized = true;
        if (kDebugMode) {
          debugPrint('🍎 Review Mode: Activated (TestFlight build detected via compile-time flag)');
        }
        return true;
      }
      
      // Production App Store builds - Review Mode automatically disabled
      _cachedReviewMode = false;
      _isInitialized = true;
      return false;
    }

    // Debug mode - can be enabled via config or manually
    if (ReviewModeConfig.enableDebugReviewMode) {
      _cachedReviewMode = true;
      _isInitialized = true;
      debugPrint('🍎 Review Mode: Activated (debug config enabled)');
      return true;
    }
    
    // Check if manually enabled via SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final manuallyEnabled = prefs.getBool(_reviewModeKey) ?? false;
    
    if (manuallyEnabled) {
      _cachedReviewMode = true;
      _isInitialized = true;
      debugPrint('🍎 Review Mode: Activated (manually enabled in debug)');
      return true;
    }

    _cachedReviewMode = false;
    _isInitialized = true;
    return false;
  }


  /// Manually enable Review Mode (debug mode only).
  /// This is useful for testing Review Mode during development.
  /// Does nothing in release builds.
  static Future<void> enableReviewMode() async {
    if (kReleaseMode) {
      // Cannot manually enable in release builds
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewModeKey, true);
    _cachedReviewMode = true;
    
    if (kDebugMode) {
      debugPrint('🍎 Review Mode: Manually enabled (debug mode)');
    }
  }

  /// Manually disable Review Mode (debug mode only).
  /// Does nothing in release builds.
  static Future<void> disableReviewMode() async {
    if (kReleaseMode) {
      // Cannot manually disable in release builds (it's already disabled)
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewModeKey, false);
    _cachedReviewMode = false;
    
    if (kDebugMode) {
      debugPrint('🍎 Review Mode: Manually disabled (debug mode)');
    }
  }

  /// Reset Review Mode detection (forces re-check on next call).
  /// Useful for testing.
  static void reset() {
    _cachedReviewMode = null;
    _cachedTestFlightStatus = null;
    _isInitialized = false;
  }

  /// Check if Review Mode has been initialized.
  static bool get isInitialized => _isInitialized;
}

