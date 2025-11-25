import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';

/// Service to handle app lifecycle and ensure calls work across all app states
class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  static const String _pendingCallKey = 'pending_incoming_call';
  Timer? _callCheckTimer;
  bool _isInitialized = false;

  /// Initialize the lifecycle service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    // Setup global call listeners that work regardless of app state
    _setupGlobalCallListeners();
    
    // Check for pending calls when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingCall();
    });
  }

  /// Setup global socket listeners for incoming calls
  void _setupGlobalCallListeners() {
    // Listen for incoming calls - this works even when app is in background
    SocketService.on('incoming-call', (data) {
      debugPrint('📞 Global incoming call listener triggered');
      
      final orderId = data['orderId']?.toString();
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      final callerName = data['callerName']?.toString() ?? 'Unknown';
      
      if (orderId == null || roomId == null || callerId == null) {
        debugPrint('Error: Invalid incoming call data');
        return;
      }
      
      // Store call data for recovery if app is terminated
      _storePendingCall(orderId, roomId, callerId, callerName);
      
      // Try to handle call immediately if app is active
      _handleIncomingCall(orderId, roomId, callerId, callerName);
    });
    
    SocketService.on('call-cancelled', (data) {
      debugPrint('🚫 Global call cancelled listener triggered');
      
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      
      if (roomId == null || callerId == null) {
        debugPrint('Error: Invalid call cancellation data');
        return;
      }
      
      // Clear pending call
      _clearPendingCall();
      
      // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
      // Call cancellation handling disabled
    });
  }

  /// Handle incoming call using global navigator
  void _handleIncomingCall(
    String orderId,
    String roomId,
    String callerId,
    String callerName,
  ) {
    debugPrint('📞 Attempting to handle incoming call');
    
    // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
    // Incoming call handling disabled
  }

  /// Store pending call data for recovery
  Future<void> _storePendingCall(
    String orderId,
    String roomId,
    String callerId,
    String callerName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingCallKey, 
        '$orderId|$roomId|$callerId|$callerName');
      debugPrint('💾 Stored pending call: $orderId');
    } catch (e) {
      debugPrint('Error storing pending call: $e');
    }
  }

  /// Clear pending call data
  Future<void> _clearPendingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingCallKey);
      debugPrint('🗑️ Cleared pending call');
    } catch (e) {
      debugPrint('Error clearing pending call: $e');
    }
  }

  /// Check for pending call when app resumes
  Future<void> _checkPendingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCallData = prefs.getString(_pendingCallKey);
      
      if (pendingCallData == null || pendingCallData.isEmpty) {
        return;
      }
      
      final parts = pendingCallData.split('|');
      if (parts.length != 4) {
        await _clearPendingCall();
        return;
      }
      
      final orderId = parts[0];
      final roomId = parts[1];
      final callerId = parts[2];
      final callerName = parts[3];
      
      debugPrint('🔄 Found pending call, attempting to handle: $orderId');
      
      // Wait a bit for app to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try to handle the call
      _handleIncomingCall(orderId, roomId, callerId, callerName);
      
      // Clear after a delay to allow call to be handled
      Future.delayed(const Duration(seconds: 2), () {
        _clearPendingCall();
      });
    } catch (e) {
      debugPrint('Error checking pending call: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check for pending calls
        debugPrint('📱 App resumed, checking for pending calls');
        _checkPendingCall();
        // Ensure socket is connected
        SocketService.initialize();
        break;
      case AppLifecycleState.paused:
        // App went to background - ensure socket stays connected
        debugPrint('📱 App paused, maintaining socket connection');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden');
        break;
    }
  }

  /// Dispose the service
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callCheckTimer?.cancel();
    _isInitialized = false;
  }
}

