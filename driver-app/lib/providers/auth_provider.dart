import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final response = await ApiService.getCurrentUser();
        if (response['user'] != null) {
          _user = response['user'] as Map<String, dynamic>;
          final vehicleType = _user?['vehicleType'];
          if (vehicleType is String && vehicleType.isNotEmpty) {
            await prefs.setString('vehicleType', vehicleType);
          } else {
            await prefs.remove('vehicleType');
          }
        }
        _isAuthenticated = true;
      } catch (e) {
        await prefs.remove('token');
        await prefs.remove('vehicleType');
        _isAuthenticated = false;
        _user = null;
      }
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    required String vehicleType,
  }) async {
    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        vehicleType: vehicleType,
      );

      if (response['message'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiService.verifyOTP(email: email, otp: otp);

      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        _user = response['user'];
        final vehicleType = _user?['vehicleType'];
        if (vehicleType is String && vehicleType.isNotEmpty) {
          await prefs.setString('vehicleType', vehicleType);
        } else {
          await prefs.remove('vehicleType');
        }
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        _user = response['user'];
        final vehicleType = _user?['vehicleType'];
        if (vehicleType is String && vehicleType.isNotEmpty) {
          await prefs.setString('vehicleType', vehicleType);
        } else {
          await prefs.remove('vehicleType');
        }
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
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
}
