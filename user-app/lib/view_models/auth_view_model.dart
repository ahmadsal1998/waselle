import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_service.dart';
import '../services/socket_service.dart';

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

  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.verifyOTP(email: email, otp: otp);

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
