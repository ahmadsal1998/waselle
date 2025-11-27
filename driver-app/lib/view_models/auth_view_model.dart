import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/fcm_service.dart';

class AuthViewModel with ChangeNotifier {
  AuthViewModel({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository() {
    _checkAuthStatus();
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true; // Track if we're checking auth status
  Map<String, dynamic>? _user;
  bool _isSuspended = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  Map<String, dynamic>? get user => _user;
  bool get isSuspended => _isSuspended;
  // Default to Available (true) unless explicitly set to false
  bool get isAvailable => _user?['isAvailable'] != false;

  Future<void> _checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _isAuthenticated = false;
      _user = null;
      _isSuspended = false;
      _isCheckingAuth = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _authRepository.getCurrentUser();
      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        await _applyUserData(userData);
      }
      _isAuthenticated = true;
      _isSuspended = _user?['isActive'] == false;
      
      // Save FCM token after successful auth check
      // Use a small delay to ensure Firebase is fully ready
      Future.delayed(const Duration(milliseconds: 500), () {
        FCMService().savePendingToken();
      });
    } catch (e) {
      await prefs.remove('token');
      await prefs.remove('vehicleType');
      _isAuthenticated = false;
      _user = null;
      _isSuspended = false;
      debugPrint('Error checking auth status: $e');
    }

    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    required String vehicleType,
  }) async {
    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        vehicleType: vehicleType,
      );
      return response['message'] != null;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return false;
    }
  }


  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );
      final token = response['token'];

      if (token is String) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        final userData = response['user'];
        if (userData is Map<String, dynamic>) {
          await _applyUserData(userData);
        }

        _isAuthenticated = true;
        _isSuspended = _user?['isActive'] == false;
        notifyListeners();
        
        // Save FCM token after successful login
        // Use a small delay to ensure Firebase is fully ready
        // This is critical after app reinstallation
        Future.delayed(const Duration(milliseconds: 500), () async {
          // Force refresh and sync token to ensure we have the latest one
          await FCMService().forceRefreshAndSyncToken();
          // Also try savePendingToken as fallback
          await FCMService().savePendingToken();
        });
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error logging in: $e');
      // Check if error is due to suspension
      if (e.toString().contains('suspended') || e.toString().contains('403')) {
        _isSuspended = true;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> setAvailability(bool isAvailable) async {
    try {
      final response = await _userRepository.updateAvailability(
        isAvailable: isAvailable,
      );

      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        await _applyUserData(userData);
        notifyListeners();
      } else {
        _user = {
          ...?_user,
          'isAvailable': isAvailable,
        };
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating availability: $e');
      return false;
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      final response = await _authRepository.getCurrentUser();
      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        await _applyUserData(userData);
      }
      _isSuspended = _user?['isActive'] == false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing current user: $e');
      // If 403 error, mark as suspended
      if (e.toString().contains('403')) {
        _isSuspended = true;
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfilePicture(String profilePictureUrl) async {
    try {
      final response = await _userRepository.updateProfilePicture(
        profilePictureUrl: profilePictureUrl,
      );

      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        await _applyUserData(userData);
        notifyListeners();
      } else {
        _user = {
          ...?_user,
          'profilePicture': profilePictureUrl,
        };
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('vehicleType');
    _isAuthenticated = false;
    _user = null;
    _isSuspended = false;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> sendOTP(String phoneNumber) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Use authenticated endpoint for account deletion OTP
      await _authRepository.sendDeleteAccountOTP(phoneNumber: phoneNumber);
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      return false;
    }
  }

  Future<bool> deleteAccount({
    required String phoneNumber,
    required String otp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.deleteAccount(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (response['message'] != null || response['success'] == true) {
        // Clear all local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Clear auth state
        _isAuthenticated = false;
        _user = null;
        _isSuspended = false;
        _errorMessage = null;
        
        notifyListeners();
        return true;
      }
      
      _errorMessage = response['message'] ?? 'Failed to delete account. Please try again.';
      return false;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      return false;
    }
  }

  void setSuspended(bool suspended) {
    _isSuspended = suspended;
    notifyListeners();
  }

  Future<void> _applyUserData(Map<String, dynamic> userData) async {
    _user = Map<String, dynamic>.from(userData);
    _isSuspended = _user?['isActive'] == false;
    final prefs = await SharedPreferences.getInstance();
    final vehicleType = _user?['vehicleType'];

    if (vehicleType is String && vehicleType.isNotEmpty) {
      await prefs.setString('vehicleType', vehicleType);
    } else {
      await prefs.remove('vehicleType');
    }
  }
}

