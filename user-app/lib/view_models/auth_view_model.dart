import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_service.dart';
import '../services/socket_service.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  String? _verificationId; // Store Firebase verification ID

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

  // Send OTP using Firebase Phone Authentication
  Future<bool> sendOTP(String phoneNumber) async {
    _errorMessage = null;
    _verificationId = null;
    notifyListeners();

    final completer = Completer<bool>();

    try {
      print('🔄 Starting OTP send process for: $phoneNumber');
      
      _firebaseAuth.sendOTPWithCallback(
        phoneNumber,
        (verificationId) {
          print('✅ OTP callback received. Verification ID stored.');
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (error) {
          print('❌ OTP error callback: $error');
          _errorMessage = error;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Wait for callback with timeout
      return await completer.future.timeout(
        const Duration(seconds: 60), // Increased timeout to 60 seconds
        onTimeout: () {
          print('⏱️ OTP request timed out after 60 seconds');
          _errorMessage = 'OTP request timed out. Please check your phone number and try again.';
          return false;
        },
      );
    } catch (e) {
      print('❌ Exception in sendOTP: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    if (_verificationId == null) {
      _errorMessage = 'Please request OTP first';
      return false;
    }

    try {
      // Verify OTP with Firebase
      final userCredential = await _firebaseAuth.verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Get Firebase user and ID token
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _errorMessage = 'Failed to get Firebase user after verification';
        return false;
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _errorMessage = 'Failed to get authentication token';
        return false;
      }

      // Format phone number with country code if needed
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        // Try to add country code (default to +970 for Palestine)
        formattedPhone = '+970$formattedPhone';
      }

      // Call phone-login endpoint to save user in MongoDB and get JWT token
      final response = await ApiService.phoneLogin(
        phone: formattedPhone,
        firebaseUid: firebaseUser.uid,
        verificationId: _verificationId!,
        smsCode: otp,
        idToken: idToken,
      );

      if (response['token'] != null) {
        // Token is already stored in ApiService.phoneLogin
        _user = response['user'];
        _isAuthenticated = true;
        _errorMessage = null;
        _verificationId = null; // Clear verification ID
        await SocketService.initialize();
        notifyListeners();
        return true;
      }
      _errorMessage = 'OTP verification failed. Please try again.';
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
