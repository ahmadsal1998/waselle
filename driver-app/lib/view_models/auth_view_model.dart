import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firebase_auth_service.dart';

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
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _verificationId; // Store Firebase verification ID

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  // Default to Available (true) unless explicitly set to false
  bool get isAvailable => _user?['isAvailable'] != false;

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _isAuthenticated = false;
      _user = null;
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
    } catch (e) {
      await prefs.remove('token');
      await prefs.remove('vehicleType');
      _isAuthenticated = false;
      _user = null;
      debugPrint('Error checking auth status: $e');
    }

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

  // Send OTP using Firebase Phone Authentication
  Future<bool> sendOTP(String phoneNumber) async {
    _verificationId = null;
    
    final completer = Completer<bool>();

    try {
      _firebaseAuth.sendOTPWithCallback(
        phoneNumber,
        (verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (error) {
          debugPrint('Error sending OTP: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Wait for callback with timeout
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('OTP request timed out');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (_verificationId == null) {
      debugPrint('No verification ID found. Please request OTP first.');
      return false;
    }

    try {
      // Verify OTP with Firebase
      final userCredential = await _firebaseAuth.verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        debugPrint('Failed to get Firebase ID token');
        return false;
      }

      // Verify with backend using Firebase token
      final response = await _authRepository.verifyFirebaseToken(
        idToken: idToken,
        phoneNumber: phoneNumber,
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
        _verificationId = null; // Clear verification ID
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
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
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error logging in: $e');
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing current user: $e');
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
    notifyListeners();
  }

  Future<void> _applyUserData(Map<String, dynamic> userData) async {
    _user = Map<String, dynamic>.from(userData);
    final prefs = await SharedPreferences.getInstance();
    final vehicleType = _user?['vehicleType'];

    if (vehicleType is String && vehicleType.isNotEmpty) {
      await prefs.setString('vehicleType', vehicleType);
    } else {
      await prefs.remove('vehicleType');
    }
  }
}

