import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_service.dart';
import '../services/socket_service.dart';
import '../services/fcm_service.dart';
import '../utils/phone_utils.dart';

class AuthViewModel with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  AuthViewModel() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // Validate token with backend
      try {
        final response = await ApiService.getCurrentUser();
        if (response['user'] != null) {
          _user = response['user'];
          _isAuthenticated = true;
          await SocketService.initialize();
          // Save FCM token after successful auth check
          // Use a small delay to ensure Firebase is fully ready
          Future.delayed(const Duration(milliseconds: 500), () {
            FCMService().savePendingToken();
          });
        } else {
          // Token is invalid, remove it
          await prefs.remove('token');
          _isAuthenticated = false;
          _user = null;
        }
      } catch (e) {
        // Token is invalid or expired, remove it
        await prefs.remove('token');
        _isAuthenticated = false;
        _user = null;
      }
    } else {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (response['message'] != null) {
        _errorMessage = null;
        return true;
      }
      _errorMessage = 'Registration failed. Please try again.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Send OTP using SMS provider (replaces Firebase)
  Future<bool> sendOTP(String phoneNumber) async {
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Starting OTP send process for: $phoneNumber');
      
      // Normalize phone number before sending
      String? normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      if (normalizedPhone == null) {
        _errorMessage = 'Invalid phone number format';
        return false;
      }

      // Call backend API to send OTP via SMS provider
      final response = await ApiService.sendPhoneOTP(
        phoneNumber: normalizedPhone,
      );

      if (response['message'] != null) {
        print('✅ OTP sent successfully');
        _errorMessage = null;
        return true;
      }
      
      _errorMessage = 'Failed to send OTP. Please try again.';
      return false;
    } catch (e) {
      print('❌ Exception in sendOTP: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Verify OTP using SMS provider (replaces Firebase)
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Normalize phone number before verification
      String? normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      if (normalizedPhone == null) {
        _errorMessage = 'Invalid phone number format';
        return false;
      }

      // Call backend API to verify OTP
      final response = await ApiService.verifyPhoneOTP(
        phoneNumber: normalizedPhone,
        otp: otp,
      );

      if (response['token'] != null) {
        // Token is already stored in ApiService.verifyPhoneOTP
        _user = response['user'];
        _isAuthenticated = true;
        _errorMessage = null;
        await SocketService.initialize();
        // Give socket a moment to connect before proceeding
        await Future.delayed(const Duration(milliseconds: 500));
        // Save FCM token after successful authentication
        // Use a small delay to ensure Firebase is fully ready
        // This is critical after app reinstallation
        Future.delayed(const Duration(milliseconds: 500), () async {
          // Force refresh and sync token to ensure we have the latest one
          await FCMService().forceRefreshAndSyncToken();
          // Also try savePendingToken as fallback
          await FCMService().savePendingToken();
        });
        notifyListeners();
        return true;
      }
      
      _errorMessage = response['message'] ?? 'OTP verification failed. Please try again.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        _user = response['user'];
        _isAuthenticated = true;
        _errorMessage = null;
        await SocketService.initialize();
        // Save FCM token after successful login
        // Use a small delay to ensure Firebase is fully ready
        // This is critical after app reinstallation
        Future.delayed(const Duration(milliseconds: 500), () async {
          // Force refresh and sync token to ensure we have the latest one
          await FCMService().forceRefreshAndSyncToken();
          // Also try savePendingToken as fallback
          await FCMService().savePendingToken();
        });
        notifyListeners();
        return true;
      }
      _errorMessage = 'Login failed. Please check your credentials.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _isAuthenticated = false;
    _user = null;
    SocketService.disconnect();
    notifyListeners();
  }

  // Send OTP for account deletion (uses authenticated endpoint)
  Future<bool> sendDeleteAccountOTP(String phoneNumber) async {
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Starting delete account OTP send process for: $phoneNumber');
      
      // Normalize phone number before sending
      String? normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      if (normalizedPhone == null) {
        _errorMessage = 'Invalid phone number format';
        return false;
      }

      // Try authenticated endpoint first, fallback to regular endpoint
      try {
        final response = await ApiService.sendDeleteAccountOTP(
          phoneNumber: normalizedPhone,
        );

        if (response['message'] != null) {
          print('✅ Delete account OTP sent successfully');
          _errorMessage = null;
          return true;
        }
        
        _errorMessage = 'Failed to send OTP. Please try again.';
        return false;
      } catch (e) {
        // If new endpoint doesn't exist (404), use regular endpoint which now supports auth
        if (e.toString().contains('404') || e.toString().contains('Cannot POST')) {
          print('⚠️  New endpoint not available, using regular sendPhoneOTP with auth');
          final response = await ApiService.sendPhoneOTP(
            phoneNumber: normalizedPhone,
          );

          if (response['message'] != null) {
            print('✅ Delete account OTP sent successfully via fallback');
            _errorMessage = null;
            return true;
          }
          
          _errorMessage = 'Failed to send OTP. Please try again.';
          return false;
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Exception in sendDeleteAccountOTP: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Delete account with OTP verification
  Future<bool> deleteAccount({
    required String phoneNumber,
    required String otp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Normalize phone number before deletion
      String? normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      if (normalizedPhone == null) {
        _errorMessage = 'Invalid phone number format';
        return false;
      }

      // Call backend API to delete account
      final response = await ApiService.deleteAccount(
        phoneNumber: normalizedPhone,
        otp: otp,
      );

      if (response['message'] != null || response['success'] == true) {
        // Clear all local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Clear auth state
        _isAuthenticated = false;
        _user = null;
        _errorMessage = null;
        
        // Disconnect socket
        SocketService.disconnect();
        
        notifyListeners();
        return true;
      }
      
      _errorMessage = response['message'] ?? 'Failed to delete account. Please try again.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Method to set authenticated state (used after OTP verification)
  Future<void> setAuthenticated({
    required String token,
    Map<String, dynamic>? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _user = user;
    _isAuthenticated = true;
    _errorMessage = null;
    await SocketService.initialize();
    notifyListeners();
  }
}
